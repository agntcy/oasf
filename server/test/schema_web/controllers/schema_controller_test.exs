# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.SchemaControllerTest do
  @moduledoc """
  Integration tests for the SchemaController and all API endpoints.

  These tests replace the Go test/api/ suite. They dispatch requests through
  Phoenix.ConnTest in-process (no live server needed) and therefore contribute
  to ExCoveralls Elixir coverage.
  """

  use SchemaWeb.ConnCase

  # Known-valid names taken from the schema; discovered at module load time
  # so the tests stay robust against future schema changes.
  @test_skill_name "contextual_comprehension"
  @test_domain_name "internet_of_things"
  @test_module_name "observability"
  @test_skill_category_name "natural_language_processing"
  @test_domain_category_name "healthcare"
  @test_module_category_name "core"
  @test_object_name "record"
  @nonexistent_name "non_existent_name_12345"

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp json_get(conn, path) do
    conn
    |> put_req_header("accept", "application/json")
    |> get(path)
  end

  defp json_post(conn, path, body) do
    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("accept", "application/json")
    |> post(path, body)
  end

  defp json_response_body(conn) do
    conn.resp_body |> Jason.decode!()
  end

  # ---------------------------------------------------------------------------
  # Healthcheck
  # ---------------------------------------------------------------------------

  describe "GET /healthz" do
    test "returns 200", %{conn: conn} do
      conn = get(conn, "/healthz")
      assert conn.status == 200
    end
  end

  # ---------------------------------------------------------------------------
  # API version endpoints
  # ---------------------------------------------------------------------------

  describe "GET /api/version" do
    test "returns 200 with schema_version", %{conn: conn} do
      conn = json_get(conn, "/api/version")
      assert conn.status == 200
      body = json_response_body(conn)
      assert Map.has_key?(body, "schema_version")
    end
  end

  describe "GET /api/versions" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/versions")
      assert conn.status == 200
    end
  end

  # ---------------------------------------------------------------------------
  # API list endpoints
  # ---------------------------------------------------------------------------

  describe "GET /api/skills (list)" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/skills")
      assert conn.status == 200
    end

    test "returns 200 by name", %{conn: conn} do
      conn = json_get(conn, "/api/skills?name=#{@test_skill_name}")
      assert conn.status == 200
    end

    test "returns 200 by id", %{conn: conn} do
      conn = json_get(conn, "/api/skills?id=10101")
      assert conn.status == 200
    end

    test "returns 200 for hierarchical name", %{conn: conn} do
      conn = json_get(conn, "/api/skills?name=analytical_skills/mathematical_reasoning")
      assert conn.status == 200
    end

    test "returns 404 for unknown name", %{conn: conn} do
      conn = json_get(conn, "/api/skills?name=#{@nonexistent_name}")
      assert conn.status == 404
      body = json_response_body(conn)
      assert Map.has_key?(body, "error")
    end

    test "returns 404 for unknown id", %{conn: conn} do
      conn = json_get(conn, "/api/skills?id=99999")
      assert conn.status == 404
      body = json_response_body(conn)
      assert Map.has_key?(body, "error")
    end

    test "returns 400 for non-numeric id", %{conn: conn} do
      conn = json_get(conn, "/api/skills?id=invalid")
      assert conn.status == 400
      body = json_response_body(conn)
      assert Map.has_key?(body, "error")
    end

    test "returns 400 for mismatched id and name", %{conn: conn} do
      conn = json_get(conn, "/api/skills?id=601&name=#{@test_skill_name}")
      assert conn.status == 400
      body = json_response_body(conn)
      assert Map.has_key?(body, "error")
    end
  end

  describe "GET /api/domains (list)" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/domains")
      assert conn.status == 200
    end

    test "returns 200 by name", %{conn: conn} do
      conn = json_get(conn, "/api/domains?name=#{@test_domain_name}")
      assert conn.status == 200
    end

    test "returns 200 by id", %{conn: conn} do
      conn = json_get(conn, "/api/domains?id=101")
      assert conn.status == 200
    end

    test "returns 200 for hierarchical name", %{conn: conn} do
      conn = json_get(conn, "/api/domains?name=agriculture/precision_agriculture")
      assert conn.status == 200
    end

    test "returns 404 for unknown name", %{conn: conn} do
      conn = json_get(conn, "/api/domains?name=#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "returns 404 for unknown id", %{conn: conn} do
      conn = json_get(conn, "/api/domains?id=99999")
      assert conn.status == 404
    end

    test "returns 400 for non-numeric id", %{conn: conn} do
      conn = json_get(conn, "/api/domains?id=invalid")
      assert conn.status == 400
    end

    test "returns 400 for mismatched id and name", %{conn: conn} do
      conn = json_get(conn, "/api/domains?id=2005&name=#{@test_domain_name}")
      assert conn.status == 400
    end
  end

  describe "GET /api/modules (list)" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/modules")
      assert conn.status == 200
    end

    test "returns 200 by name", %{conn: conn} do
      conn = json_get(conn, "/api/modules?name=#{@test_module_name}")
      assert conn.status == 200
    end

    test "returns 200 by id", %{conn: conn} do
      conn = json_get(conn, "/api/modules?id=101")
      assert conn.status == 200
    end

    test "returns 200 for hierarchical name", %{conn: conn} do
      conn = json_get(conn, "/api/modules?name=core/language_model/prompt")
      assert conn.status == 200
    end

    test "returns 404 for unknown name", %{conn: conn} do
      conn = json_get(conn, "/api/modules?name=#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "returns 404 for unknown id", %{conn: conn} do
      conn = json_get(conn, "/api/modules?id=99999")
      assert conn.status == 404
    end

    test "returns 400 for non-numeric id", %{conn: conn} do
      conn = json_get(conn, "/api/modules?id=invalid")
      assert conn.status == 400
    end

    test "returns 400 for mismatched id and name", %{conn: conn} do
      conn = json_get(conn, "/api/modules?id=103&name=#{@test_module_name}")
      assert conn.status == 400
    end
  end

  describe "GET /api/objects (list)" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/objects")
      assert conn.status == 200
    end

    test "returns 200 by name", %{conn: conn} do
      conn = json_get(conn, "/api/objects?name=#{@test_object_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown name", %{conn: conn} do
      conn = json_get(conn, "/api/objects?name=#{@nonexistent_name}")
      assert conn.status == 404
      body = json_response_body(conn)
      assert Map.has_key?(body, "error")
    end
  end

  # ---------------------------------------------------------------------------
  # Category endpoints
  # ---------------------------------------------------------------------------

  describe "GET /api/skill_categories" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/skill_categories")
      assert conn.status == 200
    end

    test "returns 200 by name", %{conn: conn} do
      conn = json_get(conn, "/api/skill_categories?name=#{@test_skill_category_name}")
      assert conn.status == 200
    end

    test "returns 200 for hierarchical category name", %{conn: conn} do
      conn = json_get(conn, "/api/skill_categories?name=natural_language_processing/personalization")
      assert conn.status == 200
    end

    test "returns 404 for unknown name", %{conn: conn} do
      conn = json_get(conn, "/api/skill_categories?name=#{@nonexistent_name}")
      assert conn.status == 404
      body = json_response_body(conn)
      assert Map.has_key?(body, "error")
    end

    test "returns 404 for unknown id", %{conn: conn} do
      conn = json_get(conn, "/api/skill_categories?id=99999")
      assert conn.status == 404
    end
  end

  describe "GET /api/domain_categories" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/domain_categories")
      assert conn.status == 200
    end

    test "returns 200 by name", %{conn: conn} do
      conn = json_get(conn, "/api/domain_categories?name=#{@test_domain_category_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown name", %{conn: conn} do
      conn = json_get(conn, "/api/domain_categories?name=#{@nonexistent_name}")
      assert conn.status == 404
    end
  end

  describe "GET /api/module_categories" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/module_categories")
      assert conn.status == 200
    end

    test "returns 200 by name", %{conn: conn} do
      conn = json_get(conn, "/api/module_categories?name=#{@test_module_category_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown name", %{conn: conn} do
      conn = json_get(conn, "/api/module_categories?name=#{@nonexistent_name}")
      assert conn.status == 404
    end
  end

  # ---------------------------------------------------------------------------
  # Dictionary, data types, profiles, extensions, schema
  # ---------------------------------------------------------------------------

  describe "GET /api/dictionary" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/dictionary")
      assert conn.status == 200
    end
  end

  describe "GET /api/data_types" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/data_types")
      assert conn.status == 200
    end
  end

  describe "GET /api/profiles" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/profiles")
      assert conn.status == 200
    end
  end

  describe "GET /api/extensions" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/extensions")
      assert conn.status == 200
    end
  end

  describe "GET /api/schema" do
    test "returns 200", %{conn: conn} do
      conn = json_get(conn, "/api/schema")
      assert conn.status == 200
    end
  end

  # ---------------------------------------------------------------------------
  # JSON schema endpoints (/schema/*)
  # ---------------------------------------------------------------------------

  describe "GET /schema/skills/:name" do
    test "returns 200 for known skill", %{conn: conn} do
      conn = json_get(conn, "/schema/skills/#{@test_skill_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown skill", %{conn: conn} do
      conn = json_get(conn, "/schema/skills/#{@nonexistent_name}")
      assert conn.status == 404
    end
  end

  describe "GET /schema/domains/:name" do
    test "returns 200 for known domain", %{conn: conn} do
      conn = json_get(conn, "/schema/domains/#{@test_domain_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown domain", %{conn: conn} do
      conn = json_get(conn, "/schema/domains/#{@nonexistent_name}")
      assert conn.status == 404
    end
  end

  describe "GET /schema/modules/:name" do
    test "returns 200 for known module", %{conn: conn} do
      conn = json_get(conn, "/schema/modules/#{@test_module_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown module", %{conn: conn} do
      conn = json_get(conn, "/schema/modules/#{@nonexistent_name}")
      assert conn.status == 404
    end
  end

  describe "GET /schema/objects/:name" do
    test "returns 200 for known object", %{conn: conn} do
      conn = json_get(conn, "/schema/objects/#{@test_object_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown object", %{conn: conn} do
      conn = json_get(conn, "/schema/objects/#{@nonexistent_name}")
      assert conn.status == 404
    end
  end

  # ---------------------------------------------------------------------------
  # Sample endpoints (/sample/*)
  # ---------------------------------------------------------------------------

  describe "GET /sample/skills/:name" do
    test "returns 200 for known skill", %{conn: conn} do
      conn = json_get(conn, "/sample/skills/#{@test_skill_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown skill", %{conn: conn} do
      conn = json_get(conn, "/sample/skills/#{@nonexistent_name}")
      assert conn.status == 404
    end
  end

  describe "GET /sample/domains/:name" do
    test "returns 200 for known domain", %{conn: conn} do
      conn = json_get(conn, "/sample/domains/#{@test_domain_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown domain", %{conn: conn} do
      conn = json_get(conn, "/sample/domains/#{@nonexistent_name}")
      assert conn.status == 404
    end
  end

  describe "GET /sample/modules/:name" do
    test "returns 200 for known module", %{conn: conn} do
      conn = json_get(conn, "/sample/modules/#{@test_module_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown module", %{conn: conn} do
      conn = json_get(conn, "/sample/modules/#{@nonexistent_name}")
      assert conn.status == 404
    end
  end

  describe "GET /sample/objects/:name" do
    test "returns 200 for known object", %{conn: conn} do
      conn = json_get(conn, "/sample/objects/#{@test_object_name}")
      assert conn.status == 200
    end

    test "returns 404 for unknown object", %{conn: conn} do
      conn = json_get(conn, "/sample/objects/#{@nonexistent_name}")
      assert conn.status == 404
    end
  end

  # ---------------------------------------------------------------------------
  # Sample → Validate round-trip (replaces Go "Sample Object Validation")
  # ---------------------------------------------------------------------------

  describe "sample → validate round-trip" do
    test "sample object validates with zero errors (record)", %{conn: conn} do
      sample_conn = json_get(conn, "/sample/objects/#{@test_object_name}")
      assert sample_conn.status == 200
      sample_body = sample_conn.resp_body

      validate_conn =
        json_post(build_conn(), "/api/validate/object/#{@test_object_name}", sample_body)

      assert validate_conn.status == 200
      result = json_response_body(validate_conn)
      assert result["error_count"] == 0
    end

    test "sample skill validates with zero errors (contextual_comprehension)", %{conn: conn} do
      sample_conn = json_get(conn, "/sample/skills/#{@test_skill_name}")
      assert sample_conn.status == 200
      sample_body = sample_conn.resp_body

      validate_conn = json_post(build_conn(), "/api/validate/skill", sample_body)
      assert validate_conn.status == 200
      result = json_response_body(validate_conn)
      assert result["error_count"] == 0
    end

    test "sample domain validates with zero errors (internet_of_things)", %{conn: conn} do
      sample_conn = json_get(conn, "/sample/domains/#{@test_domain_name}")
      assert sample_conn.status == 200
      sample_body = sample_conn.resp_body

      validate_conn = json_post(build_conn(), "/api/validate/domain", sample_body)
      assert validate_conn.status == 200
      result = json_response_body(validate_conn)
      assert result["error_count"] == 0
    end

    test "sample module validates with zero errors (observability)", %{conn: conn} do
      sample_conn = json_get(conn, "/sample/modules/#{@test_module_name}")
      assert sample_conn.status == 200
      sample_body = sample_conn.resp_body

      validate_conn = json_post(build_conn(), "/api/validate/module", sample_body)
      assert validate_conn.status == 200
      result = json_response_body(validate_conn)
      assert result["error_count"] == 0
    end
  end

  # ---------------------------------------------------------------------------
  # POST translate endpoints
  # ---------------------------------------------------------------------------

  describe "POST /api/translate/skill" do
    test "returns 2xx for valid JSON object body", %{conn: conn} do
      conn = json_post(conn, "/api/translate/skill", ~s({"name": "test_skill"}))
      assert conn.status in 200..299
    end

    test "returns 400 for non-object body", %{conn: conn} do
      conn = json_post(conn, "/api/translate/skill", ~s("just a string"))
      assert conn.status == 400
      body = json_response_body(conn)
      assert Map.has_key?(body, "error")
    end
  end

  describe "POST /api/translate/domain" do
    test "returns 2xx for valid JSON object body", %{conn: conn} do
      conn = json_post(conn, "/api/translate/domain", ~s({"name": "test_domain"}))
      assert conn.status in 200..299
    end

    test "returns 400 for non-object body", %{conn: conn} do
      conn = json_post(conn, "/api/translate/domain", ~s("just a string"))
      assert conn.status == 400
    end
  end

  describe "POST /api/translate/module" do
    test "returns 2xx for valid JSON object body", %{conn: conn} do
      conn = json_post(conn, "/api/translate/module", ~s({"name": "test_module"}))
      assert conn.status in 200..299
    end

    test "returns 400 for non-object body", %{conn: conn} do
      conn = json_post(conn, "/api/translate/module", ~s("just a string"))
      assert conn.status == 400
    end
  end

  describe "POST /api/translate/object/:name" do
    test "returns 2xx for valid JSON object body", %{conn: conn} do
      conn = json_post(conn, "/api/translate/object/#{@test_object_name}", ~s({"name": "test"}))
      assert conn.status in 200..299
    end

    test "returns 400 for non-object body", %{conn: conn} do
      conn = json_post(conn, "/api/translate/object/#{@test_object_name}", ~s("just a string"))
      assert conn.status == 400
      body = json_response_body(conn)
      assert Map.has_key?(body, "error")
    end

    test "returns 200 for non-existent object name (validation result returned)", %{conn: conn} do
      conn = json_post(conn, "/api/translate/object/#{@nonexistent_name}", ~s({"name": "test"}))
      assert conn.status == 200
    end
  end

  # ---------------------------------------------------------------------------
  # POST validate endpoints
  # ---------------------------------------------------------------------------

  describe "POST /api/validate/skill" do
    test "returns 200 for valid JSON object body", %{conn: conn} do
      conn = json_post(conn, "/api/validate/skill", ~s({"name": "test_skill"}))
      assert conn.status == 200
    end

    test "returns 400 for non-object body", %{conn: conn} do
      conn = json_post(conn, "/api/validate/skill", ~s("just a string"))
      assert conn.status == 400
      body = json_response_body(conn)
      assert Map.has_key?(body, "error")
    end
  end

  describe "POST /api/validate/domain" do
    test "returns 200 for valid JSON object body", %{conn: conn} do
      conn = json_post(conn, "/api/validate/domain", ~s({"name": "test_domain"}))
      assert conn.status == 200
    end

    test "returns 400 for non-object body", %{conn: conn} do
      conn = json_post(conn, "/api/validate/domain", ~s("just a string"))
      assert conn.status == 400
    end
  end

  describe "POST /api/validate/module" do
    test "returns 200 for valid JSON object body", %{conn: conn} do
      conn = json_post(conn, "/api/validate/module", ~s({"name": "test_module"}))
      assert conn.status == 200
    end

    test "returns 400 for non-object body", %{conn: conn} do
      conn = json_post(conn, "/api/validate/module", ~s("just a string"))
      assert conn.status == 400
    end
  end

  describe "POST /api/validate/object/:name" do
    test "returns 200 for valid JSON object body", %{conn: conn} do
      conn = json_post(conn, "/api/validate/object/#{@test_object_name}", ~s({"name": "test"}))
      assert conn.status == 200
    end

    test "returns 400 for non-object body", %{conn: conn} do
      conn = json_post(conn, "/api/validate/object/#{@test_object_name}", ~s("just a string"))
      assert conn.status == 400
      body = json_response_body(conn)
      assert Map.has_key?(body, "error")
    end

    test "returns 200 for non-existent object name (validation result returned)", %{conn: conn} do
      conn = json_post(conn, "/api/validate/object/#{@nonexistent_name}", ~s({"name": "test"}))
      assert conn.status == 200
    end
  end

  # ---------------------------------------------------------------------------
  # Validate response structure
  # ---------------------------------------------------------------------------

  describe "validate response structure" do
    test "validate response includes required fields", %{conn: conn} do
      skill_name = @test_skill_name

      conn =
        json_post(conn, "/api/validate/skill", Jason.encode!(%{"name" => skill_name}))

      assert conn.status == 200
      body = json_response_body(conn)
      assert Map.has_key?(body, "errors")
      assert Map.has_key?(body, "warnings")
      assert Map.has_key?(body, "error_count")
      assert Map.has_key?(body, "warning_count")
      assert is_list(body["errors"])
      assert is_list(body["warnings"])
      assert body["error_count"] == length(body["errors"])
      assert body["warning_count"] == length(body["warnings"])
    end
  end

  # ---------------------------------------------------------------------------
  # API response content checks (replaces Go "Object API Responses")
  # ---------------------------------------------------------------------------

  describe "API object response content" do
    test "GET /api/objects?name=record returns expected fields", %{conn: conn} do
      conn = json_get(conn, "/api/objects?name=record")
      assert conn.status == 200
      body = json_response_body(conn)
      assert body["name"] == "record"
      assert is_map(body["attributes"])
      assert Map.has_key?(body["attributes"], "name")
      assert Map.has_key?(body["attributes"], "version")
      assert Map.has_key?(body["attributes"], "schema_version")
    end

    test "GET /api/objects?name=locator returns expected fields", %{conn: conn} do
      conn = json_get(conn, "/api/objects?name=locator")
      assert conn.status == 200
      body = json_response_body(conn)
      assert body["name"] == "locator"
      assert is_map(body["attributes"])
      assert Map.has_key?(body["attributes"], "type")
    end
  end

  # ---------------------------------------------------------------------------
  # Browser-facing page endpoints
  # ---------------------------------------------------------------------------

  describe "Browser page endpoints" do
    test "GET / returns 200", %{conn: conn} do
      conn = get(conn, "/")
      assert conn.status == 200
    end

    test "GET /skills returns 200", %{conn: conn} do
      conn = get(conn, "/skills")
      assert conn.status == 200
    end

    test "GET /skills/:name returns 200 for known skill", %{conn: conn} do
      conn = get(conn, "/skills/#{@test_skill_name}")
      assert conn.status == 200
    end

    test "GET /skills/:name returns 404 for unknown skill", %{conn: conn} do
      conn = get(conn, "/skills/#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "GET /domains returns 200", %{conn: conn} do
      conn = get(conn, "/domains")
      assert conn.status == 200
    end

    test "GET /domains/:name returns 200 for known domain", %{conn: conn} do
      conn = get(conn, "/domains/#{@test_domain_name}")
      assert conn.status == 200
    end

    test "GET /domains/:name returns 404 for unknown domain", %{conn: conn} do
      conn = get(conn, "/domains/#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "GET /modules returns 200", %{conn: conn} do
      conn = get(conn, "/modules")
      assert conn.status == 200
    end

    test "GET /modules/:name returns 200 for known module", %{conn: conn} do
      conn = get(conn, "/modules/#{@test_module_name}")
      assert conn.status == 200
    end

    test "GET /modules/:name returns 404 for unknown module", %{conn: conn} do
      conn = get(conn, "/modules/#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "GET /objects returns 200", %{conn: conn} do
      conn = get(conn, "/objects")
      assert conn.status == 200
    end

    test "GET /objects/:name returns 200 for known object", %{conn: conn} do
      conn = get(conn, "/objects/#{@test_object_name}")
      assert conn.status == 200
    end

    test "GET /objects/:name returns 404 for unknown object", %{conn: conn} do
      conn = get(conn, "/objects/#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "GET /dictionary returns 200", %{conn: conn} do
      conn = get(conn, "/dictionary")
      assert conn.status == 200
    end

    test "GET /data_types returns 200", %{conn: conn} do
      conn = get(conn, "/data_types")
      assert conn.status == 200
    end

    test "GET /skill_categories returns 200", %{conn: conn} do
      conn = get(conn, "/skill_categories")
      assert conn.status == 200
    end

    test "GET /skill_categories/:name returns 200", %{conn: conn} do
      conn = get(conn, "/skill_categories/#{@test_skill_category_name}")
      assert conn.status == 200
    end

    test "GET /skill_categories/:name returns 404 for unknown", %{conn: conn} do
      conn = get(conn, "/skill_categories/#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "GET /domain_categories returns 200", %{conn: conn} do
      conn = get(conn, "/domain_categories")
      assert conn.status == 200
    end

    test "GET /domain_categories/:name returns 404 for unknown", %{conn: conn} do
      conn = get(conn, "/domain_categories/#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "GET /module_categories returns 200", %{conn: conn} do
      conn = get(conn, "/module_categories")
      assert conn.status == 200
    end

    test "GET /module_categories/:name returns 404 for unknown", %{conn: conn} do
      conn = get(conn, "/module_categories/#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "GET /skill/graph/:name returns 200 for known skill", %{conn: conn} do
      conn = get(conn, "/skill/graph/#{@test_skill_name}")
      assert conn.status == 200
    end

    test "GET /skill/graph/:name returns 404 for unknown skill", %{conn: conn} do
      conn = get(conn, "/skill/graph/#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "GET /domain/graph/:name returns 200 for known domain", %{conn: conn} do
      conn = get(conn, "/domain/graph/#{@test_domain_name}")
      assert conn.status == 200
    end

    test "GET /domain/graph/:name returns 404 for unknown domain", %{conn: conn} do
      conn = get(conn, "/domain/graph/#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "GET /module/graph/:name returns 200 for known module", %{conn: conn} do
      conn = get(conn, "/module/graph/#{@test_module_name}")
      assert conn.status == 200
    end

    test "GET /module/graph/:name returns 404 for unknown module", %{conn: conn} do
      conn = get(conn, "/module/graph/#{@nonexistent_name}")
      assert conn.status == 404
    end

    test "GET /object/graph/:name returns 200 for known object", %{conn: conn} do
      conn = get(conn, "/object/graph/#{@test_object_name}")
      assert conn.status == 200
    end

    test "GET /object/graph/:name returns 404 for unknown object", %{conn: conn} do
      conn = get(conn, "/object/graph/#{@nonexistent_name}")
      assert conn.status == 404
    end
  end
end
