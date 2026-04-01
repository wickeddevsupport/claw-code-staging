#!/usr/bin/env bash
set -euo pipefail

export PORT="${PORT:-3000}"
export WETTY_PORT="${WETTY_PORT:-3001}"
export BASIC_AUTH_USER="${BASIC_AUTH_USER:-rajan}"
export BASIC_AUTH_PASSWORD="${BASIC_AUTH_PASSWORD:-change-me-now}"

HASH="$(caddy hash-password --plaintext "$BASIC_AUTH_PASSWORD")"

cat > /tmp/Caddyfile <<EOF
:${PORT} {
  encode gzip zstd

  handle /health* {
    respond "ok" 200
  }

  handle {
    basicauth {
      ${BASIC_AUTH_USER} ${HASH}
    }
    reverse_proxy 127.0.0.1:${WETTY_PORT}
  }
}
EOF

wetty --host 127.0.0.1 --port "${WETTY_PORT}" --base / --command /usr/local/bin/launch-claw.sh &
WETTY_PID=$!

cleanup() {
  kill "$WETTY_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

exec caddy run --config /tmp/Caddyfile --adapter caddyfile
