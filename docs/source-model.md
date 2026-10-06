# Package source model

Two explicit modes for acquiring official package sources.

## LOCAL / CURRENT-ECOSYSTEM MODE

The default for developer integration work: packages resolve from the sibling
`../nift-packages/*` checkouts in the Nift workspace. Convenient, but it is
**not** authoritative for hosted CI/release certification (a dirty or divergent
local checkout would change certified behavior).

## CI / CLEAN-SOURCE MODE

Hosted certification (`contract.yml`) obtains every official package from a
**clean repository clone** of `nift-packages/<name>@main` (`--depth 1`,
`git clone https://github.com/nift-packages/<name>.git`). No dirty sibling
checkout, no `/home/nick` absolute paths, no mutation of any package source
repo. This is documented as **current ecosystem certification** (clean `main`
of each official package against the supplied Nift binary).

## Per-package overrides → pinned snapshots later

Every module honours a per-package source override (`CURL_PKG`,
`SQLITE_PKG`, `PG_PKG`, `MYSQL_PKG`, `VIPS_PKG`, ...). A future
**pinned-snapshot** mode can therefore be introduced by pointing those
overrides at fixed-checkout clones, without harness changes.

## What the suite certifies

The central suite certifies the **current official package contracts**. It is
deliberately not a historical package-API compatibility corpus: if an official
package changes a public contract (for example, PostgreSQL/MySQL parameters
are now bound via hex-encoded byte copies —
`convert_from(decode('..','hex'),'UTF8')` / `CONVERT(X'..' USING utf8mb4)` —
rather than quoted literals), the suite tracks the package. Historical package
behavior is not a Nift core guarantee.