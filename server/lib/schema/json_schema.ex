# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.JsonSchema do
  @moduledoc """
  Json schema generator. This module defines functions that generate JSON schema (see http://json-schema.org) schemas for OASF schema.
  """

  alias Schema.Utils
  alias Schema.Types

  @schema_base_uri "https://schema.oasf.agntcy.org/schema"
  @schema_version "http://json-schema.org/draft-07/schema#"

  @doc """
  Generates a JSON schema corresponding to the `type` parameter.
  The `type` can be either a class or an object defintion.

  Options: :package_name | :schema_version
  """
  @spec encode(map(), nil | Keyword.t()) :: map()
  def encode(type, options) when is_map(type) do
    Process.put(:options, options || [])

    try do
      encode_entity(type, true)
    after
      Process.delete(:options)
    end
  end

  @spec encode_entity(map(), boolean) :: map()
  def encode_entity(type, top_level) do
    name = type[:name]
    ext = type[:extension]

    {properties, required} = map_reduce(name, type[:attributes])

    schema = Map.new()

    schema =
      if Map.has_key?(type, :_links) do
        add_java_class(schema, name)
      else
        schema
      end

    schema =
      if top_level do
        schema
        |> Map.put("$schema", @schema_version)
        |> Map.put("$id", make_id_ref(name, type[:family], ext))
      else
        schema
      end

    schema =
      schema
      |> Map.put("title", type[:caption])
      |> Map.put("type", "object")
      |> Map.put("properties", properties)
      |> Map.put("additionalProperties", false)
      |> put_required(required)
      |> encode_entities(type[:entities])
      |> empty_object(properties)

    if top_level do
      flatten_defs(schema)
    else
      schema
    end
  end

  defp add_java_class(obj, name) do
    case Process.get(:options) do
      nil ->
        obj

      options ->
        add_java_class(obj, name, Keyword.get(options, :package_name))
    end
  end

  defp add_java_class(obj, _name, nil) do
    obj
  end

  defp add_java_class(obj, name, package) do
    Map.put(obj, "javaType", make_java_name(package, name))
  end

  defp make_java_name(package, name) do
    name = String.split(name, "_") |> Enum.map_join(fn name -> String.capitalize(name) end)
    "#{package}.#{name}"
  end

  defp make_class_ref(family, name) do
    Path.join([ref_entity(), "#{family}s", String.replace(name, "/", "_")])
  end

  defp make_object_ref(name) do
    Path.join([ref_entity(), "objects", String.replace(name, "/", "_")])
  end

  defp ref_entity() do
    "#/$defs"
  end

  defp make_id_ref(name, nil, nil) do
    Path.join([@schema_base_uri, "objects", name])
  end

  defp make_id_ref(name, nil, ext) do
    Path.join([@schema_base_uri, "objects", ext, name])
  end

  defp make_id_ref(name, family, nil) do
    Path.join([@schema_base_uri, family <> "s", name])
  end

  defp make_id_ref(name, family, ext) do
    Path.join([@schema_base_uri, family <> "s", ext, name])
  end

  defp empty_object(map, properties) do
    if map_size(properties) == 0 do
      Map.put(map, "additionalProperties", true)
    else
      map
    end
  end

  defp put_required(map, []) do
    map
  end

  defp put_required(map, required) do
    Map.put(map, "required", Enum.sort(required))
  end

  defp encode_entities(schema, nil) do
    schema
  end

  defp encode_entities(schema, []) do
    schema
  end

  defp encode_entities(schema, entities) do
    {skills, domains, features, objects} =
      Enum.reduce(entities, {%{}, %{}, %{}, %{}}, fn {name, entity},
                                                     {skills, domains, features, objects} ->
        if entity[:is_enum] do
          Enum.reduce(entity[:_children], {skills, domains, features, objects}, fn {child_name,
                                                                                    item},
                                                                                   {skills,
                                                                                    domains,
                                                                                    features,
                                                                                    objects} ->
            key = String.replace(child_name, "/", "_")
            value = encode_entity(item, false)

            case item[:family] do
              "skill" -> {Map.put(skills, key, value), domains, features, objects}
              "domain" -> {skills, Map.put(domains, key, value), features, objects}
              "feature" -> {skills, domains, Map.put(features, key, value), objects}
              _ -> {skills, domains, features, Map.put(objects, key, value)}
            end
          end)
        else
          key = Atom.to_string(name) |> String.replace("/", "_")
          value = encode_entity(entity, false)

          case entity[:family] do
            "skill" -> {Map.put(skills, key, value), domains, features, objects}
            "domain" -> {skills, Map.put(domains, key, value), features, objects}
            "feature" -> {skills, domains, Map.put(features, key, value), objects}
            _ -> {skills, domains, features, Map.put(objects, key, value)}
          end
        end
      end)

    defs =
      %{}
      |> (fn m -> if map_size(skills) > 0, do: Map.put(m, "skills", skills), else: m end).()
      |> (fn m -> if map_size(domains) > 0, do: Map.put(m, "domains", domains), else: m end).()
      |> (fn m -> if map_size(features) > 0, do: Map.put(m, "features", features), else: m end).()
      |> (fn m -> if map_size(objects) > 0, do: Map.put(m, "objects", objects), else: m end).()

    Map.put(schema, "$defs", defs)
  end

  defp map_reduce(type_name, attributes) do
    {properties, required} =
      Enum.map_reduce(attributes, [], fn {key, attribute}, acc ->
        name = Atom.to_string(key)

        acc =
          case attribute[:requirement] do
            "required" -> [name | acc]
            _ -> acc
          end

        schema =
          encode_attribute(type_name, attribute[:type], attribute)
          |> encode_array(attribute[:is_array])

        {{name, schema}, acc}
      end)

    {Map.new(properties), required}
  end

  defp encode_attribute(_name, "string_map_t", attr) do
    new_schema(attr)
    |> Map.put("type", "object")
    |> Map.put("additionalProperties", %{"type" => "string"})
  end

  defp encode_attribute(_name, "integer_t", attr) do
    new_schema(attr) |> encode_integer(attr)
  end

  defp encode_attribute(_name, "string_t", attr) do
    new_schema(attr) |> encode_string(attr)
  end

  defp encode_attribute(name, "object_t", attr) do
    new_schema(attr) |> encode_object(name, attr)
  end

  defp encode_attribute(name, "class_t", attr) do
    new_schema(attr) |> encode_class(name, attr)
  end

  defp encode_attribute(_name, "json_t", attr) do
    new_schema(attr)
  end

  defp encode_attribute(_name, type, attr) do
    new_schema(attr) |> Map.put("type", encode_type(type))
  end

  defp new_schema(attr), do: %{"title" => attr[:caption]}

  defp encode_type(type) do
    cond do
      Schema.data_type?(type, "string_t") -> "string"
      Schema.data_type?(type, "integer_t") -> "integer"
      Schema.data_type?(type, "long_t") -> "integer"
      Schema.data_type?(type, "float_t") -> "number"
      Schema.data_type?(type, "boolean_t") -> "boolean"
      true -> type
    end
  end

  defp encode_object(schema, _name, attr) do
    type = attr[:object_type]

    if attr[:is_enum] do
      children_objects = Utils.find_children(Schema.objects(), type)

      refs =
        Enum.map(children_objects, fn item -> %{"$ref" => make_object_ref(item[:name])} end)

      Map.put(schema, "oneOf", refs)
    else
      Map.put(schema, "$ref", make_object_ref(type))
    end
  end

  defp encode_class(schema, _name, attr) do
    type = attr[:class_type]
    family = attr[:family]

    if attr[:is_enum] do
      all_classes_fn =
        case family do
          "skill" -> Schema.all_skills()
          "domain" -> Schema.all_domains()
          "feature" -> Schema.all_features()
          _ -> schema
        end

      children_classes = Utils.find_children(all_classes_fn, type)

      refs =
        if family == "feature" do
          feature_names =
            Enum.map(children_classes, fn item ->
              Types.long_class_name(family, item[:name])
            end)

          Enum.map(children_classes, fn item ->
            %{"$ref" => make_class_ref(family, item[:name])}
          end) ++
            [
              %{
                "type" => "object",
                "properties" => %{
                  "name" => %{"type" => "string"}
                },
                "not" => %{
                  "properties" => %{
                    "name" => %{"enum" => feature_names}
                  }
                }
              }
            ]
        else
          Enum.map(children_classes, fn item ->
            %{"$ref" => make_class_ref(family, item[:name])}
          end)
        end

      Map.put(schema, "oneOf", refs)
    else
      Map.put(schema, "$ref", make_class_ref(family, type))
    end
  end

  defp encode_integer(schema, attr) do
    encode_enum(schema, attr, "integer", fn name ->
      Atom.to_string(name) |> String.to_integer()
    end)
  end

  defp encode_string(schema, attr) do
    encode_enum(schema, attr, "string", &Atom.to_string/1)
  end

  defp encode_enum(schema, attr, type, encoder) do
    case attr[:enum] do
      nil ->
        schema

      enum ->
        case encode_enum_values(enum, encoder) do
          [uid] ->
            Map.put(schema, "const", uid)

          values ->
            Map.put(schema, "enum", values)
        end
    end
    |> Map.put("type", type)
  end

  defp encode_enum_values(enum, encoder) do
    Enum.map(enum, fn {name, _} ->
      encoder.(name)
    end)
  end

  defp encode_array(schema, true) do
    {type, schema} = items_type(schema)

    Map.put(schema, "type", "array") |> Map.put("items", type)
  end

  defp encode_array(schema, _is_array) do
    schema
  end

  defp items_type(schema) do
    case Map.get(schema, "type") do
      nil ->
        cond do
          Map.has_key?(schema, "$ref") ->
            {ref, updated} = Map.pop(schema, "$ref")
            {%{"$ref" => ref}, updated}

          Map.has_key?(schema, "oneOf") ->
            {one_of, updated} = Map.pop(schema, "oneOf")
            {%{"oneOf" => one_of}, updated}

          true ->
            {schema, schema}
        end

      type ->
        case Map.pop(schema, "enum") do
          {nil, updated} ->
            {%{"type" => type}, updated}

          {enum, updated} ->
            {%{"type" => type, "enum" => enum}, updated}
        end
    end
  end

  defp flatten_defs(schema) do
    {schema, defs} =
      do_flatten_defs(schema, %{
        "skills" => %{},
        "domains" => %{},
        "features" => %{},
        "objects" => %{}
      })

    # Remove empty maps from $defs
    defs =
      defs
      |> Enum.filter(fn {_k, v} -> map_size(v) > 0 end)
      |> Enum.into(%{})

    Map.put(schema, "$defs", defs)
  end

  defp do_flatten_defs(%{"$defs" => nested_defs} = schema, acc) do
    # Remove $defs from current schema
    schema = Map.delete(schema, "$defs")
    # Recursively flatten all values in nested $defs
    acc =
      Enum.reduce(nested_defs, acc, fn {group, group_map}, acc1 ->
        Enum.reduce(group_map, acc1, fn {k, v}, acc2 ->
          {v_flat, acc3} = do_flatten_defs(v, acc2)
          Map.update(acc3, group, %{k => v_flat}, &Map.put(&1, k, v_flat))
        end)
      end)

    # Continue flattening the rest of the schema
    Enum.reduce(schema, {schema, acc}, fn {k, v}, {s_acc, d_acc} ->
      if is_map(v) do
        {v_flat, d_acc2} = do_flatten_defs(v, d_acc)
        {Map.put(s_acc, k, v_flat), d_acc2}
      else
        {Map.put(s_acc, k, v), d_acc}
      end
    end)
  end

  defp do_flatten_defs(%{} = schema, acc) do
    Enum.reduce(schema, {schema, acc}, fn {k, v}, {s_acc, d_acc} ->
      if is_map(v) do
        {v_flat, d_acc2} = do_flatten_defs(v, d_acc)
        {Map.put(s_acc, k, v_flat), d_acc2}
      else
        {Map.put(s_acc, k, v), d_acc}
      end
    end)
  end

  defp do_flatten_defs(other, acc), do: {other, acc}
end
