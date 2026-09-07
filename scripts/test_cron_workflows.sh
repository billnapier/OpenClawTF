#!/usr/bin/env bash
set -eo pipefail

TEST_DB="/tmp/test_cron_$$.db"
trap 'rm -f "$TEST_DB"' EXIT

echo "[TEST] Starting Scheduled Autonomous Workflows & Cron Gateway Verification..."

# 1. Add cron job
ADD_RES=$(python3 /home/napier/a/OpenClaw/scripts/cron_gateway.py --db "$TEST_DB" --add --schedule "0 9 * * *" --prompt "Run daily system report")
echo "$ADD_RES" | grep -q '"status": "success"'
echo "$ADD_RES" | grep -q 'scheduled'
JOB_ID=$(echo "$ADD_RES" | grep -o '"job_id": [0-9]*' | awk '{print $2}')
echo "[TEST PASS] Cron job registration (/cron add) verified (Job ID: $JOB_ID)."

# 2. List cron jobs
LIST_RES=$(python3 /home/napier/a/OpenClaw/scripts/cron_gateway.py --db "$TEST_DB" --list)
echo "$LIST_RES" | grep -q 'Run daily system report'
echo "[TEST PASS] Cron job listing (/cron list) verified."

# 3. Trigger tick & lock verification
TICK1=$(python3 /home/napier/a/OpenClaw/scripts/cron_gateway.py --db "$TEST_DB" --trigger "$JOB_ID")
echo "$TICK1" | grep -q '"status": "executed"'
echo "[TEST PASS] Cron trigger execution tick verified."

TICK2=$(python3 /home/napier/a/OpenClaw/scripts/cron_gateway.py --db "$TEST_DB" --trigger "$JOB_ID")
echo "$TICK2" | grep -q '"status": "locked"'
echo "[TEST PASS] Atomic execution lock prevention verified."

# 4. Remove job
REMOVE_RES=$(python3 /home/napier/a/OpenClaw/scripts/cron_gateway.py --db "$TEST_DB" --remove "$JOB_ID")
echo "$REMOVE_RES" | grep -q '"status": "success"'
echo "[TEST PASS] Cron job removal (/cron remove) verified."

echo "[TEST SUCCESS] All Cron Gateway workflow tests passed!"
