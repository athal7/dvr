defmodule DVR.MixProject do
  use Mix.Project

  def project do
    [
      app: :dvr,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :mnesia]
    ]
  end

  defp deps do
    [
      {:mnesiac, "~> 0.2.0"}
    ]
  end
end
