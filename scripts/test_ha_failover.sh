#!/usr/bin/env bash
set -eo pipefail

echo "[TEST] Starting HA Failover & Migration Verifier Test Suite..."

# 1. Test Dry Run Simulation
HA_OUT=$(bash /home/napier/a/OpenClaw/scripts/verify_ha_failover.sh --dry-run)
echo "$HA_OUT" | grep -q 'HA DRY-RUN'
echo "$HA_OUT" | grep -q 'SLA < 60s target met'
echo "$HA_OUT" | grep -q 'Zero-downtime failover verification SUCCESS'
echo "[TEST PASS] HA Failover dry-run simulation verified."

# 2. Test Custom Node Overrides
CUSTOM_HA=$(bash /home/napier/a/OpenClaw/scripts/verify_ha_failover.sh --dry-run --primary vm-a --standby vm-b)
echo "$CUSTOM_HA" | grep -q 'Primary VM: vm-a'
echo "$CUSTOM_HA" | grep -q 'Standby VM: vm-b'
echo "[TEST PASS] Custom primary/standby node parameter parsing verified."

echo "[TEST SUCCESS] All HA Failover & Migration Verifier tests passed!"
