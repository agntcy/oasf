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
    # domain libs
    :domains,
    :all_domains,
    :domain_categories,
    # skill libs
    :skills,
    :all_skills,
    :skill_categories,
    # module libs
    :modules,
    :all_modules,
    :module_categories
  ]
  defstruct ~w[
    version
    parsed_version
    profiles
    dictionary
    objects
    all_objects
    skills
    all_skills
    skill_categories
    domains
    all_domains
    domain_categories
    modules
    all_modules
    module_categories
  ]a

  @type t() :: %__MODULE__{}
  @type class_t() :: map()
  @type object_t() :: map()
  @type category_t() :: map()
  @type dictionary_t() :: map()

  @skill_categories_file "skill_categories.json"
  @skills_dir "skills"
  @skill_family "skill"

  @domain_categories_file "domain_categories.json"
  @domains_dir "domains"
  @domain_family "domain"

  @module_categories_file "module_categories.json"
  @modules_dir "modules"
  @module_family "module"

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

    {skills, all_skills, skill_categories} =
      read_classes(@skill_categories_file, @skills_dir, @skill_family, version[:version])

    {domains, all_domains, domain_categories} =
      read_classes(
        @domain_categories_file,
        @domains_dir,
        @domain_family,
        version[:version]
      )

    {modules, all_modules, module_categories} =
      read_classes(
        @module_categories_file,
        @modules_dir,
        @module_family,
        version[:version]
      )

    {objects, all_objects} =
      read_objects(version[:version])

    dictionary = Utils.update_dictionary(dictionary, skills, domains, modules, objects)
    dictionary_attributes = dictionary[:attributes]

    # Read and update profiles
    profiles = JsonReader.read_profiles() |> update_profiles(dictionary_attributes)
    # clean up the cached files
    JsonReader.cleanup()
    # Check profiles used in objects, adding objects to profile's _links
    profiles = Profiles.sanity_check(:object, objects, profiles)
    # Check profiles used in classes, adding classes to profile's _links
    profiles = Profiles.sanity_check(:skill, skills, profiles)
    profiles = Profiles.sanity_check(:domain, domains, profiles)
    profiles = Profiles.sanity_check(:module, modules, profiles)

    # Missing description warnings, datetime attributes, and profiles
    objects =
      objects
      |> Utils.update_objects(dictionary_attributes)
      |> update_objects()
      |> final_check(dictionary_attributes)

    skills =
      skills
      |> update_classes(objects)
      |> final_check(dictionary_attributes)

    domains =
      domains
      |> update_classes(objects)
      |> final_check(dictionary_attributes)

    modules =
      modules
      |> update_classes(objects)
      |> final_check(dictionary_attributes)

    # Check for each attribute in the schema if it has a requirement field.
    no_req_set = MapSet.new()
    {profiles, no_req_set} = fix_entities(profiles, no_req_set, "profile")
    {skills, no_req_set} = fix_entities(skills, no_req_set, "skill")
    {domains, no_req_set} = fix_entities(domains, no_req_set, "domain")
    {modules, no_req_set} = fix_entities(modules, no_req_set, "module")
    {objects, no_req_set} = fix_entities(objects, no_req_set, "object")

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
      # skill libs
      skills: skills,
      all_skills: all_skills,
      skill_categories: skill_categories,
      # domain libs
      domains: domains,
      all_domains: all_domains,
      domain_categories: domain_categories,
      # module libs
      modules: modules,
      all_modules: all_modules,
      module_categories: module_categories
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

  @spec skill_categories(__MODULE__.t()) :: map()
  def skill_categories(%__MODULE__{skill_categories: skill_categories}), do: skill_categories

  @spec main_skill(__MODULE__.t(), any) :: nil | category_t()
  def main_skill(%__MODULE__{skill_categories: skill_categories}, id) do
    Map.get(skill_categories[:attributes], id)
  end

  @spec domain_categories(__MODULE__.t()) :: map()
  def domain_categories(%__MODULE__{domain_categories: domain_categories}), do: domain_categories

  @spec main_domain(__MODULE__.t(), any) :: nil | category_t()
  def main_domain(%__MODULE__{domain_categories: domain_categories}, id) do
    Map.get(domain_categories[:attributes], id)
  end

  @spec module_categories(__MODULE__.t()) :: map()
  def module_categories(%__MODULE__{module_categories: module_categories}), do: module_categories

  @spec main_module(__MODULE__.t(), any) :: nil | category_t()
  def main_module(%__MODULE__{module_categories: module_categories}, id) do
    Map.get(module_categories[:attributes], id)
  end

  @spec all_objects(__MODULE__.t()) :: map()
  def all_objects(%__MODULE__{all_objects: all_objects}), do: all_objects

  @spec skills(__MODULE__.t()) :: map()
  def skills(%__MODULE__{skills: skills}), do: skills

  @spec all_skills(__MODULE__.t()) :: map()
  def all_skills(%__MODULE__{all_skills: all_skills}), do: all_skills

  @spec export_skills(__MODULE__.t()) :: map()
  def export_skills(%__MODULE__{skills: skills, dictionary: dictionary}) do
    Enum.into(skills, Map.new(), fn {name, skill} ->
      {name, enrich(skill, dictionary[:attributes])}
    end)
  end

  def skill(%__MODULE__{dictionary: dictionary, skills: skills}, id) do
    case Map.get(skills, id) do
      nil ->
        nil

      skill ->
        enrich(skill, dictionary[:attributes])
    end
  end

  @spec find_skill(Schema.Cache.t(), any) :: nil | map
  def find_skill(%__MODULE__{dictionary: dictionary, skills: skills}, uid) do
    case Enum.find(skills, fn {_, skill} -> skill[:uid] == uid end) do
      {_, skill} -> enrich(skill, dictionary[:attributes])
      nil -> nil
    end
  end

  @spec domains(__MODULE__.t()) :: map()
  def domains(%__MODULE__{domains: domains}), do: domains

  @spec all_domains(__MODULE__.t()) :: map()
  def all_domains(%__MODULE__{all_domains: all_domains}), do: all_domains

  @spec export_domains(__MODULE__.t()) :: map()
  def export_domains(%__MODULE__{domains: domains, dictionary: dictionary}) do
    Enum.into(domains, Map.new(), fn {name, domain} ->
      {name, enrich(domain, dictionary[:attributes])}
    end)
  end

  def domain(%__MODULE__{dictionary: dictionary, domains: domains}, id) do
    case Map.get(domains, id) do
      nil ->
        nil

      domain ->
        enrich(domain, dictionary[:attributes])
    end
  end

  @spec find_domain(Schema.Cache.t(), any) :: nil | map
  def find_domain(%__MODULE__{dictionary: dictionary, domains: domains}, uid) do
    case Enum.find(domains, fn {_, domain} -> domain[:uid] == uid end) do
      {_, domain} -> enrich(domain, dictionary[:attributes])
      nil -> nil
    end
  end

  @spec modules(__MODULE__.t()) :: map()
  def modules(%__MODULE__{modules: modules}), do: modules

  @spec all_modules(__MODULE__.t()) :: map()
  def all_modules(%__MODULE__{all_modules: all_modules}), do: all_modules

  @spec export_modules(__MODULE__.t()) :: map()
  def export_modules(%__MODULE__{modules: modules, dictionary: dictionary}) do
    Enum.into(modules, Map.new(), fn {name, module} ->
      {name, enrich(module, dictionary[:attributes])}
    end)
  end

  def module(%__MODULE__{dictionary: dictionary, modules: modules}, id) do
    case Map.get(modules, id) do
      nil ->
        nil

      module ->
        enrich(module, dictionary[:attributes])
    end
  end

  @spec find_module(Schema.Cache.t(), any) :: nil | map
  def find_module(%__MODULE__{dictionary: dictionary, modules: modules}, uid) do
    case Enum.find(modules, fn {_, module} -> module[:uid] == uid end) do
      {_, module} -> enrich(module, dictionary[:attributes])
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

  @spec entity_ex(__MODULE__.t(), atom(), atom()) :: nil | map()
  def entity_ex(
        %__MODULE__{
          dictionary: dictionary,
          objects: objects,
          skills: skills,
          domains: domains,
          modules: modules
        },
        type,
        id
      ) do
    entities =
      case type do
        :object -> objects
        :skill -> skills
        :domain -> domains
        :module -> modules
        _ -> %{}
      end

    case Map.get(entities, id) do
      nil ->
        nil

      entity ->
        {entity_ex, ref_entities} =
          enrich_ex(
            entity,
            dictionary[:attributes],
            objects,
            skills,
            domains,
            modules,
            Map.new(),
            entity[:is_enum] || false
          )

        Map.put(entity_ex, :entities, Map.to_list(ref_entities))
    end
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
          {name, Utils.deep_merge(base, attribute)}
      end
    end)
    |> Utils.add_sibling_of_to_attributes()
  end

  defp enrich_ex(
         type,
         dictionary_attributes,
         objects,
         skills,
         domains,
         modules,
         ref_entities,
         is_enum
       ) do
    {attributes, ref_entities} =
      update_attributes_ex(
        type[:attributes],
        dictionary_attributes,
        objects,
        skills,
        domains,
        modules,
        ref_entities
      )

    enriched_type =
      type
      |> Map.put(:attributes, attributes)
      |> (fn map -> if is_enum, do: Map.put(map, :is_enum, true), else: map end).()

    {enriched_type, ref_entities}
  end

  defp update_attributes_ex(
         attributes,
         dictionary_attributes,
         objects,
         skills,
         domains,
         modules,
         ref_entities
       ) do
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

          {type, entities} =
            case attribute[:type] do
              "object_t" ->
                {attribute[:object_type], objects}

              "class_t" ->
                family =
                  case attribute[:family] do
                    "skill" -> skills
                    "domain" -> domains
                    "module" -> modules
                    _ -> %{}
                  end

                {attribute[:class_type], family}

              _ ->
                {nil, objects}
            end

          update_attributes_ex(
            type,
            name,
            attribute,
            fn entity_name ->
              enrich_ex(
                entities[entity_name],
                dictionary_attributes,
                objects,
                skills,
                domains,
                modules,
                Map.put(acc, entity_name, nil),
                attribute[:is_enum] || false
              )
            end,
            acc
          )
      end
    end)
  end

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

  defp read_classes(categories_file, classes_dir, class_family, version) do
    categories = JsonReader.read_categories(categories_file) |> update_categories()
    categories_attributes = categories[:attributes]

    classes = JsonReader.read_classes(classes_dir)

    classes =
      classes
      |> Enum.into(%{}, fn class_tuple -> attribute_source(class_tuple) end)
      |> patch_type("class")
      |> resolve_extends()

    # all_classes has just enough info to interrogate the complete class hierarchy,
    # removing most details. It can be used to get the caption and parent (extends) of
    # any class, including hidden ones.
    all_classes =
      Enum.map(
        classes,
        fn {class_key, class} ->
          class =
            class
            |> Map.take([:name, :caption, :extends, :extension])
            |> Map.put(:hidden?, hidden_class?(class_key, class))

          {class_key, class}
        end
      )
      |> Enum.into(%{})

    classes =
      classes
      # remove intermediate hidden classes
      |> Stream.filter(fn {class_key, class} -> !hidden_class?(class_key, class) end)
      |> add_class_family(class_family)
      |> Enum.into(%{}, fn class_tuple ->
        enrich_class(class_tuple, categories_attributes, classes, version, all_classes)
      end)

    {classes, all_classes, categories}
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

  @spec hidden_class?(atom(), map()) :: boolean()
  defp hidden_class?(class_key, class) do
    ignored_keys = [:base_module, :base_skill, :base_domain]
    class_key not in ignored_keys and !Map.has_key?(class, :uid)
  end

  # Add class_uid, class_name, and schema_version to the class.
  defp enrich_class({class_key, class}, categories, classes, version, all_classes) do
    class =
      class
      |> update_class_uid(categories, classes)
      |> add_class_uid(class_key)
      |> add_class_name(class_key, all_classes)
      |> add_schema_version(version)

    {class_key, class}
  end

  defp enrich_object({object_key, object}, version) do
    object =
      object
      |> add_schema_version(version)

    {object_key, object}
  end

  defp update_categories(categories) do
    Map.update!(categories, :attributes, fn attributes ->
      Enum.into(attributes, Map.new(), fn {name, cat} ->
        update_category_uid(name, cat, cat[:extension_id])
      end)
    end)
  end

  defp update_category_uid(name, category, nil) do
    {name, category}
  end

  defp update_category_uid(name, category, extension) do
    {name, Map.update!(category, :uid, fn uid -> Types.category_uid(extension, uid) end)}
  end

  def update_class_uid(class, categories, classes) do
    {key, category} = Utils.find_entity(categories, class, class[:category])

    class =
      if category != nil do
        class
        |> Map.put(:category, Atom.to_string(key))
        |> Map.put(:category_name, category[:caption])
      else
        class
      end

    cat_uid = category[:uid] || 0
    class_uid = class[:uid] || 0

    try do
      case class[:extension_id] do
        nil ->
          if class[:name] == class[:category] do
            # Use the category UID directly if extends is the same as category
            Map.put(class, :uid, Types.class_uid(cat_uid, class_uid))
          else
            # Calculate UID considering the hierarchy and hidden classes
            new_uid = calculate_uid(classes, class_uid, class[:extends], cat_uid)
            Map.put(class, :uid, new_uid)
          end

        ext ->
          Map.put(class, :uid, Types.class_uid(Types.category_uid_ex(ext, cat_uid), class_uid))
      end
    rescue
      ArithmeticError ->
        error("invalid class #{class[:name]}: #{inspect(Map.delete(class, :attributes))}")
    end
  end

  defp calculate_uid(classes, class_uid, extends, cat_uid) do
    case Enum.find(classes, fn {k, _v} -> Atom.to_string(k) == extends end) do
      {_, parent} ->
        if Map.has_key?(parent, :uid) do
          if parent[:category] == parent[:name] do
            # If parent extends category, use category UID
            Types.class_uid(cat_uid, class_uid)
          else
            # Recursively calculate the UID
            parent_uid = calculate_uid(classes, parent[:uid], parent[:extends], cat_uid)
            Types.class_uid(parent_uid, class_uid)
          end
        else
          # If parent is hidden (doesn't have a uid), continue recursion
          calculate_uid(classes, class_uid, parent[:extends], cat_uid)
        end

      nil ->
        Types.class_uid(cat_uid, class_uid)
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

  defp add_class_family(classes, family) do
    Enum.into(classes, %{}, fn {key, class_data} ->
      updated_class_data = Map.put(class_data, :family, family)
      {key, updated_class_data}
    end)
  end

  defp add_class_name(data, name, all_classes) do
    if is_nil(data[:attributes][:name]) do
      data
    else
      class_name = Utils.class_name_with_hierarchy(data[:name], all_classes)

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
        "The schema version: <code>v#{version}"
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

            Map.merge(base, item, &merge_profiles/3)
            |> Map.put(:attributes, attributes)
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
