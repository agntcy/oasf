# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Schema.Graph do
  @moduledoc """
  This module generates graph data to display event class diagram.
  """

  @doc """
  Builds graph data for the given class.
  """
  @spec build(map()) :: map()
  def build(class) do
    %{
      nodes: build_nodes(class),
      edges: build_edges(class) |> Enum.uniq(),
      class: Map.delete(class, :attributes) |> Map.delete(:objects) |> Map.delete(:_links)
    }
  end

  defp build_nodes(class) do
    node =
      Map.new()
      |> Map.put(:color, "#F5F5C8")
      |> Map.put(:id, make_id(class.name, class[:extension]))
      |> Map.put(:label, class.caption)

    build_nodes([node], class)
  end

  defp build_nodes(nodes, class) do
    Map.get(class, :objects)
    |> Enum.reduce(nodes, fn {_name, obj}, acc ->
      node = %{
        id: make_id(obj.name, obj[:extension]),
        label: obj.caption
      }

      # Don't add class/object that is already added (present infinite loop)
      if not nodes_member?(nodes, node) do
        [node | acc]
      else
        acc
      end
    end)
  end

  defp make_id(name, nil) do
    name
  end

  defp make_id(name, ext) do
    Path.join(ext, name)
  end

  defp nodes_member?(nodes, node) do
    Enum.any?(nodes, fn n -> n.id == node.id end)
  end

  defp build_edges(class) do
    objects = Map.new(class.objects)
    build_edges([], class, objects)
  end

  defp build_edges(edges, class, objects) do
    Map.get(class, :attributes)
    |> Enum.reduce(edges, fn {name, obj}, acc ->
      case obj.type do
        "object_t" ->
          # For a recursive definition, we need to add the edge, creating the looping edge
          # and then we don't want to continue searching this path.
          recursive? = edges_member?(acc, obj)

          edge =
            %{
              source: Atom.to_string(obj[:_source]),
              group: obj[:group],
              requirement: obj[:requirement] || "optional",
              from: make_id(class.name, class[:extension]),
              to: obj.object_type,
              label: Atom.to_string(name)
            }
            |> add_profile(obj[:profile])

          acc = [edge | acc]

          # For recursive definitions, we've already added the edge creating the loop in the graph.
          # There's no need to recurse further (avoid infinite loops).
          if not recursive? do
            o = objects[String.to_atom(obj.object_type)]
            build_edges(acc, o, objects)
          else
            acc
          end

        _ ->
          acc
      end
    end)
  end

  defp edges_member?(edges, obj) do
    Enum.any?(edges, fn edge -> obj.object_type == edge.to end)
  end

  defp add_profile(edge, nil) do
    edge
  end

  defp add_profile(edge, profile) do
    Map.put(edge, :profile, profile)
  end
end
