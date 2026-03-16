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

  # -------------------
  # Class Schema API's
  # -------------------

  def swagger_definitions do
    %{}
  end

  @doc """
  Get the OASF schema, server, and API versions.
  """
  swagger_path :version do
    get("/api/version")
    summary("Version")
    description("Get OASF schema, server, and API versions.")
    produces("application/json")
    tag("Schema")
    response(200, "Success")
  end

  @spec version(Plug.Conn.t(), any) :: Plug.Conn.t()
  def version(conn, _params) do
    send_json_resp(conn, current_version_response(base_url(conn), Schema.version()))
  end

  @doc """
  Get available OASF schema versions with server and API metadata.
  """
  swagger_path :versions do
    get("/api/versions")
    summary("Versions")
    description("Get available OASF schema versions with server and API metadata.")
    produces("application/json")
    tag("Schema")
    response(200, "Success")
  end

  @spec versions(Plug.Conn.t(), any) :: Plug.Conn.t()
  def versions(conn, _params) do
    base_url = base_url(conn)

    available_versions = Schemas.versions()

    default_version = default_version_response(base_url, available_versions)

    versions_response =
      case available_versions do
        [] ->
          # If there is no response, we only provide a single schema
          %{:versions => [default_version], :default => default_version}

        [_head | _tail] ->
          available_versions_objects =
            available_versions
            |> Enum.map(fn {schema_version, metadata} ->
              version_response(base_url, schema_version, metadata)
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
    tag("Schema")
    response(200, "Success")
  end

  @spec data_types(Plug.Conn.t(), any) :: Plug.Conn.t()
  def data_types(conn, _params) do
    send_json_resp(conn, Schema.data_types_attributes())
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
  def profile(conn, %{"name" => name} = params) do
    full_name =
      case params["extension"] do
        nil -> name
        extension -> "#{extension}/#{name}"
      end

    data = Schema.profiles()

    case Map.get(data, full_name) do
      nil ->
        send_json_resp(conn, 404, %{error: "Profile #{full_name} not found"})

      profile ->
        send_json_resp(conn, Schema.delete_links(profile))
    end
  end

  @doc """
  Get the schema dictionary.
  """
  swagger_path :dictionary do
    get("/api/dictionary")
    summary("Dictionary")
    description("Get OASF schema dictionary.")
    produces("application/json")
    tag("Schema")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )
    end

    response(200, "Success")
  end

  @spec dictionary(Plug.Conn.t(), any) :: Plug.Conn.t()
  def dictionary(conn, params) do
    data = dictionary(params) |> Schema.deep_clean()

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
  Get the taxonomy tree for modules.
  """
  swagger_path :module_categories do
    get("/api/module_categories")
    summary("Get modules taxonomy tree")

    description(
      "Get OASF modules taxonomy tree with nested categories, subcategories, classes, and subclasses." <>
        " If id (numeric) or name (string) query parameter is provided, returns only the children of that parent." <>
        " Name can be in hierarchical format (e.g., 'natural_language_processing/natural_language_understanding/contextual_comprehension') or simple format (e.g., 'contextual_comprehension')." <>
        " If both id and name are provided, they must refer to the same node, otherwise returns 400 Bad Request."
    )

    produces("application/json")
    tag("Taxonomy")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      id(
        :query,
        :integer,
        "Optional numeric ID of parent to filter children. Returns only children of this parent.",
        required: false
      )

      name(
        :query,
        :string,
        "Optional name of parent to filter children. Can be hierarchical (e.g., 'natural_language_processing/natural_language_understanding/contextual_comprehension') or simple (e.g., 'contextual_comprehension'). Returns only children of this parent.",
        required: false
      )
    end

    response(200, "Success")
    response(400, "Bad Request - id and name parameters refer to different classes")
    response(404, "Not Found - No class found with the specified id or name")
  end

  @spec module_categories(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def module_categories(conn, params) do
    extensions_opt = parse_options(extensions(params))

    handle_with_optional_id_and_name(
      conn,
      params,
      :modules,
      fn ->
        Schema.taxonomy_modules(extensions_opt, nil)
        |> Schema.Utils.sort_taxonomy_tree()
        |> taxonomy_ordered_object()
      end,
      fn id_or_name ->
        result = Schema.taxonomy_modules(extensions_opt, id_or_name)

        if map_size(result) == 0,
          do: nil,
          else: result |> Schema.Utils.sort_taxonomy_tree() |> taxonomy_ordered_object()
      end
    )
  end

  @spec taxonomy_modules(map()) :: map()
  def taxonomy_modules(params) do
    extensions = parse_options(extensions(params))
    parent = parse_integer_param(Map.get(params, "id")) || Map.get(params, "name")
    Schema.taxonomy_modules(extensions, parent)
  end

  @doc """
  Get the taxonomy tree for skills.
  """
  swagger_path :skill_categories do
    get("/api/skill_categories")
    summary("Get skills taxonomy tree")

    description(
      "Get OASF skills taxonomy tree with nested categories, subcategories, classes, and subclasses." <>
        " If id (numeric) or name (string) query parameter is provided, returns only the children of that parent." <>
        " Name can be in hierarchical format (e.g., 'natural_language_processing/natural_language_understanding/contextual_comprehension') or simple format (e.g., 'contextual_comprehension')."
    )

    produces("application/json")
    tag("Taxonomy")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      id(
        :query,
        :integer,
        "Optional numeric ID of parent to filter children. Returns only children of this parent.",
        required: false
      )

      name(
        :query,
        :string,
        "Optional name of parent to filter children. Can be hierarchical (e.g., 'natural_language_processing/natural_language_understanding/contextual_comprehension') or simple (e.g., 'contextual_comprehension'). Returns only children of this parent.",
        required: false
      )
    end

    response(200, "Success")
    response(400, "Bad Request - id and name parameters refer to different classes")
    response(404, "Not Found - No class found with the specified id or name")
  end

  @spec skill_categories(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def skill_categories(conn, params) do
    extensions_opt = parse_options(extensions(params))

    handle_with_optional_id_and_name(
      conn,
      params,
      :skills,
      fn ->
        Schema.taxonomy_skills(extensions_opt, nil)
        |> Schema.Utils.sort_taxonomy_tree()
        |> taxonomy_ordered_object()
      end,
      fn id_or_name ->
        result = Schema.taxonomy_skills(extensions_opt, id_or_name)

        if map_size(result) == 0,
          do: nil,
          else: result |> Schema.Utils.sort_taxonomy_tree() |> taxonomy_ordered_object()
      end
    )
  end

  @spec taxonomy_skills(map()) :: map()
  def taxonomy_skills(params) do
    extensions = parse_options(extensions(params))
    parent = parse_integer_param(Map.get(params, "id")) || Map.get(params, "name")
    Schema.taxonomy_skills(extensions, parent)
  end

  @doc """
  Get the taxonomy tree for domains.
  """
  swagger_path :domain_categories do
    get("/api/domain_categories")
    summary("Get domains taxonomy tree")

    description(
      "Get OASF domains taxonomy tree with nested categories, subcategories, classes, and subclasses." <>
        " If id (numeric) or name (string) query parameter is provided, returns only the children of that parent." <>
        " Name can be in hierarchical format (e.g., 'natural_language_processing/natural_language_understanding/contextual_comprehension') or simple format (e.g., 'contextual_comprehension')."
    )

    produces("application/json")
    tag("Taxonomy")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      id(
        :query,
        :integer,
        "Optional numeric ID of parent to filter children. Returns only children of this parent.",
        required: false
      )

      name(
        :query,
        :string,
        "Optional name of parent to filter children. Can be hierarchical (e.g., 'natural_language_processing/natural_language_understanding/contextual_comprehension') or simple (e.g., 'contextual_comprehension'). Returns only children of this parent.",
        required: false
      )
    end

    response(200, "Success")
    response(400, "Bad Request - id and name parameters refer to different classes")
    response(404, "Not Found - No class found with the specified id or name")
  end

  @spec domain_categories(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def domain_categories(conn, params) do
    extensions_opt = parse_options(extensions(params))

    handle_with_optional_id_and_name(
      conn,
      params,
      :domains,
      fn ->
        Schema.taxonomy_domains(extensions_opt, nil)
        |> Schema.Utils.sort_taxonomy_tree()
        |> taxonomy_ordered_object()
      end,
      fn id_or_name ->
        result = Schema.taxonomy_domains(extensions_opt, id_or_name)

        if map_size(result) == 0,
          do: nil,
          else: result |> Schema.Utils.sort_taxonomy_tree() |> taxonomy_ordered_object()
      end
    )
  end

  @spec taxonomy_domains(map()) :: map()
  def taxonomy_domains(params) do
    extensions = parse_options(extensions(params))
    parent = parse_integer_param(Map.get(params, "id")) || Map.get(params, "name")
    Schema.taxonomy_domains(extensions, parent)
  end

  @doc """
  Get the schema modules.
  """
  swagger_path :modules do
    get("/api/modules")
    summary("List modules or get a specific module")

    description(
      "Get OASF schema modules. Returns all modules when no id or name is provided." <>
        " If id (numeric) or name (string) query parameter is provided, returns a single module." <>
        " Name can include an extension prefix (e.g., 'dev/cpu_usage')." <>
        " If both id and name are provided, they must refer to the same class."
    )

    produces("application/json")
    tag("Classes and Objects")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])

      id(
        :query,
        :integer,
        "Optional numeric ID to get a specific module.",
        required: false
      )

      name(
        :query,
        :string,
        "Optional name to get a specific module. Can include extension prefix (e.g., 'dev/cpu_usage').",
        required: false
      )
    end

    response(200, "Success")
    response(400, "Bad Request - id and name parameters refer to different classes")
    response(404, "Not Found - No module found with the specified id or name")
  end

  @spec modules(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def modules(conn, params) do
    profiles_opt = parse_options(profiles(params))

    handle_with_optional_id_and_name(
      conn,
      params,
      :modules,
      fn -> modules(params) end,
      fn id_or_name ->
        case find_class(:modules, id_or_name, profiles_opt) do
          nil -> nil
          data -> add_objects(data, params)
        end
      end
    )
  end

  @doc """
  Returns the list of modules.
  """
  @spec modules(map) :: map
  def modules(params) do
    extensions = parse_options(extensions(params))
    profiles = parse_options(profiles(params))

    Schema.modules(extensions, profiles)
    |> Enum.into(%{}, fn {k, v} -> {k, Schema.deep_clean(v)} end)
  end

  @doc """
  Get the schema skills.
  """
  swagger_path :skills do
    get("/api/skills")
    summary("List skills or get a specific skill")

    description(
      "Get OASF schema skills. Returns all skills when no id or name is provided." <>
        " If id (numeric) or name (string) query parameter is provided, returns a single skill." <>
        " Name can include an extension prefix (e.g., 'dev/cpu_usage')." <>
        " If both id and name are provided, they must refer to the same class."
    )

    produces("application/json")
    tag("Classes and Objects")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])

      id(
        :query,
        :integer,
        "Optional numeric ID to get a specific skill.",
        required: false
      )

      name(
        :query,
        :string,
        "Optional name to get a specific skill. Can include extension prefix (e.g., 'dev/cpu_usage').",
        required: false
      )
    end

    response(200, "Success")
    response(400, "Bad Request - id and name parameters refer to different classes")
    response(404, "Not Found - No skill found with the specified id or name")
  end

  @spec skills(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def skills(conn, params) do
    profiles_opt = parse_options(profiles(params))

    handle_with_optional_id_and_name(
      conn,
      params,
      :skills,
      fn -> skills(params) end,
      fn id_or_name ->
        case find_class(:skills, id_or_name, profiles_opt) do
          nil -> nil
          data -> add_objects(data, params)
        end
      end
    )
  end

  @doc """
  Returns the list of skills.
  """
  @spec skills(map) :: map
  def skills(params) do
    extensions = parse_options(extensions(params))
    profiles = parse_options(profiles(params))

    Schema.skills(extensions, profiles)
    |> Enum.into(%{}, fn {k, v} -> {k, Schema.deep_clean(v)} end)
  end

  @doc """
  Get the schema domains.
  """
  swagger_path :domains do
    get("/api/domains")
    summary("List domains or get a specific domain")

    description(
      "Get OASF schema domains. Returns all domains when no id or name is provided." <>
        " If id (numeric) or name (string) query parameter is provided, returns a single domain." <>
        " Name can include an extension prefix (e.g., 'dev/cpu_usage')." <>
        " If both id and name are provided, they must refer to the same class."
    )

    produces("application/json")
    tag("Classes and Objects")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])

      id(
        :query,
        :integer,
        "Optional numeric ID to get a specific domain.",
        required: false
      )

      name(
        :query,
        :string,
        "Optional name to get a specific domain. Can include extension prefix (e.g., 'dev/cpu_usage').",
        required: false
      )
    end

    response(200, "Success")
    response(400, "Bad Request - id and name parameters refer to different classes")
    response(404, "Not Found - No domain found with the specified id or name")
  end

  @spec domains(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def domains(conn, params) do
    profiles_opt = parse_options(profiles(params))

    handle_with_optional_id_and_name(
      conn,
      params,
      :domains,
      fn -> domains(params) end,
      fn id_or_name ->
        case find_class(:domains, id_or_name, profiles_opt) do
          nil -> nil
          data -> add_objects(data, params)
        end
      end
    )
  end

  @doc """
  Returns the list of domains.
  """
  @spec domains(map) :: map
  def domains(params) do
    extensions = parse_options(extensions(params))
    profiles = parse_options(profiles(params))

    Schema.domains(extensions, profiles)
    |> Enum.into(%{}, fn {k, v} -> {k, Schema.deep_clean(v)} end)
  end

  @doc """
  List objects or get a specific object by name.
  """
  swagger_path :objects do
    get("/api/objects")
    summary("List objects or get a specific object")

    description(
      "Get OASF schema objects. When a name is provided, returns a single object." <>
        " The object name may contain a schema extension name, for example \"dev/os_service\"."
    )

    produces("application/json")
    tag("Classes and Objects")

    parameters do
      name(:query, :string, "Object name to retrieve a specific object")

      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
    response(404, "Not Found - No object found with the specified name")
  end

  @spec objects(Plug.Conn.t(), map) :: Plug.Conn.t()
  def objects(conn, params) do
    profiles_opt = parse_options(profiles(params))
    extensions_opt = parse_options(extensions(params))
    name_param = Map.get(params, "name")

    if name_param == nil do
      send_json_resp(conn, objects(params))
    else
      case find_object(extensions_opt, name_param, profiles_opt) do
        nil ->
          send_json_resp(conn, 404, %{error: "No object found with name '#{name_param}'"})

        data ->
          send_json_resp(conn, add_objects(data, params))
      end
    end
  end

  @spec objects(map) :: map
  def objects(params) do
    extensions = parse_options(extensions(params))
    profiles = parse_options(profiles(params))

    Schema.objects(extensions, profiles)
    |> Enum.into(%{}, fn {k, v} -> {k, Schema.deep_clean(v)} end)
  end

  @doc """
  Get the complete OASF schema definitions.
  """
  swagger_path :schema do
    get("/api/schema")
    summary("Get schema")

    description(
      "Get OASF schema definitions, including data types, objects, classes," <>
        " and the dictionary of attributes."
    )

    produces("application/json")
    tag("Schema")

    parameters do
      extensions(:query, :array, "Related schema extensions to include in response.",
        items: [type: :string]
      )

      profiles(:query, :array, "Related profiles to include in response.", items: [type: :string])
    end

    response(200, "Success")
  end

  @spec schema(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def schema(conn, params) do
    profiles = parse_options(profiles(params))
    extensions = parse_options(extensions(params))
    data = Schema.schema(extensions, profiles)
    send_json_resp(conn, data)
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
  def json_skill_class(conn, %{"name" => name} = params) do
    options = Map.get(params, "package_name") |> parse_java_package()

    case skill_ex(name, params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Skill class #{name} not found"})

      data ->
        class = Schema.JsonSchema.encode(data, options)
        send_json_resp(conn, class)
    end
  end

  def skill_ex(name, params) do
    extension = extension(params)
    Schema.entity_ex(extension, :skill, name, parse_options(profiles(params)))
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
  def json_domain_class(conn, %{"name" => name} = params) do
    options = Map.get(params, "package_name") |> parse_java_package()

    case domain_ex(name, params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Domain class #{name} not found"})

      data ->
        class = Schema.JsonSchema.encode(data, options)
        send_json_resp(conn, class)
    end
  end

  def domain_ex(name, params) do
    extension = extension(params)
    Schema.entity_ex(extension, :domain, name, parse_options(profiles(params)))
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
  def json_module_class(conn, %{"name" => name} = params) do
    options = Map.get(params, "package_name") |> parse_java_package()

    case module_ex(name, params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Module class #{name} not found"})

      data ->
        class = Schema.JsonSchema.encode(data, options)
        send_json_resp(conn, class)
    end
  end

  def module_ex(name, params) do
    extension = extension(params)
    Schema.entity_ex(extension, :module, name, parse_options(profiles(params)))
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
  def json_object(conn, %{"name" => name} = params) do
    options = Map.get(params, "package_name") |> parse_java_package()

    case object_ex(name, params) do
      nil ->
        send_json_resp(conn, 404, %{error: "Object #{name} not found"})

      data ->
        object = Schema.JsonSchema.encode(data, options)
        send_json_resp(conn, object)
    end
  end

  def object_ex(name, params) do
    profiles = parse_options(profiles(params))
    extension = extension(params)
    extensions = parse_options(extensions(params))

    Schema.entity_ex(extensions, extension, :object, name, profiles)
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
        |1|Translate only the enumerated values|Untranslated:<br/><code>{"id": 10101}</code><br/><br/>Translated:<br/><code>{"id": 10101, "name": "analytical_skills/natural_language_processing/contextual_comprehension"}</code><br/><i>Note: Classes are automatically enriched with both id and name. For enum fields with siblings, the sibling field is also added.</i>|
        |2|Translate enumerated values and attribute names|Untranslated:<br/><code>{"id": 10101}</code><br/><br/>Translated:<br/><code>{"ID": 10101, "Name": "analytical_skills/natural_language_processing/contextual_comprehension"}</code><br/><i>Note: Attribute names are translated to their captions. Classes are automatically enriched with both id and name.</i>|
        |3|Verbose translation|Untranslated:<br/><code>{"id": 10101}</code><br/><br/>Translated:<br/><code>{"id": {"caption": "Contextual Comprehension","name": "ID","type": "integer_t","value": 10101}, "name": {"caption": "Name","name": "Name","type": "string_t","value": "analytical_skills/natural_language_processing/contextual_comprehension"}}</code>|
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
          |&lt;empty&gt;|The spaces in the translated names are removed.|Untranslated:<br/><code>{"id": 10101}</code><br/><br/>Translated:<br/><code>{"ID": "Contextual Comprehension"}</code>|
          |string|The spaces in the translated names are replaced with the given string.|For example, the string is an underscore (_).<br/>Untranslated:<br/><code>{"id": 10101}</code><br/><br/>Translated:<br/><code>{"ID": "Contextual Comprehension"}</code>|
        """,
        allowEmptyValue: true
      )

      data(:body, :object, "The skill class data to be translated", required: true)
    end

    response(200, "Success")
    response(400, "Bad Request - unexpected body, expected a JSON object or array")
  end

  @spec translate_skill(Plug.Conn.t(), map) :: Plug.Conn.t()
  def translate_skill(conn, params) do
    options = [
      spaces: conn.query_params[@spaces],
      verbose: verbose(conn.query_params[@verbose])
    ]

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
        |1|Translate only the enumerated values|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"id": 101, "name": "technology/internet_of_things"}</code><br/><i>Note: Classes are automatically enriched with both id and name. For enum fields with siblings, the sibling field is also added.</i>|
        |2|Translate enumerated values and attribute names|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"ID": 101, "Name": "technology/internet_of_things"}</code><br/><i>Note: Attribute names are translated to their captions. Classes are automatically enriched with both id and name.</i>|
        |3|Verbose translation|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"id": {"caption": "Internet of Things (IoT)","name": "ID","type": "integer_t","value": 101}, "name": {"caption": "Name","name": "Name","type": "string_t","value": "technology/internet_of_things"}}</code>|
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
          |&lt;empty&gt;|The spaces in the translated names are removed.|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"ID": "Internet of Things (IoT)"}</code>|
          |string|The spaces in the translated names are replaced with the given string.|For example, the string is an underscore (_).<br/>Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"ID": "Internet of Things (IoT)"}</code>|
        """,
        allowEmptyValue: true
      )

      data(:body, :object, "The domain class data to be translated", required: true)
    end

    response(200, "Success")
    response(400, "Bad Request - unexpected body, expected a JSON object or array")
  end

  @spec translate_domain(Plug.Conn.t(), map) :: Plug.Conn.t()
  def translate_domain(conn, params) do
    options = [
      spaces: conn.query_params[@spaces],
      verbose: verbose(conn.query_params[@verbose])
    ]

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
    summary("Translate module class")

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

        |Value|Description|Example|
        |-----|-----------|-------|
        |1|Translate only the enumerated values|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"id": 101, "name": "core/observability"}</code><br/><i>Note: Classes are automatically enriched with both id and name. For enum fields with siblings, the sibling field is also added.</i>|
        |2|Translate enumerated values and attribute names|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"ID": 101, "Name": "core/observability"}</code><br/><i>Note: Attribute names are translated to their captions. Classes are automatically enriched with both id and name.</i>|
        |3|Verbose translation|Untranslated:<br/><code>{"id": 101}</code><br/><br/>Translated:<br/><code>{"id": {"caption": "Observability","name": "ID","type": "integer_t","value": 101}, "name": {"caption": "Name","name": "Name","type": "string_t","value": "core/observability"}}</code>|
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

      data(:body, :object, "The module class data to be translated", required: true)
    end

    response(200, "Success")
    response(400, "Bad Request - unexpected body, expected a JSON object or array")
  end

  @spec translate_module(Plug.Conn.t(), map) :: Plug.Conn.t()
  def translate_module(conn, params) do
    options = [
      spaces: conn.query_params[@spaces],
      verbose: verbose(conn.query_params[@verbose])
    ]

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

        |Value|Description|Example|
        |-----|-----------|-------|
        |1|Translate only the enumerated values|Untranslated:<br/><code>{"type": 1}</code><br/><br/>Translated:<br/><code>{"type": 1}</code><br/><i>Note: For enum fields with siblings, the sibling field is added automatically.</i>|
        |2|Translate enumerated values and attribute names|Untranslated:<br/><code>{"type": 1}</code><br/><br/>Translated:<br/><code>{"Type": 1}</code><br/><i>Note: Attribute names are translated to their captions.</i>|
        |3|Verbose translation|Untranslated:<br/><code>{"type": 1}</code><br/><br/>Translated:<br/><code>{"type": {"caption": "Example Type","name": "Type","type": "integer_t","value": 1}}</code>|
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

      data(:body, :object, "The object data to be translated", required: true)
    end

    response(200, "Success")
    response(400, "Bad Request - unexpected body, expected a JSON object or array")
  end

  @spec translate_object(Plug.Conn.t(), map) :: Plug.Conn.t()
  def translate_object(conn, %{"name" => name} = params) do
    options = [
      name: name,
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

      data(:body, :object, "The skill class to be validated", required: true)
    end

    response(200, "Success")
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
    summary("Validate domain class")

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

      data(:body, :object, "The domain class to be validated", required: true)
    end

    response(200, "Success")
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
    summary("Validate module class")

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

      data(:body, :object, "The module class to be validated", required: true)
    end

    response(200, "Success")
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

      data(:body, :object, "The object to be validated", required: true)
    end

    response(200, "Success")
  end

  @spec validate_object(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def validate_object(conn, %{"name" => name} = params) do
    options = [
      name: name,
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
  def sample_skill(conn, %{"name" => name} = params) do
    sample_skill(conn, name, params)
  end

  defp sample_skill(conn, name, options) do
    extension = extension(options)
    profiles = profiles(options) |> parse_options()

    case Schema.skill(extension, name) do
      nil ->
        send_json_resp(conn, 404, %{error: "Skill class #{name} not found"})

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

    response(200, "Success")
    response(404, "Domain class <code>name</code> not found")
  end

  @spec sample_domain(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sample_domain(conn, %{"name" => name} = params) do
    sample_domain(conn, name, params)
  end

  defp sample_domain(conn, name, options) do
    extension = extension(options)
    profiles = profiles(options) |> parse_options()

    case Schema.domain(extension, name) do
      nil ->
        send_json_resp(conn, 404, %{error: "Domain class #{name} not found"})

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
  def sample_module(conn, %{"name" => name} = params) do
    sample_module(conn, name, params)
  end

  defp sample_module(conn, name, options) do
    extension = extension(options)
    profiles = profiles(options) |> parse_options()

    case Schema.module(extension, name) do
      nil ->
        send_json_resp(conn, 404, %{error: "Module class #{name} not found"})

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
  def sample_object(conn, %{"name" => name} = options) do
    extension = extension(options)
    profiles = profiles(options) |> parse_options()

    case Schema.object(extension, name) do
      nil ->
        send_json_resp(conn, 404, %{error: "Object #{name} not found"})

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

  defp add_objects(data, %{"objects" => "1"}) do
    objects = update_objects(Map.new(), data[:attributes])

    if map_size(objects) > 0 do
      Map.put(data, :entities, objects)
    else
      data
    end
    |> Schema.deep_clean()
  end

  defp add_objects(data, _params) do
    Schema.deep_clean(data)
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

          Map.put(acc, type, Schema.deep_clean(object))
          |> update_objects(object[:attributes])
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

  defp class_family_label(:skills), do: "skill"
  defp class_family_label(:domains), do: "domain"
  defp class_family_label(:modules), do: "module"

  # Shared handler for endpoints with optional id and name query parameters.
  # list_fn: zero-arity function returning all items when no filter is given.
  # find_fn: one-arity function accepting an integer id or string name; returns a
  #          result or nil when not found.
  #
  # When id is provided, find_fn is called with the parsed integer; 404 if nil.
  # When name is provided, find_fn is called with the string; 404 if nil.
  # When both are provided, both lookups run and must return the same result,
  # otherwise 400 is returned.
  defp handle_with_optional_id_and_name(conn, params, class_family, list_fn, find_fn) do
    id_param = Map.get(params, "id")
    name_param = Map.get(params, "name")
    id_int = parse_integer_param(id_param)
    label = class_family_label(class_family)

    cond do
      id_param != nil && id_int == nil ->
        send_json_resp(conn, 400, %{error: "Invalid id parameter: must be a numeric value"})

      id_int == nil && name_param == nil ->
        send_json_resp(conn, list_fn.())

      id_int != nil && name_param == nil ->
        case find_fn.(id_int) do
          nil -> send_json_resp(conn, 404, %{error: "No #{label} found with id #{id_int}"})
          result -> send_json_resp(conn, result)
        end

      id_int == nil ->
        case find_fn.(name_param) do
          nil ->
            send_json_resp(conn, 404, %{error: "No #{label} found with name '#{name_param}'"})

          result ->
            send_json_resp(conn, result)
        end

      true ->
        found_by_id = find_fn.(id_int)
        found_by_name = find_fn.(name_param)

        cond do
          found_by_id == nil ->
            send_json_resp(conn, 404, %{error: "No #{label} found with id #{id_int}"})

          found_by_name == nil ->
            send_json_resp(conn, 404, %{error: "No #{label} found with name '#{name_param}'"})

          found_by_id != found_by_name ->
            send_json_resp(conn, 400, %{
              error: "id #{id_int} and name '#{name_param}' refer to different #{label}s"
            })

          true ->
            send_json_resp(conn, found_by_id)
        end
    end
  end

  defp parse_integer_param(nil), do: nil
  defp parse_integer_param(id) when is_integer(id), do: id

  defp parse_integer_param(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, _} -> int
      :error -> nil
    end
  end

  @doc """
  Look up a single class by name (with optional extension prefix) and return
  cleaned data (internal fields stripped).  Returns nil when not found.
  """
  @spec class(atom(), String.t() | nil, String.t(), map() | nil) :: map() | nil
  def class(class_family, extension, name, profiles) do
    full_name = Schema.Utils.make_path(extension, name)

    case find_class(class_family, full_name, profiles) do
      nil -> nil
      data -> Schema.deep_clean(data)
    end
  end

  defp find_class(class_family, uid, profiles) when is_integer(uid) do
    class =
      case class_family do
        :skills -> Schema.find_skill(uid)
        :domains -> Schema.find_domain(uid)
        :modules -> Schema.find_module(uid)
      end

    case class do
      nil ->
        nil

      class ->
        if Map.get(class, :category) == true do
          nil
        else
          apply_profiles_to_class(class, profiles)
        end
    end
  end

  defp find_class(class_family, name, profiles) when is_binary(name) do
    direct =
      case class_family do
        :skills -> Schema.skill(nil, name, profiles)
        :domains -> Schema.domain(nil, name, profiles)
        :modules -> Schema.module(nil, name, profiles)
      end

    case direct do
      nil ->
        resolve_class_via_taxonomy(class_family, name, profiles)

      result ->
        result
    end
  end

  # Resolve a class name through the taxonomy tree.  Handles hierarchical names
  # like "core/language_model/prompt" that don't match simple cache keys.
  defp resolve_class_via_taxonomy(class_family, name, profiles) do
    taxonomy =
      case class_family do
        :skills -> Schema.taxonomy_skills(nil, name)
        :domains -> Schema.taxonomy_domains(nil, name)
        :modules -> Schema.taxonomy_modules(nil, name)
      end

    case Enum.to_list(taxonomy) do
      [{_key, %{id: uid}}] when is_integer(uid) and uid > 0 ->
        find_class(class_family, uid, profiles)

      _ ->
        nil
    end
  end

  defp apply_profiles_to_class(class, nil), do: class

  defp apply_profiles_to_class(class, profiles) do
    Map.update!(class, :attributes, fn attributes ->
      Schema.Utils.apply_profiles(attributes, profiles)
    end)
  end

  @doc """
  Look up a single object by name (with optional extension prefix) and return
  cleaned data (internal fields stripped).  Returns nil when not found.
  """
  @spec object(String.t() | nil, String.t() | nil, String.t(), map() | nil) :: map() | nil
  def object(extensions, extension, name, profiles) do
    case Schema.object(extensions, extension, name, profiles) do
      nil -> nil
      data -> Schema.deep_clean(data)
    end
  end

  defp find_object(extensions, name, profiles) do
    Schema.object(extensions, nil, name, profiles)
  end

  defp parse_java_package(nil), do: []
  defp parse_java_package(""), do: []
  defp parse_java_package(name), do: [package_name: name]

  # Convert sorted taxonomy tuple lists into JSON objects while preserving order.
  defp taxonomy_ordered_object(tree) when is_list(tree) do
    values =
      Enum.map(tree, fn {key, node} ->
        {to_string(key), taxonomy_ordered_node(node)}
      end)

    %Jason.OrderedObject{values: values}
  end

  defp taxonomy_ordered_object(tree) when is_map(tree) do
    tree
    |> Schema.Utils.sort_taxonomy_tree()
    |> taxonomy_ordered_object()
  end

  defp taxonomy_ordered_object(_), do: %Jason.OrderedObject{values: []}

  defp taxonomy_ordered_node(node) when is_map(node) do
    case Map.get(node, :classes) do
      nil ->
        node

      classes ->
        Map.put(node, :classes, taxonomy_ordered_object(classes))
    end
  end

  defp taxonomy_ordered_node(other), do: other

  defp version_response(base_url, schema_version, metadata) do
    %{
      :schema_version => schema_version,
      :server_version => version_metadata(metadata, :server_version, schema_version),
      :api_version => version_metadata(metadata, :api_version, schema_version),
      :url => "#{base_url}/#{schema_version}",
      :api_url => "#{base_url}/api/#{schema_version}"
    }
  end

  defp current_version_response(base_url, version) do
    %{
      :schema_version => version,
      :server_version => server_version(),
      :api_version => api_version(),
      :url => base_url,
      :api_url => "#{base_url}/api"
    }
  end

  defp default_version_response(base_url, available_versions) do
    case Enum.find(available_versions, fn {_schema_version, metadata} ->
           Map.get(metadata, :default) == true
         end) do
      {schema_version, metadata} ->
        %{
          :schema_version => schema_version,
          :server_version => version_metadata(metadata, :server_version, schema_version),
          :api_version => version_metadata(metadata, :api_version, schema_version),
          :url => base_url,
          :api_url => "#{base_url}/api"
        }

      nil ->
        current_version_response(base_url, Schema.version())
    end
  end

  defp base_url(conn) do
    url = Application.get_env(:schema_server, SchemaWeb.Endpoint)[:url]

    # The :url key is meant to be set for production, but isn't set for local development
    if url == nil do
      "#{conn.scheme}://#{conn.host}:#{conn.port}"
    else
      "#{conn.scheme}://#{Keyword.fetch!(url, :host)}:#{Keyword.fetch!(url, :port)}"
    end
  end

  defp server_version do
    Schema.build_version()
  end

  defp api_version do
    SchemaWeb.Router.swagger_info()[:info][:version]
  end

  defp version_metadata(metadata, key, schema_version) do
    case Map.get(metadata, key) do
      nil -> fallback_version_metadata(key, schema_version)
      value -> to_string(value)
    end
  end

  defp fallback_version_metadata(:server_version, schema_version) do
    if schema_version == Schema.version(), do: server_version(), else: nil
  end

  defp fallback_version_metadata(:api_version, schema_version) do
    if schema_version == Schema.version(), do: api_version(), else: nil
  end
end
