#!/usr/bin/env bash
set -eo pipefail

TEST_DB="/tmp/test_vector_memory_$$.db"
trap 'rm -f "$TEST_DB"' EXIT

echo "[TEST] Starting Vector Context Search & Memory Engine Verification..."

python3 /home/napier/a/OpenClaw/scripts/vector_memory.py --db "$TEST_DB" --remember "User prefers concise summaries and Python over Bash" | grep -q "Memory stored successfully"
echo "[TEST PASS] Store memory (/remember) verified."

python3 /home/napier/a/OpenClaw/scripts/vector_memory.py --db "$TEST_DB" --remember "User works on GCP terraform modules" | grep -q "Memory stored successfully"

SEARCH_RES=$(python3 /home/napier/a/OpenClaw/scripts/vector_memory.py --db "$TEST_DB" --search "coding preferences")
echo "$SEARCH_RES" | grep -q "Python over Bash"
echo "[TEST PASS] Semantic memory search (/search) verified."

echo "[TEST SUCCESS] All Vector Memory Engine tests passed!"
