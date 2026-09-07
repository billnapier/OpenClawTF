#!/usr/bin/env bash
set -eo pipefail

TEST_CONFIG="/tmp/test_rbac_$$.json"
trap 'rm -f "$TEST_CONFIG"' EXIT

echo "[TEST] Starting Multi-Tenant Authorization & RBAC Gateway Verification..."

# 1. Assign Roles
python3 /home/napier/a/OpenClaw/scripts/rbac_gateway.py --config "$TEST_CONFIG" --user-id 1001 --set-role "Admin" | grep -q '"status": "success"'
python3 /home/napier/a/OpenClaw/scripts/rbac_gateway.py --config "$TEST_CONFIG" --user-id 2002 --set-role "StandardUser" | grep -q '"status": "success"'
python3 /home/napier/a/OpenClaw/scripts/rbac_gateway.py --config "$TEST_CONFIG" --user-id 3003 --set-role "ReadOnly" | grep -q '"status": "success"'
echo "[TEST PASS] Role assignments saved to config."

# 2. Test Admin Authorized for Sensitive Action
ADMIN_RES=$(python3 /home/napier/a/OpenClaw/scripts/rbac_gateway.py --config "$TEST_CONFIG" --user-id 1001 --action "execute_cron_add")
echo "$ADMIN_RES" | grep -q '"allowed": true'
echo "[TEST PASS] Admin role authorization verified."

# 3. Test Standard User Denied Sensitive Admin Action
STD_DENIED=$(python3 /home/napier/a/OpenClaw/scripts/rbac_gateway.py --config "$TEST_CONFIG" --user-id 2002 --action "execute_cron_add")
echo "$STD_DENIED" | grep -q '"allowed": false'
echo "$STD_DENIED" | grep -q 'requires Admin role'
echo "[TEST PASS] StandardUser admin action rejection verified."

# 4. Test Standard User Allowed Standard Chat
STD_ALLOWED=$(python3 /home/napier/a/OpenClaw/scripts/rbac_gateway.py --config "$TEST_CONFIG" --user-id 2002 --action "chat")
echo "$STD_ALLOWED" | grep -q '"allowed": true'
echo "[TEST PASS] StandardUser chat action authorization verified."

# 5. Test Dynamic Reloading
RELOAD_RES=$(python3 /home/napier/a/OpenClaw/scripts/rbac_gateway.py --config "$TEST_CONFIG" --user-id 1001 --reload)
echo "$RELOAD_RES" | grep -q '"status": "success"'
echo "[TEST PASS] Dynamic RBAC config reload (/rbac reload) verified."

echo "[TEST SUCCESS] All Multi-Tenant RBAC Authorization tests passed!"
