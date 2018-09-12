defmodule DVR.CleanupTest do
  use ExUnit.Case

  setup do
    :mnesia.clear_table(:dvr)
    DVR.Store.init_store()
    DVR.Store.copy_store()
    :ok
  end

  test "cleans up records older than the ttl" do
    ttl = 60 * 60

    now = DateTime.utc_now() |> DateTime.to_unix(:microsecond)
    expired = now - 1_000_000 * ttl * 2
    active = now - 1_000_000 * ttl / 2

    DVR.record(%{}, ['*'], expired)
    DVR.record(%{}, ['*'], active)

    assert {:ok, _} = DVR.search(expired)
    assert {:ok, _} = DVR.search(active)

    DVR.Cleanup.cleanup(ttl)

    assert {:not_found, _} = DVR.search(expired)
    assert {:ok, _} = DVR.search(active)
  end
end
