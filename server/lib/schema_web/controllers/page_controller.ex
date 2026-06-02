# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.PageController do
  @moduledoc """
  The schema server web pages.

  All skill/domain/module pages share the same render logic — each Phoenix
  action is a one-line delegate to a family-parameterized helper.
  """
  use SchemaWeb, :controller

  alias SchemaWeb.SchemaController

  # ----------------------------------------------------------------------------
  # Class graphs — /skill/graph/:name, /domain/graph/:name, /module/graph/:name
  # ----------------------------------------------------------------------------

  @spec skill_graph(Plug.Conn.t(), any) :: Plug.Conn.t()
  def skill_graph(conn, %{"name" => name} = params), do: class_graph(:skill, conn, name, params)

  @spec domain_graph(Plug.Conn.t(), any) :: Plug.Conn.t()
  def domain_graph(conn, %{"name" => name} = params), do: class_graph(:domain, conn, name, params)

  @spec module_graph(Plug.Conn.t(), any) :: Plug.Conn.t()
  def module_graph(conn, %{"name" => name} = params), do: class_graph(:module, conn, name, params)

  defp class_graph(family, conn, name, params) do
    case SchemaController.class_ex(family, name, params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      class ->
        data =
          Schema.Graph.build(class)
          |> Map.put(:categories_path, "#{family}_categories")

        render(conn, "class_graph.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  @spec object_graph(Plug.Conn.t(), any) :: Plug.Conn.t()
  def object_graph(conn, %{"name" => name} = params) do
    case SchemaController.object_ex(name, params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      obj ->
        data = Schema.Graph.build(obj)

        render(conn, "object_graph.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  # ----------------------------------------------------------------------------
  # Data types / profiles / dictionary
  # ----------------------------------------------------------------------------

  @doc """
  Renders the data types.
  """
  @spec data_types(Plug.Conn.t(), any) :: Plug.Conn.t()
  def data_types(conn, params) do
    data = Schema.data_types() |> sort_attributes_by_key()

    render(conn, "data_types.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

  @doc """
  Renders schema profiles.
  """
  @spec profiles(Plug.Conn.t(), map) :: Plug.Conn.t()
  def profiles(conn, %{"name" => name} = params) do
    full_name =
      case params["extension"] do
        nil -> name
        extension -> "#{extension}/#{name}"
      end

    profiles = SchemaController.get_profiles(params)

    case Schema.profile(profiles, full_name) do
      nil ->
        send_resp(conn, 404, "Not Found: #{full_name}")

      profile ->
        render(conn, "profile.html",
          extensions: Schema.extensions(),
          profiles: profiles,
          data: sort_attributes_by_key(profile)
        )
    end
  end

  def profiles(conn, params) do
    profiles = SchemaController.get_profiles(params)
    sorted_profiles = sort_by_descoped_key(profiles)

    render(conn, "profiles.html",
      extensions: Schema.extensions(),
      profiles: profiles,
      data: sorted_profiles
    )
  end

  @doc """
  Renders the attribute dictionary.
  """
  @spec dictionary(Plug.Conn.t(), any) :: Plug.Conn.t()
  def dictionary(conn, params) do
    data = SchemaController.dictionary(params) |> sort_attributes_by_key()

    render(conn, "dictionary.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

  # ----------------------------------------------------------------------------
  # Category pages — /skill_categories[/:name], same for domain/module
  # ----------------------------------------------------------------------------

  @doc """
  Renders main skills or the skills in a given main skill.
  """
  @spec skill_categories(Plug.Conn.t(), map) :: Plug.Conn.t()
  def skill_categories(conn, params), do: class_categories(:skill, conn, params)

  @doc """
  Renders main domains or the domains in a given main domain.
  """
  @spec domain_categories(Plug.Conn.t(), map) :: Plug.Conn.t()
  def domain_categories(conn, params), do: class_categories(:domain, conn, params)

  @doc """
  Renders main modules or the modules in a given main module.
  """
  @spec module_categories(Plug.Conn.t(), map) :: Plug.Conn.t()
  def module_categories(conn, params), do: class_categories(:module, conn, params)

  defp class_categories(family, conn, %{"name" => name} = params) do
    taxonomy_params = Map.put(params, "name", name)
    taxonomy = SchemaController.taxonomy(family, taxonomy_params)

    if map_size(taxonomy) == 0 do
      send_resp(conn, 404, "Not Found: #{name}")
    else
      {_category_key, category_data} = Enum.at(taxonomy, 0)

      data =
        category_data
        |> Map.merge(%{
          class_type: to_string(family),
          classes_path: "#{family}s",
          categories_path: "#{family}_categories"
        })

      render(conn, "category.html",
        extensions: Schema.extensions(),
        profiles: SchemaController.get_profiles(params),
        data: data
      )
    end
  end

  defp class_categories(family, conn, params) do
    data =
      Map.put_new(params, "extensions", "")
      |> then(&SchemaController.taxonomy(family, &1))
      |> (fn taxonomy -> %{attributes: taxonomy} end).()
      |> sort_attributes(:id)
      |> sort_classes()
      |> Map.put(:categories_path, "#{family}_categories")
      |> Map.put(:classes_path, "#{family}s")

    render(conn, "index.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

  # ----------------------------------------------------------------------------
  # Class pages — /skills[/:name], same for domain/module
  # ----------------------------------------------------------------------------

  @doc """
  Renders skills.
  """
  @spec skills(Plug.Conn.t(), any) :: Plug.Conn.t()
  def skills(conn, params), do: classes(:skill, conn, params)

  @doc """
  Renders domains.
  """
  @spec domains(Plug.Conn.t(), any) :: Plug.Conn.t()
  def domains(conn, params), do: classes(:domain, conn, params)

  @doc """
  Renders modules.
  """
  @spec modules(Plug.Conn.t(), any) :: Plug.Conn.t()
  def modules(conn, params), do: classes(:module, conn, params)

  defp classes(family, conn, %{"name" => name} = params) do
    extension = params["extension"]
    profiles = parse_profiles_from_params(params)

    case SchemaController.class(family, extension, name, profiles) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      data ->
        children =
          Schema.Utils.find_children(Schema.all_classes(family), data[:name])
          |> Enum.reject(fn item -> item[:hidden?] == true end)

        data =
          data
          |> sort_attributes_by_key()
          |> Map.put(:key, Schema.Utils.to_uid(extension, name))
          |> Map.put(:subclasses, children)

        render(conn, "class.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  defp classes(family, conn, params) do
    plural = "#{family}s"

    data = %{
      classes:
        SchemaController.classes(family, params)
        |> sort_by(:uid),
      title: String.capitalize(plural),
      description: "The OASF #{plural}",
      classes_path: plural
    }

    render(conn, "classes.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

  # ----------------------------------------------------------------------------
  # Objects
  # ----------------------------------------------------------------------------

  @doc """
  Renders objects.
  """
  @spec objects(Plug.Conn.t(), map) :: Plug.Conn.t()
  def objects(conn, %{"name" => name} = params) do
    extension = params["extension"]
    extensions = parse_extensions_from_params(params)
    profiles = parse_profiles_from_params(params)

    case SchemaController.object(extensions, extension, name, profiles) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      data ->
        children =
          Schema.Utils.find_children(Schema.all_objects(), data[:name])
          |> Enum.reject(fn item -> item[:hidden?] == true end)

        data =
          data
          |> sort_attributes_by_key()
          |> Map.put(:key, Schema.Utils.to_uid(extension, name))
          |> Map.put(:options, children)

        render(conn, "object.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  def objects(conn, params) do
    data = SchemaController.objects(params) |> sort_by_descoped_key()

    render(conn, "objects.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

  # ----------------------------------------------------------------------------
  # Helpers
  # ----------------------------------------------------------------------------

  defp parse_extensions_from_params(params) do
    case params["extensions"] do
      nil -> nil
      "" -> nil
      ext -> ext
    end
  end

  defp parse_profiles_from_params(params) do
    case params["profiles"] do
      nil ->
        nil

      "" ->
        MapSet.new()

      profiles_string ->
        profiles_string
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> MapSet.new()
    end
  end

  defp sort_classes(categories) do
    Map.update!(categories, :attributes, &Schema.Utils.sort_taxonomy_tree/1)
  end

  defp sort_attributes(map, key) do
    Map.update!(map, :attributes, &sort_by(&1, key))
  end

  defp sort_by(map, key) do
    Enum.sort(map, fn {_, v1}, {_, v2} -> v1[key] <= v2[key] end)
  end

  defp sort_attributes_by_key(map) do
    Map.update!(map, :attributes, &sort_by_descoped_key/1)
  end

  defp sort_by_descoped_key(map) do
    Enum.sort(map, fn {k1, _}, {k2, _} ->
      Schema.Utils.descope(k1) <= Schema.Utils.descope(k2)
    end)
  end
end
