# Open Agentic Schema Framework

The [Open Agentic Schema Framework (OASF)](https://schema.oasf.outshift.com/) is
a standardized schema system for defining and managing AI agent capabilities,
interactions, and metadata.
It provides a structured way to describe agent attributes, capabilities, and
relationships using attribute-based taxonomies.
The framework includes development tools, schema validation, and hot-reload
capabilities for rapid schema development, all managed through a Taskfile-based
workflow and containerized development environment.
OASF serves as the foundation for interoperable AI agent systems, enabling
consistent definition and discovery of agent capabilities across distributed
systems.

OASF is highly inspired from
[OCSF (Open Cybersecurity Schema Framework)](https://ocsf.io/) in terms of data
modeling philosophy but also in terms of implementation.
The server is a derivative work of OCSF schema server and the schema update
workflows reproduce those developed by OCSF.

## Features

OASF defines a set of standards for agentic AI content representation that aims
to:

- Define common data structure to facilitate content standardization,
  validation, and interoperability.
- Ensure unique agent identification to address content discovery and
  consumption.
- Provide extension capabilities to enable third-party features.

## Key Concepts

At the core of OASF is the [record object](./schema/objects/record.json), which
serves as the primary data structure for representing collections of information
and metadata relevant to agentic AI applications.

OASF records can be annotated with **skills** and **domains** to enable
effective announcement and discovery across agentic systems.
Additionally, **modules** provide a flexible mechanism to extend records with
additional information in a modular and composable way, supporting a wide range
of agentic use cases.

## Schema Expansion and Contributions

The Open Agentic Schema Framework (OASF) is designed with extensibility in mind
and is expected to evolve to capture new use cases and capabilities.
A key area of anticipated expansion includes the definition and management of
**Skills**, **Domains** and **Modules** for AI agentic records.

We welcome contributions from the community to help shape the future of OASF.
For detailed guidelines on how to contribute, including information on proposing
new features, reporting bugs, and submitting code, please refer to our
[contributing guide](CONTRIBUTING.md).

OASF can be extended with private schema extensions, allowing you to leverage
all features of the framework, such as validation.
See the relevant section in the
[contributing guide](./CONTRIBUTING.md#oasf-extensions) for instructions on
adding an extension to the schema.
An OASF instance with schema extensions can be hosted, allowing you to use your
own schema server for record validation.

Alternatively, records can be extended by adding arbitrary JSON objects to the
`modules` list, using module names that do not conflict with existing OASF
modules.
However, this approach is the least recommended, as validation will be skipped
for these modules if the record is validated against the standard OASF schema.

## Useful Links

A convenient way to browse and use the OASF schema is through the
[Open Agentic Schema Framework Server](https://schema.oasf.outshift.com) hosted
by Outshift by Cisco.

To deploy the server either locally or as a hosted service, see the
[server's guide](oasf-server.md) for more information.

See
[Creating an Agent Record](https://docs.agntcy.org/how-to-guides/agent-record-guide/)
for more information on the Agent Record.

The current skill set taxonomy is described in
[Taxonomy of AI Agent Skills](https://schema.oasf.outshift.com/main_skills).

## Open Agentic Schema Framework Server

The `server/` directory contains the Open Agentic Schema Framework (OASF) Schema
Server source code.
The schema server is an HTTP server that provides a convenient way to browse and
use the OASF schema.
The server provides also schema validation capabilities to be used during
development.

You can access the OASF schema server, which is running the latest released
schema, at [schema.oasf.outshift.com](https://schema.oasf.outshift.com).

The schema server can also be used locally.

## Development

Use `Taskfile` for all related development operations such as testing,
validating, deploying, and working with the project.

Check the [example.env](example.env) to see the configuration for the operations
below.

### Prerequisites

- [Taskfile](https://taskfile.dev/)
- [Docker](https://www.docker.com/)
- [Go](https://go.dev/)
- [yq](https://github.com/mikefarah/yq)
- [curl](https://curl.se/)
- [tar](https://www.gnu.org/software/tar/)

Make sure Docker is installed with Buildx.

### Clone the Repository

```shell
git clone https://github.com/agntcy/oasf.git
```

### Build Artifacts

This step will fetch all project dependencies and subsequently build all project
artifacts such as helm charts and Docker images.

```shell
task deps
task build
```

### Deploy Locally

This step will create an ephemeral Kind cluster and deploy OASF services via
Helm chart.
It also sets up port forwarding so that the services can be accessed locally.

```shell
IMAGE_TAG=latest task build:images
task up
```

To access the schema server, open [`localhost:8080`](http://localhost:8080) in
your browser.

**Note:** Any changes made to the server backend itself will require running
`task up` again.

To set your own local OASF server using Elixir tooling, follow
[these instructions](https://github.com/agntcy/oasf/blob/main/server/README.md).

### Hot Reload

In order to run the server in hot-reload mode, you must first deploy the
services, and run another command to signal that the schema will be actively
updated.

This can be achieved by starting an interactive reload session via:

```shell
task reload
```

**Note:** This will only perform hot-reload for schema changes.
Reloading backend changes still requires re-running `task build && task up`.

### Deploy Locally with Multiple Versions

Trying out OASF locally with multiple versions is also possible, with updating
the `install/charts/oasf/values-test-versions.yaml` file with the required
versions and deploying OASF services on the ephemeral Kind cluster with those
values.

```
HELM_VALUES_PATH=./install/charts/oasf/values-test-versions.yaml task up
```

### Cleanup

This step will handle cleanup procedure by removing resources from previous
steps, including ephemeral Kind clusters and Docker containers.

```shell
task down
```

## Distribution

### Artifacts

See
[AGNTCY Github Registry](https://github.com/orgs/agntcy/packages?repo_name=oasf).

### Protocol Buffer Definitions

The `proto` directory contains the Protocol Buffer (`.proto`) files defining our
data objects and APIs.
The full proto module, generated language stubs and it's versions are hosted at
the Buf Schema Registry:
[https://buf.build/agntcy/oasf](https://buf.build/agntcy/oasf)

## Copyright Notice

[Copyright Notice and License](./LICENSE.md)

Distributed under Apache 2.0 License.
See LICENSE for more information.
Copyright AGNTCY Contributors (https://github.com/agntcy)
