#!/usr/bin/env python3
"""
OpenClaw Gemini Model Router Engine.
Supports interactive session switching and automatic rate-limit (429) fallback.
"""

import sys
import json
import argparse

MODELS = {
    "flash": "gemini-3.6-flash",
    "pro": "gemini-3.1-pro-preview"
}

DEFAULT_MODEL = "gemini-3.6-flash"
FALLBACK_MODEL = "gemini-3.6-flash"

class ModelRouter:
    def __init__(self, session_store_path="/tmp/openclaw_session_model.json"):
        self.session_store_path = session_store_path
        self.sessions = self._load_sessions()

    def _load_sessions(self):
        try:
            with open(self.session_store_path, 'r') as f:
                return json.load(f)
        except Exception:
            return {}

    def _save_sessions(self):
        try:
            with open(self.session_store_path, 'w') as f:
                json.dump(self.sessions, f)
        except Exception:
            pass

    def get_model(self, session_id="default"):
        val = self.sessions.get(session_id, DEFAULT_MODEL)
        if val not in MODELS.values():
            return DEFAULT_MODEL
        return val

    def handle_slash_command(self, command_str, session_id="default"):
        parts = command_str.strip().split()
        if not parts or parts[0] != "/model":
            return None, "Invalid command"

        if len(parts) == 1 or parts[1] == "status":
            current = self.get_model(session_id)
            return current, f"Active model: {current}. Fallback: {FALLBACK_MODEL}. Available: flash, pro"

        sub = parts[1].lower()
        if sub in MODELS:
            target = MODELS[sub]
            self.sessions[session_id] = target
            self._save_sessions()
            return target, f"Model switched to {target}"
        else:
            return None, f"Unknown model '{sub}'. Valid options: flash, pro, status"

    def route_request(self, session_id="default", simulate_status=200):
        target_model = self.get_model(session_id)
        if simulate_status == 429:
            fallback = FALLBACK_MODEL
            return {
                "model_used": fallback,
                "fallback_triggered": True,
                "notice": "Response generated via fallback model (gemini-2.5-flash)",
                "status": 200
            }
        return {
            "model_used": target_model,
            "fallback_triggered": False,
            "notice": None,
            "status": simulate_status
        }

    def get_tools(self):
        try:
            from tool_gateway import ToolGateway
            gw = ToolGateway()
            res = gw.list_mcp_tools()
            if res.get("status") == "success":
                return res.get("tools", [])
        except Exception:
            pass
        return []

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="OpenClaw Model Router CLI")
    parser.add_argument("--cmd", type=str, help="Slash command e.g. '/model pro'")
    parser.add_argument("--simulate-429", action="store_true", help="Simulate 429 rate limit error")
    args = parser.parse_args()

    router = ModelRouter()
    if args.cmd:
        model, msg = router.handle_slash_command(args.cmd)
        print(json.dumps({"model": model, "message": msg}))
    elif args.simulate_429:
        res = router.route_request(simulate_status=429)
        print(json.dumps(res))
    else:
        res = router.route_request()
        print(json.dumps(res))
