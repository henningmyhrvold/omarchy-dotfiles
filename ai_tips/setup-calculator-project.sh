#!/usr/bin/env bash
# setup-calculator-project.sh
# Run this script to initialize the python-calculator Ralph project from scratch.
# Usage: bash setup-calculator-project.sh [target-dir]
#
# Prerequisites:
#   - ralph-orchestrator installed (ralph --version should work)
#   - claude CLI installed and authenticated
#   - git installed
#   - uv installed

set -e

TARGET_DIR="${1:-$HOME/src/python-calculator}"

echo "=== Setting up Ralph project: Python Calculator ==="
echo "Target: $TARGET_DIR"
echo ""

# ─── 1. Create directory ────────────────────────────────────────────────────
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"
echo "[1/6] Created directory: $TARGET_DIR"

# ─── 2. Initialize git ──────────────────────────────────────────────────────
if [ ! -d ".git" ]; then
    git init
    git commit --allow-empty -m "chore: initial commit"
    echo "[2/6] Initialized git"
else
    echo "[2/6] Git already initialized"
fi

# ─── 3. Copy Ralph project files ────────────────────────────────────────────
# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy all project files
cp "$SCRIPT_DIR/PROMPT.md" .
cp "$SCRIPT_DIR/CLAUDE.md" .
cp "$SCRIPT_DIR/plan.json" .
cp "$SCRIPT_DIR/ralph.yml" .
cp "$SCRIPT_DIR/activity.md" .

echo "[3/6] Copied Ralph project files"

# ─── 4. Initialize ralph workspace ──────────────────────────────────────────
ralph init 2>/dev/null || true  # ralph init is idempotent
echo "[4/6] Initialized ralph workspace (.agent/ directories)"

# ─── 5. First commit ────────────────────────────────────────────────────────
git add -A
git commit -m "chore: initialize ralph project structure"
echo "[5/6] Initial commit done"

# ─── 6. Verify prerequisites ────────────────────────────────────────────────
echo ""
echo "[6/6] Verifying prerequisites..."

ERRORS=0

if ! command -v ralph &>/dev/null && ! command -v ~/.local/bin/ralph &>/dev/null; then
    echo "  ✗ ralph not found. Install: uv tool install --from ~/.local/src/ralph-orchestrator ralph-orchestrator"
    ERRORS=$((ERRORS+1))
else
    RALPH_VERSION=$(ralph --version 2>/dev/null || ~/.local/bin/ralph --version 2>/dev/null)
    echo "  ✓ ralph: $RALPH_VERSION"
fi

if ! command -v claude &>/dev/null; then
    echo "  ✗ claude not found. Install: sudo pacman -S claude-code"
    ERRORS=$((ERRORS+1))
else
    echo "  ✓ claude: $(claude --version 2>/dev/null | head -1)"
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "  ✗ ANTHROPIC_API_KEY not set. Add to ~/.zshrc: export ANTHROPIC_API_KEY='sk-ant-...'"
    ERRORS=$((ERRORS+1))
else
    echo "  ✓ ANTHROPIC_API_KEY: set"
fi

if ! command -v uv &>/dev/null; then
    echo "  ✗ uv not found. Install: sudo pacman -S python-uv"
    ERRORS=$((ERRORS+1))
else
    echo "  ✓ uv: $(uv --version)"
fi

# Check MCP servers
MCP_RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null | grep '^mcp-' | wc -l)
if [ "$MCP_RUNNING" -gt 0 ]; then
    echo "  ✓ MCP servers running: $MCP_RUNNING"
else
    echo "  ⚠ No MCP servers detected. Claude will work without them but will have fewer tools."
    echo "    To start: systemctl --user start mcp-filesystem.service mcp-ref.service mcp-docker.service"
fi

echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo "=== ✗ Setup complete with $ERRORS prerequisite error(s). Fix them before running Ralph. ==="
else
    echo "=== ✓ Setup complete! Ready to run. ==="
    echo ""
    echo "Next steps:"
    echo "  cd $TARGET_DIR"
    echo "  ralph run -a claude --verbose 2>&1 | tee ralph.log"
    echo ""
    echo "Monitor in second terminal:"
    echo "  watch -n 15 'python3 -c \""
    echo "import json; d=json.load(open(\\\"plan.json\\\"))"
    echo "total=sum(len(p[\\\"tasks\\\"]) for p in d[\\\"phases\\\"])"
    echo "done=sum(1 for p in d[\\\"phases\\\"] for t in p[\\\"tasks\\\"] if t[\\\"passes\\\"])"
    echo "print(f\\\"Progress: {done}/{total}\\\")\"'"
fi
