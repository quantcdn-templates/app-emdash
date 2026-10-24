#!/bin/bash
# Stop start-up unless each required secret is set to a unique value.
# The base image runs this script as a child process under `set -e`, so a
# non-zero exit stops the container before the app starts.

# SHA-256 of values that were published as defaults. Values are never stored.
KNOWN_DEFAULT_SHA256="
5f9cbfa52ba10bd80e486729dd63249339e348e5ea753e39cb64c0210419215a
f5aacbabea279cb64c98b0100505020bbaf32fc97a6e87b3c4daf841aeba2984
"

hash_value() {
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | cut -d' ' -f1
  else
    printf '%s' "$1" | shasum -a 256 | cut -d' ' -f1
  fi
}

is_known_default() {
  local digest
  digest=$(hash_value "$1")
  grep -qx "$digest" <<<"$KNOWN_DEFAULT_SHA256"
}

require_secret() {
  local name=$1 value=${!1}
  if [ -z "$value" ] || is_known_default "$value"; then
    echo "ERROR: $name is not set to a unique value. Set it as an application secret and redeploy." >&2
    exit 1
  fi
}

require_secret EMDASH_AUTH_SECRET
require_secret EMDASH_PREVIEW_SECRET
