# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema do
  @moduledoc """
  Schema keeps the contexts that define your business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.

  ## Class families

  Skills, domains, and modules share the same shape and lifecycle.  All public
  class accessors are parameterized by a `t:class_family/0` atom: pass
  `:skill`, `:domain`, or `:module` to select which family to operate on.
  """
  alias Schema.Repo
  alias Schema.Cache
  alias Schema.Utils

  @dialyzer :no_improper_lists

  @typedoc """
  The supported class families.  Each family is backed by its own directory of
  schema files but shares identical lookup, taxonomy, and export semantics.
  """
  @type class_family() :: Repo.class_family()

  @class_families [:skill, :domain, :module]

  @doc """
  Returns the list of class families supported by OASF.
  """
  @spec class_families() :: [class_family()]
  def class_families(), do: @class_families

  @doc """
    Returns the schema version string.
  """
  @spec version :: String.t()
  def version(), do: Repo.version()

  @spec parsed_version :: Utils.version_or_error_t()
  def parsed_version(), do: Repo.parsed_version()

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

  def profile(profiles, name) do
    case profiles[name] do
      nil ->
        nil

      profile ->
        Map.update!(profile, :attributes, &Schema.Utils.add_sibling_of_to_attributes/1)
    end
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
    Returns the attribute dictionary.
  """
  @spec dictionary() :: Cache.dictionary_t()
  def dictionary(), do: Repo.dictionary()

  @doc """
    Returns the attribute dictionary including the extension.
  """
  @spec dictionary(Repo.extensions_t()) :: Cache.dictionary_t()
  def dictionary(extensions) do
    Repo.dictionary(extensions)
    |> Map.update!(:attributes, &Schema.Utils.add_sibling_of_to_attributes/1)
  end

  @doc """
    Returns the data types defined in dictionary.
  """
  @spec data_types :: map()
  def data_types(), do: Repo.data_types()

  @spec all_objects() :: map()
  def all_objects(), do: Repo.all_objects()

  # ----------------------------------------------------------------------------
  # Class accessors (family-parameterized)
  # ----------------------------------------------------------------------------

  @doc """
  Returns the simplified map of all classes (including categories) of the given
  `family`.  Pass `:skill`, `:domain`, or `:module`.
  """
  @spec all_classes(class_family()) :: map()
  def all_classes(family), do: Repo.all_classes(family)

  @doc """
  Returns a single class of the given `family` by key.  The `id` can be either
  an atom or a string and is normalized via `Schema.Utils.to_uid/1`.

  Category classes are excluded from the result.
  """
  @spec class(class_family(), atom() | String.t()) :: nil | Cache.class_t()
  def class(family, id), do: Repo.class(family, Utils.to_uid(id))

  @doc """
  Returns a single class of the given `family` scoped by an optional `extension`.
  """
  @spec class(class_family(), nil | String.t(), String.t()) :: nil | map()
  def class(family, extension, id), do: Repo.class(family, Utils.to_uid(extension, id))

  @doc """
  Returns a single class of the given `family` with its attributes filtered by
  `profiles`.  When `profiles` is `nil`, the class is returned unfiltered.
  """
  @spec class(class_family(), String.t() | nil, String.t(), Repo.profiles_t() | nil) ::
          nil | map()
  def class(family, extension, id, nil), do: class(family, extension, id)

  def class(family, extension, id, profiles) do
    case class(family, extension, id) do
      nil ->
        nil

      c ->
        Map.update!(c, :attributes, fn attributes ->
          Utils.apply_profiles(attributes, profiles)
        end)
    end
  end

  @doc """
  Finds a class of the given `family` by its `uid`.  Unlike `class/2,3,4`,
  category classes are returned.
  """
  @spec find_class(class_family(), integer()) :: nil | Cache.class_t()
  def find_class(family, uid) when is_integer(uid), do: Repo.find_class(family, uid)

  @doc """
  Returns the taxonomy tree for the given `family`, optionally filtered by
  `extensions` and a `parent` (name or integer id).
  """
  @spec taxonomy(class_family(), Repo.extensions_t() | nil, String.t() | nil) :: map()
  def taxonomy(family, extensions \\ nil, parent \\ nil),
    do: Repo.taxonomy(family, extensions, parent)

  @doc """
  Returns all classes of the given `family`, optionally filtered by `extensions`
  and `profiles`.  Category classes are excluded.
  """
  @spec classes(class_family(), Repo.extensions_t() | nil, Repo.profiles_t() | nil) :: map()
  def classes(family, extensions \\ nil, profiles \\ nil)

  def classes(family, extensions, nil), do: Repo.classes(family, extensions) |> reduce_objects()

  def classes(family, extensions, profiles) do
    Repo.classes(family, extensions) |> apply_profiles_and_reduce(profiles)
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
    Returns a single object or class and with the embedded objects and classes.
  """
  @spec entity_ex(atom, atom | String.t()) :: nil | map()
  def entity_ex(type, id),
    do: Repo.entity_ex(type, Utils.to_uid(id))

  @spec entity_ex(nil | String.t(), atom, String.t()) :: nil | map()
  def entity_ex(extension, type, id) when is_binary(id) and is_atom(type) do
    Repo.entity_ex(type, Utils.to_uid(extension, id))
  end

  @spec entity_ex(String.t() | nil, atom, String.t(), Repo.profiles_t() | nil) :: nil | map()
  def entity_ex(extension, type, id, nil),
    do: entity_ex(extension, type, id)

  @spec entity_ex(Repo.extensions_t(), String.t(), atom, String.t()) :: nil | map()
  def entity_ex(extensions, extension, type, id) when is_binary(id) and is_atom(type) do
    Repo.entity_ex(extensions, type, Utils.to_uid(extension, id))
  end

  @spec entity_ex(String.t(), atom, String.t(), Repo.profiles_t() | nil) ::
          nil | map()
  def entity_ex(extension, type, id, profiles) do
    case entity_ex(extension, type, id) do
      nil ->
        nil

      entity ->
        Schema.Profiles.apply_profiles(entity, profiles)
    end
  end

  @spec entity_ex(Repo.extensions_t(), String.t(), atom, String.t(), Repo.profiles_t() | nil) ::
          nil | map()
  def entity_ex(extensions, extension, type, id, nil),
    do: entity_ex(extensions, extension, type, id)

  @spec entity_ex(Repo.extensions_t(), String.t(), atom, String.t(), Repo.profiles_t() | nil) ::
          nil | map()
  def entity_ex(extensions, extension, type, id, profiles) do
    case entity_ex(extensions, extension, type, id) do
      nil ->
        nil

      entity ->
        Map.update!(entity, :attributes, fn attributes ->
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
    Returns the complete schema, including data types, objects, and classes.
  """
  @spec schema(Repo.extensions_t() | nil, Repo.profiles_t() | nil) :: %{
          skills: map(),
          domains: map(),
          modules: map(),
          objects: map(),
          types: map(),
          dictionary_attributes: map(),
          version: String.t()
        }
  def schema(extensions \\ nil, profiles \\ nil) do
    %{
      skills: classes(:skill, extensions, profiles),
      domains: classes(:domain, extensions, profiles),
      modules: classes(:module, extensions, profiles),
      objects: schema_objects(extensions, profiles),
      types: data_types_attributes(),
      dictionary_attributes: schema_dictionary_attributes(extensions),
      version: version()
    }
  end

  defp schema_objects(nil, _profiles), do: objects()
  defp schema_objects(extensions, nil), do: objects(extensions)
  defp schema_objects(extensions, profiles), do: objects(extensions, profiles)

  defp schema_dictionary_attributes(nil), do: export_dictionary_attributes()
  defp schema_dictionary_attributes(extensions), do: export_dictionary_attributes(extensions)

  @doc """
    Returns the data types attributes.
  """
  @spec data_types_attributes :: any
  def data_types_attributes() do
    Map.get(data_types(), :attributes)
  end

  defp apply_profiles_and_reduce(classes, profiles) do
    apply_profiles(classes, profiles, MapSet.size(profiles)) |> reduce_objects()
  end

  @doc """
    Returns all objects.
  """
  @spec objects() :: map()
  def objects(), do: Repo.objects() |> reduce_objects()

  @spec objects(Repo.extensions_t()) :: map()
  def objects(extensions), do: Repo.objects(extensions) |> reduce_objects()

  @spec objects(Repo.extensions_t(), Repo.profiles_t() | nil) :: map()
  def objects(extensions, nil), do: objects(extensions)

  def objects(extensions, profiles) do
    Repo.objects(extensions)
    |> apply_profiles(profiles, MapSet.size(profiles))
    |> reduce_objects()
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

  @doc """
  Returns a randomly generated sample class, based on the specified profiles.
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
  Returns randomly generated sample object data, based on the specified profiles.
  """
  @spec generate_object(Cache.object_t(), Repo.profiles_t() | nil) :: map()
  def generate_object(type, profiles) when is_map(type) do
    Schema.Generator.generate_sample_object(type, profiles)
  end

  defp reduce_objects(objects) do
    Enum.into(objects, %{}, fn {name, object} ->
      updated = reduce_attributes(object)

      {name, updated}
    end)
  end

  defp reduce_data(object) do
    Map.drop(object, internal_keys(object))
  end

  defp internal_keys(map) do
    Enum.filter(Map.keys(map), fn key ->
      String.starts_with?(to_string(key), "_")
    end)
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
