# Agent Evidence extension

An OASF record can carry a module that points at a signed evidence statement about the agent: which record format the statement uses (its `predicateType` URI), the SHA-256 of the statement's bytes, and where to fetch it. The record stays a description of the agent. The statement is a separate signed object that a consumer fetches, checks against the digest and judges with the verifier its predicate type names.

A record carries the module as

```json
{
  "name": "agent_evidence/agent_evidence/agent_evidence_evidence_reference",
  "data": {
    "agent_evidence_predicate_type": "https://probityai.github.io/agent-evidence-vectors/predicate/v1/agent-audit-record",
    "agent_evidence_statement_digest": "sha256:0000000000000000000000000000000000000000000000000000000000000000",
    "agent_evidence_locations": ["https://example.org/statements/run-1.json"],
    "agent_evidence_conformance_corpus": "agent-evidence-vectors==0.29.3"
  }
}
```

The predicate type URIs are published at `https://probityai.github.io/agent-evidence-vectors/predicate/v1/<name>`. A producer that wants to show its verifier agrees with the public cases runs the corpus named in `agent_evidence_conformance_corpus` (`pip install agent-evidence-vectors`).

Layout and naming follow `schema/test/extensions/example`. The extension name and UID are reserved in `schema/extensions.md`.
