# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.HealthController do
  use SchemaWeb, :controller

  def check(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
