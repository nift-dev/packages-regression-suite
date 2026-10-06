# packages-regression-suite

Ecosystem-level regression suite for the official Nift package collection.

This suite owns **public contracts and integration behavior of real official
packages**, and is kept separate from `nift-regression-suite`, which owns Nift
language/runtime/CLI/package-manager semantics using synthetic fixtures.

## Ownership boundary

Classify every test by **whose contract it asserts**:

- `nift-regression-suite` → Nift semantics and Nift package-system behavior
  (may use small synthetic package fixtures).
- individual package repositories → package implementation, security/adversarial
  behavior, backends, package-specific edge cases.
- `packages-regression-suite` → the official ecosystem compatibility layer:
  public facades, deprecated compatibility surfaces, coexistence, cross-package
  privacy, `--no-process` semantics, source-independent installation, and
  representative combined consumers.

Real package API contracts belong here, not in the Nift historical regression
corpus, so a package API change (e.g. removing a deprecated alias) never reads
as a Nift core regression.

## Layout

```text
run.sh              deterministic runner (NIFT_BIN + optional NIFT_EXPECT_VERSION)
contract/           per-package public-contract modules (migrated from core)
integration/        ecosystem-level gates (coexistence, privacy, no-process,
                    source install, combined consumer)
docs/               ownership model + migration inventory + source model + CI note
```

## Usage

```bash
NIFT_BIN=/path/to/nift ./run.sh          # any supplied Nift binary
./run.sh /path/to/nift                   # positional alternative
NIFT_EXPECT_VERSION=4.7.2 NIFT_BIN=... ./run.sh
```

The harness:

- runs each module in a temporary, disposable workspace (no dependence on any
  developer working tree);
- reports `PASS`/`FAIL` per module and exits non-zero on any failure or on any
  un-wired suite file;
- does not hard-code a Nift version (asserts well-formed versions unless
  `NIFT_EXPECT_VERSION` is provided).

## Package source model

Two modes (see `docs/source-model.md`):

- **LOCAL / current-ecosystem** (default): packages resolve from the sibling
  `../nift-packages/*` checkouts for developer integration work.
- **CI / clean-source** (`.github/workflows/contract.yml`): official packages
  are clean-cloned from `https://github.com/nift-packages/<name>.git@main`
  (no dirty sibling dependence, no absolute paths).

Per-package overrides (`CURL_PKG`, `SQLITE_PKG`, `PG_PKG`, ...) allow pinned
package revisions to be introduced later. The suite certifies the **current**
official package contracts; historical package-API behavior is not a Nift core
guarantee.

## CI

`.github/workflows/contract.yml` runs the suite on `push` and
`workflow_dispatch` (with an optional `nift-sha` input). A supplied Nift SHA is
checked out as a commit object; the default is `main`. Requires 12/12 PASS.

## Layered Nift testing model

See `docs/ownership.md` for the three-layer ownership model, the migration
inventory in `docs/ownership-migration-inventory.md`, and the future
release-CI shape in `docs/CI-RELEASE-RECOMMENDATION.md`.