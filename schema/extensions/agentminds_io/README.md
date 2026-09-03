# `agentminds_io` extension namespace

**Owner:** AgentMinds — https://agentminds.dev
**Contact:** fabrecamimarlik@gmail.com
**Reserved:** 2026-04-27
**License:** CC-BY-4.0 (extension definitions); MIT (reference code)
**Spec:** https://github.com/agentmindsdev/profile

## Purpose

Reserve the `agentminds_io` extension namespace for AgentMinds-
specific OASF record fields that have no canonical equivalent in
the upstream OASF schema. AgentMinds operates a cross-site agent
intelligence pool; the fields below describe state that only has
meaning across organisations.

## Initial extension fields

| Field | Type | Description |
|---|---|---|
| `agentminds_io.pattern.id` | string | Cross-site pattern identifier (lowercase hex SHA-256, 64 chars) |
| `agentminds_io.pattern.fingerprint` | string | Alias of `.id` for Sentry-style readers |
| `agentminds_io.pattern.confidence` | float [0,1] | Beta-Bernoulli posterior confidence |
| `agentminds_io.pattern.cross_site_seen_count` | int | Distinct sites that observed this pattern |
| `agentminds_io.pattern.last_verified` | RFC3339 | Last network-wide confirmation timestamp |
| `agentminds_io.pattern.volatility_class` | enum (`stable`/`evolving`/`decaying`) | Drift detection signal |
| `agentminds_io.report.profile_version` | semver | ARP version this report follows |

## Reorientation clause

Per the AgentMinds Reporting Profile (ARP) §7, if a future canonical
OASF version introduces a cross-site pool concept that absorbs these
fields, AgentMinds will defer to the canonical definitions. This
extension namespace becomes a backwards-compatible alias.

## Reference

- AgentMinds Reporting Profile (ARP):
  https://github.com/agentmindsdev/profile
- Reference implementation:
  https://github.com/agentmindsdev/agentminds (closed-source;
  excerpts available on request)
