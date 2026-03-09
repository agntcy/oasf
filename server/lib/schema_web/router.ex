# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.Router do
  use SchemaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SchemaWeb do
    pipe_through :browser

    get "/", PageController, :skill_categories

    get "/skill_categories", PageController, :skill_categories
    get "/skill_categories/:name", PageController, :skill_categories
    get "/skill_categories/:extension/:name", PageController, :skill_categories

    get "/domain_categories", PageController, :domain_categories
    get "/domain_categories/:name", PageController, :domain_categories
    get "/domain_categories/:extension/:name", PageController, :domain_categories

    get "/module_categories", PageController, :module_categories
    get "/module_categories/:name", PageController, :module_categories
    get "/module_categories/:extension/:name", PageController, :module_categories

    get "/profiles", PageController, :profiles
    get "/profiles/:id", PageController, :profiles
    get "/profiles/:extension/:id", PageController, :profiles

    get "/skills", PageController, :skills
    get "/skills/:id", PageController, :skills
    get "/skills/:extension/:id", PageController, :skills

    get "/skill/graph/:id", PageController, :skill_graph
    get "/skill/graph/:extension/:id", PageController, :skill_graph

    get "/domains", PageController, :domains
    get "/domains/:id", PageController, :domains
    get "/domains/:extension/:id", PageController, :domains

    get "/domain/graph/:id", PageController, :domain_graph
    get "/domain/graph/:extension/:id", PageController, :domain_graph

    get "/modules", PageController, :modules
    get "/modules/:id", PageController, :modules
    get "/modules/:extension/:id", PageController, :modules

    get "/module/graph/:id", PageController, :module_graph
    get "/module/graph/:extension/:id", PageController, :module_graph

    get "/dictionary", PageController, :dictionary

    get "/objects", PageController, :objects
    get "/objects/:id", PageController, :objects
    get "/objects/:extension/:id", PageController, :objects

    get "/object/graph/:id", PageController, :object_graph
    get "/object/graph/:extension/:id", PageController, :object_graph

    get "/data_types", PageController, :data_types
  end

  # Other scopes may use custom stacks.
  scope "/api", SchemaWeb do
    pipe_through :api

    get "/version", SchemaController, :version
    get "/versions", SchemaController, :versions

    get "/profiles", SchemaController, :profiles
    get "/extensions", SchemaController, :extensions

    get "/profiles/:id", SchemaController, :profile
    get "/profiles/:extension/:id", SchemaController, :profile

    get "/dictionary", SchemaController, :dictionary

    # Categories API group
    get "/module_categories", SchemaController, :module_categories
    get "/skill_categories", SchemaController, :skill_categories
    get "/domain_categories", SchemaController, :domain_categories

    # Classes and Objects API group
    get "/modules", SchemaController, :modules

    get "/skills", SchemaController, :skills

    get "/domains", SchemaController, :domains

    get "/objects", SchemaController, :objects

    get "/data_types", SchemaController, :data_types
    get "/schema", SchemaController, :export_schema

    post "/translate/skill", SchemaController, :translate_skill
    post "/validate/skill", SchemaController, :validate_skill
    post "/validate_bundle/skill", SchemaController, :validate_bundle_skill

    post "/translate/domain", SchemaController, :translate_domain
    post "/validate/domain", SchemaController, :validate_domain
    post "/validate_bundle/domain", SchemaController, :validate_bundle_domain

    post "/translate/module", SchemaController, :translate_module
    post "/validate/module", SchemaController, :validate_module
    post "/validate_bundle/module", SchemaController, :validate_bundle_module

    post "/translate/object/:id", SchemaController, :translate_object
    post "/validate/object/:id", SchemaController, :validate_object
  end

  scope "/schema", SchemaWeb do
    pipe_through :api

    get "/skills/:id", SchemaController, :json_skill_class
    get "/skills/:extension/:id", SchemaController, :json_skill_class

    get "/domains/:id", SchemaController, :json_domain_class
    get "/domains/:extension/:id", SchemaController, :json_domain_class

    get "/modules/:id", SchemaController, :json_module_class
    get "/modules/:extension/:id", SchemaController, :json_module_class

    get "/objects/:id", SchemaController, :json_object
    get "/objects/:extension/:id", SchemaController, :json_object
  end

  scope "/sample", SchemaWeb do
    pipe_through :api

    get "/skills/:id", SchemaController, :sample_skill
    get "/skills/:extension/:id", SchemaController, :sample_skill

    get "/domains/:id", SchemaController, :sample_domain
    get "/domains/:extension/:id", SchemaController, :sample_domain

    get "/modules/:id", SchemaController, :sample_module
    get "/modules/:extension/:id", SchemaController, :sample_module

    get "/objects/:id", SchemaController, :sample_object
    get "/objects/:extension/:id", SchemaController, :sample_object
  end

  scope "/doc" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :schema_server,
      swagger_file: "swagger.json"
  end

  def swagger_info do
    %{
      info: %{
        title: "The OASF Schema API",
        description:
          "The Open Agentic Schema Framework (OASF) server API allows to access the JSON" <>
            " schema definitions and to validate and translate objects.",
        license: %{
          name: "Apache 2.0",
          url: "http://www.apache.org/licenses/LICENSE-2.0.html"
        },
        version: "0.5.2"
      }
    }
  end
end
