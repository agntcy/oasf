# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schemas do
  @moduledoc """
  This module provides functions to work with multiple schema versions.
  """

  use Agent

  require Logger

  def start_link(nil) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def start_link(schema_versions) do
    Agent.start_link(fn -> parse_versions_input(schema_versions) end, name: __MODULE__)
  end

  @doc """
  Returns a list of available schemas.
  Returns {:ok, list(map())}.
  """
  def versions do
    Agent.get(__MODULE__, & &1)
  end

  @doc """
  Parses the schema versions from the provided content.
  Expects a list of versions or a map with a "versions" key.
  Returns a list of {version, metadata} tuples in case of success, or an empty list if the content is invalid.
  """
  def parse_versions(%{"versions" => versions}) when is_list(versions),
    do: parse_versions(versions)

  def parse_versions(versions) when is_list(versions) do
    versions
    |> Enum.map(&normalize_version_entry/1)
    |> Enum.filter(& &1)
    |> Enum.sort(fn {_v1, p1, _m1}, {_v2, p2, _m2} -> Schema.Utils.version_sorter(p1, p2) end)
    |> Enum.map(fn {schema_version, _parsed, metadata} -> {schema_version, metadata} end)
  end

  def parse_versions(_invalid_data) do
    Logger.error(
      "Invalid schema versions provided. Expected a list or a map with a 'versions' key."
    )

    []
  end

  defp parse_versions_input(schema_versions) when is_binary(schema_versions) do
    case Jason.decode(schema_versions) do
      {:ok, decoded} ->
        parse_versions(decoded)

      {:error, _reason} ->
        schema_versions
        |> String.split(",", trim: true)
        |> Enum.map(&String.trim/1)
        |> parse_versions()
    end
  end

  defp parse_versions_input(_), do: []

  defp normalize_version_entry(version) when is_binary(version) do
    case Schema.Utils.parse_version(version) do
      parsed when is_map(parsed) -> {version, parsed, %{}}
      _error -> nil
    end
  end

  defp normalize_version_entry(%{"schema_version" => schema_version} = entry) do
    normalize_version_entry_with_metadata(schema_version, entry)
  end

  defp normalize_version_entry(%{"version" => schema_version} = entry) do
    normalize_version_entry_with_metadata(schema_version, entry)
  end

  defp normalize_version_entry(_), do: nil

  defp normalize_version_entry_with_metadata(schema_version, entry) do
    case Schema.Utils.parse_version(schema_version) do
      parsed when is_map(parsed) ->
        {schema_version, parsed,
         %{
           server_version: entry["server_version"],
           api_version: entry["api_version"]
         }}

      _error ->
        nil
    end
  end
end
