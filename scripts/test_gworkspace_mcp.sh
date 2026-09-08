#!/usr/bin/env bash
set -eo pipefail

echo "============================================================"
echo " Running OpenClaw Google Workspace MCP Integration Tests    "
echo "============================================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "[TEST 1] Verifying ToolGateway MCP tool listing..."
TOOLS_JSON=$(python3 "${SCRIPT_DIR}/tool_gateway.py" --tool list_mcp_tools)
if echo "$TOOLS_JSON" | grep -q "calendar_list_events" && echo "$TOOLS_JSON" | grep -q "gmail_search"; then
  echo "✓ PASS: ToolGateway returns Workspace tool definitions."
else
  echo "✗ FAIL: ToolGateway failed to list tools."
  exit 1
fi

echo "[TEST 2] Verifying ToolGateway MCP proxy execution..."
TOOL_RES=$(python3 "${SCRIPT_DIR}/tool_gateway.py" --tool call_mcp_tool --arg1 calendar_list_events --arg2 "{}")
if echo "$TOOL_RES" | grep -q '"status": "success"'; then
  echo "✓ PASS: ToolGateway successfully dispatched MCP call over stdio."
else
  echo "✗ FAIL: ToolGateway failed MCP proxy execution."
  exit 1
fi

echo "[TEST 3] Verifying Gmail & Drive tool execution via MCP..."
GMAIL_RES=$(python3 "${SCRIPT_DIR}/tool_gateway.py" --tool call_mcp_tool --arg1 gmail_search --arg2 '{"query":"is:unread"}')
if echo "$GMAIL_RES" | grep -q '"status": "success"'; then
  echo "✓ PASS: Gmail search via MCP returned success status."
else
  echo "✗ FAIL: Gmail search via MCP failed."
  exit 1
fi

echo "[TEST 4] Verifying Workspace Vector Memory RAG Sync..."
SYNC_RES=$(python3 "${SCRIPT_DIR}/sync_gworkspace_vector_memory.py")
if echo "$SYNC_RES" | grep -q '"synced_documents": 2'; then
  echo "✓ PASS: Workspace document ingestion to Vector Memory succeeded."
else
  echo "✗ FAIL: Workspace Vector Memory sync failed."
  exit 1
fi

echo "[TEST 5] Verifying Terraform Secrets Module HCL validation..."
if command -v terraform &>/dev/null; then
  (cd "${REPO_ROOT}/terraform/modules/secrets" && terraform init -backend=false &>/dev/null && terraform validate)
  echo "✓ PASS: Terraform secrets module HCL validated."
fi

echo "============================================================"
echo " All Google Workspace MCP Integration Tests Passed!         "
echo "============================================================"
