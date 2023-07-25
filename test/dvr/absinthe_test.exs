defmodule DVR.AbsintheTest do
  use DVR.DVRCase
  import Phoenix.ChannelTest
  use Absinthe.Phoenix.SubscriptionTest, schema: DVR.Absinthe.TestSchema

  import Absinthe.Subscription, only: [publish: 3]

  @endpoint DVR.Phoenix.TestEndpoint

  @subscription """
  subscription {
    fooUpdates {
      foo { bar }
      replayId
    }
  }
  """

  setup do
    {:ok, socket} = Phoenix.ChannelTest.connect(DVR.Phoenix.TestSocket, %{})
    {:ok, socket} = join_absinthe(socket)

    {:ok, socket: socket}
  end

  test "can replay messages", %{socket: socket} do
    ref = push_doc(socket, @subscription)
    assert_reply(ref, :ok, %{subscriptionId: subscription_id})

    publish(@endpoint, %{foo: %{bar: "qux"}}, foo_updates: "*")
    assert_push("subscription:data", %{result: %{data: data}})

    assert %{
             "fooUpdates" => %{
               "foo" => %{"bar" => "qux"},
               "replayId" => id
             }
           } = data

    publish(@endpoint, %{foo: %{bar: "corge"}}, foo_updates: "*")
    assert_push("subscription:data", %{result: %{data: data}})

    assert %{
             "fooUpdates" => %{
               "foo" => %{"bar" => "corge"},
               "replayId" => _
             }
           } = data

    push(socket, "replay", %{"replayId" => id, "subscriptionId" => subscription_id})
    assert_push("subscription:data", %{result: %{data: data}})

    assert %{
             "fooUpdates" => %{
               "foo" => %{"bar" => "corge"},
               "replayId" => _
             }
           } = data
  end

  test "resolves with the new doc on replay", %{socket: socket} do
    ref = push_doc(socket, @subscription)
    assert_reply(ref, :ok, %{subscriptionId: _subscription_id})

    publish(@endpoint, %{foo: %{bar: "qux"}}, foo_updates: "*")
    assert_push("subscription:data", %{result: %{data: data}})

    assert %{
             "fooUpdates" => %{
               "foo" => %{"bar" => "qux"},
               "replayId" => id
             }
           } = data

    publish(@endpoint, %{foo: %{bar: "corge", baz: "grault"}}, foo_updates: "*")
    assert_push("subscription:data", %{result: %{data: data}})

    assert %{
             "fooUpdates" => %{
               "foo" => %{"bar" => "corge"},
               "replayId" => _
             }
           } = data

    ref2 =
      push_doc(socket, """
        subscription {
          fooUpdates {
            foo { bar baz }
            replayId
          }
        }
      """)

    assert_reply(ref2, :ok, %{subscriptionId: subscription_id2})

    push(socket, "replay", %{"replayId" => id, "subscriptionId" => subscription_id2})
    assert_push("subscription:data", %{result: %{data: data}})

    assert %{
             "fooUpdates" => %{
               "foo" => %{"bar" => "corge", "baz" => "grault"},
               "replayId" => _
             }
           } = data
  end

  test "warns the client if the requested replay id is not available", %{socket: socket} do
    ref = push_doc(socket, @subscription)
    assert_reply(ref, :ok, %{subscriptionId: subscription_id})

    publish(@endpoint, %{foo: %{bar: "qux"}}, foo_updates: "*")
    assert_push("subscription:data", %{result: %{data: data}})

    assert %{
             "fooUpdates" => %{
               "foo" => %{"bar" => "qux"},
               "replayId" => id
             }
           } = data

    push(socket, "replay", %{"replayId" => 1, "subscriptionId" => subscription_id})
    assert_push("replay:warning", %{"requestedReplayId" => 1, "earliestReplayId" => ^id})
  end
end
