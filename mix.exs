defmodule Spector.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://github.com/flowy/spector"

  def project do
    [
      app: :spector,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Tests
      test_coverage: [tool: ExCoveralls],

      # Hex
      package: package(),
      description: "A tiny library for validating and documenting specs",

      # Docs
      name: "Spector",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # excoverals uses CAStore to push results via HTTP.
      {:castore, "~> 1.0.0", only: :test},
      {:ex_doc, ">= 0.19.0", only: :dev},
      {:excoveralls, "~> 0.18.0", only: :test},
      {:yaml_elixir, "~> 2.9"}
    ]
  end

  defp package do
    [
      maintainers: ["Emiliano Jankowski"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  defp docs do
    [
      main: "Spector",
      logo: "assets/logo-small.png",
      extras: [
        "LICENSE.md": [title: "License"]
      ],
      source_ref: "v#{@version}",
      source_url: @repo_url,
      formatters: ["html"]
    ]
  end
end
