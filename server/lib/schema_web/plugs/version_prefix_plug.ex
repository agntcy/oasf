# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.VersionPrefixPlug do
  @moduledoc """
  Plug that strips version prefixes from API paths for local development.

  In production, ingress handles version prefix rewriting, but locally we need
  to strip the version prefix so routes can match correctly.

  Handles patterns like:
  - /api/VERSION/path -> /api/path
  - /schema/VERSION/path -> /schema/path
  - /export/VERSION/path -> /export/path
  - /sample/VERSION/path -> /sample/path
  """

  import Plug.Conn
  @behaviour Plug

  @version_pattern ~r{^/(api|schema|export|sample)/([\d]+\.[\d]+\.[\d]+(?:-[\w.-]+)?)(/.*|)$}

  def init(opts), do: opts

  def call(conn, _opts) do
    path = conn.request_path

    case Regex.run(@version_pattern, path) do
      [_, prefix, version, rest] ->
        # Strip version prefix and rewrite path
        # Handle case where rest might be empty (e.g., /api/1.1.0-dev)
        new_path = if rest == "", do: "/#{prefix}", else: "/#{prefix}#{rest}"
        path_segments = String.split(new_path, "/", trim: true)

        # Update both request_path and path_info
        # Phoenix uses path_info for routing, so we need to update it
        # Use struct update syntax to properly update Plug.Conn struct
        %{conn | request_path: new_path, path_info: path_segments}
        |> put_private(:api_version, version)

      _ ->
        # No version prefix, pass through unchanged
        conn
    end
  end
end
