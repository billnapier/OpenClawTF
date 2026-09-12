#!/usr/bin/env python3
"""
OpenClaw Live Telegram Bot Daemon.
Long-polls Telegram API, enforces whitelist security, calls Gemini API, and returns responses.
"""

import os
import sys
import time
import json
import urllib.request
import urllib.error

TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "").strip()
ALLOWED_USERS_RAW = os.environ.get("TELEGRAM_ALLOWED_USER_IDS", "").strip()

# --- Mutation Confirmation State (Spec 025, data-model.md) -----------------
#
# Ephemeral, in-memory, per-chat pending-confirmation state for mutating
# Google Workspace tool calls (calendar_create_event, send_message,
# tasks_add, tasks_complete). Keyed by Telegram chat_id. Not persisted —
# restarting the daemon simply drops any pending confirmations, which is
# fine since they're short-TTL and re-askable.
PENDING_CONFIRMATIONS = {}
PENDING_CONFIRMATION_TTL_SECONDS = 300

_AFFIRMATIVE_WORDS = {"yes", "y", "yeah", "yep", "confirm", "confirmed", "ok", "okay", "go ahead", "do it", "proceed", "sure"}
_NEGATIVE_WORDS = {"no", "n", "nope", "cancel", "cancelled", "canceled", "stop", "nevermind", "never mind"}


def _is_affirmative(text):
    return text.strip().lower() in _AFFIRMATIVE_WORDS


def _is_negative(text):
    return text.strip().lower() in _NEGATIVE_WORDS

def parse_allowed_ids(raw):
    if not raw:
        return set()
    return set(x.strip() for x in raw.split(",") if x.strip())

def get_allowed_user_ids():
    raw = os.environ.get("TELEGRAM_ALLOWED_USER_IDS", "").strip()
    return parse_allowed_ids(raw)

def send_telegram_message(chat_id, text):
    token = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip() or TELEGRAM_BOT_TOKEN
    if not token:
        print("[DAEMON ERROR] TELEGRAM_BOT_TOKEN is not set.", flush=True)
        return
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = json.dumps({"chat_id": chat_id, "text": text}).encode('utf-8')
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            pass
    except Exception as e:
        print(f"[DAEMON ERROR] Failed to send message to Telegram chat {chat_id}: {e}", flush=True)

import datetime

def sanitize_schema(schema):
    if not isinstance(schema, dict):
        return schema
    clean = {}
    for k, v in schema.items():
        if k in ['title', 'additionalProperties', '$schema', 'default']:
            continue
        if k == 'anyOf' and isinstance(v, list) and len(v) > 0:
            non_null = [item for item in v if item.get('type') != 'null']
            if non_null:
                return sanitize_schema(non_null[0])
            continue
        if isinstance(v, dict):
            clean[k] = sanitize_schema(v)
        elif isinstance(v, list):
            clean[k] = [sanitize_schema(i) if isinstance(i, dict) else i for i in v]
        else:
            clean[k] = v
    if 'type' in clean:
        clean['type'] = clean['type'].upper()
    if 'required' in clean and 'properties' in clean:
        clean['required'] = [r for r in clean['required'] if r in clean['properties']]
    return clean

def query_gemini(prompt, session_id="default", history=None, chat_id=None):
    """Channel-agnostic Gemini query helper with tool-call/turn-2 support.

    `history` is an optional list of prior `{"role": "user"|"agent", "text": ...}`
    turns to seed `contents` before the current prompt (used by the CLI chat
    channel for cross-turn/cross-invocation context; omitted/empty preserves
    Telegram's existing single-prompt behavior byte-for-byte).

    `chat_id`, when provided (Telegram call site only), enables the
    confirm-before-mutate round trip (Spec 025): if Gemini calls a mutating
    Google Workspace function, the pending action is stashed in
    `PENDING_CONFIRMATIONS[chat_id]` and a human-readable confirmation
    question is returned instead of executing anything. Callers that omit
    `chat_id` (e.g. the CLI chat channel) never see a mutating call actually
    execute either — `call_mcp_tool` still returns `confirmation_required` —
    they just get that fact surfaced as text rather than round-tripped.
    """
    api_key = os.environ.get("GEMINI_API_KEY", "").strip() or GEMINI_API_KEY
    if not api_key:
        return "Error: GEMINI_API_KEY is not configured on OpenClaw server."
    try:
        from model_router import ModelRouter
        router = ModelRouter()
        model = router.get_model(session_id)
        mcp_tools = router.get_tools()
    except Exception:
        model = "gemini-3.6-flash"
        mcp_tools = []

    tools_payload = []
    if mcp_tools:
        func_decls = []
        for t in mcp_tools:
            schema = sanitize_schema(t.get("inputSchema", {}))
            func_decls.append({
                "name": t.get("name"),
                "description": t.get("description", ""),
                "parameters": schema
            })
        tools_payload = [{"function_declarations": func_decls}]

    now = datetime.datetime.now(datetime.timezone.utc)
    today_iso = now.isoformat()

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    system_prompt = f"You are OpenClaw, an autonomous AI assistant. Today's date and time is {today_iso}. You have full access to Google Workspace tools (Gmail, Calendar, Drive, Docs, Sheets, Tasks, Contacts). Always use tools when needed to answer calendar, email, or drive queries. When executing calendar queries, calculate appropriate ISO timestamps for time_min and time_max."

    user_content = []
    if history:
        for turn in history:
            role = "model" if turn.get("role") == "agent" else "user"
            user_content.append({"role": role, "parts": [{"text": turn.get("text", "")}]})
    user_content.append({"parts": [{"text": prompt}]})
    body = {
        "system_instruction": {"parts": [{"text": system_prompt}]},
        "contents": user_content
    }
    if tools_payload:
        body["tools"] = tools_payload

    try:
        payload = json.dumps(body).encode('utf-8')
        req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            candidates = data.get("candidates", [])
            if not candidates:
                return "No response generated by Gemini."

            candidate = candidates[0]
            parts = candidate.get("content", {}).get("parts", [])
            
            # Check for Function Calls from Gemini
            for part in parts:
                if "functionCall" in part:
                    fc = part["functionCall"]
                    fn_name = fc.get("name")
                    fn_args = fc.get("args", {})

                    if fn_name == "calendar_get_events" and "time_min" not in fn_args:
                        fn_args["time_min"] = (now - datetime.timedelta(days=1)).isoformat()
                        fn_args["time_max"] = (now + datetime.timedelta(days=7)).isoformat()

                    from tool_gateway import ToolGateway
                    gw = ToolGateway()
                    tool_res = gw.call_mcp_tool(fn_name, json.dumps(fn_args))

                    # Confirm-before-mutate (Spec 025, research.md Decision 7):
                    # a mutating call is never executed on this first pass —
                    # stash it and ask the user, rather than synthesizing a
                    # turn-2 response around output that doesn't exist yet.
                    if tool_res.get("status") == "confirmation_required":
                        summary = tool_res.get("summary", f"Execute {fn_name}?")
                        if chat_id is not None:
                            PENDING_CONFIRMATIONS[chat_id] = {
                                "fn_name": fn_name,
                                "args": tool_res.get("args", fn_args),
                                "expires_at": time.time() + PENDING_CONFIRMATION_TTL_SECONDS,
                            }
                            return f"⚠️ {summary}\n\nReply *yes* to proceed or *no* to cancel."
                        return f"⚠️ Confirmation required: {summary}"

                    output_val = tool_res.get("output", {})

                    # Turn 2: Provide tool execution output back to Gemini to synthesize
                    # response. Seed `history` here the same way turn 1 does (line
                    # 105-110 above) so tool-invoking turns don't lose prior
                    # conversation context. `history` defaults to None/empty for
                    # Telegram's existing call site, so this is a no-op there and
                    # preserves its behavior byte-for-byte.
                    turn2_contents = []
                    if history:
                        for turn in history:
                            role = "model" if turn.get("role") == "agent" else "user"
                            turn2_contents.append({"role": role, "parts": [{"text": turn.get("text", "")}]})
                    turn2_contents += [
                        {"role": "user", "parts": [{"text": prompt}]},
                        candidate.get("content", {}),
                        {
                            "role": "user",
                            "parts": [{
                                "functionResponse": {
                                    "name": fn_name,
                                    "response": {"content": output_val}
                                }
                            }]
                        }
                    ]
                    turn2_body = {
                        "system_instruction": body["system_instruction"],
                        "contents": turn2_contents
                    }
                    try:
                        req2 = urllib.request.Request(url, data=json.dumps(turn2_body).encode('utf-8'), headers={"Content-Type": "application/json"})
                        with urllib.request.urlopen(req2, timeout=30) as resp2:
                            data2 = json.loads(resp2.read().decode('utf-8'))
                            final_parts = data2.get("candidates", [{}])[0].get("content", {}).get("parts", [])
                            final_text = "".join([p.get("text", "") for p in final_parts if "text" in p]).strip()
                            if final_text:
                                return final_text
                    except Exception as turn2_err:
                        print(f"[DAEMON TURN2 ERROR] {turn2_err}", flush=True)

                    # Fallback to direct output string if turn 2 fails
                    output_str = json.dumps(output_val, indent=2) if isinstance(output_val, (dict, list)) else str(output_val)
                    return f"🛠️ *Executed Tool ({fn_name}):*\n```json\n{output_str}\n```"

            text_parts = [p.get("text", "") for p in parts if "text" in p]
            if text_parts:
                return "".join(text_parts).strip()
            return "No response generated by Gemini."
    except Exception as e:
        print(f"[DAEMON GEMINI ERROR] {e}", flush=True)
        return f"Gemini API Error: {e}"

def process_update(update):
    msg = update.get("message") or update.get("edited_message")
    if not msg:
        return

    chat_id = msg.get("chat", {}).get("id")
    user_id = str(msg.get("from", {}).get("id"))
    text = msg.get("text", "").strip()

    if not text or not chat_id:
        return

    allowed_ids = get_allowed_user_ids()

    # Check Whitelist Access
    if allowed_ids and user_id not in allowed_ids:
        print(f"[DAEMON REJECT] User ID {user_id} not in whitelist {allowed_ids}", flush=True)
        send_telegram_message(chat_id, f"🚫 Access Denied: Telegram User ID {user_id} is not whitelisted on OpenClaw.")
        return

    print(f"[DAEMON AUTH] Processing message from authorized User ID {user_id}: {text}", flush=True)

    if text in ["/start", "/help"]:
        send_telegram_message(
            chat_id,
            "🤖 OpenClaw Bot Active!\n"
            "Just ask naturally — e.g. \"what's on my calendar today?\", "
            "\"do I have unread email about the Q3 budget?\", or "
            "\"add 'review PR #42' to my task list\".\n"
            "Actions that change something (creating an event, sending mail, adding/completing "
            "a task) will ask you to confirm before they happen.\n"
            "/status - System status"
        )
        return
    elif text == "/status":
        send_telegram_message(
            chat_id,
            f"✅ OpenClaw Status: Online\nWhitelisted Users: {len(allowed_ids)}\nModel: gemini-3.6-flash\n"
            f"Google Workspace: via `gog` CLI (Gemini function-calling, natural language only)"
        )
        return

    # Confirm-before-mutate round trip (Spec 025, research.md Decision 7 /
    # data-model.md "Mutation Confirmation State"): if this chat has a live
    # pending mutating action, this message is treated as the yes/no reply
    # to it rather than a fresh query — natural-language routing below never
    # sees it.
    pending = PENDING_CONFIRMATIONS.get(chat_id)
    if pending:
        if pending["expires_at"] < time.time():
            del PENDING_CONFIRMATIONS[chat_id]
            pending = None
    if pending:
        if _is_affirmative(text):
            del PENDING_CONFIRMATIONS[chat_id]
            from tool_gateway import ToolGateway
            gw = ToolGateway()
            tool_res = gw.call_mcp_tool(pending["fn_name"], json.dumps(pending["args"]), confirmed=True)
            status = tool_res.get("status")
            if status == "success":
                send_telegram_message(chat_id, f"✅ Done. {json.dumps(tool_res.get('output', {}))}")
            else:
                send_telegram_message(chat_id, f"⚠️ {tool_res.get('error', 'The action could not be completed.')}")
            return
        elif _is_negative(text):
            del PENDING_CONFIRMATIONS[chat_id]
            send_telegram_message(chat_id, "🚫 Cancelled — no action was taken.")
            return
        else:
            # Not a recognizable yes/no reply: drop the stale pending action
            # and fall through to treat this message as a brand-new query.
            del PENDING_CONFIRMATIONS[chat_id]

    # Natural-language-only routing: no hardcoded /calendar, /gmail, /drive
    # commands. Gemini function-calling is the sole path to Google Workspace
    # tools (explicit user requirement, Spec 025).
    answer = query_gemini(text, chat_id=chat_id)
    send_telegram_message(chat_id, answer)

def main():
    token = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip() or TELEGRAM_BOT_TOKEN
    if not token:
        print("[DAEMON FATAL] Missing TELEGRAM_BOT_TOKEN.", flush=True)
        sys.exit(1)

    allowed_ids = get_allowed_user_ids()
    print(f"[DAEMON START] Telegram Bot Daemon running with {len(allowed_ids)} whitelisted users.", flush=True)
    offset = 0

    while True:
        try:
            token = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip() or TELEGRAM_BOT_TOKEN
            url = f"https://api.telegram.org/bot{token}/getUpdates?offset={offset}&timeout=20"
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                if data.get("ok"):
                    for update in data.get("result", []):
                        offset = update.get("update_id", 0) + 1
                        process_update(update)
        except Exception as e:
            print(f"[DAEMON POLL WARNING] Error during poll: {e}", flush=True)
            time.sleep(3)

if __name__ == "__main__":
    main()
