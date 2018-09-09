defmodule DVR.DummyPhoenixEndpoint do
  use Phoenix.Endpoint, otp_app: :dummy_dvr

  socket("/socket", DVR.DummyPhoenixSocket)
end

defmodule DVR.DummyPhoenixSocket do
  use Phoenix.Socket
  channel("room:lobby", DVR.DummyPhoenixChannel)
  def connect(_payload, socket), do: {:ok, socket}
  def id(_socket), do: nil
end

defmodule DVR.DummyPhoenixChannel do
  use Phoenix.Channel
  use DVR.Channel

  intercept(["new_msg"])

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg", %{body: body})
    {:noreply, socket}
  end

  def handle_out("new_msg", msg, socket) do
    {:ok, id} = DVR.record(msg, [socket.topic])
    push(socket, "new_msg", Map.merge(msg, %{replay_id: id}))
    {:noreply, socket}
  end
end

defmodule DVR.PhoenixChannelTest do
  use ExUnit.Case
  use Phoenix.ChannelTest

  @endpoint DVR.DummyPhoenixEndpoint

  setup do
    :mnesia.clear_table(:dvr)
    DVR.Store.init_store()
    DVR.Store.copy_store()

    {:ok, _, socket} = subscribe_and_join(socket(), DVR.DummyPhoenixChannel, "room:lobby")

    {:ok, socket: socket}
  end

  @tag :skip
  test "can replay messages", %{socket: socket} do
    push(socket, "new_msg", %{"hello" => "all"})
    assert_reply("new_msg", %{body: %{"hello" => "all"}, replay_id: id})

    push(socket, "new_msg", %{"hello" => "some"})
    assert_reply("new_msg", %{body: %{"hello" => "some"}, replay_id: id2})

    push(socket, "replay", %{"replay_id" => id})
    assert_reply("new_msg", %{body: %{"hello" => "some"}, replay_id: id2})
  end
end
