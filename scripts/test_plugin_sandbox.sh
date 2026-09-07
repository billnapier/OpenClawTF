#!/usr/bin/env bash
set -eo pipefail

TEST_DIR="/tmp/test_plugins_$$"
mkdir -p "$TEST_DIR"
trap 'rm -rf "$TEST_DIR"' EXIT

echo "[TEST] Starting Dynamic Tool Plugin Sandbox Verification..."

# 1. Create a sample valid plugin
cat << 'EOF' > "$TEST_DIR/echo_tool.py"
def run(msg="hello"):
    return {"message": f"Echo: {msg}"}
EOF

# 2. List plugins
LIST_OUT=$(python3 /home/napier/a/OpenClaw/scripts/plugin_runner.py --dir "$TEST_DIR" --list)
echo "$LIST_OUT" | grep -q 'echo_tool'
echo "[TEST PASS] Dynamic plugin discovery (/plugin list) verified."

# 3. Execute plugin
EXEC_OUT=$(python3 /home/napier/a/OpenClaw/scripts/plugin_runner.py --dir "$TEST_DIR" --run echo_tool --args '{"msg": "World"}')
echo "$EXEC_OUT" | grep -q '"status": "success"'
echo "$EXEC_OUT" | grep -q 'Echo: World'
echo "[TEST PASS] Plugin execution verified."

# 4. Timeout enforcement (create infinite loop plugin)
cat << 'EOF' > "$TEST_DIR/slow_tool.py"
import time
def run():
    time.sleep(7)
    return {}
EOF

TIMEOUT_OUT=$(python3 /home/napier/a/OpenClaw/scripts/plugin_runner.py --dir "$TEST_DIR" --run slow_tool)
echo "$TIMEOUT_OUT" | grep -q '"status": "timeout"'
echo "$TIMEOUT_OUT" | grep -q 'exceeded 5s limit'
echo "[TEST PASS] Plugin 5s timeout sandbox limit verified."

echo "[TEST SUCCESS] All Dynamic Plugin Sandbox tests passed!"
