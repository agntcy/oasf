# OASF Release Process

This document defines how OASF schema versions are released.
The [OASF server](https://github.com/agntcy/oasf-server) and its Helm chart are released separately, from their own repository.

## Versioning

- Tags are schema versions: the **major and minor** version is the schema version in `schema/version.json`, and the **patch** version counts fixes to that schema's content (for example, `v1.1.3` is the fourth release of schema `1.1.0`).
- A published schema should not change. Release branches exist only for **schema-content fixes**, such as documentation updates or corrected captions and constraints, that cannot wait for the next schema version.
- There are no server or API changes in this repository any more, so nothing is cherry-picked to release branches for the server.

## Release Steps for a New Schema Version

1. Create a release branch named after the new schema version **with `x` as the patch version** (for example, `v1.2.x`) to avoid collisions with tag names.
2. Push a commit to that branch that updates `schema/version.json` to the new schema version (for example, `1.2.0`).
3. Tag that commit with the new version tag (for example, `v1.2.0`) and push it. CI publishes the schema as `ghcr.io/agntcy/oasf-schema:1.2.0`, signed and with build provenance. The image is tagged with the schema version, so a later `v1.2.1` moves that tag to the new content. If the branch does not have `.github/workflows/schema-image.yaml`, run the **Schema Image** workflow from `main` with the tag as `ref`.
4. Generate release notes on GitHub and publish the new release.
5. **Do not delete the release branch** after the release.

## Tasks After a Schema Release

- Open a pull request to the **main branch** that bumps `schema/version.json` to the next schema version with the `-dev` suffix (for example, `1.3.0-dev`).
- Add the new version to the compatibility matrix in `proto/README.md`.
- Open a pull request in [agntcy/oasf-server](https://github.com/agntcy/oasf-server) that adds the new version to `schema-versions.json`, so the server is tested against it and the chart can deploy it.

## Fixing a Released Schema

1. Check out the release branch (for example, `v1.1.x`) and create a branch from it with the fix.
2. Open a pull request against the release branch. Its CI loads the schema with the pinned oasf-server release.
3. Once merged, tag the next patch version (for example, `v1.1.4`) and push it, then publish the release as above.
4. Renovate bumps the tag in oasf-server's `schema-versions.json` to the new patch.
