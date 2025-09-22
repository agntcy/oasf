# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Graph do
  @moduledoc """
  This module generates graph data to display class diagram.
  """

  alias Schema.Utils

  @doc """
  Builds graph data for the given class.
  """
  @spec build(map()) :: map()
  def build(class) do
    %{
      nodes: build_nodes(class),
      edges: build_edges(class) |> Enum.uniq(),
      class: Map.delete(class, :attributes) |> Map.delete(:entities) |> Map.delete(:_links)
    }
  end

  defp build_nodes(class) do
    node =
      Map.new()
      |> Map.put(:color, "#F5F5C8")
      |> Map.put(:id, make_id(class.name, nil, class[:extension]))
      |> Map.put(:label, class.caption)

    build_nodes([node], class)
  end

  defp build_nodes(nodes, class) do
    Map.get(class, :entities)
    |> Enum.reduce(nodes, fn {_name, obj}, acc ->
      color =
        if obj[:family] do
          "#C8F5D0"
        else
          "#e3e9fb"
        end

      node = %{
        id: make_id(obj.name, obj[:family], obj[:extension]),
        label: obj.caption,
        color: color
      }

      acc =
        if not nodes_member?(nodes, node) do
          [node | acc]
        else
          acc
        end

      if obj[:is_enum] do
        children =
          get_collection_by_family(obj)
          |> then(fn {collection, parent_name} ->
            Utils.find_children(collection, parent_name)
          end)

        Enum.reduce(children, acc, fn child, acc2 ->
          child_node = %{
            id: make_id(child.name, obj[:family], child[:extension]),
            label: child.caption,
            color: color
          }

          if not nodes_member?(nodes ++ acc, child_node) do
            [child_node | acc2]
          else
            acc2
          end
        end)
      else
        acc
      end
    end)
  end

  defp make_id(name, nil, nil) do
    name
  end

  defp make_id(name, nil, ext) do
    Path.join(ext, name)
  end

  defp make_id(name, family, nil) do
    Path.join(family, name)
  end

  defp make_id(name, family, ext) do
    Path.join([ext, family, name])
  end

  defp nodes_member?(nodes, node) do
    Enum.any?(nodes, fn n -> n.id == node.id end)
  end

  defp build_edges(class) do
    objects = Map.new(class.entities)
    build_edges([], class, objects)
  end

  defp build_edges(edges, class, objects) do
    Map.get(class, :attributes)
    |> Enum.reduce(edges, fn {name, obj}, acc ->
      acc =
        case obj.type do
          "object_t" ->
            recursive? = edges_member?(acc, obj)

            edge =
              %{
                source: Atom.to_string(obj[:_source]),
                group: obj[:group],
                requirement: obj[:requirement] || "optional",
                from: make_id(class.name, nil, class[:extension]),
                to: obj.object_type || obj.class_type,
                label: Atom.to_string(name)
              }
              |> add_profile(obj[:profile])

            acc = [edge | acc]

            if not recursive? do
              o = objects[String.to_atom(obj.object_type || obj.class_type)]
              build_edges(acc, o, objects)
            else
              acc
            end

          "class_t" ->
            recursive? = edges_member?(acc, obj)

            edge =
              %{
                source: Atom.to_string(obj[:_source]),
                group: obj[:group],
                requirement: obj[:requirement] || "optional",
                from: make_id(class.name, class[:family], class[:extension]),
                to: make_id(obj.class_type || obj.object_type, obj[:family], obj[:extension]),
                label: Atom.to_string(name)
              }
              |> add_profile(obj[:profile])

            acc = [edge | acc]

            if not recursive? do
              o = objects[String.to_atom(obj.class_type || obj.object_type)]
              build_edges(acc, o, objects)
            else
              acc
            end

          _ ->
            acc
        end

      if obj[:is_enum] do
        {collection, name} = get_collection_by_family(obj)

        # Recursive function to add edges for all descendants
        add_descendant_edges = fn add_descendant_edges,
                                  parent_name,
                                  parent_family,
                                  parent_extension,
                                  acc_in ->
          children = Utils.find_direct_children(collection, parent_name)

          Enum.reduce(children, acc_in, fn child, acc2 ->
            edge = %{
              from: make_id(parent_name, parent_family, parent_extension),
              to: make_id(child.name, parent_family, child[:extension]),
              label: obj[:family] || "enum",
              color: "#D6A5FF"
            }

            # Recursively add edges for child's children
            add_descendant_edges.(
              add_descendant_edges,
              child.name,
              parent_family,
              child[:extension],
              [edge | acc2]
            )
          end)
        end

        add_descendant_edges.(add_descendant_edges, name, obj[:family], obj[:extension], acc)
      else
        acc
      end
    end)
  end

  defp edges_member?(edges, entity) do
    type = entity[:object_type] || entity[:class_type]
    Enum.any?(edges, fn edge -> type == edge.to end)
  end

  defp add_profile(edge, nil) do
    edge
  end

  defp add_profile(edge, profile) do
    Map.put(edge, :profile, profile)
  end

  defp get_collection_by_family(entity) do
    case entity[:family] do
      "skill" -> {Schema.all_skills(), entity[:name] || entity[:class_type]}
      "domain" -> {Schema.all_domains(), entity[:name] || entity[:class_type]}
      "module" -> {Schema.all_modules(), entity[:name] || entity[:class_type]}
      _ -> {Schema.all_objects(), entity[:name] || entity[:object_type]}
    end
  end
end
