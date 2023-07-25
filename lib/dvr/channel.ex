defmodule DVR.Channel do
  @moduledoc """
  A Phoenix channel mixin that handles replaying of recorded messages
  """

  defmacro __using__(_opts) do
    if Code.ensure_loaded?(Phoenix.Channel) do
      quote do
        def handle_in("replay", %{"replay_id" => replay_id}, socket) do
          case DVR.search(replay_id) do
            {:ok, _} ->
              nil

            {:not_found, earliest_id} ->
              Phoenix.Channel.push(socket, "replay:warning", %{
                "requested_replay_id" => replay_id,
                "earliest_replay_id" => earliest_id
              })
          end

          replay_id
          |> DVR.replay()
          |> Stream.each(fn {message, _} ->
            Phoenix.Channel.push(socket, socket.topic, message)
          end)
          |> Stream.run()

          {:noreply, socket}
        end
      end
    else
      require Logger
      Logger.warning("DVR Channel not configured, Phoenix.Channel module is not available")
    end
  end
end
