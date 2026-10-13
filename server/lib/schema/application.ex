# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    env = Application.get_env(:schema_server, __MODULE__)

    schema_dir = Keyword.get(env, :home)
    schema_versions = Keyword.get(env, :schema_versions)

    extensions = parse_extensions(Keyword.get(env, :extension))

    # List all child processes to be supervised
    children = [
      {Schemas, schema_versions},
      {Schema.JsonReader, [schema_dir, extensions]},
      Schema.Repo,
      Schema.Generator,

      # Start the endpoint when the application starts
      SchemaWeb.Endpoint,
      {Phoenix.PubSub, [name: Schema.PubSub, adapter: Phoenix.PubSub.PG2]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Schema.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SchemaWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # A blank SCHEMA_EXTENSION means no extensions. Passing "" through would resolve to
  # SCHEMA_DIR itself and load every extension found anywhere under it.
  @doc false
  @spec parse_extensions(String.t() | nil) :: [String.t()]
  def parse_extensions(nil), do: []

  def parse_extensions(ext) do
    ext
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
