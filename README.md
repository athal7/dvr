# DVR

*Record and replay your Phoenix channels*

![Hex.pm](https://img.shields.io/hexpm/v/dvr.svg)
![Hex.pm licence](https://img.shields.io/hexpm/l/dvr.svg)
![Build Status)](https://img.shields.io/github/actions/workflow/status/athal7/dvr/ci.yml?branch=main)

**Documentation can be found at [https://hexdocs.pm/dvr](https://hexdocs.pm/dvr).**

DVR gives you the ability to resend channel messages from your Phoenix server, based on a client-supplied id for the last seen message. Unlike the [example mentioned in the Phoenix Docs](https://hexdocs.pm/phoenix/channels.html#resending-server-messages), this implementation utilizes [mnesia](http://erlang.org/doc/man/mnesia.html), as opposed to an external database backend.

## Installation

The package can be installed by adding `dvr` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dvr, "~> 1.1.0"}
  ]
end
```

## Configuration

### Mnesia

The mnesia table can be easily setup across your cluster by utilizing the [mnesiac](https://github.com/beardedeagle/mnesiac) package.

```elixir
config :mnesiac, stores: [DVR.Store]
```

Or you can configure the mnesia table on your own at startup:

```elixir
DVR.Store.init_store()
DVR.Store.copy_store()
```

### Cleanup

You probably want to cleanup the saved messages after a period of time, so as to not over-use your memory or disc capacity (based on the mnesia backend you choose). You can do so by adding the provided cleanup task to your supervision tree:

```elixir
children = [DVR.Cleanup]
Supervisor.start_link(children, strategy: :one_for_one)
```

The default interval is 1 minute, and the default ttl is 1 hour, but you can configure them as you desire:

```elixir
children = [{DVR.Cleanup, interval_seconds: 60 * 10, ttl_seconds: 60 * 60 * 24}]
Supervisor.start_link(children, strategy: :one_for_one)
```

## Usage

### Basic Usage

**Record a message**

```elixir
{:ok, id} = DVR.record(%{some: "message"}, ['some_topic'])
```

**Replay missed messages**

```elixir
id # last seen message id
|> DVR.replay(['some_topic'])
|> Stream.each(&send_to_client/1) # your implementation
|> Stream.run()
```

**Check for a message by id**

```elixir
{:ok, id} = DVR.search(id)
```

### With Phoenix

In `channel.ex`

```elixir
defmodule MyApp.Channel do
  use Phoenix.Channel
  use DVR.Channel

  ...

  def handle_in("new_msg", msg, socket) do
    case DVR.record(msg, [socket.topic]) do
      {:ok, replay_id} ->
        broadcast!(socket, socket.topic, Map.put(msg, :replay_id, replay_id))

      err ->
        Logger.error("Unable to add replayId to message", error: err)
        push(socket, socket.topic, msg)
    end

    {:noreply, socket}
  end
end
```

In your client:

```js
...

let replayId // recovered from storage somewhere

channel.on("new_msg", payload => {
  lastMessageId = payload.replay_id
})

channel.join()
  .receive("ok", resp => {
    console.log("Joined successfully", resp)
    channel.push('replay', { replayId })
  })
  .receive("error", resp => { console.log("Unable to join", resp) })
```

### With Absinthe

Make sure to add the `replayId` to your schema for the subscription type that you are publishing. Then you can record the message when resolving:

```elixir
object :foo do
  field(:bar, :string)
  field(:baz, :string)
end

object :foo_update do
  field(:foo, :foo)
  field(:replayId, :integer)
end

subscription do
  field :foo_updates, :foo_update do
    config(fn _, _ -> {:ok, topic: "*"} end)

    resolve(fn root, _, _ ->
      {:ok, replay_id} = DVR.record(root, [foo_updates: "*"])
      {:ok, Map.put(root, :replay_id, replay_id)}
    end)
  end
end
```

For now, you have to customize the entire set of channel / socket modules, since there's not yet a way to decorate the default channel:

endpoint.ex

```elixir
defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :web
  use Absinthe.Phoenix.Endpoint

  socket("/socket", MyApp.UserSocket, websocket: true)
  ...
```

socket.ex

```elixir
defmodule MyApp.UserSocket do
  use Phoenix.Socket

  def connect(_payload, socket), do: {:ok, socket}
  def id(_socket), do: nil

  channel(
    "__absinthe__:*",
    MyApp.AbsintheChannel,
    assigns: %{__absinthe_schema__: MyApp.Schema}
  )

  defdelegate put_options(socket, opts), to: Absinthe.Phoenix.Socket
  defdelegate put_schema(socket, schema), to: Absinthe.Phoenix.Socket
end
```

channel.ex

```elixir
defmodule MyApp.Channel do
  use Phoenix.Channel

  defdelegate handle_in(event, payload, socket), to: DVR.AbsintheChannel
  defdelegate join(channel, message, socket), to: Absinthe.Phoenix.Channel
end
```

In your client:

```js
...

let replayId // recovered from storage somewhere

channel.on("new_msg", payload => {
  // take the replayId from the relevant place in your schema
  replayId = payload.replayId
})

channel.join()
  .receive("ok", resp => {
    console.log("Joined successfully", resp)
    const subscriptionId = resp.body.payload.response.subscriptionId
    channel.push('replay', { replayId, subscriptionId })
  })
  .receive("error", resp => { console.log("Unable to join", resp) })
```
