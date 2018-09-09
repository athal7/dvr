defmodule DVR.Channel do
  @moduledoc """
  A Phoenix channel mixin that handles replaying of recorded messages
  """

  defmacro __using__(_opts) do
    if Code.ensure_loaded?(Phoenix.Channel) do
      quote do
        def handle_in("replay", %{"replayId" => replay_id}, socket) do
          case DVR.search(replay_id) do
            {:ok, _} ->
              nil

            {:not_found, earliest_id} ->
              Phoenix.Channel.push(socket, "replay:warning", %{
                "requestedReplayId" => replay_id,
                "earliestReplayId" => earliest_id
              })
          end

          # TODO utilize stream
          for {message, _} <- DVR.replay(replay_id, [socket.topic]) do
            Phoenix.Channel.push(socket, socket.topic, %{result: message})
          end

          {:noreply, socket}
        end
      end
    else
      require Logger
      Logger.warn("DVR Channel not configured, Phoenix.Channel module is not available")
    end
  end
end
