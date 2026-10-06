#!/usr/bin/env bash
# Representative combined consumer: the CP5 cross-section (ansi cli csv dotenv
# fuzzy semver url id ignore assert curl + a couple more pure) installs and
# imports together, representative operations run, privacy holds, and a live
# loopback curl request works end to end alongside the pure packages. External
# network is never required.
set -euo pipefail
NIFT_BIN=${NIFT_BIN:?}
ROOT=${NIFT_PACKAGES_ROOT:?}
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/site/.nift"
for p in ansi cli csv dotenv duration fuzzy humanize semver url id ignore assert curl; do
  (cd "$t/site" && "$NIFT_BIN" add "$ROOT/$p" >/dev/null 2>&1) || { echo "add $p failed" >&2; exit 1; }
done
PORT=$((20000 + RANDOM % 3000))
python3 - "$PORT" <<'PYEOF' &
import http.server, sys
port = int(sys.argv[1])
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.send_header("Content-Type", "text/plain"); self.end_headers()
        self.wfile.write(b"combined-ok")
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", port), H).serve_forever()
PYEOF
SERVER_PID=$!
trap 'rm -rf "$t"; kill $SERVER_PID 2>/dev/null' EXIT
sleep 1
cat > "$t/site/t.f" <<EOF
@import("ansi")
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
@import("assert")
@import("curl")
print(assert.eq(semver.parse("1.4.0").minor, 4))
print(dotenv.parse("X=Y").values.X)
print(csv.parse("a,b,c")[0].size())
print(fuzzy.matches("hello", "hello"))
print(humanize.ordinal(2))
print(id.uuid().length())
print(ignore.match(ignore.parse("*.tmp"), "x.tmp"))
print(ansi.bold("z").length())
print(url.parse("https://example.com/p?q=1").host)
r := curl.request("http://127.0.0.1:$PORT/")
print(r.ok)
print(r.body)
print(curl.version().contains("curl"))
EOF
out=$(cd "$t/site" && "$NIFT_BIN" t.f)
exp=$'true\nY\n3\ntrue\n2nd\n36\ntrue\n9\nexample.com\ntrue\ncombined-ok\ntrue'
[ "$out" = "$exp" ] || { printf 'unexpected combined-consumer output:\n%s\n' "$out" >&2; exit 1; }
printf 'PASS ecosystem combined consumer\n'