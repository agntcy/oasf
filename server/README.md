# Open Agentic Schema Framework Server

This directory contains the Open Agents Schema Framework (OASF) Schema Server source code.
The schema server is an HTTP server that provides a convenient way to browse and use the OASF schema.

You can access the OASF schema server, which is running the latest released schema, at [schema.oasf.agntcy.org](https://schema.oasf.agntcy.org).

The schema server can also be used locally.

## Usage

OASF uses Kubernetes as its native runtime.
The project comes with the necessary tooling for local development that relies on [Taskfile](https://taskfile.dev/installation/) and [Docker](https://docs.docker.com/get-started/get-docker/).
Make sure Docker is installed with Buildx.

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

#### Hot reload

In order to run the server in hot-reload mode, you must specify the necessary flags
during deployment to signal that the schema will be actively updated.

This can be achieved by performing an interactive deployment via:

```shell
task reload
```

Note that this will only perform hot-reload for schema changes, but not the backend.
Reloading backend changes requires `task build`.

### Cleanup

This step will handle cleanup procedure by
removing resources from previous steps,
including ephemeral Kind clusters and Docker containers.

```shell
task down
```
