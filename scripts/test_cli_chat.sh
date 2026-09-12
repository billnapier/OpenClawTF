#!/usr/bin/env bash
set -eo pipefail

echo "[TEST] Starting CLI Chat Interface Verification..."

OPENCLAW="/home/napier/a/OpenClaw/scripts/openclaw"
TEST_DB="/tmp/test_cli_chat_$$.db"
export VECTOR_DB_PATH="$TEST_DB"
trap 'rm -f "$TEST_DB"' EXIT

# ---------------------------------------------------------------------------
# User Story 1: Interactive Terminal Conversation
# ---------------------------------------------------------------------------
echo "[TEST] -- User Story 1: Interactive Terminal Conversation --"

if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "[TEST SKIP] GEMINI_API_KEY not set — skipping live-Gemini round-trip scenarios."
  echo "[TEST SKIP]   (quickstart.md prerequisite: run this script on a deployed host with GEMINI_API_KEY configured)"
else
  # One-shot round trip (T012).
  RESP1=$(python3 "$OPENCLAW" chat "Say the single word: pong")
  [ -n "$RESP1" ]
  echo "[TEST PASS] One-shot round trip verified (non-empty response, exit 0)."

  # REPL multi-turn context awareness + /exit (T012).
  REPL_OUT=$(printf 'My favorite number is 42.\nWhat is my favorite number?\n/exit\n' | python3 "$OPENCLAW" chat 2>&1)
  echo "$REPL_OUT" | grep -qi "42"
  echo "[TEST PASS] REPL multi-turn context awareness verified."

  # Cross-invocation persistence: two separate process invocations share context (T012).
  python3 "$OPENCLAW" chat "Remember the code word banana77." > /dev/null
  RESP2=$(python3 "$OPENCLAW" chat "What was the code word I just told you?")
  echo "$RESP2" | grep -qi "banana77"
  echo "[TEST PASS] Cross-invocation persistence verified (separate process invocations share context)."
fi

# Channel-isolation spot-check (FR-008, T012) — deterministic, no live Gemini call needed.
python3 -c "
import sys
sys.path.insert(0, '/home/napier/a/OpenClaw/scripts')
from vector_memory import VectorMemoryEngine
engine = VectorMemoryEngine('$TEST_DB')
engine.add_memory('cli-only isolation-check message', session_id='cli', role='user')
other = engine.get_recent(session_id='telegram:999', limit=20)
assert other == [], 'cli session row leaked into telegram session'
mine = engine.get_recent(session_id='cli', limit=20)
assert any(r['text'] == 'cli-only isolation-check message' for r in mine), 'cli row not found in its own session'
print('OK')
" | grep -q "OK"
echo "[TEST PASS] Channel-isolation spot-check verified (cli session rows do not leak to other session_ids, FR-008)."

# --- Malformed/oversized input rejection (FR-010, T013) — no network call, deterministic. ---

OVERSIZED=$(python3 -c "print('a' * 8001)")
if OUT=$(python3 "$OPENCLAW" chat "$OVERSIZED" 2>&1); then
  echo "[TEST FAIL] Oversized input should have exited non-zero"
  exit 1
fi
echo "$OUT" | grep -qi "exceeds maximum length"
echo "[TEST PASS] Oversized input (>8000 chars) rejection verified, no network call made."

BAD_UTF8_RC_AND_ERR=$(python3 -c "
import subprocess
bad = b'hello \xff\xfe world'
p = subprocess.run(['python3', '$OPENCLAW', 'chat', bad.decode('utf-8', 'surrogateescape')], capture_output=True, text=True)
print(p.returncode)
print(p.stderr, end='')
")
BAD_UTF8_RC=$(echo "$BAD_UTF8_RC_AND_ERR" | head -1)
[ "$BAD_UTF8_RC" != "0" ]
echo "$BAD_UTF8_RC_AND_ERR" | grep -qi "not valid UTF-8"
echo "[TEST PASS] Invalid UTF-8 byte sequence rejection verified, no network call made."

NUL_OUT=$(printf 'hello\x00world\n/exit\n' | python3 "$OPENCLAW" chat 2>&1)
echo "$NUL_OUT" | grep -qi "invalid binary/control characters"
echo "[TEST PASS] NUL-byte / binary input rejection verified, no network call made."

# --- Backend-unreachable error path (FR-005, T013) — forces an unconfigured key,
#     deterministic without needing real network access. ---

if UNREACHABLE_OUT=$(GEMINI_API_KEY="" python3 "$OPENCLAW" chat "hello" 2>&1); then
  echo "[TEST FAIL] Backend-unreachable path should have exited non-zero"
  exit 1
fi
echo "$UNREACHABLE_OUT" | grep -qi "Agent backend unreachable"
echo "[TEST PASS] Backend-unreachable error path verified (no hang, clear stderr message)."

# --- REPL exit mechanisms (FR-004): /exit, /quit, Ctrl-D (EOF), Ctrl-C (SIGINT). ---

EXIT_OUT=$(printf '/exit\n' | python3 "$OPENCLAW" chat 2>&1)
echo "$EXIT_OUT" | grep -qi "Exiting"
QUIT_OUT=$(printf '/quit\n' | python3 "$OPENCLAW" chat 2>&1)
echo "$QUIT_OUT" | grep -qi "Exiting"
EOF_OUT=$(printf '' | python3 "$OPENCLAW" chat 2>&1)
echo "$EOF_OUT" | grep -qi "Exiting (EOF)"
echo "[TEST PASS] REPL exit mechanisms verified: /exit, /quit, Ctrl-D (EOF)."

SIGINT_RC=$(python3 -c "
import subprocess, signal, time
p = subprocess.Popen(['python3', '$OPENCLAW', 'chat'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
time.sleep(0.4)
p.send_signal(signal.SIGINT)
out, _ = p.communicate(timeout=5)
print(p.returncode)
assert 'Exiting (interrupted)' in out, out
")
[ "$SIGINT_RC" = "0" ]
echo "[TEST PASS] REPL exit via Ctrl-C (SIGINT) verified — clean exit, no orphaned process."

# ---------------------------------------------------------------------------
# User Story 2: Access Limited to the Host Itself
# ---------------------------------------------------------------------------
echo "[TEST] -- User Story 2: Access Limited to the Host Itself --"

# No listening socket / network server registered by the chat code path (FR-003, T016).
if grep -nE "\.bind\(|\.listen\(|socketserver|BaseHTTPRequestHandler|http\.server" \
     /home/napier/a/OpenClaw/scripts/openclaw \
     /home/napier/a/OpenClaw/scripts/channel_gateway.py \
     /home/napier/a/OpenClaw/scripts/vector_memory.py \
     /home/napier/a/OpenClaw/scripts/telegram_daemon.py; then
  echo "[TEST FAIL] Found a listening-socket/server pattern in the chat code path"
  exit 1
fi
echo "[TEST PASS] No listening socket / network server registered by the chat code path (FR-003)."

# CLIAdapter.is_authorized() always True for any/absent user_id (T017).
python3 -c "
import sys
sys.path.insert(0, '/home/napier/a/OpenClaw/scripts')
from channel_gateway import CLIAdapter
a = CLIAdapter()
assert a.is_authorized('arbitrary-user-id-12345') is True
assert a.is_authorized(None) is True
assert a.is_authorized('') is True
print('OK')
" | grep -q "OK"
echo "[TEST PASS] CLIAdapter.is_authorized() always returns True for any/absent user_id (FR-009)."

# No CLI-specific allowlist env var is read or honored (T017).
if grep -nE "CLI_ALLOWED_USER_IDS|CLI[_-]ALLOWED" \
     /home/napier/a/OpenClaw/scripts/openclaw \
     /home/napier/a/OpenClaw/scripts/channel_gateway.py; then
  echo "[TEST FAIL] Found a CLI-specific allowlist env var reference — FR-009 forbids a separate CLI credential"
  exit 1
fi
echo "[TEST PASS] No CLI-specific allowlist env var is read or honored (FR-009)."

echo "[TEST SUCCESS] All CLI Chat Interface tests passed!"
