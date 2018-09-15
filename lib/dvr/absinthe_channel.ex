defmodule DVR.AbsintheChannel do
  @moduledoc """
  An Absinthe channel mixin that handles replaying of recorded messages.
  """

  if Code.ensure_loaded?(Absinthe.Subscription) do
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

      doc_topics = doc_id_topics(doc_id, socket)

      replay_id
      |> DVR.replay()
      |> Stream.each(fn {payload, topics} ->
        matched_topics = MapSet.intersection(MapSet.new(doc_topics), MapSet.new(topics))

        for doc <- docs(socket, matched_topics, doc_id) do
          {:ok, %{result: data}, _} = resolve(payload, doc)
          Phoenix.Channel.push(socket, "subscription:data", %{result: data})
        end
      end)
      |> Stream.run()

      {:noreply, socket}
    end

    defdelegate handle_in(event, payload, socket), to: Absinthe.Phoenix.Channel

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

    defp resolve(payload, %Absinthe.Blueprint{} = doc) do
      doc.execution.root_value
      |> put_in(payload)
      |> Absinthe.Pipeline.run(@pipeline)
    end
  end
end
