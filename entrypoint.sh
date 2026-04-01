#!/usr/bin/env bash
set -euo pipefail

export PORT="${PORT:-3000}"
export CODE_SERVER_PORT="${CODE_SERVER_PORT:-3001}"
export BASIC_AUTH_USER="${BASIC_AUTH_USER:-rajan}"
export BASIC_AUTH_PASSWORD="${BASIC_AUTH_PASSWORD:-change-me-now}"

HASH="$(caddy hash-password --plaintext "$BASIC_AUTH_PASSWORD")"

mkdir -p /home/claw/.config/code-server /home/claw/.local/share/code-server/User /workspace

cat > /home/claw/.config/code-server/config.yaml <<EOF
bind-addr: 127.0.0.1:${CODE_SERVER_PORT}
auth: none
cert: false
EOF

cat > /home/claw/.local/share/code-server/User/settings.json <<'EOF'
{
  "workbench.colorTheme": "Default Dark Modern",
  "workbench.startupEditor": "readme",
  "security.workspace.trust.enabled": false,
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.tabs.enabled": true,
  "files.autoSave": "afterDelay",
  "update.mode": "none",
  "telemetry.telemetryLevel": "off"
}
EOF

if [ ! -f /workspace/README-STAGING.md ]; then
cat > /workspace/README-STAGING.md <<'EOF'
# Claw Code Staging Workspace

This workspace runs inside an isolated staging container.

## What's installed

- `claw` CLI (from the pinned `instructkr/claw-code` Rust build)
- code-server
- Continue extension
- Cline extension

## First steps

1. Open the integrated terminal.
2. Run `claw --help`.
3. Configure Continue / Cline with only the minimum model credentials you want to test.
4. Treat this as staging — do not paste sensitive long-lived secrets unless you intend to.
EOF
fi

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
    reverse_proxy 127.0.0.1:${CODE_SERVER_PORT}
  }
}
EOF

code-server /workspace --config /home/claw/.config/code-server/config.yaml --disable-telemetry --disable-update-check &
CODE_SERVER_PID=$!

cleanup() {
  kill "$CODE_SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

exec caddy run --config /tmp/Caddyfile --adapter caddyfile
