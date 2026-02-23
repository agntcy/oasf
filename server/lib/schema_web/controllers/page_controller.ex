# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.PageController do
  @moduledoc """
  The schema server web pages
  """
  use SchemaWeb, :controller

  alias SchemaWeb.SchemaController

  @spec skill_graph(Plug.Conn.t(), any) :: Plug.Conn.t()
  def skill_graph(conn, %{"id" => id} = params) do
    case SchemaWeb.SchemaController.skill_ex(id, params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

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
  def domain_graph(conn, %{"id" => id} = params) do
    case SchemaWeb.SchemaController.domain_ex(id, params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

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
  def module_graph(conn, %{"id" => id} = params) do
    case SchemaWeb.SchemaController.module_ex(id, params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

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
  def object_graph(conn, %{"id" => id} = params) do
    case SchemaWeb.SchemaController.object_ex(id, params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

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
  def profiles(conn, %{"id" => id} = params) do
    name =
      case params["extension"] do
        nil -> id
        extension -> "#{extension}/#{id}"
      end

    profiles = SchemaController.get_profiles(params)

    case Schema.profile(profiles, name) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

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
  def skill_categories(conn, %{"id" => id} = params) do
    case SchemaController.skill_category_skills(params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        skills = sort_by(data[:classes], :uid)

        data =
          data
          |> Map.put(:classes, skills)
          |> sort_subcategories()
          |> Map.put(:class_type, "skill")
          |> Map.put(:classes_path, "skills")
          |> Map.put(:categories_path, "skill_categories")

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
      |> SchemaController.skill_categories()
      |> sort_attributes(:uid)
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
  def domain_categories(conn, %{"id" => id} = params) do
    case SchemaController.domain_category_domains(params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        domains = sort_by(data[:classes], :uid)

        data =
          data
          |> Map.put(:classes, domains)
          |> sort_subcategories()
          |> Map.put(:class_type, "domain")
          |> Map.put(:classes_path, "domains")
          |> Map.put(:categories_path, "domain_categories")

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
      |> SchemaController.domain_categories()
      |> sort_attributes(:uid)
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
  def module_categories(conn, %{"id" => id} = params) do
    case SchemaController.module_category_modules(params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        modules = sort_by(data[:classes], :uid)

        data =
          data
          |> Map.put(:classes, modules)
          |> sort_subcategories()
          |> Map.put(:class_type, "module")
          |> Map.put(:classes_path, "modules")
          |> Map.put(:categories_path, "module_categories")

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
      |> SchemaController.module_categories()
      |> sort_attributes(:uid)
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
  def skills(conn, %{"id" => id} = params) do
    extension = params["extension"]
    profiles = parse_profiles_from_params(params)

    case Schema.skill(extension, id, profiles) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        children =
          Schema.Utils.find_children(Schema.all_skills(), data[:name])
          |> Enum.reject(fn item -> item[:hidden?] == true end)

        data =
          data
          |> sort_attributes_by_key()
          |> Map.put(:key, Schema.Utils.to_uid(extension, id))
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
  def domains(conn, %{"id" => id} = params) do
    extension = params["extension"]
    profiles = parse_profiles_from_params(params)

    case Schema.domain(extension, id, profiles) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        children =
          Schema.Utils.find_children(Schema.all_domains(), data[:name])
          |> Enum.reject(fn item -> item[:hidden?] == true end)

        data =
          data
          |> sort_attributes_by_key()
          |> Map.put(:key, Schema.Utils.to_uid(extension, id))
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
  def modules(conn, %{"id" => id} = params) do
    extension = params["extension"]
    profiles = parse_profiles_from_params(params)

    case Schema.module(extension, id, profiles) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        children =
          Schema.Utils.find_children(Schema.all_modules(), data[:name])
          |> Enum.reject(fn item -> item[:hidden?] == true end)

        data =
          data
          |> sort_attributes_by_key()
          |> Map.put(:key, Schema.Utils.to_uid(extension, id))
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
  def objects(conn, %{"id" => id} = params) do
    case SchemaController.object(params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        children =
          Schema.Utils.find_children(Schema.all_objects(), data[:name])
          |> Enum.reject(fn item -> item[:hidden?] == true end)

        data =
          data
          |> sort_attributes_by_key()
          |> Map.put(:key, Schema.Utils.to_uid(params["extension"], id))
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
    Map.update!(categories, :attributes, fn list ->
      Enum.map(list, fn {name, category} ->
        category =
          category
          |> Map.update(:classes, [], &sort_by_float_uid(&1))
          |> sort_subcategories()

        {name, category}
      end)
    end)
  end

  defp sort_subcategories(category) do
    subcategories = category[:subcategories] || %{}

    if map_size(subcategories) > 0 do
      sorted_subcategories =
        subcategories
        |> Enum.map(fn {key, subcategory} ->
          sorted_subcategory =
            subcategory
            |> Map.update(:classes, [], &sort_by_float_uid(&1))
            |> sort_subcategories()

          {key, sorted_subcategory}
        end)
        |> Enum.into(%{})

      Map.put(category, :subcategories, sorted_subcategories)
    else
      category
    end
  end

  defp sort_by_float_uid(classes) do
    Enum.sort_by(classes, fn {_, class} -> uid_to_float(class[:uid]) end)
  end

  # Convert the uid into a float with a leading "0."
  defp uid_to_float(uid) do
    uid_string = Integer.to_string(uid)
    float_string = "0." <> String.slice(uid_string, 0..-1//1)
    String.to_float(float_string)
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
