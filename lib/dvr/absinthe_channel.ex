defmodule DVR.AbsintheChannel do
  @moduledoc """
  An Absinthe channel mixin that handles replaying of recorded messages.
  """

  @required_modules [
    Absinthe,
    Absinthe.Subscription,
    Phoenix.Channel
  ]
  defmacro __using__(_opts) do
    if Enum.all?(@required_modules, &Code.ensure_loaded?/1) do
      quote do
        @pipeline [
          Absinthe.Phase.Document.Execution.Resolution,
          Absinthe.Phase.Document.Result
        ]

        def handle_in("replay", %{"replayId" => replay_id, "subscriptionId" => doc_id}, socket) do
          case DVR.search(replay_id) do
            {:ok, _} ->
              nil

            {:not_found, earliest_id} ->
              Phoenix.Channel.push(socket, "replay:warning", %{
                "requestedReplayId" => replay_id,
                "earliestReplayId" => earliest_id
              })
          end

          topics = doc_id_topics(doc_id, socket)

          # TODO utilize stream
          for message <- DVR.replay(replay_id, topics) do
            for doc <- docs(socket, message.topics, doc_id) do
              {:ok, %{result: data}, _} = resolve(message.payload, doc)
              Phoenix.Channel.push(socket, "subscription:data", %{result: data})
            end
          end

          {:noreply, socket}
        end

        defp doc_id_topics(doc_id, socket) do
          socket.endpoint
          |> Absinthe.Subscription.registry_name()
          |> Registry.lookup({self(), doc_id})
          |> Enum.map(fn {_self, field_key} -> field_key end)
        end

        defp docs(socket, topics, doc_id) do
          topics
          |> Enum.flat_map(fn topic ->
            socket.endpoint
            |> Absinthe.Subscription.get(topic)
            |> Enum.filter(fn {id, _doc} -> id == doc_id end)
            |> Enum.map(fn {_id, doc} -> doc end)
          end)
        end

        defp resolve(%Message{payload: payload}, %Absinthe.Blueprint{} = doc) do
          doc.execution.root_value
          |> put_in(payload)
          |> Absinthe.Pipeline.run(@pipeline)
        end
      end
    end
  else
    _ ->
      require Logger

      Logger.warn(
        "DVR Absinthe Channel not configured, not all modules are available",
        modules: Enum.map(@required_modules, &Code.ensure_loaded/1)
      )
  end
end
