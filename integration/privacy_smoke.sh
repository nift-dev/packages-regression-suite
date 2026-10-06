#!/usr/bin/env bash
# Ecosystem privacy gate: official packages export only their sole facade;
# known private helpers never leak into the importer, across many packages at
# once. Deeper per-package adversarial privacy stays in each package repo.
set -euo pipefail
NIFT_BIN=${NIFT_BIN:?}
ROOT=${NIFT_PACKAGES_ROOT:?}
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/site/.nift"
for p in curl sqlite semver url dotenv csv id fuzzy assert; do
  (cd "$t/site" && "$NIFT_BIN" add "$ROOT/$p" >/dev/null 2>&1) || { echo "add $p failed" >&2; exit 1; }
done
leak(){ # <pkg> <private-name>
  local pkg="$1" name="$2"
  printf '@import("%s")\nprint(%s)\n' "$pkg" "$name" > "$t/site/p.f"
  if (cd "$t/site" && "$NIFT_BIN" p.f >/dev/null 2>&1); then
    echo "private helper leaked: $pkg.$name" >&2; exit 1
  fi
}
leak curl curl_parse_headers
leak sqlite sqlite_bind
leak semver ascii_identifier
leak semver compare_parsed
leak url decode_text
leak dotenv export_prefix
leak csv add_record
leak id hex_byte
leak fuzzy banded_work
leak assert brief
leak assert fail
# Every private standalone check must reach this point; also verify the facades
# themselves remain importable in the same project after the leak probes.
cat > "$t/site/ok.f" << 'F'
@import("semver")
@import("url")
print(semver.parse("1.2.3").major)
print(url.parse("https://example.com/").host)
F
[ "$(cd "$t/site" && "$NIFT_BIN" ok.f)" = $'1\nexample.com' ] || exit 1
printf 'PASS ecosystem privacy\n'