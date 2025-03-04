
# Open Agentic Schema Framework

## Development

**For an optimal developer experience, it is recommended to install [Taskfile](https://taskfile.dev/installation/) and [Docker](https://docs.docker.com/get-started/get-docker/).**

Make sure Docker is installed with Buildx.

Fetch required tools:

```shell
task deps
```

Build artifacts locally:

```shell
task build
```

Deploy services and access [`localhost:8080`](http://localhost:8080) locally:

```shell
task up
```

Run interactive hot-reload session for schema changes:

```shell
task reload
```

Run the test suite:

```shell
task test
```

Once you are done, tear down the deployment:

```shell
task down
```

### Configuration

You can check [example.env](example.env) file which contains a list of 
environment variables used to control the operations above.

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
