# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema do
  @moduledoc """
  Schema keeps the contexts that define your business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  alias Schema.Repo
  alias Schema.Cache
  alias Schema.Utils

  @dialyzer :no_improper_lists

  @doc """
    Returns the schema version string.
  """
  @spec version :: String.t()
  def version(), do: Repo.version()

  @spec build_version :: String.t()
  def build_version() do
    Application.spec(:schema_server)
    |> Keyword.get(:vsn)
    |> to_string()
    |> String.trim_trailing("-SNAPSHOT")
  end

  @doc """
    Returns the schema extensions.
  """
  @spec extensions :: map()
  def extensions(), do: Cache.extensions()

  @doc """
    Returns the schema profiles.
  """
  @spec profiles :: map()
  def profiles(), do: Repo.profiles()

  @spec profiles(Repo.extensions_t()) :: map()
  def profiles(extensions) do
    Repo.profiles(extensions)
  end

  @doc """
    Reloads the schema without the extensions.
  """
  @spec reload() :: :ok
  def reload(), do: Repo.reload()

  @doc """
    Reloads the schema with extensions from the given path.
  """
  @spec reload(String.t() | list()) :: :ok
  def reload(path), do: Repo.reload(path)

  @doc """
    Returns the categories.
  """
  @spec categories :: map()
  def categories(), do: Repo.categories()

  @doc """
    Returns the categories defined in the given extension set.
  """
  def categories(extensions) do
    Map.update(Repo.categories(extensions), :attributes, %{}, fn attributes ->
      Enum.into(attributes, %{}, fn {name, _category} ->
        {name, category(extensions, name)}
      end)
    end)
  end

  @doc """
    Returns a single category with its classes.
  """
  @spec category(atom | String.t()) :: nil | Cache.category_t()
  def category(id), do: get_category(Utils.to_uid(id))

  @spec category(Repo.extensions_t(), String.t()) :: nil | Cache.category_t()
  def category(extensions, id), do: get_category(extensions, Utils.to_uid(id))

  @spec category(Repo.extensions_t(), String.t(), String.t()) :: nil | Cache.category_t()
  def category(extensions, extension, id),
    do: get_category(extensions, Utils.to_uid(extension, id))

  @doc """
    Returns skill categories.
  """
  @spec main_skills :: map()
  def main_skills(), do: Repo.main_skills()

  @doc """
    Returns skill categories defined in the given extension set.
  """
  def main_skills(extensions) do
    Map.update(Repo.main_skills(extensions), :attributes, %{}, fn attributes ->
      Enum.into(attributes, %{}, fn {name, _main_skill} ->
        {name, main_skill(extensions, name)}
      end)
    end)
  end

  @doc """
    Returns a single skill category with its classes.
  """
  @spec main_skill(atom | String.t()) :: nil | Cache.category_t()
  def main_skill(id), do: get_main_skill(Utils.to_uid(id))

  @spec main_skill(Repo.extensions_t(), String.t()) :: nil | Cache.category_t()
  def main_skill(extensions, id), do: get_main_skill(extensions, Utils.to_uid(id))

  @spec main_skill(Repo.extensions_t(), String.t(), String.t()) :: nil | Cache.category_t()
  def main_skill(extensions, extension, id),
    do: get_main_skill(extensions, Utils.to_uid(extension, id))

  @doc """
    Returns the main domains.
  """
  @spec main_domains :: map()
  def main_domains(), do: Repo.main_domains()

  @doc """
    Returns domain categories defined in the given extension set.
  """
  def main_domains(extensions) do
    Map.update(Repo.main_domains(extensions), :attributes, %{}, fn attributes ->
      Enum.into(attributes, %{}, fn {name, _main_domain} ->
        {name, main_domain(extensions, name)}
      end)
    end)
  end

  @doc """
    Returns a single domain category with its classes.
  """
  @spec main_domain(atom | String.t()) :: nil | Cache.category_t()
  def main_domain(id), do: get_main_domain(Utils.to_uid(id))

  @spec main_domain(Repo.extensions_t(), String.t()) :: nil | Cache.category_t()
  def main_domain(extensions, id), do: get_main_domain(extensions, Utils.to_uid(id))

  @spec main_domain(Repo.extensions_t(), String.t(), String.t()) :: nil | Cache.category_t()
  def main_domain(extensions, extension, id),
    do: get_main_domain(extensions, Utils.to_uid(extension, id))

  @doc """
    Returns features categories.
  """
  @spec main_features :: map()
  def main_features(), do: Repo.main_features()

  @doc """
    Returns features categories defined in the given extension set.
  """
  def main_features(extensions) do
    Map.update(Repo.main_features(extensions), :attributes, %{}, fn attributes ->
      Enum.into(attributes, %{}, fn {name, _main_feature} ->
        {name, main_feature(extensions, name)}
      end)
    end)
  end

  @doc """
    Returns a single feature category with its classes.
  """
  @spec main_feature(atom | String.t()) :: nil | Cache.category_t()
  def main_feature(id), do: get_main_feature(Utils.to_uid(id))

  @spec main_feature(Repo.extensions_t(), String.t()) :: nil | Cache.category_t()
  def main_feature(extensions, id), do: get_main_feature(extensions, Utils.to_uid(id))

  @spec main_feature(Repo.extensions_t(), String.t(), String.t()) :: nil | Cache.category_t()
  def main_feature(extensions, extension, id),
    do: get_main_feature(extensions, Utils.to_uid(extension, id))

  @doc """
    Returns the attribute dictionary.
  """
  @spec dictionary() :: Cache.dictionary_t()
  def dictionary(), do: Repo.dictionary()

  @doc """
    Returns the attribute dictionary including the extension.
  """
  @spec dictionary(Repo.extensions_t()) :: Cache.dictionary_t()
  def dictionary(extensions), do: Repo.dictionary(extensions)

  @doc """
    Returns the data types defined in dictionary.
  """
  @spec data_types :: map()
  def data_types(), do: Repo.data_types()

  @spec data_type?(binary(), binary() | list(binary())) :: boolean()
  def data_type?(type, type), do: true

  def data_type?(type, base_type) when is_binary(base_type) do
    types = Map.get(Repo.data_types(), :attributes)

    case Map.get(types, String.to_atom(type)) do
      nil -> false
      data -> data[:type] == base_type
    end
  end

  def data_type?(type, base_types) do
    types = Map.get(Repo.data_types(), :attributes)

    case Map.get(types, String.to_atom(type)) do
      nil ->
        false

      data ->
        t = data[:type] || type
        Enum.any?(base_types, fn b -> b == t end)
    end
  end

  @doc """
    Returns all classes.
  """
  @spec classes() :: map()
  def classes(), do: Repo.classes()

  @spec classes(Repo.extensions_t()) :: map()
  def classes(extensions), do: Repo.classes(extensions)

  @spec classes(Repo.extensions_t(), Repo.profiles_t()) :: map()
  def classes(extensions, profiles) do
    extensions
    |> Repo.classes()
    |> apply_profiles(profiles, MapSet.size(profiles))
  end

  @spec all_classes() :: map()
  def all_classes(), do: Repo.all_classes()

  @spec all_objects() :: map()
  def all_objects(), do: Repo.all_objects()

  @doc """
    Returns a single class.
  """
  @spec class(atom() | String.t()) :: nil | Cache.class_t()
  def class(id), do: Repo.class(Utils.to_uid(id))

  @spec class(nil | String.t(), String.t()) :: nil | map()
  def class(extension, id),
    do: Repo.class(Utils.to_uid(extension, id))

  @spec class(String.t() | nil, String.t(), Repo.profiles_t() | nil) :: nil | map()
  def class(extension, id, nil), do: class(extension, id)

  def class(extension, id, profiles) do
    case class(extension, id) do
      nil ->
        nil

      class ->
        Map.update!(class, :attributes, fn attributes ->
          Utils.apply_profiles(attributes, profiles)
        end)
    end
  end

  @doc """
    Returns a single class with the embedded objects.
  """
  @spec class_ex(atom() | String.t()) :: nil | Cache.class_t()
  def class_ex(id),
    do: Repo.class_ex(Utils.to_uid(id))

  @spec class_ex(nil | String.t(), String.t()) :: nil | map()
  def class_ex(extension, id),
    do: Repo.class_ex(Utils.to_uid(extension, id))

  @spec class_ex(String.t() | nil, String.t(), Repo.profiles_t() | nil) :: nil | map()
  def class_ex(extension, id, nil),
    do: class_ex(extension, id)

  def class_ex(extension, id, profiles) do
    case class_ex(extension, id) do
      nil ->
        nil

      class ->
        Schema.Profiles.apply_profiles(class, profiles)
    end
  end

  @doc """
  Finds a class by its name. Class names are unique across all class families.
  """
  @spec find_class_by_name(String.t()) :: nil | Cache.class_t()
  def find_class_by_name(name) when is_bitstring(name), do: Repo.find_class_by_name(name)

  @doc """
    Returns all skill classes.
  """
  @spec skills() :: map()
  def skills(), do: Repo.skills()

  @spec skills(Repo.extensions_t()) :: map()
  def skills(extensions), do: Repo.skills(extensions)

  @spec skills(Repo.extensions_t(), Repo.profiles_t()) :: map()
  def skills(extensions, profiles) do
    extensions
    |> Repo.skills()
    |> apply_profiles(profiles, MapSet.size(profiles))
  end

  @spec all_skills() :: map()
  def all_skills(), do: Repo.all_skills()

  @doc """
    Returns a single skill class.
  """
  @spec skill(atom() | String.t()) :: nil | Cache.class_t()
  def skill(id), do: Repo.skill(Utils.to_uid(id))

  @spec skill(nil | String.t(), String.t()) :: nil | map()
  def skill(extension, id),
    do: Repo.skill(Utils.to_uid(extension, id))

  @spec skill(String.t() | nil, String.t(), Repo.profiles_t() | nil) :: nil | map()
  def skill(extension, id, nil), do: skill(extension, id)

  def skill(extension, id, profiles) do
    case skill(extension, id) do
      nil ->
        nil

      skill ->
        Map.update!(skill, :attributes, fn attributes ->
          Utils.apply_profiles(attributes, profiles)
        end)
    end
  end

  @doc """
    Returns a single skill class with the embedded objects.
  """
  @spec skill_ex(atom() | String.t()) :: nil | Cache.class_t()
  def skill_ex(id),
    do: Repo.skill_ex(Utils.to_uid(id))

  @spec skill_ex(nil | String.t(), String.t()) :: nil | map()
  def skill_ex(extension, id),
    do: Repo.skill_ex(Utils.to_uid(extension, id))

  @spec skill_ex(String.t() | nil, String.t(), Repo.profiles_t() | nil) :: nil | map()
  def skill_ex(extension, id, nil),
    do: skill_ex(extension, id)

  def skill_ex(extension, id, profiles) do
    case skill_ex(extension, id) do
      nil ->
        nil

      skill ->
        Schema.Profiles.apply_profiles(skill, profiles)
    end
  end

  @doc """
  Finds a skill class by the skill uid value.
  """
  @spec find_skill(integer()) :: nil | Cache.class_t()
  def find_skill(uid) when is_integer(uid), do: Repo.find_skill(uid)

  @doc """
    Returns all domains.
  """
  @spec domains() :: map()
  def domains(), do: Repo.domains()

  @spec domains(Repo.extensions_t()) :: map()
  def domains(extensions), do: Repo.domains(extensions)

  @spec domains(Repo.extensions_t(), Repo.profiles_t()) :: map()
  def domains(extensions, profiles) do
    extensions
    |> Repo.domains()
    |> apply_profiles(profiles, MapSet.size(profiles))
  end

  @spec all_domains() :: map()
  def all_domains(), do: Repo.all_domains()

  @doc """
    Returns a single domain.
  """
  @spec domain(atom() | String.t()) :: nil | Cache.class_t()
  def domain(id), do: Repo.domain(Utils.to_uid(id))

  @spec domain(nil | String.t(), String.t()) :: nil | map()
  def domain(extension, id),
    do: Repo.domain(Utils.to_uid(extension, id))

  @spec domain(String.t() | nil, String.t(), Repo.profiles_t() | nil) :: nil | map()
  def domain(extension, id, nil), do: domain(extension, id)

  def domain(extension, id, profiles) do
    case domain(extension, id) do
      nil ->
        nil

      domain ->
        Map.update!(domain, :attributes, fn attributes ->
          Utils.apply_profiles(attributes, profiles)
        end)
    end
  end

  @doc """
    Returns a single domain with the embedded objects.
  """
  @spec domain_ex(atom() | String.t()) :: nil | Cache.class_t()
  def domain_ex(id),
    do: Repo.domain_ex(Utils.to_uid(id))

  @spec domain_ex(nil | String.t(), String.t()) :: nil | map()
  def domain_ex(extension, id),
    do: Repo.domain_ex(Utils.to_uid(extension, id))

  @spec domain_ex(String.t() | nil, String.t(), Repo.profiles_t() | nil) :: nil | map()
  def domain_ex(extension, id, nil),
    do: domain_ex(extension, id)

  def domain_ex(extension, id, profiles) do
    case domain_ex(extension, id) do
      nil ->
        nil

      domain ->
        Schema.Profiles.apply_profiles(domain, profiles)
    end
  end

  @doc """
  Finds a domain by the domain uid value.
  """
  @spec find_domain(integer()) :: nil | Cache.class_t()
  def find_domain(uid) when is_integer(uid), do: Repo.find_domain(uid)

  @doc """
    Returns all features.
  """
  @spec features() :: map()
  def features(), do: Repo.features()

  @spec features(Repo.extensions_t()) :: map()
  def features(extensions), do: Repo.features(extensions)

  @spec features(Repo.extensions_t(), Repo.profiles_t()) :: map()
  def features(extensions, profiles) do
    extensions
    |> Repo.features()
    |> apply_profiles(profiles, MapSet.size(profiles))
  end

  @spec all_features() :: map()
  def all_features(), do: Repo.all_features()

  @doc """
    Returns a single feature.
  """
  @spec feature(atom() | String.t()) :: nil | Cache.class_t()
  def feature(id), do: Repo.feature(Utils.to_uid(id))

  @spec feature(nil | String.t(), String.t()) :: nil | map()
  def feature(extension, id),
    do: Repo.feature(Utils.to_uid(extension, id))

  @spec feature(String.t() | nil, String.t(), Repo.profiles_t() | nil) :: nil | map()
  def feature(extension, id, nil), do: feature(extension, id)

  def feature(extension, id, profiles) do
    case feature(extension, id) do
      nil ->
        nil

      feature ->
        Map.update!(feature, :attributes, fn attributes ->
          Utils.apply_profiles(attributes, profiles)
        end)
    end
  end

  @doc """
    Returns a single feature with the embedded objects.
  """
  @spec feature_ex(atom() | String.t()) :: nil | Cache.class_t()
  def feature_ex(id),
    do: Repo.feature_ex(Utils.to_uid(id))

  @spec feature_ex(nil | String.t(), String.t()) :: nil | map()
  def feature_ex(extension, id),
    do: Repo.feature_ex(Utils.to_uid(extension, id))

  @spec feature_ex(String.t() | nil, String.t(), Repo.profiles_t() | nil) :: nil | map()
  def feature_ex(extension, id, nil),
    do: feature_ex(extension, id)

  def feature_ex(extension, id, profiles) do
    case feature_ex(extension, id) do
      nil ->
        nil

      feature ->
        Schema.Profiles.apply_profiles(feature, profiles)
    end
  end

  @doc """
  Finds a feature by the feature uid value.
  """
  @spec find_feature(integer()) :: nil | Cache.class_t()
  def find_feature(uid) when is_integer(uid), do: Repo.find_feature(uid)

  @doc """
    Returns all objects.
  """
  @spec objects() :: map()
  def objects(), do: Repo.objects()

  @spec objects(Repo.extensions_t()) :: map()
  def objects(extensions), do: Repo.objects(extensions)

  @spec objects(Repo.extensions_t(), Repo.profiles_t()) :: map()
  def objects(extensions, profiles) do
    extensions
    |> Repo.objects()
    |> apply_profiles(profiles, MapSet.size(profiles))
  end

  @doc """
    Returns a single object.
  """
  @spec object(atom | String.t()) :: nil | Cache.object_t()
  def object(id),
    do: Repo.object(Utils.to_uid(id))

  @spec object(nil | String.t(), String.t()) :: nil | map()
  def object(extension, id) when is_binary(id) do
    Repo.object(Utils.to_uid(extension, id))
  end

  @spec object(Repo.extensions_t(), String.t(), String.t()) :: nil | map()
  def object(extensions, extension, id) when is_binary(id) do
    Repo.object(extensions, Utils.to_uid(extension, id))
  end

  @spec object(Repo.extensions_t(), String.t(), String.t(), Repo.profiles_t() | nil) ::
          nil | map()
  def object(extensions, extension, id, nil),
    do: object(extensions, extension, id)

  def object(extensions, extension, id, profiles) do
    case object(extensions, extension, id) do
      nil ->
        nil

      object ->
        Map.update!(object, :attributes, fn attributes ->
          Utils.apply_profiles(attributes, profiles)
        end)
    end
  end

  @doc """
    Returns a single object and with the embedded objects.
  """
  @spec object_ex(atom | String.t()) :: nil | Cache.object_t()
  def object_ex(id),
    do: Repo.object_ex(Utils.to_uid(id))

  @spec object_ex(nil | String.t(), String.t()) :: nil | map()
  def object_ex(extension, id) when is_binary(id) do
    Repo.object_ex(Utils.to_uid(extension, id))
  end

  @spec object_ex(Repo.extensions_t(), String.t(), String.t()) :: nil | map()
  def object_ex(extensions, extension, id) when is_binary(id) do
    Repo.object_ex(extensions, Utils.to_uid(extension, id))
  end

  @spec object_ex(Repo.extensions_t(), String.t(), String.t(), Repo.profiles_t() | nil) ::
          nil | map()
  def object_ex(extensions, extension, id, nil),
    do: object_ex(extensions, extension, id)

  def object_ex(extensions, extension, id, profiles) do
    case object_ex(extensions, extension, id) do
      nil ->
        nil

      object ->
        Map.update!(object, :attributes, fn attributes ->
          Utils.apply_profiles(attributes, profiles)
        end)
    end
  end

  # ------------------#
  # Export Functions #
  # ------------------#

  defp cleanup_dictionary_attributes(attributes) do
    Enum.reduce(
      attributes,
      %{},
      fn {attribute_key, attribute}, attributes ->
        Map.put(
          attributes,
          attribute_key,
          Enum.reduce(
            attribute,
            %{},
            fn {k, v}, attribute ->
              if Atom.to_string(k) |> String.starts_with?("_") do
                attribute
              else
                Map.put(attribute, k, v)
              end
            end
          )
        )
      end
    )
  end

  defp export_dictionary_attributes() do
    dictionary()[:attributes] |> cleanup_dictionary_attributes()
  end

  defp export_dictionary_attributes(extensions) do
    dictionary(extensions)[:attributes] |> cleanup_dictionary_attributes()
  end

  @doc """
    Exports the schema, including data types, objects, and classes.
  """
  @spec export_schema() :: %{
          base_class: map(),
          classes: map(),
          domains: map(),
          features: map(),
          objects: map(),
          types: map(),
          dictionary_attributes: map(),
          version: String.t()
        }
  def export_schema() do
    %{
      base_class: Schema.export_base_class(),
      classes: Schema.export_classes(),
      domains: Schema.export_domains(),
      features: Schema.export_features(),
      objects: Schema.export_objects(),
      types: Schema.export_data_types(),
      dictionary_attributes: export_dictionary_attributes(),
      version: Schema.version()
    }
  end

  @spec export_schema(Repo.extensions_t()) :: %{
          base_class: map(),
          classes: map(),
          domains: map(),
          features: map(),
          objects: map(),
          types: map(),
          dictionary_attributes: map(),
          version: String.t()
        }
  def export_schema(extensions) do
    %{
      base_class: Schema.export_base_class(),
      classes: Schema.export_classes(extensions),
      domains: Schema.export_domains(extensions),
      features: Schema.export_features(extensions),
      objects: Schema.export_objects(extensions),
      types: Schema.export_data_types(),
      dictionary_attributes: export_dictionary_attributes(extensions),
      version: Schema.version()
    }
  end

  @spec export_schema(Repo.extensions_t(), Repo.profiles_t() | nil) :: %{
          base_class: map(),
          classes: map(),
          domains: map(),
          features: map(),
          objects: map(),
          types: map(),
          dictionary_attributes: map(),
          version: String.t()
        }
  def export_schema(extensions, nil) do
    export_schema(extensions)
  end

  def export_schema(extensions, profiles) do
    %{
      base_class: Schema.export_base_class(profiles),
      classes: Schema.export_classes(extensions, profiles),
      domains: Schema.export_domains(extensions, profiles),
      features: Schema.export_features(extensions, profiles),
      objects: Schema.export_objects(extensions, profiles),
      types: Schema.export_data_types(),
      dictionary_attributes: export_dictionary_attributes(extensions),
      version: Schema.version()
    }
  end

  @doc """
    Exports the data types.
  """
  @spec export_data_types :: any
  def export_data_types() do
    Map.get(data_types(), :attributes)
  end

  @doc """
    Exports the classes.
  """
  @spec export_classes() :: map()
  def export_classes(), do: Repo.export_classes() |> reduce_objects()

  @spec export_classes(Repo.extensions_t()) :: map()
  def export_classes(extensions), do: Repo.export_classes(extensions) |> reduce_objects()

  @spec export_classes(Repo.extensions_t(), Repo.profiles_t() | nil) :: map()
  def export_classes(extensions, nil), do: export_classes(extensions)

  def export_classes(extensions, profiles) do
    Repo.export_classes(extensions) |> update_exported_classes(profiles)
  end

  @doc """
    Exports the skill classes.
  """
  @spec export_skills() :: map()
  def export_skills(), do: Repo.export_skills() |> reduce_objects()

  @spec export_skills(Repo.extensions_t()) :: map()
  def export_skills(extensions), do: Repo.export_skills(extensions) |> reduce_objects()

  @spec export_skills(Repo.extensions_t(), Repo.profiles_t() | nil) :: map()
  def export_skills(extensions, nil), do: export_skills(extensions)

  def export_skills(extensions, profiles) do
    Repo.export_skills(extensions) |> update_exported_classes(profiles)
  end

  @doc """
    Exports the domain classes.
  """
  @spec export_domains() :: map()
  def export_domains(), do: Repo.export_domains() |> reduce_objects()

  @spec export_domains(Repo.extensions_t()) :: map()
  def export_domains(extensions), do: Repo.export_domains(extensions) |> reduce_objects()

  @spec export_domains(Repo.extensions_t(), Repo.profiles_t() | nil) :: map()
  def export_domains(extensions, nil), do: export_domains(extensions)

  def export_domains(extensions, profiles) do
    Repo.export_domains(extensions) |> update_exported_classes(profiles)
  end

  @doc """
    Exports the feature classes.
  """
  @spec export_features() :: map()
  def export_features(), do: Repo.export_features() |> reduce_objects()

  @spec export_features(Repo.extensions_t()) :: map()
  def export_features(extensions), do: Repo.export_features(extensions) |> reduce_objects()

  @spec export_features(Repo.extensions_t(), Repo.profiles_t() | nil) :: map()
  def export_features(extensions, nil), do: export_features(extensions)

  def export_features(extensions, profiles) do
    Repo.export_features(extensions) |> update_exported_classes(profiles)
  end

  @spec export_base_class() :: map()
  def export_base_class() do
    Repo.export_base_class()
    |> reduce_attributes()
    |> Map.update!(:attributes, fn attributes ->
      Utils.remove_profiles(attributes) |> Enum.into(%{})
    end)
  end

  @spec export_base_class(Repo.profiles_t() | nil) :: map()
  def export_base_class(nil) do
    export_base_class()
  end

  def export_base_class(profiles) do
    size = MapSet.size(profiles)

    Repo.export_base_class()
    |> reduce_attributes()
    |> Map.update!(:attributes, fn attributes ->
      Utils.apply_profiles(attributes, profiles, size) |> Enum.into(%{})
    end)
  end

  defp update_exported_classes(classes, profiles) do
    apply_profiles(classes, profiles, MapSet.size(profiles)) |> reduce_objects()
  end

  @doc """
    Exports the objects.
  """
  @spec export_objects() :: map()
  def export_objects(), do: Repo.export_objects() |> reduce_objects()

  @spec export_objects(Repo.extensions_t()) :: map()
  def export_objects(extensions), do: Repo.export_objects(extensions) |> reduce_objects()

  @spec export_objects(Repo.extensions_t(), Repo.profiles_t() | nil) :: map()
  def export_objects(extensions, nil), do: export_objects(extensions)

  def export_objects(extensions, profiles) do
    Repo.export_objects(extensions)
    |> apply_profiles(profiles, MapSet.size(profiles))
    |> reduce_objects()
  end

  # ----------------------------#
  # Enrich Class Data Functions #
  # ----------------------------#

  def enrich(data, enum_text, observables, type) do
    Schema.Helper.enrich(data, enum_text, observables, type)
  end

  # -------------------------------#
  # Generate Sample Data Functions #
  # -------------------------------#

  @doc """
  Returns a randomly generated sample class.
  """
  @spec generate_class(Cache.class_t() | atom() | binary()) :: nil | map()
  def generate_class(class) when is_map(class) do
    Schema.Generator.generate_sample_class(class, nil)
  end

  def generate_class(class) do
    Schema.class(class) |> Schema.Generator.generate_sample_class(nil)
  end

  @doc """
  Returns a randomly generated sample class, based on the spcified profiles.
  """
  @spec generate_class(Cache.class_t(), Repo.profiles_t() | nil) :: map()
  def generate_class(class, profiles) when is_map(class) do
    Schema.Generator.generate_sample_class(class, profiles)
  end

  @doc """
  Returns randomly generated sample object data.
  """
  @spec generate_object(Cache.object_t() | atom() | binary()) :: any()
  def generate_object(type) when is_map(type) do
    Schema.Generator.generate_sample_object(type, nil)
  end

  def generate_object(type) do
    Schema.object(type) |> Schema.Generator.generate_sample_object(nil)
  end

  @doc """
  Returns randomly generated sample object data, based on the spcified profiles.
  """
  @spec generate_object(Cache.object_t(), Repo.profiles_t() | nil) :: map()
  def generate_object(type, profiles) when is_map(type) do
    Schema.Generator.generate_sample_object(type, profiles)
  end

  defp get_category(id) do
    Repo.category(id) |> reduce_category()
  end

  defp get_category(extensions, id) do
    Repo.category(extensions, id) |> reduce_category()
  end

  defp get_main_skill(id) do
    Repo.main_skill(id) |> reduce_category()
  end

  defp get_main_skill(extensions, id) do
    Repo.main_skill(extensions, id) |> reduce_category()
  end

  defp get_main_domain(id) do
    Repo.main_domain(id) |> reduce_category()
  end

  defp get_main_domain(extensions, id) do
    Repo.main_domain(extensions, id) |> reduce_category()
  end

  defp get_main_feature(id) do
    Repo.main_feature(id) |> reduce_category()
  end

  defp get_main_feature(extensions, id) do
    Repo.main_feature(extensions, id) |> reduce_category()
  end

  defp reduce_category(nil) do
    nil
  end

  defp reduce_category(data) do
    Map.update(data, :classes, [], fn classes ->
      Enum.into(classes, %{}, fn {name, class} ->
        {name, reduce_class(class)}
      end)
    end)
  end

  defp reduce_objects(objects) do
    Enum.into(objects, %{}, fn {name, object} ->
      updated = reduce_attributes(object)

      {name, updated}
    end)
  end

  defp reduce_data(object) do
    delete_links(object) |> Map.drop([:_source, :_source_patched])
  end

  defp reduce_attributes(data) do
    reduce_data(data)
    |> Map.update(:attributes, [], fn attributes ->
      Enum.into(attributes, %{}, fn {attribute_name, attribute_details} ->
        {attribute_name, reduce_attribute(attribute_details)}
      end)
    end)
  end

  defp reduce_attribute(attribute_details) do
    attribute_details
    |> filter_internal()
    |> reduce_enum()
  end

  defp filter_internal(m) do
    Map.filter(m, fn {key, _} ->
      s = Atom.to_string(key)
      not String.starts_with?(s, "_")
    end)
  end

  defp reduce_enum(attribute_details) do
    if Map.has_key?(attribute_details, :enum) do
      Map.update!(attribute_details, :enum, fn enum ->
        Enum.map(
          enum,
          fn {enum_value_key, enum_value_details} ->
            {
              enum_value_key,
              filter_internal(enum_value_details)
            }
          end
        )
        |> Enum.into(%{})
      end)
    else
      attribute_details
    end
  end

  @spec reduce_class(map) :: map
  def reduce_class(data) do
    delete_attributes(data) |> delete_associations()
  end

  @spec delete_attributes(map) :: map
  def delete_attributes(data) do
    Map.delete(data, :attributes)
  end

  @spec delete_associations(map) :: map
  def delete_associations(data) do
    Map.delete(data, :associations)
  end

  @spec delete_links(map) :: map
  def delete_links(data) do
    Map.delete(data, :_links)
  end

  @spec deep_clean(map()) :: map()
  def deep_clean(data) do
    reduce_attributes(data)
  end

  def apply_profiles(types, _profiles, 0) do
    Enum.into(types, %{}, fn {name, type} ->
      remove_profiles(name, type)
    end)
  end

  def apply_profiles(types, profiles, size) do
    Enum.into(types, %{}, fn {name, type} ->
      apply_profiles(name, type, profiles, size)
    end)
  end

  defp apply_profiles(name, type, profiles, size) do
    {
      name,
      Map.update!(type, :attributes, fn attributes ->
        Utils.apply_profiles(attributes, profiles, size)
      end)
    }
  end

  defp remove_profiles(name, type) do
    {
      name,
      Map.update!(type, :attributes, fn attributes ->
        Utils.remove_profiles(attributes)
      end)
    }
  end
end
