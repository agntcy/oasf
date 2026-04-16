# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.SchemaIntegrityTest do
  @moduledoc """
  Validates the integrity of the loaded schema data.

  These tests operate on the in-memory schema loaded at startup and cover:
    - Unique names within each entity type
    - Valid `extends` references (all parents exist)
    - No inheritance cycles
    - Attribute dictionary consistency (all attributes used in classes/objects
      must be defined in the dictionary)

  Raw JSON metaschema validation (verifying each .json file in schema/ against
  schema/metaschema/*.schema.json) is handled separately by
  `schema/check_metaschema.py`, which runs as `task test:schema` in CI.
  """

  use ExUnit.Case, async: false

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Returns a flat map of all entities of a given type (including base/category)
  defp all_items(:skill), do: Schema.all_skills()
  defp all_items(:domain), do: Schema.all_domains()
  defp all_items(:module), do: Schema.all_modules()
  defp all_items(:object), do: Schema.all_objects()

  defp base_class_names do
    Schema.Utils.base_classes() |> Enum.map(&Atom.to_string/1) |> MapSet.new()
  end

  # DFS cycle detection: returns true if item_name leads back to itself
  defp has_cycle?(item_name, items, visiting \\ MapSet.new()) do
    if MapSet.member?(visiting, item_name) do
      true
    else
      key = String.to_atom(item_name)

      case Map.get(items, key) do
        nil ->
          false

        item ->
          case item[:extends] do
            nil ->
              false

            parent_name ->
              has_cycle?(parent_name, items, MapSet.put(visiting, item_name))
          end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Unique name tests
  # ---------------------------------------------------------------------------

  describe "unique names" do
    test "all skill names are unique (no duplicate atom keys)" do
      skills = all_items(:skill)
      keys = Map.keys(skills)
      assert length(keys) == length(Enum.uniq(keys))
    end

    test "all domain names are unique" do
      domains = all_items(:domain)
      keys = Map.keys(domains)
      assert length(keys) == length(Enum.uniq(keys))
    end

    test "all module names are unique" do
      modules = all_items(:module)
      keys = Map.keys(modules)
      assert length(keys) == length(Enum.uniq(keys))
    end

    test "all object names are unique" do
      objects = all_items(:object)
      keys = Map.keys(objects)
      assert length(keys) == length(Enum.uniq(keys))
    end
  end

  # ---------------------------------------------------------------------------
  # Valid extends references
  # ---------------------------------------------------------------------------

  describe "extends references" do
    for entity_type <- [:skill, :domain, :module] do
      @entity_type entity_type

      test "all #{entity_type} extends references point to existing #{entity_type}s" do
        items = all_items(@entity_type)
        base_names = base_class_names()

        invalid =
          Enum.filter(items, fn {_key, item} ->
            case item[:extends] do
              nil ->
                false

              parent_name ->
                parent_key = String.to_atom(parent_name)

                not Map.has_key?(items, parent_key) and
                  not MapSet.member?(base_names, parent_name)
            end
          end)

        assert invalid == [],
               "#{@entity_type}s with invalid extends: #{Enum.map(invalid, fn {k, _} -> k end) |> inspect()}"
      end
    end

    test "all object extends references point to existing objects" do
      objects = all_items(:object)

      invalid =
        Enum.filter(objects, fn {_key, item} ->
          case item[:extends] do
            nil ->
              false

            parent_name ->
              parent_key = String.to_atom(parent_name)
              not Map.has_key?(objects, parent_key)
          end
        end)

      assert invalid == [],
             "Objects with invalid extends: #{Enum.map(invalid, fn {k, _} -> k end) |> inspect()}"
    end
  end

  # ---------------------------------------------------------------------------
  # No inheritance cycles
  # ---------------------------------------------------------------------------

  describe "inheritance cycles" do
    for entity_type <- [:skill, :domain, :module, :object] do
      @entity_type entity_type

      test "no inheritance cycles in #{entity_type}s" do
        items = all_items(@entity_type)

        cyclic =
          Enum.filter(items, fn {key, item} ->
            case item[:extends] do
              nil ->
                false

              _parent ->
                has_cycle?(Atom.to_string(key), items)
            end
          end)

        assert cyclic == [],
               "#{@entity_type}s with inheritance cycles: #{Enum.map(cyclic, fn {k, _} -> k end) |> inspect()}"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Attribute dictionary consistency
  # ---------------------------------------------------------------------------

  describe "attribute dictionary consistency" do
    test "dictionary contains at least the primitive types" do
      dict = Schema.dictionary()
      types = dict[:types][:attributes]
      assert Map.has_key?(types, :string_t)
      assert Map.has_key?(types, :integer_t)
      assert Map.has_key?(types, :boolean_t)
    end

    test "all attribute types used in objects are defined in dictionary or are object_t/class_t" do
      dict = Schema.dictionary()
      type_keys = dict[:types][:attributes] |> Map.keys() |> MapSet.new()
      objects = all_items(:object)

      special_types = MapSet.new(["object_t", "class_t"])

      bad_attrs =
        Enum.flat_map(objects, fn {obj_key, obj} ->
          attrs = obj[:attributes] || %{}

          Enum.filter(attrs, fn {_attr_key, attr} ->
            type = attr[:type]

            if type == nil do
              false
            else
              type_atom = String.to_atom(type)

              not MapSet.member?(type_keys, type_atom) and
                not MapSet.member?(special_types, type)
            end
          end)
          |> Enum.map(fn {attr_key, attr} ->
            "#{obj_key}.#{attr_key} (type: #{attr[:type]})"
          end)
        end)

      assert bad_attrs == [],
             "Attributes with unknown types: #{inspect(bad_attrs)}"
    end

    test "all attribute types used in skills are defined in dictionary or are object_t/class_t" do
      dict = Schema.dictionary()
      type_keys = dict[:types][:attributes] |> Map.keys() |> MapSet.new()
      skills = all_items(:skill)
      special_types = MapSet.new(["object_t", "class_t"])

      bad_attrs =
        Enum.flat_map(skills, fn {skill_key, skill} ->
          attrs = skill[:attributes] || %{}

          Enum.filter(attrs, fn {_attr_key, attr} ->
            type = attr[:type]

            if type == nil do
              false
            else
              type_atom = String.to_atom(type)

              not MapSet.member?(type_keys, type_atom) and
                not MapSet.member?(special_types, type)
            end
          end)
          |> Enum.map(fn {attr_key, attr} ->
            "#{skill_key}.#{attr_key} (type: #{attr[:type]})"
          end)
        end)

      assert bad_attrs == [],
             "Skill attributes with unknown types: #{inspect(bad_attrs)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Category classes are not in the flat skills/domains/modules lists
  # ---------------------------------------------------------------------------

  describe "category class filtering" do
    test "Schema.skills() does not include category-only skills" do
      flat_skills = Schema.skills()

      categories =
        Enum.filter(flat_skills, fn {_k, v} -> Map.get(v, :category) == true end)

      assert categories == [],
             "Category skills present in Schema.skills(): #{Enum.map(categories, fn {k, _} -> k end) |> inspect()}"
    end

    test "Schema.domains() does not include category-only domains" do
      flat_domains = Schema.domains()

      categories =
        Enum.filter(flat_domains, fn {_k, v} -> Map.get(v, :category) == true end)

      assert categories == [],
             "Category domains present in Schema.domains(): #{Enum.map(categories, fn {k, _} -> k end) |> inspect()}"
    end

    test "Schema.modules() does not include category-only modules" do
      flat_modules = Schema.modules()

      categories =
        Enum.filter(flat_modules, fn {_k, v} -> Map.get(v, :category) == true end)

      assert categories == [],
             "Category modules present in Schema.modules(): #{Enum.map(categories, fn {k, _} -> k end) |> inspect()}"
    end
  end

  # ---------------------------------------------------------------------------
  # Schema version is valid semver
  # ---------------------------------------------------------------------------

  describe "schema version" do
    test "schema version string is non-empty" do
      version = Schema.version()
      assert is_binary(version)
      assert String.length(version) > 0
    end

    test "schema version is parseable semver" do
      version = Schema.version()
      parsed = Schema.Utils.parse_version(version)

      assert is_map(parsed),
             "Schema version #{inspect(version)} is not valid semver: #{inspect(parsed)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Skills, domains, modules have UIDs
  # ---------------------------------------------------------------------------

  describe "non-base class UIDs" do
    test "non-base, non-category skills have a uid" do
      # Schema.skills() returns the fully processed/exported data (includes uid, filters categories)
      skills_without_uid =
        Schema.skills()
        |> Enum.filter(fn {_k, v} -> is_nil(v[:uid]) end)

      assert skills_without_uid == [],
             "Skills without uid: #{Enum.map(skills_without_uid, fn {k, _} -> k end) |> inspect()}"
    end

    test "non-base, non-category domains have a uid" do
      domains_without_uid =
        Schema.domains()
        |> Enum.filter(fn {_k, v} -> is_nil(v[:uid]) end)

      assert domains_without_uid == [],
             "Domains without uid: #{Enum.map(domains_without_uid, fn {k, _} -> k end) |> inspect()}"
    end

    test "non-base, non-category modules have a uid" do
      modules_without_uid =
        Schema.modules()
        |> Enum.filter(fn {_k, v} -> is_nil(v[:uid]) end)

      assert modules_without_uid == [],
             "Modules without uid: #{Enum.map(modules_without_uid, fn {k, _} -> k end) |> inspect()}"
    end
  end

  # ---------------------------------------------------------------------------
  # Skills are not empty (sanity check that schema loaded)
  # ---------------------------------------------------------------------------

  describe "schema loaded" do
    test "schema has at least one skill" do
      assert map_size(Schema.all_skills()) > 0
    end

    test "schema has at least one domain" do
      assert map_size(Schema.all_domains()) > 0
    end

    test "schema has at least one module" do
      assert map_size(Schema.all_modules()) > 0
    end

    test "schema has at least one object" do
      assert map_size(Schema.all_objects()) > 0
    end

    test "dictionary has attributes" do
      dict = Schema.dictionary()
      assert map_size(dict[:attributes]) > 0
    end
  end
end
