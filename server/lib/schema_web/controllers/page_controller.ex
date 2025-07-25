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

  @spec feature_graph(Plug.Conn.t(), any) :: Plug.Conn.t()
  def feature_graph(conn, %{"id" => id} = params) do
    case SchemaWeb.SchemaController.feature_ex(id, params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      class ->
        data =
          Schema.Graph.build(class)
          |> Map.put(:categories_path, "main_features")

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
    data = Schema.data_types() |> sort_attributes()

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

    data = SchemaController.get_profiles(params)

    case Map.get(data, name) do
      nil ->
        send_resp(conn, 404, "Not Found: #{name}")

      profile ->
        render(conn, "profile.html",
          extensions: Schema.extensions(),
          profiles: data,
          data: sort_attributes(profile)
        )
    end
  end

  def profiles(conn, params) do
    data = SchemaController.get_profiles(params)

    render(conn, "profiles.html",
      extensions: Schema.extensions(),
      profiles: data,
      data: data
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
  Renders main features or the features in a given main feature.
  """
  @spec main_features(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_features(conn, %{"id" => id} = params) do
    case SchemaController.main_feature_features(params) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        features = sort_by(data[:classes], :uid)

        data =
          Map.put(data, :classes, features)
          |> Map.put(:class_type, "feature")
          |> Map.put(:classes_path, "features")

        render(conn, "category.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  def main_features(conn, params) do
    data =
      Map.put_new(params, "extensions", "")
      |> SchemaController.main_features()
      |> sort_attributes(:uid)
      |> sort_classes()
      |> Map.put(:categories_path, "main_features")
      |> Map.put(:classes_path, "features")

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
    data = SchemaController.dictionary(params) |> sort_attributes()

    render(conn, "dictionary.html",
      extensions: Schema.extensions(),
      profiles: SchemaController.get_profiles(params),
      data: data
    )
  end

  @doc """
  Redirects from the older /base_class URL to /classes/base_class.
  """
  @spec base_class(Plug.Conn.t(), any) :: Plug.Conn.t()
  def base_class(conn, _params) do
    redirect(conn, to: "/classes/base_class")
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
        data =
          data
          |> sort_attributes()
          |> Map.put(:key, Schema.Utils.to_uid(extension, id))

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
        data =
          data
          |> sort_attributes()
          |> Map.put(:key, Schema.Utils.to_uid(extension, id))

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
  Renders features.
  """
  @spec features(Plug.Conn.t(), any) :: Plug.Conn.t()
  def features(conn, %{"id" => id} = params) do
    extension = params["extension"]

    case Schema.feature(extension, id) do
      nil ->
        send_resp(conn, 404, "Not Found: #{id}")

      data ->
        data =
          data
          |> sort_attributes()
          |> Map.put(:key, Schema.Utils.to_uid(extension, id))

        render(conn, "class.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  def features(conn, params) do
    data = %{
      classes:
        SchemaController.features(params)
        |> sort_by(:uid),
      title: "Features",
      description: "The OASF features",
      classes_path: "features"
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
        data =
          data
          |> sort_attributes()
          |> Map.put(:key, Schema.Utils.to_uid(params["extension"], id))

        render(conn, "object.html",
          extensions: Schema.extensions(),
          profiles: SchemaController.get_profiles(params),
          data: data
        )
    end
  end

  def objects(conn, params) do
    data = SchemaController.objects(params) |> sort_by_name()

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

  defp sort_attributes(map) do
    sort_attributes(map, :caption)
  end

  defp sort_attributes(map, key) do
    Map.update!(map, :attributes, &sort_by(&1, key))
  end

  defp sort_by_name(map) do
    sort_by(map, :caption)
  end

  defp sort_by(map, key) do
    Enum.sort(map, fn {_, v1}, {_, v2} -> v1[key] <= v2[key] end)
  end
end
