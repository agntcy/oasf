# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :schema_server, SchemaWeb.Endpoint,
  http: [port: System.get_env("PORT") || 8000],
  server: false

# Configure the logger to write to a file in test mode
config :logger,
  level: :warning,
  backends: [{LoggerFileBackend, :test_log}]

config :logger, :test_log,
  path: "log/test_#{System.system_time(:millisecond)}.log",
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
