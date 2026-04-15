# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemasTest do
  use ExUnit.Case, async: true

  require Logger

  # ---------------------------------------------------------------------------
  # parse_versions/1 — plain list of version strings
  # ---------------------------------------------------------------------------

  describe "parse_versions/1 with version string list" do
    test "parses and sorts a list of version strings" do
      result = Schemas.parse_versions(["2.0.0", "1.0.0", "1.5.0"])
      versions = Enum.map(result, &elem(&1, 0))
      assert versions == ["1.0.0", "1.5.0", "2.0.0"]
    end

    test "skips malformed version strings" do
      result = Schemas.parse_versions(["1.0.0", "not-a-version", "2.0.0"])
      versions = Enum.map(result, &elem(&1, 0))
      assert versions == ["1.0.0", "2.0.0"]
    end

    test "returns empty list for all-malformed input" do
      assert Schemas.parse_versions(["bad", "also-bad"]) == []
    end

    test "returns empty list for empty list" do
      assert Schemas.parse_versions([]) == []
    end

    test "metadata is empty map for plain string entries" do
      [{_v, meta}] = Schemas.parse_versions(["1.0.0"])
      assert meta == %{}
    end
  end

  # ---------------------------------------------------------------------------
  # parse_versions/1 — list of map entries
  # ---------------------------------------------------------------------------

  describe "parse_versions/1 with map entries" do
    test "parses entries with schema_version key" do
      entries = [%{"schema_version" => "1.0.0", "server_version" => "v1"}]
      [{version, meta}] = Schemas.parse_versions(entries)
      assert version == "1.0.0"
      assert meta.server_version == "v1"
    end

    test "parses entries with version key" do
      entries = [%{"version" => "2.0.0", "api_version" => "v2"}]
      [{version, meta}] = Schemas.parse_versions(entries)
      assert version == "2.0.0"
      assert meta.api_version == "v2"
    end

    test "default flag is captured" do
      entries = [%{"schema_version" => "1.0.0", "default" => true}]
      [{_v, meta}] = Schemas.parse_versions(entries)
      assert meta.default == true
    end

    test "default is false when not set to true" do
      entries = [%{"schema_version" => "1.0.0"}]
      [{_v, meta}] = Schemas.parse_versions(entries)
      assert meta.default == false
    end

    test "skips entries with invalid schema_version" do
      entries = [%{"schema_version" => "bad"}, %{"schema_version" => "1.0.0"}]
      result = Schemas.parse_versions(entries)
      assert length(result) == 1
    end

    test "skips entries with no recognised version key" do
      entries = [%{"other_key" => "1.0.0"}, %{"schema_version" => "1.0.0"}]
      result = Schemas.parse_versions(entries)
      assert length(result) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # parse_versions/1 — map with "versions" key
  # ---------------------------------------------------------------------------

  describe "parse_versions/1 with versions-keyed map" do
    test "unwraps versions list from map" do
      result = Schemas.parse_versions(%{"versions" => ["1.0.0", "2.0.0"]})
      assert length(result) == 2
    end
  end

  # ---------------------------------------------------------------------------
  # parse_versions/1 — invalid inputs
  # ---------------------------------------------------------------------------

  describe "parse_versions/1 with invalid input" do
    test "returns empty list for non-list, non-map input" do
      # Disable logging for the current process so Logger.error calls do not
      # write [error] lines to the log file and fail Schema.CompilationTest.
      Logger.disable(self())

      try do
        assert Schemas.parse_versions("bad") == []
        assert Schemas.parse_versions(42) == []
        assert Schemas.parse_versions(nil) == []
      after
        Logger.enable(self())
      end
    end
  end
end
