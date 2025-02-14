# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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

  @spec categories :: map()
  def categories() do
    Agent.get(__MODULE__, fn schema -> Cache.categories(schema) end)
  end

  @spec categories(extensions_t() | nil) :: map()
  def categories(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.categories(schema) end)
  end

  def categories(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.categories(schema)
      |> Map.update!(:attributes, fn attributes -> filter(attributes, extensions) end)
    end)
  end

  @spec category(atom) :: nil | Cache.category_t()
  def category(id) do
    category(nil, id)
  end

  @spec category(extensions_t() | nil, atom) :: nil | Cache.category_t()
  def category(extensions, id) do
    Agent.get(__MODULE__, fn schema ->
      case Cache.category(schema, id) do
        nil ->
          nil

        category ->
          add_classes(extensions, {id, category}, Cache.classes(schema))
      end
    end)
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

  @spec classes() :: map()
  def classes() do
    Agent.get(__MODULE__, fn schema -> Cache.classes(schema) end)
  end

  @spec classes(extensions_t() | nil) :: map()
  def classes(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.classes(schema) end)
  end

  def classes(extensions) do
    Agent.get(__MODULE__, fn schema -> Cache.classes(schema) |> filter(extensions) end)
  end

  @spec all_classes() :: map()
  def all_classes() do
    Agent.get(__MODULE__, fn schema -> Cache.all_classes(schema) end)
  end

  @spec all_objects() :: map()
  def all_objects() do
    Agent.get(__MODULE__, fn schema -> Cache.all_objects(schema) end)
  end

  @spec export_classes() :: map()
  def export_classes() do
    Agent.get(__MODULE__, fn schema -> Cache.export_classes(schema) end)
  end

  @spec export_classes(extensions_t() | nil) :: map()
  def export_classes(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.export_classes(schema) end)
  end

  def export_classes(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_classes(schema) |> filter(extensions)
    end)
  end

  @spec export_base_event() :: map()
  def export_base_event() do
    Agent.get(__MODULE__, fn schema -> Cache.export_base_event(schema) end)
  end

  @spec class(atom) :: nil | Cache.class_t()
  def class(id) do
    Agent.get(__MODULE__, fn schema -> Cache.class(schema, id) end)
  end

  @spec class_ex(atom) :: nil | Cache.class_t()
  def class_ex(id) do
    Agent.get(__MODULE__, fn schema -> Cache.class_ex(schema, id) end)
  end

  @spec find_class(any) :: nil | map
  def find_class(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_class(schema, uid) end)
  end

  @spec objects() :: map()
  def objects() do
    Agent.get(__MODULE__, fn schema -> Cache.objects(schema) end)
  end

  @spec objects(extensions_t() | nil) :: map()
  def objects(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.objects(schema) end)
  end

  def objects(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.objects(schema) |> filter(extensions)
    end)
  end

  @spec export_objects() :: map()
  def export_objects() do
    Agent.get(__MODULE__, fn schema -> Cache.export_objects(schema) end)
  end

  @spec export_objects(extensions_t() | nil) :: map()
  def export_objects(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.export_objects(schema) end)
  end

  def export_objects(extensions) do
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
    Agent.get(__MODULE__, fn schema -> Cache.object(schema, id) end)
    |> Map.update(:_links, [], fn links -> remove_extension_links(links, extensions) end)
  end

  @spec object_ex(atom) :: nil | Cache.class_t()
  def object_ex(id) do
    Agent.get(__MODULE__, fn schema -> Cache.object_ex(schema, id) end)
  end

  @spec object_ex(extensions_t() | nil, atom) :: nil | Cache.class_t()
  def object_ex(nil, id) do
    Agent.get(__MODULE__, fn schema -> Cache.object_ex(schema, id) end)
  end

  def object_ex(extensions, id) do
    Agent.get(__MODULE__, fn schema -> Cache.object_ex(schema, id) end)
    |> Map.update(:_links, [], fn links -> remove_extension_links(links, extensions) end)
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

  defp add_classes(nil, {id, category}, classes) do
    category_uid = Atom.to_string(id)

    list =
      classes
      |> Stream.filter(fn {_name, class} ->
        cat = Map.get(class, :category)
        cat == category_uid or Utils.to_uid(class[:extension], cat) == id
      end)
      |> Stream.map(fn {name, class} ->
        class =
          class
          |> Map.delete(:category)
          |> Map.delete(:category_name)

        {name, class}
      end)
      |> Enum.to_list()

    Map.put(category, :classes, list)
    |> Map.put(:name, category_uid)
  end

  defp add_classes(extensions, {id, category}, classes) do
    category_uid = Atom.to_string(id)

    list =
      Enum.filter(
        classes,
        fn {_name, class} ->
          cat = class[:category]

          case class[:extension] do
            nil ->
              cat == category_uid

            ext ->
              MapSet.member?(extensions, ext) and
                (cat == category_uid or Utils.to_uid(ext, cat) == id)
          end
        end
      )

    Map.put(category, :classes, list)
  end
end
