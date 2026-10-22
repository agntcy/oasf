# OASF Release Process

This document defines how OASF schema versions are released.
The [OASF server](https://github.com/agntcy/oasf-server) and its Helm chart are released separately, from their own repository.

## Versioning

- Every release is a new schema version, tagged on `main` as `vX.Y.0`, where `X.Y.0` is the version in `schema/version.json`.
- We bump the **minor version** for any schema change, including additions, and the **major version** for breaking changes.
- A published schema does not change. Fixes, such as documentation updates or corrected captions and constraints, ship in the next schema version.
- The release branches (`v0.3.x` … `v1.1.x`) and their patch tags (for example, `v1.1.3`) date from when the server was released from this repository and its fixes were backported to them. They are kept for reference but get no new commits or tags.

## Release Steps

1. Open a pull request to `main` that sets `schema/version.json` to the new schema version (for example, `1.2.0`, replacing `1.2.0-dev`), and merge it.
2. Tag that commit with the new version tag (for example, `v1.2.0`) and push the tag. CI publishes the schema as `ghcr.io/agntcy/oasf-schema:1.2.0`, signed and with build provenance.
3. Generate release notes on GitHub and publish the new release.

## Tasks After a Schema Release

- Open a pull request to `main` that bumps `schema/version.json` to the next schema version with the `-dev` suffix (for example, `1.3.0-dev`).
- Add the new version to the compatibility matrix in `proto/README.md`.
- Open a pull request in [agntcy/oasf-server](https://github.com/agntcy/oasf-server) that adds the new version to `schema-versions.json`, so the server is tested against it and the chart can deploy it.

## Republishing a Schema Image

The **Schema Image** workflow can also be run by hand from `main` with a release tag as `ref`, for example if publishing failed. It builds the image with the Dockerfile from `main` and the schema from that tag, and tags it with the tag's schema version.
