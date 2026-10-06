#!/usr/bin/env bash
# Ecosystem contract for the curl package's supported facade: loopback GET
# response shape (headers values are ARRAYS under the current contract),
# convenience verbs, version/capability inspection, private-helper isolation,
# and absence of the removed deprecated top-level aliases. When sqlite3 is
# available, the combined curl+sqlite import is also certified. Offline.
set -euo pipefail
NIFT_BIN=${NIFT_BIN:?}
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURL_PKG="${CURL_PKG:-$ROOT/../nift-packages/curl}"
SQLITE_PKG="${SQLITE_PKG:-$ROOT/../nift-packages/sqlite}"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/site/.nift"
(cd "$t/site" && "$NIFT_BIN" add "$CURL_PKG" >/dev/null 2>&1)

PORT=$((18000 + RANDOM % 2000))
python3 - "$PORT" <<'PYEOF' &
import http.server, sys
port = int(sys.argv[1])
class H(http.server.BaseHTTPRequestHandler):
    def _send(self, code=200, body=b"ok"):
        self.send_response(code); self.send_header("Content-Type", "text/plain")
        self.send_header("Set-Cookie", "a=1"); self.send_header("Set-Cookie", "b=2")
        self.end_headers()
        if self.command != "HEAD": self.wfile.write(body)
    def do_HEAD(self): self._send(200 if self.path != "/notfound" else 404)
    def do_GET(self):
        if self.path == "/notfound": self._send(404, b"nope"); return
        self._send(200, b"from-api")
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        self._send(200, self.rfile.read(n))
    def do_PUT(self):
        n = int(self.headers.get("Content-Length", 0)); self._send(200, self.rfile.read(n))
    def do_DELETE(self): self._send(200, b"deleted")
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", port), H).serve_forever()
PYEOF
SERVER_PID=$!
trap 'rm -rf "$t"; kill $SERVER_PID 2>/dev/null' EXIT
sleep 1

cat > "$t/site/t.f" <<EOF
@import("curl")
r := curl.request("http://127.0.0.1:$PORT/")
print(r.body)
setcookie := r.headers.get("set-cookie")
print(setcookie.size())
print(setcookie.join("; "))
print(curl.delete("http://127.0.0.1:$PORT/").body)
print(curl.version().contains("curl"))
EOF
out=$(cd "$t/site" && "$NIFT_BIN" t.f)
[ "$out" = $'from-api\n2\na=1; b=2\ndeleted\ntrue' ] || { printf 'unexpected curl facade output:\n%s\n' "$out" >&2; exit 1; }

# The deprecated top-level aliases are gone; only the facade is exported.
if (cd "$t/site" && printf '@import("curl")\nprint(request("http://127.0.0.1:%s/"))\n' "$PORT" > p.f && "$NIFT_BIN" p.f >/dev/null 2>&1); then
  echo "deprecated top-level curl alias unexpectedly present" >&2; exit 1
fi
if (cd "$t/site" && printf '@import("curl")\nprint(curl_parse_headers(""))\n' > p2.f && "$NIFT_BIN" p2.f >/dev/null 2>&1); then
  echo "curl private helper leaked" >&2; exit 1
fi

# Combined curl+sqlite import (only when the sqlite backend is available).
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "note: sqlite combined portion skipped (no sqlite3 executable)"
  printf 'PASS curl facade contract (ecosystem)\n'
  exit 0
fi
(cd "$t/site" && "$NIFT_BIN" add "$SQLITE_PKG" >/dev/null 2>&1)
cat > "$t/site/s.f" <<EOF
@import("curl")
@import("sqlite")
r := curl.request("http://127.0.0.1:$PORT/")
db := sqlite.open("cache.db")
sqlite.exec(db, "CREATE TABLE IF NOT EXISTS responses(status INTEGER, body TEXT)")
sqlite.exec(db, "INSERT INTO responses VALUES(?, ?)", r.status, r.body)
rows := sqlite.query(db, "SELECT * FROM responses")
print(rows.rows.size())
print(rows.rows[0].body)
EOF
out=$(cd "$t/site" && "$NIFT_BIN" s.f)
[ "$out" = $'1\nfrom-api' ] || { printf 'unexpected combined curl+sqlite output:\n%s\n' "$out" >&2; exit 1; }
if (cd "$t/site" && printf '@import("sqlite")\nprint(sqlite_bind)\n' > p3.f && "$NIFT_BIN" p3.f >/dev/null 2>&1); then
  echo "sqlite private helper leaked" >&2; exit 1
fi
printf 'PASS curl facade + sqlite combined (ecosystem)\n'