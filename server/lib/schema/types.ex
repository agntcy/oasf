# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
  def class_uid(category_uid, class_id), do: category_uid * 1000 + class_id

  @doc """
  Makes a main domain uid for the given main domain and extension identifiers.
  """
  @spec main_domain_uid(number, number) :: number
  def main_domain_uid(extension_uid, main_domain_id), do: extension_uid * 100 + main_domain_id

  @doc """
  Makes a main domain uid for the given main domain and extension identifiers. Checks if the
  main domain uid already has the extension.
  """
  @spec main_domain_uid_ex(number, number) :: number
  def main_domain_uid_ex(extension_uid, main_domain_id) when main_domain_id < 100,
    do: main_domain_uid(extension_uid, main_domain_id)

  def main_domain_uid_ex(_extension_uid, main_domain_id), do: main_domain_id

  @doc """
  Makes a domain uid for the given domain and domain identifiers.
  """
  @spec domain_uid(number, number) :: number
  def domain_uid(main_domain_uid, domain_id), do: main_domain_uid * 1000 + domain_id

  @doc """
  Makes a main feature uid for the given main feature and extension identifiers.
  """
  @spec main_feature_uid(number, number) :: number
  def main_feature_uid(extension_uid, main_feature_id), do: extension_uid * 100 + main_feature_id

  @doc """
  Makes a main feature uid for the given main feature and extension identifiers. Checks if the
  main feature uid already has the extension.
  """
  @spec main_feature_uid_ex(number, number) :: number
  def main_feature_uid_ex(extension_uid, main_feature_id) when main_feature_id < 100,
      do: main_feature_uid(extension_uid, main_feature_id)

  def main_feature_uid_ex(_extension_uid, main_feature_id), do: main_feature_id

  @doc """
  Makes a feature uid for the given feature and feature identifiers.
  """
  @spec feature_uid(number, number) :: number
  def feature_uid(main_feature_uid, feature_id), do: main_feature_uid * 1000 + feature_id

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

end
