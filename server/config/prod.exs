import Config

# Do not print debug messages in production
config :logger,
  level: :warning

config :phoenix, :serve_endpoints, true
