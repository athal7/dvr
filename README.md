# DVR

**Record and replay your Phoenix channels**

DVR gives you the ability to resend channel messages from your Phoenix server, based on a client-supplied id for the last seen message. Unlike the [example mentioned in the Phoenix Docs](https://hexdocs.pm/phoenix/channels.html#resending-server-messages), this implementation utilizes [mnesia](http://erlang.org/doc/man/mnesia.html), as opposed to an external database backend.

## Installation

The package can be installed by adding `dvr` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dvr, "~> 0.1.0"}
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
children = [{DVR.Cleanup, interval_seconds: 60 * 10, ttl_seconds: 60 * 60 * 24]
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

*coming soon*

### With Absinthe

*coming soon*
