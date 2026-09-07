#!/usr/bin/env bash
set -eo pipefail

echo "[TEST] Starting Disaster Recovery & Snapshot Restoration Verification..."

# 1. Dry run execution check
DRY_OUT=$(bash /home/napier/a/OpenClaw/scripts/disaster_recovery_restore.sh --dry-run)
echo "$DRY_OUT" | grep -q "DR DRY-RUN"
echo "$DRY_OUT" | grep -q "Restoration workflow dry-run completed successfully"
echo "[TEST PASS] Dry-run disaster recovery simulation verified."

# 2. Dry run with custom snapshot name
CUSTOM_OUT=$(bash /home/napier/a/OpenClaw/scripts/disaster_recovery_restore.sh --dry-run --snapshot my-test-snapshot)
echo "$CUSTOM_OUT" | grep -q "my-test-snapshot"
echo "[TEST PASS] Custom snapshot flag verified."

echo "[TEST SUCCESS] All Disaster Recovery restoration tests passed!"
