# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.SchemaController do
  @moduledoc """
  The Class Schema API.
  """

  use SchemaWeb, :controller

  import PhoenixSwagger

  @verbose "_mode"
  @spaces "_spaces"
  @missing_recommended "missing_recommended"

  @extensions_param_description "When included in request, filters response to included only the" <>
                                  " supplied schema extensions, or no extensions if this parameter has" <>
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
      SkillDesc:
        swagger_schema do
          title("Skill Class Descriptor")
          description("Schema skill class descriptor.")
          type(:object)

          properties do
            name(:string, "Skill class name", required: true)
            family(:string, "Skill class family", required: true)
            caption(:string, "Skill class caption", required: true)
            description(:string, "Skill class description", required: true)
            category(:string, "Skill class category", required: true)
            category_name(:string, "Skill class category caption", required: true)
            profiles(:array, "Skill class profiles", items: %PhoenixSwagger.Schema{type: :string})
            uid(:integer, "Skill class unique identifier", required: true)
          end

          example([
            %{
              name: "problem_solving",
              family: "skill",
              description:
                "Assisting with solving problems by generating potential solutions or strategies.",
              category: "nlp",
              extends: "analytical_reasoning",
              uid: 10702,
              caption: "Problem Solving",
              category_name: "Natural Language Processing",
            }
          ])
        end,
      SkillsDesc:
        swagger_schema do
          title("Skill Class Descriptors")
          description("A collection of Skill Class Descriptors.")
          type(:array)
          items(Schema.ref(:SkillDesc))

          example([
            %{
              name: "question_generation",
              family: "skill",
              description:
                "Automatically generating relevant and meaningful questions from a given text or context.",
              category: "nlp",
              extends: "natural_language_generation",
              uid: 10205,
              caption: "Question Generation",
              category_name: "Natural Language Processing",
            },
            %{
              name: "speech_recognition",
              family: "skill",
              description: "Converting spoken language into written text.",
              category: "multi_modal",
              extends: "audio_processing",
              uid: 70202,
              caption: "Automatic Speech Recognition",
              category_name: "Multi-modal",
            },
            %{
              name: "dialogue_generation",
              family: "skill",
              description:
                "Producing conversational responses that are contextually relevant and engaging within a dialogue context.",
              category: "nlp",
              extends: "natural_language_generation",
              uid: 10204,
              caption: "Dialogue Generation",
              category_name: "Natural Language Processing",
            }
          ])
        end,
      DomainDesc:
        swagger_schema do
          title("Domain Class Descriptor")
          description("Schema domain class descriptor.")

          properties do
            name(:string, "Domain class name", required: true)
            family(:string, "Domain class family", required: true)
            caption(:string, "Domain class caption", required: true)
            description(:string, "Domain class description", required: true)
            category(:string, "Domain class category", required: true)
            category_name(:string, "Domain class category caption", required: true)

            profiles(:array, "Domain class profiles",
              items: %PhoenixSwagger.Schema{type: :string}
            )

            uid(:integer, "Domain class unique identifier", required: true)
          end

          example([
            %{
              name: "information_technology",
              family: "domain",
              description:
                "All aspects of managing and supporting technology systems and infrastructure.",
              category: "technology",
              extends: "technology",
              uid: 106,
              caption: "Information Technology",
              category_name: "Technology",
            }
          ])
        end,
      DomainsDesc:
        swagger_schema do
          title("Domain Class Descriptors")
          description("A collection of Domain Class Descriptors.")
          type(:array)
          items(Schema.ref(:DomainDesc))

          example([
            %{
              name: "process_engineering",
              family: "domain",
              description:
                "Designing, implementing, and optimizing industrial processes to improve efficiency and quality. Subdomains: Process Design, Process Optimization, Quality Control, and Safety Engineering.",
              category: "industrial_manufacturing",
              extends: "industrial_manufacturing",
              uid: 705,
              caption: "Process Engineering",
              category_name: "Industrial Manufacturing",
            },
            %{
              name: "data_privacy",
              family: "domain",
              description:
                "Safeguarding personal information from unauthorized access and ensuring compliance with privacy laws and regulations. Subdomains: Privacy Regulations Compliance, Data Encryption, Data Anonymization, and User Consent Management.",
              category: "trust_and_safety",
              extends: "trust_and_safety",
              uid: 404,
              caption: "Data Privacy",
              category_name: "Trust and Safety",
            },
            %{
              name: "robotics",
              family: "domain",
              description:
                "Designing and using robots for manufacturing tasks to enhance productivity and precision. Subdomains: Robotic Process Automation, Industrial Robotics, AI and Robotics, and Collaborative Robots.",
              category: "industrial_manufacturing",
              extends: "industrial_manufacturing",
              uid: 702,
              caption: "Robotics",
              category_name: "Industrial Manufacturing",
            }
          ])
        end,
      ModuleDesc:
        swagger_schema do
          title("Module Class Descriptor")
          description("Schema Module class descriptor.")

          properties do
            name(:string, "Module class name", required: true)
            family(:string, "Module class family", required: true)
            caption(:string, "Module class caption", required: true)
            description(:string, "Module class description", required: true)
            category(:string, "Module class category", required: true)
            category_name(:string, "Module class category caption", required: true)

            profiles(:array, "Module class profiles",
              items: %PhoenixSwagger.Schema{type: :string}
            )

            uid(:integer, "Module class unique identifier", required: true)
          end

          example([
            %{
              name: "observability",
              family: "module",
              description: "Agent extension describing how the agent can be observed",
              category: "observability",
              extends: "base_module",
              uid: 101,
              caption: "Observability",
              category_name: "Observability"
            }
          ])
        end,
      ModulesDesc:
        swagger_schema do
          title("Module Class Descriptors")
          description("A collection of Module Class Descriptors.")
          type(:array)
          items(Schema.ref(:ModuleDesc))

          example([
            %{
              name: "manifest",
              family: "module",
              description: "Agent manifest",
              category: "runtime",
              extends: "runtime",
              uid: 301,
              caption: "Manifest",
              category_name: "Runtime"
            },
            %{
              name: "observability",
              family: "module",
              description: "Agent extension describing how the agent can be observed",
              category: "observability",
              extends: "base_module",
              uid: 101,
              caption: "Observability",
              category_name: "Observability"
            },
            %{
              name: "evaluation",
              family: "module",
              description:
                "Assessing actions and outcomes to determine their effectiveness, guiding future decision-making and enhancing personal agency.",
              category: "evaluation",
              extends: "base_module",
              uid: 201,
              caption: "Evaluation",
              category_name: "Evaluation"
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
            extends(:string, "Object parent class name", required: true)
            profiles(:array, "Object profiles", items: %PhoenixSwagger.Schema{type: :string})
          end

          example([
            %{
              name: "streaming_modes",
              description:
                "Supported streaming modes. If missing, streaming is not supported.  If no mode is supported attempts to stream output will result in an error.",
              extends: "object",
              caption: "Streaming Modes"
            }
          ])
        end,
      ObjectsDesc:
        swagger_schema do
          title("Object Descriptors")
          description("A collection of Object Descriptors.")
          type(:array)
          items(Schema.ref(:ObjectDesc))

          example([
            %{
              name: "streaming_modes",
              description:
                "Supported streaming modes. If missing, streaming is not supported.  If no mode is supported attempts to stream output will result in an error.",
              extends: "object",
              caption: "Streaming Modes"
            },
            %{
              name: "deployment_option",
              description: "Describes a deployment option for an agent.",
              extends: "object",
              caption: "Deployment Option"
            },
            %{
              name: "docker_deployment",
              description: "Describes the docker deployment for this agent.",
              extends: "deployment_option",
              caption: "Docker Deployment"
            }
          ])
        end,
      Skill:
        swagger_schema do
          title("Skill class")
          description("An OASF formatted skill class object.")
          type(:object)

          properties do
            name(:string, "The class name, as defined by id value")

            id(
              :integer,
              "The unique identifier of a class"
            )
          end

          example(%{
            id: 10101,
            name: "natural_language_processing/natural_language_understanding/contextual_comprehension"
          })
        end,
      Domain:
        swagger_schema do
          title("Domain class")
          description("An OASF formatted domain class object.")
          type(:object)

          properties do
            name(:string, "The class name, as defined by id value")

            id(
              :integer,
              "The unique identifier of a class"
            )
          end

          example(%{
            id: 101,
            name: "technology/internet_of_things"
          })
        end,
      Module:
        swagger_schema do
          title("Module class")
          description("An OASF formatted module class object.")
          type(:object)

          properties do
            name(:string, "The agent extension name")

            version(
              :string,
              "The schema version"
            )

            data(
              :object,
              "The data associated with the agent extension"
            )
          end

          example(%{
            data: %{
              communication_protocols: ["SLIM"],
              data_platform_integrations: [],
              data_schema: %{
                name: "Agntcy Observability Data Schema",
                version: "v0.0.1",
                url:
                  "https://github.com/agntcy/oasf/blob/main/schema/references/agntcy_observability/agntcy_observability_data_schema.json"
              },
              export_format: "csv"
            },
            name: "observability",
            version: "v0.2.2"
          })
        end,
      Object:
        swagger_schema do
          title("Object")
          description("An OASF formatted object.")
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
      Validation:
        swagger_schema do
          title("Class or object Validation")
          description("The errors and and warnings found when validating a class or an object.")

          properties do
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
      SkillBundle:
        swagger_schema do
          title("Skill Class Bundle")
          description("A bundle of skill classes.")

          properties do
            inputs(
              :array,
              "Array of skill classes.",
              items: %PhoenixSwagger.Schema{"$ref": "#definitions/Skill"},
              required: true
            )

            count(:integer, "Count of classes")
          end

          example(%{
            count: 2,
            inputs: [
              %{
                id: 10101,
                name: "natural_language_processing/natural_language_understanding/contextual_comprehension"
              },
              %{
                id: 10203,
                name: "natural_language_processing/natural_language_generation/paraphrasing"
              }
            ]
          })

          additional_properties(false)
        end,
      SkillBundleValidation:
        swagger_schema do
          title("Skill Class Bundle Validation")
          description("The errors and and warnings found when validating a skill class bundle.")

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

            input_validations(
              :array,
              "Array of skill class validations",
              items: %PhoenixSwagger.Schema{"$ref": "#/definitions/Validation"},
              required: true
            )
          end

          additional_properties(false)
        end,
      DomainBundle:
        swagger_schema do
          title("Domain Class Bundle")
          description("A bundle of domain classes.")

          properties do
            inputs(
              :array,
              "Array of domain classes.",
              items: %PhoenixSwagger.Schema{"$ref": "#definitions/Domain"},
              required: true
            )

            count(:integer, "Count of classes")
          end

          example(%{
            count: 2,
            inputs: [
              %{
                id: 101,
                name: "technology/internet_of_things	"
              },
              %{
                id: 403,
                name: "trust_and_safety/fraud_prevention"
              }
            ]
          })

          additional_properties(false)
        end,
      DomainBundleValidation:
        swagger_schema do
          title("Domain Class Bundle Validation")
          description("The errors and and warnings found when validating a domain class bundle.")

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

            input_validations(
              :array,
              "Array of domain class validations",
              items: %PhoenixSwagger.Schema{"$ref": "#/definitions/Validation"},
              required: true
            )
          end

          additional_properties(false)
        end,
      ModuleBundle:
        swagger_schema do
          title("Module Class Bundle")
          description("A bundle of module classes.")

          properties do
            inputs(
              :array,
              "Array of module classes.",
              items: %PhoenixSwagger.Schema{"$ref": "#definitions/Module"},
              required: true
            )

            count(:integer, "Count of classes")
          end

          example(%{
            count: 1,
            inputs: [
              %{
                data: %{
                  communication_protocols: ["SLIM"],
                  data_platform_integrations: [],
                  data_schema: %{
                    name: "Agntcy Observability Data Schema",
                    version: "v0.0.1",
                    url:
                      "https://github.com/agntcy/oasf/blob/main/schema/references/agntcy_observability/agntcy_observability_data_schema.json"
                  },
                  export_format: "csv"
                },
                name: "observability",
                version: "v0.2.2"
              }
            ]
          })

          additional_properties(false)
        end,
      ModuleBundleValidation:
        swagger_schema do
          title("Module Class Bundle Validation")
          description("The errors and and warnings found when validating a module class bundle.")

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

            input_validations(
              :array,
              "Array of module class validations",
              items: %PhoenixSwagger.Schema{"$ref": "#/definitions/Validation"},
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
      :url => "#{base_url}/api/#{Schema.version()}"
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
    tag("Dictionary and Types")
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
    summary("List schema extensions")
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
      "Get OASF schema profile by name. The profile name may contain a schema extension name." <>
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
  Get the schema main skills.
  """
  swagger_path :main_skills do
    get("/api/main_skills")
    summary("List skill categories")
    description("Get all OASF skill classes by category.")
    produces("application/json")
    tag("Categories")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
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
    summary("List skills of a skill category")

    description(
      "Get OASF skills defined in the named skill category. The skill category name may contain a" <>
        " schema extension name. For example, \"dev/policy\"."
    )

    produces("application/json")
    tag("Categories")

    parameters do
      name(:path, :string, "Skill category name", required: true)

      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
    response(404, "Skill category <code>name</code> not found")
  end

  @spec main_skill(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_skill(conn, %{"id" => id} = params) do
    case main_skill_skills(params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Skill category #{id} not found"})

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
    summary("List domain categories")
    description("Get all OASF domain classes by category.")
    produces("application/json")
    tag("Categories")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
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
    summary("List domains of a domain category")

    description(
      "Get OASF domains defined in the named domain category. The domain category name may contain a" <>
        " schema extension name. For example, \"dev/policy\"."
    )

    produces("application/json")
    tag("Categories")

    parameters do
      name(:path, :string, "Domain category name", required: true)

      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
    response(404, "Domain category <code>name</code> not found")
  end

  @spec main_domain(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_domain(conn, %{"id" => id} = params) do
    case main_domain_domains(params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Domain category #{id} not found"})

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
  Get the schema main modules.
  """
  swagger_path :main_modules do
    get("/api/main_modules")
    summary("List module categories")
    description("Get all OASF module classes by category.")
    produces("application/json")
    tag("Categories")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
  end

  @doc """
  Returns the list of main modules.
  """
  @spec main_modules(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_modules(conn, params) do
    send_json_resp(conn, main_modules(params))
  end

  @spec main_modules(map()) :: map()
  def main_modules(params) do
    parse_options(extensions(params)) |> Schema.main_modules()
  end

  @doc """
  Get the modules defined in a given main module.
  """
  swagger_path :main_module do
    get("/api/main_modules/{name}")
    summary("List modules of a module category")

    description(
      "Get OASF modules defined in the named module category. The module category name may contain a" <>
        " schema extension name. For example, \"dev/policy\"."
    )

    produces("application/json")
    tag("Categories")

    parameters do
      name(:path, :string, "Module category name", required: true)

      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
    response(404, "Module category <code>name</code> not found")
  end

  @spec main_module(Plug.Conn.t(), map) :: Plug.Conn.t()
  def main_module(conn, %{"id" => id} = params) do
    case main_module_modules(params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Module category #{id} not found"})

      data ->
        send_json_resp(conn, data)
    end
  end

  @spec main_module_modules(map()) :: map() | nil
  def main_module_modules(params) do
    name = params["id"]
    extension = extension(params)
    extensions = parse_options(extensions(params))

    Schema.main_module(extensions, extension, name)
  end

  @doc """
  Get the schema dictionary.
  """
  swagger_path :dictionary do
    get("/api/dictionary")
    summary("Dictionary")
    description("Get OASF schema dictionary.")
    produces("application/json")
    tag("Dictionary and Types")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
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
  Get a skill by name.
  get /api/skills/:name
  """
  swagger_path :skill do
    get("/api/skills/{name}")
    summary("Skill")

    description(
      "Get OASF skill class by name. The skill name may contain a schema extension name." <>
        " For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("Classes and Objects")

    parameters do
      name(:path, :string, "Skill class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Skill <code>name</code> not found")
  end

  @spec skill(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def skill(conn, %{"id" => id} = params) do
    skill(conn, id, params)
  end

  defp skill(conn, id, params) do
    extension = extension(params)

    case Schema.skill(extension, id, parse_options(profiles(params))) do
      nil ->
        send_json_resp(conn, 404, %{error: "Skill #{id} not found"})

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
    summary("List all skills")
    description("Get OASF skill classes.")
    produces("application/json")
    tag("Classes and Objects")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success", :SkillsDesc)
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
      "Get OASF domain class by name. The domain name may contain a schema extension name." <>
        " For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("Classes and Objects")

    parameters do
      name(:path, :string, "Domain class name", required: true)
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
    summary("List all domains")
    description("Get OASF domain classes.")
    produces("application/json")
    tag("Classes and Objects")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success", :DomainsDesc)
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
  Get a module by name.
  get /api/modules/:name
  """
  swagger_path :module do
    get("/api/modules/{name}")
    summary("Module")

    description(
      "Get OASF module class by name. The module name may contain a schema extension name." <>
        " For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("Classes and Objects")

    parameters do
      name(:path, :string, "Module class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Module <code>name</code> not found")
  end

  @spec module(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def module(conn, %{"id" => id} = params) do
    module(conn, id, params)
  end

  defp module(conn, id, params) do
    extension = extension(params)

    case Schema.module(extension, id, parse_options(profiles(params))) do
      nil ->
        send_json_resp(conn, 404, %{error: "Module #{id} not found"})

      data ->
        module = add_objects(data, params)
        send_json_resp(conn, module)
    end
  end

  @doc """
  Get the schema module.
  """
  swagger_path :modules do
    get("/api/modules")
    summary("List all modules")
    description("Get OASF module classes.")
    produces("application/json")
    tag("Classes and Objects")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success", :ModulesDesc)
  end

  @spec modules(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def modules(conn, params) do
    modules =
      Enum.map(modules(params), fn {_name, module} ->
        Schema.reduce_class(module)
      end)

    send_json_resp(conn, modules)
  end

  @doc """
  Returns the list of modules.
  """
  @spec modules(map) :: map
  def modules(params) do
    extensions = parse_options(extensions(params))

    case parse_options(profiles(params)) do
      nil ->
        Schema.modules(extensions)

      profiles ->
        Schema.modules(extensions, profiles)
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
      "Get OASF schema object by name. The object name may contain a schema extension name." <>
        " For example, \"dev/os_service\"."
    )

    produces("application/json")
    tag("Classes and Objects")

    parameters do
      name(:path, :string, "Object name", required: true)

      extensions(:query, :array, "Related schema extensions to include in response.",
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
        object = add_objects(data, params)
        send_json_resp(conn, object)
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
    tag("Classes and Objects")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success", :ObjectsDesc)
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
  Export the OASF skill classes.
  """
  swagger_path :export_skills do
    get("/export/skills")
    summary("Export skill classes")
    description("Get OASF schema skill classes.")
    produces("application/json")
    tag("Schema Export")

    parameters do
      extensions(:query, :array, @extensions_param_description, items: [type: :string])
      profiles(:query, :array, @profiles_param_description, items: [type: :string])
    end

    response(200, "Success")
  end

  def export_skills(conn, params) do
    profiles = parse_options(profiles(params))
    extensions = parse_options(extensions(params))
    classes = Schema.export_skills(extensions, profiles)
    send_json_resp(conn, classes)
  end

  @doc """
  Export the OASF domain classes.
  """
  swagger_path :export_domains do
    get("/export/domains")
    summary("Export domain classes")
    description("Get OASF schema domain classes.")
    produces("application/json")
    tag("Schema Export")

    parameters do
      extensions(:query, :array, @extensions_param_description, items: [type: :string])
      profiles(:query, :array, @profiles_param_description, items: [type: :string])
    end

    response(200, "Success")
  end

  def export_domains(conn, params) do
    profiles = parse_options(profiles(params))
    extensions = parse_options(extensions(params))
    classes = Schema.export_domains(extensions, profiles)
    send_json_resp(conn, classes)
  end

  @doc """
  Export the OASF module classes.
  """
  swagger_path :export_modules do
    get("/export/modules")
    summary("Export module classes")
    description("Get OASF schema module classes.")
    produces("application/json")
    tag("Schema Export")

    parameters do
      extensions(:query, :array, @extensions_param_description, items: [type: :string])
      profiles(:query, :array, @profiles_param_description, items: [type: :string])
    end

    response(200, "Success")
  end

  def export_modules(conn, params) do
    profiles = parse_options(profiles(params))
    extensions = parse_options(extensions(params))
    classes = Schema.export_modules(extensions, profiles)
    send_json_resp(conn, classes)
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
  Get JSON schema definitions for a given skill class.
  get /schema/skills/:name
  """
  swagger_path :json_skill_class do
    get("/schema/skills/{name}")
    summary("Skill")

    description(
      "Get OASF schema skill class by name, using JSON schema Draft-07 format " <>
        "(see http://json-schema.org). The class name may contain a schema extension name. "
    )

    produces("application/json")
    tag("JSON Schema")

    parameters do
      name(:path, :string, "Skill class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
      package_name(:query, :string, "Java package name")
    end

    response(200, "Success")
    response(404, "Skill class <code>name</code> not found")
  end

  @spec json_skill_class(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def json_skill_class(conn, %{"id" => id} = params) do
    options = Map.get(params, "package_name") |> parse_java_package()

    case skill_ex(id, params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Skill class #{id} not found"})

      data ->
        class = Schema.JsonSchema.encode(data, options)
        send_json_resp(conn, class)
    end
  end

  def skill_ex(id, params) do
    extension = extension(params)
    Schema.entity_ex(extension, :skill, id, parse_options(profiles(params)))
  end

  @doc """
  Get JSON schema definitions for a given domain class.
  get /schema/domains/:name
  """
  swagger_path :json_domain_class do
    get("/schema/domains/{name}")
    summary("Domain")

    description(
      "Get OASF schema domain class by name, using JSON schema Draft-07 format " <>
        "(see http://json-schema.org). The class name may contain a schema extension name. "
    )

    produces("application/json")
    tag("JSON Schema")

    parameters do
      name(:path, :string, "Domain class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
      package_name(:query, :string, "Java package name")
    end

    response(200, "Success")
    response(404, "Domain class <code>name</code> not found")
  end

  @spec json_domain_class(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def json_domain_class(conn, %{"id" => id} = params) do
    options = Map.get(params, "package_name") |> parse_java_package()

    case domain_ex(id, params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Domain class #{id} not found"})

      data ->
        class = Schema.JsonSchema.encode(data, options)
        send_json_resp(conn, class)
    end
  end

  def domain_ex(id, params) do
    extension = extension(params)
    Schema.entity_ex(extension, :domain, id, parse_options(profiles(params)))
  end

  @doc """
  Get JSON schema definitions for a given module class.
  get /schema/modules/:name
  """
  swagger_path :json_module_class do
    get("/schema/modules/{name}")
    summary("Module")

    description(
      "Get OASF schema module class by name, using JSON schema Draft-07 format " <>
        "(see http://json-schema.org). The class name may contain a schema extension name. "
    )

    produces("application/json")
    tag("JSON Schema")

    parameters do
      name(:path, :string, "Module class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
      package_name(:query, :string, "Java package name")
    end

    response(200, "Success")
    response(404, "Module class <code>name</code> not found")
  end

  @spec json_module_class(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def json_module_class(conn, %{"id" => id} = params) do
    options = Map.get(params, "package_name") |> parse_java_package()

    case module_ex(id, params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Module class #{id} not found"})

      data ->
        class = Schema.JsonSchema.encode(data, options)
        send_json_resp(conn, class)
    end
  end

  def module_ex(id, params) do
    extension = extension(params)
    Schema.entity_ex(extension, :module, id, parse_options(profiles(params)))
  end

  @doc """
  Get JSON schema definitions for a given object.
  get /schema/objects/:name
  """
  swagger_path :json_object do
    get("/schema/objects/{name}")
    summary("Object")

    description(
      "Get OASF object by name, using JSON schema Draft-07 format (see http://json-schema.org)." <>
        " The object name may contain a schema extension name. For example, \"dev/printer\"."
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

    Schema.entity_ex(extensions, extension, :object, id, profiles)
  end

  # ---------------------------------------------
  # Validation, and translation API's
  # ---------------------------------------------

  @doc """
  Translate skill class data. A single class is encoded as a JSON object and multiple classes are encoded as JSON array of objects.
  """
  swagger_path :translate_skill do
    post("/api/translate/skill")
    summary("Translate skill class")

    description(
      "The purpose of this API is to translate the provided skill class data using the OASF schema." <>
        " Each class is represented as a JSON object, while multiple classes are encoded as a" <>
        "  JSON array of objects."
    )

    produces("application/json")
    tag("Translation")

    parameters do
      _mode(
        :query,
        :number,
        """
        Controls how attribute names and enumerated values are translated.<br/>
        The format is _mode=[1|2|3]. The default mode is `1` -- translate enumerated values.

        |Value|Description|Example|
        |-----|-----------|-------|
        |1|Translate only the enumerated values|Untranslated:<br/><code>{"id": 10101}</code><br/><br/>Translated:<br/><code>{"name": "Contextual Comprehension", "id": 10101}</code>|
        |2|Translate enumerated values and attribute names|Untranslated:<br/><code>{"id": 10101}</code><br/><br/>Translated:<br/><code>{"Class": "Contextual Comprehension", "Class ID": 10101}</code>|
        |3|Verbose translation|Untranslated:<br/><code>{"id": 10101}</code><br/><br/>Translated:<br/><code>{"id": {"caption": "Contextual Comprehension","name": "Class ID","type": "integer_t","value": 10101}}</code>|
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
          |&lt;empty&gt;|The spaces in the translated names are removed.|Untranslated:<br/><code>{"id": 10101}</code><br/><br/>Translated:<br/><code>{"ClassID": "Contextual Comprehension"}</code>|
          |string|The spaces in the translated names are replaced with the given string.|For example, the string is an underscore (_).<br/>Untranslated:<br/><code>{"id": 10101}</code><br/><br/>Translated:<br/><code>{"Class_ID": "Contextual Comprehension"}</code>|
        """,
        allowEmptyValue: true
      )

      data(:body, PhoenixSwagger.Schema.ref(:Skill), "The skill class data to be translated",
        required: true
      )
    end

    response(200, "Success")
  end

  @spec translate_skill(Plug.Conn.t(), map) :: Plug.Conn.t()
  def translate_skill(conn, params) do
    options = [spaces: conn.query_params[@spaces], verbose: verbose(conn.query_params[@verbose])]

    {status, result} =
      case params["_json"] do
        # Translate a single classes
        class when is_map(class) ->
          {200, Schema.Translator.translate(class, options, :skill)}

        # Translate a list of classes
        list when is_list(list) ->
          {200,
           Enum.map(list, fn class -> Schema.Translator.translate(class, options, :skill) end)}

        # some other json data
        _ ->
          {400, %{error: "Unexpected body. Expected a JSON object or array."}}
      end

    send_json_resp(conn, status, result)
  end

  @doc """
  Translate domain class data. A single class is encoded as a JSON object and multiple classes are encoded as JSON array of objects.
  """
  swagger_path :translate_domain do
    post("/api/translate/domain")
    summary("Translate domain class")

    description(
      "The purpose of this API is to translate the provided domain class data using the OASF schema." <>
        " Each class is represented as a JSON object, while multiple classes are encoded as a" <>
        "  JSON array of objects."
    )

    produces("application/json")
    tag("Translation")

    parameters do
      _mode(
        :query,
        :number,
        """
        Controls how attribute names and enumerated values are translated.<br/>
        The format is _mode=[1|2|3]. The default mode is `1` -- translate enumerated values.

        |Value|Description|Example|
        |-----|-----------|-------|
        |1|Translate only the enumerated values|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"name": "Internet of Things (IoT)", "id": 101}</code>|
        |2|Translate enumerated values and attribute names|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"Class": "Internet of Things (IoT)", "Class ID": 101}</code>|
        |3|Verbose translation|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"id": {"caption": "Internet of Things (IoT)","name": "Class ID","type": "integer_t","value": 101}}</code>|
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
          |&lt;empty&gt;|The spaces in the translated names are removed.|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"ClassID": "Internet of Things (IoT)"}</code>|
          |string|The spaces in the translated names are replaced with the given string.|For example, the string is an underscore (_).<br/>Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"Class_ID": "Internet of Things (IoT)"}</code>|
        """,
        allowEmptyValue: true
      )

      data(:body, PhoenixSwagger.Schema.ref(:Domain), "The domain class data to be translated",
        required: true
      )
    end

    response(200, "Success")
  end

  @spec translate_domain(Plug.Conn.t(), map) :: Plug.Conn.t()
  def translate_domain(conn, params) do
    options = [spaces: conn.query_params[@spaces], verbose: verbose(conn.query_params[@verbose])]

    {status, result} =
      case params["_json"] do
        # Translate a single classes
        class when is_map(class) ->
          {200, Schema.Translator.translate(class, options, :domain)}

        # Translate a list of classes
        list when is_list(list) ->
          {200,
           Enum.map(list, fn class -> Schema.Translator.translate(class, options, :domain) end)}

        # some other json data
        _ ->
          {400, %{error: "Unexpected body. Expected a JSON object or array."}}
      end

    send_json_resp(conn, status, result)
  end

  @doc """
  Translate module class data. A single class is encoded as a JSON object and multiple classes are encoded as JSON array of objects.
  """
  swagger_path :translate_module do
    post("/api/translate/module")
    summary("Translate module Class")

    description(
      "The purpose of this API is to translate the provided module class data using the OASF schema." <>
        " Each class is represented as a JSON object, while multiple classes are encoded as a" <>
        "  JSON array of objects."
    )

    produces("application/json")
    tag("Translation")

    parameters do
      _mode(
        :query,
        :number,
        """
        Controls how attribute names and enumerated values are translated.<br/>
        The format is _mode=[1|2|3]. The default mode is `1` -- translate enumerated values.

        |Value|Description|
        |-----|-----------|
        |1|Translate only the enumerated values|
        |2|Translate enumerated values and attribute names|
        |3|Verbose translation|
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

          |Value|Description|
          |-----|-----------|
          |&lt;empty&gt;|The spaces in the translated names are removed.|
          |string|The spaces in the translated names are replaced with the given string.|
        """,
        allowEmptyValue: true
      )

      data(:body, PhoenixSwagger.Schema.ref(:Module), "The module class data to be translated",
        required: true
      )
    end

    response(200, "Success")
  end

  @spec translate_module(Plug.Conn.t(), map) :: Plug.Conn.t()
  def translate_module(conn, params) do
    options = [spaces: conn.query_params[@spaces], verbose: verbose(conn.query_params[@verbose])]

    {status, result} =
      case params["_json"] do
        # Translate a single classes
        class when is_map(class) ->
          {200, Schema.Translator.translate(class, options, :module)}

        # Translate a list of classes
        list when is_list(list) ->
          {200,
           Enum.map(list, fn class -> Schema.Translator.translate(class, options, :module) end)}

        # some other json data
        _ ->
          {400, %{error: "Unexpected body. Expected a JSON object or array."}}
      end

    send_json_resp(conn, status, result)
  end

  @doc """
  Translate object data. A single class is encoded as a JSON object and multiple classes are encoded as JSON array of objects.
  """
  swagger_path :translate_object do
    post("/api/translate/object/{name}")
    summary("Translate object")

    description(
      "The purpose of this API is to translate the provided object data using the OASF schema." <>
        " Each class is represented as a JSON object, while multiple classes are encoded as a" <>
        "  JSON array of objects."
    )

    produces("application/json")
    tag("Translation")

    parameters do
      name(:path, :string, "Object name", required: true)

      _mode(
        :query,
        :number,
        """
        Controls how attribute names and enumerated values are translated.<br/>
        The format is _mode=[1|2|3]. The default mode is `1` -- translate enumerated values.

        |Value|Description|
        |-----|-----------|
        |1|Translate only the enumerated values|
        |2|Translate enumerated values and attribute names|
        |3|Verbose translation|
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

          |Value|Description|
          |-----|-----------|
          |&lt;empty&gt;|The spaces in the translated names are removed.|
          |string|The spaces in the translated names are replaced with the given string.|
        """,
        allowEmptyValue: true
      )

      data(:body, PhoenixSwagger.Schema.ref(:Object), "The object data to be translated",
        required: true
      )
    end

    response(200, "Success")
  end

  @spec translate_object(Plug.Conn.t(), map) :: Plug.Conn.t()
  def translate_object(conn, %{"id" => id} = params) do
    options = [
      name: id,
      spaces: conn.query_params[@spaces],
      verbose: verbose(conn.query_params[@verbose])
    ]

    {status, result} =
      case params["_json"] do
        # Translate a single classes
        class when is_map(class) ->
          {200, Schema.Translator.translate(class, options, :object)}

        # Translate a list of classes
        list when is_list(list) ->
          {200,
           Enum.map(list, fn class -> Schema.Translator.translate(class, options, :object) end)}

        # some other json data
        _ ->
          {400, %{error: "Unexpected body. Expected a JSON object or array."}}
      end

    send_json_resp(conn, status, result)
  end

  @doc """
  Validate skill class data. Validates a single class.
  post /api/validate/skill
  """
  swagger_path :validate_skill do
    post("/api/validate/skill")
    summary("Validate skill class")

    description(
      "This API validates the provided skill class data against the OASF schema, returning a response" <>
        " containing validation errors and warnings."
    )

    produces("application/json")
    tag("Validation")

    parameters do
      missing_recommended(
        :query,
        :boolean,
        """
        When true, warnings are created for missing recommended attributes, otherwise recommended attributes are treated the same as optional.
        """,
        default: false
      )

      data(:body, PhoenixSwagger.Schema.ref(:Skill), "The skill class to be validated",
        required: true
      )
    end

    response(200, "Success", PhoenixSwagger.Schema.ref(:Validation))
  end

  @spec validate_skill(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def validate_skill(conn, params) do
    options = [
      warn_on_missing_recommended:
        case conn.query_params[@missing_recommended] do
          "true" -> true
          _ -> false
        end
    ]

    # We've configured Plug.Parsers / Plug.Parsers.JSON to always nest JSON in the _json key in
    # endpoint.ex.
    {status, result} = validate_actual(params["_json"], options, :skill)

    send_json_resp(conn, status, result)
  end

  @doc """
  Validate domain class data. Validates a single class.
  post /api/validate/domain
  """
  swagger_path :validate_domain do
    post("/api/validate/domain")
    summary("Validate domain Class")

    description(
      "This API validates the provided domain class data against the OASF schema, returning a response" <>
        " containing validation errors and warnings."
    )

    produces("application/json")
    tag("Validation")

    parameters do
      missing_recommended(
        :query,
        :boolean,
        """
        When true, warnings are created for missing recommended attributes, otherwise recommended attributes are treated the same as optional.
        """,
        default: false
      )

      data(:body, PhoenixSwagger.Schema.ref(:Domain), "The domain class to be validated",
        required: true
      )
    end

    response(200, "Success", PhoenixSwagger.Schema.ref(:Validation))
  end

  @spec validate_domain(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def validate_domain(conn, params) do
    options = [
      warn_on_missing_recommended:
        case conn.query_params[@missing_recommended] do
          "true" -> true
          _ -> false
        end
    ]

    # We've configured Plug.Parsers / Plug.Parsers.JSON to always nest JSON in the _json key in
    # endpoint.ex.
    {status, result} = validate_actual(params["_json"], options, :domain)

    send_json_resp(conn, status, result)
  end

  @doc """
  Validate module class data. Validates a single class.
  post /api/validate/module
  """
  swagger_path :validate_module do
    post("/api/validate/module")
    summary("Validate module Class")

    description(
      "This API validates the provided module class data against the OASF schema, returning a response" <>
        " containing validation errors and warnings."
    )

    produces("application/json")
    tag("Validation")

    parameters do
      missing_recommended(
        :query,
        :boolean,
        """
        When true, warnings are created for missing recommended attributes, otherwise recommended attributes are treated the same as optional.
        """,
        default: false
      )

      data(:body, PhoenixSwagger.Schema.ref(:Module), "The module class to be validated",
        required: true
      )
    end

    response(200, "Success", PhoenixSwagger.Schema.ref(:Validation))
  end

  @spec validate_module(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def validate_module(conn, params) do
    options = [
      warn_on_missing_recommended:
        case conn.query_params[@missing_recommended] do
          "true" -> true
          _ -> false
        end
    ]

    # We've configured Plug.Parsers / Plug.Parsers.JSON to always nest JSON in the _json key in
    # endpoint.ex.
    {status, result} = validate_actual(params["_json"], options, :module)

    send_json_resp(conn, status, result)
  end

  @doc """
  Validate object data. Validates a single class.
  post /api/validate/object
  """
  swagger_path :validate_object do
    post("/api/validate/object/{name}")
    summary("Validate object")

    description(
      "This API validates the provided object data against the OASF schema, returning a response" <>
        " containing validation errors and warnings."
    )

    produces("application/json")
    tag("Validation")

    parameters do
      name(:path, :string, "Object name", required: true)

      missing_recommended(
        :query,
        :boolean,
        """
        When true, warnings are created for missing recommended attributes, otherwise recommended attributes are treated the same as optional.
        """,
        default: false
      )

      data(:body, PhoenixSwagger.Schema.ref(:Object), "The object to be validated",
        required: true
      )
    end

    response(200, "Success", PhoenixSwagger.Schema.ref(:Validation))
  end

  @spec validate_object(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def validate_object(conn, %{"id" => id} = params) do
    options = [
      name: id,
      warn_on_missing_recommended:
        case conn.query_params[@missing_recommended] do
          "true" -> true
          _ -> false
        end
    ]

    # We've configured Plug.Parsers / Plug.Parsers.JSON to always nest JSON in the _json key in
    # endpoint.ex.
    {status, result} = validate_actual(params["_json"], options, :object)

    send_json_resp(conn, status, result)
  end

  defp validate_actual(input, options, type) when is_map(input) do
    {200, Schema.Validator.validate(input, options, type)}
  end

  defp validate_actual(_, _, _) do
    {400, %{error: "Unexpected body. Expected a JSON object."}}
  end

  @doc """
  Validate skill class data. Validates a bundle of skill classes.
  post /api/validate_bundle/skill
  """
  swagger_path :validate_bundle_skill do
    post("/api/validate_bundle/skill")
    summary("Validate skill class bundle")

    description(
      "This API validates the provided skill class bundle. The class bundle itself is validated, and" <>
        " each class in the bundle's classes attribute are validated."
    )

    produces("application/json")
    tag("Validation")

    parameters do
      missing_recommended(
        :query,
        :boolean,
        """
        When true, warnings are created for missing recommended attributes, otherwise recommended attributes are treated the same as optional.
        """,
        default: false
      )

      data(
        :body,
        PhoenixSwagger.Schema.ref(:SkillBundle),
        "The skill class bundle to be validated",
        required: true
      )
    end

    response(200, "Success", PhoenixSwagger.Schema.ref(:SkillBundleValidation))
  end

  @spec validate_bundle_skill(Plug.Conn.t(), map) :: Plug.Conn.t()
  def validate_bundle_skill(conn, params) do
    options = [
      warn_on_missing_recommended:
        case conn.query_params[@missing_recommended] do
          "true" -> true
          _ -> false
        end
    ]

    # We've configured Plug.Parsers / Plug.Parsers.JSON to always nest JSON in the _json key in
    # endpoint.ex.
    {status, result} =
      validate_bundle_actual(params["_json"], options, :skill)

    send_json_resp(conn, status, result)
  end

  @doc """
  Validate domain class data. Validates a bundle of domain classes.
  post /api/validate_bundle/domain
  """
  swagger_path :validate_bundle_domain do
    post("/api/validate_bundle/domain")
    summary("Validate domain class bundle")

    description(
      "This API validates the provided domain class bundle. The class bundle itself is validated, and" <>
        " each class in the bundle's classes attribute are validated."
    )

    produces("application/json")
    tag("Validation")

    parameters do
      missing_recommended(
        :query,
        :boolean,
        """
        When true, warnings are created for missing recommended attributes, otherwise recommended attributes are treated the same as optional.
        """,
        default: false
      )

      data(
        :body,
        PhoenixSwagger.Schema.ref(:DomainBundle),
        "The domain class bundle to be validated",
        required: true
      )
    end

    response(200, "Success", PhoenixSwagger.Schema.ref(:DomainBundleValidation))
  end

  @spec validate_bundle_domain(Plug.Conn.t(), map) :: Plug.Conn.t()
  def validate_bundle_domain(conn, params) do
    options = [
      warn_on_missing_recommended:
        case conn.query_params[@missing_recommended] do
          "true" -> true
          _ -> false
        end
    ]

    # We've configured Plug.Parsers / Plug.Parsers.JSON to always nest JSON in the _json key in
    # endpoint.ex.
    {status, result} =
      validate_bundle_actual(params["_json"], options, :domain)

    send_json_resp(conn, status, result)
  end

  @doc """
  Validate module class data. Validates a bundle of module classes.
  post /api/validate_bundle/module
  """
  swagger_path :validate_bundle_module do
    post("/api/validate_bundle/module")
    summary("validate module class bundle")

    description(
      "This API validates the provided module class bundle. The class bundle itself is validated, and" <>
        " each class in the bundle's classes attribute are validated."
    )

    produces("application/json")
    tag("Validation")

    parameters do
      missing_recommended(
        :query,
        :boolean,
        """
        When true, warnings are created for missing recommended attributes, otherwise recommended attributes are treated the same as optional.
        """,
        default: false
      )

      data(
        :body,
        PhoenixSwagger.Schema.ref(:ModuleBundle),
        "The module class bundle to be validated",
        required: true
      )
    end

    response(200, "Success", PhoenixSwagger.Schema.ref(:ModuleBundleValidation))
  end

  @spec validate_bundle_module(Plug.Conn.t(), map) :: Plug.Conn.t()
  def validate_bundle_module(conn, params) do
    options = [
      warn_on_missing_recommended:
        case conn.query_params[@missing_recommended] do
          "true" -> true
          _ -> false
        end
    ]

    # We've configured Plug.Parsers / Plug.Parsers.JSON to always nest JSON in the _json key in
    # endpoint.ex.
    {status, result} =
      validate_bundle_actual(params["_json"], options, :module)

    send_json_resp(conn, status, result)
  end

  defp validate_bundle_actual(bundle, options, type) when is_map(bundle) do
    {200, Schema.Validator.validate_bundle(bundle, options, type)}
  end

  defp validate_bundle_actual(_, _, _) do
    {400, %{error: "Unexpected body. Expected a JSON object."}}
  end

  # --------------------------
  # Request sample data API's
  # --------------------------

  @doc """
  Returns randomly generated skill class sample data for the given name.
  get /sample/skills/:name
  get /sample/skills/:extension/:name
  """
  swagger_path :sample_skill do
    get("/sample/skills/{name}")
    summary("Skill class sample data")

    description(
      "This API returns randomly generated sample data for the given skill class name. The class" <>
        " name may contain a schema extension name. For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("Sample Data")

    parameters do
      name(:path, :string, "Skill class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Skill class <code>name</code> not found")
  end

  @spec sample_skill(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sample_skill(conn, %{"id" => id} = params) do
    sample_skill(conn, id, params)
  end

  defp sample_skill(conn, id, options) do
    extension = extension(options)
    profiles = profiles(options) |> parse_options()

    case Schema.skill(extension, id) do
      nil ->
        send_json_resp(conn, 404, %{error: "Skill class #{id} not found"})

      class ->
        class =
          Schema.generate_class(class, profiles)

        send_json_resp(conn, class)
    end
  end

  @doc """
  Returns randomly generated domain class sample data for the given name.
  get /sample/domains/:name
  get /sample/domains/:extension/:name
  """
  swagger_path :sample_domain do
    get("/sample/domains/{name}")
    summary("Domain class sample data")

    description(
      "This API returns randomly generated sample data for the given domain class name. The class" <>
        " name may contain a schema extension name. For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("Sample Data")

    parameters do
      name(:path, :string, "Domain class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success", :Domain)
    response(404, "Domain class <code>name</code> not found")
  end

  @spec sample_domain(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sample_domain(conn, %{"id" => id} = params) do
    sample_domain(conn, id, params)
  end

  defp sample_domain(conn, id, options) do
    extension = extension(options)
    profiles = profiles(options) |> parse_options()

    case Schema.domain(extension, id) do
      nil ->
        send_json_resp(conn, 404, %{error: "Domain class #{id} not found"})

      class ->
        class =
          Schema.generate_class(class, profiles)

        send_json_resp(conn, class)
    end
  end

  @doc """
  Returns randomly generated module class sample data for the given name.
  get /sample/modules/:name
  get /sample/modules/:extension/:name
  """
  swagger_path :sample_module do
    get("/sample/modules/{name}")
    summary("Module class sample data")

    description(
      "This API returns randomly generated sample data for the given module class name. The class" <>
        " name may contain a schema extension name. For example, \"dev/cpu_usage\"."
    )

    produces("application/json")
    tag("Sample Data")

    parameters do
      name(:path, :string, "Module class name", required: true)
      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Module class <code>name</code> not found")
  end

  @spec sample_module(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sample_module(conn, %{"id" => id} = params) do
    sample_module(conn, id, params)
  end

  defp sample_module(conn, id, options) do
    extension = extension(options)
    profiles = profiles(options) |> parse_options()

    case Schema.module(extension, id) do
      nil ->
        send_json_resp(conn, 404, %{error: "Module class #{id} not found"})

      class ->
        class =
          Schema.generate_class(class, profiles)

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
        " name may contain a schema extension name. For example, \"dev/os_service\"."
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
      Map.put(data, :entities, objects)
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
