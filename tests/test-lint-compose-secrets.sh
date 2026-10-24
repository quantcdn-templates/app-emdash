#!/bin/bash
# Tests for scripts/lint-compose-secrets.sh
cd "$(dirname "$0")/.." || exit 1
# Last commit that still held the old defaults; CI needs full history.
BASE_REF=${BASE_REF:-ad465c872ceb6c60c97323dfa8c9394984681d36}
LINT=scripts/lint-compose-secrets.sh
FAILS=0
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILS=$((FAILS + 1)); }

expect() { # expect NAME WANT_RC FILE
  bash "$LINT" "$3" >/dev/null 2>&1
  if [ "$?" = "$2" ]; then pass "$1"; else fail "$1"; fi
}

git show "$BASE_REF:docker-compose.yml" >"$TMP/old.yml"
expect "old compose fails the lint" 1 "$TMP/old.yml"
expect "new compose passes the lint" 0 docker-compose.yml

cat >"$TMP/empty.yml" <<'Y'
services:
  app:
    environment:
      - API_TOKEN=${API_TOKEN:-}
      - OTHER_KEY=${OTHER_KEY}
      - EMPTY_PASS=
Y
expect "empty and bare references pass" 0 "$TMP/empty.yml"

cat >"$TMP/managed.yml" <<'Y'
services:
  db:
    labels:
      quant.type: database
    environment:
      - MYSQL_PASSWORD=${X:-y}
Y
expect "quant.type service is out of scope" 0 "$TMP/managed.yml"

cat >"$TMP/map.yml" <<'Y'
services:
  app:
    environment:
      DB_PASSWORD: ${DB_PASSWORD:-changeme}
Y
expect "map form default fails" 1 "$TMP/map.yml"

OUT=$(bash "$LINT" "$TMP/map.yml" 2>&1)
if grep -q "map.yml:4: DB_PASSWORD has a literal value" <<<"$OUT"; then pass "message names file, line and variable"; else fail "message names file, line and variable"; fi

[ "$FAILS" = 0 ] || { echo "$FAILS failure(s)"; exit 1; }
