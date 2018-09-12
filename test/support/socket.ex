defmodule DVR.Phoenix.TestSocket do
  use Phoenix.Socket
  channel("phoenix", DVR.Phoenix.TestChannel)

  def connect(_payload, socket), do: {:ok, socket}
  def id(_socket), do: nil
end
