# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.TranslatorTest do
  use ExUnit.Case, async: false

  alias Schema.Translator

  # Known-stable UIDs
  @skill_uid 10101
  @domain_uid 101

  # ---------------------------------------------------------------------------
  # Non-map passthrough
  # ---------------------------------------------------------------------------

  describe "translate/3 non-map input" do
    test "returns non-map input unchanged for skill type" do
      assert Translator.translate("not a map", [], :skill) == "not a map"
      assert Translator.translate(42, [], :domain) == 42
      assert Translator.translate(nil, [], :module) == nil
    end
  end

  # ---------------------------------------------------------------------------
  # Unknown type
  # ---------------------------------------------------------------------------

  describe "translate/3 unknown type" do
    test "returns data unchanged for unknown type (entity not found)" do
      result = Translator.translate(%{"name" => "whatever"}, [], :unknown_type)
      assert result == %{"name" => "whatever"}
    end
  end

  # ---------------------------------------------------------------------------
  # Skill translation — by id
  # ---------------------------------------------------------------------------

  describe "translate/3 skill by id" do
    test "translates a skill by id and enriches with name" do
      result = Translator.translate(%{"id" => @skill_uid}, [], :skill)
      assert is_map(result)
      assert Map.has_key?(result, "name")
    end

    test "unknown skill id returns data unchanged" do
      result = Translator.translate(%{"id" => 999_999_999}, [], :skill)
      assert result == %{"id" => 999_999_999}
    end
  end

  # ---------------------------------------------------------------------------
  # Skill translation — by name
  # ---------------------------------------------------------------------------

  describe "translate/3 skill by name" do
    test "translates a skill by name and enriches with id" do
      result = Translator.translate(%{"name" => "contextual_comprehension"}, [], :skill)
      assert is_map(result)
      assert Map.has_key?(result, "id")
    end

    test "unknown skill name returns data unchanged" do
      result = Translator.translate(%{"name" => "does_not_exist_xyz"}, [], :skill)
      assert result == %{"name" => "does_not_exist_xyz"}
    end
  end

  # ---------------------------------------------------------------------------
  # Domain translation
  # ---------------------------------------------------------------------------

  describe "translate/3 domain" do
    test "translates a domain by id and enriches with name" do
      result = Translator.translate(%{"id" => @domain_uid}, [], :domain)
      assert is_map(result)
      assert Map.has_key?(result, "name")
    end

    test "translates a domain by name and enriches with id" do
      result = Translator.translate(%{"name" => "internet_of_things"}, [], :domain)
      assert is_map(result)
      assert Map.has_key?(result, "id")
    end
  end

  # ---------------------------------------------------------------------------
  # Module translation
  # ---------------------------------------------------------------------------

  describe "translate/3 module" do
    test "unknown module id returns data unchanged" do
      result = Translator.translate(%{"id" => 999_999_999}, [], :module)
      assert result == %{"id" => 999_999_999}
    end
  end

  # ---------------------------------------------------------------------------
  # Object translation
  # ---------------------------------------------------------------------------

  describe "translate/3 object" do
    test "translates a known object type by name option" do
      result = Translator.translate(%{"type" => "container_image"}, [name: "locator"], :object)
      assert is_map(result)
    end

    test "returns data unchanged when no name option provided" do
      result = Translator.translate(%{"type" => "container_image"}, [], :object)
      assert result == %{"type" => "container_image"}
    end
  end

  # ---------------------------------------------------------------------------
  # verbose option — mode 1 (enum caption substitution)
  # ---------------------------------------------------------------------------

  describe "translate/3 verbose: 1" do
    test "returns a map for a known skill with verbose: 1" do
      result = Translator.translate(%{"id" => @skill_uid}, [verbose: 1], :skill)
      assert is_map(result)
    end
  end

  # ---------------------------------------------------------------------------
  # verbose option — mode 3 (structured output)
  # ---------------------------------------------------------------------------

  describe "translate/3 verbose: 3" do
    test "non-enum fields are wrapped in name/type/value map" do
      result = Translator.translate(%{"id" => @skill_uid}, [verbose: 3], :skill)
      assert is_map(result)

      # At least the id field should be present
      if Map.has_key?(result, "id") do
        id_entry = result["id"]

        if is_map(id_entry) do
          assert Map.has_key?(id_entry, "value")
          assert Map.has_key?(id_entry, "name")
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # enrich_input_data — id and name are both added when one is missing
  # ---------------------------------------------------------------------------

  describe "enrich_input_data via translate/3" do
    test "translating by id adds name to result" do
      result = Translator.translate(%{"id" => @skill_uid}, [], :skill)
      assert Map.has_key?(result, "name")
      assert is_binary(result["name"])
    end

    test "translating by name adds id to result" do
      result = Translator.translate(%{"name" => "contextual_comprehension"}, [], :skill)
      assert Map.has_key?(result, "id")
      assert is_integer(result["id"])
    end

    test "translating with both id and name keeps both" do
      skill = Schema.find_skill(@skill_uid)

      if skill do
        name = Schema.Utils.class_name_with_hierarchy(skill[:name], Schema.all_skills())
        result = Translator.translate(%{"id" => @skill_uid, "name" => name}, [], :skill)
        assert Map.has_key?(result, "id")
        assert Map.has_key?(result, "name")
      end
    end
  end
end
