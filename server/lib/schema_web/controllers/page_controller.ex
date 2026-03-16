# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.PageController do
  @moduledoc """
  The schema server web pages
  """
  use SchemaWeb, :controller

  alias SchemaWeb.SchemaController

  @spec skill_graph(Plug.Conn.t(), any) :: Plug.Conn.t()
  def skill_graph(conn, %{"name" => name} = params) do
    case SchemaController.skill_ex(name, params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      class ->
        data =
          Schema.Graph.build(class)
          |> Map.put(:categories_path, "skill_categories")

        render(conn, "class_graph.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  @spec domain_graph(Plug.Conn.t(), any) :: Plug.Conn.t()
  def domain_graph(conn, %{"name" => name} = params) do
    case SchemaController.domain_ex(name, params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      class ->
        data =
          Schema.Graph.build(class)
          |> Map.put(:categories_path, "domain_categories")

        render(conn, "class_graph.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  @spec module_graph(Plug.Conn.t(), any) :: Plug.Conn.t()
  def module_graph(conn, %{"name" => name} = params) do
    case SchemaController.module_ex(name, params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      class ->
        data =
          Schema.Graph.build(class)
          |> Map.put(:categories_path, "module_categories")

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
  Renders main skills or the skills in a given main skill.
  """
  @spec skill_categories(Plug.Conn.t(), map) :: Plug.Conn.t()
  def skill_categories(conn, %{"name" => name} = params) do
    # Use name parameter directly for taxonomy function
    taxonomy_params = Map.put(params, "name", name)
    taxonomy = SchemaController.taxonomy_skills(taxonomy_params)

    if map_size(taxonomy) == 0 do
      send_resp(conn, 404, "Not Found: #{name}")
    else
      # Extract the category data from the taxonomy map (which has the category name as key)
      {_category_key, category_data} = Enum.at(taxonomy, 0)

      data =
        category_data
        |> Map.merge(%{
          class_type: "skill",
          classes_path: "skills",
          categories_path: "skill_categories"
        })

      render(conn, "category.html",
        extensions: Schema.extensions(),
        profiles: SchemaController.get_profiles(params),
        data: data
      )
    end
  end

  def skill_categories(conn, params) do
    data =
      Map.put_new(params, "extensions", "")
      |> SchemaController.taxonomy_skills()
      |> (fn taxonomy -> %{attributes: taxonomy} end).()
      |> sort_attributes(:id)
      |> sort_classes()
      |> Map.put(:categories_path, "skill_categories")
      |> Map.put(:classes_path, "skills")

    render(conn, "index.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

  @doc """
  Renders main domains or the domains in a given main domain.
  """
  @spec domain_categories(Plug.Conn.t(), map) :: Plug.Conn.t()
  def domain_categories(conn, %{"name" => name} = params) do
    # Use name parameter directly for taxonomy function
    taxonomy_params = Map.put(params, "name", name)
    taxonomy = SchemaController.taxonomy_domains(taxonomy_params)

    if map_size(taxonomy) == 0 do
      send_resp(conn, 404, "Not Found: #{name}")
    else
      # Extract the category data from the taxonomy map (which has the category name as key)
      {_category_key, category_data} = Enum.at(taxonomy, 0)

      data =
        category_data
        |> Map.merge(%{
          class_type: "domain",
          classes_path: "domains",
          categories_path: "domain_categories"
        })

      render(conn, "category.html",
        extensions: Schema.extensions(),
        profiles: SchemaController.get_profiles(params),
        data: data
      )
    end
  end

  def domain_categories(conn, params) do
    data =
      Map.put_new(params, "extensions", "")
      |> SchemaController.taxonomy_domains()
      |> (fn taxonomy -> %{attributes: taxonomy} end).()
      |> sort_attributes(:id)
      |> sort_classes()
      |> Map.put(:categories_path, "domain_categories")
      |> Map.put(:classes_path, "domains")

    render(conn, "index.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

  @doc """
  Renders main modules or the modules in a given main module.
  """
  @spec module_categories(Plug.Conn.t(), map) :: Plug.Conn.t()
  def module_categories(conn, %{"name" => name} = params) do
    # Use name parameter directly for taxonomy function
    taxonomy_params = Map.put(params, "name", name)
    taxonomy = SchemaController.taxonomy_modules(taxonomy_params)

    if map_size(taxonomy) == 0 do
      send_resp(conn, 404, "Not Found: #{name}")
    else
      # Extract the category data from the taxonomy map (which has the category name as key)
      {_category_key, category_data} = Enum.at(taxonomy, 0)

      data =
        category_data
        |> Map.merge(%{
          class_type: "module",
          classes_path: "modules",
          categories_path: "module_categories"
        })

      render(conn, "category.html",
        extensions: Schema.extensions(),
        profiles: SchemaController.get_profiles(params),
        data: data
      )
    end
  end

  def module_categories(conn, params) do
    data =
      Map.put_new(params, "extensions", "")
      |> SchemaController.taxonomy_modules()
      |> (fn taxonomy -> %{attributes: taxonomy} end).()
      |> sort_attributes(:id)
      |> sort_classes()
      |> Map.put(:categories_path, "module_categories")
      |> Map.put(:classes_path, "modules")

    render(conn, "index.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
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

  @doc """
  Renders skills.
  """
  @spec skills(Plug.Conn.t(), any) :: Plug.Conn.t()
  def skills(conn, %{"name" => name} = params) do
    extension = params["extension"]
    profiles = parse_profiles_from_params(params)

    case SchemaController.class(:skills, extension, name, profiles) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      data ->
        children =
          Schema.Utils.find_children(Schema.all_skills(), data[:name])
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

  def skills(conn, params) do
    data = %{
      classes:
        SchemaController.skills(params)
        |> sort_by(:uid),
      title: "Skills",
      description: "The OASF skills",
      classes_path: "skills"
    }

    render(conn, "classes.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

  @doc """
  Renders domains.
  """
  @spec domains(Plug.Conn.t(), any) :: Plug.Conn.t()
  def domains(conn, %{"name" => name} = params) do
    extension = params["extension"]
    profiles = parse_profiles_from_params(params)

    case SchemaController.class(:domains, extension, name, profiles) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      data ->
        children =
          Schema.Utils.find_children(Schema.all_domains(), data[:name])
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

  def domains(conn, params) do
    data = %{
      classes:
        SchemaController.domains(params)
        |> sort_by(:uid),
      title: "Domains",
      description: "The OASF domains",
      classes_path: "domains"
    }

    render(conn, "classes.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

  @doc """
  Renders modules.
  """
  @spec modules(Plug.Conn.t(), any) :: Plug.Conn.t()
  def modules(conn, %{"name" => name} = params) do
    extension = params["extension"]
    profiles = parse_profiles_from_params(params)

    case SchemaController.class(:modules, extension, name, profiles) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      data ->
        children =
          Schema.Utils.find_children(Schema.all_modules(), data[:name])
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

  def modules(conn, params) do
    data = %{
      classes:
        SchemaController.modules(params)
        |> sort_by(:uid),
      title: "Modules",
      description: "The OASF modules",
      classes_path: "modules"
    }

    render(conn, "classes.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

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
    Map.update!(categories, :attributes, fn attributes ->
      Enum.map(attributes, fn {name, category} ->
        {name, sort_classes_recursive(category)}
      end)
    end)
  end

  defp sort_classes_recursive(category) when is_map(category) do
    sorted_classes =
      category
      |> Map.get(:classes, %{})
      |> sort_by_class_id()
      |> Enum.map(fn {key, class} -> {key, sort_classes_recursive(class)} end)

    Map.put(category, :classes, sorted_classes)
  end

  defp sort_classes_recursive(other), do: other

  defp sort_by_class_id(classes) when is_map(classes) do
    classes
    |> Enum.to_list()
    |> sort_by_class_id()
  end

  defp sort_by_class_id(classes) when is_list(classes) do
    Enum.sort_by(classes, fn {_, class} ->
      normalize_class_id(Map.get(class, :id, Map.get(class, :uid, 0)))
    end)
  end

  defp sort_by_class_id(_), do: []

  defp normalize_class_id(id) when is_integer(id), do: id

  defp normalize_class_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {parsed, ""} -> parsed
      _ -> 0
    end
  end

  defp normalize_class_id(_), do: 0

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
