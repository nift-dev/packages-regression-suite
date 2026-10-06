# Regression ownership model

The three testing layers, by the semantic contract being asserted — never by
repository name alone.

## Layer 1 — Nift core + `nift-regression-suite`

Owns **Nift semantics and Nift package-system behavior**:

- language/parser/evaluator/runtime semantics;
- CLI contracts;
- package-manager semantics, dependency resolution, import/export behavior;
- privacy enforcement and process controls at the language level;
- FFI, concurrency, platform behavior;
- historical Nift regressions.

The core suite may and should use package **fixtures** when the subject is Nift
itself (a controlled local package proving "can Nift install/import/export this
shape?"). It deliberately does not assert evolving real-package public APIs
such as `curl.request(...)`, `sqlite.transaction(...)`, `semver.parse(...)` or
`id.uuid(...)`.

## Layer 2 — individual package repositories

Own **package implementation correctness**: security/adversarial behavior,
backends, package-specific edge cases, detailed public API behavior. Each
package's own tests are independently authoritative for that package.

## Layer 3 — `packages-regression-suite`

Owns the **official ecosystem compatibility layer** for real official packages:

- public package facades and deprecated compatibility surfaces;
- package-specific result contracts;
- source-independent installation;
- package coexistence and cross-package export-collision freedom;
- cross-package privacy boundaries;
- `--no-process` behavior across the ecosystem;
- backend-unavailable behavior;
- representative combined consumers;
- compatibility against supplied Nift builds.

## Decision rule

For every test ask: **whose contract is it asserting?** A module that mixes a
Nift-machinery guarantee with a real-package API guarantee is **split**: the
machinery portion stays (or becomes a synthetic fixture) in Layer 1, and the
package API portion moves to Layer 3. Neither guarantee is weakened by the
split.

## Curl compatibility policy

The deprecated top-level Curl exports (`request`, `get`, `post`, `put`,
`patch`, `delete`, `head`) were audited and have **no supported consumer** — all
real consumers (Curl's own tests, examples, docs) use the `curl` facade. They
were removed from the Curl package; `packages-regression-suite` certifies the
**current supported `curl` facade** and never re-enshrines the removed aliases.
Future package API changes are expected to evolve here without marking Nift
itself broken.