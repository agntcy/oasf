# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.GraphTest do
  use ExUnit.Case, async: false

  alias Schema.Graph

  # Build a minimal class suitable for Graph.build/1.
  # Note: entities must be a map (not a keyword list) and attribute values
  # must have at minimum a :type key since build_edges accesses obj.type.
  defp minimal_class(opts \\ []) do
    %{
      name: Keyword.get(opts, :name, "test_class"),
      caption: Keyword.get(opts, :caption, "Test Class"),
      family: Keyword.get(opts, :family),
      extension: Keyword.get(opts, :extension),
      category: Keyword.get(opts, :category, false),
      attributes: Keyword.get(opts, :attributes, %{}),
      entities: Keyword.get(opts, :entities, %{})
    }
  end

  # ---------------------------------------------------------------------------
  # build/1 — return shape
  # ---------------------------------------------------------------------------

  describe "build/1 return structure" do
    test "returns a map with nodes, edges, and class keys" do
      result = Graph.build(minimal_class())
      assert Map.has_key?(result, :nodes)
      assert Map.has_key?(result, :edges)
      assert Map.has_key?(result, :class)
      assert is_list(result.nodes)
      assert is_list(result.edges)
      assert is_map(result.class)
    end

    test "class key strips :attributes, :entities, :_links" do
      # attributes values need a :type key for build_edges to work
      class =
        minimal_class(attributes: %{f: %{type: "string_t", _source: :test_class, caption: "F"}})
        |> Map.put(:_links, [])

      result = Graph.build(class)
      refute Map.has_key?(result.class, :attributes)
      refute Map.has_key?(result.class, :entities)
      refute Map.has_key?(result.class, :_links)
    end
  end

  # ---------------------------------------------------------------------------
  # build/1 — nodes
  # ---------------------------------------------------------------------------

  describe "build/1 nodes" do
    test "root node has correct id and label" do
      class = minimal_class(name: "my_class", caption: "My Class")
      result = Graph.build(class)
      root = Enum.find(result.nodes, fn n -> n.id == "my_class" end)
      assert root != nil
      assert root.label == "My Class"
    end

    test "category class node has font color set" do
      class = minimal_class(name: "cat_class", caption: "Cat", category: true)
      result = Graph.build(class)
      root = Enum.find(result.nodes, fn n -> n.id == "cat_class" end)
      assert root != nil
      assert Map.has_key?(root, :font)
    end

    test "non-category class node has no font key" do
      class = minimal_class(name: "reg_class", caption: "Regular")
      result = Graph.build(class)
      root = Enum.find(result.nodes, fn n -> n.id == "reg_class" end)
      assert root != nil
      refute Map.has_key?(root, :font)
    end

    test "entity nodes are included" do
      entity = %{
        name: "child_obj",
        caption: "Child",
        family: nil,
        extension: nil,
        category: false,
        is_enum: false,
        attributes: %{}
      }

      class = minimal_class(entities: %{child_obj: entity})
      result = Graph.build(class)
      ids = Enum.map(result.nodes, & &1.id)
      assert "child_obj" in ids
    end
  end

  # ---------------------------------------------------------------------------
  # build/1 — edges
  # ---------------------------------------------------------------------------

  describe "build/1 edges" do
    test "object_t attribute produces an edge from class to object type" do
      entity = %{
        name: "locator",
        caption: "Locator",
        family: nil,
        extension: nil,
        category: false,
        is_enum: false,
        attributes: %{}
      }

      class =
        minimal_class(
          name: "record",
          caption: "Record",
          entities: %{locator: entity},
          attributes: %{
            loc: %{
              type: "object_t",
              object_type: "locator",
              requirement: "optional",
              _source: :record,
              caption: "Locator"
            }
          }
        )

      result = Graph.build(class)
      assert length(result.edges) > 0
      edge = hd(result.edges)
      assert edge.from == "record"
      assert edge.to == "locator"
    end

    test "non-object/class attributes produce no edges" do
      class =
        minimal_class(
          name: "simple",
          caption: "Simple",
          attributes: %{
            name: %{type: "string_t", requirement: "required", _source: :simple, caption: "Name"}
          }
        )

      result = Graph.build(class)
      assert result.edges == []
    end
  end

  # ---------------------------------------------------------------------------
  # build/1 — real schema objects
  # ---------------------------------------------------------------------------

  describe "build/1 with real schema objects" do
    test "builds graph for a known domain class" do
      # Use a domain that is known to have a proper entities map
      domain = Schema.domain("internet_of_things")

      if domain && is_map(domain[:entities]) do
        result = Graph.build(domain)
        assert is_map(result)
        assert is_list(result.nodes)
        assert length(result.nodes) >= 1
        assert is_list(result.edges)
      end
    end
  end
end
