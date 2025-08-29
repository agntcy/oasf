# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Utils do
  @moduledoc """
  Defines map helper functions.
  """
  @type link_t() :: %{
          :group => :skill | :domain | :feature | :object,
          :type => String.t(),
          :caption => String.t(),
          optional(:deprecated?) => boolean(),
          optional(:attribute_keys) => nil | MapSet.t(String.t())
        }

  @type version_t() :: %{
          :major => integer(),
          :minor => integer(),
          :patch => integer(),
          optional(:prerelease) => nil | String.t()
        }

  @type version_error_t() :: {:error, String.t(), any()}

  @type version_or_error_t() :: version_t() | version_error_t()

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

  @spec update_dictionary(map, map, map, map, map) :: map
  def update_dictionary(dictionary, skills, domains, features, objects) do
    dictionary
    |> link_classes(:skill, skills)
    |> link_classes(:domain, domains)
    |> link_classes(:feature, features)
    |> link_objects(objects)
    |> update_data_types(objects)
    |> define_datetime_attributes()
  end

  @spec update_classes(map(), map()) :: map()
  def update_classes(classes, all_classes) do
    Enum.into(classes, %{}, fn {name, class} ->
      children =
        find_children(all_classes, Atom.to_string(name))
        |> Enum.map(fn child ->
          case Map.get(classes, String.to_atom(child[:name])) do
            nil ->
              nil

            child_class ->
              child_class
              |> Map.put(:class_name, child_class[:caption])
              |> Map.put(:type, Atom.to_string(:class_t))
              |> Map.put(:class_type, child_class[:name])
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.into(%{}, fn child ->
          {child.name, child}
        end)

      class
      |> Map.put(:_children, children)
      |> (&{name, &1}).()
    end)
  end

  @spec update_objects(map(), map(), map()) :: map()
  def update_objects(objects, all_objects, dictionary) do
    Enum.into(objects, %{}, fn {name, object} ->
      links = object_links(dictionary, Atom.to_string(name))

      children =
        find_children(all_objects, Atom.to_string(name))
        |> Enum.map(fn child ->
          case Map.get(objects, String.to_atom(child[:name])) do
            nil ->
              nil

            child_class ->
              child_class
              |> Map.put(:object_name, child_class[:caption])
              |> Map.put(:type, Atom.to_string(:object_t))
              |> Map.put(:object_type, child_class[:name])
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.into(%{}, fn child ->
          {child.name, child}
        end)

      object
      |> Map.put(:_links, links)
      |> Map.put(:_children, children)
      |> (&{name, &1}).()
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

  defp link_classes(dictionary, family, classes) do
    Enum.reduce(classes, dictionary, fn class, acc ->
      add_class_links(acc, class, family)
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
    Enum.into(attributes, %{}, fn {attribute_key, attribute} ->
      attribute_update =
        if attribute[:type] == "object_t" do
          update_object_type(attribute_key, attribute, objects)
        else
          update_data_type(attribute_key, attribute, types)
        end

      {attribute_key, attribute_update}
    end)
  end

  defp update_object_type(attribute_key, attribute, objects) do
    object_key = attribute[:object_type]

    case find_entity(objects, attribute, object_key) do
      {object_key, nil} ->
        Logger.error("Undefined object type: #{object_key}, for #{attribute_key}")
        Map.put(attribute, :object_name, "_undefined_")

      {object_key, object} ->
        attribute
        |> Map.put(:object_name, object[:caption])
        |> Map.put(:object_type, Atom.to_string(object_key))
    end
  end

  defp update_data_type(attribute_key, attribute, types) do
    type =
      case attribute[:type] do
        nil ->
          Logger.error("Missing data type for: #{attribute_key}, will use string_t type")
          "string_t"

        t ->
          t
      end

    case types[String.to_atom(type)] do
      nil ->
        Logger.error("Undefined data type: #{attribute_key}: #{type}")
        attribute

      type ->
        Map.put(attribute, :type_name, type[:caption])
    end
  end

  @spec make_link(:skill | :domain | :feature | :object, atom() | String.t(), map()) :: link_t()
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

  defp add_class_links(dictionary, {class_key, class}, family) do
    Map.update!(dictionary, :attributes, fn dictionary_attributes ->
      link = make_link(family, class_key, class)

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
        # If the reference is different, use that as item_attribute_key
        item_attribute_key =
          if Map.has_key?(item_attribute, :reference) do
            item_attribute[:reference]
          else
            item_attribute_key
          end

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
                      deep_merge(item_attribute, dictionary_attribute)
                      |> update_links_fn.(link)
                  end

                Map.put(dictionary_attributes, ext_key, data)

              _ ->
                Logger.error(
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

  @spec find_children(map(), String.t()) :: [map()]
  def find_children(map, parent_name) do
    map
    |> Enum.filter(fn {_key, elem} ->
      Map.has_key?(elem, :extends) && elem[:extends] == parent_name
    end)
    |> Enum.map(fn {_key, elem} -> elem end)
    |> Enum.flat_map(fn elem ->
      [elem | find_children(map, elem[:name])]
    end)
  end

  @spec add_sibling_of_to_attributes(list() | map() | nil) :: list() | nil
  def add_sibling_of_to_attributes(nil), do: nil

  def add_sibling_of_to_attributes(attributes) when is_list(attributes) do
    _add_sibling_of_to_attributes(attributes)
  end

  def add_sibling_of_to_attributes(attributes) when is_map(attributes) do
    attributes
    |> _add_sibling_of_to_attributes()
    |> Enum.into(%{})
  end

  defp _add_sibling_of_to_attributes(attributes) do
    # Enum attributes point to their enum sibling through the :sibling attribute,
    # however the siblings do _not_ refer back to the related enum attribute, so let's build that.
    sibling_of_map =
      Enum.reduce(attributes, %{}, fn {attribute_key, attribute}, acc ->
        if Map.has_key?(attribute, :sibling) do
          Map.put(acc, String.to_atom(attribute[:sibling]), attribute_key)
        else
          acc
        end
      end)

    Enum.map(attributes, fn {attribute_key, attribute} ->
      attribute =
        case sibling_of_map[attribute_key] do
          nil ->
            attribute

          enum_attribute_key ->
            Map.put(attribute, :_sibling_of, enum_attribute_key)
        end

      {attribute_key, attribute}
    end)
  end

  @version_regex ~r/^(?<major>0|[1-9]\d*)\.(?<minor>0|[1-9]\d*)\.(?<patch>0|[1-9]\d*)(?:-(?<prerelease>.+))?$/

  @spec version_regex_source() :: String.t()
  def version_regex_source(), do: @version_regex.source

  @spec parse_version(any()) :: version_or_error_t()
  def parse_version(s) when is_binary(s) do
    captured = Regex.named_captures(@version_regex, s)

    if captured do
      major = parse_integer(captured["major"])
      minor = parse_integer(captured["minor"])
      patch = parse_integer(captured["patch"])
      prerelease = captured["prerelease"]

      if major && minor && patch do
        if prerelease && prerelease != "" do
          %{major: major, minor: minor, patch: patch, prerelease: prerelease}
        else
          %{major: major, minor: minor, patch: patch}
        end
      else
        # This should never happen due to regex, but here to be defensive
        {:error, "non-integral", s}
      end
    else
      {:error, "malformed", s}
    end
  end

  def parse_version(v) do
    {:error, "not a string", v}
  end

  defp parse_integer(s) do
    case Integer.parse(s) do
      {number, ""} -> number
      _ -> nil
    end
  end

  @spec version_is_initial_development?(version_or_error_t()) :: boolean()
  def version_is_initial_development?(v) when is_map(v) do
    v[:major] == 0
  end

  def version_is_initial_development?(v) when is_tuple(v), do: false

  @spec version_is_prerelease?(version_or_error_t()) :: boolean()
  def version_is_prerelease?(v) when is_map(v) do
    prerelease = v[:prerelease]
    is_binary(prerelease) and prerelease != ""
  end

  def version_is_prerelease?(v) when is_tuple(v), do: false

  @spec version_sorter(version_or_error_t(), version_or_error_t()) :: boolean()
  def version_sorter(v1, v2) when is_map(v1) and is_map(v2) do
    cond do
      v1 == v2 ->
        true

      v1[:major] < v2[:major] ->
        true

      v1[:major] == v2[:major] and v1[:minor] < v2[:minor] ->
        true

      v1[:major] == v2[:major] and v1[:minor] == v2[:minor] and v1[:patch] < v2[:patch] ->
        true

      v1[:major] == v2[:major] and v1[:minor] == v2[:minor] and v1[:patch] == v2[:patch] ->
        cond do
          Map.has_key?(v1, :prerelease) and Map.has_key?(v2, :prerelease) ->
            v1[:prerelease] <= v2[:prerelease]

          Map.has_key?(v1, :prerelease) and not Map.has_key?(v2, :prerelease) ->
            true

          not Map.has_key?(v1, :prerelease) and Map.has_key?(v2, :prerelease) ->
            false

          # Covered by v1 == v2:
          #   not Map.has_key?(v1, :prerelease) and not Map.has_key?(v2, :prerelease)

          true ->
            true
        end

      true ->
        false
    end
  end

  def version_sorter(v1, v2) do
    case {v1, v2} do
      {{:error, _, original1}, {:error, _, original2}} ->
        original1 <= original2

      {{:error, _, _}, _} ->
        true

      {_, {:error, _, _}} ->
        false

      _ ->
        false
    end
  end
end
