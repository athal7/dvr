defmodule DVR do
  @moduledoc """
  Documentation for Dvr.
  """

  @type replay_id() :: integer()
  @type payload() :: any()
  @type topics() :: list(String.t())

  require Logger

  @spec record(payload(), topics()) :: {:ok, replay_id()} | {:error, any()}
  def record(payload, topics), do: record(payload, topics, calculate_id())

  def record(payload, topics, id) do
    write = fn -> :mnesia.write({:dvr, id, payload, topics}) end

    case :mnesia.transaction(write) do
      {:atomic, _} ->
        {:ok, id}

      err ->
        {:error, err}
    end
  end

  @spec replay(replay_id()) :: {:ok, list(tuple)} | {:error, any()}
  def replay(id) do
    select = fn ->
      :mnesia.select(:dvr, [
        {
          {:dvr, :"$1", :"$2", :"$3"},
          [{:>, :"$1", id}],
          [:"$$"]
        }
      ])
    end

    case :mnesia.transaction(select) do
      {:atomic, result} ->
        Stream.map(result, fn [_, payload, topics] -> {payload, topics} end)

      err ->
        {:error, err}
    end
  end

  @spec search(replay_id()) :: {:ok, replay_id()} | {:not_found, replay_id()}
  def search(id) do
    read = fn -> :mnesia.read({:dvr, id}) end

    case :mnesia.transaction(read) do
      {:atomic, []} ->
        case :mnesia.transaction(fn -> :mnesia.first(:dvr) end) do
          {:atomic, earliest_id} ->
            {:not_found, earliest_id}

          err ->
            {:error, err}
        end

      {:atomic, _} ->
        {:ok, id}

      err ->
        {:error, err}
    end
  end

  @spec calculate_id() :: replay_id()
  def calculate_id, do: DateTime.utc_now() |> DateTime.to_unix(:microsecond)
end
