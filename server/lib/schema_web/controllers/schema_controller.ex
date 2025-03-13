# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule SchemaWeb.SchemaController do
  @moduledoc """
  The Class Schema API.
  """

  use SchemaWeb, :controller

  import PhoenixSwagger

  require Logger

  @verbose "_mode"
  @spaces "_spaces"

  @enum_text "_enum_text"
  @observables "_observables"

  @extensions_param_description "When included in request, filters response to included only the" <>
                                  " supplied extensions, or no extensions if this parameter has" <>
                                  " no value. When not included, all extensions are returned in" <>
                                  " the response."

  @profiles_param_description "When included in request, filters response to include only the" <>
                                " supplied profiles, or no profiles if this parameter has no" <>
                                " value. When not included, all profiles are returned in" <>
                                " the response."

  # -------------------
  # Class Schema API's
  # -------------------

  def swagger_definitions do
    %{
      Version:
        swagger_schema do
          title("Version")
          description("Schema version, using Semantic Versioning Specification (SemVer) format.")

          properties do
            version(:string, "Version number", required: true)
          end

          example(%{
            version: "1.0.0"
          })
        end,
      Versions:
        swagger_schema do
          title("Versions")
          description("Schema versions, using Semantic Versioning Specification (SemVer) format.")

          properties do
            versions(:string, "Version numbers", required: true)
          end

          example(%{
            default: %{
              version: "1.0.0",
              url: "https://schema.example.com:443/api"
            },
            versions: [
              %{
                version: "1.1.0-dev",
                url: "https://schema.example.com:443/1.1.0-dev/api"
              },
              %{
                version: "1.0.0",
                url: "https://schema.example.com:443/1.0.0/api"
              }
            ]
          })
        end,
      ClassDesc:
        swagger_schema do
          title("Class Descriptor")
          description("Schema class descriptor.")

          properties do
            name(:string, "Class name", required: true)
            caption(:string, "Class caption", required: true)
            description(:string, "Class description", required: true)
            category(:string, "Class category", required: true)
            category_name(:string, "Class category caption", required: true)
            profiles(:array, "Class profiles", items: %PhoenixSwagger.Schema{type: :string})
            uid(:integer, "Class unique identifier", required: true)
          end

          example([
            %{
              caption: "DHCP Activity",
              category: "network",
              category_name: "Network Activity",
              description: "DHCP Activity classes report MAC to IP assignment via DHCP.",
              name: "dhcp_activity",
              profiles: [
                "cloud",
                "datetime",
                "host",
                "file_security"
              ],
              uid: 4004
            }
          ])
        end,
      DomainDesc:
        swagger_schema do
          title("Domain Descriptor")
          description("Schema domain descriptor.")

          properties do
            name(:string, "Domain name", required: true)
            caption(:string, "Domain caption", required: true)
            description(:string, "Domain description", required: true)
            main_domain(:string, "Domain's main domain", required: true)
            main_domain_name(:string, "omain's main domain's caption", required: true)
            profiles(:array, "Domain profiles", items: %PhoenixSwagger.Schema{type: :string})
            uid(:integer, "Domain unique identifier", required: true)
          end

          example([
            %{
              caption: "DHCP Activity",
              main_domain: "network",
              main_domain_name: "Network Activity",
              description: "DHCP Activity classes report MAC to IP assignment via DHCP.",
              name: "dhcp_activity",
              profiles: [
                "cloud",
                "datetime",
                "host",
                "file_security"
              ],
              uid: 4004
            }
          ])
        end,
      FeatureDesc:
        swagger_schema do
          title("Feature Descriptor")
          description("Schema feature descriptor.")

          properties do
            name(:string, "Feature name", required: true)
            caption(:string, "Feature caption", required: true)
            description(:string, "Feature description", required: true)
            main_feature(:string, "Feature's main feature", required: true)
            main_feature_name(:string, "Feature's main feature's caption", required: true)
            profiles(:array, "Feature profiles", items: %PhoenixSwagger.Schema{type: :string})
            uid(:integer, "Feature unique identifier", required: true)
          end

          example([
            %{
              caption: "DHCP Activity",
              main_feature: "network",
              main_feature_name: "Network Activity",
              description: "DHCP Activity classes report MAC to IP assignment via DHCP.",
              name: "dhcp_activity",
              profiles: [
                "cloud",
                "datetime",
                "host",
                "file_security"
              ],
              uid: 4004
            }
          ])
        end,
      ObjectDesc:
        swagger_schema do
          title("Object Descriptor")
          description("Schema object descriptor.")

          properties do
            name(:string, "Object name", required: true)
            caption(:string, "Object caption", required: true)
            description(:string, "Object description", required: true)
            observable(:integer, "Observable ID")
            profiles(:array, "Object profiles", items: %PhoenixSwagger.Schema{type: :string})
          end

          example([
            %{
              caption: "File",
              description:
                "The file object describes files, folders, links and mounts," <>
                  " including the reputation information, if applicable.",
              name: "file",
              observable: 24,
              profiles: [
                "file_security"
              ]
            }
          ])
        end,
      Class:
        swagger_schema do
          title("Class")
          description("An OASF formatted class object.")
          type(:object)
        end,
      ValidationError:
        swagger_schema do
          title("Validation Error")
          description("A validation error. Additional error-specific properties will exist.")

          properties do
            error(:string, "Error code")
            message(:string, "Human readable error message")
          end

          additional_properties(true)
        end,
      ValidationWarning:
        swagger_schema do
          title("Validation Warning")
          description("A validation warning. Additional warning-specific properties will exist.")

          properties do
            error(:string, "Warning code")
            message(:string, "Human readable warning message")
          end

          additional_properties(true)
        end,
      ClassValidation:
        swagger_schema do
          title("Class Validation")
          description("The errors and and warnings found when validating an class.")

          properties do
            uid(:string, "The class's metadata.uid, if available")
            error(:string, "Overall error message")

            errors(
              :array,
              "Validation errors",
              items: %PhoenixSwagger.Schema{"$ref": "#/definitions/ValidationError"}
            )

            warnings(
              :array,
              "Validation warnings",
              items: %PhoenixSwagger.Schema{"$ref": "#/definitions/ValidationWarning"}
            )

            error_count(:integer, "Count of errors")
            warning_count(:integer, "Count of warnings")
          end

          additional_properties(false)
        end,
      ClassBundle:
        swagger_schema do
          title("Class Bundle")
          description("A bundle of classes.")

          properties do
            classes(
              :array,
              "Array of classes.",
              items: %PhoenixSwagger.Schema{"$ref": "#/definitions/Class"},
              required: true
            )

            start_time(:integer, "Earliest class time in Epoch milliseconds (OASF timestamp_t)")
            end_time(:integer, "Latest class time in Epoch milliseconds (OASF timestamp_t)")
            start_time_dt(:string, "Earliest class time in RFC 3339 format (OASF datetime_t)")
            end_time_dt(:string, "Latest class time in RFC 3339 format (OASF datetime_t)")
            count(:integer, "Count of classes")
          end

          additional_properties(false)
        end,
      ClassBundleValidation:
        swagger_schema do
          title("Class Bundle Validation")
          description("The errors and and warnings found when validating an class bundle.")

          properties do
            error(:string, "Overall error message")

            errors(
              :array,
              "Validation errors of the bundle itself",
              items: %PhoenixSwagger.Schema{type: :object}
            )

            warnings(
              :array,
              "Validation warnings of the bundle itself",
              items: %PhoenixSwagger.Schema{type: :object}
            )

            error_count(:integer, "Count of errors of the bundle itself")
            warning_count(:integer, "Count of warnings of the bundle itself")

            class_validations(
              :array,
              "Array of class validations",
              items: %PhoenixSwagger.Schema{"$ref": "#/definitions/ClassValidation"},
              required: true
            )
          end

          additional_properties(false)
        end
    }
  end

  @doc """
  Get the OASF schema version.
  """
  swagger_path :version do
    get("/api/version")
    summary("Version")
    description("Get OASF schema version.")
    produces("application/json")
    tag("Schema")
    response(200, "Success", :Version)
  end

  @spec version(Plug.Conn.t(), any) :: Plug.Conn.t()
  def version(conn, _params) do
    version = %{:version => Schema.version()}
    send_json_resp(conn, version)
  end

  @doc """
  Get available OASF schema versions.
  """
  swagger_path :versions do
    get("/api/versions")
    summary("Versions")
    description("Get available OASF schema versions.")
    produces("application/json")
    tag("Schema")
    response(200, "Success", :Versions)
  end

  @spec versions(Plug.Conn.t(), any) :: Plug.Conn.t()
  def versions(conn, _params) do
    url = Application.get_env(:schema_server, SchemaWeb.Endpoint)[:url]

    # The :url key is meant to be set for production, but isn't set for local development
    base_url =
      if url == nil do
        "#{conn.scheme}://#{conn.host}:#{conn.port}"
      else
        "#{conn.scheme}://#{Keyword.fetch!(url, :host)}:#{Keyword.fetch!(url, :port)}"
      end

    available_versions =
      Schemas.versions()
      |> Enum.map(fn {version, _} -> version end)

    default_version = %{
      :version => Schema.version(),
      :url => "#{base_url}/#{Schema.version()}/api"
    }

    versions_response =
      case available_versions do
        [] ->
          # If there is no response, we only provide a single schema
          %{:versions => [default_version], :default => default_version}

        [_head | _tail] ->
          available_versions_objects =
            available_versions
            |> Enum.map(fn version ->
              %{:version => version, :url => "#{base_url}/#{version}/api"}
            end)

          %{:versions => available_versions_objects, :default => default_version}
      end

    send_json_resp(conn, versions_response)
  end

  @doc """
  Get the schema data types.
  """
  swagger_path :data_types do
    get("/api/data_types")
    summary("Data types")
    description("Get OASF schema data types.")
    produces("application/json")
    tag("Objects and Types")
    response(200, "Success")
  end

  @spec data_types(Plug.Conn.t(), any) :: Plug.Conn.t()
  def data_types(conn, _params) do
    send_json_resp(conn, Schema.export_data_types())
  end

  @doc """
  Get the schema extensions.
  """
  swagger_path :extensions do
    get("/api/extensions")
    summary("List extensions")
    description("Get OASF schema extensions.")
    produces("application/json")
    tag("Schema")
    response(200, "Success")
  end

  @spec extensions(Plug.Conn.t(), any) :: Plug.Conn.t()
  def extensions(conn, _params) do
    extensions =
      Schema.extensions()
      |> Enum.into(%{}, fn {k, v} ->
        {k, Map.delete(v, :path)}
      end)

    send_json_resp(conn, extensions)
  end

  @doc """
  Get the schema profiles.
  """
  swagger_path :profiles do
    get("/api/profiles")
    summary("List profiles")
    description("Get OASF schema profiles.")
    produces("application/json")
    tag("Schema")
    response(200, "Success")
  end

  @spec profiles(Plug.Conn.t(), any) :: Plug.Conn.t()
  def profiles(conn, params) do
    profiles =
      Enum.into(get_profiles(params), %{}, fn {k, v} ->
        {k, Schema.delete_links(v)}
      end)

    send_json_resp(conn, profiles)
  end

  @doc """
    Returns the list of profiles.
  """
  @spec get_profiles(map) :: map
  def get_profiles(params) do
    extensions = parse_options(extensions(params))
    Schema.profiles(extensions)
  end

  @doc """
  Get a profile by name.
  get /api/profiles/:name
  get /api/profiles/:extension/:name
  """
  swagger_path :profile do
    get("/api/profiles/{name}")
    summary("Profile")

    description(
      "Get OASF schema profile by name. The profile name may contain an extension name." <>
        " For example, \"linux/linux_users\"."
    )

    produces("application/json")
    tag("Schema")

    parameters do
      name(:path, :string, "Profile name", required: true)
    end

    response(200, "Success")
    response(404, "Profile <code>name</code> not found")
  end

  @spec profile(Plug.Conn.t(), map) :: Plug.Conn.t()
  def profile(conn, %{"id" => id} = params) do
    name =
      case params["extension"] do
        nil -> id
        extension -> "#{extension}/#{id}"
      end

    data = Schema.profiles()

    case Map.get(data, name) do
      nil ->
        send_json_resp(conn, 404, %{error: "Profile #{name} not found"})

      profile ->
        send_json_resp(conn, Schema.delete_links(profile))
    end
  end

  @doc """
  Get the schema categories.
  """
  swagger_path :categories do
    get("/api/categories")
    summary("List categories")
    description("Get OASF schema categories.")
    produces("application/json")
    tag("Categories and Classes")

    parameters do
      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
  end

  @doc """
  Returns the list of categories.
  """
  @spec categories(Plug.Conn.t(), map) :: Plug.Conn.t()
  def categories(conn, params) do
    send_json_resp(conn, categories(params))
  end

  @spec categories(map()) :: map()
  def categories(params) do
    parse_options(extensions(params)) |> Schema.categories()
  end

  @doc """
  Get the classes defined in a given category.
  """
  swagger_path :category do
    get("/api/categories/{name}")
    summary("List category classes")

    description(
      "Get OASF schema classes defined in the named category. The category name may contain an" <>
        " extension name. For example, \"dev/policy\"."
    )

    produces("application/json")
    tag("Categories and Classes")

    parameters do
      name(:path, :string, "Category name", required: true)

      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
    response(404, "Category <code>name</code> not found")
  end

  @spec category(Plug.Conn.t(), map) :: Plug.Conn.t()
  def category(conn, %{"id" => id} = params) do
    case category_classes(params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Category #{id} not found"})

      data ->
        send_json_resp(conn, data)
    end
  end

  @spec category_classes(map()) :: map() | nil
  def category_classes(params) do
    name = params["id"]
    extension = extension(params)
    extensions = parse_options(extensions(params))

    Schema.category(extensions, extension, name)
  end

  @doc """
  Get the schema main skills.
  """
  swagger_path :main_skills do
    get("/api/main_skills")
    summary("List main skills")
    description("Get OASF schema main skills.")
    produces("application/json")
    tag("skills")

    parameters do
      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
  end

  @doc """
  Returns the list of main skills.
  """
  @spec main_skills(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_skills(conn, params) do
    send_json_resp(conn, main_skills(params))
  end

  @spec main_skills(map()) :: map()
  def main_skills(params) do
    parse_options(extensions(params)) |> Schema.main_skills()
  end

  @doc """
  Get the skills defined in a given main skill.
  """
  swagger_path :main_skill do
    get("/api/main_skills/{name}")
    summary("List sub skills of main skill")

    description(
      "Get OASF schema skills defined in the named main skill. The main skill name may contain an" <>
        " extension name. For example, \"dev/policy\"."
    )

    produces("application/json")
    tag("skills")

    parameters do
      name(:path, :string, "Main skill name", required: true)

      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
    response(404, "Main skill <code>name</code> not found")
  end

  @spec main_skill(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_skill(conn, %{"id" => id} = params) do
    case main_skill_skills(params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Main skill #{id} not found"})

      data ->
        send_json_resp(conn, data)
    end
  end

  @spec main_skill_skills(map()) :: map() | nil
  def main_skill_skills(params) do
    name = params["id"]
    extension = extension(params)
    extensions = parse_options(extensions(params))

    Schema.main_skill(extensions, extension, name)
  end

  @doc """
  Get the schema main domains.
  """
  swagger_path :main_domains do
    get("/api/main_domains")
    summary("List main domains")
    description("Get OASF schema main domains.")
    produces("application/json")
    tag("Domains")

    parameters do
      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
  end

  @doc """
  Returns the list of main domains.
  """
  @spec main_domains(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_domains(conn, params) do
    send_json_resp(conn, main_domains(params))
  end

  @spec main_domains(map()) :: map()
  def main_domains(params) do
    parse_options(extensions(params)) |> Schema.main_domains()
  end

  @doc """
  Get the domains defined in a given main domain.
  """
  swagger_path :main_domain do
    get("/api/main_domains/{name}")
    summary("List sub domains of main domain")

    description(
      "Get OASF schema domains defined in the named main domain. The main domain name may contain an" <>
        " extension name. For example, \"dev/policy\"."
    )

    produces("application/json")
    tag("Domains")

    parameters do
      name(:path, :string, "Main domain name", required: true)

      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
    response(404, "Main domain <code>name</code> not found")
  end

  @spec main_domain(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_domain(conn, %{"id" => id} = params) do
    case main_domain_domains(params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Main domain #{id} not found"})

      data ->
        send_json_resp(conn, data)
    end
  end

  @spec main_domain_domains(map()) :: map() | nil
  def main_domain_domains(params) do
    name = params["id"]
    extension = extension(params)
    extensions = parse_options(extensions(params))

    Schema.main_domain(extensions, extension, name)
  end

  @doc """
  Get the schema main features.
  """
  swagger_path :main_features do
    get("/api/main_features")
    summary("List main features")
    description("Get OASF schema main features.")
    produces("application/json")
    tag("Features")

    parameters do
      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
  end

  @doc """
  Returns the list of main features.
  """
  @spec main_features(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_features(conn, params) do
    send_json_resp(conn, main_features(params))
  end

  @spec main_features(map()) :: map()
  def main_features(params) do
    parse_options(extensions(params)) |> Schema.main_features()
  end

  @doc """
  Get the features defined in a given main feature.
  """
  swagger_path :main_feature do
    get("/api/main_features/{name}")
    summary("List sub features of main feature")

    description(
      "Get OASF schema features defined in the named main feature. The main feature name may contain an" <>
      " extension name. For example, \"dev/policy\"."
    )

    produces("application/json")
    tag("Features")

    parameters do
      name(:path, :string, "Main feature name", required: true)

      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
    response(404, "Main feature <code>name</code> not found")
  end

  @spec main_feature(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_feature(conn, %{"id" => id} = params) do
    case main_feature_features(params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Main feature #{id} not found"})

      data ->
        send_json_resp(conn, data)
    end
  end

  @spec main_feature_features(map()) :: map() | nil
  def main_feature_features(params) do
    name = params["id"]
    extension = extension(params)
    extensions = parse_options(extensions(params))

    Schema.main_feature(extensions, extension, name)
  end

  @doc """
  Get the schema dictionary.
  """
  swagger_path :dictionary do
    get("/api/dictionary")
    summary("Dictionary")
    description("Get OASF schema dictionary.")
    produces("application/json")
    tag("Dictionary")

    parameters do
      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
  end

  @spec dictionary(Plug.Conn.t(), any) :: Plug.Conn.t()
  def dictionary(conn, params) do
    data = dictionary(params) |> remove_links(:attributes)

    send_json_resp(conn, data)
  end

  @doc """
  Renders the dictionary.
  """
  @spec dictionary(map) :: map
  def dictionary(params) do
    parse_options(extensions(params)) |> Schema.dictionary()
  end

  @doc """
  Get the schema base class.
  """
  swagger_path :base_class do
    get("/api/base_class")
    summary("Base class")
    description("Get OASF schema base class.")
    produces("application/json")
    tag("Categories and Classes")

    parameters do
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
  end

  @spec base_class(Plug.Conn.t(), any) :: Plug.Conn.t()
  def base_class(conn, params) do
    class(conn, "base_class", params)
  end

  @doc """
  Get an class by name.
  get /api/classes/:name
  """
  swagger_path :class do
    get("/api/classes/{name}")
    summary("Class")

    description(
      "Get OASF schema class by name. The class name may contain an extension name." <>
        " For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("Categories and Classes")

    parameters do
      name(:path, :string, "Class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Class <code>name</code> not found")
  end

  @spec class(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def class(conn, %{"id" => id} = params) do
    class(conn, id, params)
  end

  defp class(conn, id, params) do
    extension = extension(params)

    case Schema.class(extension, id, parse_options(profiles(params))) do
      nil ->
        send_json_resp(conn, 404, %{error: "Class #{id} not found"})

      data ->
        class = add_objects(data, params)
        send_json_resp(conn, class)
    end
  end

  @doc """
  Get the schema classes.
  """
  swagger_path :classes do
    get("/api/classes")
    summary("List classes")
    description("Get OASF schema classes.")
    produces("application/json")
    tag("Categories and Classes")

    parameters do
      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success", :ClassDesc)
  end

  @spec classes(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def classes(conn, params) do
    classes =
      Enum.map(classes(params), fn {_name, class} ->
        Schema.reduce_class(class)
      end)

    send_json_resp(conn, classes)
  end

  @doc """
  Returns the list of classes.
  """
  @spec classes(map) :: map
  def classes(params) do
    extensions = parse_options(extensions(params))

    case parse_options(profiles(params)) do
      nil ->
        Schema.classes(extensions)

      profiles ->
        Schema.classes(extensions, profiles)
    end
  end

  @doc """
  Get a skill by name.
  get /api/skills/:name
  """
  swagger_path :skill do
    get("/api/skills/{name}")
    summary("skill")

    description(
      "Get OASF schema skill by name. The skill name may contain an extension name." <>
        " For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("skills")

    parameters do
      name(:path, :string, "skill name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "skill <code>name</code> not found")
  end

  @spec skill(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def skill(conn, %{"id" => id} = params) do
    skill(conn, id, params)
  end

  defp skill(conn, id, params) do
    extension = extension(params)

    case Schema.skill(extension, id, parse_options(profiles(params))) do
      nil ->
        send_json_resp(conn, 404, %{error: "skill #{id} not found"})

      data ->
        skill = add_objects(data, params)
        send_json_resp(conn, skill)
    end
  end

  @doc """
  Get the schema skill.
  """
  swagger_path :skills do
    get("/api/skills")
    summary("List skills")
    description("Get OASF schema skills.")
    produces("application/json")
    tag("skills")

    parameters do
      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success", :skillDesc)
  end

  @spec skills(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def skills(conn, params) do
    skills =
      Enum.map(skills(params), fn {_name, skill} ->
        Schema.reduce_class(skill)
      end)

    send_json_resp(conn, skills)
  end

  @doc """
  Returns the list of skills.
  """
  @spec skills(map) :: map
  def skills(params) do
    extensions = parse_options(extensions(params))

    case parse_options(profiles(params)) do
      nil ->
        Schema.skills(extensions)

      profiles ->
        Schema.skills(extensions, profiles)
    end
  end

  @doc """
  Get a domain by name.
  get /api/domains/:name
  """
  swagger_path :domain do
    get("/api/domains/{name}")
    summary("Domain")

    description(
      "Get OASF schema domain by name. The domain name may contain an extension name." <>
        " For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("Domains")

    parameters do
      name(:path, :string, "Domain name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Domain <code>name</code> not found")
  end

  @spec domain(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def domain(conn, %{"id" => id} = params) do
    domain(conn, id, params)
  end

  defp domain(conn, id, params) do
    extension = extension(params)

    case Schema.domain(extension, id, parse_options(profiles(params))) do
      nil ->
        send_json_resp(conn, 404, %{error: "Domain #{id} not found"})

      data ->
        domain = add_objects(data, params)
        send_json_resp(conn, domain)
    end
  end

  @doc """
  Get the schema domain.
  """
  swagger_path :domains do
    get("/api/domains")
    summary("List domains")
    description("Get OASF schema domains.")
    produces("application/json")
    tag("Domains")

    parameters do
      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success", :DomainDesc)
  end

  @spec domains(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def domains(conn, params) do
    domains =
      Enum.map(domains(params), fn {_name, domain} ->
        Schema.reduce_class(domain)
      end)

    send_json_resp(conn, domains)
  end

  @doc """
  Returns the list of domains.
  """
  @spec domains(map) :: map
  def domains(params) do
    extensions = parse_options(extensions(params))

    case parse_options(profiles(params)) do
      nil ->
        Schema.domains(extensions)

      profiles ->
        Schema.domains(extensions, profiles)
    end
  end

  @doc """
  Get a feature by name.
  get /api/features/:name
  """
  swagger_path :feature do
    get("/api/features/{name}")
    summary("Feature")

    description(
      "Get OASF schema feature by name. The feature name may contain an extension name." <>
      " For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("Features")

    parameters do
      name(:path, :string, "Feature name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Feature <code>name</code> not found")
  end

  @spec feature(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def feature(conn, %{"id" => id} = params) do
    feature(conn, id, params)
  end

  defp feature(conn, id, params) do
    extension = extension(params)

    case Schema.feature(extension, id, parse_options(profiles(params))) do
      nil ->
        send_json_resp(conn, 404, %{error: "Feature #{id} not found"})

      data ->
        feature = add_objects(data, params)
        send_json_resp(conn, feature)
    end
  end

  @doc """
  Get the schema feature.
  """
  swagger_path :features do
    get("/api/features")
    summary("List features")
    description("Get OASF schema features.")
    produces("application/json")
    tag("Features")

    parameters do
      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success", :FeatureDesc)
  end

  @spec features(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def features(conn, params) do
    features =
      Enum.map(features(params), fn {_name, feature} ->
        Schema.reduce_class(feature)
      end)

    send_json_resp(conn, features)
  end

  @doc """
  Returns the list of features.
  """
  @spec features(map) :: map
  def features(params) do
    extensions = parse_options(extensions(params))

    case parse_options(profiles(params)) do
      nil ->
        Schema.features(extensions)

      profiles ->
        Schema.features(extensions, profiles)
    end
  end

  @doc """
  Get an object by name.
  get /api/objects/:name
  get /api/objects/:extension/:name
  """
  swagger_path :object do
    get("/api/objects/{name}")
    summary("Object")

    description(
      "Get OASF schema object by name. The object name may contain an extension name." <>
        " For example, \"dev/os_service\"."
    )

    produces("application/json")
    tag("Objects and Types")

    parameters do
      name(:path, :string, "Object name", required: true)

      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Object <code>name</code> not found")
  end

  @spec object(Plug.Conn.t(), map) :: Plug.Conn.t()
  def object(conn, %{"id" => id} = params) do
    case object(params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Object #{id} not found"})

      data ->
        send_json_resp(conn, add_objects(data, params))
    end
  end

  @doc """
  Get the schema objects.
  """
  swagger_path :objects do
    get("/api/objects")
    summary("List objects")
    description("Get OASF schema objects.")
    produces("application/json")
    tag("Objects and Types")

    parameters do
      extensions(:query, :array, "Related extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success", :ObjectDesc)
  end

  @spec objects(Plug.Conn.t(), map) :: Plug.Conn.t()
  def objects(conn, params) do
    objects =
      Enum.map(objects(params), fn {_name, map} ->
        Map.delete(map, :_links) |> Schema.delete_attributes()
      end)

    send_json_resp(conn, objects)
  end

  @spec objects(map) :: map
  def objects(params) do
    parse_options(extensions(params)) |> Schema.objects()
  end

  @spec object(map) :: map() | nil
  def object(%{"id" => id} = params) do
    profiles = parse_options(profiles(params))
    extension = extension(params)
    extensions = parse_options(extensions(params))

    Schema.object(extensions, extension, id, profiles)
  end

  # -------------------
  # Schema Export API's
  # -------------------

  @doc """
  Export the OASF schema definitions.
  """
  swagger_path :export_schema do
    get("/export/schema")
    summary("Export schema")

    description(
      "Get OASF schema definitions, including data types, objects, classes," <>
        " and the dictionary of attributes."
    )

    produces("application/json")
    tag("Schema Export")

    parameters do
      extensions(:query, :array, @extensions_param_description, items: [type: :string])
      profiles(:query, :array, @profiles_param_description, items: [type: :string])
    end

    response(200, "Success")
  end

  @spec export_schema(Plug.Conn.t(), any) :: Plug.Conn.t()
  def export_schema(conn, params) do
    profiles = parse_options(profiles(params))
    extensions = parse_options(extensions(params))
    data = Schema.export_schema(extensions, profiles)
    send_json_resp(conn, data)
  end

  @doc """
  Export the OASF schema classes.
  """
  swagger_path :export_classes do
    get("/export/classes")
    summary("Export classes")
    description("Get OASF schema classes.")
    produces("application/json")
    tag("Schema Export")

    parameters do
      extensions(:query, :array, @extensions_param_description, items: [type: :string])
      profiles(:query, :array, @profiles_param_description, items: [type: :string])
    end

    response(200, "Success")
  end

  def export_classes(conn, params) do
    profiles = parse_options(profiles(params))
    extensions = parse_options(extensions(params))
    classes = Schema.export_classes(extensions, profiles)
    send_json_resp(conn, classes)
  end

  @doc """
  Export the OASF base  class.
  """
  swagger_path :export_base_class do
    get("/export/base_class")
    summary("Export base class")
    description("Get OASF schema base class.")
    produces("application/json")
    tag("Schema Export")

    parameters do
      profiles(:query, :array, @profiles_param_description, items: [type: :string])
    end

    response(200, "Success")
  end

  def export_base_class(conn, params) do
    profiles = parse_options(profiles(params))
    base_class = Schema.export_base_class(profiles)

    send_json_resp(conn, base_class)
  end

  @doc """
  Export the OASF schema objects.
  """
  swagger_path :export_objects do
    get("/export/objects")
    summary("Export objects")
    description("Get OASF schema objects.")
    produces("application/json")
    tag("Schema Export")

    parameters do
      extensions(:query, :array, @extensions_param_description, items: [type: :string])
      profiles(:query, :array, @profiles_param_description, items: [type: :string])
    end

    response(200, "Success")
  end

  def export_objects(conn, params) do
    profiles = parse_options(profiles(params))
    extensions = parse_options(extensions(params))
    objects = Schema.export_objects(extensions, profiles)
    send_json_resp(conn, objects)
  end

  # -----------------
  # JSON Schema API's
  # -----------------

  @doc """
  Get JSON schema definitions for a given class.
  get /schema/classes/:name
  """
  swagger_path :json_class do
    get("/schema/classes/{name}")
    summary("Class")

    description(
      "Get OASF schema class by name, using JSON schema Draft-07 format " <>
        "(see http://json-schema.org). The class name may contain an extension name. " <>
        "For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("JSON Schema")

    parameters do
      name(:path, :string, "Class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
      package_name(:query, :string, "Java package name")
    end

    response(200, "Success")
    response(404, "Class <code>name</code> not found")
  end

  @spec json_class(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def json_class(conn, %{"id" => id} = params) do
    options = Map.get(params, "package_name") |> parse_java_package()

    case class_ex(id, params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Class #{id} not found"})

      data ->
        class = Schema.JsonSchema.encode(data, options)
        send_json_resp(conn, class)
    end
  end

  def class_ex(id, params) do
    extension = extension(params)
    Schema.class_ex(extension, id, parse_options(profiles(params)))
  end

  @doc """
  Get JSON schema definitions for a given class object.
  get /schema/classes/:name
  """
  swagger_path :json_object do
    get("/schema/objects/{name}")
    summary("Object")

    description(
      "Get OASF object by name, using JSON schema Draft-07 format (see http://json-schema.org)." <>
        " The object name may contain an extension name. For example, \"dev/printer\"."
    )

    produces("application/json")
    tag("JSON Schema")

    parameters do
      name(:path, :string, "Object name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
      package_name(:query, :string, "Java package name")
    end

    response(200, "Success")
    response(404, "Object <code>name</code> not found")
  end

  @spec json_object(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def json_object(conn, %{"id" => id} = params) do
    options = Map.get(params, "package_name") |> parse_java_package()

    case object_ex(id, params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Object #{id} not found"})

      data ->
        object = Schema.JsonSchema.encode(data, options)
        send_json_resp(conn, object)
    end
  end

  def object_ex(id, params) do
    profiles = parse_options(profiles(params))
    extension = extension(params)
    extensions = parse_options(extensions(params))

    Schema.object_ex(extensions, extension, id, profiles)
  end

  # ---------------------------------------------
  # Enrichment, validation, and translation API's
  # ---------------------------------------------

  @doc """
  Enrich class data by adding type_uid, enumerated text, and observables.
  A single class is encoded as a JSON object and multiple classes are encoded as JSON array of
  objects.
  """
  swagger_path :enrich do
    post("/api/enrich")
    summary("Enrich Class")

    description(
      "The purpose of this API is to enrich the provided class data with <code>type_uid</code>," <>
        " enumerated text, and <code>observables</code> array. Each class is represented as a" <>
        " JSON object, while multiple classes are encoded as a JSON array of objects."
    )

    produces("application/json")
    tag("Tools")

    parameters do
      _enum_text(
        :query,
        :boolean,
        """
        Enhance the class data by adding the enumerated text values.<br/>

        |Value|Example|
        |-----|-------|
        |true|Untranslated:<br/><code>{"category_uid":0,"class_uid":0,"activity_id": 0,"severity_id": 5,"status": "Something else","status_id": 99,"time": 1689125893360905}</code><br/><br/>Translated:<br/><code>{"activity_name": "Unknown", "activity_id": 0, "category_name": "Uncategorized", "category_uid": 0, "class_name": "Base Class", "class_uid": 0, "severity": "Critical", "severity_id": 5, "status": "Something else", "status_id": 99, "time": 1689125893360905, "type_name": "Base Class: Unknown", "type_uid": 0}</code>|
        """,
        default: false
      )

      _observables(
        :query,
        :boolean,
        "<strong>TODO</strong>: Enhance the class data by adding the observables associated with" <>
          " the class.",
        default: false
      )

      data(:body, PhoenixSwagger.Schema.ref(:Class), "The class data to be enriched.",
        required: true
      )
    end

    response(200, "Success")
  end

  @spec enrich(Plug.Conn.t(), map) :: Plug.Conn.t()
  def enrich(conn, params) do
    enum_text = conn.query_params[@enum_text]
    observables = conn.query_params[@observables]

    {status, result} =
      case params["_json"] do
        # Enrich a single class
        class when is_map(class) ->
          {200, Schema.enrich(class, enum_text, observables)}

        # Enrich a list of classes
        list when is_list(list) ->
          {200,
           Enum.map(list, &Task.async(fn -> Schema.enrich(&1, enum_text, observables) end))
           |> Enum.map(&Task.await/1)}

        # something other than json data
        _ ->
          {400, %{error: "Unexpected body. Expected a JSON object or array."}}
      end

    send_json_resp(conn, status, result)
  end

  @doc """
  Translate class data. A single class is encoded as a JSON object and multiple classes are encoded as JSON array of objects.
  """
  swagger_path :translate do
    post("/api/translate")
    summary("Translate Class")

    description(
      "The purpose of this API is to translate the provided class data using the OASF schema." <>
        " Each class is represented as a JSON object, while multiple classes are encoded as a" <>
        "  JSON array of objects."
    )

    produces("application/json")
    tag("Tools")

    parameters do
      _mode(
        :query,
        :number,
        """
        Controls how attribute names and enumerated values are translated.<br/>
        The format is _mode=[1|2|3]. The default mode is `1` -- translate enumerated values.

        |Value|Description|Example|
        |-----|-----------|-------|
        |1|Translate only the enumerated values|Untranslated:<br/><code>{"class_uid": 1000}</code><br/><br/>Translated:<br/><code>{"class_name": File Activity", "class_uid": 1000}</code>|
        |2|Translate enumerated values and attribute names|Untranslated:<br/><code>{"class_uid": 1000}</code><br/><br/>Translated:<br/><code>{"Class": File Activity", "Class ID": 1000}</code>|
        |3|Verbose translation|Untranslated:<br/><code>{"class_uid": 1000}</code><br/><br/>Translated:<br/><code>{"class_uid": {"caption": "File Activity","name": "Class ID","type": "integer_t","value": 1000}}</code>|
        """,
        default: 1
      )

      _spaces(
        :query,
        :string,
        """
          Controls how spaces in the translated attribute names are handled.<br/>
          By default, the translated attribute names may contain spaces (for example, Class Time).
          You can remove the spaces or replace the spaces with another string. For example, if you
          want to forward to a database that does not support spaces.<br/>
          The format is _spaces=[&lt;empty&gt;|string].

          |Value|Description|Example|
          |-----|-----------|-------|
          |&lt;empty&gt;|The spaces in the translated names are removed.|Untranslated:<br/><code>{"class_uid": 1000}</code><br/><br/>Translated:<br/><code>{"ClassID": File Activity"}</code>|
          |string|The spaces in the translated names are replaced with the given string.|For example, the string is an underscore (_).<br/>Untranslated:<br/><code>{"class_uid": 1000}</code><br/><br/>Translated:<br/><code>{"Class_ID": File Activity"}</code>|
        """,
        allowEmptyValue: true
      )

      data(:body, PhoenixSwagger.Schema.ref(:Class), "The class data to be translated",
        required: true
      )
    end

    response(200, "Success")
  end

  @spec translate(Plug.Conn.t(), map) :: Plug.Conn.t()
  def translate(conn, params) do
    options = [spaces: conn.query_params[@spaces], verbose: verbose(conn.query_params[@verbose])]

    {status, result} =
      case params["_json"] do
        # Translate a single classes
        class when is_map(class) ->
          {200, Schema.Translator.translate(class, options)}

        # Translate a list of classes
        list when is_list(list) ->
          {200, Enum.map(list, fn class -> Schema.Translator.translate(class, options) end)}

        # some other json data
        _ ->
          {400, %{error: "Unexpected body. Expected a JSON object or array."}}
      end

    send_json_resp(conn, status, result)
  end

  @doc """
  Validate class data.
  A single class is encoded as a JSON object and multiple classes are encoded as JSON array of
  object.
  post /api/validate
  """
  swagger_path :validate do
    post("/api/validate")
    summary("Validate Class")

    description(
      "The primary objective of this API is to validate the provided class data against the OASF" <>
        " schema. Each class is represented as a JSON object, while multiple classes are encoded" <>
        " as a JSON array of objects."
    )

    produces("application/json")
    tag("Tools")

    parameters do
      data(:body, PhoenixSwagger.Schema.ref(:Class), "The class data to be validated",
        required: true
      )
    end

    response(200, "Success")
  end

  @spec validate(Plug.Conn.t(), map) :: Plug.Conn.t()
  def validate(conn, params) do
    {status, result} =
      case params["_json"] do
        # Validate a single classes
        class when is_map(class) ->
          {200, Schema.Validator.validate(class)}

        # Validate a list of classes
        list when is_list(list) ->
          {200,
           Enum.map(list, &Task.async(fn -> Schema.Validator.validate(&1) end))
           |> Enum.map(&Task.await/1)}

        # some other json data
        _ ->
          {400, %{error: "Unexpected body. Expected a JSON object or array."}}
      end

    send_json_resp(conn, status, result)
  end

  @doc """
  Validate class data, version 2. Validates a single class.
  post /api/v2/validate
  """
  swagger_path :validate2 do
    post("/api/v2/validate")
    summary("Validate Class (version 2)")

    description(
      "This API validates the provided class data against the OASF schema, returning a response" <>
        " containing validation errors and warnings."
    )

    produces("application/json")
    tag("Tools")

    parameters do
      missing_recommended(
        :query,
        :boolean,
        """
        When true, warnings are created for missing recommended attributes, otherwise recommended attributes are treated the same as optional.
        """,
        default: false
      )

      data(:body, PhoenixSwagger.Schema.ref(:Class), "The class to be validated", required: true)
    end

    response(200, "Success", PhoenixSwagger.Schema.ref(:ClassValidation))
  end

  @spec validate2(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def validate2(conn, params) do
    warn_on_missing_recommended =
      case conn.query_params["missing_recommended"] do
        "true" -> true
        _ -> false
      end

    # We've configured Plug.Parsers / Plug.Parsers.JSON to always nest JSON in the _json key in
    # endpoint.ex.
    {status, result} = validate2_actual(params["_json"], warn_on_missing_recommended)

    send_json_resp(conn, status, result)
  end

  defp validate2_actual(class, warn_on_missing_recommended) when is_map(class) do
    {200, Schema.Validator2.validate(class, warn_on_missing_recommended)}
  end

  defp validate2_actual(_, _) do
    {400, %{error: "Unexpected body. Expected a JSON object."}}
  end

  @doc """
  Validate class data, version 2. Validates a single class.
  post /api/v2/validate
  """
  swagger_path :validate2_bundle do
    post("/api/v2/validate_bundle")
    summary("Validate Class Bundle (version 2)")

    description(
      "This API validates the provided class bundle. The class bundle itself is validated, and" <>
        " each class in the bundle's classes attribute are validated."
    )

    produces("application/json")
    tag("Tools")

    parameters do
      missing_recommended(
        :query,
        :boolean,
        """
        When true, warnings are created for missing recommended attributes, otherwise recommended attributes are treated the same as optional.
        """,
        default: false
      )

      data(:body, PhoenixSwagger.Schema.ref(:ClassBundle), "The class bundle to be validated",
        required: true
      )
    end

    response(200, "Success", PhoenixSwagger.Schema.ref(:ClassBundleValidation))
  end

  @spec validate2_bundle(Plug.Conn.t(), map) :: Plug.Conn.t()
  def validate2_bundle(conn, params) do
    warn_on_missing_recommended =
      case conn.query_params["missing_recommended"] do
        "true" -> true
        _ -> false
      end

    # We've configured Plug.Parsers / Plug.Parsers.JSON to always nest JSON in the _json key in
    # endpoint.ex.
    {status, result} = validate2_bundle_actual(params["_json"], warn_on_missing_recommended)

    send_json_resp(conn, status, result)
  end

  defp validate2_bundle_actual(bundle, warn_on_missing_recommended) when is_map(bundle) do
    {200, Schema.Validator2.validate_bundle(bundle, warn_on_missing_recommended)}
  end

  defp validate2_bundle_actual(_, _) do
    {400, %{error: "Unexpected body. Expected a JSON object."}}
  end

  # --------------------------
  # Request sample data API's
  # --------------------------

  @doc """
  Returns randomly generated class sample data for the base class.
  """
  swagger_path :sample_base_class do
    get("/sample/base_class")
    summary("Base sample data")
    description("This API returns randomly generated sample data for the base class.")
    produces("application/json")
    tag("Sample Data")

    parameters do
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
  end

  @spec sample_base_class(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sample_base_class(conn, params) do
    sample_class(conn, "base_class", params)
  end

  @doc """
  Returns randomly generated class sample data for the given name.
  get /sample/classes/:name
  get /sample/classes/:extension/:name
  """
  swagger_path :sample_class do
    get("/sample/classes/{name}")
    summary("Class sample data")

    description(
      "This API returns randomly generated sample data for the given class name. The class" <>
        " name may contain an extension name. For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("Sample Data")

    parameters do
      name(:path, :string, "Class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Class <code>name</code> not found")
  end

  @spec sample_class(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sample_class(conn, %{"id" => id} = params) do
    sample_class(conn, id, params)
  end

  defp sample_class(conn, id, options) do
    # TODO: honor constraints

    extension = extension(options)
    profiles = profiles(options) |> parse_options()

    case Schema.class(extension, id) do
      nil ->
        send_json_resp(conn, 404, %{error: "Class #{id} not found"})

      class ->
        class =
          case Map.get(options, @verbose) do
            nil ->
              Schema.generate_class(class, profiles)

            verbose ->
              Schema.generate_class(class, profiles)
              |> Schema.Translator.translate(
                spaces: options[@spaces],
                verbose: verbose(verbose)
              )
          end

        send_json_resp(conn, class)
    end
  end

  @doc """
  Returns randomly generated object sample data for the given name.
  get /sample/objects/:name
  get /sample/objects/:extension/:name
  """
  swagger_path :sample_object do
    get("/sample/objects/{name}")
    summary("Object sample data")

    description(
      "This API returns randomly generated sample data for the given object name. The object" <>
        " name may contain an extension name. For example, \"dev/os_service\"."
    )

    produces("application/json")
    tag("Sample Data")

    parameters do
      name(:path, :string, "Object name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Object <code>name</code> not found")
  end

  @spec sample_object(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sample_object(conn, %{"id" => id} = options) do
    # TODO: honor constraints

    extension = extension(options)
    profiles = profiles(options) |> parse_options()

    case Schema.object(extension, id) do
      nil ->
        send_json_resp(conn, 404, %{error: "Object #{id} not found"})

      data ->
        send_json_resp(conn, Schema.generate_object(data, profiles))
    end
  end

  defp send_json_resp(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> put_resp_header("access-control-allow-methods", "POST, GET, OPTIONS")
    |> send_resp(status, Jason.encode!(data))
  end

  defp send_json_resp(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> put_resp_header("access-control-allow-methods", "POST, GET, OPTIONS")
    |> send_resp(200, Jason.encode!(data))
  end

  defp remove_links(data) do
    data
    |> Schema.delete_links()
    |> remove_links(:attributes)
  end

  defp remove_links(data, key) do
    case data[key] do
      nil ->
        data

      list ->
        updated =
          Enum.map(list, fn {k, v} ->
            %{k => Schema.delete_links(v)}
          end)

        Map.put(data, key, updated)
    end
  end

  defp add_objects(data, %{"objects" => "1"}) do
    objects = update_objects(Map.new(), data[:attributes])

    if map_size(objects) > 0 do
      Map.put(data, :objects, objects)
    else
      data
    end
    |> remove_links()
  end

  defp add_objects(data, _params) do
    remove_links(data)
  end

  defp update_objects(objects, attributes) do
    Enum.reduce(attributes, objects, fn {_name, field}, acc ->
      update_object(field, acc)
    end)
  end

  defp update_object(field, acc) do
    case field[:type] do
      "object_t" ->
        type = field[:object_type] |> String.to_existing_atom()

        if Map.has_key?(acc, type) do
          acc
        else
          object = Schema.object(type)
          Map.put(acc, type, remove_links(object)) |> update_objects(object[:attributes])
        end

      _other ->
        acc
    end
  end

  defp verbose(option) when is_binary(option) do
    case Integer.parse(option) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp verbose(_), do: 1

  defp profiles(params), do: params["profiles"]
  defp extension(params), do: params["extension"]
  defp extensions(params), do: params["extensions"]

  defp parse_options(nil), do: nil
  defp parse_options(""), do: MapSet.new()

  defp parse_options(options) do
    options
    |> String.split(",")
    |> Enum.map(fn s -> String.trim(s) end)
    |> MapSet.new()
  end

  defp parse_java_package(nil), do: []
  defp parse_java_package(""), do: []
  defp parse_java_package(name), do: [package_name: name]
end
