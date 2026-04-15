# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.JsonSchemaTest do
  use ExUnit.Case

  alias Schema.JsonSchema

  describe "put_type/2 and encode_string/2 string constraints" do
    test "emits maxLength for direct string_t attributes" do
      # string_t is handled by encode_string/2, not put_type/2 — constraints must
      # be applied there too so plain string fields don't fall through the gap.
      types = Schema.data_types()[:attributes]
      assert types[:string_t][:max_len] == 2000, "string_t should have max_len: 2000"

      schema = encode_simple_type("string_t")

      assert Map.get(schema, "maxLength") == 2000,
             "Generated JSON schema for a string_t attribute should include maxLength: 2000"
    end

    test "emits maxLength for types with max_len constraint (e.g. file_name_t)" do
      types = Schema.data_types()[:attributes]
      assert types[:file_name_t][:max_len] == 255, "file_name_t should have max_len: 255"

      schema = encode_simple_type("file_name_t")

      assert Map.get(schema, "maxLength") == 255,
             "Generated JSON schema for file_name_t should include maxLength: 255"
    end

    test "emits pattern for types with regex constraint (e.g. uuid_t)" do
      types = Schema.data_types()[:attributes]
      expected_regex = types[:uuid_t][:regex]
      assert is_binary(expected_regex), "uuid_t should have a regex in dictionary"

      schema = encode_simple_type("uuid_t")

      assert Map.get(schema, "pattern") == expected_regex,
             "Generated JSON schema for uuid_t should include pattern matching the type regex"
    end

    test "emits both maxLength and pattern for types with both constraints (e.g. cid_t)" do
      types = Schema.data_types()[:attributes]
      assert types[:cid_t][:max_len] == 120, "cid_t should have max_len: 120 in dictionary"
      expected_regex = types[:cid_t][:regex]
      assert is_binary(expected_regex), "cid_t should have a regex in dictionary"

      schema = encode_simple_type("cid_t")

      assert Map.get(schema, "maxLength") == 120,
             "Generated JSON schema for cid_t should include maxLength: 120"

      assert Map.get(schema, "pattern") == expected_regex,
             "Generated JSON schema for cid_t should include pattern matching cid_t regex"
    end

    test "emits maxLength inherited from string_t supertype for subtypes without own max_len (e.g. datetime_t)" do
      # datetime_t has type: string_t but no own max_len; it should inherit string_t's max_len: 2000
      types = Schema.data_types()[:attributes]
      assert types[:string_t][:max_len] == 2000, "string_t should have max_len: 2000"

      refute Map.has_key?(types[:datetime_t], :max_len),
             "datetime_t should not have its own max_len"

      schema = encode_simple_type("datetime_t")

      assert Map.get(schema, "maxLength") == 2000,
             "Generated JSON schema for datetime_t should inherit maxLength: 2000 from string_t"
    end

    test "emits both maxLength and pattern for file_hash_t" do
      types = Schema.data_types()[:attributes]
      assert types[:file_hash_t][:max_len] == 71, "file_hash_t should have max_len: 71"
      expected_regex = types[:file_hash_t][:regex]

      schema = encode_simple_type("file_hash_t")

      assert Map.get(schema, "maxLength") == 71,
             "Generated JSON schema for file_hash_t should include maxLength: 71"

      assert Map.get(schema, "pattern") == expected_regex,
             "Generated JSON schema for file_hash_t should include pattern"
    end

    test "does not emit maxLength or pattern for types without constraints (e.g. boolean_t)" do
      schema = encode_simple_type("boolean_t")

      refute Map.has_key?(schema, "maxLength"),
             "Generated JSON schema for boolean_t should not include maxLength"

      refute Map.has_key?(schema, "pattern"),
             "Generated JSON schema for boolean_t should not include pattern"
    end

    test "preserves enum values when emitting string constraints" do
      # An enum string_t attribute should keep its enum/const while also gaining maxLength
      minimal_type = %{
        name: "test_object",
        caption: "Test Object",
        attributes: %{
          test_attr: %{
            caption: "Test Attribute",
            type: "string_t",
            requirement: "optional",
            enum: %{foo: %{caption: "Foo"}, bar: %{caption: "Bar"}}
          }
        }
      }

      encoded = JsonSchema.encode(minimal_type, [])
      schema = get_in(encoded, ["properties", "test_attr"])

      assert Map.get(schema, "type") == "string"
      assert Enum.sort(Map.get(schema, "enum", [])) == ["bar", "foo"]

      assert Map.get(schema, "maxLength") == 2000,
             "Enum string attribute should still carry maxLength from string_t"
    end
  end

  # ---------------------------------------------------------------------------
  # encode_integer — integer enum attributes
  # ---------------------------------------------------------------------------

  describe "encode_integer/2 integer enum attributes" do
    test "emits enum list for integer attribute with multiple enum values" do
      type = %{
        name: "test_object",
        caption: "Test",
        attributes: %{
          status: %{
            caption: "Status",
            type: "integer_t",
            requirement: "optional",
            enum: %{"1": %{caption: "Active"}, "2": %{caption: "Inactive"}}
          }
        }
      }

      encoded = JsonSchema.encode(type, [])
      prop = get_in(encoded, ["properties", "status"])
      assert prop["type"] == "integer"
      assert Enum.sort(prop["enum"]) == [1, 2]
    end

    test "emits const for integer attribute with single enum value" do
      type = %{
        name: "test_object",
        caption: "Test",
        attributes: %{
          flag: %{
            caption: "Flag",
            type: "integer_t",
            requirement: "optional",
            enum: %{"99": %{caption: "Only"}}
          }
        }
      }

      encoded = JsonSchema.encode(type, [])
      prop = get_in(encoded, ["properties", "flag"])
      assert prop["type"] == "integer"
      assert prop["const"] == 99
      refute Map.has_key?(prop, "enum")
    end

    test "integer attribute without enum emits only type" do
      schema = encode_simple_type("integer_t")
      assert schema["type"] == "integer"
      refute Map.has_key?(schema, "enum")
      refute Map.has_key?(schema, "const")
    end
  end

  # ---------------------------------------------------------------------------
  # encode_array — is_array wrapping
  # ---------------------------------------------------------------------------

  describe "encode_array/2 array wrapping" do
    test "optional array wraps schema in array type with uniqueItems but no minItems" do
      type = %{
        name: "test_object",
        caption: "Test",
        attributes: %{
          tags: %{
            caption: "Tags",
            type: "string_t",
            requirement: "optional",
            is_array: true
          }
        }
      }

      encoded = JsonSchema.encode(type, [])
      prop = get_in(encoded, ["properties", "tags"])
      assert prop["type"] == "array"
      assert prop["uniqueItems"] == true
      assert prop["items"]["type"] == "string"
      refute Map.has_key?(prop, "minItems")
    end

    test "required array adds minItems: 1" do
      type = %{
        name: "test_object",
        caption: "Test",
        attributes: %{
          authors: %{
            caption: "Authors",
            type: "string_t",
            requirement: "required",
            is_array: true
          }
        }
      }

      encoded = JsonSchema.encode(type, [])
      prop = get_in(encoded, ["properties", "authors"])
      assert prop["type"] == "array"
      assert prop["minItems"] == 1
    end

    test "array of integer enum wraps enum into items" do
      type = %{
        name: "test_object",
        caption: "Test",
        attributes: %{
          flags: %{
            caption: "Flags",
            type: "integer_t",
            requirement: "optional",
            is_array: true,
            enum: %{"1": %{caption: "A"}, "2": %{caption: "B"}}
          }
        }
      }

      encoded = JsonSchema.encode(type, [])
      prop = get_in(encoded, ["properties", "flags"])
      assert prop["type"] == "array"
      items = prop["items"]
      assert items["type"] == "integer"
      assert Enum.sort(items["enum"]) == [1, 2]
    end
  end

  # ---------------------------------------------------------------------------
  # put_required — required array in object schema
  # ---------------------------------------------------------------------------

  describe "put_required/2 required fields" do
    test "required attributes appear in the required array" do
      type = %{
        name: "test_object",
        caption: "Test",
        attributes: %{
          req_field: %{caption: "Required", type: "string_t", requirement: "required"},
          opt_field: %{caption: "Optional", type: "string_t", requirement: "optional"}
        }
      }

      encoded = JsonSchema.encode(type, [])
      assert "req_field" in encoded["required"]
      refute "opt_field" in (encoded["required"] || [])
    end

    test "no required key when all attributes are optional" do
      type = %{
        name: "test_object",
        caption: "Test",
        attributes: %{
          field: %{caption: "Field", type: "string_t", requirement: "optional"}
        }
      }

      encoded = JsonSchema.encode(type, [])
      refute Map.has_key?(encoded, "required")
    end
  end

  # ---------------------------------------------------------------------------
  # put_just_one / put_at_least_one — object-level constraints
  # ---------------------------------------------------------------------------

  describe "put_just_one/2 and put_at_least_one/2" do
    test "just_one constraint emits oneOf at object level" do
      type = %{
        name: "test_object",
        caption: "Test",
        attributes: %{
          a: %{caption: "A", type: "string_t", requirement: "optional"},
          b: %{caption: "B", type: "string_t", requirement: "optional"}
        },
        constraints: %{just_one: ["a", "b"]}
      }

      encoded = JsonSchema.encode(type, [])
      assert Map.has_key?(encoded, "oneOf")
      one_of = encoded["oneOf"]
      assert length(one_of) == 2
      required_sets = Enum.map(one_of, & &1["required"])
      assert ["a"] in required_sets
      assert ["b"] in required_sets
    end

    test "at_least_one constraint emits anyOf at object level" do
      type = %{
        name: "test_object",
        caption: "Test",
        attributes: %{
          x: %{caption: "X", type: "string_t", requirement: "optional"},
          y: %{caption: "Y", type: "string_t", requirement: "optional"}
        },
        constraints: %{at_least_one: ["x", "y"]}
      }

      encoded = JsonSchema.encode(type, [])
      assert Map.has_key?(encoded, "anyOf")
      any_of = encoded["anyOf"]
      required_sets = Enum.map(any_of, & &1["required"])
      assert ["x"] in required_sets
      assert ["y"] in required_sets
    end
  end

  # ---------------------------------------------------------------------------
  # json_t — no type emitted
  # ---------------------------------------------------------------------------

  describe "encode_attribute for json_t" do
    test "json_t attribute emits only title, no type field" do
      schema = encode_simple_type("json_t")
      assert schema["title"] == "Test Attribute"
      refute Map.has_key?(schema, "type")
    end
  end

  # ---------------------------------------------------------------------------
  # empty_object — no attributes → additionalProperties: true
  # ---------------------------------------------------------------------------

  describe "empty_object/2 — no attributes" do
    test "object with no attributes sets additionalProperties to true" do
      type = %{name: "empty_obj", caption: "Empty", attributes: %{}}
      encoded = JsonSchema.encode(type, [])
      assert encoded["additionalProperties"] == true
    end

    test "object with attributes sets additionalProperties to false" do
      type = %{
        name: "obj",
        caption: "Obj",
        attributes: %{f: %{caption: "F", type: "string_t", requirement: "optional"}}
      }

      encoded = JsonSchema.encode(type, [])
      assert encoded["additionalProperties"] == false
    end
  end

  # ---------------------------------------------------------------------------
  # :package_name option — javaType injection
  # ---------------------------------------------------------------------------

  describe "package_name option (javaType)" do
    test "package_name option adds javaType when _links key is present" do
      type = %{
        name: "my_record",
        caption: "My Record",
        _links: [],
        attributes: %{}
      }

      encoded = JsonSchema.encode(type, package_name: "com.example")
      assert encoded["javaType"] == "com.example.MyRecord"
    end

    test "no javaType emitted without _links key" do
      type = %{name: "my_record", caption: "My Record", attributes: %{}}
      encoded = JsonSchema.encode(type, package_name: "com.example")
      refute Map.has_key?(encoded, "javaType")
    end

    test "no javaType emitted without package_name option" do
      type = %{name: "my_record", caption: "My Record", _links: [], attributes: %{}}
      encoded = JsonSchema.encode(type, [])
      refute Map.has_key?(encoded, "javaType")
    end
  end

  # ---------------------------------------------------------------------------
  # encode_entity/2 — top-level schema structure
  # ---------------------------------------------------------------------------

  describe "encode_entity/2 top-level structure" do
    test "top-level schema includes $schema and $id" do
      type = %{name: "record", caption: "Record", attributes: %{}}
      encoded = JsonSchema.encode(type, [])
      assert Map.has_key?(encoded, "$schema")
      assert Map.has_key?(encoded, "$id")
      assert String.contains?(encoded["$id"], "record")
    end

    test "nil entity returns empty map" do
      assert JsonSchema.encode_entity(nil, true) == %{}
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Builds a minimal object type with a single attribute of the given type_name
  # and returns the JSON schema for that attribute (the first property).
  defp encode_simple_type(type_name) do
    minimal_type = %{
      name: "test_object",
      caption: "Test Object",
      attributes: %{
        test_attr: %{
          caption: "Test Attribute",
          type: type_name,
          requirement: "optional"
        }
      }
    }

    encoded = JsonSchema.encode(minimal_type, [])
    get_in(encoded, ["properties", "test_attr"])
  end
end
