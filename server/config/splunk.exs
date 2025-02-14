import Config

# cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger,
  format: "$time $metadata[$level] $message\n",
  level: :info

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
config :schema_server, SchemaWeb.Endpoint,
  https: [
    port: 443,
    cipher_suite: :strong,
    keyfile: "/etc/ssl/private/splunk-selfsigned.key",
    certfile: "/etc/ssl/certs/splunk-selfsigned.crt"
  ]

#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :schema, SchemaWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases (distillery)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :schema, SchemaWeb.Endpoint, server: true
#
# Note you can't rely on `System.get_env/1` when using releases.
# See the releases documentation accordingly.

# Finally import the config/prod.secret.exs which should be versioned
# separately.
# import_config "prod.secret.exs"
