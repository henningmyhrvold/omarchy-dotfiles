#!/bin/bash
set -euo pipefail

# ============================================================================
# Pi Coding Agent Offline Bundle Generator
# Run this on an ONLINE machine to create tarballs for offline install
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(mktemp -d)"
PREFIX="$WORK_DIR/npm-global"
PI_AGENT_DIR="$WORK_DIR/pi-agent"

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

echo "=== Creating clean npm global prefix ==="
mkdir -p "$PREFIX"

echo "=== Installing pi-coding-agent ==="
NPM_CONFIG_PREFIX="$PREFIX" npm install -g @mariozechner/pi-coding-agent

echo "=== Verifying pi binary ==="
"$PREFIX/bin/pi" --version || echo "Warning: pi --version failed (may need terminal)"

echo "=== Creating pi-npm-global.tar.gz ==="
tar -czf "$SCRIPT_DIR/pi-npm-global.tar.gz" -C "$WORK_DIR" npm-global

echo "=== Installing pi extensions ==="
mkdir -p "$PI_AGENT_DIR"
export HOME="$WORK_DIR/fakehome"
mkdir -p "$HOME/.pi/agent"

# Point pi to use our clean prefix
export PATH="$PREFIX/bin:$PATH"

# Install extensions — pi install writes to ~/.pi/agent/settings.json
# and downloads packages to ~/.pi/agent/npm/
pi install npm:oh-pi || echo "Warning: oh-pi install had issues (may need interactive)"
pi install npm:pi-hooks || echo "Warning: pi-hooks install had issues (may need interactive)"
pi install npm:pi-context || echo "Warning: pi-context install had issues (may need interactive)"
pi install npm:pi-interview || echo "Warning: pi-interview install had issues (may need interactive)"
pi install npm:pi-subagents || echo "Warning: subagents install had issues (may need interactive)"
pi install npm:pi-extensions || echo "Warning: pi extensions install had issues (may need interactive)"
pi install npm:@aliou/pi-guardrails || echo "Warning: pi guardrails install had issues (may need interactive)"

echo "=== Creating pi-agent-data.tar.gz ==="
# Bundle the pi agent directory (npm packages + settings)
tar -czf "$SCRIPT_DIR/pi-agent-data.tar.gz" -C "$HOME" .pi

echo ""
echo "=== Done ==="
echo "Files created:"
ls -lh "$SCRIPT_DIR/pi-npm-global.tar.gz"
ls -lh "$SCRIPT_DIR/pi-agent-data.tar.gz"
echo ""
echo "Commit these to your dotfiles repo or copy to USB."
