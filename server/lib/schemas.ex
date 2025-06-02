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
    # Split the string by commas into a list
    parsed_versions = String.split(schema_versions, ",")
    IO.inspect(parsed_versions, label: "Parsed schema versions")
    Agent.start_link(fn -> parse_versions(parsed_versions) end, name: __MODULE__)
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
  @spec parse_versions(any()) :: list({String.t(), map()})
  def parse_versions(%{"versions" => versions}) when is_list(versions) do
    # Transform each version into a tuple {version, metadata}
    Enum.map(versions, fn version -> {version, %{}} end)
  end

  def parse_versions(versions) when is_list(versions) do
    # Assume the input is already a list of version strings
    Enum.map(versions, fn version -> {version, %{}} end)
  end

  def parse_versions(_invalid_data) do
    Logger.error(
      "Invalid schema versions provided. Expected a list or a map with a 'versions' key."
    )

    []
  end
end
