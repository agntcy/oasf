# OASF Release Process

This document defines the OASF release process and tagging strategy.
The tag structure differs slightly from standard semantic versioning.
The major and minor versions always reflect the schema version, while server and API changes result only in a patch version bump (even if the API introduces breaking changes).

## Release Branches and Versioning

- We use **release branches** for each schema release because the schema and server are shipped bundled within a container image.
- The **schema** itself should never be changed once published, but the **server** and the **API** can be improved independently.
- It is common to **cherry-pick commits** and update the server and API for earlier schema versions to fix bugs or add features that should be available across supported OASF versions.
- We bump the **minor version** when the schema changes, and the **patch version** when only the server or the API changes.

## Release Steps for a New Schema Version

1. Create a release branch named after the new schema version number **with `x` as the patch version** (for example, `v0.6.x`) to avoid collisions with tag names.
2. Push a commit to that branch that updates `schema/version.json` to the new schema version.
   Also bump the server version in `server/mix.exs` to the same version number.
3. Tag that commit with the new version tag (for example, `v0.6.0`) and push it so the CI pipeline can create packages.
4. Generate release notes on GitHub and publish the new release.
5. **Do not delete the release branch** after the release.

## Tasks After a Schema Release

- Open a pull request to the **main branch** that bumps `schema/version.json` to the next schema version with the `-dev` suffix (for example, `0.7.0-dev`).
- Adjust the versions in `install/charts/oasf/values-test.yaml` and `install/charts/oasf/values-test-versions.yaml` so local development versions are displayed correctly.
- Add the new version to the compatibility matrix in `proto/README.md`.

## Backporting Server Changes to Earlier Versions

- Checkout the relevant release branch.
- Create a new branch from it and add or cherry-pick the necessary server changes.
- Bump the server patch version in `server/mix.exs`.
- Open a pull request for review.
- Once merged, tag and push a new patch version (for example, on branch `v0.6.x`, tags would be `v0.6.1`, `v0.6.2`, etc.).

## API Version Bumping

- The API version in `server/lib/schema_web/router.ex` only needs to be bumped when the API endpoints themselves are changed.
- API changes should be backported to the release branch of every maintained OASF version, tagged with a patch version bump, and released at the same time.

## Releasing a New Chart Version

- Use tags with the prefix `helm/` followed by the version number (for example, `helm/vX.Y.Z`).

Please follow this process to maintain consistency and ensure smooth releases across all OASF versions.
