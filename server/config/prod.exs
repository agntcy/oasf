# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

import Config

# Do not print debug messages in production
config :logger,
  level: :warning

config :phoenix, :serve_endpoints, true
