#!/usr/bin/env bash
set -eo pipefail

echo "[TEST] Starting OpenTelemetry APM & Distributed Tracing Verification..."

# 1. Full turn tracing verification
TRACE_OUT=$(python3 /home/napier/a/OpenClaw/scripts/otel_tracing.py --trace-turn)
echo "$TRACE_OUT" | grep -q '"trace_id":'
echo "$TRACE_OUT" | grep -q 'channel.receive'
echo "$TRACE_OUT" | grep -q 'rbac.authorize'
echo "$TRACE_OUT" | grep -q 'vector.search'
echo "$TRACE_OUT" | grep -q 'gemini.generate_content'
echo "[TEST PASS] Multi-span message lifecycle tracing verified."

# 2. Secret Redaction Verification
echo "$TRACE_OUT" | grep -q '"gemini_api_key": "\[REDACTED\]"'
echo "[TEST PASS] Secret sanitization in trace attributes verified."

echo "[TEST SUCCESS] All OpenTelemetry Distributed Tracing tests passed!"
