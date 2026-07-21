# OASF Data Models

This document describes how OASF data is structured, composed, and consumed.
The source of truth for field names and types is [proto/agntcy/oasf/](proto/agntcy/oasf/);
worked examples live under [examples/](examples/).

- [Overview](#overview)
- [Data Tree](#data-tree)
- [Module Taxonomy](#module-taxonomy)
- [Module Composition](#module-composition)
- [Module Catalog](#module-catalog)
- [Authoring a New Module](#authoring-a-new-module)
- [Versioning](#versioning)

---

## Overview

OASF describes an agentic artifact (an agent, a model, a tool collection, an
MCP server, …) as a **record**. A record is a tree of typed **modules**; each
module carries specific set of data that define an agent or an agentic system.

| Concept    | Purpose                                                                |
| ---------- | ---------------------------------------------------------------------- |
| **Record** | Top-level document. Identity + skills/domains taxonomy + modules tree. |
| **Module** | Typed, composable node attached to a record or another module.         |

---

## Data Tree

Every OASF document is a **Record**. The record itself is not a module (although it can be, but introduces breaking changes) — it is
the envelope that carries identity and hosts the root of a module tree.

### Record shape

`Record` is defined in
[types/v2alpha1/record.proto](proto/agntcy/oasf/types/v2alpha1/record.proto).
Its identity fields live directly on the record; the module tree hangs off
`modules[]`.

```json
{
  "schema_version": "1.0.0",
  "name": "org.example/hello",
  "version": "v1.0.0",
  "description": "Minimal example record.",
  "created_at": "2026-01-01T00:00:00Z",
  "modules": []
}
```

### Module envelope

Every module — at any depth — uses the same envelope, defined in
[types/v2alpha1/module.proto](proto/agntcy/oasf/types/v2alpha1/module.proto):

```json
{
  "type": "namespace/name",
  "annotations": { "...": "..." },
  "data":        { /* payload defined by the module type */ },
  "modules":     [ /* child modules (optional) */ ]
}
```

### Tree shape

```mermaid
graph TD
  R[Record<br/>identity + taxonomy] --> M1[resource/model/language<br/>Llama 3.3]
  R --> M2[resource/model/language<br/>Qwen 2.5 Coder]
  R --> P[traits/access/permissions]
  M1 --> E1[traits/quality/evaluation<br/>MMLU]
  M2 --> E2[traits/quality/evaluation<br/>HumanEval]
```

Two rules govern the shape:

1. **Locality of authority** — a module describes or constrains only its own
   subtree. A `traits/quality/evaluation` under a `resource/model/language` is
   about *that* model, not about the whole record.
2. **No cross-references** — modules do not name-link across the tree. If the
   same data belongs to two subtrees, place it in each subtree (or at their
   nearest common ancestor).

---

## Module Taxonomy

Every module `type` string is a path made of tier segments. The first segment
identifies the module's **tier**; the tier fixes both its role and its
composition rules.

| Tier          | Prefix        | Role                                                       | Hosts children?                                    |
| ------------- | ------------- | ---------------------------------------------------------- | -------------------------------------------------- |
| **Resource**  | `resource/`   | An identified, addressable subject (a model, a skill, …).  | Yes — `traits/*` scoped to this subject.           |
| **Interface** | `interface/`  | An exposed surface (an MCP server, an A2A endpoint, …).    | Yes — `traits/*` scoped to this interface.         |
| **Traits**    | `traits/`     | A property attached to its parent (permissions, evaluation, requirements). | No — traits are leaves.                            |

### Placement rule

- **Resources** and **interfaces** live under the record root (or, in future,
  under an actor). They may nest `traits/*` for anything scoped just to that
  subject.
- **Traits** attach either at the record root (record-wide scope) or under a
  single subject (subject-scoped). Traits do **not** host other modules.

### Taxonomy extension

The shipped catalog covers only the shapes needed by the current examples.
The taxonomy is designed to grow along four axes. Everything in this section
is **directional** — none of it is on the wire yet — but the naming and
composition rules are already fixed, so producers can anticipate the shape
and reviewers can spot proposals that violate it.

#### 1. Actors (`actor/*`) — compound subjects

Actors are the only tier permitted to host other subject tiers as children
in addition to `traits/*`. Everything else is a leaf-subject.

| `type`            | Composition | Purpose                                                                            |
| ----------------- | ----------- | ---------------------------------------------------------------------------------- |
| `actor/agent`     | instance    | A single agent: a `resource/model/*` brain plus its skills, memory, and interfaces. |
| `actor/crew`      | instance    | A container of peer agents that share crew-level resources and traits.             |
| `actor/workflow`  | instance    | An ordered composition of steps that bind to other actors and resources.           |

#### 2. Additional `resource/*` families

The subject tier will grow to cover the standard building blocks of an agent:

| `type` prefix         | Purpose                                                                       | Examples of leaves                                                       |
| --------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `resource/model/*`    | Models the agent thinks with.                                                 | `resource/model/language` (shipped), `resource/model/embedding`, `resource/model/reranker`, `resource/model/vision` |
| `resource/skill/*`    | Reusable units of behaviour or invocation.                                    | `resource/skill/agentskill` (shipped), `resource/skill/prompt` (shipped) |
| `resource/memory/*`   | Memory backends the agent reads and writes.                                   | `resource/memory/vector`, `resource/memory/keyvalue`, `resource/memory/episodic`, `resource/memory/summary` |
| `resource/knowledge/*`| Read-only knowledge sources the agent grounds on.                             | `resource/knowledge/document`, `resource/knowledge/graph`, `resource/knowledge/sql` |
| `resource/tool/*`     | Direct, non-protocol tools the agent can call.                                | `resource/tool/http`, `resource/tool/shell`, `resource/tool/python`      |
| `resource/policy/*`   | Behavioural policies expressed as first-class objects (not just traits).      | `resource/policy/guardrails`, `resource/policy/routing`, `resource/policy/moderation` |

All `resource/*` families follow the same composition rule as the shipped
resources: **instance**, each occurrence is a distinct thing, no merging
across siblings.

#### 3. Additional `interface/*` families

Interfaces are exposed *surfaces* — the framework-specific or
protocol-specific packaging that lets another system call the parent
subject. Planned families:

| `type` prefix          | Purpose                                                                      | Examples of leaves                                                                   |
| ---------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `interface/framework/*`| Framework-native agent packagings.                                           | `interface/framework/mcp` (shipped), `interface/framework/a2a` (shipped), `interface/framework/langchain`, `interface/framework/langgraph`, `interface/framework/crewai`, `interface/framework/autogen`, `interface/framework/llamaindex` |
| `interface/transport/*`| Raw transports independent of a framework.                                   | `interface/transport/http`, `interface/transport/grpc`, `interface/transport/websocket` |

An agent can carry multiple interface children — for example, a single
`actor/agent` might expose both `interface/framework/mcp` (for MCP clients)
and `interface/framework/langgraph` (for LangGraph orchestration) over the
same underlying implementation.

#### 4. Additional `traits/*` families

Traits attach behaviour or metadata without introducing a new subject:

| `type` prefix          | Purpose                                                                  |
| ---------------------- | ------------------------------------------------------------------------ |
| `traits/access/*`      | Permissions, quotas, rate limits.                                        |
| `traits/quality/*`     | Evaluations, benchmarks, red-team results.                               |
| `traits/runtime/*`     | Runtime prerequisites, resource limits, scheduling hints.                |
| `traits/policy/*`      | Inline policy toggles (`pii_redaction`, `content_filter`, `max_tokens`). |
| `traits/observability/*`| Telemetry endpoints, tracing configuration, log sinks.                  |
| `traits/lifecycle/*`   | Deprecation, versioning, sunset dates.                                   |

#### Examples

*Single agent exposed as an MCP server:*

```
Record
└── actor/agent  "web-researcher"
    ├── resource/model/language    "Llama 3.3 70B"
    ├── resource/skill/prompt      "system-prompt"
    ├── resource/memory/vector     "short-term"
    ├── resource/knowledge/document "docs-corpus"
    ├── interface/framework/mcp    "web-researcher-mcp"
    ├── traits/access/permissions  { network: read, docs-corpus: read }
    └── traits/policy/guardrails   { pii_redaction: on }
```

*Crew of agents on mixed protocols:*

```
Record
└── actor/crew  "coding-team"
    ├── resource/memory/keyvalue    "crew-scratchpad"   ← shared
    ├── resource/knowledge/document "repo-docs"         ← shared
    │
    ├── actor/agent  "planner"                          ← speaks A2A
    │   ├── resource/model/language "OpenAI o1"
    │   └── interface/framework/a2a "planner-a2a"
    │
    ├── actor/agent  "coder"                            ← exposes MCP
    │   ├── resource/model/language "Qwen 2.5 Coder 7B"
    │   ├── resource/memory/vector  "code-context"
    │   ├── resource/tool/shell     "git+build"
    │   └── interface/framework/mcp "coder-mcp"
    │
    ├── actor/agent  "reviewer"                         ← via LangGraph
    │   ├── resource/model/language "Llama 3.3 70B"
    │   └── interface/framework/langgraph "reviewer-lg"
    │
    └── traits/access/permissions   { repo: read_write, ci: read }
```

---

## Module Composition

Composition is a contract-level property of the module type and is declared
in the first lines of each module's proto docstring.

### Composition modes

| Mode         | Behaviour                                                                                                                                                                        | Used by                                                                                             |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **instance** | Each occurrence is a distinct thing. Multiple instances are never merged; they enumerate. Every instance carries its own identifying fields (typically `name`, `version`).       | All `resource/*`, all `interface/*`                                                                 |
| **replace**  | At most one effective instance per subtree. A deeper instance **replaces** the outer one for its subtree. To accumulate across scopes, include the full desired set on each one. | All `traits/*` (`traits/access/permissions`, `traits/quality/evaluation`, `traits/runtime/requirements`) |

### Placement guidance

- **instance** modules attach as top-level children of the record (or, in
  future, of an actor) when they describe a distinct subject. Nest them under
  a parent subject only when they are genuinely scoped to that parent.
- **replace** modules attach at the broadest scope where they apply. To
  tighten or override for a subtree, place another instance inside that
  subtree; it fully replaces the outer one for its descendants.

### Replace example

A record-level `traits/access/permissions` grants `read` to a resource; a
`traits/access/permissions` nested under one `interface/framework/mcp` grants
`read_write` to the same resource. For that MCP subtree the inner
permissions win entirely — the outer permissions block is not merged.

```json
{
  "schema_version": "1.0.0",
  "name": "org.example/agents",
  "version": "v1.0.0",
  "description": "…",
  "created_at": "2026-01-01T00:00:00Z",
  "modules": [
    {
      "type": "traits/access/permissions",
      "data": {
        "resources": [
          { "name": "local_filesystem", "description": "…", "access_level": "read" }
        ]
      }
    },
    {
      "type": "interface/framework/mcp",
      "data": { "name": "playwright-mcp", "...": "..." },
      "modules": [
        {
          "type": "traits/access/permissions",
          "data": {
            "resources": [
              { "name": "local_filesystem", "description": "…", "access_level": "read_write" }
            ]
          }
        }
      ]
    }
  ]
}
```

---

## Authoring a New Module

Adding a module type is a three-step change. Use the existing modules under
[proto/agntcy/oasf/modules/](proto/agntcy/oasf/modules/) as templates.

### 1. Pick the type name

- Choose a tier: `resource/`, `interface/`, or `traits/`.
- Add a family segment: `resource/model/…`, `interface/framework/…`,
  `traits/access/…`. Third-party namespaces should include a publisher
  prefix (`<reverse-dns>/…`).
- Short name: `snake_case` or `lowercase` (`resource/model/language`,
  `interface/framework/mcp`).
- The full type string is what appears in `type` on the wire.

### 2. Declare the payload in proto

Create `proto/agntcy/oasf/modules/<tier>/<family>/v1alpha1/<name>.proto`:

```proto
syntax = "proto3";

package agntcy.oasf.modules.<tier>.<family>.v1alpha1;

// <Name> is the payload for a Module of type "<tier>/<family>/<name>".
// It describes ...
//
// Composition mode: <instance|replace>. <one-line rationale>
message <Name> {
  // <field docs>
  string name = 1;
  // ...
}
```

Requirements:

- The docstring MUST name the module type on its first line.
- The docstring MUST state the composition mode — consumers depend on it.
- Reuse shared objects (`Artifact`, `EnvVar`, `HttpHeader`) instead of
  inlining equivalents.
- Traits (`traits/*`) are leaves — never host child modules.

### 3. Provide an example

Add or extend an example under [examples/](examples/) that exercises the new
module. If the module is `replace`, show a nested override. If `instance`,
show two distinct entries. Populate every required field.

### Design tips

- **Prefer many small modules over one large module.** If a payload branches
  internally (`if runtime == "local" then X else Y`), split it.
- **Keep instance modules symmetrical.** Each entry should describe one thing
  completely — never scatter one thing across multiple instances.
- **Use `annotations` for consumer-specific hints**, not for schema fields.
  If the same annotation shows up in every producer, promote it to a proper
  field in the next `v1alphaN` of that module.
- **Never rely on sibling ordering.** If order matters, model it explicitly
  with an ordered field inside a single module payload.

---

## Versioning

OASF has three independent versioning axes:

- **Schema version** — the value in `schema_version` on the record.
  Follows the OASF release cadence
  (see [README.md](README.md#schema-versioning-and-immutability)).
- **Types version** — the package suffix on `Record` and `Module`
  (currently `types/v2alpha1`). Changes to the top-level envelopes.
- **Module version** — each module family carries its **own** version
  suffix, e.g. `modules/resource/model/v1alpha1/language.proto` or
  `modules/traits/access/v1alpha1/permissions.proto`. Families evolve
  independently: bumping `resource/model` does not force a bump in
  `traits/access`.

Change semantics per axis:

- **Additive change** (new optional field) — non-breaking; ships in the
  current `v1alphaN`. Consumers ignore unknown fields.
- **Breaking change** (rename or remove) — introduce a new proto version
  for that specific family, keep the old package intact for the current
  release, and migrate examples.
