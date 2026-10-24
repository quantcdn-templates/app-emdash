#!/bin/bash
# Tests for quant/entrypoints/00-require-secrets.sh
cd "$(dirname "$0")/.." || exit 1
# Last commit that still held the old defaults; CI needs full history.
BASE_REF=${BASE_REF:-ad465c872ceb6c60c97323dfa8c9394984681d36}
GUARD=quant/entrypoints/00-require-secrets.sh
FAILS=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILS=$((FAILS + 1)); }

# run_guard AUTH PREVIEW -> exit code in $RC, stderr in $ERR
run_guard() {
  ERR=$(EMDASH_AUTH_SECRET="$1" EMDASH_PREVIEW_SECRET="$2" bash -c ". $GUARD" 2>&1 >/dev/null)
  RC=$?
}

# Read an old compose value straight into the child env. Never echoed.
run_with_old() {
  local var=$1 other
  other=$(openssl rand -hex 16)
  ERR=$(git show "$BASE_REF:docker-compose.yml" | sed -n "s/^ *- $var=//p" | tr -d '\n' \
    | { IFS= read -r OLD; export OLD; if [ "$var" = EMDASH_AUTH_SECRET ]; then
          EMDASH_AUTH_SECRET="$OLD" EMDASH_PREVIEW_SECRET="$other" bash -c ". $GUARD"
        else
          EMDASH_AUTH_SECRET="$other" EMDASH_PREVIEW_SECRET="$OLD" bash -c ". $GUARD"
        fi; } 2>&1 >/dev/null)
  RC=$?
}

GOOD=$(openssl rand -hex 16)
GOOD2=$(openssl rand -hex 16)

run_guard "" "$GOOD2"
if [ "$RC" = 1 ] && grep -q EMDASH_AUTH_SECRET <<<"$ERR"; then pass "empty auth is refused"; else fail "empty auth is refused"; fi
run_guard "$GOOD" ""
if [ "$RC" = 1 ] && grep -q EMDASH_PREVIEW_SECRET <<<"$ERR"; then pass "empty preview is refused"; else fail "empty preview is refused"; fi

for var in EMDASH_AUTH_SECRET EMDASH_PREVIEW_SECRET; do
  run_with_old "$var"
  if [ "$RC" = 1 ] && grep -q "$var" <<<"$ERR"; then pass "known default is refused ($var)"; else fail "known default is refused ($var)"; fi
done

run_guard "$GOOD" "$GOOD2"
if [ "$RC" = 0 ]; then pass "generated values are accepted"; else fail "generated values are accepted"; fi

run_guard 'a$b&c#d e' 'x$y&z#w v'
if [ "$RC" = 0 ]; then pass "special characters are accepted"; else fail "special characters are accepted"; fi

[ "$FAILS" = 0 ] || { echo "$FAILS failure(s)"; exit 1; }
