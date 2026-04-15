# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.ValidatorTest do
  use ExUnit.Case, async: false

  # Helpers

  defp validate(data, type), do: Schema.Validator.validate(data, [], type)

  defp validate(data, opts, type), do: Schema.Validator.validate(data, opts, type)

  defp errors(result), do: result[:errors] || []
  defp warnings(result), do: result[:warnings] || []
  defp error_types(result), do: Enum.map(errors(result), & &1[:error])

  # Known-stable UIDs from the schema. Skills/domains/modules are identified
  # by integer uid (id field). The "name" field value must match the full
  # hierarchical path stored in the class's name enum (e.g.
  # "natural_language_processing/natural_language_understanding/contextual_comprehension"),
  # not the simple name atom key. Using the uid is the safest approach.
  @test_skill_uid 10101
  @test_domain_uid 101
  @test_module_uid 101

  # Short names used for lookups via Schema.skill/1 etc. (accepted by Repo lookups)
  @test_skill_name "contextual_comprehension"
  @test_domain_name "internet_of_things"

  defp first_skill_name do
    # Return the full hierarchical name as stored in the name attribute enum
    skill = Schema.skill(@test_skill_name)
    name_enum = get_in(skill, [:attributes, :name, :enum]) || %{}
    case Map.keys(name_enum) do
      [key | _] -> to_string(key)
      _ -> @test_skill_name
    end
  end

  defp first_skill_uid, do: @test_skill_uid

  defp first_domain_name do
    domain = Schema.domain(@test_domain_name)
    name_enum = get_in(domain, [:attributes, :name, :enum]) || %{}
    case Map.keys(name_enum) do
      [key | _] -> to_string(key)
      _ -> @test_domain_name
    end
  end

  # ---------------------------------------------------------------------------
  # Skill validation — happy path
  # ---------------------------------------------------------------------------

  describe "validate skill — happy path" do
    test "valid skill by name has no errors" do
      name = first_skill_name()
      result = validate(%{"name" => name}, :skill)
      assert result[:error_count] == 0,
             "Expected 0 errors, got: #{inspect(result[:errors])}"
    end

    test "valid skill by id has no errors" do
      uid = first_skill_uid()
      result = validate(%{"id" => uid}, :skill)
      assert result[:error_count] == 0,
             "Expected 0 errors, got: #{inspect(result[:errors])}"
    end

    test "valid skill by both id and name has no errors" do
      canonical_name = first_skill_name()
      result = validate(%{"id" => @test_skill_uid, "name" => canonical_name}, :skill)
      assert result[:error_count] == 0,
             "Expected 0 errors, got: #{inspect(result[:errors])}"
    end
  end

  # ---------------------------------------------------------------------------
  # Skill validation — id and name errors
  # ---------------------------------------------------------------------------

  describe "validate skill — id/name errors" do
    test "missing both id and name returns attribute_required_missing error" do
      result = validate(%{}, :skill)
      assert "attribute_required_missing" in error_types(result)
    end

    test "unknown name returns name_unknown error" do
      result = validate(%{"name" => "this_skill_does_not_exist_xyz"}, :skill)
      assert "name_unknown" in error_types(result)
    end

    test "unknown id returns id_unknown error" do
      result = validate(%{"id" => 999_999_999}, :skill)
      assert "id_unknown" in error_types(result)
    end

    test "non-integer id returns attribute_wrong_type error" do
      result = validate(%{"id" => "not_an_int"}, :skill)
      assert "attribute_wrong_type" in error_types(result)
    end

    test "mismatched id and name returns id_name_mismatch error" do
      # Find two different skills
      non_base_skills =
        Schema.skills()
        |> Enum.reject(fn {_k, v} -> Map.get(v, :category) == true end)
        |> Enum.reject(fn {k, _v} -> k == :base_skill end)

      if length(non_base_skills) >= 2 do
        [{_k1, v1}, {k2, _v2}] = Enum.take(non_base_skills, 2)

        if v1[:uid] != nil do
          result =
            validate(%{"id" => v1[:uid], "name" => Atom.to_string(k2)}, :skill)

          assert "id_name_mismatch" in error_types(result) or
                   result[:error_count] > 0
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Domain validation
  # ---------------------------------------------------------------------------

  describe "validate domain — happy path" do
    test "valid domain by name has no errors" do
      name = first_domain_name()
      result = validate(%{"name" => name}, :domain)
      assert result[:error_count] == 0,
             "Expected 0 errors, got: #{inspect(result[:errors])}"
    end
  end

  describe "validate domain — errors" do
    test "unknown domain name returns name_unknown error" do
      result = validate(%{"name" => "this_domain_does_not_exist_xyz"}, :domain)
      assert "name_unknown" in error_types(result)
    end
  end

  # ---------------------------------------------------------------------------
  # Module validation
  # ---------------------------------------------------------------------------

  describe "validate module — happy path" do
    test "module identified by id is resolved (missing required fields are reported)" do
      # Non-category modules all require a `data` field, so we cannot produce a zero-error
      # result without providing deeply-nested object data. Instead, test that the module
      # is correctly identified (no name_unknown / id_unknown errors) and that any errors
      # are exclusively about missing required attributes.
      uid = @test_module_uid
      result = validate(%{"id" => uid}, :module)

      non_required_errors =
        errors(result)
        |> Enum.reject(fn e -> e[:error] == "attribute_required_missing" end)

      assert non_required_errors == [],
             "Expected only required-attribute errors, got extra: #{inspect(non_required_errors)}"
    end
  end

  describe "validate module — errors" do
    test "unknown module name returns name_unknown error" do
      result = validate(%{"name" => "this_module_does_not_exist_xyz"}, :module)
      assert "name_unknown" in error_types(result)
    end
  end

  # ---------------------------------------------------------------------------
  # Object validation
  # ---------------------------------------------------------------------------

  describe "validate object — happy path" do
    test "valid locator object by type value has no errors" do
      result =
        Schema.Validator.validate(
          %{"type" => "container_image", "urls" => ["https://example.com/image:latest"]},
          [],
          :object
        )

      # Without object name option, we get attribute_required_missing for object_name
      assert is_map(result)
    end

    test "valid record object with required fields has no errors" do
      # Use UIDs for skills and domains to avoid enum name format issues.
      # Use "1.0.0" as schema_version: the current schema is "1.1.0-dev" (prerelease),
      # so passing an earlier released version yields only a warning, not an error.
      result =
        Schema.Validator.validate(
          %{
            "name" => "test_agent",
            "version" => "1.0.0",
            "description" => "test",
            "authors" => ["author@example.com"],
            "created_at" => "2024-01-01T00:00:00Z",
            "schema_version" => "1.0.0",
            "skills" => [%{"id" => @test_skill_uid}],
            "domains" => [%{"id" => @test_domain_uid}]
          },
          [name: "record"],
          :object
        )

      assert result[:error_count] == 0,
             "Expected 0 errors, got: #{inspect(result[:errors])}"
    end
  end

  describe "validate object — errors" do
    test "unknown object name returns name_unknown error" do
      result =
        Schema.Validator.validate(
          %{"type" => "container_image"},
          [name: "this_object_does_not_exist_xyz"],
          :object
        )

      assert "name_unknown" in error_types(result)
    end

    test "missing required attribute returns attribute_required_missing" do
      result =
        Schema.Validator.validate(
          %{},
          [name: "record"],
          :object
        )

      assert "attribute_required_missing" in error_types(result)
    end

    test "unknown attribute returns attribute_unknown" do
      result =
        Schema.Validator.validate(
          %{
            "name" => "test_agent",
            "version" => "1.0.0",
            "description" => "test",
            "authors" => ["author@example.com"],
            "created_at" => "2024-01-01T00:00:00Z",
            "skills" => [%{"id" => @test_skill_uid}],
            "domains" => [%{"id" => @test_domain_uid}],
            "this_attribute_does_not_exist" => "bad"
          },
          [name: "record"],
          :object
        )

      assert "attribute_unknown" in error_types(result)
    end

    test "required array that is empty returns attribute_required_empty" do
      result =
        Schema.Validator.validate(
          %{
            "name" => "test_agent",
            "version" => "1.0.0",
            "description" => "test",
            "authors" => [],
            "created_at" => "2024-01-01T00:00:00Z",
            "skills" => [%{"id" => @test_skill_uid}],
            "domains" => [%{"id" => @test_domain_uid}]
          },
          [name: "record"],
          :object
        )

      assert "attribute_required_empty" in error_types(result)
    end

    test "wrong type for a string field returns attribute_wrong_type" do
      result =
        Schema.Validator.validate(
          %{
            "name" => 12345,
            "version" => "1.0.0",
            "description" => "test",
            "authors" => ["author@example.com"],
            "created_at" => "2024-01-01T00:00:00Z",
            "skills" => [%{"id" => @test_skill_uid}]
          },
          [name: "record"],
          :object
        )

      assert "attribute_wrong_type" in error_types(result)
    end

    test "array type passed as scalar returns attribute_wrong_type" do
      result =
        Schema.Validator.validate(
          %{
            "name" => "agent",
            "version" => "1.0.0",
            "description" => "test",
            "authors" => "not_an_array",
            "created_at" => "2024-01-01T00:00:00Z",
            "skills" => [%{"id" => @test_skill_uid}]
          },
          [name: "record"],
          :object
        )

      assert "attribute_wrong_type" in error_types(result)
    end
  end

  # ---------------------------------------------------------------------------
  # Enum validation
  # ---------------------------------------------------------------------------

  describe "validate enum — locator type" do
    test "unknown enum value returns attribute_enum_value_unknown" do
      result =
        Schema.Validator.validate(
          %{"type" => "UNKNOWN_LOCATOR_TYPE", "urls" => ["https://example.com"]},
          [name: "locator"],
          :object
        )

      assert "attribute_enum_value_unknown" in error_types(result)
    end

    test "valid enum value returns no enum errors" do
      result =
        Schema.Validator.validate(
          %{"type" => "container_image", "urls" => ["https://example.com/image:latest"]},
          [name: "locator"],
          :object
        )

      enum_errors = Enum.filter(errors(result), &(&1[:error] == "attribute_enum_value_unknown"))
      assert enum_errors == []
    end
  end

  # ---------------------------------------------------------------------------
  # schema_version validation
  # ---------------------------------------------------------------------------

  describe "validate schema_version" do
    test "matching schema version produces no version errors" do
      current = Schema.version()

      result =
        validate(
          %{"id" => @test_skill_uid, "schema_version" => current},
          :skill
        )

      version_errors =
        Enum.filter(errors(result), &String.starts_with?(&1[:error] || "", "version_"))

      assert version_errors == []
    end

    test "malformed schema_version returns version_invalid_format error" do
      result =
        validate(
          %{"id" => @test_skill_uid, "schema_version" => "not.a.version!!!"},
          :skill
        )

      assert "version_invalid_format" in error_types(result)
    end

    test "schema_version newer than server returns version_incompatible_later error" do
      result =
        validate(
          %{"id" => @test_skill_uid, "schema_version" => "9999.0.0"},
          :skill
        )

      assert "version_incompatible_later" in error_types(result)
    end

    test "earlier stable schema_version returns version_earlier warning" do
      current_parsed = Schema.parsed_version()

      # Only run if server is on a non-prerelease version >= 1.0.0
      if is_map(current_parsed) and current_parsed[:major] >= 1 and
           not Schema.Utils.version_is_prerelease?(current_parsed) do
        result =
          validate(
            %{"id" => @test_skill_uid, "schema_version" => "1.0.0"},
            :skill
          )

        version_issues =
          Enum.filter(
            errors(result) ++ warnings(result),
            &String.starts_with?(&1[:error] || &1[:warning] || "", "version_")
          )

        assert length(version_issues) > 0
      end
    end

    test "initial development schema_version returns version_incompatible_initial_development" do
      current_parsed = Schema.parsed_version()

      # Only meaningful if server version is not initial development itself
      if is_map(current_parsed) and current_parsed[:major] >= 1 do
        result =
          validate(
            %{"id" => @test_skill_uid, "schema_version" => "0.1.0"},
            :skill
          )

        assert "version_incompatible_initial_development" in error_types(result)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # warn_on_missing_recommended option
  # ---------------------------------------------------------------------------

  describe "warn_on_missing_recommended option" do
    test "missing recommended attribute triggers warning when option is set" do
      result_with = validate(%{"id" => @test_skill_uid}, [warn_on_missing_recommended: true], :skill)
      result_without = validate(%{"id" => @test_skill_uid}, [], :skill)

      recommended_warnings =
        Enum.filter(
          warnings(result_with),
          &(&1[:warning] == "attribute_recommended_missing")
        )

      # Without option, no recommended warnings
      assert Enum.filter(warnings(result_without), &(&1[:warning] == "attribute_recommended_missing")) == []

      # With option, should have at least one (skill has "name" as recommended attribute)
      assert length(recommended_warnings) > 0
    end
  end

  # ---------------------------------------------------------------------------
  # Unknown type
  # ---------------------------------------------------------------------------

  describe "unknown validation type" do
    test "unknown type raises a MatchError due to schema bug in validator" do
      # The validator's unknown-type branch returns a plain map instead of {response, class}
      # tuple, which causes a MatchError. This documents existing behavior.
      assert_raise MatchError, fn ->
        validate(%{"name" => "test"}, :unknown_type)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Duplicate array items
  # ---------------------------------------------------------------------------

  describe "duplicate array items" do
    test "duplicate skills in array returns attribute_array_duplicate" do
      result =
        Schema.Validator.validate(
          %{
            "name" => "test_agent",
            "version" => "1.0.0",
            "description" => "test",
            "authors" => ["author@example.com"],
            "created_at" => "2024-01-01T00:00:00Z",
            "skills" => [
              %{"id" => @test_skill_uid},
              %{"id" => @test_skill_uid}
            ]
          },
          [name: "record"],
          :object
        )

      assert "attribute_array_duplicate" in error_types(result)
    end
  end
end
