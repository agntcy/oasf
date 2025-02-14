#!/bin/sh

cd /oasf-server
if [ ! -d ./_build ]; then
    echo "_build folder not found, removing .mix and deps/ and running a build."
    rm -Rf .mix/
    rm -Rf deps/
    mix local.hex --force
    mix local.rebar --force
    mix do deps.get, deps.compile
    mix compile
fi

exec "$@"
