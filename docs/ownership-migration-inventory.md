# Ownership migration inventory (CP1)

Audit of `nift-regression-suite` (at **cf34587**, 94 modules) for dependencies
on real official packages. Every row was classified by the **semantic contract
asserted** (never by package-name appearance).

## Real-package contract modules (7) — migrate to `packages-regression-suite`

| core module | package(s) | what it proves | class | synthetic core replacement required? |
| --- | --- | --- | --- | --- |
| `v44_curl_combined_smoke.sh` | curl, sqlite | curl+sqlite public facades, response shapes, combined multi-package import, private-helper isolation, (historically) deprecated top-level curl aliases | SPLIT | yes — a two-package synthetic fixture in core (`v48_package_combined_fixture_smoke.sh`) covers the Nift "import two packages with distinct exports + private isolation" machinery the original also exercised |
| `v44_sqlite_module_smoke.sh` | sqlite | sqlite module-style facade (open/exec/query/transaction), private isolation | MOVE | no (private-helper isolation is already covered by core `v44_package_hardening_smoke.sh` and the new combined fixture) |
| `v44_database_packages_smoke.sh` | postgres, mysql, redis | database modules' consistent client API, structured failures, privacy | MOVE | no |
| `v44_parameter_binding_smoke.sh` | sqlite, postgres, mysql | package parameter-binder substitution semantics | MOVE | no |
| `v44_transaction_atomicity_smoke.sh` | sqlite, postgres, mysql | package `transaction()` atomic BEGIN..COMMIT submission/rollback | MOVE | no |
| `v44_imagemagick_package_smoke.sh` | imagemagick | `magick` facade (package name != export name), live pipeline, private isolation | MOVE | no |
| `v44_vips_magick_combined_smoke.sh` | vips, imagemagick | two packages coexisting without namespace collision; live/absent-backend behavior | SPLIT | covered by the two-package synthetic fixture in core; coexistence also asserted at the ecosystem level here |

## Keep in core (synthetic fixtures / name-only matches)

| core module | reason to keep |
| --- | --- |
| `v44_module_export_smoke.sh` | inline synthetic "vips" package fixture — Nift module-export machinery, not the real package |
| `v44_package_hardening_smoke.sh` | synthetic "evil" fixture — Nift package hardening (path traversal, duplicate add, private bindings) |
| `v46_package_graph_smoke.sh` | synthetic multi-package graph fixtures — Nift deterministic lockfile/provenance machinery |
| `v46_package_metadata_smoke.sh` | synthetic manifests — Nift package-metadata validation machinery |
| `v44_packages_smoke.sh` | synthetic "demo" fixture — Nift install/import/lock machinery |
| `parameter_interpolation_smoke.sh`, `requirements_smoke.sh`, `unreadable_source_smoke.sh`, `v43_*`, `v44_shell_bare_command_smoke.sh`, `v46_runtime_utilities_smoke.sh` | match only on substrings (url/id/assert/... as language features or filenames); they do not `@import` any real package — keep |

## Outcome

- Core: **94 → 88** modules (remove 7 migrated, add 1 synthetic two-package
  fixture `v48_package_combined_fixture_smoke.sh`).
- `packages-regression-suite`: new suite with the 7 migrated contracts plus
  ecosystem integration gates (coexistence, privacy, no-process,
  source-independent install, combined consumer).

## Curl alias audit (CP3)

Consumers of Curl's deprecated top-level `request/get/post/put/patch/delete/head`:

- `nift-packages/*` — none import curl except curl's own tests, which use only
  the `curl` facade.
- `nift-regression-suite` (contract + legacy) — only
  `v44_curl_combined_smoke.sh` (bare `request`/`delete`), the module being
  migrated.
- Nift docs / website — none.

CONCLUSION: no supported consumer. The aliases were **removed** from the Curl
package (with README updated); the new suite certifies the current `curl`
facade.