# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Helper do
  @moduledoc """
  Provides helper functions to enrich the class data.
  """
  require Logger

  def enrich(data, enum_text, observables) when is_map(data) do
    Logger.debug(fn ->
      "enrich class: #{inspect(data)}, enum_text: #{enum_text}, observables: #{observables}"
    end)

    enrich_class(data["class_uid"], data, enum_text, observables)
  end

  # this is not a class
  def enrich(data, _enum_text, _observables), do: %{:error => "Not a JSON object", :data => data}

  # missing class_uid
  defp enrich_class(nil, data, _enum_text, _observables),
    do: %{:error => "Missing class_uid", :data => data}

  defp enrich_class(class_uid, data, enum_text, _observables) do
    Logger.debug("enrich class: #{class_uid}")

    # if observables == "true", do:

    case Schema.find_class_by_uid(class_uid) do
      # invalid class ID
      nil ->
        %{:error => "Invalid class_uid: #{class_uid}", :data => data}

      class ->
        data = type_uid(class_uid, data)

        if enum_text == "true" do
          enrich_type(class, data)
        else
          data
        end
    end
  end

  defp enrich_type(type, data) do
    attributes = type[:attributes]

    Enum.reduce(data, %{}, fn {name, value}, acc ->
      key = to_atom(name)

      case attributes[key] do
        # Attribute name is not defined in the schema
        nil ->
          Map.put(acc, name, value)

        attribute ->
          {name, text} = enrich_attribute(attribute[:type], name, attribute, value)

          if Map.has_key?(attribute, :enum) do
            Logger.debug("enrich enum: #{name} = #{text}")

            case attribute[:sibling] do
              nil ->
                Map.put_new(acc, name, value)

              sibling ->
                Map.put_new(acc, name, value) |> Map.put_new(sibling, text)
            end
          else
            Map.put(acc, name, text)
          end
      end
    end)
  end

  defp type_uid(class_uid, data) do
    case data["activity_id"] do
      nil ->
        data

      activity_id ->
        uid =
          if activity_id >= 0 do
            Schema.Types.type_uid(class_uid, activity_id)
          else
            0
          end

        Map.put(data, "type_uid", uid)
    end
  end

  defp to_atom(key) when is_atom(key), do: key
  defp to_atom(key), do: String.to_atom(key)

  defp enrich_attribute("integer_t", name, attribute, value) do
    enrich_integer(attribute[:enum], name, value)
  end

  defp enrich_attribute("object_t", name, attribute, value) when is_map(value) do
    {name, enrich_type(Schema.object(attribute[:object_type]), value)}
  end

  defp enrich_attribute("object_t", name, attribute, value) when is_list(value) do
    data =
      if attribute[:is_array] and is_map(List.first(value)) do
        obj_type = Schema.object(attribute[:object_type])

        Enum.map(value, fn data ->
          enrich_type(obj_type, data)
        end)
      else
        value
      end

    {name, data}
  end

  defp enrich_attribute(_, name, _attribute, value) do
    {name, value}
  end

  # Integer value
  defp enrich_integer(nil, name, value) do
    {name, value}
  end

  # Single enum value
  defp enrich_integer(enum, name, value) when is_integer(value) do
    key = Integer.to_string(value) |> String.to_atom()

    {name, caption(enum[key], value)}
  end

  # Array of enum values
  defp enrich_integer(enum, name, values) when is_list(values) do
    list =
      Enum.map(values, fn n ->
        key = Integer.to_string(n) |> String.to_atom()
        caption(enum[key], key)
      end)

    {name, list}
  end

  # Non-integer value
  defp enrich_integer(_, name, value),
    do: {name, value}

  defp caption(nil, value), do: value
  defp caption(map, _value), do: map[:caption]
end
