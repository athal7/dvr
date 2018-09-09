defmodule DVR.Store do
  @moduledoc """
  Mnesia table for replay storage.
  """

  require Record

  Record.defrecord(
    :dvr_message,
    :dvr,
    replay_id: nil,
    message: nil,
    channels: nil
  )

  @type dvr_message ::
          record(
            :dvr_message,
            replay_id: integer(),
            message: map(),
            channels: list(String.t())
          )

  @doc """
  Mnesiac will call this method to initialize the table
  """
  def init_store do
    :mnesia.create_table(
      :dvr,
      attributes: dvr_message() |> dvr_message() |> Keyword.keys()
      # TODO configure disc vs memory
      # disc_copies: [Node.self()]
    )
  end

  @doc """
  Mnesiac will call this method to copy the table
  """
  def copy_store do
    # TODO configure disc vs memory
    :mnesia.add_table_copy(:dvr, Node.self(), :disc_copies)
  end
end
