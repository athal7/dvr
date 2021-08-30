defmodule DVR.AbsintheChannel do
  @moduledoc """
  An Absinthe channel mixin that handles replaying of recorded messages.
  """

  if Code.ensure_loaded?(Absinthe.Subscription) do
    alias Absinthe.{Phase, Pipeline, Subscription}

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
      |> Subscription.registry_name()
      |> Registry.lookup({self(), doc_id})
      |> Enum.map(fn {_self, field_key} -> field_key end)
    end

    defp docs(socket, topics, doc_id) do
      topics
      |> Enum.flat_map(fn topic ->
        socket.endpoint
        |> Subscription.get(topic)
        |> Enum.filter(fn {id, _doc} -> id == doc_id end)
        |> Enum.map(fn {_id, doc} -> doc end)
      end)
    end

    # From https://github.com/absinthe-graphql/absinthe/blob/master/lib/absinthe/subscription/local.ex#run_docset

    defp resolve(payload, doc) do
      pipeline =
        doc.initial_phases
        |> Pipeline.replace(
          Phase.Telemetry,
          {Phase.Telemetry, event: [:subscription, :publish, :start]}
        )
        |> Pipeline.without(Phase.Subscription.SubscribeSelf)
        |> Pipeline.insert_before(
          Phase.Document.Execution.Resolution,
          {Phase.Document.OverrideRoot, root_value: payload}
        )
        |> Pipeline.upto(Phase.Document.Execution.Resolution)

      pipeline = [
        pipeline,
        [
          Phase.Document.Result,
          {Phase.Telemetry, event: [:subscription, :publish, :stop]}
        ]
      ]

      Pipeline.run(doc.source, pipeline)
    end
  end
end
