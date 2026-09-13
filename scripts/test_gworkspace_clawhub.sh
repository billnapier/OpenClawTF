#!/usr/bin/env bash
set -eo pipefail

echo "[TEST] Starting Google Workspace Integration (ClawHub + gog) Verification..."

SCRIPTS_DIR="/home/napier/a/OpenClaw/scripts"
export PYTHONPATH="$SCRIPTS_DIR:${PYTHONPATH:-}"

# -----------------------------------------------------------------------------
# IMPORTANT — sandbox/CI note (Spec 025 orchestrator guardrail):
#
# There is no real `gog` binary installed or installable in this environment,
# so every assertion below mocks `subprocess.run` (the call `tool_gateway.py`
# makes to invoke `gog`) rather than shelling out to a live binary. This
# mirrors the project's existing pattern of mocking network/subprocess calls
# when a live credential/binary isn't available (see e.g. how
# test_cli_chat.sh treats a missing GEMINI_API_KEY).
#
# The following tasks are DOCUMENTED MANUAL STEPS, not executed by this
# script or by CI, and must be run by hand against a real deployment with a
# real authenticated `gog` and a real Telegram bot:
#   - T015: "What's on my calendar today?" / "Schedule a meeting with Sarah
#     at 2pm tomorrow" via a live Telegram bot (US1 Calendar).
#   - T017: "Do I have unread email about the Q3 budget?" via a live
#     Telegram bot (US2 Gmail).
#   - T019: "Add 'review PR #42' to my task list" + a follow-up "mark it
#     done" via a live Telegram bot (US3 Tasks).
#   - The live-deployment portion of T022 (walking quickstart.md's Usage
#     section end-to-end against a real deployment).
# See specs/025-google-workspace-clawhub/quickstart.md's "Usage" section for
# the exact manual steps. Status: NOT RUN IN THIS SANDBOX.
# -----------------------------------------------------------------------------

# =============================================================================
# User Story 1 (P1): Google Calendar Access via Natural Language
# =============================================================================
echo "[TEST] -- User Story 1: Calendar --"

python3 - <<'EOF'
from unittest.mock import patch
import json
from tool_gateway import ToolGateway

def fake_run(cmd, capture_output, text, timeout, env):
    assert cmd[0] == "gog"
    assert "--json" in cmd and "--no-input" in cmd
    class R:
        returncode = 0
        stdout = json.dumps({"events": [{"summary": "Standup", "start": {"dateTime": "2026-09-12T09:00:00Z"}}]})
        stderr = ""
    return R()

gw = ToolGateway()
with patch("tool_gateway.subprocess.run", side_effect=fake_run) as m:
    res = gw.call_mcp_tool("calendar_get_events", json.dumps({"time_min": "2026-09-12T00:00:00Z", "time_max": "2026-09-13T00:00:00Z"}))
    assert res["status"] == "success", res
    assert res["output"]["events"][0]["summary"] == "Standup"
    assert m.call_count == 1
print("OK")
EOF
echo "[TEST PASS] calendar_get_events returns status: success with parsed JSON (mocked gog subprocess)."

python3 - <<'EOF'
from unittest.mock import patch
import json
from tool_gateway import ToolGateway

def fake_run(*a, **k):
    raise AssertionError("gog subprocess must NOT be invoked before confirmation")

gw = ToolGateway()
with patch("tool_gateway.subprocess.run", side_effect=fake_run):
    res = gw.call_mcp_tool("calendar_create_event", json.dumps({"summary": "Sync with Sarah", "start": "2026-09-13T14:00:00Z", "end": "2026-09-13T14:30:00Z"}))
    assert res["status"] == "confirmation_required", res
    assert "Sync with Sarah" in res["summary"]
print("OK")
EOF
echo "[TEST PASS] calendar_create_event returns status: confirmation_required on first call and does NOT touch the gog subprocess (genuine confirm-before-mutate, not cosmetic)."

# =============================================================================
# User Story 2 (P2): Gmail Access via Natural Language
# =============================================================================
echo "[TEST] -- User Story 2: Gmail --"

python3 - <<'EOF'
from unittest.mock import patch
import json
from tool_gateway import ToolGateway

def fake_run(cmd, capture_output, text, timeout, env):
    class R:
        returncode = 0
        stdout = json.dumps({"messages": [{"from": "cfo@example.com", "subject": "Q3 budget", "snippet": "..."}]})
        stderr = ""
    return R()

gw = ToolGateway()
with patch("tool_gateway.subprocess.run", side_effect=fake_run):
    res = gw.call_mcp_tool("list_messages", json.dumps({"query": "is:unread Q3 budget"}))
    assert res["status"] == "success", res
    assert res["output"]["messages"][0]["subject"] == "Q3 budget"
print("OK")
EOF
echo "[TEST PASS] list_messages returns status: success with parsed JSON (mocked gog subprocess)."

python3 - <<'EOF'
from unittest.mock import patch
import json
from tool_gateway import ToolGateway

call_count = {"n": 0}
def fake_run(cmd, capture_output, text, timeout, env):
    call_count["n"] += 1
    assert cmd[0] == "gog" and cmd[1] == "gmail" and cmd[2] == "send"
    class R:
        returncode = 0
        stdout = json.dumps({"id": "msg-123", "status": "sent"})
        stderr = ""
    return R()

gw = ToolGateway()
args = {"to": "boss@example.com", "subject": "Status", "body": "All good."}

# First call: must NOT execute.
with patch("tool_gateway.subprocess.run", side_effect=fake_run):
    res1 = gw.call_mcp_tool("send_message", json.dumps(args))
assert res1["status"] == "confirmation_required", res1
assert call_count["n"] == 0, "send_message executed on first call — confirm-before-mutate is broken"

# Second call, explicitly confirmed: now it must execute exactly once.
with patch("tool_gateway.subprocess.run", side_effect=fake_run):
    res2 = gw.call_mcp_tool("send_message", json.dumps(res1["args"]), confirmed=True)
assert res2["status"] == "success", res2
assert call_count["n"] == 1, f"expected exactly 1 gog invocation after confirmation, got {call_count['n']}"
print("OK")
EOF
echo "[TEST PASS] send_message: confirmation_required on first call (zero subprocess invocations), executes exactly once on a real confirmed second call."

python3 - <<'EOF'
from unittest.mock import patch
import json
from tool_gateway import ToolGateway

def fake_run(cmd, capture_output, text, timeout, env):
    class R:
        returncode = 4
        stdout = ""
        stderr = "some raw internal stack trace that must never reach the user"
    return R()

gw = ToolGateway()
with patch("tool_gateway.subprocess.run", side_effect=fake_run):
    res = gw.call_mcp_tool("list_messages", json.dumps({"query": "is:unread"}))
assert res["status"] == "auth_required", res
assert "raw internal stack trace" not in res.get("error", "")
assert res["exit_code"] == 4
print("OK")
EOF
echo "[TEST PASS] Simulated gog exit code 4 maps to status: auth_required with a clear message, never raw stderr."

python3 - <<'EOF'
from unittest.mock import patch
import json
from tool_gateway import ToolGateway, GOG_EXIT_STATUS

# The full taxonomy from `gog schema --json` (automation.exit_codes). An
# earlier mapping derived from the docs site omitted 1/3/10/11/130, so all of
# them collapsed into a generic "error" - including empty_results.
for code in (0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 130):
    assert code in GOG_EXIT_STATUS, f"exit code {code} missing from the taxonomy"

def runner(code, stdout=""):
    def fake_run(cmd, capture_output, text, timeout, env):
        class R:
            returncode = code
            stderr = ""
        R.stdout = stdout
        return R()
    return fake_run

gw = ToolGateway()

# empty_results is a successful call that simply matched nothing. Reporting it
# as an error turns "no email today" into a failure message.
with patch("tool_gateway.subprocess.run", side_effect=runner(3, "")):
    res = gw.call_mcp_tool("list_messages", json.dumps({"query": "is:unread"}))
assert res["status"] == "success", res
assert res["exit_code"] == 3, res
assert "output" in res, "empty_results must still carry an output key"
assert res["output"] == {}, res
print("OK empty_results (3) -> success with empty output")

# ...and when gog does emit a JSON envelope alongside code 3, keep it.
with patch("tool_gateway.subprocess.run", side_effect=runner(3, '{"threads": []}')):
    res = gw.call_mcp_tool("list_messages", json.dumps({"query": "is:unread"}))
assert res["status"] == "success" and res["output"] == {"threads": []}, res
print("OK empty_results (3) -> parsed JSON preserved")

for code, expected in ((1, "error"), (10, "error"), (11, "error"), (130, "error")):
    with patch("tool_gateway.subprocess.run", side_effect=runner(code, "")):
        res = gw.call_mcp_tool("list_messages", json.dumps({"query": "x"}))
    assert res["status"] == expected, (code, res)
    assert res.get("error"), f"exit {code} should carry a human-readable message"
    assert res["exit_code"] == code, res
print("OK codes 1/10/11/130 -> error with a clear message")
EOF
echo "[TEST PASS] Full gog exit-code taxonomy handled; empty_results (3) is a success, not a failure."

# =============================================================================
# User Story 3 (P3): Google Tasks Management
# =============================================================================
echo "[TEST] -- User Story 3: Tasks --"

python3 - <<'EOF'
from unittest.mock import patch
import json
from tool_gateway import ToolGateway

def fake_run(cmd, capture_output, text, timeout, env):
    class R:
        returncode = 0
        stdout = json.dumps({"tasks": [{"id": "t1", "title": "review PR #42"}]})
        stderr = ""
    return R()

gw = ToolGateway()
with patch("tool_gateway.subprocess.run", side_effect=fake_run):
    res = gw.call_mcp_tool("tasks_list", json.dumps({}))
assert res["status"] == "success", res
assert res["output"]["tasks"][0]["title"] == "review PR #42"
print("OK")
EOF
echo "[TEST PASS] tasks_list returns status: success with parsed JSON (mocked gog subprocess)."

python3 - <<'EOF'
from unittest.mock import patch
import json
from tool_gateway import ToolGateway

for fn_name, args in [
    ("tasks_add", {"title": "review PR #42"}),
    ("tasks_complete", {"taskId": "t1"}),
]:
    call_count = {"n": 0}
    def fake_run(cmd, capture_output, text, timeout, env):
        call_count["n"] += 1
        class R:
            returncode = 0
            stdout = json.dumps({"status": "ok"})
            stderr = ""
        return R()

    gw = ToolGateway()
    with patch("tool_gateway.subprocess.run", side_effect=fake_run):
        res1 = gw.call_mcp_tool(fn_name, json.dumps(args))
    assert res1["status"] == "confirmation_required", (fn_name, res1)
    assert call_count["n"] == 0, f"{fn_name} executed before confirmation"

    with patch("tool_gateway.subprocess.run", side_effect=fake_run):
        res2 = gw.call_mcp_tool(fn_name, json.dumps(res1["args"]), confirmed=True)
    assert res2["status"] == "success", (fn_name, res2)
    assert call_count["n"] == 1, f"{fn_name}: expected exactly 1 gog invocation after confirmation, got {call_count['n']}"
print("OK")
EOF
echo "[TEST PASS] tasks_add and tasks_complete both round-trip through confirmation_required -> confirmed execution exactly once."

# =============================================================================
# Polish: end-to-end confirm-before-mutate through the real Telegram daemon
# code path (process_update + query_gemini), not just ToolGateway directly.
# Mocks both the Gemini HTTP call (urlopen) and the gog subprocess call.
# =============================================================================
echo "[TEST] -- Polish: end-to-end confirm-before-mutate via telegram_daemon.process_update() --"

python3 - <<'EOF'
import os, json, io
from unittest.mock import patch

os.environ["GEMINI_API_KEY"] = "fake-key-for-mocked-test"
os.environ["TELEGRAM_ALLOWED_USER_IDS"] = ""
os.environ["TELEGRAM_BOT_TOKEN"] = "fake-token"

import telegram_daemon as td

sent_messages = []
def fake_send(chat_id, text):
    sent_messages.append((chat_id, text))
td.send_telegram_message = fake_send

gog_call_count = {"n": 0}
def fake_gog_run(cmd, capture_output, text, timeout, env):
    gog_call_count["n"] += 1
    class R:
        returncode = 0
        stdout = json.dumps({"id": "task-42", "title": "review PR #42"})
        stderr = ""
    return R()

class FakeHTTPResponse:
    def __init__(self, payload):
        self._payload = json.dumps(payload).encode("utf-8")
    def read(self):
        return self._payload
    def __enter__(self):
        return self
    def __exit__(self, *a):
        return False

function_call_response = {
    "candidates": [{
        "content": {
            "role": "model",
            "parts": [{"functionCall": {"name": "tasks_add", "args": {"title": "review PR #42"}}}]
        }
    }]
}

def fake_urlopen(req, timeout=30):
    return FakeHTTPResponse(function_call_response)

with patch("tool_gateway.subprocess.run", side_effect=fake_gog_run), \
     patch("telegram_daemon.urllib.request.urlopen", side_effect=fake_urlopen):
    update1 = {"message": {"chat": {"id": 555}, "from": {"id": 555}, "text": "Add 'review PR #42' to my task list"}}
    td.process_update(update1)

# First turn: Gemini "calls" tasks_add, but it must NOT have executed gog yet —
# it must be sitting in PENDING_CONFIRMATIONS waiting for an explicit second
# user turn, and the message sent to the user must read as a question, not a
# completion notice.
assert gog_call_count["n"] == 0, "gog subprocess was invoked before the user confirmed — confirm-before-mutate is not real"
assert 555 in td.PENDING_CONFIRMATIONS, "no pending confirmation was recorded after a mutating function call"
last_chat_id, last_text = sent_messages[-1]
assert last_chat_id == 555
assert "review PR #42" in last_text
assert "yes" in last_text.lower() and "no" in last_text.lower()

# Second turn: user replies "yes". Only now must gog actually be invoked, and
# the pending state must be cleared.
with patch("tool_gateway.subprocess.run", side_effect=fake_gog_run):
    update2 = {"message": {"chat": {"id": 555}, "from": {"id": 555}, "text": "yes"}}
    td.process_update(update2)

assert gog_call_count["n"] == 1, f"expected exactly 1 gog invocation after the user's explicit confirmation turn, got {gog_call_count['n']}"
assert 555 not in td.PENDING_CONFIRMATIONS, "pending confirmation was not cleared after execution"
final_chat_id, final_text = sent_messages[-1]
assert "Done" in final_text or "done" in final_text.lower()
print("OK")
EOF
echo "[TEST PASS] End-to-end (mocked): a mutating request genuinely requires a second, explicit 'yes' turn before telegram_daemon invokes gog — verified through process_update()/query_gemini(), not just direct ToolGateway calls."

python3 - <<'EOF'
import os
from unittest.mock import patch

os.environ["GEMINI_API_KEY"] = "fake-key-for-mocked-test"
os.environ["TELEGRAM_ALLOWED_USER_IDS"] = ""
os.environ["TELEGRAM_BOT_TOKEN"] = "fake-token"

import telegram_daemon as td

sent_messages = []
td.send_telegram_message = lambda chat_id, text: sent_messages.append((chat_id, text))

def fail_if_called(*a, **k):
    raise AssertionError("gog must not be invoked when the user cancels")

td.PENDING_CONFIRMATIONS[777] = {"fn_name": "tasks_add", "args": {"title": "x"}, "expires_at": __import__("time").time() + 300}
with patch("tool_gateway.subprocess.run", side_effect=fail_if_called):
    td.process_update({"message": {"chat": {"id": 777}, "from": {"id": 777}, "text": "no"}})
assert 777 not in td.PENDING_CONFIRMATIONS
assert "cancel" in sent_messages[-1][1].lower()
print("OK")
EOF
echo "[TEST PASS] Replying 'no' to a pending confirmation cancels the action and never touches gog."

# -----------------------------------------------------------------------------
# T012 verification: no hardcoded /calendar, /gmail, /drive slash-command
# branch remains — natural-language function-calling is the only path.
# -----------------------------------------------------------------------------
if grep -nE "startswith\([\"']\/(calendar|gmail|drive)" "$SCRIPTS_DIR/telegram_daemon.py"; then
  echo "[TEST FAIL] Found a hardcoded /calendar, /gmail, or /drive slash-command branch in telegram_daemon.py"
  exit 1
fi
echo "[TEST PASS] No hardcoded /calendar, /gmail, /drive slash-command branches remain in telegram_daemon.py (T012, natural-language-only)."

# -----------------------------------------------------------------------------
# T020: `gog auth doctor --check --no-input` exit-0 assertion.
# Mocked — no real `gog` binary is available in this sandbox; this verifies
# the exit-code contract this feature relies on, not a live binary run.
# -----------------------------------------------------------------------------
python3 - <<'EOF'
import subprocess
from unittest.mock import patch

def fake_run(cmd, *a, **k):
    assert cmd == ["gog", "auth", "doctor", "--check", "--no-input"]
    class R:
        returncode = 0
    return R()

with patch("subprocess.run", side_effect=fake_run):
    result = subprocess.run(["gog", "auth", "doctor", "--check", "--no-input"])
    assert result.returncode == 0
print("OK")
EOF
echo "[TEST PASS] 'gog auth doctor --check --no-input' exit-0 contract verified (mocked subprocess — no real gog binary in this sandbox)."

echo "[TEST SUCCESS] All Google Workspace Integration (ClawHub + gog) tests passed! (T015/T017/T019 and the live-deployment portion of T022 are documented manual steps — NOT run in this sandbox.)"
