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

  @spec skill_categories :: map()
  def skill_categories() do
    skill_categories(nil)
  end

  @spec skill_categories(extensions_t() | nil) :: map()
  def skill_categories(extensions) do
    categories_generic(extensions, &Cache.skills/1, &filter/2)
  end

  @spec skill_category(atom) :: nil | Cache.category_t()
  def skill_category(id) do
    skill_category(nil, id)
  end

  @spec skill_category(extensions_t() | nil, atom) :: nil | Cache.category_t()
  def skill_category(extensions, id) do
    category_generic(extensions, id, &Cache.skills/1)
  end

  @spec domain_categories :: map()
  def domain_categories() do
    domain_categories(nil)
  end

  @spec domain_categories(extensions_t() | nil) :: map()
  def domain_categories(extensions) do
    categories_generic(extensions, &Cache.domains/1, &filter/2)
  end

  @spec domain_category(atom) :: nil | Cache.category_t()
  def domain_category(id) do
    domain_category(nil, id)
  end

  @spec domain_category(extensions_t() | nil, atom) :: nil | Cache.category_t()
  def domain_category(extensions, id) do
    category_generic(extensions, id, &Cache.domains/1)
  end

  @spec module_categories :: map()
  def module_categories() do
    module_categories(nil)
  end

  @spec module_categories(extensions_t() | nil) :: map()
  def module_categories(extensions) do
    # Categories are structural and don't have extension fields, so we don't filter them
    categories_generic(extensions, &Cache.modules/1, fn attributes, _extensions -> attributes end)
  end

  @spec module_category(atom) :: nil | Cache.category_t()
  def module_category(id) do
    module_category(nil, id)
  end

  @spec module_category(extensions_t() | nil, atom) :: nil | Cache.category_t()
  def module_category(extensions, id) do
    category_generic(extensions, id, &Cache.modules/1)
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
    skills(nil)
  end

  @spec skills(extensions_t() | nil) :: map()
  def skills(extensions) do
    classes_generic(extensions, &Cache.skills/1, &filter_category_classes/1)
  end

  @spec all_skills() :: map()
  def all_skills() do
    Agent.get(__MODULE__, fn schema ->
      Cache.skills(schema) |> build_all_classes()
    end)
  end

  @spec domains() :: map()
  def domains() do
    domains(nil)
  end

  @spec domains(extensions_t() | nil) :: map()
  def domains(extensions) do
    classes_generic(extensions, &Cache.domains/1, &filter_category_classes/1)
  end

  @spec all_domains() :: map()
  def all_domains() do
    Agent.get(__MODULE__, fn schema ->
      Cache.domains(schema) |> build_all_classes()
    end)
  end

  @spec modules() :: map()
  def modules() do
    modules(nil)
  end

  @spec modules(extensions_t() | nil) :: map()
  def modules(extensions) do
    classes_generic(extensions, &Cache.modules/1, &filter_category_classes/1)
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

  @spec export_skills() :: map()
  def export_skills() do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_skills(schema) |> filter_category_classes()
    end)
  end

  @spec export_skills(extensions_t() | nil) :: map()
  def export_skills(nil) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_skills(schema) |> filter_category_classes()
    end)
  end

  def export_skills(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_skills(schema) |> filter_category_classes() |> filter(extensions)
    end)
  end

  @spec export_domains() :: map()
  def export_domains() do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_domains(schema) |> filter_category_classes()
    end)
  end

  @spec export_domains(extensions_t() | nil) :: map()
  def export_domains(nil) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_domains(schema) |> filter_category_classes()
    end)
  end

  def export_domains(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_domains(schema) |> filter_category_classes() |> filter(extensions)
    end)
  end

  @spec export_modules() :: map()
  def export_modules() do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_modules(schema) |> filter_category_classes()
    end)
  end

  @spec export_modules(extensions_t() | nil) :: map()
  def export_modules(nil) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_modules(schema) |> filter_category_classes()
    end)
  end

  def export_modules(extensions) do
    Agent.get(__MODULE__, fn schema ->
      Cache.export_modules(schema) |> filter_category_classes() |> filter(extensions)
    end)
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

  # Generic helper for categories functions
  defp categories_generic(extensions, cache_fn, filter_fn) do
    Agent.get(__MODULE__, fn schema ->
      all_classes = cache_fn.(schema)
      flat_categories = all_classes |> build_categories_flat()
      nested_categories = build_categories_nested(flat_categories)

      # Populate classes recursively while preserving subcategories
      populated_categories =
        populate_categories_recursive(extensions, nested_categories, all_classes)

      result = %{attributes: populated_categories}

      # Apply extension filtering if needed
      if extensions != nil do
        Map.update!(result, :attributes, fn attributes ->
          filter_fn.(attributes, extensions)
        end)
      else
        result
      end
    end)
  end

  # Generic helper for classes functions (skills, domains, modules)
  defp classes_generic(extensions, cache_fn, preprocess_fn) do
    Agent.get(__MODULE__, fn schema ->
      classes = cache_fn.(schema) |> preprocess_fn.()

      if extensions != nil do
        filter(classes, extensions)
      else
        classes
      end
    end)
  end

  # Generic helper for single category functions
  defp category_generic(extensions, id, cache_fn) do
    Agent.get(__MODULE__, fn schema ->
      all_classes = cache_fn.(schema)
      flat_categories = all_classes |> build_categories_flat()

      case Map.get(flat_categories, id) do
        nil ->
          nil

        category ->
          # Build nested structure for this category and its subcategories
          nested_categories = build_categories_nested(flat_categories)

          # Get the category from nested structure if it's a top-level category,
          # otherwise use the flat category and build its subcategories
          category_with_subcategories =
            case Map.get(nested_categories, id) do
              nil ->
                # It's a subcategory, build its subcategories structure
                add_subcategories_to_category(category, id, flat_categories)

              nested_category ->
                nested_category
            end

          # Populate classes and subcategories recursively
          category_uid = Atom.to_string(id)

          populated_category =
            populate_category_recursive(extensions, id, category_with_subcategories, all_classes)

          Map.put(populated_category, :name, category_uid)
      end
    end)
  end

  # Extract class filtering logic to avoid duplication
  defp filter_classes_for_category(extensions, category_uid, category_id, all_classes) do
    all_classes
    |> Enum.filter(fn {_name, class} ->
      # Exclude classes that are themselves categories (category: true)
      # These should appear in subcategories, not classes
      if Map.get(class, :category) == true do
        false
      else
        cat = class[:category]

        # Match the original add_classes logic
        if extensions == nil do
          # When extensions is nil, check both conditions like original add_classes(nil, ...)
          cat == category_uid or Utils.to_uid(class[:extension], cat) == category_id
        else
          # When extensions is provided, use case statement like original add_classes(extensions, ...)
          case class[:extension] do
            nil ->
              cat == category_uid

            ext ->
              MapSet.member?(extensions, ext) and
                (cat == category_uid or Utils.to_uid(ext, cat) == category_id)
          end
        end
      end
    end)
    |> Enum.map(fn {name, class} ->
      # Remove category and category_name fields like the original add_classes did
      cleaned_class = class |> Map.delete(:category) |> Map.delete(:category_name)
      {name, cleaned_class}
    end)
    |> Enum.into(%{})
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

  # Helper: Build flat categories map from classes
  defp build_categories_flat(classes) do
    base_classes = [:base_module, :base_skill, :base_domain]

    classes
    |> Enum.filter(fn {key, class} ->
      key not in base_classes && Map.get(class, :category) == true
    end)
    |> Enum.map(fn {_key, class} ->
      category_key = String.to_atom(class[:name])

      category_data = %{
        uid: class[:uid] || 0,
        caption: class[:caption],
        description: class[:description],
        extends: class[:extends]
      }

      {category_key, category_data}
    end)
    |> Enum.into(%{})
  end

  # Helper: Build nested categories structure from flat categories
  defp build_categories_nested(flat_categories) do
    # Find top-level categories (those that don't extend another category)
    top_level =
      flat_categories
      |> Enum.filter(fn {_key, category} ->
        case category[:extends] do
          nil ->
            true

          extends ->
            parent_key = String.to_atom(extends)
            not Map.has_key?(flat_categories, parent_key)
        end
      end)
      |> Enum.into(%{})

    # Build subcategories for each top-level category recursively
    Enum.into(top_level, %{}, fn {key, category} ->
      {key, add_subcategories_to_category(category, key, flat_categories)}
    end)
  end

  defp add_subcategories_to_category(category, category_key, all_categories) do
    subcategories =
      all_categories
      |> Enum.filter(fn {_key, cat} ->
        cat[:extends] == Atom.to_string(category_key)
      end)
      |> Enum.map(fn {subcat_key, subcat} ->
        subcat_with_nested = add_subcategories_to_category(subcat, subcat_key, all_categories)
        {subcat_key, subcat_with_nested}
      end)
      |> Enum.sort_by(fn {_key, subcat} -> subcat[:uid] || 0 end)

    if length(subcategories) > 0 do
      subcategories_map = Enum.into(subcategories, %{})
      Map.put(category, :subcategories, subcategories_map)
    else
      category
    end
  end

  # Helper: Filter out category classes (category: true)
  defp filter_category_classes(classes) do
    base_classes = [:base_module, :base_skill, :base_domain]

    classes
    |> Enum.filter(fn {key, class} ->
      key in base_classes || Map.get(class, :category) != true
    end)
    |> Enum.into(%{})
  end

  # Helper: Recursively populate classes for categories while preserving subcategories structure
  defp populate_categories_recursive(extensions, categories, all_classes) do
    Enum.into(categories, %{}, fn {category_id, category} ->
      # Get classes for this category using the same logic as add_classes
      category_uid = Atom.to_string(category_id)

      category_classes =
        filter_classes_for_category(extensions, category_uid, category_id, all_classes)

      category_with_classes = Map.put(category, :classes, category_classes)

      # Recursively populate subcategories if they exist
      populated_category =
        case category[:subcategories] do
          nil ->
            category_with_classes

          subcategories when is_map(subcategories) ->
            populated_subcategories =
              subcategories
              |> Enum.map(fn {subcat_id, subcat} ->
                {subcat_id,
                 populate_category_recursive(extensions, subcat_id, subcat, all_classes)}
              end)
              |> Enum.into(%{})

            Map.put(category_with_classes, :subcategories, populated_subcategories)

          _ ->
            category_with_classes
        end

      {category_id, populated_category}
    end)
  end

  # Helper: Recursively populate classes for a single category (used for subcategories)
  defp populate_category_recursive(extensions, category_id, category, all_classes) do
    # Get classes for this category
    category_uid = Atom.to_string(category_id)

    category_classes =
      filter_classes_for_category(extensions, category_uid, category_id, all_classes)

    category_with_classes =
      category
      |> Map.put(:classes, category_classes)
      |> Map.put(:name, category_uid)

    # Recursively populate subcategories if they exist
    case category[:subcategories] do
      nil ->
        category_with_classes

      subcategories when is_map(subcategories) ->
        populated_subcategories =
          subcategories
          |> Enum.map(fn {subcat_id, subcat} ->
            {subcat_id, populate_category_recursive(extensions, subcat_id, subcat, all_classes)}
          end)
          |> Enum.into(%{})

        Map.put(category_with_classes, :subcategories, populated_subcategories)

      _ ->
        category_with_classes
    end
  end

  @spec taxonomy_modules :: map()
  def taxonomy_modules() do
    taxonomy_modules(nil)
  end

  @spec taxonomy_modules(extensions_t() | nil) :: map()
  def taxonomy_modules(extensions) do
    Agent.get(__MODULE__, fn schema ->
      all_classes = Cache.modules(schema)
      build_taxonomy_tree(extensions, all_classes, :base_module)
    end)
  end

  @spec taxonomy_skills :: map()
  def taxonomy_skills() do
    taxonomy_skills(nil)
  end

  @spec taxonomy_skills(extensions_t() | nil) :: map()
  def taxonomy_skills(extensions) do
    Agent.get(__MODULE__, fn schema ->
      all_classes = Cache.skills(schema)
      build_taxonomy_tree(extensions, all_classes, :base_skill)
    end)
  end

  @spec taxonomy_domains :: map()
  def taxonomy_domains() do
    taxonomy_domains(nil)
  end

  @spec taxonomy_domains(extensions_t() | nil) :: map()
  def taxonomy_domains(extensions) do
    Agent.get(__MODULE__, fn schema ->
      all_classes = Cache.domains(schema)
      build_taxonomy_tree(extensions, all_classes, :base_domain)
    end)
  end

  # Build a complete taxonomy tree with categories, subcategories, classes, and subclasses
  defp build_taxonomy_tree(extensions, all_classes, base_class_key) do
    # Filter out base class and build flat categories
    filtered_classes =
      Enum.filter(all_classes, fn {key, _class} ->
        key != base_class_key
      end)
      |> Enum.into(%{})

    # Build flat categories map
    flat_categories = build_categories_flat(filtered_classes)

    # Build nested categories structure
    nested_categories = build_categories_nested(flat_categories)

    # Build complete taxonomy tree with classes and subclasses
    build_taxonomy_tree_recursive(
      extensions,
      nested_categories,
      filtered_classes,
      flat_categories
    )
  end

  # Recursively build taxonomy tree for categories
  defp build_taxonomy_tree_recursive(extensions, categories, all_classes, flat_categories) do
    Enum.into(categories, %{}, fn {category_id, category} ->
      category_uid = Atom.to_string(category_id)

      # Get regular classes for this category (non-category classes)
      regular_classes =
        filter_classes_for_category(extensions, category_uid, category_id, all_classes)
        |> Enum.filter(fn {_name, class} ->
          # Exclude classes that extend another non-category class
          extends = class[:extends]

          if extends do
            extends_key = String.to_atom(extends)

            # Only include if extends is a category, or if extends doesn't exist in all_classes as a non-category
            case Map.get(all_classes, extends_key) do
              # Parent doesn't exist, include it
              nil -> true
              # Only include if parent is a category
              parent_class -> Map.get(parent_class, :category) == true
            end
          else
            # No extends, include it
            true
          end
        end)
        |> Enum.into(%{}, fn {name, class} ->
          # Build subclasses for this class - use class[:name] (string) not the atom key
          parent_class_name = Map.get(class, :name) || Atom.to_string(name)

          subclasses =
            build_subclasses_for_class(
              extensions,
              parent_class_name,
              all_classes,
              flat_categories
            )

          simplified_class = simplify_class(class, name, all_classes)

          class_with_subclasses =
            if map_size(subclasses) > 0,
              do: Map.put(simplified_class, :classes, subclasses),
              else: simplified_class

          {name, class_with_subclasses}
        end)

      # Get subcategories (category classes) and merge them into classes with category: true
      subcategory_classes =
        case category[:subcategories] do
          nil ->
            %{}

          subs when is_map(subs) ->
            build_taxonomy_tree_recursive(extensions, subs, all_classes, flat_categories)
            |> Enum.into(%{}, fn {subcat_id, subcat_data} ->
              # Add category: true to mark this as a category class
              subcat_with_category = Map.put(subcat_data, :category, true)
              {subcat_id, subcat_with_category}
            end)

          _ ->
            %{}
        end

      # Merge regular classes and subcategory classes
      all_category_classes = Map.merge(subcategory_classes, regular_classes)

      simplified_category = simplify_category(category, category_id, all_classes)
      # Mark this category with category: true
      category_with_flag = Map.put(simplified_category, :category, true)
      category_with_classes = Map.put(category_with_flag, :classes, all_category_classes)

      {category_id, category_with_classes}
    end)
  end

  # Build subclasses for a given class (classes that extend this class and are not categories)
  defp build_subclasses_for_class(extensions, parent_class_name, all_classes, flat_categories) do
    # parent_class_name should be a string (the name field from the class)
    # Convert to atom for map key lookup if needed
    parent_name_str =
      if is_atom(parent_class_name),
        do: Atom.to_string(parent_class_name),
        else: parent_class_name

    parent_key = String.to_atom(parent_name_str)

    all_classes
    |> Enum.filter(fn {_name, class} ->
      # Exclude categories
      if Map.get(class, :category) == true do
        false
      else
        # Check if this class extends the parent
        extends = class[:extends]

        if extends do
          # extends is a string, compare with parent_name_str
          # Only include if it extends the parent AND the parent is not a category
          if extends == parent_name_str do
            # Make sure the parent is not a category
            not Map.has_key?(flat_categories, parent_key)
          else
            false
          end
        else
          false
        end
      end
    end)
    |> Enum.filter(fn {_name, class} ->
      # Apply extension filtering if needed
      if extensions == nil do
        true
      else
        case class[:extension] do
          nil -> true
          ext -> MapSet.member?(extensions, ext)
        end
      end
    end)
    |> Enum.into(%{}, fn {name, class} ->
      # Recursively build subclasses for this subclass - use class[:name] (string) not the atom key
      subclass_parent_name = Map.get(class, :name) || Atom.to_string(name)

      subclasses =
        build_subclasses_for_class(extensions, subclass_parent_name, all_classes, flat_categories)

      simplified_class = simplify_class(class, name, all_classes)

      class_with_subclasses =
        if map_size(subclasses) > 0,
          do: Map.put(simplified_class, :classes, subclasses),
          else: simplified_class

      {name, class_with_subclasses}
    end)
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

  # Simplify a category to only include name, id, caption, description
  defp simplify_category(category, _category_id, _all_classes) do
    hierarchical_name = get_hierarchical_name(category)

    %{
      name: hierarchical_name,
      id: Map.get(category, :uid) || 0,
      caption: Map.get(category, :caption) || "",
      description: Map.get(category, :description) || ""
    }
  end

  # Simplify a class to only include name, id, caption, description
  defp simplify_class(class, _name_key, _all_classes) do
    hierarchical_name = get_hierarchical_name(class)

    %{
      name: hierarchical_name,
      id: Map.get(class, :uid) || 0,
      caption: Map.get(class, :caption) || "",
      description: Map.get(class, :description) || ""
    }
  end
end
