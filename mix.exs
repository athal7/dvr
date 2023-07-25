defmodule DVR.MixProject do
  use Mix.Project

  def project do
    [
      app: :dvr,
      version: "1.1.1",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [main: "readme", extras: ["README.md"]],
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_deps: :transitive
      ]
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :mnesia]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 1.3.0", only: [:dev, :test], runtime: false},
      {:phoenix, "~> 1.7", optional: true},
      {:absinthe, "~> 1.7", optional: true},
      {:absinthe_phoenix, "~> 2.0", optional: true},
      {:jason, "~> 1.0", only: [:dev, :test]}
    ]
  end
end
