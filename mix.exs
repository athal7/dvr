defmodule DVR.MixProject do
  use Mix.Project

  def project do
    [
      app: :dvr,
      version: "1.0.3",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [main: "readme", extras: ["README.md"]],
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_deps: :transitive]
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
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev, :test], runtime: false},
      {:phoenix, "~> 1.4", optional: true},
      {:absinthe, "~> 1.4.0", optional: true},
      {:absinthe_phoenix, "~> 1.4.0", optional: true}
    ]
  end
end
