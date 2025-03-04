// SPDX-FileCopyrightText: Copyright (c) 2025 Cisco and/or its affiliates.
// SPDX-License-Identifier: Apache-2.0

# Documentation available at: https://docs.docker.com/build/bake/

# Docker build args
variable "IMAGE_REPO" {default = "ghcr.io/agntcy"}
variable "IMAGE_TAG" {default = "latest"}

function "get_tag" {
  params = [tags, name]
  result = coalescelist(tags, ["${IMAGE_REPO}/${name}:${IMAGE_TAG}"])
}

group "default" {
  targets = [
    "oasf-server",
  ]
}

target "_common" {
  output = [
    "type=image",
  ]
  platforms = [
    "linux/arm64",
    "linux/amd64",
  ]
}

target "docker-metadata-action" {
  tags = []
}

target "oasf-server" {
  inherits = [
    "_common",
    "docker-metadata-action",
  ]
  context = "./server"
  contexts = {
    schema = "./schema"
  }
  tags = get_tag(target.docker-metadata-action.tags, "${target.oasf-server.name}")
}
