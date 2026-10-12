#!/bin/bash
# Image entrypoint. Normally the container starts as user dev and this just runs the command.
# When started as root with HOST_UID/HOST_GID set (run.sh does this on Linux when your UID is
# not dev's), dev is renumbered to match the owner of the mounted project, so files written in
# /workspace belong to you on the host, and the command then runs as dev.
set -e

if [ "$(id -u)" = 0 ] && [ -n "${HOST_UID:-}" ]; then
  HOST_GID="${HOST_GID:-$HOST_UID}"
  if [ "$HOST_UID" != "$(id -u dev)" ] || [ "$HOST_GID" != "$(id -g dev)" ]; then
    groupmod -o -g "$HOST_GID" dev
    usermod -o -u "$HOST_UID" dev >/dev/null
    chown -R dev:dev /home/dev
  fi
  exec setpriv --reuid=dev --regid=dev --init-groups \
    env HOME=/home/dev USER=dev LOGNAME=dev "$@"
fi

# Settings volumes created by an earlier image (where dev had another UID) would be read-only.
if [ "$(id -un 2>/dev/null)" = dev ]; then
  for d in .claude .codex .config/opencode .local/share/opencode .local/share/code-server; do
    [ -O "/home/dev/$d" ] || sudo chown -R dev:dev "/home/dev/$d" 2>/dev/null || true
  done
fi

exec "$@"
