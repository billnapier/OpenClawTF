#!/usr/bin/env bash
set -eo pipefail

echo "[TEST] Starting Gemini Multi-Model Routing Verification..."

python3 /home/napier/a/OpenClaw/scripts/model_router.py --cmd "/model status" | grep -q "gemini-2.5-flash"
echo "[TEST PASS] Status query verified."

python3 /home/napier/a/OpenClaw/scripts/model_router.py --cmd "/model pro" | grep -q "gemini-2.5-pro"
echo "[TEST PASS] Model switch to gemini-2.5-pro verified."

FALLBACK_OUTPUT=$(python3 /home/napier/a/OpenClaw/scripts/model_router.py --simulate-429)
echo "$FALLBACK_OUTPUT" | grep -q '"fallback_triggered": true'
echo "$FALLBACK_OUTPUT" | grep -q 'Response generated via fallback model (gemini-2.5-flash)'
echo "[TEST PASS] Rate-limit HTTP 429 fallback verified."

python3 /home/napier/a/OpenClaw/scripts/model_router.py --cmd "/model flash" | grep -q "gemini-2.5-flash"
echo "[TEST PASS] Reset model to gemini-2.5-flash verified."

echo "[TEST SUCCESS] All Gemini model routing tests passed!"
