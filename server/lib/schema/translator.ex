# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Translator do
  @moduledoc """
  Translates inputs to more user friendly form.
  """
  require Logger

  def translate(data, options, type) when is_map(data) do
    Logger.debug(
      "translate input: #{inspect(data)}, options: #{inspect(options)}, type: #{type}}"
    )

    translate_entity(data, options, type)
  end

  # this is not a valid input
  def translate(data, _options, _type), do: data

  defp translate_entity(data, options, type) do
    entity_def =
      case type do
        :skill ->
          case Map.get(data, "id") do
            nil ->
              if name = Map.get(data, "name") do
                Logger.debug("translate skill class: #{name}")
                Schema.skill(Schema.Utils.descope(name))
              end

            class_uid ->
              Logger.debug("translate skill class: #{class_uid}")
              Schema.find_skill(class_uid)
          end

        :domain ->
          case Map.get(data, "id") do
            nil ->
              if name = Map.get(data, "name") do
                Logger.debug("translate domain class: #{name}")
                Schema.domain(Schema.Utils.descope(name))
              end

            class_uid ->
              Logger.debug("translate domain class: #{class_uid}")
              Schema.find_domain(class_uid)
          end

        :module ->
          case Map.get(data, "id") do
            nil ->
              if name = Map.get(data, "name") do
                Logger.debug("translate module class: #{name}")
                Schema.module(Schema.Utils.descope(name))
              end

            class_uid ->
              Logger.debug("translate module class: #{class_uid}")
              Schema.find_module(class_uid)
          end

        :object ->
          if object_name = Keyword.get(options, :name) do
            Logger.debug("translate object: #{object_name}")
            Schema.object(object_name)
          end

        _ ->
          nil
      end

    if entity_def == nil do
      data
    else
      # Enrich input data before translation if enrich option is enabled
      enriched_data =
        if Keyword.get(options, :enrich, false) do
          enrich_input_data(data, entity_def, type)
        else
          data
        end

      translate_input(entity_def, enriched_data, options)
    end
  end

  # unknown input class, thus cannot translate the input
  defp translate_input(nil, data, _options), do: data

  defp translate_input(type, data, options) do
    attributes = type[:attributes]

    Enum.reduce(data, %{}, fn {name, value}, acc ->
      Logger.debug("translate attribute: #{name} = #{inspect(value)}")

      key = to_atom(name)

      case attributes[key] do
        nil ->
          # Attribute name is not defined in the schema
          Map.put(acc, name, value)

        attribute ->
          {name, text} = translate_attribute(attribute[:type], name, attribute, value, options)

          verbose = Keyword.get(options, :verbose)

          if Map.has_key?(attribute, :enum) and (verbose == 1 or verbose == 2) do
            Logger.debug("translated enum: #{name} = #{text}")

            case sibling(attribute[:sibling], attributes, options, verbose) do
              nil ->
                Map.put_new(acc, name, value)

              sibling ->
                Logger.debug("translated name: #{sibling}")

                Map.put_new(acc, name, value) |> Map.put_new(sibling, text)
            end
          else
            Map.put(acc, name, text)
          end
      end
    end)
  end

  defp sibling(nil, _attributes, _options, _verbose) do
    nil
  end

  defp sibling(name, _attributes, _options, 1) do
    name
  end

  defp sibling(name, attributes, options, _verbose) do
    case attributes[String.to_atom(name)] do
      nil -> nil
      attr -> attr[:caption] |> to_text(options)
    end
  end

  defp to_atom(key) when is_atom(key), do: key
  defp to_atom(key), do: String.to_atom(key)

  defp translate_attribute("integer_t", name, attribute, value, options) do
    translate_integer(attribute[:enum], name, attribute, value, options)
  end

  defp translate_attribute("object_t", name, attribute, value, options) when is_map(value) do
    translated = translate_input(Schema.object(attribute[:object_type]), value, options)
    translate_attribute(name, attribute, translated, options)
  end

  defp translate_attribute("object_t", name, attribute, value, options) when is_list(value) do
    translated =
      if attribute[:is_array] and is_map(List.first(value)) do
        obj_type = Schema.object(attribute[:object_type])

        Enum.map(value, fn data ->
          translate_input(obj_type, data, options)
        end)
      else
        value
      end

    translate_attribute(name, attribute, translated, options)
  end

  defp translate_attribute("class_t", name, attribute, value, options) when is_map(value) do
    translated = translate_entity(value, options, String.to_atom(attribute[:family]))
    translate_attribute(name, attribute, translated, options)
  end

  defp translate_attribute("class_t", name, attribute, value, options) when is_list(value) do
    translated =
      if attribute[:is_array] and is_map(List.first(value)) do
        Enum.map(value, fn data ->
          translate_entity(data, options, String.to_atom(attribute[:family]))
        end)
      else
        value
      end

    translate_attribute(name, attribute, translated, options)
  end

  defp translate_attribute(_, name, attribute, value, options),
    do: translate_attribute(name, attribute, value, options)

  # Translate an integer value
  defp translate_integer(nil, name, attribute, value, options),
    do: translate_attribute(name, attribute, value, options)

  # Translate a single enum value
  defp translate_integer(enum, name, attribute, value, options) when is_integer(value) do
    item = Integer.to_string(value) |> String.to_atom()

    translated =
      case enum[item] do
        nil -> value
        map -> map[:caption]
      end

    translate_enum(name, attribute, value, translated, options)
  end

  # Translate an array of enum values
  defp translate_integer(enum, name, attribute, value, options) when is_list(value) do
    Logger.debug("translate_integer: #{name}")

    translated =
      Enum.map(value, fn n ->
        item = Integer.to_string(n) |> String.to_atom()

        case enum[item] do
          nil -> n
          map -> map[:caption]
        end
      end)

    translate_enum(name, attribute, value, translated, options)
  end

  # Translate a non-integer value
  defp translate_integer(_, name, attribute, value, options),
    do: translate_attribute(name, attribute, value, options)

  defp translate_attribute(name, attribute, value, options) do
    case Keyword.get(options, :verbose) do
      2 ->
        {to_text(attribute[:caption], options), value}

      3 ->
        {name,
         %{
           "name" => to_text(attribute[:caption], options),
           "type" => attribute[:object_type] || attribute[:type],
           "value" => value
         }}

      _ ->
        {name, value}
    end
  end

  defp translate_enum(name, attribute, value, translated, options) do
    Logger.debug("translate  enum: #{name} = #{value}")

    case Keyword.get(options, :verbose) do
      1 ->
        {name, translated}

      2 ->
        {to_text(attribute[:caption], options), translated}

      3 ->
        {name,
         %{
           "name" => to_text(attribute[:caption], options),
           "type" => attribute[:object_type] || attribute[:type],
           "value" => value,
           "caption" => translated
         }}

      _ ->
        {name, value}
    end
  end

  defp to_text(name, options) do
    case Keyword.get(options, :spaces) do
      nil -> name
      ch -> String.replace(name, " ", ch)
    end
  end

  # Enrich class result with both id and name
  # Enrich input data by adding missing id or name BEFORE translation
  defp enrich_input_data(data, class_def, type) when is_map(data) and class_def != nil do
    data
    |> enrich_input_id(class_def, type)
    |> enrich_input_name(class_def, type)
  end

  defp enrich_input_data(data, _class_def, _type), do: data

  # Add id to input if missing
  defp enrich_input_id(data, class_def, _type) when is_map(data) do
    if Map.has_key?(class_def, :uid) and not Map.has_key?(data, "id") do
      Map.put(data, "id", class_def[:uid])
    else
      data
    end
  end

  defp enrich_input_id(data, _class_def, _type), do: data

  # Add name to input if missing
  defp enrich_input_name(data, class_def, type) when is_map(data) do
    if Map.has_key?(class_def, :name) and not Map.has_key?(data, "name") do
      # Get the full class name with hierarchy
      class_name = get_class_name(class_def, type)
      Map.put(data, "name", class_name)
    else
      data
    end
  end

  defp enrich_input_name(data, _class_def, _type), do: data

  # Get the full class name from class definition with hierarchy
  defp get_class_name(class_def, type) do
    case class_def[:name] do
      nil ->
        nil

      name ->
        # Get all classes based on the type
        all_classes = get_all_classes_for_type(type)

        if all_classes != nil do
          Schema.Utils.class_name_with_hierarchy(name, all_classes)
        else
          # Fallback to simple name conversion
          if is_atom(name), do: Atom.to_string(name), else: name
        end
    end
  end

  # Get all classes map based on type
  defp get_all_classes_for_type(:skill), do: Schema.all_skills()
  defp get_all_classes_for_type(:domain), do: Schema.all_domains()
  defp get_all_classes_for_type(:module), do: Schema.all_modules()
  defp get_all_classes_for_type(_), do: nil
end
