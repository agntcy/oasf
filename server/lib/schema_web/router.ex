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

    get "/", PageController, :main_skills

    get "/main_skills", PageController, :main_skills
    get "/main_skills/:id", PageController, :main_skills
    get "/main_skills/:extension/:id", PageController, :main_skills

    get "/main_domains", PageController, :main_domains
    get "/main_domains/:id", PageController, :main_domains
    get "/main_domains/:extension/:id", PageController, :main_domains

    get "/main_features", PageController, :main_features
    get "/main_features/:id", PageController, :main_features
    get "/main_features/:extension/:id", PageController, :main_features

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

    get "/features", PageController, :features
    get "/features/:id", PageController, :features
    get "/features/:extension/:id", PageController, :features

    get "/feature/graph/:id", PageController, :feature_graph
    get "/feature/graph/:extension/:id", PageController, :feature_graph

    get "/dictionary", PageController, :dictionary

    get "/objects", PageController, :objects
    get "/objects/:id", PageController, :objects
    get "/objects/:extension/:id", PageController, :objects

    get "/object/graph/:id", PageController, :object_graph
    get "/object/graph/:extension/:id", PageController, :object_graph

    get "/data_types", PageController, :data_types

    get "/agent_model", PageController, :agent_model
  end

  # Other scopes may use custom stacks.
  scope "/api", SchemaWeb do
    pipe_through :api

    get "/version", SchemaController, :version
    get "/versions", SchemaController, :versions

    get "/profiles", SchemaController, :profiles
    get "/extensions", SchemaController, :extensions

    get "/main_skills", SchemaController, :main_skills
    get "/main_skills/:id", SchemaController, :main_skill
    get "/main_skills/:extension/:id", SchemaController, :main_skill

    get "/main_domains", SchemaController, :main_domains
    get "/main_domains/:id", SchemaController, :main_domain
    get "/main_domains/:extension/:id", SchemaController, :main_domain

    get "/main_features", SchemaController, :main_features
    get "/main_features/:id", SchemaController, :main_feature
    get "/main_features/:extension/:id", SchemaController, :main_feature

    get "/profiles/:id", SchemaController, :profile
    get "/profiles/:extension/:id", SchemaController, :profile

    get "/skills", SchemaController, :skills
    get "/skills/:id", SchemaController, :skill
    get "/skills/:extension/:id", SchemaController, :skill

    get "/domains", SchemaController, :domains
    get "/domains/:id", SchemaController, :domain
    get "/domains/:extension/:id", SchemaController, :domain

    get "/features", SchemaController, :features
    get "/features/:id", SchemaController, :feature
    get "/features/:extension/:id", SchemaController, :feature

    get "/dictionary", SchemaController, :dictionary

    get "/objects", SchemaController, :objects
    get "/objects/:id", SchemaController, :object
    get "/objects/:extension/:id", SchemaController, :object

    get "/data_types", SchemaController, :data_types

    post "/translate/skill", SchemaController, :translate_skill
    post "/validate/skill", SchemaController, :validate_skill
    post "/validate_bundle/skill", SchemaController, :validate_bundle_skill

    post "/translate/domain", SchemaController, :translate_domain
    post "/validate/domain", SchemaController, :validate_domain
    post "/validate_bundle/domain", SchemaController, :validate_bundle_domain

    post "/translate/feature", SchemaController, :translate_feature
    post "/validate/feature", SchemaController, :validate_feature
    post "/validate_bundle/feature", SchemaController, :validate_bundle_feature

    post "/translate/object/:id", SchemaController, :translate_object
    post "/validate/object/:id", SchemaController, :validate_object
  end

  scope "/schema", SchemaWeb do
    pipe_through :api

    get "/skills/:id", SchemaController, :json_skill_class
    get "/skills/:extension/:id", SchemaController, :json_skill_class

    get "/domains/:id", SchemaController, :json_domain_class
    get "/domains/:extension/:id", SchemaController, :json_domain_class

    get "/features/:id", SchemaController, :json_feature_class
    get "/features/:extension/:id", SchemaController, :json_feature_class

    get "/objects/:id", SchemaController, :json_object
    get "/objects/:extension/:id", SchemaController, :json_object
  end

  scope "/export", SchemaWeb do
    pipe_through :api

    get "/skills", SchemaController, :export_skills
    get "/domains", SchemaController, :export_domains
    get "/features", SchemaController, :export_features
    get "/objects", SchemaController, :export_objects
    get "/schema", SchemaController, :export_schema
  end

  scope "/sample", SchemaWeb do
    pipe_through :api

    get "/skills/:id", SchemaController, :sample_skill
    get "/skills/:extension/:id", SchemaController, :sample_skill

    get "/domains/:id", SchemaController, :sample_domain
    get "/domains/:extension/:id", SchemaController, :sample_domain

    get "/features/:id", SchemaController, :sample_feature
    get "/features/:extension/:id", SchemaController, :sample_feature

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
          "The Open Agents Schema Framework (OASF) server API allows to access the JSON" <>
            " schema definitions and to validate and translate objects.",
        license: %{
          name: "Apache 2.0",
          url: "http://www.apache.org/licenses/LICENSE-2.0.html"
        },
        version: "0.4.0"
      }
    }
  end
end
