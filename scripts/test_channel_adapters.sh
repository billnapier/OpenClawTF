#!/usr/bin/env bash
set -eo pipefail

echo "[TEST] Starting Multi-Channel Transport Gateway Verification..."

export TELEGRAM_ALLOWED_USER_IDS="1111,2222"
export DISCORD_ALLOWED_USER_IDS="3333,4444"

# 1. Telegram Authorized Message
TG_AUTH=$(python3 /home/napier/a/OpenClaw/scripts/channel_gateway.py --channel telegram --user-id 1111 --text "Hello Telegram")
echo "$TG_AUTH" | grep -q '"status": "success"'
echo "[TEST PASS] Telegram authorized message processing verified."

# 2. Telegram Unauthorized Message
TG_UNAUTH=$(python3 /home/napier/a/OpenClaw/scripts/channel_gateway.py --channel telegram --user-id 9999 --text "Hello Telegram")
echo "$TG_UNAUTH" | grep -q '"status": "unauthorized"'
echo "$TG_UNAUTH" | grep -q 'Access Denied: User ID 9999'
echo "[TEST PASS] Telegram whitelist rejection parity verified."

# 3. Discord Authorized Message
DC_AUTH=$(python3 /home/napier/a/OpenClaw/scripts/channel_gateway.py --channel discord --user-id 3333 --text "Hello Discord")
echo "$DC_AUTH" | grep -q '"status": "success"'
echo "[TEST PASS] Discord authorized message processing verified."

# 4. Discord Unauthorized Message
DC_UNAUTH=$(python3 /home/napier/a/OpenClaw/scripts/channel_gateway.py --channel discord --user-id 8888 --text "Hello Discord")
echo "$DC_UNAUTH" | grep -q '"status": "unauthorized"'
echo "$DC_UNAUTH" | grep -q 'Access Denied: User ID 8888'
echo "[TEST PASS] Discord whitelist rejection parity verified."

echo "[TEST SUCCESS] All Multi-Channel Transport Gateway tests passed!"
