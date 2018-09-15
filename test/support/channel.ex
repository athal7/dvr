defmodule DVR.Phoenix.TestChannel do
  use Phoenix.Channel
  use DVR.Channel

  require Logger

  def join("phoenix", _message, socket) do
    {:ok, socket}
  end

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

defmodule DVR.Absinthe.TestChannel do
  use Phoenix.Channel

  defdelegate handle_in(event, payload, socket), to: DVR.AbsintheChannel
  defdelegate join(channel, message, socket), to: Absinthe.Phoenix.Channel
end
