#!/usr/bin/env bash
set -eo pipefail

echo "[TEST] Starting Tool Execution Gateway & Sandbox Verification..."

# 1. Sandboxed Python execution
PY_OUT=$(python3 /home/napier/a/OpenClaw/scripts/tool_gateway.py --tool execute_python --arg1 "print('Hello Tool Gateway')")
echo "$PY_OUT" | grep -q '"status": "success"'
echo "$PY_OUT" | grep -q 'Hello Tool Gateway'
echo "[TEST PASS] Python tool execution verified."

# 2. File write & read containment
TEST_FILE="/tmp/openclaw_test_tool_$$.txt"
python3 /home/napier/a/OpenClaw/scripts/tool_gateway.py --tool write_file --arg1 "$TEST_FILE" --arg2 "Sandbox file test content" | grep -q '"status": "success"'
python3 /home/napier/a/OpenClaw/scripts/tool_gateway.py --tool read_file --arg1 "$TEST_FILE" | grep -q 'Sandbox file test content'
rm -f "$TEST_FILE"
echo "[TEST PASS] File write/read operations verified."

# 3. Restricted path rejection
UNSAFE_OUT=$(python3 /home/napier/a/OpenClaw/scripts/tool_gateway.py --tool read_file --arg1 "/etc/passwd")
echo "$UNSAFE_OUT" | grep -q '"status": "error"'
echo "$UNSAFE_OUT" | grep -q 'outside allowed directories'
echo "[TEST PASS] Security path restriction verified."

# 4. Timeout enforcement
TIMEOUT_OUT=$(python3 /home/napier/a/OpenClaw/scripts/tool_gateway.py --tool execute_python --arg1 "import time; time.sleep(12)")
echo "$TIMEOUT_OUT" | grep -q '"status": "timeout"'
echo "$TIMEOUT_OUT" | grep -q 'Tool execution timed out (10s limit)'
echo "[TEST PASS] Execution timeout enforcement verified."

echo "[TEST SUCCESS] All Tool Execution Gateway tests passed!"
