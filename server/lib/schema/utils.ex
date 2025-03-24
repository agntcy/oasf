# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Utils do
  @moduledoc """
  Defines map helper functions.
  """
  @type link_t() :: %{
          :group => :common | :class | :object,
          :type => String.t(),
          :caption => String.t(),
          optional(:deprecated?) => boolean(),
          optional(:attribute_keys) => nil | MapSet.t(String.t())
        }

  require Logger

  @spec to_uid(binary() | atom()) :: atom
  def to_uid(name) when is_binary(name) do
    String.to_atom(name)
  end

  def to_uid(name) when is_atom(name) do
    name
  end

  @spec to_uid(binary() | nil, binary() | atom()) :: atom()
  def to_uid(nil, name) when is_atom(name) do
    name
  end

  def to_uid(extension, name) when is_atom(name) do
    to_uid(extension, Atom.to_string(name))
  end

  def to_uid(extension, name) do
    make_path(extension, name) |> to_uid()
  end

  @spec make_path(binary() | nil, binary()) :: binary()
  def make_path(nil, name), do: name
  def make_path(extension, name), do: Path.join(extension, name)

  @spec descope(atom() | String.t()) :: String.t()
  def descope(name) when is_binary(name) do
    Path.basename(name)
  end

  def descope(name) when is_atom(name) do
    Path.basename(Atom.to_string(name))
  end

  @spec descope_to_uid(atom() | String.t()) :: atom()
  def descope_to_uid(name) when is_binary(name) do
    String.to_atom(Path.basename(name))
  end

  def descope_to_uid(name) when is_atom(name) do
    String.to_atom(Path.basename(Atom.to_string(name)))
  end

  def find_entity(map, entity, name) when is_binary(name) do
    find_entity(map, entity, String.to_atom(name))
  end

  def find_entity(map, entity, key) do
    case entity[:extension] do
      nil ->
        {key, map[key]}

      extension ->
        ext_key = to_uid(extension, key)

        case Map.get(map, ext_key) do
          nil ->
            {key, map[key]}

          other ->
            {ext_key, other}
        end
    end
  end

  @spec update_dictionary(map, map, map, map) :: map
  def update_dictionary(dictionary, common, classes, objects) do
    dictionary
    |> add_common_links(common)
    |> link_classes(classes)
    |> link_objects(objects)
    |> update_data_types(objects)
    |> define_datetime_attributes()
  end

  @spec update_objects(map(), map()) :: map()
  def update_objects(objects, dictionary) do
    Enum.into(objects, %{}, fn {name, object} ->
      links = object_links(dictionary, Atom.to_string(name))
      {name, Map.put(object, :_links, links)}
    end)
  end

  defp object_links(dictionary, name) do
    Enum.filter(dictionary, fn {_name, map} -> Map.get(map, :object_type) == name end)
    |> Enum.map(fn {_, map} -> Map.get(map, :_links) end)
    |> List.flatten()
    |> Enum.filter(fn links -> links != nil end)
    # We need to de-duplicate by group and type, and merge the attribute_keys sets for each
    # First group_by
    |> Enum.group_by(fn link -> {link[:group], link[:type]} end)
    # Next use reduce to merge each group
    |> Enum.reduce(
      [],
      fn {_group, group_links}, acc ->
        group_link =
          Enum.reduce(
            group_links,
            fn link, link_acc ->
              Map.update(
                link_acc,
                :attribute_keys,
                MapSet.new(),
                fn attribute_keys ->
                  MapSet.union(attribute_keys, link[:attribute_keys])
                end
              )
            end
          )

        [group_link | acc]
      end
    )
    |> Enum.to_list()
  end

  defp link_classes(dictionary, classes) do
    Enum.reduce(classes, dictionary, fn class, acc ->
      add_class_links(acc, class)
    end)
  end

  defp link_objects(dictionary, objects) do
    Enum.reduce(objects, dictionary, fn obj, acc ->
      add_object_links(acc, obj)
    end)
  end

  defp update_data_types(dictionary, objects) do
    types = dictionary[:types][:attributes]

    Map.update!(dictionary, :attributes, fn attributes ->
      update_data_types(attributes, types, objects)
    end)
  end

  defp update_data_types(attributes, types, objects) do
    Enum.into(attributes, %{}, fn {name, value} ->
      data =
        if value[:type] == "object_t" do
          update_object_type(name, value, objects)
        else
          update_data_type(name, value, types)
        end

      {name, data}
    end)
  end

  defp update_object_type(name, value, objects) do
    key = value[:object_type]

    case find_entity(objects, value, key) do
      {key, nil} ->
        Logger.warning("Undefined object type: #{key}, for #{name}")
        Map.put(value, :object_name, "_undefined_")

      {key, object} ->
        value
        |> Map.put(:object_name, object[:caption])
        |> Map.put(:object_type, Atom.to_string(key))
    end
  end

  defp update_data_type(name, value, types) do
    type =
      case value[:type] do
        nil ->
          Logger.warning("Missing data type for: #{name}, will use string_t type")
          "string_t"

        t ->
          t
      end

    case types[String.to_atom(type)] do
      nil ->
        Logger.warning("Undefined data type: #{name}: #{type}")
        value

      type ->
        Map.put(value, :type_name, type[:caption])
    end
  end

  @spec make_link(:common | :class | :object, atom() | String.t(), map()) :: link_t()
  def make_link(group, type, item) do
    if Map.has_key?(item, :"@deprecated") do
      %{
        group: group,
        type: to_string(type),
        caption: item[:caption] || "*No name*",
        deprecated?: true
      }
    else
      %{group: group, type: to_string(type), caption: item[:caption] || "*No name*"}
    end
  end

  # Adds attribute's used-by links to the dictionary.
  defp add_common_links(dict, class) do
    Map.update!(dict, :attributes, fn attributes ->
      link = make_link(:common, class[:name], class)

      update_attributes(
        class,
        attributes,
        link,
        &update_dictionary_links/2
      )
    end)
  end

  defp add_class_links(dictionary, {class_key, class}) do
    Map.update!(dictionary, :attributes, fn dictionary_attributes ->
      type =
        case class[:name] do
          nil -> "base_class"
          _ -> class_key
        end

      link = make_link(:class, type, class)

      update_attributes(
        class,
        dictionary_attributes,
        link,
        &update_dictionary_links/2
      )
    end)
  end

  defp update_dictionary_links(attribute, link) do
    Map.update(attribute, :_links, [link], fn links ->
      [link | links]
    end)
  end

  defp add_object_links(dictionary, {object_key, object}) do
    Map.update!(dictionary, :attributes, fn dictionary_attributes ->
      link = make_link(:object, object_key, object)
      update_attributes(object, dictionary_attributes, link, &update_object_links/2)
    end)
  end

  defp update_object_links(attribute, link) do
    Map.update(attribute, :_links, [link], fn links ->
      [link | links]
    end)
  end

  defp update_attributes(item, dictionary_attributes, link, update_links_fn) do
    item_attributes = item[:attributes]

    Enum.reduce(
      item_attributes,
      dictionary_attributes,
      fn {item_attribute_key, item_attribute}, dictionary_attributes ->
        link =
          Map.update(
            link,
            :attribute_keys,
            MapSet.new([item_attribute_key]),
            fn attribute_keys ->
              MapSet.put(attribute_keys, item_attribute_key)
            end
          )

        case find_entity(dictionary_attributes, item, item_attribute_key) do
          {_, nil} ->
            case String.split(Atom.to_string(item_attribute[:_source]), "/") do
              [ext, _] ->
                ext_key = String.to_atom("#{ext}/#{item_attribute_key}")

                data =
                  case Map.get(dictionary_attributes, ext_key) do
                    nil ->
                      update_links_fn.(item_attribute, link)

                    dictionary_attribute ->
                      # We do _not_ want to merge class / object attribute observable values
                      # back to the dictionary
                      clean_item_attribute = Map.delete(item_attribute, :observable)

                      deep_merge(dictionary_attribute, clean_item_attribute)
                      |> update_links_fn.(link)
                  end

                Map.put(dictionary_attributes, ext_key, data)

              _ ->
                Logger.warning(
                  "\"#{item[:caption]}\" uses undefined attribute:" <>
                    " #{item_attribute_key}: #{inspect(item_attribute)}"
                )

                dictionary_attributes
            end

          {key, item} ->
            Map.put(dictionary_attributes, key, update_links_fn.(item, link))
        end
      end
    )
  end

  @spec merge_classes([map()]) :: map()
  def merge_classes(maps) when is_list(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Map.merge(acc, map, fn
        :base_class, val1, _val2 -> val1
        key, _val1, _val2 -> raise ArgumentError, "Duplicate class names are forbidden: #{key}"
      end)
    end)
  end

  @spec merge_categories([map()]) :: map()
  def merge_categories(maps) when is_list(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Map.merge(acc, map, fn
        key, _val1, _val2 -> raise ArgumentError, "Duplicate category names are forbidden: #{key}"
      end)
    end)
  end

  @spec deep_merge(map | nil, map | nil) :: map | nil
  def deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  def deep_merge(left, nil) when is_map(left) do
    left
  end

  def deep_merge(nil, right) when is_map(right) do
    right
  end

  def deep_merge(nil, nil) do
    nil
  end

  # Key exists in both and both values are maps as well, then they can be merged recursively
  defp deep_resolve(_key, left, right) when is_map(left) and is_map(right) do
    if map_size(left) == 0 do
      right
    else
      if map_size(right) == 0 do
        left
      else
        deep_merge(left, right)
      end
    end
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
  end

  @spec put_non_nil(map(), any(), any()) :: map()
  def put_non_nil(map, _key, nil) when is_map(map) do
    map
  end

  def put_non_nil(map, key, value) when is_map(map) do
    Map.put(map, key, value)
  end

  @doc """
  Filter attributes based on the given profiles.
  """
  @spec apply_profiles(Enum.t(), nil | list() | MapSet.t()) :: Enum.t()
  def apply_profiles(attributes, nil) do
    attributes
  end

  def apply_profiles(attributes, profiles) when is_list(profiles) do
    profiles = MapSet.new(profiles)
    apply_profiles(attributes, profiles, MapSet.size(profiles))
  end

  def apply_profiles(attributes, %MapSet{} = profiles) do
    apply_profiles(attributes, profiles, MapSet.size(profiles))
  end

  def apply_profiles(attributes, _profiles) do
    attributes
  end

  def apply_profiles(attributes, _profiles, 0) do
    remove_profiles(attributes)
  end

  def apply_profiles(attributes, profiles, _size) do
    Enum.filter(attributes, fn {_k, v} ->
      case v[:profile] do
        nil -> true
        profile -> MapSet.member?(profiles, profile)
      end
    end)
  end

  def remove_profiles(attributes) do
    Enum.filter(attributes, fn {_k, v} -> Map.has_key?(v, :profile) == false end)
  end

  defp define_datetime_attributes(dictionary) do
    Map.update!(dictionary, :attributes, fn attributes ->
      Enum.reduce(attributes, %{}, fn {name, attribute}, acc ->
        define_datetime_attribute(acc, attribute[:type], name, attribute)
      end)
    end)
  end

  defp define_datetime_attribute(acc, "timestamp_t", name, attribute) do
    acc
    |> Map.put(name, attribute)
    |> Map.put(make_datetime(name), datetime_attribute(attribute))
  end

  defp define_datetime_attribute(acc, _type, name, attribute) do
    Map.put(acc, name, attribute)
  end

  defp datetime_attribute(attribute) do
    attribute
    |> Map.put(:type, "datetime_t")
    |> Map.put(:type_name, "Datetime")
  end

  def make_datetime(name) do
    (Atom.to_string(name) <> "_dt") |> String.to_atom()
  end

  @spec observable_type_id_to_atom(any()) :: atom()
  def observable_type_id_to_atom(observable_type_id) when is_integer(observable_type_id) do
    Integer.to_string(observable_type_id) |> String.to_atom()
  end

  def observable_type_id_to_atom(observable_type_id) do
    Logger.error(
      "Bad observable type_id - cannot convert non-integer to atom: #{inspect(observable_type_id)}"
    )

    System.stop(1)
    -1
  end

  @spec find_parent(map(), String.t(), String.t()) :: {atom() | nil, map() | nil}
  def find_parent(items, extends, extension) do
    if extends do
      extends_key = String.to_atom(extends)
      parent_item = Map.get(items, extends_key)

      if parent_item do
        {extends_key, parent_item}
      else
        if extension do
          extension_extends_key = to_uid(extension, extends)
          extension_parent_item = Map.get(items, to_uid(extension, extends))

          if extension_parent_item do
            {extension_extends_key, extension_parent_item}
          else
            {extension_extends_key, nil}
          end
        else
          {extends_key, nil}
        end
      end
    else
      {nil, nil}
    end
  end
end
