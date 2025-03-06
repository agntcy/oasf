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

Note that any changes made to the schema or server backend itself will require running `task up` again.

### Hot reload

In order to run the server in hot-reload mode, you must first deploy
the services, and run another command to signal that the schema will be actively updated.

This can be achieved by starting an interactive reload session via:

```shell
task reload
```

Note that this will only perform hot-reload for schema changes.
Reloading backend changes still requires re-running `task build && task up`.

### Cleanup

This step will handle cleanup procedure by
removing resources from previous steps,
including ephemeral Kind clusters and Docker containers.

```shell
task down
```

## Artifacts distribution

See https://github.com/orgs/agntcy/packages?repo_name=oasf

### Container images

```bash
docker pull ghcr.io/agntcy/oasf-server:latest
```

### Helm charts

```bash
helm pull oci://ghcr.io/agntcy/oasf/helm-charts/oasf --version latest
```

## Copyright Notice

[Copyright Notice and License](./LICENSE.md)

Copyright (c) 2025 Cisco and/or its affiliates.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.# dir
