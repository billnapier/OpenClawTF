#!/usr/bin/env bash
# Telegram daemon message-delivery tests.
#
# Regression cover for a bug where any reply over Telegram's 4096-character
# limit was rejected with an opaque "HTTP Error 400: Bad Request" and dropped
# entirely - the user saw nothing at all. Calendar answers fit; email summaries
# did not, which made it look like Gmail support was broken.
set -eo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - <<'EOF'
import sys, json
sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath("scripts/telegram_daemon.py")))
sys.path.insert(0, "scripts")
import telegram_daemon as td

# --- splitting ---------------------------------------------------------------
limit = td.TELEGRAM_TEXT_LIMIT
assert limit <= 4096, "chunk limit must stay under Telegram's hard cap"

long_text = ("word " * 3000).strip()
parts = td.split_for_telegram(long_text)
assert len(parts) > 1, "long text should split"
assert all(len(p) <= limit for p in parts), f"chunk exceeded limit: {[len(p) for p in parts]}"
assert "".join(p.replace(" ", "") for p in parts) == long_text.replace(" ", ""), "content lost while splitting"
print("OK split: long text -> %d chunks, all <= %d, no content lost" % (len(parts), limit))

short = "just a short reply"
assert td.split_for_telegram(short) == [short], "short text should pass through unchanged"
print("OK split: short text unchanged")

# prefers newline boundaries when one is available
para = ("a" * 100 + "\n") * 60
parts = td.split_for_telegram(para)
assert all(not p.startswith("a" * 100 + "a") for p in parts)
assert len(parts) > 1
print("OK split: respects line boundaries")

# a single unbroken token longer than the limit still gets cut rather than hang
blob = "z" * (limit * 2 + 17)
parts = td.split_for_telegram(blob)
assert all(len(p) <= limit for p in parts)
assert sum(len(p) for p in parts) == len(blob), "unbroken blob lost characters"
print("OK split: unbroken blob is chunked without loss")

# --- send behaviour ----------------------------------------------------------
calls = []


class FakeResp:
    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False


def fake_urlopen(req, timeout=None):
    calls.append(json.loads(req.data.decode()))
    return FakeResp()


td.urllib.request.urlopen = fake_urlopen
import os
os.environ["TELEGRAM_BOT_TOKEN"] = "test-token"

calls.clear()
td.send_telegram_message(42, "hello")
assert len(calls) == 1 and calls[0]["text"] == "hello"
print("OK send: short message -> 1 API call")

calls.clear()
td.send_telegram_message(42, long_text)
assert len(calls) > 1, "long message should be sent as multiple API calls"
assert all(len(c["text"]) <= limit for c in calls)
print("OK send: long message -> %d API calls, none over the limit" % len(calls))

calls.clear()
td.send_telegram_message(42, "   ")
assert calls == [], "empty/whitespace message must not hit the API"
print("OK send: empty message refused without an API call")
EOF

echo "[TEST SUCCESS] Telegram daemon message-delivery tests passed."
