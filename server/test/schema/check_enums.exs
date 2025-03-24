# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.CheckEnums do
  def classes() do
    Enum.each(Schema.classes(), fn {name, _class} ->
      each(Schema.class(name)) |> print(name)
    end)
  end

  def objects() do
    Enum.each(Schema.objects(), fn {name, obj} ->
      each(obj) |> print(name)
    end)
  end

  defp print([], _name) do
    :ok
  end

  defp print(list, name) do
    text = Enum.join(list, ", ")
    IO.puts(name)
    IO.puts("   #{text}")
  end

  defp each(map) do
    Map.get(map, :attributes) |> Map.new() |> check()
  end

  defp check(attributes) do
    Enum.reduce(attributes, [], fn {name, attribute}, acc ->
      if is_enum?(attribute) do
        check_enum(attributes, name, attribute, acc)
      else
        acc
      end
    end)
  end

  defp is_enum?(attribute) do
    # and Map.get(attribute, :requirement) != "reserved"
    Map.has_key?(attribute, :enum)
  end

  defp check_enum(attributes, name, attribute, acc) do
    enum = Map.get(attribute, :enum)
    key = Schema.Enums.sibling(name, attribute)

    case Map.get(attributes, key) do
      nil ->
        name = Atom.to_string(name)
        if Map.has_key?(enum, :"-1") do
          ["#{name}*" | acc]
        else
          [name | acc]
        end

      sibling ->
        if attribute[:requirement] != sibling[:requirement] do
          IO.puts("requirement for #{name} differ from #{key}")
        end
        acc
    end
  end
end
