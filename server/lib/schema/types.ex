# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule Schema.Types do
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
  Makes type name from class name and type uid enum name.
  """
  @spec type_name(binary, binary) :: binary
  def type_name(class, name) do
    class <> ": " <> name
  end

  @doc """
  Encodes the given type to a JSON schema type.
  """
  @spec encode_type(String.t()) :: String.t()
  def encode_type(type) do
    case type do
      "string_t" -> "string"
      "integer_t" -> "integer"
      "long_t" -> "integer"
      "float_t" -> "number"
      "boolean_t" -> "boolean"
      "timestamp_t" -> "integer"
      "datetime_t" -> "string"
      "uuid_t" -> "string"
      "cid_t" -> "string"
      "long_string_t" -> "string"
      "email_t" -> "string"
      "url_t" -> "string"
      "ip_t" -> "string"
      "mac_t" -> "string"
      "port_t" -> "integer"
      "file_name_t" -> "string"
      "path_t" -> "string"
      "mime_t" -> "string"
      "subnet_t" -> "string"
      "file_hash_t" -> "string"
      "unit_interval_t" -> "number"
      _ -> "object"
    end
  end
end
