# Example Extension

A minimal, working reference extension. It exists so that the extension mechanism
documented in [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) and
[`server/README.md`](../../../server/README.md) has a concrete example to point at,
and so that the schema test suite exercises the extension validation path.

## Layout

An extension mirrors the layout of the core `schema` directory:

| Path | Purpose |
| --- | --- |
| `extension.json` | Declares the extension's `name` and `uid`. A directory becomes an extension by containing this file. |
| `dictionary.json` | New attributes contributed by the extension. |
| `domains/` | New domain classes. A class becomes a category by setting `"category": true`. |
| `modules/` | New module classes. A module overrides `data` with its own payload object. |
| `objects/` | New objects, including module payload objects, which extend `module_data`. |

`skills/` and `profiles/` follow the same pattern and are omitted here for brevity.

## Loading it

```shell
SCHEMA_DIR=../schema SCHEMA_EXTENSION=extensions iex -S mix phx.server
```

Then, from the `iex` prompt:

```elixir
Schema.reload(["extensions/example"])
```

## Naming

Extension entities are keyed as `<extension_name>/<entity_name>`, so a reference from
one extension entity to another must carry that prefix. `cold_chain_logistics.json`
extends `example/example_verticals`, not `example_verticals`: an unqualified `extends`
does not resolve, the class is left without a category, and its identifier is computed
against category `0`.

The class defined in `domains/example_verticals/cold_chain_logistics.json` is written
into a record as:

```json
{ "name": "example/example_verticals/example_cold_chain_logistics", "id": 9980101 }
```

The name is the category path followed by `<extension_name>_<class_name>`. The
identifier is derived as `(extension_uid * 100 + category_uid) * 100 + class_uid`,
here `(998 * 100 + 1) * 100 + 1`.

## Module payloads

A module overrides `data` with a `reference` to its own payload object, and the
dictionary entry for that payload is *self-typed* — its `type` is the object's own
name, as `observability_data` is in the core dictionary. Without that entry the
reference does not resolve, `data` silently falls back to `string_t`, and the schema
fails to compile.

## Reserving a UID

Before publishing an extension, reserve its name and `uid` in
[`schema/extensions.md`](../../extensions.md) to avoid collisions with the core
schema and with other extensions.
