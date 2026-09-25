# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.ScopedObjectControllerTest do
  use SchemaWeb.ConnCase, async: false

  @extension_paths Application.compile_env(:schema_server, [Schema.Application, :extension], nil)
  @object_name "example/example_telemetry_data"
  @payload %{
    "example_endpoint" => "https://example.com/telemetry",
    "example_sample_rate" => 50
  }
  @locator_payload %{"type" => "url", "urls" => ["https://example.com/agent"]}
  @translated_locator %{
    "Type" => "url",
    "URLs" => ["https://example.com/agent"],
    "name" => "locator"
  }
  @valid_response %{"error_count" => 0, "errors" => [], "warning_count" => 0, "warnings" => []}
  @unknown_names [
    "example/non_existent_object",
    "unknown_extension/example_telemetry_data",
    "example/locator",
    "unknown_extension/locator",
    "example_telemetry_data",
    "non_existent_object"
  ]

  describe "POST /api/validate/object/:extension/:name" do
    if @extension_paths in [nil, ""] do
      @describetag skip: "requires the example extension; run task test:server:extensions"
    end

    test "validates the example extension's object" do
      result =
        post_json("/api/validate/object/#{@object_name}", @payload)
        |> json_response(200)

      assert result["error_count"] == 0
      assert result["errors"] == []
    end

    test "validates a sample fetched through the scoped GET route" do
      sample =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> get("/sample/objects/#{@object_name}")
        |> json_response(200)

      result =
        post_json("/api/validate/object/#{@object_name}", sample)
        |> json_response(200)

      assert result["error_count"] == 0
    end

    test "reports the extension object's missing required attribute" do
      result =
        post_json("/api/validate/object/#{@object_name}", %{})
        |> json_response(200)

      assert result["error_count"] == 1

      assert [
               %{
                 "error" => "attribute_required_missing",
                 "attribute" => "example_endpoint"
               }
             ] = result["errors"]
    end

    test "reports the extension object's invalid attribute type" do
      payload = Map.put(@payload, "example_endpoint", 123)

      result =
        post_json("/api/validate/object/#{@object_name}", payload)
        |> json_response(200)

      assert result["error_count"] == 1

      assert [
               %{
                 "error" => "attribute_wrong_type",
                 "attribute" => "example_endpoint"
               }
             ] = result["errors"]
    end

    test "rejects non-object bodies with the existing error" do
      for payload <- ["not an object", [], nil] do
        assert post_json("/api/validate/object/#{@object_name}", payload)
               |> json_response(400) ==
                 %{"error" => "Unexpected body. Expected a JSON object."}
      end
    end

    @tag :path_parameters
    test "path name and extension take precedence over query parameters" do
      for query <- [
            "extension=unknown_extension&name=locator",
            "extension[foo]=bar&name[foo]=bar"
          ] do
        assert post_json("/api/validate/object/#{@object_name}?#{query}", @payload)
               |> json_response(200) == @valid_response
      end
    end

    @tag :path_parameters
    test "path name and extension take precedence over accepted form parameters" do
      for extension <- ["unknown_extension", %{"foo" => "bar"}] do
        form = %{
          "_json" => %{"example_endpoint" => @payload["example_endpoint"]},
          "extension" => extension,
          "name" => "locator"
        }

        assert post_form("/api/validate/object/#{@object_name}", form)
               |> json_response(200) == @valid_response
      end
    end

    @tag :path_parameters
    test "accepts the versioned encoded object name used by Swagger" do
      path = "/api/#{Schema.version()}/validate/object/#{URI.encode_www_form(@object_name)}"

      assert post_json(path, @payload) |> json_response(200) == @valid_response
    end
  end

  describe "POST /api/translate/object/:extension/:name" do
    if @extension_paths in [nil, ""] do
      @describetag skip: "requires the example extension; run task test:server:extensions"
    end

    test "translates extension attribute names to their captions" do
      result =
        post_json("/api/translate/object/#{@object_name}?_mode=2", @payload)
        |> json_response(200)

      assert result["Example Endpoint"] == @payload["example_endpoint"]
      assert result["Example Sample Rate"] == 50
      refute Map.has_key?(result, "example_endpoint")
    end

    test "translates each object in an array" do
      second = Map.put(@payload, "example_endpoint", "https://example.com/other")

      result =
        post_json("/api/translate/object/#{@object_name}?_mode=2", [@payload, second])
        |> json_response(200)

      assert [first_result, second_result] = result
      assert first_result["Example Endpoint"] == @payload["example_endpoint"]
      assert second_result["Example Endpoint"] == second["example_endpoint"]
      refute Map.has_key?(first_result, "example_endpoint")
      refute Map.has_key?(second_result, "example_endpoint")
    end

    test "preserves the spaces option" do
      result =
        post_json("/api/translate/object/#{@object_name}?_mode=2&_spaces=_", @payload)
        |> json_response(200)

      assert result["Example_Endpoint"] == @payload["example_endpoint"]
      assert result["Example_Sample_Rate"] == 50
    end

    test "preserves verbose translation" do
      result =
        post_json("/api/translate/object/#{@object_name}?_mode=3", @payload)
        |> json_response(200)

      assert result["example_endpoint"] == %{
               "name" => "Example Endpoint",
               "type" => "string_t",
               "value" => @payload["example_endpoint"]
             }
    end

    test "rejects non-object, non-array bodies with the existing error" do
      for payload <- ["not an object", nil] do
        assert post_json("/api/translate/object/#{@object_name}", payload)
               |> json_response(400) ==
                 %{"error" => "Unexpected body. Expected a JSON object or array."}
      end
    end

    @tag :path_parameters
    test "path name and extension take precedence over query parameters" do
      for query <- [
            "extension=unknown_extension&name=locator",
            "extension[foo]=bar&name[foo]=bar"
          ] do
        result =
          post_json("/api/translate/object/#{@object_name}?_mode=2&#{query}", @payload)
          |> json_response(200)

        assert result["Example Endpoint"] == @payload["example_endpoint"]
        assert result["Example Sample Rate"] == 50
        assert result["name"] == "example_telemetry_data"
        refute Map.has_key?(result, "example_endpoint")
      end
    end

    @tag :path_parameters
    test "path name and extension take precedence over accepted form parameters" do
      for extension <- ["unknown_extension", %{"foo" => "bar"}] do
        form = %{
          "_json" => %{"example_endpoint" => @payload["example_endpoint"]},
          "extension" => extension,
          "name" => "locator"
        }

        result =
          post_form("/api/translate/object/#{@object_name}?_mode=2", form)
          |> json_response(200)

        assert result == %{
                 "Example Endpoint" => @payload["example_endpoint"],
                 "name" => "example_telemetry_data"
               }
      end
    end

    @tag :path_parameters
    test "accepts the versioned encoded object name used by Swagger" do
      path = "/api/#{Schema.version()}/translate/object/#{URI.encode_www_form(@object_name)}"
      result = post_json("#{path}?_mode=2", @payload) |> json_response(200)

      assert result["Example Endpoint"] == @payload["example_endpoint"]
      assert result["Example Sample Rate"] == 50
      assert result["name"] == "example_telemetry_data"
      refute Map.has_key?(result, "example_endpoint")
    end
  end

  describe "unscoped and unknown object controls" do
    test "still validates an unscoped core object" do
      payload = %{"type" => "url", "urls" => ["https://example.com/agent"]}
      result = post_json("/api/validate/object/locator", payload) |> json_response(200)

      assert result["error_count"] == 0
      assert result["errors"] == []
    end

    test "still translates an unscoped core object" do
      payload = %{"type" => "url", "urls" => ["https://example.com/agent"]}
      result = post_json("/api/translate/object/locator?_mode=2", payload) |> json_response(200)

      assert result["Type"] == "url"
      assert result["URLs"] == payload["urls"]
      refute Map.has_key?(result, "type")
    end

    test "unknown objects return name_unknown without dropping the extension" do
      for name <- @unknown_names do
        result = post_json("/api/validate/object/#{name}", @payload) |> json_response(200)

        assert result["error_count"] == 1
        assert [%{"error" => "name_unknown", "value" => ^name}] = result["errors"]
      end
    end

    test "unknown objects are returned unchanged by translation" do
      for name <- @unknown_names do
        assert post_json("/api/translate/object/#{name}?_mode=2", @payload)
               |> json_response(200) == @payload
      end
    end
  end

  describe "unscoped object path parameters" do
    @describetag :path_parameters

    test "validation ignores a scalar extension query parameter" do
      assert post_json("/api/validate/object/locator?extension=example", @locator_payload)
             |> json_response(200) == @valid_response
    end

    test "translation ignores a scalar extension query parameter" do
      assert post_json(
               "/api/translate/object/locator?_mode=2&extension=example",
               @locator_payload
             )
             |> json_response(200) == @translated_locator
    end

    test "validation ignores a map-valued extension query parameter" do
      assert post_json("/api/validate/object/locator?extension[foo]=bar", @locator_payload)
             |> json_response(200) == @valid_response
    end

    test "translation ignores a map-valued extension query parameter" do
      assert post_json(
               "/api/translate/object/locator?_mode=2&extension[foo]=bar",
               @locator_payload
             )
             |> json_response(200) == @translated_locator
    end

    test "validation ignores a scalar extension in an accepted form body" do
      form = %{"_json" => @locator_payload, "extension" => "example", "name" => "other_object"}

      assert post_form("/api/validate/object/locator", form)
             |> json_response(200) == @valid_response
    end

    test "translation ignores a scalar extension in an accepted form body" do
      form = %{"_json" => @locator_payload, "extension" => "example", "name" => "other_object"}

      assert post_form("/api/translate/object/locator?_mode=2", form)
             |> json_response(200) == @translated_locator
    end

    test "validation ignores a map-valued extension in an accepted form body" do
      form = %{"_json" => @locator_payload, "extension" => %{"foo" => "bar"}}

      assert post_form("/api/validate/object/locator", form)
             |> json_response(200) == @valid_response
    end

    test "translation ignores a map-valued extension in an accepted form body" do
      form = %{"_json" => @locator_payload, "extension" => %{"foo" => "bar"}}

      assert post_form("/api/translate/object/locator?_mode=2", form)
             |> json_response(200) == @translated_locator
    end
  end

  defp post_json(path, payload) do
    build_conn()
    |> put_req_header("content-type", "application/json")
    |> put_req_header("accept", "application/json")
    |> post(path, Jason.encode!(payload))
  end

  defp post_form(path, payload) do
    build_conn()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> put_req_header("accept", "application/json")
    |> post(path, Plug.Conn.Query.encode(payload))
  end
end
