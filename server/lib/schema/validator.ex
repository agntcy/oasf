# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Schema.Validator do
  @moduledoc """
  OASF Class validator.
  """

  require Logger

  alias Schema.Utils

  @class_uid "class_uid"

  @doc """
  Validates the given class using `class_uid` value and the schema.
  """
  @spec validate(map()) :: map()
  def validate(data) when is_map(data), do: data[@class_uid] |> validate_class(data)
  def validate(_data), do: %{:error => "Not a JSON object"}

  defp validate_class(nil, _data), do: %{:error => "Missing class_uid"}

  defp validate_class(class_uid, data) do
    profiles = get_in(data, ["metadata", "profiles"]) || []

    Logger.info("validate class: #{class_uid} using profiles: #{inspect(profiles)}")

    case Schema.find_class(class_uid) do
      nil ->
        class_uid = data[@class_uid]
        %{:error => "Invalid class_uid value", :value => class_uid}

      class ->
        if is_list(profiles) do
          validate_type(class, data, profiles)
        else
          %{:error => "Invalid profiles value", :value => profiles}
        end
    end
  end

  defp validate_type(type, data, profiles) when is_map(data) do
    attributes = type[:attributes] |> Utils.apply_profiles(profiles)

    Enum.reduce(attributes, %{}, fn {name, attribute}, acc ->
      value = data[Atom.to_string(name)]

      if attribute[:is_array] == true and value != nil and not is_list(value) do
        Map.put(acc, name, invalid_data_type(attribute, value, "array of " <> attribute[:type]))
      else
        validate_data(acc, name, attribute, value, profiles)
      end
    end)
    |> undefined_attributes(attributes, data)
  end

  defp validate_type(type, data, _profiles) do
    invalid_data_type(type, data, type.name)
  end

  defp undefined_attributes(acc, attributes, data) do
    Enum.reduce(data, acc, fn {key, value}, map ->
      case attributes[String.to_atom(key)] do
        nil ->
          Map.put(map, key, %{:error => "Undefined attribute name", :value => value})

        _attribute ->
          map
      end
    end)
  end

  defp validate_data(acc, name, attribute, value, _profiles) when is_binary(value) do
    case attribute[:type] do
      "string_t" ->
        case validate_enum_value(attribute[:enum], value) do
          :ok -> acc
          error -> Map.put(acc, name, error)
        end

      "json_t" ->
        acc

      _ ->
        validate_data_type(acc, name, attribute, value, "string_t")
    end
  end

  defp validate_data(acc, name, attribute, value, _profiles) when is_integer(value) do
    case attribute[:type] do
      "integer_t" ->
        case validate_enum(attribute[:enum], attribute, value) do
          :ok -> acc
          error -> Map.put(acc, name, error)
        end

      "json_t" ->
        acc

      _ ->
        validate_data_type(acc, name, attribute, value, ["integer_t", "long_t"])
    end
  end

  defp validate_data(acc, name, attribute, value, _profiles) when is_float(value) do
    validate_data_type(acc, name, attribute, value, "float_t")
  end

  defp validate_data(acc, name, attribute, value, _profiles) when is_boolean(value) do
    validate_data_type(acc, name, attribute, value, "boolean_t")
  end

  defp validate_data(acc, name, attribute, value, profiles) when is_map(value) do
    case attribute[:type] do
      "object_t" -> validate_object(acc, name, attribute, value, profiles)
      "json_t" -> acc
      type -> Map.put(acc, name, invalid_data_type(attribute, value, type))
    end
  end

  defp validate_data(acc, name, attribute, value, profiles) when is_list(value) do
    case attribute[:type] do
      "json_t" ->
        acc

      type ->
        if attribute[:is_array] do
          validate_array(acc, name, attribute, value, profiles)
        else
          Map.put(acc, name, invalid_data_type(attribute, value, type))
        end
    end
  end

  # checks for missing required attributes
  defp validate_data(acc, name, attribute, nil, _profiles) do
    case attribute[:requirement] do
      "required" ->
        Map.put(acc, name, %{
          :error => "Missing required attribute"
        })

      _ ->
        acc
    end
  end

  defp validate_data(acc, name, _attribute, value, _profiles) do
    Map.put(acc, name, %{
      :error => "Unhanded attribute",
      :value => value
    })
  end

  defp validate_array(acc, _name, _attribute, [], _profiles) do
    acc
  end

  defp validate_array(acc, name, attribute, value, profiles) do
    Logger.debug("validate array: #{name}")

    case attribute[:type] do
      "json_t" -> acc
      "object_t" -> validate_object_array(acc, name, attribute, value, profiles)
      _simple_type -> validate_simple_array(acc, name, attribute, value, profiles)
    end
  end

  defp validate_simple_array(acc, name, attribute, value, profiles) do
    {map, _count} =
      Enum.reduce(value, {Map.new(), 0}, fn data, {map, count} ->
        {validate_data(map, Integer.to_string(count), attribute, data, profiles), count + 1}
      end)

    if map_size(map) > 0 do
      error =
        if attribute[:enum] == nil do
          "The array contains invalid data: expected #{attribute[:type]} type"
        else
          "The array contains invalid enum values"
        end

      values = Enum.into(map, %{}, fn {key, data} -> {key, data.value} end)

      Map.put(acc, name, %{
        :error => error,
        :values => values
      })
    else
      acc
    end
  end

  defp validate_object_array(acc, name, attribute, value, profiles) do
    case attribute[:object_type] do
      "object" ->
        acc

      object_type ->
        object = Schema.object(object_type)

        {map, _count} =
          Enum.reduce(value, {Map.new(), 0}, fn data, {map, count} ->
            map = validate_type(object, data, profiles) |> add_count(map, count)

            {map, count + 1}
          end)

        if map_size(map) > 0 do
          Map.put(acc, name, %{
            :error => "The array contains invalid data",
            :values => map
          })
        else
          acc
        end
    end
  end

  defp add_count(result, map, count) do
    if map_size(result) > 0 do
      Map.put(map, "#{count}", result)
    else
      map
    end
  end

  defp validate_object(acc, name, attribute, value, profiles) do
    case attribute[:object_type] do
      "object" ->
        acc

      object_type ->
        Schema.object(object_type)
        |> validate_type(value, profiles)
        |> valid?(acc, name)
    end
  end

  defp valid?(map, acc, name) do
    if map_size(map) > 0 do
      Map.put(acc, name, map)
    else
      acc
    end
  end

  # check the attribute value type
  defp validate_data_type(acc, name, attribute, value, value_type) do
    case attribute[:type] do
      "json_t" ->
        acc

      ^value_type ->
        acc

      type ->
        if Schema.data_type?(type, value_type) do
          acc
        else
          Map.put(acc, name, invalid_data_type(attribute, value, type))
        end
    end
  end

  defp invalid_data_type(_attribute, value, type) do
    %{
      :error => "Invalid data type: expected '#{type}' type",
      :value => value
    }
  end

  # Validate an integer enum value
  defp validate_enum(nil, _attribute, _value), do: :ok

  defp validate_enum(enum, _attribute, value) do
    validate_enum_value(enum, Integer.to_string(value))
  end

  defp validate_enum_value(nil, _value), do: :ok

  defp validate_enum_value(enum, value) do
    if Map.has_key?(enum, String.to_atom(value)) do
      :ok
    else
      %{
        :error => "Invalid enum value",
        :value => value
      }
    end
  end
end
