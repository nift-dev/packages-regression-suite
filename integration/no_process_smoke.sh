#!/usr/bin/env bash
# Ecosystem no-process gate. With external process execution disabled, pure
# packages keep working, process-backed packages degrade per their documented
# contract (curl -> structured backend_unavailable), and one process-backed
# failure never breaks unrelated pure packages in the same combined consumer.
set -euo pipefail
NIFT_BIN=${NIFT_BIN:?}
ROOT=${NIFT_PACKAGES_ROOT:?}
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/site/.nift"
for p in ansi assert cli csv dotenv duration fuzzy humanize semver url id ignore curl; do
  (cd "$t/site" && "$NIFT_BIN" add "$ROOT/$p" >/dev/null 2>&1) || { echo "add $p failed" >&2; exit 1; }
done
cat > "$t/site/t.f" << 'F'
@import("ansi")
@import("assert")
@import("cli")
@import("csv")
@import("dotenv")
@import("duration")
@import("fuzzy")
@import("humanize")
@import("semver")
@import("url")
@import("id")
@import("ignore")
@import("curl")
print(semver.parse("1.2.3").major)
print(dotenv.parse("A=B").values.A)
print(id.uuid().length())
print(csv.parse("a,b")[0][0])
print(assert.eq(1, 1))
print(fuzzy.matches("abc", "abc"))
bad := curl.request("http://127.0.0.1:1/")
print(bad.ok)
print(bad.error_code)
print(ignore.match(ignore.parse("*.log"), "a.log"))
F
out=$(cd "$t/site" && NIFT_NO_PROCESS=1 "$NIFT_BIN" t.f)
exp=$'1\nB\n36\na\ntrue\ntrue\nfalse\nbackend_unavailable\ntrue'
[ "$out" = "$exp" ] || { printf 'unexpected no-process output:\n%s\n' "$out" >&2; exit 1; }
printf 'PASS ecosystem no-process\n'