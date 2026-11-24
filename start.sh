#!/bin/busybox sh
# Start script for OpenTodo on Railway. Any failure exits non-zero, so Railway's
# ON_FAILURE restart policy restarts the service.
set -eu
bb=/bin/busybox
log() { echo "railway-start: $*" >&2; }

# Listen on Railway's PORT (OPENTODO_PORT replaces the port of OPENTODO_ADDR).
export OPENTODO_PORT="${PORT:-8080}"
export OPENTODO_DATA_DIR="${OPENTODO_DATA_DIR:-/data}"

# Closed sign-up: the owner account needs OPENTODO_SETUP_TOKEN, later people
# need an invitation from the owner.
export OPENTODO_ALLOW_SIGNUP="${OPENTODO_ALLOW_SIGNUP:-false}"

# Railway's edge proxy connects from 100.64.0.0/10 (and 152.233.0.0/16), which
# OpenTodo's default (private ranges only) doesn't trust. Trust them, so client
# addresses (rate limits, audit log) and X-Forwarded-Proto are read correctly.
export OPENTODO_TRUSTED_PROXIES="${OPENTODO_TRUSTED_PROXIES:-private 100.64.0.0/10 152.233.0.0/16}"

# The template refuses to start an unguarded first sign-up: without a setup
# token, whoever opens the public address first would become the owner.
tok="$(echo "${OPENTODO_SETUP_TOKEN:-}" | $bb tr -d '[:space:]')"
if [ "${#tok}" -lt 16 ]; then
  log "OPENTODO_SETUP_TOKEN must be set (16+ characters); refusing to start with an open owner sign-up"
  exit 1
fi

# OPENTODO_BASE_URL is built from ${{RAILWAY_PUBLIC_DOMAIN}}. If the service has
# no public domain yet it is just "https://", which OpenTodo rejects; start
# without it instead of crash-looping, and say how to fix it.
base="${OPENTODO_BASE_URL:-}"
case "$base" in
  http://?*|https://?*) ;;
  *)
    if [ -n "$base" ]; then
      log "OPENTODO_BASE_URL is '$base' (no host): the service has no public domain yet. Starting without it; generate a domain (port 8080) and redeploy."
    fi
    unset OPENTODO_BASE_URL ;;
esac

# Size Go's heap goal to the service's memory limit (80%), so the garbage
# collector works harder before the container is OOM-killed on small plans.
if [ -z "${GOMEMLIMIT:-}" ] && [ -r /sys/fs/cgroup/memory.max ]; then
  max="$($bb cat /sys/fs/cgroup/memory.max)"
  case "$max" in
    ''|max) ;;
    *) export GOMEMLIMIT="$(( max / 100 * 80 ))B" ;;
  esac
fi

# The Railway volume is mounted root-owned: give it to the image's nonroot user.
$bb mkdir -p "$OPENTODO_DATA_DIR"
$bb chown -R 65532:65532 "$OPENTODO_DATA_DIR"

log "starting OpenTodo $(/opentodo version 2>/dev/null | $bb cut -d' ' -f2) on port $OPENTODO_PORT (data in $OPENTODO_DATA_DIR)"
exec $bb setuidgid nonroot /opentodo
