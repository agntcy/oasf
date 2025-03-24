# Copyright 2025 ../header.txt
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG elixir_image=elixir:1.18.1-alpine

FROM ${elixir_image} AS builder

# prepare build dir
WORKDIR /app

RUN apk --update add openssl

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# Cross-/multiplatform images of OTP languages is unsupported since the introduction of the JIT compiler in OTP24.
# Set flags to bypass JIT in order to allow multiplatform image compilation.
# TODO(ramizpolic): make this bake-configurable
ENV ERL_AFLAGS="+JMsingle true"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib

# Compile the release
RUN mix compile
# Generate ssl certificate
RUN openssl req -new -newkey rsa:4096 -days 365 -nodes -sha256 -x509 -subj "/C=US/ST=CA/L=oasf/O=oasf.agntcy.org/CN=oasf-schema" -keyout priv/cert/selfsigned_key.pem -out priv/cert/selfsigned.pem
# Changes to config/runtime.exs don't require recompiling the code
COPY config/releases.exs  config/runtime.exs

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${elixir_image}

# Set the locale
# RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR "/app"
EXPOSE 8080
EXPOSE 8443
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"
ENV PORT=8080
ENV SCHEMA_DIR="/app/schema"
ENV SCHEMA_EXTENSION="extensions"
ENV PHX_SERVER=true

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/schema_server ./

# Copy the things that need to be displayed
COPY --from=schema . /app/schema

USER nobody

CMD ["/app/bin/schema_server", "start"]
