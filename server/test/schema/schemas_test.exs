defmodule SchemasTest do
  use ExUnit.Case

  test "parse_versions parses CSV-style string list" do
    versions = Schemas.parse_versions(["0.7.0", "1.1.0-dev"])

    assert {"0.7.0", %{}} in versions
    assert {"1.1.0-dev", %{}} in versions
  end

  test "parse_versions parses JSON-style metadata entries" do
    versions =
      Schemas.parse_versions(%{
        "versions" => [
          %{
            "schema_version" => "0.8.0",
            "server_version" => "v0.8.3",
            "api_version" => "0.5.1"
          },
          %{
            "schema_version" => "1.0.0",
            "server_version" => "v1.0.0",
            "api_version" => "0.5.2"
          }
        ]
      })

    assert {"0.8.0", %{server_version: "v0.8.3", api_version: "0.5.1"}} in versions
    assert {"1.0.0", %{server_version: "v1.0.0", api_version: "0.5.2"}} in versions
  end
end
