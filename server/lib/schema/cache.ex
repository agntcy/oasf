# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Cache do
  @moduledoc """
  Builds the schema cache.
  """

  alias Schema.Utils
  alias Schema.JsonReader
  alias Schema.Profiles
  alias Schema.Types

  require Logger

  @enforce_keys [
    :version,
    :parsed_version,
    :profiles,
    :dictionary,
    :objects,
    :all_objects,
    :domains,
    :skills,
    :modules
  ]
  defstruct ~w[
    version
    parsed_version
    profiles
    dictionary
    objects
    all_objects
    skills
    domains
    modules
  ]a

  @type t() :: %__MODULE__{}
  @type class_t() :: map()
  @type object_t() :: map()
  @type category_t() :: map()
  @type dictionary_t() :: map()

  # Maps each class family atom to the directory under priv/schema where its
  # JSON definitions live.  The map's key order also defines the canonical
  # iteration order during cache initialization.
  @class_family_dirs %{skill: "skills", domain: "domains", module: "modules"}

  @doc """
  Load the schema files and initialize the cache.
  """
  @spec init() :: __MODULE__.t()
  def init() do
    version = JsonReader.read_version()
    parsed_version = Utils.parse_version(version[:version])

    if not is_map(parsed_version) do
      {:error, error_message, original_version} = parsed_version
      error("Schema version #{inspect(original_version)} is invalid: #{error_message}")
    end

    dictionary = JsonReader.read_dictionary() |> update_dictionary()

    classes_by_family =
      Map.new(@class_family_dirs, fn {family, dir} ->
        {family, read_classes(dir, Atom.to_string(family), version[:version])}
      end)

    {objects, all_objects} = read_objects(version[:version])

    dictionary = Utils.update_dictionary(dictionary, classes_by_family, objects)
    dictionary_attributes = dictionary[:attributes]

    # Read and update profiles
    profiles = JsonReader.read_profiles() |> update_profiles(dictionary_attributes)
    # clean up the cached files
    JsonReader.cleanup()

    # Check profiles used in objects and classes, adding them to profile's _links
    profiles = Profiles.sanity_check(:object, objects, profiles)

    profiles =
      Enum.reduce(classes_by_family, profiles, fn {family, classes}, acc ->
        Profiles.sanity_check(family, classes, acc)
      end)

    # Missing description warnings, datetime attributes, and profiles
    objects =
      objects
      |> Utils.update_objects(dictionary_attributes)
      |> update_objects()
      |> final_check(dictionary_attributes)

    classes_by_family =
      Map.new(classes_by_family, fn {family, classes} ->
        {family, classes |> update_classes(objects) |> final_check(dictionary_attributes)}
      end)

    # Check for each attribute in the schema if it has a requirement field.
    no_req_set = MapSet.new()
    {profiles, no_req_set} = fix_entities(profiles, no_req_set, "profile")
    {objects, no_req_set} = fix_entities(objects, no_req_set, "object")

    {classes_by_family, no_req_set} =
      Enum.reduce(classes_by_family, {%{}, no_req_set}, fn {family, classes},
                                                           {acc_map, acc_no_req} ->
        {fixed, new_no_req} = fix_entities(classes, acc_no_req, Atom.to_string(family))
        {Map.put(acc_map, family, fixed), new_no_req}
      end)

    if MapSet.size(no_req_set) > 0 do
      no_reqs = no_req_set |> Enum.sort() |> Enum.join(", ")

      Logger.warning(
        "The following attributes do not have a \"requirement\" field," <>
          " a value of \"optional\" will be used: #{no_reqs}"
      )
    end

    %__MODULE__{
      version: version,
      parsed_version: parsed_version,
      profiles: profiles,
      dictionary: dictionary,
      objects: objects,
      all_objects: all_objects,
      skills: classes_by_family.skill,
      domains: classes_by_family.domain,
      modules: classes_by_family.module
    }
  end

  @doc """
    Returns the class extensions.
  """
  @spec extensions :: map()
  def extensions(), do: Schema.JsonReader.extensions()

  @spec reset :: :ok
  def reset(), do: Schema.JsonReader.reset()

  @spec reset(binary) :: :ok
  def reset(path), do: Schema.JsonReader.reset(path)

  @spec version(__MODULE__.t()) :: String.t()
  def version(%__MODULE__{version: version}), do: version[:version]

  @spec parsed_version(__MODULE__.t()) :: Utils.version_or_error_t()
  def parsed_version(%__MODULE__{parsed_version: parsed_version}), do: parsed_version

  @spec profiles(__MODULE__.t()) :: map()
  def profiles(%__MODULE__{profiles: profiles}), do: profiles

  @spec data_types(__MODULE__.t()) :: map()
  def data_types(%__MODULE__{dictionary: dictionary}), do: dictionary[:types]

  @spec dictionary(__MODULE__.t()) :: dictionary_t()
  def dictionary(%__MODULE__{dictionary: dictionary}), do: dictionary

  @spec all_objects(__MODULE__.t()) :: map()
  def all_objects(%__MODULE__{all_objects: all_objects}), do: all_objects

  @typedoc """
  The supported class families.  Each family is backed by its own field on the
  cache struct but shares identical lookup and export semantics.
  """
  @type class_family() :: :skill | :domain | :module

  @doc """
  Returns the raw map of classes for the given `family` (not enriched).
  """
  @spec classes(__MODULE__.t(), class_family()) :: map()
  def classes(%__MODULE__{skills: classes}, :skill), do: classes
  def classes(%__MODULE__{domains: classes}, :domain), do: classes
  def classes(%__MODULE__{modules: classes}, :module), do: classes

  @doc """
  Returns the map of classes for the given `family`, with attributes enriched
  from the dictionary.
  """
  @spec export_classes(__MODULE__.t(), class_family()) :: map()
  def export_classes(%__MODULE__{dictionary: dictionary} = cache, family) do
    cache
    |> classes(family)
    |> Enum.into(Map.new(), fn {name, class} ->
      {name, enrich(class, dictionary[:attributes])}
    end)
  end

  @doc """
  Returns a single enriched class of the given `family` by key, or `nil`.
  """
  @spec class(__MODULE__.t(), class_family(), atom()) :: nil | class_t()
  def class(%__MODULE__{dictionary: dictionary} = cache, family, id) do
    case Map.get(classes(cache, family), id) do
      nil -> nil
      class -> enrich(class, dictionary[:attributes])
    end
  end

  @doc """
  Finds a single enriched class of the given `family` by its `uid`, or `nil`.
  """
  @spec find_class(__MODULE__.t(), class_family(), any) :: nil | map()
  def find_class(%__MODULE__{dictionary: dictionary} = cache, family, uid) do
    case Enum.find(classes(cache, family), fn {_, class} -> class[:uid] == uid end) do
      {_, class} -> enrich(class, dictionary[:attributes])
      nil -> nil
    end
  end

  @spec objects(__MODULE__.t()) :: map()
  def objects(%__MODULE__{objects: objects}), do: objects

  @spec export_objects(__MODULE__.t()) :: map()
  def export_objects(%__MODULE__{dictionary: dictionary, objects: objects}) do
    Enum.into(objects, Map.new(), fn {name, object} ->
      {name, enrich(object, dictionary[:attributes])}
    end)
  end

  @spec object(__MODULE__.t(), any) :: nil | object_t()
  def object(%__MODULE__{dictionary: dictionary, objects: objects}, id) do
    case Map.get(objects, id) do
      nil ->
        nil

      object ->
        enrich(object, dictionary[:attributes])
    end
  end

  @spec entity_ex(__MODULE__.t(), :object | class_family(), atom()) :: nil | map()
  def entity_ex(
        %__MODULE__{dictionary: dictionary} = cache,
        type,
        id
      ) do
    entities = all_entities(cache)
    pool = Map.get(entities, type, %{})

    case Map.get(pool, id) do
      nil ->
        nil

      entity ->
        {entity_ex, ref_entities} =
          enrich_ex(
            entity,
            dictionary[:attributes],
            entities,
            Map.new(),
            entity[:is_enum] || false
          )

        Map.put(entity_ex, :entities, Map.to_list(ref_entities))
    end
  end

  # Builds the `%{object: ..., skill: ..., domain: ..., module: ...}` lookup
  # used by `enrich_ex/5` to resolve `class_t`/`object_t` references.
  defp all_entities(%__MODULE__{
         objects: objects,
         skills: skills,
         domains: domains,
         modules: modules
       }) do
    %{object: objects, skill: skills, domain: domains, module: modules}
  end

  defp enrich(type, dictionary_attributes) do
    Map.update!(type, :attributes, fn list -> update_attributes(list, dictionary_attributes) end)
  end

  defp update_attributes(attributes, dictionary_attributes) do
    attributes
    |> Enum.map(fn {name, attribute} ->
      # Use reference if exists instead of the name
      reference =
        if Map.has_key?(attribute, :reference) do
          String.to_atom(attribute[:reference])
        else
          name
        end

      case find_attribute(dictionary_attributes, reference, attribute[:_source]) do
        nil ->
          Logger.warning("undefined attribute: #{reference}: #{inspect(attribute)}")
          {name, attribute}

        base ->
          # Drop the dictionary attribute's `_links` back-reference: it lists
          # every class using the attribute (O(n) per attribute), so keeping it
          # on each enriched class is O(n^2) and, since the export is deep-copied
          # out of the Repo Agent per request, inflates memory by >100 MiB.
          # `_links` is internal and stripped from every response anyway (the
          # detailed `enrich_ex/5` path drops it identically).
          {name, Utils.deep_merge(base, attribute) |> Map.delete(:_links)}
      end
    end)
    |> Utils.add_sibling_of_to_attributes()
  end

  defp enrich_ex(type, dictionary_attributes, entities, ref_entities, is_enum) do
    {attributes, ref_entities} =
      update_attributes_ex(type[:attributes], dictionary_attributes, entities, ref_entities)

    enriched_type =
      type
      |> Map.put(:attributes, attributes)
      |> (fn map -> if is_enum, do: Map.put(map, :is_enum, true), else: map end).()

    {enriched_type, ref_entities}
  end

  defp update_attributes_ex(attributes, dictionary_attributes, entities, ref_entities) do
    Enum.map_reduce(attributes, ref_entities, fn {name, attribute}, acc ->
      reference =
        if Map.has_key?(attribute, :reference) do
          String.to_atom(attribute[:reference])
        else
          name
        end

      case find_attribute(dictionary_attributes, reference, attribute[:_source]) do
        nil ->
          Logger.warning("undefined attribute: #{reference}: #{inspect(attribute)}")
          {{name, attribute}, acc}

        base ->
          attribute =
            Utils.deep_merge(base, attribute)
            |> Map.delete(:_links)

          {type, pool} = resolve_attribute_pool(attribute, entities)

          update_attributes_ex(
            type,
            name,
            attribute,
            fn entity_name ->
              enrich_ex(
                pool[entity_name],
                dictionary_attributes,
                entities,
                Map.put(acc, entity_name, nil),
                attribute[:is_enum] || false
              )
            end,
            acc
          )
      end
    end)
  end

  # Selects the type-key and entity pool to look up an attribute's reference in.
  # Returns `{nil, _}` for attributes that aren't class or object references.
  defp resolve_attribute_pool(attribute, entities) do
    case attribute[:type] do
      "object_t" ->
        {attribute[:object_type], entities[:object]}

      "class_t" ->
        family_atom = family_to_atom(attribute[:family])
        {attribute[:class_type], Map.get(entities, family_atom, %{})}

      _ ->
        {nil, entities[:object]}
    end
  end

  defp family_to_atom("skill"), do: :skill
  defp family_to_atom("domain"), do: :domain
  defp family_to_atom("module"), do: :module
  defp family_to_atom(_), do: nil

  defp update_attributes_ex(nil, name, attribute, _enrich, acc) do
    {{name, attribute}, acc}
  end

  defp update_attributes_ex(type, name, attribute, enrich, acc) do
    entity_name = String.to_atom(type)

    acc =
      if Map.has_key?(acc, entity_name) do
        acc
      else
        {entity, acc} = enrich.(entity_name)
        Map.put(acc, entity_name, entity)
      end

    {{name, attribute}, acc}
  end

  defp find_attribute(dictionary, name, source) do
    case Atom.to_string(source) |> String.split("/") do
      [_] ->
        dictionary[name]

      [ext, _] ->
        ext_name = String.to_atom("#{ext}/#{name}")
        dictionary[ext_name] || dictionary[name]

      _ ->
        Logger.warning("#{name} has an invalid source: #{source}")
        dictionary[name]
    end
  end

  defp read_classes(classes_dir, class_family, version) do
    classes = JsonReader.read_classes(classes_dir)

    classes =
      classes
      |> Enum.into(%{}, fn class_tuple -> attribute_source(class_tuple) end)
      |> patch_type("class")
      |> resolve_extends()
      |> Enum.into(%{}, fn class_tuple ->
        enrich_class(class_tuple, classes, class_family, version)
      end)

    classes
  end

  defp read_objects(version) do
    objects = JsonReader.read_objects()

    objects =
      objects
      |> Enum.into(%{}, fn object_tuple -> attribute_source(object_tuple) end)
      |> patch_type("object")
      |> resolve_extends()

    # all_objects has just enough info to interrogate the complete object hierarchy,
    # removing most details. It can be used to get the caption and parent (extends) of
    # any object, including hidden ones
    all_objects =
      Enum.map(
        objects,
        fn {object_key, object} ->
          object =
            object
            |> Map.take([:name, :caption, :extends, :extension])
            |> Map.put(:hidden?, hidden_object?(object_key))

          {object_key, object}
        end
      )
      |> Enum.into(%{})

    objects =
      objects
      |> Stream.filter(fn {object_key, _object} -> !hidden_object?(object_key) end)
      |> Enum.into(%{})
      |> Enum.into(%{}, fn object_tuple ->
        enrich_object(object_tuple, version)
      end)

    {objects, all_objects}
  end

  @spec hidden_object?(atom() | String.t()) :: boolean()
  defp hidden_object?(object_name) when is_binary(object_name) do
    String.starts_with?(object_name, "_")
  end

  defp hidden_object?(object_key) when is_atom(object_key) do
    hidden_object?(Atom.to_string(object_key))
  end

  # Add class_uid, class_name, schema_version, and family to the class.
  defp enrich_class({class_key, class}, classes, class_family, version) do
    class =
      class
      |> Map.put(:family, class_family)
      |> update_class_uid(classes)
      |> add_class_uid(class_key)
      |> add_class_name(class_key, classes)
      |> add_schema_version(version)

    {class_key, class}
  end

  defp enrich_object({object_key, object}, version) do
    object =
      object
      |> add_schema_version(version)

    {object_key, object}
  end

  def update_class_uid(class, classes_with_uids) do
    # If this class is itself a category, don't add category metadata
    is_category = Map.get(class, :category) == true

    # Find the category class by traversing up the inheritance chain (only for non-category classes)
    category = if is_category, do: nil, else: find_category_class(class, classes_with_uids)

    class =
      if category != nil do
        category_key = String.to_atom(category[:name])

        class
        |> Map.put(:category, Atom.to_string(category_key))
        |> Map.put(:category_name, category[:caption])
      else
        class
      end

    class_uid = class[:uid] || 0

    try do
      case class[:extension_id] do
        nil ->
          # Calculate UID based on parent's UID recursively
          new_uid = calculate_uid(classes_with_uids, class_uid, class[:extends])
          Map.put(class, :uid, new_uid)

        ext ->
          # For extensions, we still need category UID
          cat_uid = if category != nil, do: category[:uid] || 0, else: 0
          Map.put(class, :uid, Types.class_uid(Types.category_uid_ex(ext, cat_uid), class_uid))
      end
    rescue
      ArithmeticError ->
        error("invalid class #{class[:name]}: #{inspect(Map.delete(class, :attributes))}")
    end
  end

  defp find_category_class(class, classes) do
    # If this class itself is a category, return it
    if Map.get(class, :category) == true do
      class
    else
      # Otherwise, check the immediate parent first
      case class[:extends] do
        nil ->
          nil

        extends ->
          parent_key = String.to_atom(extends)

          case classes[parent_key] do
            nil ->
              nil

            parent ->
              # If the immediate parent is a category, return it
              # Otherwise, continue traversing up
              if Map.get(parent, :category) == true do
                parent
              else
                find_category_class(parent, classes)
              end
          end
      end
    end
  end

  defp calculate_uid(classes, class_uid, extends) do
    case extends do
      nil ->
        # No parent, use 0 as base
        Types.class_uid(0, class_uid)

      extends ->
        # Find the parent class
        case Enum.find(classes, fn {k, _v} -> Atom.to_string(k) == extends end) do
          {_, parent} ->
            # If parent has a uid, recursively calculate it first, then use it
            if Map.has_key?(parent, :uid) do
              parent_uid = calculate_uid(classes, parent[:uid], parent[:extends])
              Types.class_uid(parent_uid, class_uid)
            else
              # Parent is hidden (no uid), continue recursion up the chain
              calculate_uid(classes, class_uid, parent[:extends])
            end

          nil ->
            # Parent not found, use 0 as base
            Types.class_uid(0, class_uid)
        end
    end
  end

  defp add_class_uid(data, name) do
    if is_nil(data[:attributes][:id]) do
      data
    else
      class_caption = data[:caption]

      class_uid =
        data[:uid]
        |> Integer.to_string()
        |> String.to_atom()

      enum = %{
        :caption => class_caption,
        :description => data[:description]
      }

      data
      |> put_in([:attributes, :id, :enum], %{class_uid => enum})
      |> put_in([:attributes, :id, :_source], name)
    end
  end

  defp add_class_name(data, name, all_classes) do
    if is_nil(data[:attributes][:name]) do
      data
    else
      class_name = Utils.class_name_with_hierarchy(name, all_classes)

      enum = %{
        :caption => data[:caption],
        :description => data[:description]
      }

      data
      |> put_in([:attributes, :name, :enum], %{String.to_atom(class_name) => enum})
      |> put_in([:attributes, :name, :_source], name)
    end
  end

  defp add_schema_version(class, version) do
    if class[:attributes][:schema_version] == nil do
      class
    else
      class
      |> put_in(
        [:attributes, :schema_version, :description],
        "The schema version: <code>#{version}"
      )
    end
  end

  # Adds :_source key to each attribute of item. This must be done before processing (compiling)
  # inheritance and patching (resolve_extends and patch_type) since after that processing the
  # original source is lost.
  defp attribute_source({item_key, item}) do
    item =
      Map.update(
        item,
        :attributes,
        [],
        fn attributes ->
          Enum.into(
            attributes,
            %{},
            fn
              {key, nil} ->
                {key, nil}

              {key, attribute} ->
                if patch_extends?(item) do
                  # Because attribute_source done before patching with patch_type, we need to
                  # capture the final "patched" type for use by the UI when displaying the source.
                  # Other uses of :_source require the original pre-patched source.
                  {
                    key,
                    attribute
                    |> Map.put(:_source, item_key)
                    |> Map.put(:_source_patched, String.to_atom(item[:extends]))
                  }
                else
                  {key, Map.put(attribute, :_source, item_key)}
                end
            end
          )
        end
      )

    {item_key, item}
  end

  defp patch_type(items, kind) do
    Enum.reduce(items, %{}, fn {key, item}, acc ->
      # Logger.debug(fn ->
      #   patching? =
      #     if patch_extends?(item) do
      #       "    PATCHING:"
      #     else
      #       "not patching:"
      #     end

      #   "#{patching?} key #{inspect(key)}," <>
      #     " name #{inspect(item[:name])}, extends #{inspect(item[:extends])}," <>
      #     " caption #{inspect(item[:caption])}, extension #{inspect(item[:extension])}"
      # end)

      if patch_extends?(item) do
        # This is an extension class or object with the same name its own base class
        # (The name is not prefixed with the extension name, unlike a key / uid.)

        name = item[:extends]

        base_key = String.to_atom(name)

        Logger.info("#{key} #{kind} is patching #{base_key}")

        # First check the accumulator in case the same object is extended by multiple extensions,
        # that way the previous modifications are taken into account
        case Map.get(acc, base_key, Map.get(items, base_key)) do
          nil ->
            error("#{key} #{kind} attempted to patch invalid item: #{base_key}")
            acc

          base ->
            profiles = merge_profiles(base[:profiles], item[:profiles])
            attributes = Utils.deep_merge(base[:attributes], item[:attributes])

            patched_base =
              base
              |> Map.put(:profiles, profiles)
              |> Map.put(:attributes, attributes)
              |> Utils.put_non_nil(:references, item[:references])
              # Top-level attribute associations.
              # Only occurs in classes, but is safe to do for objects too.
              |> Utils.put_non_nil(:associations, item[:associations])
              |> patch_constraints(item)

            Map.put(acc, base_key, patched_base)
        end
      else
        Map.put_new(acc, key, item)
      end
    end)
  end

  # Is this item a special patch extends definition as done by patch_type.
  # It is triggered by a class or object that has no name or the name is the same as the extends.
  defp patch_extends?(item) do
    extends = item[:extends]

    if extends do
      name = item[:name]

      if name do
        if name == extends do
          # name and extends are the same
          true
        else
          # true if name matches extends without extension scope ("extension/name" -> "name")
          # This when an item in one extension patches an item in another.
          name == Utils.descope(extends)
        end
      else
        # extends with no name
        true
      end
    else
      false
    end
  end

  defp patch_constraints(base, item) do
    if Map.has_key?(item, :constraints) do
      constraints = item[:constraints]

      if constraints != nil and !Enum.empty?(constraints) do
        Map.put(base, :constraints, constraints)
      else
        Map.delete(base, :constraints)
      end
    else
      base
    end
  end

  defp resolve_extends(items) do
    Enum.map(items, fn {item_key, item} -> {item_key, resolve_extends(items, item)} end)
  end

  defp resolve_extends(items, item) do
    case item[:extends] do
      nil ->
        item

      extends ->
        {_parent_key, parent_item} = Utils.find_parent(items, extends, item[:extension])

        case parent_item do
          nil ->
            error("#{inspect(item[:name])} extends undefined item: #{inspect(extends)}")

          base ->
            base = resolve_extends(items, base)

            attributes =
              Utils.deep_merge(base[:attributes], item[:attributes])
              |> Enum.filter(fn {_name, attr} -> attr != nil end)
              |> Map.new()

            # Merge base into item, but don't inherit the category field
            # Category should only be present if explicitly defined in the class itself
            merged =
              Map.merge(base, item, &merge_profiles/3)
              |> Map.put(:attributes, attributes)

            # Remove category if it wasn't originally in the item (don't inherit it)
            if Map.has_key?(item, :category) do
              merged
            else
              Map.delete(merged, :category)
            end
        end
    end
  end

  defp merge_profiles(:profiles, v1, nil), do: v1
  defp merge_profiles(:profiles, nil, v2), do: v2
  defp merge_profiles(:profiles, v1, v2), do: Enum.concat(v1, v2) |> Enum.uniq()
  defp merge_profiles(_profiles, v1, nil), do: v1
  defp merge_profiles(_profiles, _v1, v2), do: v2

  # Final fix up a map of many name -> entity key-value pairs.
  # The term "entities" means to profiles, objects, or classes.
  @spec fix_entities(map(), MapSet.t(), String.t()) :: {map(), MapSet.t()}
  defp fix_entities(entities, no_req_set, kind) do
    Enum.reduce(
      entities,
      {Map.new(), no_req_set},
      fn {entity_key, entity}, {entities, no_req_set} ->
        {entity, no_req_set} = fix_entity(entity, no_req_set, entity_key, kind)
        {Map.put(entities, entity_key, entity), no_req_set}
      end
    )
  end

  # Final fix up of an entity definition map.
  # The term "entity" mean a single profile, object, or class.
  @spec fix_entity(map(), MapSet.t(), atom(), String.t()) :: {map(), MapSet.t()}
  defp fix_entity(entity, no_req_set, entity_key, kind) do
    attributes = entity[:attributes]

    if attributes do
      {attributes, no_req_set} =
        Enum.reduce(
          attributes,
          {%{}, no_req_set},
          fn {attribute_name, attribute_details}, {attributes, no_req_set} ->
            {
              # The Map.put_new fixes the actual missing requirement problem
              Map.put(
                attributes,
                attribute_name,
                Map.put_new(attribute_details, :requirement, "optional")
              ),
              # This adds attributes with missing requirement to a set for later logging
              track_missing_requirement(
                attribute_name,
                attribute_details,
                no_req_set,
                entity_key,
                kind
              )
            }
          end
        )

      {Map.put(entity, :attributes, attributes), no_req_set}
    else
      {entity, no_req_set}
    end
  end

  @spec track_missing_requirement(atom(), map(), MapSet.t(), atom(), String.t()) :: MapSet.t()
  defp track_missing_requirement(attribute_key, attribute, no_req_set, entity_key, kind) do
    if Map.has_key?(attribute, :requirement) do
      no_req_set
    else
      context = "#{entity_key}.#{attribute_key} (#{kind})"

      if MapSet.member?(no_req_set, context) do
        no_req_set
      else
        MapSet.put(no_req_set, context)
      end
    end
  end

  defp final_check(maps, dictionary) do
    Enum.into(maps, %{}, fn {name, map} ->
      {name, final_check(name, map, dictionary)}
    end)
  end

  defp final_check(name, map, dictionary) do
    profiles = map[:profiles]
    attributes = map[:attributes]

    list =
      Enum.reduce(attributes, [], fn {key, attribute}, acc ->
        missing_desc_warning(attribute[:description], name, key, dictionary)
        add_datetime(find_attribute(dictionary, key, attribute[:_source]), key, attribute, acc)
      end)

    update_profiles(list, map, profiles, attributes)
  end

  defp missing_desc_warning(nil, name, key, dictionary) do
    desc = get_in(dictionary, [key, :description]) || ""

    if String.contains?(desc, "See specific usage") do
      Logger.warning("Please update the description for #{name}.#{key}: #{desc}")
    end
  end

  defp missing_desc_warning(_desc, _name, _key, _dict) do
    :ok
  end

  defp add_datetime(nil, _key, _attribute, acc) do
    acc
  end

  defp add_datetime(v, key, attribute, acc) do
    case Map.get(v, :type) do
      "timestamp_t" ->
        attribute =
          attribute
          |> Map.put(:profile, "datetime")
          |> Map.put(:requirement, "optional")

        [{Utils.make_datetime(key), attribute} | acc]

      _ ->
        acc
    end
  end

  defp update_profiles([], map, _profiles, _attributes) do
    map
  end

  defp update_profiles(list, map, profiles, attributes) do
    # add the synthetic datetime profile
    map
    |> Map.put(:profiles, merge_profiles(profiles, ["datetime"]))
    |> Map.put(:attributes, Enum.into(list, attributes))
  end

  defp update_objects(objects) do
    Enum.reduce(objects, objects, fn {_name, object}, acc ->
      if Map.has_key?(object, :profiles) do
        update_object_profiles(object, acc)
      else
        acc
      end
    end)
  end

  defp update_object_profiles(object, objects) do
    case object[:_links] do
      nil ->
        objects

      links ->
        update_linked_profiles(:object, links, object, objects)
    end
  end

  defp update_classes(classes, objects) do
    Enum.reduce(objects, classes, fn {name, object}, acc ->
      if Map.has_key?(object, :profiles) do
        update_class_profiles(name, object, acc)
      else
        acc
      end
    end)
  end

  defp update_class_profiles(_name, object, classes) do
    case object[:_links] do
      nil ->
        classes

      links ->
        update_linked_profiles(:class, links, object, classes)
    end
  end

  defp update_linked_profiles(group, links, object, classes) do
    Enum.reduce(links, classes, fn link, acc ->
      if link[:group] == group do
        Map.update!(acc, String.to_atom(link[:type]), fn class ->
          Map.put(class, :profiles, merge_profiles(class[:profiles], object[:profiles]))
        end)
      else
        acc
      end
    end)
  end

  defp merge_profiles(nil, p2) do
    p2
  end

  defp merge_profiles(p1, nil) do
    p1
  end

  defp merge_profiles(p1, p2) do
    Enum.concat(p1, p2) |> Enum.uniq()
  end

  defp update_dictionary(dictionary) do
    types = get_in(dictionary, [:types, :attributes])

    Map.update!(dictionary, :attributes, fn attributes ->
      Enum.into(attributes, %{}, fn {attribute_key, attribute} ->
        type = attribute[:type] || "object_t"

        attribute =
          case types[String.to_atom(type)] do
            nil ->
              attribute
              |> Map.put(:type, "object_t")
              |> Map.put(:object_type, type)

            _type ->
              attribute
          end

        {attribute_key, attribute}
      end)
    end)
  end

  # Flesh out profile attributes from dictionary attributes
  defp update_profiles(profiles, dictionary_attributes) do
    Enum.into(profiles, %{}, fn {name, profile} ->
      {name,
       Map.update!(profile, :attributes, fn attributes ->
         update_profile(name, attributes, dictionary_attributes)
       end)}
    end)
  end

  defp update_profile(profile, profile_attributes, dictionary_attributes) do
    Enum.into(profile_attributes, %{}, fn {name, attribute} ->
      reference =
        if Map.has_key?(attribute, :reference) do
          String.to_atom(attribute[:reference])
        else
          name
        end

      {name,
       case find_attribute(dictionary_attributes, reference, String.to_atom(profile)) do
         nil ->
           Logger.warning(
             "profile #{profile} uses #{reference} that is not defined in the dictionary"
           )

           attribute

         dictionary_attribute ->
           update_profile_attribute(attribute, dictionary_attribute)
       end
       |> Map.delete(:profile)}
    end)
  end

  defp update_profile_attribute(to, from) do
    to
    |> copy_new(from, :caption)
    |> copy_new(from, :description)
    |> copy_new(from, :is_array)
    |> copy_new(from, :enum)
    |> copy_new(from, :type)
    |> copy_new(from, :type_name)
    |> copy_new(from, :object_name)
    |> copy_new(from, :object_type)
    |> copy_new(from, :source)
    |> copy_new(from, :references)
    |> copy_new(from, :sibling)
    |> copy_new(from, :"@deprecated")
  end

  defp copy_new(to, from, key) do
    case from[key] do
      nil -> to
      val -> Map.put_new(to, key, val)
    end
  end

  defp error(message) do
    Logger.error(message)
    System.stop(1)
  end
end
