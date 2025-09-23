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
          |> Map.put(:categories_path, "main_skills")

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
          |> Map.put(:categories_path, "main_domains")

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
          |> Map.put(:categories_path, "main_modules")

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
  @spec main_skills(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_skills(conn, %{"id" => id} = params) do
    case SchemaController.main_skill_skills(params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        skills = sort_by(data[:classes], :uid)

        data =
          Map.put(data, :classes, skills)
          |> Map.put(:class_type, "skill")
          |> Map.put(:classes_path, "skills")

        render(conn, "category.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  def main_skills(conn, params) do
    data =
      Map.put_new(params, "extensions", "")
      |> SchemaController.main_skills()
      |> sort_attributes(:uid)
      |> sort_classes()
      |> Map.put(:categories_path, "main_skills")
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
  @spec main_domains(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_domains(conn, %{"id" => id} = params) do
    case SchemaController.main_domain_domains(params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        domains = sort_by(data[:classes], :uid)

        data =
          Map.put(data, :classes, domains)
          |> Map.put(:class_type, "domain")
          |> Map.put(:classes_path, "domains")

        render(conn, "category.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  def main_domains(conn, params) do
    data =
      Map.put_new(params, "extensions", "")
      |> SchemaController.main_domains()
      |> sort_attributes(:uid)
      |> sort_classes()
      |> Map.put(:categories_path, "main_domains")
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
  @spec main_modules(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_modules(conn, %{"id" => id} = params) do
    case SchemaController.main_module_modules(params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        modules = sort_by(data[:classes], :uid)

        data =
          Map.put(data, :classes, modules)
          |> Map.put(:class_type, "module")
          |> Map.put(:classes_path, "modules")

        render(conn, "category.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  def main_modules(conn, params) do
    data =
      Map.put_new(params, "extensions", "")
      |> SchemaController.main_modules()
      |> sort_attributes(:uid)
      |> sort_classes()
      |> Map.put(:categories_path, "main_modules")
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

    case Schema.skill(extension, id) do
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

    case Schema.domain(extension, id) do
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

    case Schema.module(extension, id) do
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
          |> Map.put(:_children, children)

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

  defp sort_classes(categories) do
    Map.update!(categories, :attributes, fn list ->
      Enum.map(list, fn {name, category} ->
        {name, Map.update!(category, :classes, &sort_by_float_uid(&1))}
      end)
    end)
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
