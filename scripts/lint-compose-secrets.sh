#!/bin/bash
# Usage: lint-compose-secrets.sh <compose-file>...
# Fail when a service without a quant.type label sets a secret-like
# environment variable (name has KEY, SECRET, PASSWORD, PASS, TOKEN or SALT)
# to a literal value or to a ${VAR:-default} with a non-empty default.
# Empty values, ${VAR} and ${VAR:-} pass.

AWK_PROGRAM='
function flush(   i) {
  if (!managed) for (i = 1; i <= n; i++) print FILENAME ":" lno[i] ": " nm[i] " has a literal value"
  n = 0; managed = 0
}
function leading(s) { match(s, /^ */); return RLENGTH }
function secret_name(v) { return toupper(v) ~ /(KEY|SECRET|PASSWORD|PASS|TOKEN|SALT)/ }
function literal(v) {
  gsub(/^["\047]|["\047]$/, "", v)
  if (v == "" || v ~ /^\$\{[A-Za-z_0-9]+\}$/ || v ~ /^\$\{[A-Za-z_0-9]+:?-\}$/) return 0
  if (v ~ /^\$\{[A-Za-z_0-9]+:?\?/) return 0
  return 1
}
function record(name, val) {
  if (secret_name(name) && literal(val)) { n++; nm[n] = name; lno[n] = NR }
}
function entry(line) {
  sub(/^ */, "", line); sub(/^- */, "", line)
  if (match(line, /^[A-Za-z_][A-Za-z_0-9]*[=:]/)) {
    name = substr(line, 1, RLENGTH - 1)
    val = substr(line, RLENGTH + 1); sub(/^ +/, "", val); sub(/ +#.*$/, "", val)
    record(name, val)
  }
}
/^[ \t]*(#|$)/ { next }
{ ind = leading($0) }
/^services:/ { insvc = 1; next }
insvc && ind == 0 { flush(); insvc = 0 }
insvc && ind == 2 && /^ *[^ ]+:/ { flush(); inenv = 0; next }
/quant\.type/ { managed = 1 }
inenv && ind <= envind { inenv = 0 }
inenv { entry($0); next }
insvc && /^ *environment: *$/ { inenv = 1; envind = ind }
END { flush() }
'

lint_file() { awk "$AWK_PROGRAM" "$1"; }

main() {
  local out="" f rc=0
  for f in "$@"; do out+=$(lint_file "$f")$'\n'; done
  out=$(printf '%s' "$out" | sed '/^$/d')
  [ -z "$out" ] && return 0
  printf '%s\n' "$out" >&2
  return 1
}

main "$@"
