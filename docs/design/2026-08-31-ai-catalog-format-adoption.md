# Adopting the AI Catalog format

**Status:** draft for discussion — see [#493](https://github.com/agntcy/oasf/issues/493)
**Date:** 2026-08-31 (updated 2026-09-02)

## Context

OASF defines its own top-level container (`objects/record.json`) plus a module system on top of it. The [AI Catalog specification](https://ai-catalog.io/spec) covers most of what a record does, and the part of OASF that nothing else supplies is the skill and domain taxonomy.

One decision stands above the rest and applies to either path: **how our extension keys are named**, since a key embedded in a published catalog entry is permanent. Two ways to make that identity stable are laid out below; the choice is about who resolves the key, not about how stable it is.

After that, two **steps** rather than two alternatives. **Step 1** narrows OASF's purpose to hosting the taxonomy and validating a single new top-level object, published as one AI Catalog extension. **Step 2** is conditional and may never happen: only if we come to need several extensions versioned independently *and* want them all managed in one place does the framework need a different home.

## How we got here

The design passed through several shapes first. They are recorded so that later references to "the earlier analysis" are legible, and so that options a reader might reasonably propose are visibly already weighed.

| Considered | Why it was set aside |
| --- | --- |
| A single fat `record` extension carrying skills, domains, locators, and authors | Forces one version across unrelated concerns, and a consumer wanting only skills has to accept the whole blob. Replaced by focused concerns, then narrowed further once routing became the stated purpose. |
| A taxonomy-only extension, dropping everything else | The right instinct but incomplete: once the purpose was stated as DHT routing, formats and distributions turned out to be routed on as well. |
| Independent majors per extension in the key — `taxonomy.v1` beside `security.v2` | Incompatible with OASF versioning the whole schema at once. See *Why it needs a different home*. |
| Full semver in the key — `taxonomy.v1_1_0` | Every minor release mints new keys. Since consumers match keys exactly and must ignore unknown ones silently, each release would quietly blind existing consumers instead of erroring. |
| A URN key — `urn:agntcy:oasf:discovery` | Echoes the spec's own `urn:air:` identifier style, but is neither of the two permitted key forms. |
| A `locators` extension preserving the record's locator list | The entry's `url` covers the single-location case we actually have. The locator *type* survives in Step 1 as a routing facet, without the URL. |
| Several extensions hosted inside OASF with versionless keys, discriminating breaking changes via `schema_version` in each payload | Dominated. Its only purpose was hosting more than one extension, but OASF cannot version them independently — so the moment that is needed we meet Step 2's trigger and leave anyway. Choosing it would mean paying Step 2's costs later while giving up Step 1's clear scope now. |
| Modelling the AI Catalog entry itself in OASF | Puts us on the hook for tracking an external spec's evolution. Revisited under *One-pass validation*, where the conclusion is to contribute a schema upstream instead. |
| Deleting `proto/` | Correct while the payload was open-ended JSON; reversed once Step 1 made it a small closed structure of numeric enums. |
| Keeping the name `record` for the reduced object | The referent inverts while the word stays: the old record *was* the container, the new object is a fragment attached to someone else's. It would also collide with the thing that took over that role, since "the record" would be ambiguous between a catalog entry and our payload. And a rename makes the break loud — `objects/record.json` disappearing fails a consumer immediately, where a same-named object with nine of ten attributes gone fails at runtime. Named `discovery` instead. |

## Extension identity — two ways to make it stable

The spec permits exactly two key forms: "the keys MUST be a valid URL or a reverse-DNS string". Both can be made permanent, so stability is not what separates them. What separates them is **who resolves the key into a schema** — an HTTP client, or our SDK.

Whichever we pick, the naive version of the other's advantage is what we are avoiding. A bare URL under a host we operate (`https://schema.oasf.outshift.com/...`) conflates identity with location: move the host and every key already published in the wild is dead. A bare reverse-DNS string resolves to nothing at all without a documented mapping. Both options below fix their respective flaw.

### Option 1 — a w3id.org URL

`https://w3id.org/agntcy/oasf/discovery/v1`

A permanent-identifier service decouples identity from location: the URL is dereferenceable *and* the redirect target is reconfigurable without touching a published entry. Anyone holding only the key can fetch the schema with `curl`, no documentation and no SDK required.

[w3id.org](https://w3id.org) is run by the [W3C Permanent Identifier Community Group](https://www.w3.org/community/perma-id/); a consortium including Digital Bazaar, OpenLink Software, and KurrawongAI pledges to keep it operating.

1. Registration is one top-level directory per project in [`perma-id/w3id.org`](https://github.com/perma-id/w3id.org), containing an `.htaccess`. Fork it and add `agntcy/.htaccess`.
2. Follow the conventions used by existing namespaces — a header comment naming the project, description, and maintainer contacts; `Options -MultiViews`; a CORS header (needed if a browser-based UI or validator fetches the schema); and `RewriteRule`s issuing `303 See Other`:

   ```apache
   # Name of the project: AGNTCY — Open Agentic Schema Framework (OASF)
   # Description: JSON Schemas for AGNTCY AI Catalog extensions.
   # Contacts:
   # - <maintainer> (<email>)

   Options -MultiViews
   Header set Access-Control-Allow-Origin *

   RewriteRule ^/?oasf/([^/]+)/(v[0-9]+)$ https://schema.oasf.outshift.com/extensions/$1/$2 [R=303,L]
   RewriteRule ^/?oasf/?$ https://schema.oasf.outshift.com/ [R=303,L]
   ```

3. Open a PR against `perma-id/w3id.org`. The community group reviews; the naming policy expects a name unlikely to collide and a commitment to maintain it.
4. Set each published schema's `$id` to its **w3id URL**, not the redirect target. JSON Schema resolves relative `$ref`s against `$id`, so sibling refs stay stable even if the target moves.
5. Because resolution is a `303`, tooling that fetches remote schemas must follow redirects.

**Costs.** A third party sits in the resolution path — its availability, and the community group's continuity, become ours to depend on. Registration is a PR review with unknown latency, so it gates the key format. And the identifier is public and permanent the moment it is merged.

### Option 2 — reverse-DNS resolved in oasf-sdk

`org.agntcy.oasf.discovery.v1`

The key is a pure identifier that resolves to nothing on its own; `oasf-sdk` owns the mapping. It prefix-matches `org.agntcy.oasf.`, parses the remainder, and resolves the schema from an embedded copy or a configured server. Offline and air-gapped validation become the default case rather than a special mode, and there is no service in the path that can fail, rate-limit, or disappear.

Nothing to register, nothing to wait for, no external dependency, and no third-party review gating the schedule.

**Costs.** A stranger holding only the key cannot find our schema — they need our documentation or our SDK. That is a real barrier to anyone wanting to consume AGNTCY extensions without adopting AGNTCY tooling, and it puts us on the hook for keeping the mapping documented and every SDK implementation in sync. Note also that the spec's examples (`com.example.confidenceScore`) are camelCase and dot-separated, so a semver in the key must be mangled — `v1` is fine, `v1_1_0` is awkward.

### What the choice does not affect

Two things that look coupled to this decision are not:

- **One-pass validation works either way.** In a composed schema the key appears as a *property name* and the schema location as a separate `$ref` target — `"properties": {"extensions": {"properties": {"<key>": {"$ref": "<schema url>"}}}}`. The property name is just a string, so a reverse-DNS key costs nothing here. This removes what would otherwise be the strongest argument for URL keys.
- **Hosting and `$id`.** The schema still lives somewhere with a stable URL and still declares an `$id`, under either option. Only whether that URL is *also* the key changes.

### Keep the project name out of the key

Both example keys above embed `oasf`. That is worth avoiding, because a key is permanent and the project's name is not settled (see open question 2). If the project is ever renamed, an `oasf`-bearing key either becomes a lie we maintain forever or forces a migration we chose this design to prevent.

Naming the organisation and the artifact, rather than the project that produces them, decouples the two decisions:

| | Embeds the project name | Does not |
| --- | --- | --- |
| Option 1 | `https://w3id.org/agntcy/oasf/discovery/v1` | `https://w3id.org/agntcy/discovery/v1` |
| Option 2 | `org.agntcy.oasf.discovery.v1` | `org.agntcy.discovery.v1` |

The right-hand forms cost nothing and remove the coupling entirely — `agntcy` is an organisation that will outlive any project name, and `discovery` describes the payload rather than its producer. The w3id namespace is registered per project directory (`agntcy/`) either way, so the `.htaccess` rules simply match on the first path segment.

Examples elsewhere in this document use the `oasf` form because it is what was drafted; they should be read as pending questions 1 and 2, not as settled.

### Recommendation

Lean Option 1 if we expect third parties to consume our extensions without our SDK — a self-describing key is a meaningful lowering of the barrier, and it costs one upstream PR. Lean Option 2 if the realistic consumer set is Directory plus our own tooling, in which case the third-party dependency buys little and the SDK has to implement resolution regardless.

Left open deliberately; see open question 1. Registering the w3id namespace early is cheap insurance either way — an unused namespace costs nothing, while a late registration blocks the key format.

## Shared ground

Independent of which step we are on:

- The AI Catalog entry becomes the container. `objects/record.json` in its current form has no future.
- The skill and domain taxonomy is what we keep and continue to own.
- Our data is carried as an AI Catalog extension, in **catalog-extension shape, not OASF-module shape**: the key already carries identity, so the wrapper `name`, `id`, `data` nesting, `artifact`, and per-item `annotations` all disappear. The payload is flat.
- Entry-level validation is not ours to own; see *One-pass validation* for where that gets complicated.
- "Extension" now means two things: OASF *schema* extensions (the OCSF-style framework mechanism) and AI Catalog extensions (instance-level payloads). Be explicit about which.

The spec constrains almost nothing: keys "MUST be a valid URL or a reverse-DNS string", unrecognised keys "MUST be ignored without throwing an error", and there is **no** extension versioning mechanism, registry, or schema-validation requirement.

## Step 1 — the discovery extension

OASF keeps its framework, server, and browser, but its *purpose* narrows. It becomes the curator of the **closed vocabularies that Directory's DHT routing indexes on**. Free-text fields cannot be routing keys; fixed enums can. That is a sharper reason to exist than "we maintain a schema framework," and it is what makes the validator matter rather than being ceremony: every field must resolve against a known vocabulary or the entry is not routable.

`objects/record.json` is reduced and renamed — `discovery` — and becomes the single extension payload. Four fields, each a closed vocabulary:

| Field | Was | Shape | Answers |
| --- | --- | --- | --- |
| `skills` | `skills` | name + uid, hierarchical class family | what it can do |
| `domains` | `domains` | name + uid, hierarchical class family | where it applies |
| `formats` | `modules` | name + uid, one category | which specifications its artifact conforms to |
| `distributions` | `locator.type` | flat enum | what form it is distributed in |

```json
{
  "specVersion": "1.0",
  "entries": [
    {
      "identifier": "urn:air:cisco:agntcy:marketing-strategy-agent",
      "type": "application/a2a-agent-card+json",
      "version": "1.4.2",
      "url": "https://example.com/agents/marketing-strategy/card.json",
      "extensions": {
        "https://w3id.org/agntcy/oasf/discovery/v1": {
          "schema_version": "2.0.0",
          "skills":        [{"name": "software_engineering/code_debugging/error_handling", "id": 60101}],
          "domains":       [{"name": "technology/networking/network_security", "id": 60401}],
          "formats":       [{"name": "a2a", "id": 101}],
          "distributions": ["live_service", "container_image"]
        }
      }
    }
  ]
}
```

The key above is Option 1's form; under Option 2 it reads `org.agntcy.oasf.discovery.v1` and nothing else about the payload changes.

Everything the catalog entry already covers — name, description, version, publisher, timestamps, the artifact itself — is gone. What remains is exactly what a DHT index needs.

`schema_version` carries the taxonomy version the payload conforms to, the role `record.schema_version` played. One wrinkle: a validator must read it out of a payload it has not yet validated in order to pick the schema that validates it, so that field needs its own format check before being used to build a URL.

### What this deletes

`schema/objects/` goes from 56 files to about three. Every module payload object disappears — `a2a_data`, the six `mcp_*`, the nine `acp_*`, five `agentspec_*`, four `agentskills_*`, `language_model*`, `prompt`, `evaluation*`, `observability*`, the three `*_deployment` objects, `env_var*`, the framework configs, `metric`, `overall_scores` — because the actual A2A card or MCP manifest lives in the catalog entry's `data` or behind its `url`, not in OASF. `descriptor`, `publisher`, and `locator` go too. Only the base `object`, the renamed `discovery`, and possibly `key_value_object` survive.

The module *classes* survive as the media-type vocabulary, stripped to name and uid — no `data`, no `artifact`, no `annotations`, exactly like a skill or a domain. `base_module` collapses into the same shape as `base_skill`.

`proto/` is retained. A small, closed structure of numeric enums is close to ideal for proto codegen, and Directory routes in Go.

### `formats` is not the entry's `type`

The spec says `type` is "an open text format, so any string value is accepted" — it describes what an artifact *is*, informationally. `formats` is a closed set describing what Directory will *accept and route on*. One is documentation, the other is enforceable.

An earlier draft called this attribute `media_types`, which was a poor name twice over: the values are slugs (`a2a`), not media types (`application/a2a-agent-card+json`), and class names are constrained to `^[a-z0-9_]*$` so they can never be the latter; and sharing a name with the entry's `type` field invited exactly the confusion this section had to talk readers out of.

The vocabulary is `a2a`, `mcp`, `agentskills`, and `agentspec`, grouped under a single `core` category. `acp` is **dropped** — the protocol is discontinued, so it is not a format Directory should route on.

Retaining one category rather than flattening keeps the family structurally identical to skills and domains, which matters in two concrete ways. The browser's top-level cards then mean the same thing in every family — a category to drill into, rather than a concrete value in one family and a category in the others. And a category class is not usable as a value, which is what `class_out_of_scope` reports: flattening removes the only way that error can arise for `formats`, silently dropping validator coverage that skills and domains keep.

Uids are renumbered regardless of the choice, since the old values were scoped to the previous `core`/`integration` split (`category_uid * 100 + class_uid`). Under one category they are 101–104, so there is no uid worth reserving for the dropped `acp`.

### `distributions` carry no location

The existing enum in `objects/locator.json` is `unspecified`, `helm_chart`, `container_image`, `package`, `source_code`, `binary`, `url`. Step 1 keeps those and adds the A2A cases — a live service versus a static JSON document. The `urls` and `annotations` attributes are dropped; location comes from the catalog entry.

The attribute is named `distributions` rather than carrying `locator` forward, because once the URL moves to the catalog entry nothing about it locates anything: it answers what form the artifact is obtained in. Retaining `locator_types` would have described the one thing the attribute no longer does.

**Known limitation:** `distributions` is a set, but an entry has exactly one `url`. So a payload can say "available as a container image *and* a helm chart" without saying which URL is which. For routing that is sufficient — it is a search facet, and the consumer fetches the entry afterwards. For fidelity it is lossy. Genuinely multi-distribution artifacts would need either one entry per distribution or a nested catalog (`application/ai-catalog+json`), which the spec explicitly supports.

### Why one extension fits OASF as it is

OASF versions **the whole schema**, never an individual class: `server/lib/schema/cache.ex:55-70` reads a single `version.json` and builds one tree, and `server/lib/schema/application.ex:16-26` serves multiple versions by loading several complete schema checkouts side by side.

With exactly one extension, that is not a limitation — it is the right model. The extension's version *is* the OASF version. The key can safely carry the major, because an OASF major bump now legitimately means this extension broke.

### Reversals from the earlier analysis

- **Numeric uids stop being vestigial and become the point.** DHT routing keys want compact numeric identifiers, not long path strings. `base_skill`'s `at_least_one: [id, name]` stays.
- **Proto's case revives.** The earlier argument for deleting it was that a catalog entry is open-ended JSON — but this payload is not open-ended at all.

### Scope boundary

Metrics and security data are not routing metadata, so under Step 1 they are **not OASF's**. That is a feature: OASF's scope becomes crisp and defensible instead of "whatever we happen to model." Wanting them anyway is precisely the trigger for Step 2.

### Known costs

- Still a breaking change to `record`, so `dir` and `oasf-sdk` must move together; there is no release in which both shapes validate.
- Closed vocabularies mean every new media type or locator type requires an OASF release.
- The `distributions`-without-URL limitation above.
- Ties OASF's scope tightly to Directory's routing needs. Another consumer wanting these vocabularies for a different purpose reopens the scope argument.
- Deleting ~50 objects discards modelling work some consumers may already depend on.

## Step 2 — only if both conditions hold

Not a plan to execute now. The trigger is **both** of:

1. We need several extensions versioned **independently** of each other, and
2. We want all of our custom extensions managed in **one place**.

Either alone does not justify it. One extension that versions with OASF is Step 1. Several extensions that happen to share OASF's version are also Step 1.

### Why it needs a different home

For two majors of one extension to resolve simultaneously, the version must become part of the class name (`security/v1`, `security/v2`) — which collides in the uid space (`cache.ex:493-523` computes `class_uid = category_uid * 100 + class_uid`, capped at 999 per level by `metaschema/class.schema.json`) and fills the taxonomy view with `v1`/`v2` siblings. The alternative is that extension versions become a function of the OASF release version, which is not independent versioning at all.

This is inherited from OCSF, which has no versioned schema files either — root `version.json`, one tree, versioned by git tag.

### What it would look like

This repo would be archived at its last release and phased out of `agntcy/dir`; a new repo becomes the source of truth. Archiving inverts the usual migration cost: OASF stays permanently available, immutable, and readable, so existing consumers keep a working reference instead of facing a schema deleted from under them. The `dir` phase-out becomes the critical path rather than a schema migration.

Published schemas would keep **every version committed side by side** — the industry norm, unanimously:

| Project | Layout |
| --- | --- |
| CycloneDX | `schema/bom-1.2.schema.json` … `bom-1.7.schema.json` |
| AsyncAPI | `schemas/1.0.0.json` … `2.4.0.json` |
| SPDX | `schemas/spdx-schema-2-2.json` … `3-1-dev.json`, plus unversioned `spdx-schema.json` as a "latest" alias |

Git tags are the wrong tool despite being better version-control philosophy: a tag is not an address. A schema URL must stay dereferenceable forever, independently of whoever resolves tags. Tags version the *source*; committed files version the *published artifact*.

Hosting would be GitHub Pages, with the keys unchanged either way: under Option 1 only the redirect target in `.htaccess` moves, and under Option 2 only the SDK's configured source. Pages serves `.json` as `application/json`; `raw.githubusercontent.com` serves `text/plain` and is unsuitable as a schema address.

### The real cost: the integrity harness, not the file layout

The fear of trading a well-structured tree for one large JSON Schema file is avoidable. The structured source — one file per item, organised in folders — would remain the thing contributors edit; the single `schema.json` with inlined enums is a **generated build artifact**, never hand-written. That much is free.

What is not free is the integrity tooling, and this is the strongest argument for staying put. `schema/test` currently enforces properties that **JSON Schema cannot express**, because they are graph properties across 716 files rather than the shape of one document:

- every file validates against its metaschema;
- names are unique within each entity type;
- every `extends` resolves to a valid name within the same entity type;
- skill inheritance contains no cycles;
- every attribute used anywhere is defined in the dictionary.

A published `schema.json` can validate *use* of the taxonomy. Nothing in it can validate the taxonomy's own coherence. So that harness — and the dictionary that keeps captions and descriptions consistent — has to be rebuilt in the new repo before the first contribution lands, not after. Any Step 2 estimate that omits it is wrong.

## One-pass validation

The goal: one validator run over an entry that also validates our extension payload, rather than two separate validation paths.

**JSON Schema cannot dispatch on instance data.** There is no mechanism to treat a property's key or value as a schema URL and fetch it, so no validator will resolve our schema on its own.

**But a composed schema gets one pass** — `allOf` the entry schema plus a `$ref` for our extension key. CycloneDX does exactly this: `bom-1.6.schema.json` carries relative `$ref`s to sibling `spdx.schema.json` and `jsf-0.82.schema.json#/definitions/signature`, resolved against its `$id` base. Two requirements: the composed schema must **not** set `additionalProperties: false` on `extensions`, or it rejects the third-party extensions the spec requires consumers to tolerate; and because many validators disable remote `$ref` fetching by default, the robust form is a **bundled** schema with everything inlined in `$defs` and zero network access.

**What exists today.** `agent-card/ai-catalog` publishes no JSON Schema — only `specification/ai-catalog.md`, one example, a respec config, and Python build tooling. Its `ai-catalog-go`, `ai-catalog-rust`, and `ai-catalog-cli` SDKs are typed implementations, not schema-driven.

The [ARD project](https://github.com/ards-project/ard-spec) does publish one, at `spec/schemas/ai-catalog.schema.json`, alongside `ard-entry.schema.json`, a CDDL, a JSON-LD context, an OpenAPI document, and a conformance runner. But it is not authoritative and diverges from the spec:

- `catalogEntry` has **no `extensions` property at all** — it models `metadata` instead. The mechanism we would build on is simply absent.
- `displayName` is required, where the spec makes it optional.
- It adds `capabilities` and `representativeQueries`, which are not in the spec.
- The top level requires `specVersion` and `entries` with `additionalProperties: false`, and uses `host` rather than `publisher`.
- Its `$id` is a `raw.githubusercontent.com` URL, which serves `text/plain`.

`catalogEntry` does not set `additionalProperties: false`, so our extension key would at least pass through unvalidated rather than be rejected.

Two projects have already produced divergent models of the same format — exactly the gap an official schema closes. **The clean path is to contribute an authoritative JSON Schema upstream to `agent-card/ai-catalog`.** Until one exists, the options are to vendor a schema (accepting the cost of tracking the spec ourselves) or to accept two-step validation. This is independent of the step we are on.

## Open questions

1. **Extension identity: w3id.org URL or reverse-DNS resolved in `oasf-sdk`?** Turns on whether we expect third parties to consume AGNTCY extensions without AGNTCY tooling. Both give a permanent key; only the resolver differs.
2. **Is "Open Agentic Schema *Framework*" still the right name?** After Step 1, `schema/objects/` drops from 56 files to about three, and what remains is three vocabularies (`skills`, `domains`, `formats`), one flat enum (`distributions`), and one payload object. The metaschema, dictionary, categories, `extends` inheritance, and uid arithmetic all survive — but they survive *in service of curating a taxonomy*, not as a general-purpose schema-definition system in the way OCSF's do. The test that matters: could a third party use OASF to define a schema of their own? Today yes, via schema extensions; after Step 1 that capability has nothing left to extend, and contributing a skill is participating in a taxonomy rather than using a framework. So "Framework" becomes the weak letter — "Open", "Agentic", and arguably "Schema" all still hold. Options: rename (costly — `agntcy/oasf`, `schema.oasf.outshift.com`, the `agntcy.oasf.types.v1` proto packages, `oasf-sdk`, the Helm chart, and links from `docs.agntcy.org` all carry it), or keep the letters and stop expanding them into a claim, as plenty of projects do once they outgrow their acronym. **This gates key minting** unless the key omits the project name — see *Keep the project name out of the key*.
3. Does `dir` confirm that skills, domains, formats, and distributions are the complete set of fields DHT routing indexes on? If it routes on something else, that field belongs in the payload; if it does not route on one of these, that field should not be there. **This is the question that most shapes Step 1.**
4. Is one entry per distribution acceptable for multi-distribution artifacts, or do we need nested catalogs?
5. Do we contribute an entry schema upstream, vendor one, or accept two-step validation? Has our SDK team already built something contributable?
6. Sequencing with `agntcy/dir` and `oasf-sdk`, both of which consume the record today.
7. Do module categories still mean anything once the payload objects are gone? Overlaps with [#478](https://github.com/agntcy/oasf/issues/478).

## Next steps

- Decide the key form (open question 1). If Option 1, open the `perma-id/w3id.org` PR immediately — it is independent of both steps and has unknown third-party latency. Registering early is cheap even if we later pick Option 2.
- Confirm the routed field set with `dir` (open question 2) before writing the implementation plan.
- Raise the missing JSON Schema with `agent-card/ai-catalog`, ideally with a draft attached.
- Reconcile with [#472](https://github.com/agntcy/oasf/issues/472) (proposes an `ai_catalog` module — reshaped once the catalog is the container) and [#478](https://github.com/agntcy/oasf/issues/478) (reshapes `record` — overlaps directly with Step 1's reduction).
- Write the Step 1 implementation plan.
