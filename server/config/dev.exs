# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :schema_server, SchemaWeb.Endpoint,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Watch static and templates for browser reloading.
config :schema_server, SchemaWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{lib/schema_web/views/.*(ex)$},
      ~r{lib/schema_web/templates/.*(eex|md)$}
    ]
  ]

# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
# config :phoenix, :serve_endpoints, true

config :logger, :console,
  level: :debug,
  format: "[$level] $metadata $message\n",
  metadata: [:mfa, :line]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
