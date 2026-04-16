# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.TypesTest do
  use ExUnit.Case, async: true

  alias Schema.Types

  # ---------------------------------------------------------------------------
  # category_uid/2
  # ---------------------------------------------------------------------------

  describe "category_uid/2" do
    test "combines extension uid and category id" do
      assert Types.category_uid(1, 5) == 105
      assert Types.category_uid(0, 10) == 10
      assert Types.category_uid(3, 42) == 342
    end
  end

  # ---------------------------------------------------------------------------
  # category_uid_ex/2
  # ---------------------------------------------------------------------------

  describe "category_uid_ex/2" do
    test "delegates to category_uid when category_id < 100" do
      assert Types.category_uid_ex(2, 7) == Types.category_uid(2, 7)
    end

    test "returns category_id unchanged when already >= 100" do
      assert Types.category_uid_ex(2, 100) == 100
      assert Types.category_uid_ex(99, 200) == 200
    end

    test "boundary: 99 is still < 100 so extension is applied" do
      assert Types.category_uid_ex(1, 99) == Types.category_uid(1, 99)
    end
  end

  # ---------------------------------------------------------------------------
  # class_uid/2
  # ---------------------------------------------------------------------------

  describe "class_uid/2" do
    test "combines category uid and class id" do
      assert Types.class_uid(1, 1) == 101
      assert Types.class_uid(10, 5) == 1005
      assert Types.class_uid(0, 3) == 3
    end
  end

  # ---------------------------------------------------------------------------
  # type_name/2
  # ---------------------------------------------------------------------------

  describe "type_name/2" do
    test "joins class and name with colon-space separator" do
      assert Types.type_name("Skill", "Contextual") == "Skill: Contextual"
    end

    test "works with empty strings" do
      assert Types.type_name("", "") == ": "
    end
  end

  # ---------------------------------------------------------------------------
  # encode_type/1
  # ---------------------------------------------------------------------------

  describe "encode_type/1" do
    test "string types encode to \"string\"" do
      for t <- ~w(string_t datetime_t uuid_t cid_t long_string_t email_t url_t ip_t mac_t
                  file_name_t path_t mime_t subnet_t file_hash_t bytestring_t) do
        assert Types.encode_type(t) == "string", "expected #{t} -> string"
      end
    end

    test "integer types encode to \"integer\"" do
      for t <- ~w(integer_t long_t timestamp_t port_t) do
        assert Types.encode_type(t) == "integer", "expected #{t} -> integer"
      end
    end

    test "float types encode to \"number\"" do
      for t <- ~w(float_t unit_interval_t) do
        assert Types.encode_type(t) == "number", "expected #{t} -> number"
      end
    end

    test "boolean_t encodes to \"boolean\"" do
      assert Types.encode_type("boolean_t") == "boolean"
    end

    test "unknown type encodes to \"object\"" do
      assert Types.encode_type("some_unknown_t") == "object"
      assert Types.encode_type("") == "object"
    end
  end
end
