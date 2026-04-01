# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.RequestLoggerPlug do
  @moduledoc """
  Request logger plug that keeps probe traffic quieter.

  - Logs health checks at `:debug`
  - Logs all other requests at `:info`
  """

  @behaviour Plug

  @health_paths MapSet.new(["/healthz"])
  @logger_debug_opts Plug.Logger.init(log: :debug)
  @logger_info_opts Plug.Logger.init(log: :info)

  def init(opts), do: opts

  def call(conn, _opts) do
    logger_opts =
      if MapSet.member?(@health_paths, conn.request_path),
        do: @logger_debug_opts,
        else: @logger_info_opts

    Plug.Logger.call(conn, logger_opts)
  end
end
