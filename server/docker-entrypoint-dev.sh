#!/bin/sh
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
