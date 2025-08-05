# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Types do
  @schema_uri "schema.oasf.agntcy.org"

  @moduledoc """
  Schema types and helpers functions to make unique identifiers.
  """

  @doc """
  Makes a category uid for the given category and extension identifiers.
  """
  @spec category_uid(number, number) :: number
  def category_uid(extension_uid, category_id), do: extension_uid * 100 + category_id

  @doc """
  Makes a category uid for the given category and extension identifiers. Checks if the
  category uid already has the extension.
  """
  @spec category_uid_ex(number, number) :: number
  def category_uid_ex(extension_uid, category_id) when category_id < 100,
    do: category_uid(extension_uid, category_id)

  def category_uid_ex(_extension_uid, category_id), do: category_id

  @doc """
  Makes a class uid for the given class and category identifiers.
  """
  @spec class_uid(number, number) :: number
  def class_uid(category_uid, class_id), do: category_uid * 100 + class_id

  @doc """
  Makes a type uid for the given class and activity identifiers.
  """
  @spec type_uid(number, number) :: number
  def type_uid(class_uid, activity_id), do: class_uid * 100 + activity_id

  @doc """
  Makes type name from class name and type uid enum name.
  """
  @spec type_name(binary, binary) :: binary
  def type_name(class, name) do
    class <> ": " <> name
  end

  @doc """
  Makes class name as its unique identifier within OASF by adding classes it extends from,
  excluding base classes.
  """
  def class_name_with_hierarchy(name, all_classes) do
    base_items = ["base_class", "base_skill", "base_domain", "base_feature"]
    hierarchy = build_hierarchy(name, all_classes, [])
    filtered = Enum.reject(hierarchy, &(&1 in base_items))
    Enum.join(filtered ++ [name], "/")
  end

  defp build_hierarchy(name, class_map, acc) do
    key = if is_atom(name), do: name, else: String.to_atom(name)

    case Map.get(class_map, key) do
      %{extends: parent} when parent not in [nil, ""] ->
        build_hierarchy(parent, class_map, [parent | acc])

      _ ->
        acc
    end
  end

  def is_oasf_class?(name) do
    String.starts_with?(name, @schema_uri)
  end
end
