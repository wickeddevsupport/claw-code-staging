#!/usr/bin/env bash
set -euo pipefail
cd /workspace
printf '\n🦞 Claw Code staging wrapper\n'
printf 'Upstream pinned commit: %s\n' '9ade3a70d70ae690ae15d3c8f1de7e6d03d87a2a'
printf 'Workspace: %s\n\n' "$PWD"
printf 'Use `claw login` or set model env vars manually inside this isolated session.\n'
printf 'No host mounts or production secrets are preloaded here.\n\n'
exec /usr/local/bin/claw
