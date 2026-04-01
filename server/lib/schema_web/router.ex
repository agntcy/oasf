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

  pipeline :health do
  end

  scope "/", SchemaWeb do
    pipe_through :health

    get "/healthz", HealthController, :check
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
    get "/profiles/:name", PageController, :profiles
    get "/profiles/:extension/:name", PageController, :profiles

    get "/skills", PageController, :skills
    get "/skills/:name", PageController, :skills
    get "/skills/:extension/:name", PageController, :skills

    get "/skill/graph/:name", PageController, :skill_graph
    get "/skill/graph/:extension/:name", PageController, :skill_graph

    get "/domains", PageController, :domains
    get "/domains/:name", PageController, :domains
    get "/domains/:extension/:name", PageController, :domains

    get "/domain/graph/:name", PageController, :domain_graph
    get "/domain/graph/:extension/:name", PageController, :domain_graph

    get "/modules", PageController, :modules
    get "/modules/:name", PageController, :modules
    get "/modules/:extension/:name", PageController, :modules

    get "/module/graph/:name", PageController, :module_graph
    get "/module/graph/:extension/:name", PageController, :module_graph

    get "/dictionary", PageController, :dictionary

    get "/objects", PageController, :objects
    get "/objects/:name", PageController, :objects
    get "/objects/:extension/:name", PageController, :objects

    get "/object/graph/:name", PageController, :object_graph
    get "/object/graph/:extension/:name", PageController, :object_graph

    get "/data_types", PageController, :data_types
  end

  # Other scopes may use custom stacks.
  scope "/api", SchemaWeb do
    pipe_through :api

    get "/version", SchemaController, :version
    get "/versions", SchemaController, :versions

    get "/profiles", SchemaController, :profiles
    get "/extensions", SchemaController, :extensions

    get "/profiles/:name", SchemaController, :profile
    get "/profiles/:extension/:name", SchemaController, :profile

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
    get "/schema", SchemaController, :schema

    post "/translate/skill", SchemaController, :translate_skill
    post "/validate/skill", SchemaController, :validate_skill

    post "/translate/domain", SchemaController, :translate_domain
    post "/validate/domain", SchemaController, :validate_domain

    post "/translate/module", SchemaController, :translate_module
    post "/validate/module", SchemaController, :validate_module

    post "/translate/object/:name", SchemaController, :translate_object
    post "/validate/object/:name", SchemaController, :validate_object
  end

  scope "/schema", SchemaWeb do
    pipe_through :api

    get "/skills/:name", SchemaController, :json_skill_class
    get "/skills/:extension/:name", SchemaController, :json_skill_class

    get "/domains/:name", SchemaController, :json_domain_class
    get "/domains/:extension/:name", SchemaController, :json_domain_class

    get "/modules/:name", SchemaController, :json_module_class
    get "/modules/:extension/:name", SchemaController, :json_module_class

    get "/objects/:name", SchemaController, :json_object
    get "/objects/:extension/:name", SchemaController, :json_object
  end

  scope "/sample", SchemaWeb do
    pipe_through :api

    get "/skills/:name", SchemaController, :sample_skill
    get "/skills/:extension/:name", SchemaController, :sample_skill

    get "/domains/:name", SchemaController, :sample_domain
    get "/domains/:extension/:name", SchemaController, :sample_domain

    get "/modules/:name", SchemaController, :sample_module
    get "/modules/:extension/:name", SchemaController, :sample_module

    get "/objects/:name", SchemaController, :sample_object
    get "/objects/:extension/:name", SchemaController, :sample_object
  end

  # Version-aware Swagger UI routes
  scope "/doc" do
    get "/", SchemaWeb.SwaggerController, :swagger_ui
  end

  scope "/:version/doc" do
    get "/", SchemaWeb.SwaggerController, :swagger_ui
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
        version: "0.6.0"
      }
    }
  end
end
