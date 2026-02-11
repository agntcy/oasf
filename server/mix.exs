# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    build = System.get_env("GITHUB_RUN_NUMBER") || "SNAPSHOT"

    [
      releases: [
        schema_server: [
          steps: [:assemble, :tar, &write_version/1],
          include_executables_for: [:unix]
        ]
      ],
      app: :schema_server,
      version: "#{@version}-#{build}",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers() ++ [:phoenix_swagger],
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.json": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Schema.Application, []},
      extra_applications: [:logger, :crypto, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7"},
      {:number, "~> 1.0"},
      {:elixir_uuid, "~> 1.6", hex: :uuid_utils},
      {:phoenix_swagger, "~> 0.8"},
      {:logger_file_backend, "~> 0.0.13"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  # Write the version number
  defp write_version(rel) do
    case System.argv() do
      ["release" | _] ->
        # Write the version number
        version = Mix.Project.config()[:version]
        File.write(".version", version)

      _ ->
        :ok
    end

    rel
  end
end
