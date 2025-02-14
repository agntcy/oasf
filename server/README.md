# Open Agents Schema Framework Server

This directory contains the Open Agents Schema Framework (OASF) Schema Server source code.
The schema server is an HTTP server that provides a convenient way to browse and use the OASF schema.

You can access the OASF schema server, which is running the latest released schema, at [schema.oasf.io](https://schema.oasf.io).

The schema server can be also used locally. To do that clone the `oasf-server` and `oasf-schema` repositories and follow the instruction below to build and run the schema server.

## Clone the OAFS schema (`oasf-schema`) repository

```shell
git clone https://github.com/agntcy/oasf.git
```

## Build a server docker image

```shell
cd oasf/server
docker build -t oasf-server .
```

## Run the server docker image

Change the `/path/to` to your local OASF schema directory (use an absolute path). Note, the `-p 8443:8443` parameter enables HTTPS with a self-signed SSL certificate.

```shell
docker run -it --rm --volume /path/to/oasf/schema:/app/schema -p 8080:8080 -p 8443:8443 oasf-server
```

For example, if the `oasf-schema` and `oasf-server` repos were cloned to the local directory `~/github-projects`, this would be the proper replacement for `/path/to`:

```shell
docker run -it --rm --volume ~/github-projects/oasf/schema:/app/schema -p 8080:8080 -p 8443:8443 oasf-server
```

(Note that paths used for volume mounts with `docker run` cannot be relative.)

To access the schema server, open [`localhost:8080`](http://localhost:8080) or [`localhost:8443`](https://localhost:8443) in your Web browser.

## Development with docker-compose

The `docker-compose` environment enables development without needing to install any dependencies (apart from Docker/Podman and docker-compose) on the development machine.

When run, the standard `_build` and `deps` folders are created, along with a `.mix` folder. If the environment needs to be recreated for whatever reason, the `_build` folder can be removed and `docker-compose` brought down and up again and the environment will automatically rebuild.

### Run the oasf-server and build the development container

```shell
docker-compose up
```

Then browse to the schema server at http://localhost:8080

### Testing the schema with docker-compose

**NOTE:** it is _not_ necessary to run the server with `docker-compose up` first in order to test the schema (or run any other commands in the development container).

```
# docker-compose run oasf-elixir mix test
Creating oasf-server_oasf-elixir_run ... done
Emulate Docker CLI using podman. Create /etc/containers/nodocker to quiet msg.


Finished in 0.00 seconds (0.00s async, 0.00s sync)
0 failures

Randomized with seed 933777
```

### Set aliases to avoid docker-compose inflicted RSI

```shell
source docker-source.sh
```

### Using aliases to run docker-compose commands

```
# testschema
Creating oasf-server_oasf-elixir_run ... done
Emulate Docker CLI using podman. Create /etc/containers/nodocker to quiet msg.


Finished in 0.00 seconds (0.00s async, 0.00s sync)
0 failures

Randomized with seed 636407
```

### Using environment variables to change docker-compose defaults

Optional environment variables can be placed in a `.env` file in the root of the repo to change the default behavior.

An `.env.sample` is provided, and the following options are available:

```
SCHEMA_PATH=../oasf-schema      # Set the local schema path, eg. ../oasf-schema, defaults to ../oasf-schema
OASF_SERVER_PORT=8080           # Set the port for Docker to listen on for forwarding traffic to the Schema server, defaults to 8080
ELIXIR_VERSION=otp-25-alpine    # Set the Elixir container version for development, defaults to otp-25-alpine
```

## Local Usage

This section describes how to build and run the OASF Schema server.

### Required build tools

The Schema server is written in [Elixir](https://elixir-lang.org) using the [Phoenix](https://phoenixframework.org/) Web framework.

The Elixir site maintains a great installation page, see https://elixir-lang.org/install.html for help.

### Building the schema server

Elixir uses the [`mix`](https://hexdocs.pm/mix/Mix.html) build tool, which is included in the Elixir installation package.

#### Install the build tools

```shell
mix local.hex --force && mix local.rebar --force
```

#### Get the dependencies

Change to the schema directory, fetch and compile the dependencies:

```shell
cd oasf-server
mix do deps.get, deps.compile
```

#### Compile the source code

```shell
mix compile
```

### Testing local schema changes

You can use `mix test` command to test the changes made to the schema. For example to ensure the JSON files are correct or the attributes are defined.

Assuming the schema repo has been cloned in `../oasf-schema` directory, then you can test the schema with this command:

```shell
SCHEMA_DIR=../oasf-schema SCHEMA_EXTENSION=extensions mix test
```

If everything is correct, then you should not see any errors or warnings.

### Running the schema server

You can use the Elixir's interactive shell, [IEx](https://hexdocs.pm/iex/IEx.html), to start the schema server use:

```shell
SCHEMA_DIR=../oasf-schema SCHEMA_EXTENSION=extensions iex -S mix phx.server
```

Now you can access the Schema server at [`localhost:8080`](http://localhost:8080) or [`localhost:8443`](https://localhost:8443).

### Reloading the schema

You can use the following command in the `iex` shell to force reloading the schema with extensions:

```elixir
Schema.reload(["<extension folder>", "<extension folder>", ...])
```

Reload the core schema without extensions:

```elixir
Schema.reload()
```

Reload the schema only with the `linux` extension (note the folder is relative to the `SCHEMA_DIR` folder):

```elixir
Schema.reload(["extensions/linux"])
```

Reload the schema with all extensions defined in the `extensions` folder (note the folder is relative to the `SCHEMA_DIR` folder):

```elixir
Schema.reload(["extensions"])
```

Reload the schema with extensions defined outside the `SCHEMA_DIR` folder (use an absolute or relative path):

```elixir
Schema.reload(["/home/schema/cloud", "../dev-ext"])
```

### Runtime configuration

The schema server uses a number of environment variables.

| Variable Name    | Description                                                                               |
| ---------------- | ----------------------------------------------------------------------------------------- |
| HTTP_PORT        | The server HTTP port number, default: `8080`                                              |
| HTTPS_PORT       | The server HTTPS port number, default: `8443`                                             |
| SCHEMA_DIR       | The directory containing the schema, default: `../oasf-schema`                            |
| SCHEMA_EXTENSION | The directory containing the schema extensions, relative to SCHEMA_DIR or absolute path   |
| RELEASE_NODE     | The Erlang node name. Set it if you want to run more than one server on the same computer |

```shell
SCHEMA_DIR=../oasf-schema SCHEMA_EXTENSION=extensions iex -S mix phx.server
```
