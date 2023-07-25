import Config

config :logger, level: :warning

config :dvr_phoenix, DVR.Phoenix.TestEndpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "GSGmIoMRxcLfHBfBhtD/Powy7WaucKbLuB7BTMt41nkm5xS+8LfnXZYNsk6qKOo1",
  render_errors: [accepts: ~w(json)],
  pubsub_server: DVR.Phoenix.PubSub
