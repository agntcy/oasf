# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Types do
  @schema_addr "schema.oasf.agntcy.org"

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
  Makes longer class name from class type/family, category and name.
  """
  def long_class_name(family, category, name) do
    "#{@schema_addr}/#{family}/#{category}/#{name}"
  end

  @doc """
  Extracts class name from longer class name.
  """
  def extract_class_name(name) do
    case String.split(name, "/") do
      [last] ->
        # if there were no "/" characters, return the original string
        last

      list ->
        # return the last part of the list
        List.last(list)
    end
  end
end
