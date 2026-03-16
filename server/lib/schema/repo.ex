# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Repo do
  @moduledoc """
  This module keeps a cache of the schema files.
  """
  use Agent

  alias Schema.Cache
  alias Schema.Utils

  @typedoc """
  Defines a set of extensions.
  """
  @type extensions_t() :: MapSet.t(binary())

  @type profiles_t() :: MapSet.t(binary())

  @spec start :: {:error, any} | {:ok, pid}
  def start(), do: Agent.start(fn -> Cache.init() end, name: __MODULE__)

  @spec start_link(any) :: {:error, any} | {:ok, pid}
  def start_link(_), do: Agent.start_link(fn -> Cache.init() end, name: __MODULE__)

  @spec version :: String.t()
  def version(), do: Agent.get(__MODULE__, fn schema -> Cache.version(schema) end)

  @spec parsed_version :: Utils.version_or_error_t()
  def parsed_version(), do: Agent.get(__MODULE__, fn schema -> Cache.parsed_version(schema) end)

  @spec profiles :: map()
  def profiles() do
    Agent.get(__MODULE__, fn schema -> Cache.profiles(schema) end)
  end

  @spec profiles(extensions_t() | nil) :: map()
  def profiles(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.profiles(schema) end)
  end

  def profiles(extensions) do
    Agent.get(__MODULE__, fn schema -> Cache.profiles(schema) |> filter(extensions) end)
  end

  @spec data_types() :: map()
  def data_types() do
    Agent.get(__MODULE__, fn schema -> Cache.data_types(schema) end)
  end

  @spec dictionary() :: Cache.dictionary_t()
  def dictionary() do
    Agent.get(__MODULE__, fn schema -> Cache.dictionary(schema) end)
  end

  @spec dictionary(extensions_t() | nil) :: Cache.dictionary_t()
  def dictionary(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.dictionary(schema) end)
  end

  def dictionary(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.dictionary(schema)
      |> Map.update!(:attributes, fn attributes ->
        filter(attributes, extensions)
      end)
    end)
  end

  @spec skills() :: map()
  def skills() do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_skills(schema) |> filter_category_classes()
    end)
  end

  @spec skills(extensions_t() | nil) :: map()
  def skills(nil) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_skills(schema) |> filter_category_classes()
    end)
  end

  def skills(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_skills(schema) |> filter_category_classes() |> filter(extensions)
    end)
  end

  @spec all_skills() :: map()
  def all_skills() do
    Agent.get(__MODULE__, fn schema ->
      Cache.skills(schema) |> build_all_classes()
    end)
  end

  @spec domains() :: map()
  def domains() do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_domains(schema) |> filter_category_classes()
    end)
  end

  @spec domains(extensions_t() | nil) :: map()
  def domains(nil) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_domains(schema) |> filter_category_classes()
    end)
  end

  def domains(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_domains(schema) |> filter_category_classes() |> filter(extensions)
    end)
  end

  @spec all_domains() :: map()
  def all_domains() do
    Agent.get(__MODULE__, fn schema ->
      Cache.domains(schema) |> build_all_classes()
    end)
  end

  @spec modules() :: map()
  def modules() do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_modules(schema) |> filter_category_classes()
    end)
  end

  @spec modules(extensions_t() | nil) :: map()
  def modules(nil) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_modules(schema) |> filter_category_classes()
    end)
  end

  def modules(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_modules(schema) |> filter_category_classes() |> filter(extensions)
    end)
  end

  @spec all_modules() :: map()
  def all_modules() do
    Agent.get(__MODULE__, fn schema ->
      Cache.modules(schema) |> build_all_classes()
    end)
  end

  @spec all_objects() :: map()
  def all_objects() do
    Agent.get(__MODULE__, fn schema -> Cache.all_objects(schema) end)
  end

  @spec skill(atom) :: nil | Cache.class_t()
  def skill(id) do
    case Agent.get(__MODULE__, fn schema -> Cache.skill(schema, id) end) do
      nil ->
        nil

      skill ->
        # Don't return category classes - they should be accessed via category endpoints
        if Map.get(skill, :category) == true do
          nil
        else
          skill
        end
    end
  end

  @spec find_skill(any) :: nil | map
  def find_skill(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_skill(schema, uid) end)
  end

  @spec domain(atom) :: nil | Cache.class_t()
  def domain(id) do
    case Agent.get(__MODULE__, fn schema -> Cache.domain(schema, id) end) do
      nil ->
        nil

      domain ->
        # Don't return category classes - they should be accessed via category endpoints
        if Map.get(domain, :category) == true do
          nil
        else
          domain
        end
    end
  end

  @spec find_domain(any) :: nil | map
  def find_domain(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_domain(schema, uid) end)
  end

  @spec module(atom) :: nil | Cache.class_t()
  def module(id) do
    case Agent.get(__MODULE__, fn schema -> Cache.module(schema, id) end) do
      nil ->
        nil

      module ->
        # Don't return category classes - they should be accessed via category endpoints
        if Map.get(module, :category) == true do
          nil
        else
          module
        end
    end
  end

  @spec find_module(any) :: nil | map
  def find_module(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_module(schema, uid) end)
  end

  @spec objects() :: map()
  def objects() do
    Agent.get(__MODULE__, fn schema -> Cache.export_objects(schema) end)
  end

  @spec objects(extensions_t() | nil) :: map()
  def objects(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.export_objects(schema) end)
  end

  def objects(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_objects(schema) |> filter(extensions)
    end)
  end

  @spec object(atom) :: nil | Cache.class_t()
  def object(id) do
    Agent.get(__MODULE__, fn schema -> Cache.object(schema, id) end)
  end

  @spec object(extensions_t() | nil, atom) :: nil | Cache.class_t()
  def object(nil, id) do
    Agent.get(__MODULE__, fn schema -> Cache.object(schema, id) end)
  end

  def object(extensions, id) do
    case Agent.get(__MODULE__, fn schema -> Cache.object(schema, id) end) do
      nil ->
        nil

      object ->
        Map.update(object, :_links, [], fn links -> remove_extension_links(links, extensions) end)
    end
  end

  @spec entity_ex(atom, atom) :: nil | Cache.class_t()
  def entity_ex(type, id) do
    case Agent.get(__MODULE__, fn schema -> Cache.entity_ex(schema, type, id) end) do
      nil ->
        nil

      entity ->
        # Don't return category classes - they should be accessed via category endpoints
        if Map.get(entity, :category) == true do
          nil
        else
          entity
        end
    end
  end

  @spec entity_ex(extensions_t() | nil, atom, atom) :: nil | Cache.class_t()
  def entity_ex(nil, type, id) do
    entity_ex(type, id)
  end

  def entity_ex(extensions, type, id) do
    case Agent.get(__MODULE__, fn schema -> Cache.entity_ex(schema, type, id) end) do
      nil ->
        nil

      entity ->
        # Don't return category classes - they should be accessed via category endpoints
        if Map.get(entity, :category) == true do
          nil
        else
          Map.update(entity, :_links, [], fn links ->
            remove_extension_links(links, extensions)
          end)
        end
    end
  end

  @spec reload() :: :ok
  def reload() do
    Cache.reset()
    Agent.cast(__MODULE__, fn _ -> Cache.init() end)
  end

  @spec reload(String.t() | list()) :: :ok
  def reload(path) do
    Cache.reset(path)
    Agent.cast(__MODULE__, fn _ -> Cache.init() end)
  end

  defp filter(attributes, extensions) do
    Map.filter(attributes, fn {_k, f} ->
      extension = f[:extension]
      extension == nil or MapSet.member?(extensions, extension)
    end)
    |> filter_extension_links(extensions)
  end

  defp filter_extension_links(attributes, extensions) do
    Enum.into(attributes, %{}, fn {n, v} ->
      links = remove_extension_links(v[:_links], extensions)

      {n, Map.put(v, :_links, links)}
    end)
  end

  defp remove_extension_links(nil, _extensions), do: []

  defp remove_extension_links(links, extensions) do
    Enum.filter(links, fn link ->
      [ext | rest] = String.split(link[:type], "/")
      rest == [] or MapSet.member?(extensions, ext)
    end)
  end

  # Helper: Filter out category classes (category: true)
  defp filter_category_classes(classes) do
    classes
    |> Enum.filter(fn {key, class} ->
      key in Utils.base_classes() || Map.get(class, :category) != true
    end)
    |> Enum.into(%{})
  end

  # Helper: Build all_classes map with name, extends, caption, and category fields
  defp build_all_classes(classes) do
    classes
    |> Enum.map(fn {class_key, class} ->
      {class_key,
       %{
         name: class[:name],
         extends: class[:extends],
         caption: class[:caption],
         category: class[:category]
       }}
    end)
    |> Enum.into(%{})
  end

  @spec taxonomy_modules :: map()
  def taxonomy_modules() do
    taxonomy_modules(nil, nil)
  end

  @spec taxonomy_modules(extensions_t() | nil) :: map()
  def taxonomy_modules(extensions) do
    taxonomy_modules(extensions, nil)
  end

  @spec taxonomy_modules(extensions_t() | nil, String.t() | integer() | nil) :: map()
  def taxonomy_modules(extensions, parent) do
    Agent.get(__MODULE__, fn schema ->
      all_classes = Cache.modules(schema)
      tree = build_taxonomy_tree(extensions, all_classes, :base_module)
      filter_by_parent(tree, parent)
    end)
  end

  @spec taxonomy_skills :: map()
  def taxonomy_skills() do
    taxonomy_skills(nil, nil)
  end

  @spec taxonomy_skills(extensions_t() | nil) :: map()
  def taxonomy_skills(extensions) do
    taxonomy_skills(extensions, nil)
  end

  @spec taxonomy_skills(extensions_t() | nil, String.t() | integer() | nil) :: map()
  def taxonomy_skills(extensions, parent) do
    Agent.get(__MODULE__, fn schema ->
      all_classes = Cache.skills(schema)
      tree = build_taxonomy_tree(extensions, all_classes, :base_skill)
      filter_by_parent(tree, parent)
    end)
  end

  @spec taxonomy_domains :: map()
  def taxonomy_domains() do
    taxonomy_domains(nil, nil)
  end

  @spec taxonomy_domains(extensions_t() | nil) :: map()
  def taxonomy_domains(extensions) do
    taxonomy_domains(extensions, nil)
  end

  @spec taxonomy_domains(extensions_t() | nil, String.t() | integer() | nil) :: map()
  def taxonomy_domains(extensions, parent) do
    Agent.get(__MODULE__, fn schema ->
      all_classes = Cache.domains(schema)
      tree = build_taxonomy_tree(extensions, all_classes, :base_domain)
      filter_by_parent(tree, parent)
    end)
  end

  # Build a complete taxonomy tree with categories, subcategories, classes, and subclasses
  defp build_taxonomy_tree(extensions, all_classes, base_class_key) do
    # Filter out base class
    filtered_classes =
      Enum.filter(all_classes, fn {key, _class} ->
        key != base_class_key
      end)
      |> Enum.into(%{})

    # Apply extension filtering if needed
    filtered_classes =
      if extensions != nil do
        Enum.filter(filtered_classes, fn {_key, class} ->
          case class[:extension] do
            nil -> true
            ext -> MapSet.member?(extensions, ext)
          end
        end)
        |> Enum.into(%{})
      else
        filtered_classes
      end

    # Build tree structure using extends relationships
    # Returns a map: {parent_key => [child_keys]}
    children_map = build_children_map(filtered_classes, base_class_key)

    # Find top-level items (those that extend base_class_key or have no extends)
    top_level_keys = find_top_level_items(filtered_classes, base_class_key)

    # Build simplified tree starting from top-level
    Enum.reduce(top_level_keys, %{}, fn class_key, acc ->
      simplified = build_tree_item(class_key, filtered_classes, children_map)
      if simplified != nil, do: Map.put(acc, class_key, simplified), else: acc
    end)
  end

  # Build a map of parent -> [children] based on extends relationships
  defp build_children_map(all_classes, base_class_key) do
    Enum.reduce(all_classes, %{}, fn {class_key, class}, acc ->
      extends = class[:extends]

      # Determine parent key
      parent_key =
        cond do
          extends == nil -> nil
          String.to_atom(extends) == base_class_key -> nil
          true -> String.to_atom(extends)
        end

      # If parent exists in all_classes, add this as a child
      if parent_key != nil && Map.has_key?(all_classes, parent_key) do
        Map.update(acc, parent_key, [class_key], fn children ->
          [class_key | children]
        end)
      else
        acc
      end
    end)
  end

  # Find top-level items:
  # 1. Items with no extends
  # 2. Items that extend base_class_key
  # 3. Items whose parent is not in all_classes (was filtered out)
  defp find_top_level_items(all_classes, base_class_key) do
    Enum.filter(all_classes, fn {_class_key, class} ->
      extends = class[:extends]

      cond do
        extends == nil -> true
        String.to_atom(extends) == base_class_key -> true
        true -> not Map.has_key?(all_classes, String.to_atom(extends))
      end
    end)
    |> Enum.map(fn {class_key, _class} -> class_key end)
  end

  # Recursively build a tree item and its children
  defp build_tree_item(class_key, all_classes, children_map) do
    class = Map.get(all_classes, class_key)

    if class == nil do
      nil
    else
      # Get children of this class
      children_keys = Map.get(children_map, class_key, [])

      # Simplify this class/category
      simplified = simplify_class_or_category(class)

      # Recursively build children
      children =
        Enum.reduce(children_keys, %{}, fn child_key, acc ->
          child_simplified = build_tree_item(child_key, all_classes, children_map)

          if child_simplified != nil do
            Map.put(acc, child_key, child_simplified)
          else
            acc
          end
        end)

      # Add children to simplified class if any exist
      if map_size(children) > 0 do
        Map.put(simplified, :classes, children)
      else
        simplified
      end
    end
  end

  # Simplify a class or category to only include needed fields
  defp simplify_class_or_category(class) do
    hierarchical_name = get_hierarchical_name(class)
    is_category = Map.get(class, :category) == true
    deprecated = Map.has_key?(class, :"@deprecated")

    result = %{
      name: hierarchical_name,
      id: Map.get(class, :uid) || 0,
      caption: Map.get(class, :caption) || "",
      description: Map.get(class, :description) || ""
    }

    result =
      if is_category, do: Map.put(result, :category, true), else: result

    if deprecated, do: Map.put(result, :deprecated, true), else: result
  end

  # Extract hierarchical name from class attributes.name.enum (already calculated in cache)
  defp get_hierarchical_name(class) do
    case get_in(class, [:attributes, :name, :enum]) do
      nil ->
        nil

      enum_map when is_map(enum_map) ->
        # Extract the hierarchical name from enum keys (stored as an atom key)
        case Enum.at(Map.keys(enum_map), 0) do
          nil -> nil
          enum_key -> Atom.to_string(enum_key)
        end
    end
  end

  # Filter taxonomy tree by parent name. If parent is nil, returns full tree.
  # If parent is provided, finds the parent node and returns it at the top level with its children nested.
  defp filter_by_parent(tree, nil), do: tree

  defp filter_by_parent(tree, parent_id) when is_integer(parent_id) do
    case find_node_by_id_with_key(tree, parent_id) do
      nil ->
        # Parent not found, return empty map
        %{}

      {parent_key, parent_node} ->
        # Return the parent node at the top level with its children nested
        %{parent_key => parent_node}
    end
  end

  defp filter_by_parent(tree, parent_name) when is_binary(parent_name) do
    case find_node_by_name_with_key(tree, parent_name) do
      nil ->
        # Parent not found, return empty map
        %{}

      {parent_key, parent_node} ->
        # Return the parent node at the top level with its children nested
        %{parent_key => parent_node}
    end
  end

  # Recursively search for a node with matching ID in the taxonomy tree.
  # Returns both the key and the node, so we can reconstruct the top-level structure.
  defp find_node_by_id_with_key(tree, target_id) when is_map(tree) do
    Enum.reduce_while(tree, nil, fn {key, node}, _acc ->
      node_id = Map.get(node, :id)

      cond do
        # Found the target node by ID field
        node_id == target_id ->
          {:halt, {key, node}}

        # Check children recursively
        Map.has_key?(node, :classes) ->
          case find_node_by_id_with_key(Map.get(node, :classes, %{}), target_id) do
            nil -> {:cont, nil}
            found -> {:halt, found}
          end

        # Continue searching
        true ->
          {:cont, nil}
      end
    end)
  end

  defp find_node_by_id_with_key(_tree, _target_id), do: nil

  # Recursively search for a node with matching name in the taxonomy tree.
  # Handles both hierarchical names ("core/language_model/prompt") and simple names ("prompt").
  # Returns both the key and the node, so we can reconstruct the top-level structure.
  defp find_node_by_name_with_key(tree, target_name) when is_map(tree) do
    Enum.reduce_while(tree, nil, fn {key, node}, _acc ->
      node_name = Map.get(node, :name)
      key_name = Atom.to_string(key)

      # Check if this node matches by exact name, key, or last segment
      node_matches =
        cond do
          # Found the target node by exact name match (handles both hierarchical and simple)
          node_name == target_name ->
            true

          # Found the target node by key (for top-level items)
          key_name == target_name ->
            true

          # Found by last segment of hierarchical name (e.g., "prompt" from "core/language_model/prompt")
          # This allows searching by simple name even if the node has a hierarchical name
          is_binary(node_name) && String.contains?(node_name, "/") ->
            last_segment = node_name |> String.split("/") |> List.last()
            last_segment == target_name

          # Also check if key matches last segment (for cases where name might be nil or different)
          true ->
            false
        end

      if node_matches do
        {:halt, {key, node}}
      else
        # Check children recursively if this node doesn't match
        if Map.has_key?(node, :classes) do
          case find_node_by_name_with_key(Map.get(node, :classes, %{}), target_name) do
            nil -> {:cont, nil}
            found -> {:halt, found}
          end
        else
          {:cont, nil}
        end
      end
    end)
  end

  defp find_node_by_name_with_key(_tree, _target_name), do: nil
end
