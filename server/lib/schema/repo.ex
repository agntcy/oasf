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

  @spec main_skills :: map()
  def main_skills() do
    Agent.get(__MODULE__, fn schema -> Cache.main_skills(schema) end)
  end

  @spec main_skills(extensions_t() | nil) :: map()
  def main_skills(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.main_skills(schema) end)
  end

  def main_skills(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.main_skills(schema)
      |> Map.update!(:attributes, fn attributes -> filter(attributes, extensions) end)
    end)
  end

  @spec main_skill(atom) :: nil | Cache.category_t()
  def main_skill(id) do
    main_skill(nil, id)
  end

  @spec main_skill(extensions_t() | nil, atom) :: nil | Cache.category_t()
  def main_skill(extensions, id) do
    Agent.get(__MODULE__, fn schema ->
      case Cache.main_skill(schema, id) do
        nil ->
          nil

        main_skill ->
          add_classes(extensions, {id, main_skill}, Cache.skills(schema))
      end
    end)
  end

  @spec main_domains :: map()
  def main_domains() do
    Agent.get(__MODULE__, fn schema -> Cache.main_domains(schema) end)
  end

  @spec main_domains(extensions_t() | nil) :: map()
  def main_domains(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.main_domains(schema) end)
  end

  def main_domains(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.main_domains(schema)
      |> Map.update!(:attributes, fn attributes -> filter(attributes, extensions) end)
    end)
  end

  @spec main_domain(atom) :: nil | Cache.category_t()
  def main_domain(id) do
    main_domain(nil, id)
  end

  @spec main_domain(extensions_t() | nil, atom) :: nil | Cache.category_t()
  def main_domain(extensions, id) do
    Agent.get(__MODULE__, fn schema ->
      case Cache.main_domain(schema, id) do
        nil ->
          nil

        main_domain ->
          add_classes(extensions, {id, main_domain}, Cache.domains(schema))
      end
    end)
  end

  @spec main_modules :: map()
  def main_modules() do
    Agent.get(__MODULE__, fn schema -> Cache.main_modules(schema) end)
  end

  @spec main_modules(extensions_t() | nil) :: map()
  def main_modules(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.main_modules(schema) end)
  end

  def main_modules(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.main_modules(schema)
      |> Map.update!(:attributes, fn attributes -> filter(attributes, extensions) end)
    end)
  end

  @spec main_module(atom) :: nil | Cache.category_t()
  def main_module(id) do
    main_module(nil, id)
  end

  @spec main_module(extensions_t() | nil, atom) :: nil | Cache.category_t()
  def main_module(extensions, id) do
    Agent.get(__MODULE__, fn schema ->
      case Cache.main_module(schema, id) do
        nil ->
          nil

        main_module ->
          add_classes(extensions, {id, main_module}, Cache.modules(schema))
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

  @spec skills() :: map()
  def skills() do
    Agent.get(__MODULE__, fn schema -> Cache.skills(schema) end)
  end

  @spec skills(extensions_t() | nil) :: map()
  def skills(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.skills(schema) end)
  end

  def skills(extensions) do
    Agent.get(__MODULE__, fn schema -> Cache.skills(schema) |> filter(extensions) end)
  end

  @spec all_skills() :: map()
  def all_skills() do
    Agent.get(__MODULE__, fn schema -> Cache.all_skills(schema) end)
  end

  @spec domains() :: map()
  def domains() do
    Agent.get(__MODULE__, fn schema -> Cache.domains(schema) end)
  end

  @spec domains(extensions_t() | nil) :: map()
  def domains(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.domains(schema) end)
  end

  def domains(extensions) do
    Agent.get(__MODULE__, fn schema -> Cache.domains(schema) |> filter(extensions) end)
  end

  @spec all_domains() :: map()
  def all_domains() do
    Agent.get(__MODULE__, fn schema -> Cache.all_domains(schema) end)
  end

  @spec modules() :: map()
  def modules() do
    Agent.get(__MODULE__, fn schema -> Cache.modules(schema) end)
  end

  @spec modules(extensions_t() | nil) :: map()
  def modules(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.modules(schema) end)
  end

  def modules(extensions) do
    Agent.get(__MODULE__, fn schema -> Cache.modules(schema) |> filter(extensions) end)
  end

  @spec all_modules() :: map()
  def all_modules() do
    Agent.get(__MODULE__, fn schema -> Cache.all_modules(schema) end)
  end

  @spec all_objects() :: map()
  def all_objects() do
    Agent.get(__MODULE__, fn schema -> Cache.all_objects(schema) end)
  end

  @spec export_skills() :: map()
  def export_skills() do
    Agent.get(__MODULE__, fn schema -> Cache.export_skills(schema) end)
  end

  @spec export_skills(extensions_t() | nil) :: map()
  def export_skills(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.export_skills(schema) end)
  end

  def export_skills(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_skills(schema) |> filter(extensions)
    end)
  end

  @spec export_domains() :: map()
  def export_domains() do
    Agent.get(__MODULE__, fn schema -> Cache.export_domains(schema) end)
  end

  @spec export_domains(extensions_t() | nil) :: map()
  def export_domains(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.export_domains(schema) end)
  end

  def export_domains(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_domains(schema) |> filter(extensions)
    end)
  end

  @spec export_modules() :: map()
  def export_modules() do
    Agent.get(__MODULE__, fn schema -> Cache.export_modules(schema) end)
  end

  @spec export_modules(extensions_t() | nil) :: map()
  def export_modules(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.export_modules(schema) end)
  end

  def export_modules(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_modules(schema) |> filter(extensions)
    end)
  end

  @spec skill(atom) :: nil | Cache.class_t()
  def skill(id) do
    Agent.get(__MODULE__, fn schema -> Cache.skill(schema, id) end)
  end

  @spec find_skill(any) :: nil | map
  def find_skill(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_skill(schema, uid) end)
  end

  @spec domain(atom) :: nil | Cache.class_t()
  def domain(id) do
    Agent.get(__MODULE__, fn schema -> Cache.domain(schema, id) end)
  end

  @spec find_domain(any) :: nil | map
  def find_domain(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_domain(schema, uid) end)
  end

  @spec module(atom) :: nil | Cache.class_t()
  def module(id) do
    Agent.get(__MODULE__, fn schema -> Cache.module(schema, id) end)
  end

  @spec find_module(any) :: nil | map
  def find_module(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_module(schema, uid) end)
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

  @spec entity_ex(atom, atom) :: nil | Cache.class_t()
  def entity_ex(type, id) do
    Agent.get(__MODULE__, fn schema -> Cache.entity_ex(schema, type, id) end)
  end

  @spec entity_ex(extensions_t() | nil, atom, atom) :: nil | Cache.class_t()
  def entity_ex(nil, type, id) do
    Agent.get(__MODULE__, fn schema -> Cache.entity_ex(schema, type, id) end)
  end

  def entity_ex(extensions, type, id) do
    Agent.get(__MODULE__, fn schema -> Cache.entity_ex(schema, type, id) end)
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
