# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.ProfilesTest do
  use ExUnit.Case, async: true

  alias Schema.Profiles

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # apply_profiles returns filtered attributes as a list of {key, value} tuples.
  defp attr_keys(result), do: result.attributes |> Enum.map(&elem(&1, 0))

  # Build a minimal class map that apply_profiles expects.
  # entities must be a map of {name => %{attributes: ...}}.
  defp minimal_class(attributes, entities \\ %{}) do
    %{attributes: attributes, entities: entities}
  end

  # ---------------------------------------------------------------------------
  # apply_profiles/2 — list input
  # ---------------------------------------------------------------------------

  describe "apply_profiles/2 with list of profile names" do
    test "empty profile list removes all profiled attributes" do
      attrs = %{
        a: %{caption: "A"},
        b: %{caption: "B", profile: "security"}
      }

      result = Profiles.apply_profiles(minimal_class(attrs), [])
      keys = attr_keys(result)
      assert :a in keys
      refute :b in keys
    end

    test "matching profile keeps matching profiled attributes" do
      attrs = %{
        a: %{caption: "A"},
        b: %{caption: "B", profile: "security"},
        c: %{caption: "C", profile: "network"}
      }

      result = Profiles.apply_profiles(minimal_class(attrs), ["security"])
      keys = attr_keys(result)
      assert :a in keys
      assert :b in keys
      refute :c in keys
    end

    test "multiple profiles keep attributes matching any of them" do
      attrs = %{
        x: %{caption: "X", profile: "p1"},
        y: %{caption: "Y", profile: "p2"},
        z: %{caption: "Z", profile: "p3"}
      }

      result = Profiles.apply_profiles(minimal_class(attrs), ["p1", "p2"])
      keys = attr_keys(result)
      assert :x in keys
      assert :y in keys
      refute :z in keys
    end

    test "attributes without a profile key are always kept" do
      attrs = %{always: %{caption: "Always"}}
      result = Profiles.apply_profiles(minimal_class(attrs), ["anything"])
      assert :always in attr_keys(result)
    end
  end

  # ---------------------------------------------------------------------------
  # apply_profiles/2 — MapSet input
  # ---------------------------------------------------------------------------

  describe "apply_profiles/2 with MapSet" do
    test "MapSet input behaves the same as list" do
      attrs = %{
        a: %{caption: "A"},
        b: %{caption: "B", profile: "sec"}
      }

      result = Profiles.apply_profiles(minimal_class(attrs), MapSet.new(["sec"]))
      keys = attr_keys(result)
      assert :a in keys
      assert :b in keys
    end
  end

  # ---------------------------------------------------------------------------
  # apply_profiles/2 — entities are also filtered
  # ---------------------------------------------------------------------------

  describe "apply_profiles/2 filters nested entity attributes" do
    test "entity attributes are filtered by the same profiles" do
      entity_attrs = %{
        visible: %{caption: "Visible"},
        hidden: %{caption: "Hidden", profile: "other"}
      }

      class = %{
        attributes: %{},
        entities: %{my_entity: %{attributes: entity_attrs}}
      }

      result = Profiles.apply_profiles(class, [])
      {_name, entity} = hd(result.entities)
      entity_keys = entity.attributes |> Enum.map(&elem(&1, 0))
      assert :visible in entity_keys
      refute :hidden in entity_keys
    end
  end

  # ---------------------------------------------------------------------------
  # sanity_check/3
  # ---------------------------------------------------------------------------

  describe "sanity_check/3" do
    test "returns profiles unchanged when items have no profiles key" do
      items = %{item_a: %{caption: "A"}}
      profiles = %{"sec" => %{caption: "Security"}}
      result = Profiles.sanity_check("skills", items, profiles)
      assert result == profiles
    end

    test "adds _links to matching profile" do
      items = %{
        my_skill: %{caption: "My Skill", profiles: ["sec"]}
      }

      profiles = %{"sec" => %{caption: "Security"}}
      result = Profiles.sanity_check("skills", items, profiles)
      assert length(result["sec"][:_links]) == 1
    end

    test "logs warning and leaves profiles unchanged for undefined profiles" do
      items = %{my_skill: %{caption: "My Skill", profiles: ["nonexistent"]}}
      profiles = %{"sec" => %{caption: "Security"}}
      # Should not raise; missing profile is warned and skipped
      result = Profiles.sanity_check("skills", items, profiles)
      assert result == profiles
    end
  end
end
