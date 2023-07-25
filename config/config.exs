import Config

env_config = Path.expand("#{config_env()}.exs", __DIR__)

if File.exists?(env_config) do
  import_config(env_config)
end
