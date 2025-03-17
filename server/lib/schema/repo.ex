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
          add_skills(extensions, {id, main_skill}, Cache.skills(schema))
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
          add_domains(extensions, {id, main_domain}, Cache.domains(schema))
      end
    end)
  end

  @spec main_features :: map()
  def main_features() do
    Agent.get(__MODULE__, fn schema -> Cache.main_features(schema) end)
  end

  @spec main_features(extensions_t() | nil) :: map()
  def main_features(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.main_features(schema) end)
  end

  def main_features(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.main_features(schema)
      |> Map.update!(:attributes, fn attributes -> filter(attributes, extensions) end)
    end)
  end

  @spec main_feature(atom) :: nil | Cache.category_t()
  def main_feature(id) do
    main_feature(nil, id)
  end

  @spec main_feature(extensions_t() | nil, atom) :: nil | Cache.category_t()
  def main_feature(extensions, id) do
    Agent.get(__MODULE__, fn schema ->
      case Cache.main_feature(schema, id) do
        nil ->
          nil

        main_feature ->
          add_features(extensions, {id, main_feature}, Cache.features(schema))
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

  @spec features() :: map()
  def features() do
    Agent.get(__MODULE__, fn schema -> Cache.features(schema) end)
  end

  @spec features(extensions_t() | nil) :: map()
  def features(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.features(schema) end)
  end

  def features(extensions) do
    Agent.get(__MODULE__, fn schema -> Cache.features(schema) |> filter(extensions) end)
  end

  @spec all_features() :: map()
  def all_features() do
    Agent.get(__MODULE__, fn schema -> Cache.all_features(schema) end)
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

  @spec export_features() :: map()
  def export_features() do
    Agent.get(__MODULE__, fn schema -> Cache.export_features(schema) end)
  end

  @spec export_features(extensions_t() | nil) :: map()
  def export_features(nil) do
    Agent.get(__MODULE__, fn schema -> Cache.export_features(schema) end)
  end

  def export_features(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_features(schema) |> filter(extensions)
    end)
  end

  @spec export_base_class() :: map()
  def export_base_class() do
    Agent.get(__MODULE__, fn schema -> Cache.export_base_class(schema) end)
  end

  @spec class(atom) :: nil | Cache.class_t()
  def class(id) do
    Agent.get(__MODULE__, fn schema -> Cache.class(schema, id) end)
  end

  @spec class_ex(atom) :: nil | Cache.class_t()
  def class_ex(id) do
    Agent.get(__MODULE__, fn schema -> Cache.class_ex(schema, id) end)
  end

  @spec find_class_by_uid(integer()) :: nil | map
  def find_class_by_uid(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_class_by_uid(schema, uid) end)
  end

  @spec skill(atom) :: nil | Cache.class_t()
  def skill(id) do
    Agent.get(__MODULE__, fn schema -> Cache.skill(schema, id) end)
  end

  @spec skill_ex(atom) :: nil | Cache.class_t()
  def skill_ex(id) do
    Agent.get(__MODULE__, fn schema -> Cache.skill_ex(schema, id) end)
  end

  @spec find_skill(any) :: nil | map
  def find_skill(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_skill(schema, uid) end)
  end

  @spec domain(atom) :: nil | Cache.class_t()
  def domain(id) do
    Agent.get(__MODULE__, fn schema -> Cache.domain(schema, id) end)
  end

  @spec domain_ex(atom) :: nil | Cache.class_t()
  def domain_ex(id) do
    Agent.get(__MODULE__, fn schema -> Cache.domain_ex(schema, id) end)
  end

  @spec find_domain(any) :: nil | map
  def find_domain(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_domain(schema, uid) end)
  end

  @spec feature(atom) :: nil | Cache.class_t()
  def feature(id) do
    Agent.get(__MODULE__, fn schema -> Cache.feature(schema, id) end)
  end

  @spec feature_ex(atom) :: nil | Cache.class_t()
  def feature_ex(id) do
    Agent.get(__MODULE__, fn schema -> Cache.feature_ex(schema, id) end)
  end

  @spec find_feature(any) :: nil | map
  def find_feature(uid) do
    Agent.get(__MODULE__, fn schema -> Cache.find_feature(schema, uid) end)
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

  defp add_skills(nil, {id, main_skill}, skills) do
    main_skill_uid = Atom.to_string(id)

    list =
      skills
      |> Stream.filter(fn {_name, skill} ->
        md = Map.get(skill, :category)
        md == main_skill_uid or Utils.to_uid(skill[:extension], md) == id
      end)
      |> Stream.map(fn {name, skill} ->
        skill =
          skill
          |> Map.delete(:category)
          |> Map.delete(:category_name)

        {name, skill}
      end)
      |> Enum.to_list()

    Map.put(main_skill, :classes, list)
    |> Map.put(:name, main_skill_uid)
  end

  defp add_skills(extensions, {id, main_skill}, skills) do
    main_skill_uid = Atom.to_string(id)

    list =
      Enum.filter(
        skills,
        fn {_name, skill} ->
          md = skill[:category]

          case skill[:extension] do
            nil ->
              md == main_skill_uid

            ext ->
              MapSet.member?(extensions, ext) and
                (md == main_skill_uid or Utils.to_uid(ext, md) == id)
          end
        end
      )

    Map.put(main_skill, :classes, list)
  end

  defp add_domains(nil, {id, main_domain}, domains) do
    main_domain_uid = Atom.to_string(id)

    list =
      domains
      |> Stream.filter(fn {_name, domain} ->
        md = Map.get(domain, :category)
        md == main_domain_uid or Utils.to_uid(domain[:extension], md) == id
      end)
      |> Stream.map(fn {name, domain} ->
        domain =
          domain
          |> Map.delete(:category)
          |> Map.delete(:category_name)

        {name, domain}
      end)
      |> Enum.to_list()

    Map.put(main_domain, :classes, list)
    |> Map.put(:name, main_domain_uid)
  end

  defp add_domains(extensions, {id, main_domain}, domains) do
    main_domain_uid = Atom.to_string(id)

    list =
      Enum.filter(
        domains,
        fn {_name, domain} ->
          md = domain[:category]

          case domain[:extension] do
            nil ->
              md == main_domain_uid

            ext ->
              MapSet.member?(extensions, ext) and
                (md == main_domain_uid or Utils.to_uid(ext, md) == id)
          end
        end
      )

    Map.put(main_domain, :classes, list)
  end

  defp add_features(nil, {id, main_feature}, features) do
    main_feature_uid = Atom.to_string(id)

    list =
      features
      |> Stream.filter(fn {_name, feature} ->
        md = Map.get(feature, :category)
        md == main_feature_uid or Utils.to_uid(feature[:extension], md) == id
      end)
      |> Stream.map(fn {name, feature} ->
        feature =
          feature
          |> Map.delete(:category)
          |> Map.delete(:category_name)

        {name, feature}
      end)
      |> Enum.to_list()

    Map.put(main_feature, :classes, list)
    |> Map.put(:name, main_feature_uid)
  end

  defp add_features(extensions, {id, main_feature}, features) do
    main_feature_uid = Atom.to_string(id)

    list =
      Enum.filter(
        features,
        fn {_name, feature} ->
          md = feature[:category]

          case feature[:extension] do
            nil ->
              md == main_feature_uid

            ext ->
              MapSet.member?(extensions, ext) and
                (md == main_feature_uid or Utils.to_uid(ext, md) == id)
          end
        end
      )

    Map.put(main_feature, :classes, list)
  end
end
