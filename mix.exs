defmodule DVR.MixProject do
  use Mix.Project

  def project do
    [
      app: :dvr,
      version: "0.1.4",
      elixir: "~> 1.6",
      docs: [main: "readme", extras: ["README.md"]],
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp package do
    [
      description: "Record and replay your Phoenix channels",
      files: ["lib", "mix.exs", "README.md", ".formatter.exs"],
      maintainers: [
        "Andrew Thal"
      ],
      licenses: ["MIT"],
      links: %{
        GitHub: "https://github.com/athal7/dvr"
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger, :mnesia]
    ]
  end

  defp deps do
    [
      {:mnesiac, "~> 0.2.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev, :test], runtime: false},
      {:phoenix, "~> 1.3.0", optional: true},
      {:absinthe, "~> 1.4.0", optional: true},
      {:absinthe_phoenix, "~> 1.4.0", optional: true}
    ]
  end
end
