#!/usr/bin/env bash
# Ecosystem coexistence gate: many official packages install and import side by
# side in one project with no namespace collision; every facade resolves and a
# representative structured operation works for each pure package. This is the
# cross-package safety net individual package suites cannot provide.
set -euo pipefail
NIFT_BIN=${NIFT_BIN:?}
ROOT=${NIFT_PACKAGES_ROOT:?}
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/site/.nift"
for p in ansi assert cli csv dotenv duration fuzzy humanize semver url id ignore; do
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
print(type(ansi))
print(ansi.bold("x").length())
print(assert.eq(1, 1))
print(cli.parse(["--x"], {"options": {"x": {"type": "bool"}}}).ok)
v := csv.parse("a,b")
print(v.size())
print(v[0][0])
print(dotenv.parse("A=B").values.A)
print(duration.format(1000))
print(fuzzy.matches("abc", "abc"))
print(humanize.ordinal(23))
print(semver.parse("1.2.3").major)
print(semver.parse("1.2.3").patch)
print(url.parse("https://example.com/a?b=c").scheme)
print(url.parse("https://example.com/a?b=c").host)
print(id.uuid().length())
print(ignore.match(ignore.parse("*.log"), "a.log"))
F
out=$(cd "$t/site" && "$NIFT_BIN" t.f)
exp=$'struct\n9\ntrue\ntrue\n1\na\nB\n1s\ntrue\n23rd\n1\n3\nhttps\nexample.com\n36\ntrue'
[ "$out" = "$exp" ] || { printf 'unexpected coexistence output:\n%s\n' "$out" >&2; exit 1; }
printf 'PASS ecosystem coexistence\n'