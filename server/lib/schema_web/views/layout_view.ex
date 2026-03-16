# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.LayoutView do
  use SchemaWeb, :view

  def format_profile(profile) do
    Enum.reduce(profile[:attributes], [], fn {name, _}, acc ->
      [Atom.to_string(name) | acc]
    end)
    |> Enum.join("\n")
  end

  def format_extension(extension) do
    caption = "#{extension[:caption]}"
    uid = " [#{extension[:uid]}]"

    case extension[:version] do
      nil ->
        [caption, uid]

      ext_ver ->
        [caption, uid, "</br>", "v", ext_ver]
    end
  end

  def select_versions(_conn) do
    current = Schema.version()

    case Schemas.versions() do
      [] ->
        [
          "<option value='",
          current,
          "' selected=true disabled=true>",
          "#{current}",
          "</option>"
        ]

      versions ->
        Enum.map(versions, fn {version, _path} ->
          [
            "<option value='",
            "/#{version}",
            if version == current do
              "' selected=true disabled=true>"
            else
              "'>"
            end,
            "#{version}",
            "</option>"
          ]
        end)
    end
  end

  def doc_path(conn) do
    # Generate version-aware doc path
    # If accessed via versioned path, use that version, otherwise use current version
    version = extract_version_from_path(conn) || Schema.version()
    "/#{version}/doc"
  end

  defp extract_version_from_path(conn) do
    path_segments = String.split(conn.request_path, "/", trim: true)

    # Check if path starts with a version (e.g., /1.0.0/skills)
    case path_segments do
      [potential_version | _rest] ->
        # Check if it looks like a version (semver format)
        if Regex.match?(~r/^\d+\.\d+\.\d+/, potential_version) do
          potential_version
        else
          nil
        end

      _ ->
        nil
    end
  end
end
