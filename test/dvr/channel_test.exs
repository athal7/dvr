defmodule DVR.PhoenixChannelTest do
  use DVR.DVRCase
  use Phoenix.ChannelTest

  @endpoint DVR.Phoenix.TestEndpoint

  setup do
    {:ok, _, socket} =
      socket("asdf", [])
      |> subscribe_and_join(DVR.Phoenix.TestChannel, "phoenix")

    {:ok, socket: socket}
  end

  test "can replay messages", %{socket: socket} do
    push(socket, "new_msg", %{"hello" => "all"})
    assert_broadcast("phoenix", %{"hello" => "all", replay_id: id})

    push(socket, "new_msg", %{"hello" => "some"})
    assert_broadcast("phoenix", %{"hello" => "some", replay_id: id2})

    push(socket, "replay", %{"replay_id" => id})
    assert_push("phoenix", %{"hello" => "some"})
  end

  test "warns the client if the requested replay id is not available", %{socket: socket} do
    push(socket, "new_msg", %{"hello" => "all"})
    assert_broadcast("phoenix", %{"hello" => "all", replay_id: id})

    push(socket, "replay", %{"replay_id" => 1})
    assert_push("replay:warning", %{"requested_replay_id" => 1, "earliest_replay_id" => id})
  end
end
