defmodule DVR.Phoenix.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :dvr_phoenix
  use Absinthe.Phoenix.Endpoint

  socket(
    "/socket",
    DVR.Phoenix.TestSocket,
    websocket: true
  )

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
end
