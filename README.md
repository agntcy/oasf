# Open Agentic Schema Framework

![GitHub Release (latest by date)](https://img.shields.io/github/v/release/agntcy/oasf)
[![CI](https://github.com/agntcy/oasf/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/agntcy/oasf/actions/workflows/ci.yaml)
[![License](https://img.shields.io/github/license/agntcy/oasf)](./LICENSE.md)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/agntcy/oasf/badge)](https://scorecard.dev/viewer/?uri=github.com/agntcy/oasf)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/14994/badge)](https://www.bestpractices.dev/projects/14994)

The [Open Agentic Schema Framework (OASF)](https://schema.oasf.outshift.com/) is a standardized schema system for
defining and managing AI agent capabilities, interactions, and metadata.
It provides a structured way to describe agent attributes, capabilities, and relationships using attribute-based
taxonomies.
The framework includes development tools, schema validation, and hot-reload capabilities for rapid schema development,
all managed through a Taskfile-based workflow.
OASF serves as the foundation for interoperable AI agent systems, enabling consistent definition and discovery of agent
capabilities across distributed systems.

OASF is highly inspired from [OCSF (Open Cybersecurity Schema Framework)](https://ocsf.io/) in terms of data modeling
philosophy but also in terms of implementation.
The schema update workflows reproduce those developed by OCSF, and the [OASF server](https://github.com/agntcy/oasf-server) is a
derivative work of the OCSF schema server.

## Features

OASF defines a set of standards for agentic AI content representation that aims to:

- Define common data structure to facilitate content standardization, validation, and interoperability.
- Ensure unique agent identification to address content discovery and consumption.
- Provide extension capabilities to enable third-party features.

## Key Concepts

At the core of OASF is the [record object](./schema/objects/record.json), which serves as the primary data structure for
representing collections of information and metadata relevant to agentic AI applications.

OASF records can be annotated with **skills** and **domains** to enable effective announcement and discovery across
agentic systems.
Formats other than OASF records, such as A2A Agent Cards and AI Catalog entries, can carry the same skills and domains
through the [discovery extension](https://docs.agntcy.org/oasf/discovery-extension/).
Additionally, **modules** provide a flexible mechanism to extend records with additional information in a modular and
composable way, supporting a wide range of agentic use cases.

## Schema Expansion and Contributions

The Open Agentic Schema Framework (OASF) is designed with extensibility in mind and is expected to evolve to capture new
use cases and capabilities.
A key area of anticipated expansion includes the definition and management of **Skills**, **Domains** and **Modules**
for AI agentic records.

We welcome contributions from the community to help shape the future of OASF.
For detailed guidelines on how to contribute, including information on proposing new features, reporting bugs, and
submitting code, please refer to our [contributing guide](CONTRIBUTING.md).

OASF can be extended with private schema extensions, allowing you to leverage all features of the framework, such as
validation.
See the relevant section in the [contributing guide](./CONTRIBUTING.md#oasf-extensions) for instructions on adding an
extension to the schema.
An OASF instance with schema extensions can be hosted, allowing you to use your own schema server for record validation.

### Schema Versioning and Immutability

Once a schema version is released, no changes to that version of the schema are expected, except for non-breaking fixes
such as documentation updates or minor bug corrections.
Any deletions, additions, or structural changes made after a schema version is released will be part of the next schema
version.
This immutability policy ensures backward compatibility and stability for systems that depend on specific schema
versions, while allowing the framework to evolve and improve over time through new version releases.

## Useful Links

A convenient way to browse and use the OASF schema is through the
[Open Agentic Schema Framework Server](https://schema.oasf.outshift.com) hosted by Outshift by Cisco.

To deploy the server either locally or as a hosted service, see the [server's guide](oasf-server.md) for more
information.

See [Creating an Agent Record](https://docs.agntcy.org/how-to-guides/agent-record-guide/) for more information on the
Agent Record.

The current skill set taxonomy is described in
[Taxonomy of AI Agent Skills](https://schema.oasf.outshift.com/skill_categories).

## Creating Valid OASF Records with MCP Server

The [Directory MCP Server](https://github.com/agntcy/dir/tree/main/mcp) provides powerful capabilities to help create
valid OASF agent records when configured with an LLM (such as in Cursor or other MCP-compatible IDEs).
The MCP server exposes tools and prompts that enable LLMs to generate, validate, and refine OASF records with
schema-aware assistance.

### Key Capabilities

- **Schema Discovery**:
  Query OASF schema versions and navigate domains/skills taxonomy
- **Record Generation**:
  Automatically generate complete OASF records from your codebase
- **Validation**:
  Check records against the schema and iteratively fix validation errors
- **Format Conversion**:
  Import from MCP/A2A formats and export to other formats with automatic enrichment

### Getting Started

To use the MCP server with an LLM for creating OASF records:

1. **Install the Directory MCP Server** - See the [MCP Server README](https://github.com/agntcy/dir/tree/main/mcp) for
   installation instructions
2. **Configure your IDE** - Add the MCP server to your IDE's MCP configuration (e.g., `~/.cursor/mcp.json`)
3. **Start Creating Records** - Use natural language to ask the LLM to create, validate, or refine OASF records

### Example Usage

Once configured, you can interact with the LLM using natural language:

- "Create an OASF record for this project" - Generates a complete record from your codebase
- "Validate this OASF record and fix any errors" - Checks and corrects validation issues
- "Import this MCP server configuration to OASF format" - Converts from other formats

## Open Agentic Schema Framework Server

The OASF schema server, an HTTP server to browse the schema and validate records against it, lives in
[agntcy/oasf-server](https://github.com/agntcy/oasf-server), along with its Helm chart.
It does not bundle a schema: deployments mount one, usually from the `ghcr.io/agntcy/oasf-schema` image this
repository publishes for every release.

You can access the OASF schema server, which is running the latest released schema, at
[schema.oasf.outshift.com](https://schema.oasf.outshift.com).

## Development

Use `Taskfile` for all related development operations such as testing, validating and previewing the schema.

### Prerequisites

- [Taskfile](https://taskfile.dev/)
- [Docker](https://www.docker.com/)
- [Go](https://go.dev/)
- [jq](https://jqlang.org/)
- [curl](https://curl.se/)
- [Elixir](https://elixir-lang.org/install.html), only for `task test:server`

### Clone the Repository

```shell
git clone https://github.com/agntcy/oasf.git
```

### Preview Schema Changes

`task server:up` serves the local `schema/` directory with the oasf-server release pinned in
[`.oasf-server-version`](.oasf-server-version), at [`localhost:8080`](http://localhost:8080):

```shell
task server:up
```

Then run `task server:reload` in another terminal. It reloads the schema in the running server whenever a file under
`schema/` changes. Set `LOG_LEVEL` (`debug`, `info`, `warning`, `error`) or `SCHEMA_EXTENSION` when running
`task server:up` to change the log level or load extensions, and `OASF_SERVER_VERSION` to try another server release.
`task server:down` stops the server.

### Test Schema Changes

```shell
task test
```

runs the metaschema and proto checks, the pinned oasf-server's test suite against `schema/` (with and without the
example extension), and a smoke test of the server image serving `schema/`. CI runs the same checks, so a schema change
that the server cannot load fails the pull request.

### Schema Image

Each schema release is also published as `ghcr.io/agntcy/oasf-schema:<schema version>`, a data-only
image with the schema under `/schema`, for [oasf-server](https://github.com/agntcy/oasf-server)
deployments to mount. To build one from the local `schema/` directory:

```shell
task build:schema SCHEMA_IMAGE_TAG=dev
```

## Distribution

### Artifacts

See [AGNTCY Github Registry](https://github.com/orgs/agntcy/packages?repo_name=oasf).

### Protocol Buffer Definitions

The `proto` directory contains the Protocol Buffer (`.proto`) files defining our data objects and APIs.
The full proto module, generated language stubs and it's versions are hosted at the Buf Schema Registry:
[https://buf.build/agntcy/oasf](https://buf.build/agntcy/oasf)

## Copyright Notice

[Copyright Notice and License](./LICENSE.md)

Distributed under Apache 2.0 License.
See LICENSE for more information.
Copyright AGNTCY Contributors (https://github.com/agntcy)
