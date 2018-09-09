defmodule DVR.AbsintheChannelTest do
  use ExUnit.Case

  setup do
    :mnesia.clear_table(:dvr)
    DVR.Store.init_store()
    DVR.Store.copy_store()
  end

  @tag :skip
  test "can replay subscription messages" do
  end
end
