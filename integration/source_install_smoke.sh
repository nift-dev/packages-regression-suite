#!/usr/bin/env bash
# Source-independent installation gate: `nift add` from each official package
# source directory into a fresh temporary site produces a working installation
# that imports and runs, independent of any developer working-tree state (the
# installed copy lives in the site, not the source tree).
set -euo pipefail
NIFT_BIN=${NIFT_BIN:?}
ROOT=${NIFT_PACKAGES_ROOT:?}
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/site/.nift"
for p in semver url dotenv csv id ansi; do
  (cd "$t/site" && "$NIFT_BIN" add "$ROOT/$p" >/dev/null 2>&1) || { echo "add $p failed" >&2; exit 1; }
done
cat > "$t/site/t.f" << 'F'
@import("semver")
@import("url")
@import("dotenv")
@import("csv")
@import("id")
print(semver.parse("1.2.3").patch)
print(url.parse("https://example.com/a").path)
print(dotenv.parse("K=V").values.K)
print(csv.parse("x,y")[0][1])
print(id.uuid().length())
F
out=$(cd "$t/site" && "$NIFT_BIN" t.f)
exp=$'3\n/a\nV\ny\n36'
[ "$out" = "$exp" ] || { printf 'unexpected source-install output:\n%s\n' "$out" >&2; exit 1; }
[ -f "$t/site/.nift/packages.lock.json" ] || { echo "lockfile missing" >&2; exit 1; }
( cd "$ROOT" && git status --short "semver" "url" "dotenv" "csv" "id" "ansi" | grep -q . ) && { echo "package source trees were mutated" >&2; exit 1; } || true
printf 'PASS ecosystem source-independent installation\n'