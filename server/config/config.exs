# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

import Config

port = System.get_env("HTTP_PORT") || System.get_env("PORT") || 8080
path = System.get_env("SCHEMA_PATH") || "/"

# Configures the endpoint
config :schema_server, SchemaWeb.Endpoint,
  http: [port: port],
  secret_key_base: "HUvG8AlzaUpVx5PShWbGv6JpifzM/d46Rj3mxAIddA7DJ9qKg6df8sG6PsKXScAh",
  render_errors: [view: SchemaWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Schema.PubSub

# Configures Elixir's Logger
config :logger, :console,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  format: "$date $time [$level] $metadata $message\n",
  metadata: [:request_id, :mfa, :line]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :schema_server, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      router: SchemaWeb.Router,
      endpoint: SchemaWeb.Endpoint
    ]
  }

config :phoenix_swagger, json_library: Jason

# Configures the location of the schema files
config :schema_server, Schema.Application, home: System.get_env("SCHEMA_DIR") || "../schema"
config :schema_server, Schema.Application, extension: System.get_env("SCHEMA_EXTENSION")
config :schema_server, Schema.Application, schema_home: System.get_env("SCHEMA_HOME")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
