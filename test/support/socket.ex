defmodule DVR.Phoenix.TestSocket do
  use Phoenix.Socket

  channel("phoenix", DVR.Phoenix.TestChannel)

  channel(
    "__absinthe__:*",
    DVR.Absinthe.TestChannel,
    assigns: %{__absinthe_schema__: DVR.Absinthe.TestSchema}
  )

  def connect(_payload, socket), do: {:ok, socket}
  def id(_socket), do: nil
end
