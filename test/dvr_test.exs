defmodule DVR.DvrTest do
  use ExUnit.Case

  setup do
    :mnesia.clear_table(:dvr)
    DVR.Store.init_store()
    DVR.Store.copy_store()
    :ok
  end

  test "can replay messages" do
    pre_id = DVR.calculate_id()

    message1 = %{foo: "bar"}
    message2 = %{baz: "quz"}
    topics = ["*"]

    {:ok, id1} = DVR.record(message1, topics)
    {:ok, id2} = DVR.record(message2, topics)

    assert {message1, topics} in Enum.to_list(DVR.replay(pre_id))
    assert {message2, topics} in Enum.to_list(DVR.replay(pre_id))

    assert Enum.to_list(DVR.replay(id1)) == [{message2, topics}]
    assert Enum.to_list(DVR.replay(id2)) == []
  end
end
