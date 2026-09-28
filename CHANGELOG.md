# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Versioning

OASF does **not** follow semantic versioning. As described in [RELEASE.md](./RELEASE.md):

- the **major and minor** version track the *schema* version;
- the **patch** version covers *server and API* changes only — including breaking API changes.

Releases are cut from long-lived release branches (`v0.7.x`, `v1.1.x`, and so on) rather than
from `main`, and server fixes are routinely cherry-picked back onto older schema lines. Two
consequences for this file: versions are grouped by release line rather than strictly by date,
and the same change may appear under more than one version.

Entries are derived from the commit history. Purely internal `chore` and `style` commits are
omitted. Security fixes appear under **Fixed** or **Dependencies**.

## Unreleased

[Compare with v1.1.1](https://github.com/agntcy/oasf/compare/v1.1.1...main)

### Added

- **ci:** add openssf scoreboard ([#497](https://github.com/agntcy/oasf/pull/497))
- **schema:** add a reference example extension ([#489](https://github.com/agntcy/oasf/pull/489))

### Fixed

- **ci:** scope image cleanup packages token to the job ([#499](https://github.com/agntcy/oasf/pull/499))
- **schema:** validate extension files against their entity metaschema ([#488](https://github.com/agntcy/oasf/pull/488))
- **server:** stop converting request-supplied names to new atoms ([#508](https://github.com/agntcy/oasf/pull/508))

### Dependencies

- **ci:** update go test module dependencies for security advisories ([#504](https://github.com/agntcy/oasf/pull/504))

### Internal

- **ci:** pin remaining unpinned dependencies by hash ([#503](https://github.com/agntcy/oasf/pull/503))
- **ci:** replace taskfile install with official action ([#483](https://github.com/agntcy/oasf/pull/483))
- **server:** add property-based tests for the validator and translator ([#511](https://github.com/agntcy/oasf/pull/511))

## [v1.1.1](https://github.com/agntcy/oasf/releases/tag/v1.1.1) - 2026-07-21

[Compare with v1.1.0](https://github.com/agntcy/oasf/compare/v1.1.0...v1.1.1)

### Changed

- **server:** server memory handling ([#487](https://github.com/agntcy/oasf/pull/487))

### Fixed

- **ci:** buf workflow action ([#486](https://github.com/agntcy/oasf/pull/486))

## [v1.1.0](https://github.com/agntcy/oasf/releases/tag/v1.1.0) - 2026-07-10

[Compare with v1.0.0](https://github.com/agntcy/oasf/compare/v1.0.0...v1.1.0)

### Added

- **ci:** add codecov coverage upload for server tests ([#402](https://github.com/agntcy/oasf/pull/402))
- **ci:** image arch and simplification ([#448](https://github.com/agntcy/oasf/pull/448))
- **helm:** log level settings ([#446](https://github.com/agntcy/oasf/pull/446))
- **helm:** support f5 ingress controller ([#454](https://github.com/agntcy/oasf/pull/454))
- **schema:** add Agent Skills support under language_model module ([#399](https://github.com/agntcy/oasf/pull/399))
- **schema:** add descriptor object and module.artifact attribute ([#458](https://github.com/agntcy/oasf/pull/458))
- **schema:** add granular skills and domains ([#475](https://github.com/agntcy/oasf/pull/475))
- **server:** improved category support ([#412](https://github.com/agntcy/oasf/pull/412))
- **server:** json schema generator maxLength and pattern constraints ([#464](https://github.com/agntcy/oasf/pull/464))
- **server:** migrate to Elixir tests ([#466](https://github.com/agntcy/oasf/pull/466))
- less strict agentskills module attribute requirements ([#450](https://github.com/agntcy/oasf/pull/450))
- version aware Swagger UI ([#416](https://github.com/agntcy/oasf/pull/416))

### Changed

- **BREAKING** **api, helm:** improve version api ([#430](https://github.com/agntcy/oasf/pull/430))
- **BREAKING** **api:** categories endpoints to return nested class taxonomies ([#414](https://github.com/agntcy/oasf/pull/414))
- **BREAKING** **api:** cleanup API, Swagger UI ([#428](https://github.com/agntcy/oasf/pull/428))
- **BREAKING** **api:** improve class apis ([#426](https://github.com/agntcy/oasf/pull/426))
- **schema:** language model modules ([#396](https://github.com/agntcy/oasf/pull/396))
- **server:** reduce code duplications ([#473](https://github.com/agntcy/oasf/pull/473))

### Fixed

- **api:** use proper object schema for body params in validation/translation endpoints ([#433](https://github.com/agntcy/oasf/pull/433))
- **chart:** remove duplicate env definition in values.yaml ([#393](https://github.com/agntcy/oasf/pull/393))
- **ci:** bake tags ([#453](https://github.com/agntcy/oasf/pull/453))
- **ci:** build and push mult-arch image ([#452](https://github.com/agntcy/oasf/pull/452))
- **ci:** load images into kind via single-platform archive ([#482](https://github.com/agntcy/oasf/pull/482))
- **ci:** use latest image in container scan and harden server Dockerfile ([#403](https://github.com/agntcy/oasf/pull/403))
- **docs:** remove obsolete paragraph about modules ([#411](https://github.com/agntcy/oasf/pull/411))
- **helm:** prevent unknown version paths from matching default backend ([#443](https://github.com/agntcy/oasf/pull/443))
- **schema,dictionary:** fix uuid example typo ([#434](https://github.com/agntcy/oasf/pull/434))
- **schema:** feature extraction skill captions ([#441](https://github.com/agntcy/oasf/pull/441))
- **server, api:** subclass sorting ([#432](https://github.com/agntcy/oasf/pull/432))
- **server:** enforce class_type taxonomy scope ([#477](https://github.com/agntcy/oasf/pull/477))
- **server:** enforce constraint backfill with correct field shapes ([#460](https://github.com/agntcy/oasf/pull/460))
- **server:** validation fixes ([#463](https://github.com/agntcy/oasf/pull/463))
- add CVEs to .trivyignore with explanation ([#470](https://github.com/agntcy/oasf/pull/470))
- remove self-signed cert ([#405](https://github.com/agntcy/oasf/pull/405))
- versioned link to A2A AgentCard proto spec ([#410](https://github.com/agntcy/oasf/pull/410))

### Documentation

- **ci:** add repo badges ([#404](https://github.com/agntcy/oasf/pull/404))
- added RELEASE.md ([#436](https://github.com/agntcy/oasf/pull/436))

### Internal

- **server, schema:** renovate and pre commit config ([#469](https://github.com/agntcy/oasf/pull/469))
- lint PR title ([#394](https://github.com/agntcy/oasf/pull/394))

## [v1.0.4](https://github.com/agntcy/oasf/releases/tag/v1.0.4) - 2026-04-09

[Compare with v1.0.3](https://github.com/agntcy/oasf/compare/v1.0.3...v1.0.4)

### Added

- **schema:** add descriptor object and module.artifact attribute ([#458](https://github.com/agntcy/oasf/pull/458))

### Fixed

- **api:** use proper object schema for body params in validation/translation endpoints ([#433](https://github.com/agntcy/oasf/pull/433))
- **server:** enforce constraint backfill with correct field shapes ([#460](https://github.com/agntcy/oasf/pull/460))
- **server:** validation fixes ([#463](https://github.com/agntcy/oasf/pull/463))

## [v1.0.3](https://github.com/agntcy/oasf/releases/tag/v1.0.3) - 2026-04-07

[Compare with v1.0.2](https://github.com/agntcy/oasf/compare/v1.0.2...v1.0.3)

### Added

- **ci:** image arch and simplification ([#448](https://github.com/agntcy/oasf/pull/448))
- **helm:** log level settings ([#446](https://github.com/agntcy/oasf/pull/446))
- less strict agentskills module attribute requirements ([#450](https://github.com/agntcy/oasf/pull/450))

### Fixed

- **ci:** bake tags
- **ci:** build and push mult-arch image ([#452](https://github.com/agntcy/oasf/pull/452))
- **helm:** prevent unknown version paths from matching default backend ([#443](https://github.com/agntcy/oasf/pull/443))
- **schema:** feature extraction skill captions ([#441](https://github.com/agntcy/oasf/pull/441))

## [v1.0.2](https://github.com/agntcy/oasf/releases/tag/v1.0.2) - 2026-03-20

[Compare with v1.0.1](https://github.com/agntcy/oasf/compare/v1.0.1...v1.0.2)

### Added

- **ci:** add codecov coverage upload for server tests ([#402](https://github.com/agntcy/oasf/pull/402))
- **schema:** add Agent Skills support under language_model module ([#399](https://github.com/agntcy/oasf/pull/399))

### Changed

- **schema:** inline skill/module/domain category metadata into class jsons
- **schema:** language model modules ([#396](https://github.com/agntcy/oasf/pull/396))

### Fixed

- **ci:** use latest image in container scan and harden server Dockerfile ([#403](https://github.com/agntcy/oasf/pull/403))
- **schema,dictionary:** fix uuid example typo ([#434](https://github.com/agntcy/oasf/pull/434))
- remove self-signed cert ([#405](https://github.com/agntcy/oasf/pull/405))
- versioned link to A2A AgentCard proto spec ([#410](https://github.com/agntcy/oasf/pull/410))

### Documentation

- **ci:** add repo badges ([#404](https://github.com/agntcy/oasf/pull/404))

### Internal

- lint PR title ([#394](https://github.com/agntcy/oasf/pull/394))

## [v1.0.1](https://github.com/agntcy/oasf/releases/tag/v1.0.1) - 2026-01-30

[Compare with v1.0.0](https://github.com/agntcy/oasf/compare/v1.0.0...v1.0.1)

No user-facing changes.

## [v1.0.0](https://github.com/agntcy/oasf/releases/tag/v1.0.0) - 2026-02-05

[Compare with v0.8.0](https://github.com/agntcy/oasf/compare/v0.8.0...v1.0.0)

### Added

- **schema:** A2A AgentCard v1 support ([#387](https://github.com/agntcy/oasf/pull/387))
- **schema:** extend agent spec module to support deployment options ([#355](https://github.com/agntcy/oasf/pull/355))
- **schema:** improve MCP and A2A modules ([#356](https://github.com/agntcy/oasf/pull/356))
- **server:** add google analytics support ([#380](https://github.com/agntcy/oasf/pull/380))
- **server:** add translation for class id/name ([#370](https://github.com/agntcy/oasf/pull/370))
- **server:** duplicate checks in validator ([#376](https://github.com/agntcy/oasf/pull/376))
- **server:** remove unknown module warning ([#378](https://github.com/agntcy/oasf/pull/378))
- **server:** validator improvements ([#375](https://github.com/agntcy/oasf/pull/375))
- add evaluation module back ([#388](https://github.com/agntcy/oasf/pull/388))
- add v1 protos for objects ([#368](https://github.com/agntcy/oasf/pull/368))
- api validator to return warning to base classes ([#354](https://github.com/agntcy/oasf/pull/354))

### Changed

- **schema:** language model modules ([#396](https://github.com/agntcy/oasf/pull/396))

### Fixed

- **chart:** remove duplicate env definition in values.yaml ([#393](https://github.com/agntcy/oasf/pull/393))
- **ci:** grant buildx filesystem entitlements ([#358](https://github.com/agntcy/oasf/pull/358))
- **schema:** update stale url in agent spec module object ([#362](https://github.com/agntcy/oasf/pull/362))
- **server:** empty array validation ([#371](https://github.com/agntcy/oasf/pull/371))
- add cid_t type so previous_record_cid ([#353](https://github.com/agntcy/oasf/pull/353))
- add minItems constraint to required arrays ([#372](https://github.com/agntcy/oasf/pull/372))
- don't allow duplicate enum values in arrays ([#379](https://github.com/agntcy/oasf/pull/379))

### Documentation

- add section to README about OASF record generation ([#359](https://github.com/agntcy/oasf/pull/359))

### Internal

- add CodeQL and update container security workflows ([#363](https://github.com/agntcy/oasf/pull/363))
- lint PR title ([#394](https://github.com/agntcy/oasf/pull/394))

## [v0.8.7](https://github.com/agntcy/oasf/releases/tag/v0.8.7) - 2026-04-07

[Compare with v0.8.6](https://github.com/agntcy/oasf/compare/v0.8.6...v0.8.7)

### Added

- **ci:** image arch and simplification ([#448](https://github.com/agntcy/oasf/pull/448))
- **helm:** log level settings ([#446](https://github.com/agntcy/oasf/pull/446))

### Fixed

- **ci:** bake tags
- **ci:** build and push mult-arch image ([#452](https://github.com/agntcy/oasf/pull/452))
- **helm:** prevent unknown version paths from matching default backend ([#443](https://github.com/agntcy/oasf/pull/443))
- **schema:** feature extraction skill captions ([#441](https://github.com/agntcy/oasf/pull/441))

## [v0.8.6](https://github.com/agntcy/oasf/releases/tag/v0.8.6) - 2026-03-20

[Compare with v0.8.5](https://github.com/agntcy/oasf/compare/v0.8.5...v0.8.6)

### Changed

- **schema:** inline skill/module/domain category metadata into class jsons

### Fixed

- **schema,dictionary:** fix uuid example typo ([#434](https://github.com/agntcy/oasf/pull/434))

## [v0.8.5](https://github.com/agntcy/oasf/releases/tag/v0.8.5) - 2026-02-19

[Compare with v0.8.4](https://github.com/agntcy/oasf/compare/v0.8.4...v0.8.5)

### Fixed

- versioned link to A2A AgentCard proto spec ([#410](https://github.com/agntcy/oasf/pull/410))

## [v0.8.4](https://github.com/agntcy/oasf/releases/tag/v0.8.4) - 2026-02-13

[Compare with v0.8.3](https://github.com/agntcy/oasf/compare/v0.8.3...v0.8.4)

### Fixed

- **ci:** use latest image in container scan and harden server Dockerfile ([#403](https://github.com/agntcy/oasf/pull/403))
- remove self-signed cert ([#405](https://github.com/agntcy/oasf/pull/405))

## [v0.8.3](https://github.com/agntcy/oasf/releases/tag/v0.8.3) - 2026-01-29

[Compare with v0.8.2](https://github.com/agntcy/oasf/compare/v0.8.2...v0.8.3)

### Added

- **server:** remove unknown module warning ([#378](https://github.com/agntcy/oasf/pull/378))

### Fixed

- don't allow duplicate enum values in arrays ([#379](https://github.com/agntcy/oasf/pull/379))

## [v0.8.2](https://github.com/agntcy/oasf/releases/tag/v0.8.2) - 2026-01-19

[Compare with v0.8.1](https://github.com/agntcy/oasf/compare/v0.8.1...v0.8.2)

### Added

- **server:** add translation for class id/name ([#370](https://github.com/agntcy/oasf/pull/370))
- **server:** duplicate checks in validator ([#376](https://github.com/agntcy/oasf/pull/376))
- **server:** validator improvements ([#375](https://github.com/agntcy/oasf/pull/375))

### Fixed

- **server:** empty array validation ([#371](https://github.com/agntcy/oasf/pull/371))
- add minItems constraint to required arrays ([#372](https://github.com/agntcy/oasf/pull/372))

## [v0.8.1](https://github.com/agntcy/oasf/releases/tag/v0.8.1) - 2025-12-08

[Compare with v0.8.0](https://github.com/agntcy/oasf/compare/v0.8.0...v0.8.1)

### Added

- backport latest fixes to 0.8.0 ([#361](https://github.com/agntcy/oasf/pull/361))

## [v0.8.0](https://github.com/agntcy/oasf/releases/tag/v0.8.0) - 2025-10-22

[Compare with v0.7.0](https://github.com/agntcy/oasf/compare/v0.7.0...v0.8.0)

### Added

- **ci:** fmt schema jsons ([#336](https://github.com/agntcy/oasf/pull/336))
- **schema, server:** customizable map type ([#331](https://github.com/agntcy/oasf/pull/331))
- **schema, server:** reorganize modules ([#324](https://github.com/agntcy/oasf/pull/324))
- **schema:** add Agent Spec feature extension ([#334](https://github.com/agntcy/oasf/pull/334))
- **schema:** extend skill taxonomy with categories 8-15 and initial leaf skills ([#338](https://github.com/agntcy/oasf/pull/338))
- **schema:** make some signature fields optional ([#306](https://github.com/agntcy/oasf/pull/306))
- add base object to OASF ([#293](https://github.com/agntcy/oasf/pull/293))
- add more Technology domain categories ([#326](https://github.com/agntcy/oasf/pull/326))
- add v0.3.1 proto files ([#292](https://github.com/agntcy/oasf/pull/292))
- entity and graph UI improvements ([#311](https://github.com/agntcy/oasf/pull/311))
- improve domain taxonomy ([#343](https://github.com/agntcy/oasf/pull/343))
- more informative class validation error msgs ([#335](https://github.com/agntcy/oasf/pull/335))
- sample generator not to return duplicates ([#300](https://github.com/agntcy/oasf/pull/300))

### Changed

- **BREAKING** **schema, server:** class categories ([#323](https://github.com/agntcy/oasf/pull/323))
- Fix: graph view ([#310](https://github.com/agntcy/oasf/pull/310))
- Update CONTRIBUTORS.md ([#302](https://github.com/agntcy/oasf/pull/302))
- remove old protos ([#291](https://github.com/agntcy/oasf/pull/291))

### Fixed

- **server, schema:** extension support ([#321](https://github.com/agntcy/oasf/pull/321))
- Agents -> Agentic in OASF acronym ([#288](https://github.com/agntcy/oasf/pull/288))
- add schema version to link in json schema gen ([#298](https://github.com/agntcy/oasf/pull/298))
- display schema_version without "v" prefix ([#319](https://github.com/agntcy/oasf/pull/319))
- don't include deprecated classes in sample ([#327](https://github.com/agntcy/oasf/pull/327))
- error when input is not a map in validator ([#297](https://github.com/agntcy/oasf/pull/297))

### Documentation

- update with docs site updates ([#308](https://github.com/agntcy/oasf/pull/308))

### Internal

- add API tests ([#294](https://github.com/agntcy/oasf/pull/294))
- add fmt formatting check to Github Actions ([#301](https://github.com/agntcy/oasf/pull/301))
- add git diff log when format is checked ([#339](https://github.com/agntcy/oasf/pull/339))
- add more verification jobs ([#280](https://github.com/agntcy/oasf/pull/280))
- add server compilation test ([#309](https://github.com/agntcy/oasf/pull/309))
- schema tests ([#305](https://github.com/agntcy/oasf/pull/305))

## [v0.7.8](https://github.com/agntcy/oasf/releases/tag/v0.7.8) - 2026-04-07

[Compare with v0.7.7](https://github.com/agntcy/oasf/compare/v0.7.7...v0.7.8)

### Added

- **ci:** image arch and simplification ([#448](https://github.com/agntcy/oasf/pull/448))
- **helm:** log level settings ([#446](https://github.com/agntcy/oasf/pull/446))

### Fixed

- **ci:** bake tags
- **ci:** build and push mult-arch image ([#452](https://github.com/agntcy/oasf/pull/452))
- **helm:** prevent unknown version paths from matching default backend ([#443](https://github.com/agntcy/oasf/pull/443))
- **schema:** feature extraction skill captions ([#441](https://github.com/agntcy/oasf/pull/441))

## [v0.7.7](https://github.com/agntcy/oasf/releases/tag/v0.7.7) - 2026-03-20

[Compare with v0.7.6](https://github.com/agntcy/oasf/compare/v0.7.6...v0.7.7)

### Changed

- **schema:** inline category metadata into top-level class jsons

### Fixed

- **schema,dictionary:** fix uuid example typo ([#434](https://github.com/agntcy/oasf/pull/434))

## [v0.7.6](https://github.com/agntcy/oasf/releases/tag/v0.7.6) - 2026-02-19

[Compare with v0.7.5](https://github.com/agntcy/oasf/compare/v0.7.5...v0.7.6)

### Fixed

- versioned link to A2A AgentCard proto spec ([#410](https://github.com/agntcy/oasf/pull/410))

## [v0.7.5](https://github.com/agntcy/oasf/releases/tag/v0.7.5) - 2026-02-13

[Compare with v0.7.4](https://github.com/agntcy/oasf/compare/v0.7.4...v0.7.5)

### Fixed

- **ci:** e2e test default image
- **ci:** use latest image in container scan and harden server Dockerfile ([#403](https://github.com/agntcy/oasf/pull/403))
- remove self-signed cert ([#405](https://github.com/agntcy/oasf/pull/405))

## [v0.7.4](https://github.com/agntcy/oasf/releases/tag/v0.7.4) - 2026-01-29

[Compare with v0.7.3](https://github.com/agntcy/oasf/compare/v0.7.3...v0.7.4)

### Added

- **server:** remove unknown module warning ([#378](https://github.com/agntcy/oasf/pull/378))

### Fixed

- don't allow duplicate enum values in arrays ([#379](https://github.com/agntcy/oasf/pull/379))

## [v0.7.3](https://github.com/agntcy/oasf/releases/tag/v0.7.3) - 2026-01-19

[Compare with v0.7.2](https://github.com/agntcy/oasf/compare/v0.7.2...v0.7.3)

### Added

- **server:** add translation for class id/name ([#370](https://github.com/agntcy/oasf/pull/370))
- **server:** duplicate checks in validator ([#376](https://github.com/agntcy/oasf/pull/376))
- **server:** validator improvements ([#375](https://github.com/agntcy/oasf/pull/375))

### Fixed

- **server:** empty array validation ([#371](https://github.com/agntcy/oasf/pull/371))
- add minItems constraint to required arrays ([#372](https://github.com/agntcy/oasf/pull/372))

## [v0.7.2](https://github.com/agntcy/oasf/releases/tag/v0.7.2) - 2025-12-08

[Compare with v0.7.1](https://github.com/agntcy/oasf/compare/v0.7.1...v0.7.2)

### Added

- backport latest fixes to 0.7.0 ([#360](https://github.com/agntcy/oasf/pull/360))

## [v0.7.1](https://github.com/agntcy/oasf/releases/tag/v0.7.1) - 2025-09-17

[Compare with v0.7.0](https://github.com/agntcy/oasf/compare/v0.7.0...v0.7.1)

### Fixed

- validator, generator, signature object ([#307](https://github.com/agntcy/oasf/pull/307))

## [v0.7.0](https://github.com/agntcy/oasf/releases/tag/v0.7.0) - 2025-09-05

[Compare with v0.6.0](https://github.com/agntcy/oasf/compare/v0.6.0...v0.7.0)

### Added

- **schema:** adjustments ([#263](https://github.com/agntcy/oasf/pull/263))
- **server:** improve children object/class display ([#282](https://github.com/agntcy/oasf/pull/282))
- **server:** validate enum objects ([#258](https://github.com/agntcy/oasf/pull/258))
- **server:** validator adjustments ([#265](https://github.com/agntcy/oasf/pull/265))

### Changed

- features to modules ([#284](https://github.com/agntcy/oasf/pull/284))
- remove base class and references ([#273](https://github.com/agntcy/oasf/pull/273))

### Fixed

- **schema, server:** schema types ([#272](https://github.com/agntcy/oasf/pull/272))
- validator 500 response on incorrect input ([#262](https://github.com/agntcy/oasf/pull/262))

### Documentation

- update readmes and contributing guide ([#277](https://github.com/agntcy/oasf/pull/277))

## [v0.6.1](https://github.com/agntcy/oasf/releases/tag/v0.6.1) - 2025-09-05

[Compare with v0.6.0](https://github.com/agntcy/oasf/compare/v0.6.0...v0.6.1)

No user-facing changes.

## [v0.6.0](https://github.com/agntcy/oasf/releases/tag/v0.6.0) - 2025-08-13

[Compare with v0.5.0](https://github.com/agntcy/oasf/compare/v0.5.0...v0.6.0)

### Added

- **schema:** add schema_url to record ([#250](https://github.com/agntcy/oasf/pull/250))
- **schema:** improve a2a feature ([#251](https://github.com/agntcy/oasf/pull/251))
- **server, schema:** simplified class names ([#234](https://github.com/agntcy/oasf/pull/234))
- **server:** add range to json schema generator ([#253](https://github.com/agntcy/oasf/pull/253))
- **server:** remove activity and type ids ([#255](https://github.com/agntcy/oasf/pull/255))
- **server:** update UI with upstream changes ([#233](https://github.com/agntcy/oasf/pull/233))
- **server:** update server with upstream changes ([#231](https://github.com/agntcy/oasf/pull/231))
- add OASF schema for MCP servers ([#205](https://github.com/agntcy/oasf/pull/205))
- add unit_interval_t with generator ([#248](https://github.com/agntcy/oasf/pull/248))
- link domains with record object ([#217](https://github.com/agntcy/oasf/pull/217))

### Changed

- Fix issue templates ([#247](https://github.com/agntcy/oasf/pull/247))
- Revert "fix: rename remaining web links (#229)" ([#230](https://github.com/agntcy/oasf/pull/230))

### Fixed

- **server:** class indentation of classes from extensions ([#249](https://github.com/agntcy/oasf/pull/249))
- **server:** constraints in validator ([#238](https://github.com/agntcy/oasf/pull/238))
- **server:** minor generator and validator issues ([#242](https://github.com/agntcy/oasf/pull/242))
- CI ([#227](https://github.com/agntcy/oasf/pull/227))
- ci workflow GHA ([#223](https://github.com/agntcy/oasf/pull/223))
- json schema generator ([#204](https://github.com/agntcy/oasf/pull/204))
- remove test schema folder ([#196](https://github.com/agntcy/oasf/pull/196))
- rename remaining web links ([#229](https://github.com/agntcy/oasf/pull/229))
- search within categories ([#236](https://github.com/agntcy/oasf/pull/236))
- update post-migration OASF web links ([#218](https://github.com/agntcy/oasf/pull/218))
- use all_* maps to find children ([#220](https://github.com/agntcy/oasf/pull/220))
- versions in bug report template ([#243](https://github.com/agntcy/oasf/pull/243))

### Internal

- fix Helm release tag calculation ([#214](https://github.com/agntcy/oasf/pull/214))
- improve Dockerfile ([#215](https://github.com/agntcy/oasf/pull/215))
- release helm chart separately ([#192](https://github.com/agntcy/oasf/pull/192))

## [v0.5.3](https://github.com/agntcy/oasf/releases/tag/v0.5.3) - 2025-09-05

[Compare with v0.5.2](https://github.com/agntcy/oasf/compare/v0.5.2...v0.5.3)

No user-facing changes.

## [v0.5.2](https://github.com/agntcy/oasf/releases/tag/v0.5.2) - 2025-08-13

[Compare with v0.5.1](https://github.com/agntcy/oasf/compare/v0.5.1...v0.5.2)

No user-facing changes.

## [v0.5.1](https://github.com/agntcy/oasf/releases/tag/v0.5.1) - 2025-07-30

[Compare with v0.5.0](https://github.com/agntcy/oasf/compare/v0.5.0...v0.5.1)

No user-facing changes.

## [v0.5.0](https://github.com/agntcy/oasf/releases/tag/v0.5.0) - 2025-07-16

[Compare with v0.4.0](https://github.com/agntcy/oasf/compare/v0.4.0...v0.5.0)

### Added

- renamed agent_record to record ([#198](https://github.com/agntcy/oasf/pull/198))

### Fixed

- appy ingress annotations to nginx-internal ([#194](https://github.com/agntcy/oasf/pull/194))
- class enum sample generator ([#195](https://github.com/agntcy/oasf/pull/195))
- fix doc ingress ([#193](https://github.com/agntcy/oasf/pull/193))

## [v0.4.2](https://github.com/agntcy/oasf/releases/tag/v0.4.2) - 2025-07-14

[Compare with v0.4.1](https://github.com/agntcy/oasf/compare/v0.4.1...v0.4.2)

### Fixed

- appy ingress annotations to nginx-internal ([#194](https://github.com/agntcy/oasf/pull/194))

## [v0.4.1](https://github.com/agntcy/oasf/releases/tag/v0.4.1) - 2025-07-14

[Compare with v0.4.0](https://github.com/agntcy/oasf/compare/v0.4.0...v0.4.1)

### Fixed

- fix doc ingress ([#193](https://github.com/agntcy/oasf/pull/193))

## [v0.4.0](https://github.com/agntcy/oasf/releases/tag/v0.4.0) - 2025-07-10

[Compare with v0.3.0](https://github.com/agntcy/oasf/compare/v0.3.0...v0.4.0)

### Added

- **schema:** add LLM/Prompt/A2A/MCP feature extensions ([#143](https://github.com/agntcy/oasf/pull/143))
- class names as enums ([#169](https://github.com/agntcy/oasf/pull/169))
- dictionary references ([#161](https://github.com/agntcy/oasf/pull/161))
- generate API objects ([#171](https://github.com/agntcy/oasf/pull/171))
- multi-version deploy ([#127](https://github.com/agntcy/oasf/pull/127))
- remove general classes, categories ([#172](https://github.com/agntcy/oasf/pull/172))
- remove observables ([#138](https://github.com/agntcy/oasf/pull/138))
- rename AGP to SLIM ([#162](https://github.com/agntcy/oasf/pull/162))
- schema generator to handle class type ([#133](https://github.com/agntcy/oasf/pull/133))
- standardize reference names to use lowercase with underscores ([#151](https://github.com/agntcy/oasf/pull/151))
- update core models ([#137](https://github.com/agntcy/oasf/pull/137))
- v1, v2 object versions ([#182](https://github.com/agntcy/oasf/pull/182))

### Fixed

- local dev env ([#157](https://github.com/agntcy/oasf/pull/157))
- remove base_class from class lists ([#177](https://github.com/agntcy/oasf/pull/177))
- remove default namespace ([#185](https://github.com/agntcy/oasf/pull/185))
- rename manifest data main properties ([#108](https://github.com/agntcy/oasf/pull/108))
- resolve docker image version mismatch in local deployment ([#142](https://github.com/agntcy/oasf/pull/142))
- sample generator to respect constraints ([#129](https://github.com/agntcy/oasf/pull/129))

### Documentation

- add all prerequisites to README ([#165](https://github.com/agntcy/oasf/pull/165))
- change README.md ([#180](https://github.com/agntcy/oasf/pull/180))

## [v0.3.3](https://github.com/agntcy/oasf/releases/tag/v0.3.3) - 2025-09-17

[Compare with v0.3.2](https://github.com/agntcy/oasf/compare/v0.3.2...v0.3.3)

No user-facing changes.

## [v0.3.2](https://github.com/agntcy/oasf/releases/tag/v0.3.2) - 2025-07-09

[Compare with v0.3.1](https://github.com/agntcy/oasf/compare/v0.3.1...v0.3.2)

### Fixed

- schema ([#181](https://github.com/agntcy/oasf/pull/181))

## [v0.3.1](https://github.com/agntcy/oasf/releases/tag/v0.3.1) - 2025-05-13

[Compare with v0.3.0](https://github.com/agntcy/oasf/compare/v0.3.0...v0.3.1)

No user-facing changes.

## [v0.3.0](https://github.com/agntcy/oasf/releases/tag/v0.3.0) - 2025-05-13

[Compare with v0.2.0](https://github.com/agntcy/oasf/compare/v0.2.0...v0.3.0)

### Added

- **schema:** updating evaluation extension ([#89](https://github.com/agntcy/oasf/pull/89))
- **server:** extend export api ([#92](https://github.com/agntcy/oasf/pull/92))
- implement API tools for OASF types ([#95](https://github.com/agntcy/oasf/pull/95))
- implement generator for string_map_t type ([#104](https://github.com/agntcy/oasf/pull/104))
- implement string map type ([#103](https://github.com/agntcy/oasf/pull/103))
- update agent object and base classes ([#101](https://github.com/agntcy/oasf/pull/101))
- validation and translation for `class_t` ([#102](https://github.com/agntcy/oasf/pull/102))

### Changed

- **schema:** observability object ([#93](https://github.com/agntcy/oasf/pull/93))
- Add a README.md plus OASF schema updates ([#99](https://github.com/agntcy/oasf/pull/99))
- feat/complete evaluation feature ([#85](https://github.com/agntcy/oasf/pull/85))

### Fixed

- **schema:** Agntcy observability schema reference ([#90](https://github.com/agntcy/oasf/pull/90))
- **server:** add missing check on enum attributes ([#91](https://github.com/agntcy/oasf/pull/91))
- **server:** array generation ([#87](https://github.com/agntcy/oasf/pull/87))
- **server:** displaying Options in description ([#86](https://github.com/agntcy/oasf/pull/86))
- Swagger UI ([#100](https://github.com/agntcy/oasf/pull/100))
- manifest schema ([#98](https://github.com/agntcy/oasf/pull/98))
- update OASF deployment maniftest ([#97](https://github.com/agntcy/oasf/pull/97))

## [v0.2.2](https://github.com/agntcy/oasf/releases/tag/v0.2.2) - 2025-04-15

[Compare with v0.2.1](https://github.com/agntcy/oasf/compare/v0.2.1...v0.2.2)

### Added

- **schema:** updating evaluation extension ([#89](https://github.com/agntcy/oasf/pull/89))
- **server:** extend export api ([#92](https://github.com/agntcy/oasf/pull/92))

### Changed

- **schema:** observability object ([#93](https://github.com/agntcy/oasf/pull/93))

### Fixed

- **schema:** Agntcy observability schema reference ([#90](https://github.com/agntcy/oasf/pull/90))
- **server:** add missing check on enum attributes ([#91](https://github.com/agntcy/oasf/pull/91))

## [v0.2.1](https://github.com/agntcy/oasf/releases/tag/v0.2.1) - 2025-04-09

[Compare with v0.2.0](https://github.com/agntcy/oasf/compare/v0.2.0...v0.2.1)

### Changed

- feat/complete evaluation feature ([#85](https://github.com/agntcy/oasf/pull/85))

### Fixed

- **server:** array generation ([#87](https://github.com/agntcy/oasf/pull/87))
- **server:** displaying Options in description ([#86](https://github.com/agntcy/oasf/pull/86))

## [v0.2.0](https://github.com/agntcy/oasf/releases/tag/v0.2.0) - 2025-04-09

[Compare with v0.1.0](https://github.com/agntcy/oasf/compare/v0.1.0...v0.2.0)

### Added

- **schema:** remove eval features ([#80](https://github.com/agntcy/oasf/pull/80))
- add agntcy observability data schema ([#79](https://github.com/agntcy/oasf/pull/79))
- add observability to the schema ([#67](https://github.com/agntcy/oasf/pull/67))
- extension generator ([#73](https://github.com/agntcy/oasf/pull/73))
- generate more accurate agent object ([#70](https://github.com/agntcy/oasf/pull/70))
- improve api docs ([#74](https://github.com/agntcy/oasf/pull/74))
- object enum ([#75](https://github.com/agntcy/oasf/pull/75))
- observability extension class ([#72](https://github.com/agntcy/oasf/pull/72))

### Changed

- Modify schema ([#83](https://github.com/agntcy/oasf/pull/83))

### Fixed

- **schema:** fix domain category numbers ([#81](https://github.com/agntcy/oasf/pull/81))
- swagger UI link in Resources dropdown ([#69](https://github.com/agntcy/oasf/pull/69))

## [v0.1.0](https://github.com/agntcy/oasf/releases/tag/v0.1.0) - 2025-03-27

[Compare with v0.0.1](https://github.com/agntcy/oasf/compare/v0.0.1...v0.1.0)

### Added

- add links to footer ([#65](https://github.com/agntcy/oasf/pull/65))
- improve generator ([#60](https://github.com/agntcy/oasf/pull/60))
- separate skills from classes ([#54](https://github.com/agntcy/oasf/pull/54))

### Changed

- 62 update copyright notice ([#64](https://github.com/agntcy/oasf/pull/64))
- change event references in codebase ([#56](https://github.com/agntcy/oasf/pull/56))

### Fixed

- graph view ([#55](https://github.com/agntcy/oasf/pull/55))
- update link formats ([#53](https://github.com/agntcy/oasf/pull/53))
- updated agent example ([#51](https://github.com/agntcy/oasf/pull/51))

### Documentation

- copyright ([#63](https://github.com/agntcy/oasf/pull/63))

## [v0.0.1](https://github.com/agntcy/oasf/releases/tag/v0.0.1) - 2025-03-06

### Added

- add CICD pipeline ([#4](https://github.com/agntcy/oasf/pull/4))
- add Skills attribute to Agent object ([#14](https://github.com/agntcy/oasf/pull/14))
- add acp object ([#30](https://github.com/agntcy/oasf/pull/30))
- add data model schema ([#6](https://github.com/agntcy/oasf/pull/6))
- add manifest class ([#45](https://github.com/agntcy/oasf/pull/45))
- add new feature category and data ([#10](https://github.com/agntcy/oasf/pull/10))
- improve dev experience ([#21](https://github.com/agntcy/oasf/pull/21))
- nested classes on the UI ([#27](https://github.com/agntcy/oasf/pull/27))
- replace logo, favicon and updated CSS ([#43](https://github.com/agntcy/oasf/pull/43))
- separated domains from categories ([#5](https://github.com/agntcy/oasf/pull/5))

### Changed

- 1 initialize repo ([#2](https://github.com/agntcy/oasf/pull/2))
- Add data model ([#8](https://github.com/agntcy/oasf/pull/8))
- Add skills example ([#23](https://github.com/agntcy/oasf/pull/23))
- Fix broken links ([#38](https://github.com/agntcy/oasf/pull/38))
- Renaming events ([#40](https://github.com/agntcy/oasf/pull/40))
- Revert "feat: separated domains from categories (#5)" ([#7](https://github.com/agntcy/oasf/pull/7))
- first commit
- remove html template duplications ([#15](https://github.com/agntcy/oasf/pull/15))
- small fixes ([#20](https://github.com/agntcy/oasf/pull/20))

### Fixed

- docs cleanup ([#31](https://github.com/agntcy/oasf/pull/31))
- editorial documentation review ([#42](https://github.com/agntcy/oasf/pull/42))
- release latest version for helm chart ([#33](https://github.com/agntcy/oasf/pull/33))
- remove category_ids ([#47](https://github.com/agntcy/oasf/pull/47))
- resolve cleanup targets ([#22](https://github.com/agntcy/oasf/pull/22))
- resolve release pipeline ([#49](https://github.com/agntcy/oasf/pull/49))
- update navbar links to point to the homepage ([#36](https://github.com/agntcy/oasf/pull/36))
- use GA artifacts in CICD pipeline ([#37](https://github.com/agntcy/oasf/pull/37))

### Documentation

- add OCSF attribution ([#41](https://github.com/agntcy/oasf/pull/41))
- temporary cut ([#29](https://github.com/agntcy/oasf/pull/29))
