# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

# Data-only image holding one OASF schema under /schema, for the oasf-server
# image to mount. Build it with the schema/ directory as the context:
#
#   docker build -f schema.Dockerfile -t oasf-schema schema
#
# Kubernetes can mount it two ways:
# - as an init container that runs `cp -R /schema/. <emptyDir>`, which is why
#   the base is a static busybox rather than scratch;
# - as an image volume with `subPath: schema`, where nothing in it runs.

ARG base_image=busybox:1.37.0-musl@sha256:5cec3fc171c87218698e85a52af7087de727372aae264a787b8112901a5b0092

FROM ${base_image}

# schema/test holds the schema test suite and the example extension, which a
# released schema must not serve.
COPY --exclude=test --exclude=.gitignore . /schema

USER 65534:65534
WORKDIR /schema
