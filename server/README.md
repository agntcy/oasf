# Open Agentic Schema Framework Server

This directory contains the Open Agents Schema Framework (OASF) Schema Server source code.
The schema server is an HTTP server that provides a convenient way to browse and use the OASF schema.

You can access the OASF schema server, which is running the latest released schema, at [schema.oasf.agntcy.org](https://schema.oasf.agntcy.org).

The schema server can also be used locally.

## Clone the OAFS schema and server (`oasf`) repository

```shell
git clone https://github.com/agntcy/oasf.git
```

## Build a server docker image

```shell
task server:build
task server:run
```

To access the schema server, open [`localhost:8080`](http://localhost:8080) or [`localhost:8443`](https://localhost:8443) in your Web browser.

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
cd server
mix do deps.get, deps.compile
```

#### Compile the source code

```shell
mix compile
```

### Testing local schema changes

You can use `mix test` command to test the changes made to the schema. For example to ensure the JSON files are correct or the attributes are defined.

Assuming the schema repo is in `../schema` directory, then you can test the schema with this command:

```shell
SCHEMA_DIR=../schema SCHEMA_EXTENSION=extensions mix test
```

If everything is correct, then you should not see any errors or warnings.

### Running the schema server

You can use the Elixir's interactive shell, [IEx](https://hexdocs.pm/iex/IEx.html), to start the schema server use:

```shell
SCHEMA_DIR=../schema SCHEMA_EXTENSION=extensions iex -S mix phx.server
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
| SCHEMA_DIR       | The directory containing the schema, default: `../schema`                                 |
| SCHEMA_EXTENSION | The directory containing the schema extensions, relative to SCHEMA_DIR or absolute path   |
| RELEASE_NODE     | The Erlang node name. Set it if you want to run more than one server on the same computer |

```shell
SCHEMA_DIR=../schema SCHEMA_EXTENSION=extensions iex -S mix phx.server
```
