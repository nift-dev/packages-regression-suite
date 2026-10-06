#!/usr/bin/env bash
# Resolve clean official package sources (current ecosystem certification) and
# record an exact per-run source manifest. Clones each official package from
# https://github.com/nift-packages/<name>@main (--depth 1) into ./nift-packages
# and writes package-sources.json with the full resolved commit of every
# package the suite uses. Fail-closed on clone/resolve/incomplete-manifest.
# Usage: scripts/record_package_sources.sh [out-file]   (run from repo root;
#         creates ./nift-packages in the working directory)
set -euo pipefail
OUT="${1:-package-sources.json}"
mkdir -p nift-packages
pkgs=(ansi assert cli csv curl dotenv duration fuzzy humanize id ignore \
      imagemagick mysql postgres redis semver sqlite url vips)
pkg_json='{"schema_version":1,"packages":{}}'
for p in "${pkgs[@]}"; do
  git clone -q --depth 1 "https://github.com/nift-packages/${p}.git" "nift-packages/${p}"
  sha="$(git -C "nift-packages/${p}" rev-parse HEAD)"
  [[ "$sha" =~ ^[0-9a-f]{40}$ ]] || { echo "FAIL: could not resolve a full 40-char SHA for $p" >&2; exit 1; }
  pkg_json="$(NIFT_PACKAGE_NAME="$p" NIFT_PACKAGE_SHA="$sha" NIFT_PKG_JSON="$pkg_json" python3 - <<'PY'
import json, os
m = json.loads(os.environ["NIFT_PKG_JSON"])
name = os.environ["NIFT_PACKAGE_NAME"]
m["packages"][name] = {"repository": f"nift-packages/{name}", "requested_ref": "main", "commit": os.environ["NIFT_PACKAGE_SHA"]}
print(json.dumps(m, sort_keys=True))
PY
)"
done
printf '%s\n' "$pkg_json" > "$OUT"
python3 - "$pkg_json" "${pkgs[@]}" <<'PY'
import json, sys
manifest = json.loads(sys.argv[1])
expected = set(sys.argv[2:])
assert set(manifest["packages"]) == expected, f"incomplete package manifest: {expected - set(manifest['packages'])}"
print("Certified official package sources (current ecosystem main):")
for name in sorted(expected):
    p = manifest["packages"][name]
    print(f"  {name:12s} {p['commit']}  ref={p['requested_ref']}  {p['repository']}")
PY
echo "package source manifest: $OUT"