# Open Agentic Schema Framework

The Open Agentic Schema Framework (OASF) is a standardized schema system for
defining and managing AI agent capabilities, interactions, and metadata. It
provides a structured way to describe agent attributes, capabilities, and
relationships using attribute-based taxonomies. The framework includes
development tools, schema validation, and hot-reload capabilities for rapid
schema development, all managed through a Taskfile-based workflow and
containerized development environment. OASF serves as the foundation for
interoperable AI agent systems, enabling consistent definition and discovery of
agent capabilities across distributed systems.

OASF is highly inspired from OCSF (Open Cybersecurity Schema Framework) in terms of data modeling philosophy but also in terms of implementation.
The server is a derivative work of OCSF schema server and the schema update
workflows reproduce those developed by OCSF.


## Features

OASF defines a set of standards for AI agent content representation that aims to:

- Define common data structure to facilitate content standardization, validation, and interoperability
- Ensure unique agent identification to address content discovery and consumption
- Provide extension capabilities to enable third-party features

### Open Agentic Schema Framework Server

The server/ directory contains the Open Agents Schema Framework (OASF) Schema Server source code.
The schema server is an HTTP server that provides a convenient way to browse and use the OASF schema.
The server provides also schema validation capabilities to be used during development.

You can access the OASF schema server, which is running the latest released schema, at [schema.oasf.agntcy.org](https://schema.oasf.agntcy.org).

The schema server can also be used locally.

## Prerequisites

- [Taskfile](https://taskfile.dev/)
- [Docker](https://www.docker.com/)

Make sure Docker is installed with Buildx.

## Development

Use `Taskfile` for all related development operations such as testing, validating, deploying, and working with the project.

Check the [example.env](example.env) to see the configuration for the operations below.

### Clone the repository

```shell
git clone https://github.com/agntcy/oasf.git
```

### Build artifacts

This step will fetch all project dependencies and
subsequently build all project artifacts such as
helm charts and docker images.

```shell
task deps
task build
```

### Deploy locally

This step will create an ephemeral Kind cluster
and deploy OASF services via Helm chart.
It also sets up port forwarding
so that the services can be accessed locally.

```shell
task up
```

To access the schema server, open [`localhost:8080`](http://localhost:8080) in your Web browser.

Note that any changes made to the server backend itself will require running `task up` again.

### Hot reload

In order to run the server in hot-reload mode, you must first deploy
the services, and run another command to signal that the schema will be actively updated.

This can be achieved by starting an interactive reload session via:

```shell
task reload
```

Note that this will only perform hot-reload for schema changes.
Reloading backend changes still requires re-running `task build && task up`.

### Deploy locally with multiple versions

Trying out OASF locally with multiple versions is also possible, with updating the
`install/charts/oasf/values-test-versions.yaml` file with the required versions and deploying OASF services on the
ephemeral Kind cluster with those values.

```
HELM_VALUES_PATH=./install/charts/oasf/values-test-versions.yaml task up
```

### Cleanup

This step will handle cleanup procedure by
removing resources from previous steps,
including ephemeral Kind clusters and Docker containers.

```shell
task down
```

## Artifacts distribution

See https://github.com/orgs/agntcy/packages?repo_name=oasf

## Copyright Notice

[Copyright Notice and License](./LICENSE.md)

Distributed under Apache 2.0 License. See LICENSE for more information.
Copyright AGNTCY Contributors (https://github.com/agntcy)
