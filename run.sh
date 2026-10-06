#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIFT_BIN="${NIFT_BIN:-${1:-nift}}"

if [[ -n "${NIFT_EXPECT_VERSION:-}" ]]; then
  NIFT_EXPECT_VERSION="${NIFT_EXPECT_VERSION#v}"
  export NIFT_EXPECT_VERSION
fi

# Package sources resolve to the sibling nift-packages checkouts ("current
# official package main") by default; every module honours a per-package
# override (e.g. SQLITE_PKG=/path/to/pinned/sqlite) so a pinned-snapshot mode
# can be added without harness changes.
export NIFT_PACKAGES_ROOT="${NIFT_PACKAGES_ROOT:-$(cd "$ROOT/../nift-packages" 2>/dev/null && pwd)}"

if [[ "$NIFT_BIN" == */* && -x "$NIFT_BIN" ]]; then
  NIFT_BIN="$(cd "$(dirname "$NIFT_BIN")" && pwd)/$(basename "$NIFT_BIN")"
elif command -v "$NIFT_BIN" >/dev/null 2>&1; then
  NIFT_BIN="$(command -v "$NIFT_BIN")"
else
  echo "FAIL: NIFT_BIN not found: $NIFT_BIN" >&2
  exit 2
fi
export NIFT_BIN

FAILS=0
MODULES=0
TMP="$(mktemp -d "${TMPDIR:-/tmp}/nift-packages-suite.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

run_module(){
  local name="$1"; shift
  MODULES=$((MODULES+1))
  local log="$TMP/${MODULES}.log"
  if "$@" >"$log" 2>&1; then
    printf 'PASS  %s\n' "$name"
  else
    printf 'FAIL  %s\n' "$name" >&2
    cat "$log" >&2
    FAILS=$((FAILS+1))
  fi
}

CONTRACT_TESTS=(
  curl_facade_smoke.sh
  sqlite_module_smoke.sh
  database_packages_smoke.sh
  parameter_binding_smoke.sh
  transaction_atomicity_smoke.sh
  imagemagick_package_smoke.sh
  vips_magick_combined_smoke.sh
)

INTEGRATION_TESTS=(
  coexistence_smoke.sh
  privacy_smoke.sh
  no_process_smoke.sh
  source_install_smoke.sh
  combined_consumer_smoke.sh
)

# Fail closed when a test file is added but not wired into this runner.
wired(){ local f="$1"; shift; for t in "$@"; do [[ "$f" == "$t" ]] && return 0; done; return 1; }
ORPHANS=()
while IFS= read -r path; do
  test="$(basename "$path")"
  if ! wired "$test" "${CONTRACT_TESTS[@]}" "${INTEGRATION_TESTS[@]}"; then ORPHANS+=("$test"); fi
done < <(find "$ROOT/contract" "$ROOT/integration" -maxdepth 1 -name '*.sh' 2>/dev/null | sort)
if (( ${#ORPHANS[@]} )); then
  printf 'FAIL: suite files not wired into run.sh:\n' >&2
  printf '  %s\n' "${ORPHANS[@]}" >&2
  exit 2
fi

for test in "${CONTRACT_TESTS[@]}"; do
  run_module "contract/$test" env NIFT_BIN="$NIFT_BIN" NIFT_PACKAGES_ROOT="$NIFT_PACKAGES_ROOT" bash "$ROOT/contract/$test"
done
for test in "${INTEGRATION_TESTS[@]}"; do
  run_module "integration/$test" env NIFT_BIN="$NIFT_BIN" NIFT_PACKAGES_ROOT="$NIFT_PACKAGES_ROOT" bash "$ROOT/integration/$test"
done

if [[ $FAILS -eq 0 ]]; then
  printf '\nPASS: %d package regression modules\n' "$MODULES"
  exit 0
fi
printf '\nFAIL: %d of %d package regression modules failed\n' "$FAILS" "$MODULES" >&2
exit 1