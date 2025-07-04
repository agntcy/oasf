# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.JsonSchema do
  @moduledoc """
  Json schema generator. This module defines functions that generate JSON schema (see http://json-schema.org) schemas for OASF schema.
  """
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

  def encode_entity(type, top_level) do
    name = type[:name]

    {properties, required} = map_reduce(name, type[:attributes])

    ext = type[:extension]

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

    schema
    |> Map.put("title", type[:caption])
    |> Map.put("type", "object")
    |> Map.put("properties", properties)
    |> Map.put("additionalProperties", false)
    |> put_required(required)
    |> encode_entities(type[:entities])
    |> empty_object(properties)
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

  defp make_object_ref(name) do
    Path.join([ref_object(), String.replace(name, "/", "_")])
  end

  defp ref_object() do
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
    defs =
      Enum.into(entities, %{}, fn {name, entity} ->
        key = Atom.to_string(name) |> String.replace("/", "_")
        {key, encode_entity(entity, false)}
      end)

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
    Map.put(schema, "$ref", make_object_ref(type))
  end

  defp encode_class(schema, _name, attr) do
    type = attr[:class_type]
    Map.put(schema, "$ref", make_object_ref(type))
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
        {ref, updated} = Map.pop(schema, "$ref")
        {%{"$ref" => ref}, updated}

      type ->
        case Map.pop(schema, "enum") do
          {nil, updated} ->
            {%{"type" => type}, updated}

          {enum, updated} ->
            {%{"type" => type, "enum" => enum}, updated}
        end
    end
  end
end
