defmodule DVR.Cleanup do
  @moduledoc """
  A process to periodically cleanup stored messages that are older than the configured ttl.
  """

  use Task
  require Logger

  @default_interval 60
  @default_ttl 60 * 60

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(arg) do
    interval = Map.get(arg, :interval_seconds, @default_interval)
    ttl = Map.get(arg, :ttl_seconds, @default_ttl)

    receive do
    after
      interval ->
        count = cleanup(ttl)
        Logger.debug("Cleaned up expired subscription messages", count: count)
        run(%{interval_ms: interval})
    end
  end

  def cleanup(ttl) do
    expired = expired_messages(ttl)
    count = Enum.count(expired)

    for [key, _, _] <- expired do
      :mnesia.transaction(fn -> :mnesia.delete({:dvr, key}) end)
    end

    count
  end

  defp expired_messages(ttl) do
    expired_id_cutoff = DVR.calculate_id() - 1_000_000 * ttl

    {:atomic, result} =
      :mnesia.transaction(fn ->
        :mnesia.select(:dvr, [
          {
            {:dvr, :"$1", :"$2", :"$3"},
            [{:<, :"$1", expired_id_cutoff}],
            [:"$$"]
          }
        ])
      end)

    result
  end
end
