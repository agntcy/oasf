# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Schema.Translator do
  @moduledoc """
  Translates classes to more user friendly form.
  """
  require Logger

  def translate(data, options) when is_map(data) do
    Logger.debug("translate class: #{inspect(data)}, options: #{inspect(options)}")

    translate_class(data["class_uid"], data, options)
  end

  # this is not an class
  def translate(data, _options), do: data

  # missing class_uid, thus cannot translate the class
  defp translate_class(nil, data, _options), do: data

  defp translate_class(class_uid, data, options) do
    Logger.debug("translate class: #{class_uid}")

    type = Schema.find_class_by_uid(class_uid)
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
    translated = translate_class(Schema.object(attribute[:object_type]), value, options)
    translate_attribute(name, attribute, translated, options)
  end

  defp translate_attribute("object_t", name, attribute, value, options) when is_list(value) do
    translated =
      if attribute[:is_array] and is_map(List.first(value)) do
        obj_type = Schema.object(attribute[:object_type])

        Enum.map(value, fn data ->
          translate_class(obj_type, data, options)
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
end
