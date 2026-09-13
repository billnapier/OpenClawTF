#!/usr/bin/env python3
"""
OpenClaw Structured Tool Call & Sandboxed Execution Gateway.
Includes timeout enforcement, path containment, and output size caps.

Also implements the Google Workspace integration (Spec 025): Gemini
function-calling tool declarations (`list_mcp_tools`) and dispatch to the
`gog` CLI (`call_mcp_tool`), replacing the two previously-dangling method
references left behind by Spec 024's revert (see
specs/025-google-workspace-clawhub/research.md Decision 6).
"""

import os
import sys
import json
import time
import tempfile
import subprocess
import argparse

ALLOWED_DIRS = ["/mnt/disks/openclaw-data", "/tmp"]
TIMEOUT_SECONDS = 10
MAX_OUTPUT_BYTES = 2048

# --- Google Workspace (`gog`) configuration --------------------------------
#
# `gog` version/flag provenance (T001): the exact release tag and flag names
# assumed below were verified via web research against
# https://github.com/openclaw/gogcli/releases and https://gogcli.sh docs —
# NOT a live `gog schema --json` run, since no installable/runnable `gog`
# binary is available in this build environment. See
# specs/025-google-workspace-clawhub/research.md Decision 8's verification
# note for exactly what was and wasn't confirmed. Re-verify against the real
# binary on first actual deployment.
GOG_BINARY = os.environ.get("GOG_BINARY", "gog")
GOG_TIMEOUT_SECONDS = 30

# Exit-code -> status taxonomy, taken from `gog schema --json` on the pinned
# binary (automation.exit_codes). This supersedes an earlier partial mapping
# derived from https://gogcli.sh/automation.html, which omitted 1, 3, 10, 11
# and 130 - so those all fell through to a generic "error".
#
# Code 3 (empty_results) is the consequential one: a search that matched
# nothing is a *successful* call, and reporting it as a failure turned "you
# have no email today" into an error message.
GOG_EXIT_STATUS = {
    0: "success",          # ok
    1: "error",            # generic error
    2: "error",            # usage / invalid arguments
    3: "success",          # empty_results - call succeeded, nothing matched
    4: "auth_required",
    5: "error",            # not found
    6: "error",            # permission denied
    7: "error",            # rate limited (bounded retry first)
    8: "error",            # retryable transient failure (bounded retry first)
    10: "error",           # config
    11: "error",           # orphaned
    130: "error",          # cancelled
}
GOG_EXIT_MESSAGES = {
    1: "The Google Workspace tool call failed.",
    2: "Invalid arguments were passed to the Google Workspace tool.",
    4: "Google Workspace authentication is missing or expired. Please re-authenticate (see docs/Quickstart.md).",
    5: "The requested Google Workspace resource was not found.",
    6: "Permission denied for this Google Workspace action.",
    7: "Google Workspace API rate limit reached; please retry shortly.",
    8: "A transient failure occurred talking to Google Workspace; please retry.",
    10: "The Google Workspace tool is misconfigured on this host.",
    11: "The Google Workspace credential is orphaned; please re-authenticate (see docs/Quickstart.md).",
    130: "The Google Workspace tool call was cancelled.",
}
GOG_RETRYABLE_EXIT_CODES = {7, 8}
# Exit codes that carry a usable result on stdout rather than a failure.
GOG_RESULT_EXIT_CODES = {0, 3}

# Mutating functions require an explicit user confirmation before they are
# actually executed (research.md Decision 7 / data-model.md "Mutation
# Confirmation State"). `call_mcp_tool()` returns `confirmation_required` the
# first time one of these is invoked; only a subsequent call with
# `confirmed=True` actually shells out to `gog`.
MUTATING_FUNCTIONS = {"calendar_create_event", "send_message", "tasks_add", "tasks_complete"}

# Gemini function declarations (data-model.md "Tool Declaration" table).
# `readonly` is internal-only (stripped before being sent to Gemini by
# telegram_daemon.py's sanitize_schema/tools_payload construction, which only
# reads `name`/`description`/`inputSchema`).
MCP_TOOL_DECLARATIONS = [
    {
        "name": "calendar_get_events",
        "description": "List Google Calendar events between a start and end time.",
        "readonly": True,
        "inputSchema": {
            "type": "object",
            "properties": {
                "time_min": {"type": "string", "description": "ISO 8601 start of the time range."},
                "time_max": {"type": "string", "description": "ISO 8601 end of the time range."},
            },
            "required": ["time_min", "time_max"],
        },
    },
    {
        "name": "calendar_create_event",
        "description": "Create a new Google Calendar event. Requires user confirmation before it actually executes.",
        "readonly": False,
        "inputSchema": {
            "type": "object",
            "properties": {
                "summary": {"type": "string", "description": "Event title."},
                "start": {"type": "string", "description": "ISO 8601 event start time."},
                "end": {"type": "string", "description": "ISO 8601 event end time."},
            },
            "required": ["summary", "start", "end"],
        },
    },
    {
        "name": "list_messages",
        "description": "Search Gmail messages using Gmail query syntax.",
        "readonly": True,
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Gmail search query, e.g. 'is:unread budget'."},
                "max": {"type": "integer", "description": "Maximum number of messages to return."},
            },
            "required": ["query"],
        },
    },
    {
        "name": "send_message",
        "description": "Send a Gmail message. Requires user confirmation before it actually executes.",
        "readonly": False,
        "inputSchema": {
            "type": "object",
            "properties": {
                "to": {"type": "string", "description": "Recipient email address."},
                "subject": {"type": "string", "description": "Email subject line."},
                "body": {"type": "string", "description": "Plain-text email body."},
            },
            "required": ["to", "subject", "body"],
        },
    },
    {
        "name": "search_drive_files",
        "description": "Full-text search across Google Drive files.",
        "readonly": True,
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Drive search query."},
                "max": {"type": "integer", "description": "Maximum number of files to return."},
            },
            "required": ["query"],
        },
    },
    {
        "name": "tasks_list",
        "description": "List Google Tasks.",
        "readonly": True,
        "inputSchema": {
            "type": "object",
            "properties": {
                "tasklistId": {"type": "string", "description": "Task list ID; defaults to the primary list."},
            },
            "required": [],
        },
    },
    {
        "name": "tasks_add",
        "description": "Add a new Google Task. Requires user confirmation before it actually executes.",
        "readonly": False,
        "inputSchema": {
            "type": "object",
            "properties": {
                "tasklistId": {"type": "string", "description": "Task list ID; defaults to the primary list."},
                "title": {"type": "string", "description": "Task title."},
                "due": {"type": "string", "description": "Optional due date (RFC3339 or YYYY-MM-DD)."},
            },
            "required": ["title"],
        },
    },
    {
        "name": "tasks_complete",
        "description": "Mark a Google Task as complete. Requires user confirmation before it actually executes.",
        "readonly": False,
        "inputSchema": {
            "type": "object",
            "properties": {
                "tasklistId": {"type": "string", "description": "Task list ID; defaults to the primary list."},
                "taskId": {"type": "string", "description": "ID of the task to mark complete."},
            },
            "required": ["taskId"],
        },
    },
]


def is_path_safe(path):
    resolved = os.path.realpath(path)
    return any(resolved.startswith(allowed) for allowed in ALLOWED_DIRS)


def _default_tasklist(args):
    return args.get("tasklistId") or "@default"


class ToolGateway:
    def execute_python(self, code):
        start_t = time.time()
        try:
            res = subprocess.run(
                [sys.executable, "-c", code],
                capture_output=True,
                text=True,
                timeout=TIMEOUT_SECONDS
            )
            stdout = res.stdout[:MAX_OUTPUT_BYTES]
            stderr = res.stderr[:MAX_OUTPUT_BYTES]
            return {
                "status": "success" if res.returncode == 0 else "error",
                "returncode": res.returncode,
                "stdout": stdout,
                "stderr": stderr,
                "execution_time_ms": int((time.time() - start_t) * 1000)
            }
        except subprocess.TimeoutExpired:
            return {
                "status": "timeout",
                "error": "Tool execution timed out (10s limit)",
                "execution_time_ms": int((time.time() - start_t) * 1000)
            }

    def write_file(self, path, content):
        if not is_path_safe(path):
            return {"status": "error", "error": f"Path '{path}' outside allowed directories."}
        try:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w") as f:
                f.write(content)
            return {"status": "success", "bytes_written": len(content)}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def read_file(self, path):
        if not is_path_safe(path):
            return {"status": "error", "error": f"Path '{path}' outside allowed directories."}
        try:
            with open(path, "r") as f:
                content = f.read(MAX_OUTPUT_BYTES)
            return {"status": "success", "content": content}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def get_system_status(self):
        return {
            "status": "success",
            "uptime": "online",
            "pid": os.getpid(),
            "allowed_dirs": ALLOWED_DIRS
        }

    # --- Google Workspace (`gog`) integration (Spec 025) -------------------

    def list_mcp_tools(self):
        """Gemini function-declaration table for Google Workspace tools.

        Replaces the previously-nonexistent method `model_router.py`'s
        `get_tools()` calls (research.md Decision 6).
        """
        return {"status": "success", "tools": MCP_TOOL_DECLARATIONS}

    def _summarize_action(self, fn_name, args):
        if fn_name == "calendar_create_event":
            return (f"Create calendar event '{args.get('summary', '(untitled)')}' "
                    f"from {args.get('start', '?')} to {args.get('end', '?')}?")
        if fn_name == "send_message":
            return (f"Send an email to {args.get('to', '?')} "
                    f"with subject '{args.get('subject', '(no subject)')}'?")
        if fn_name == "tasks_add":
            due = args.get("due")
            due_str = f" (due {due})" if due else ""
            return f"Add task '{args.get('title', '(untitled)')}'{due_str} to your task list?"
        if fn_name == "tasks_complete":
            return f"Mark task {args.get('taskId', '?')} as complete?"
        return f"Execute {fn_name}?"

    def _run_gog(self, gog_args):
        """Invoke the `gog` subprocess, retrying once on a transient/rate-limited
        exit code (7/8, research.md Decision 9), and return the normalized
        Invocation Result shape from data-model.md. Never surfaces raw stderr.
        """
        cmd = [GOG_BINARY] + gog_args + ["--json", "--no-input"]
        attempts = 0
        last_exit_code = None
        last_stdout = ""
        while attempts < 2:
            attempts += 1
            try:
                proc = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=GOG_TIMEOUT_SECONDS,
                    env=os.environ.copy(),
                )
            except FileNotFoundError:
                return {
                    "status": "error",
                    "error": "The 'gog' CLI is not installed on this host.",
                    "exit_code": None,
                }
            except subprocess.TimeoutExpired:
                return {
                    "status": "error",
                    "error": "Google Workspace tool call timed out.",
                    "exit_code": None,
                }

            last_exit_code = proc.returncode
            last_stdout = proc.stdout or ""

            if last_exit_code in GOG_RESULT_EXIT_CODES:
                try:
                    parsed = json.loads(last_stdout) if last_stdout.strip() else {}
                except (ValueError, json.JSONDecodeError):
                    parsed = last_stdout
                return {"status": "success", "output": parsed, "exit_code": last_exit_code}

            if last_exit_code in GOG_RETRYABLE_EXIT_CODES and attempts < 2:
                # Single bounded retry for rate-limited/transient failures.
                continue
            break

        status = GOG_EXIT_STATUS.get(last_exit_code, "error")
        message = GOG_EXIT_MESSAGES.get(
            last_exit_code, "The Google Workspace tool call failed."
        )
        return {"status": status, "error": message, "exit_code": last_exit_code}

    def _dispatch(self, fn_name, args):
        if fn_name == "calendar_get_events":
            return self._run_gog([
                "calendar", "events", "primary",
                "--from", str(args.get("time_min", "")),
                "--to", str(args.get("time_max", "")),
            ])
        if fn_name == "calendar_create_event":
            return self._run_gog([
                "calendar", "create", "primary",
                "--summary", str(args.get("summary", "")),
                "--from", str(args.get("start", "")),
                "--to", str(args.get("end", "")),
            ])
        if fn_name == "list_messages":
            return self._run_gog([
                "gmail", "search", str(args.get("query", "")),
                "--max", str(args.get("max", 10)),
            ])
        if fn_name == "send_message":
            body = args.get("body", "")
            tmp_path = None
            try:
                with tempfile.NamedTemporaryFile(
                    mode="w", suffix=".txt", delete=False, dir="/tmp"
                ) as tmp:
                    tmp.write(body)
                    tmp_path = tmp.name
                return self._run_gog([
                    "gmail", "send",
                    "--to", str(args.get("to", "")),
                    "--subject", str(args.get("subject", "")),
                    "--body-file", tmp_path,
                ])
            finally:
                if tmp_path and os.path.exists(tmp_path):
                    try:
                        os.remove(tmp_path)
                    except OSError:
                        pass
        if fn_name == "search_drive_files":
            return self._run_gog([
                "drive", "search", str(args.get("query", "")),
                "--max", str(args.get("max", 10)),
            ])
        if fn_name == "tasks_list":
            return self._run_gog(["tasks", "list"])
        if fn_name == "tasks_add":
            gog_args = [
                "tasks", "add", _default_tasklist(args),
                "--title", str(args.get("title", "")),
            ]
            if args.get("due"):
                gog_args += ["--due", str(args.get("due"))]
            return self._run_gog(gog_args)
        if fn_name == "tasks_complete":
            return self._run_gog([
                "tasks", "done", _default_tasklist(args), str(args.get("taskId", "")),
            ])
        return {"status": "error", "error": f"Unknown tool '{fn_name}'.", "exit_code": None}

    def call_mcp_tool(self, fn_name, args_json, confirmed=False):
        """Single public entry point for Google Workspace tool calls.

        Wires together the fn_name -> `gog` dispatch table, exit-code
        mapping, and the confirm-before-mutate gate (research.md Decision 7 /
        data-model.md "Mutation Confirmation State"). Mutating functions
        return `status: "confirmation_required"` on first call; only a call
        with `confirmed=True` actually shells out to `gog`.
        """
        if isinstance(args_json, dict):
            args = args_json
        else:
            try:
                args = json.loads(args_json) if args_json else {}
            except (ValueError, json.JSONDecodeError):
                args = {}

        if fn_name in MUTATING_FUNCTIONS and not confirmed:
            return {
                "status": "confirmation_required",
                "summary": self._summarize_action(fn_name, args),
                "fn_name": fn_name,
                "args": args,
            }

        return self._dispatch(fn_name, args)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Tool Execution Gateway")
    parser.add_argument(
        "--tool", type=str, required=True,
        choices=[
            "execute_python", "write_file", "read_file", "get_system_status",
            "list_mcp_tools", "call_mcp_tool",
        ],
    )
    parser.add_argument("--arg1", type=str, default="")
    parser.add_argument("--arg2", type=str, default="")
    parser.add_argument("--confirmed", action="store_true", help="Bypass confirmation gate for call_mcp_tool (manual debugging).")
    args = parser.parse_args()

    gw = ToolGateway()
    if args.tool == "execute_python":
        print(json.dumps(gw.execute_python(args.arg1)))
    elif args.tool == "write_file":
        print(json.dumps(gw.write_file(args.arg1, args.arg2)))
    elif args.tool == "read_file":
        print(json.dumps(gw.read_file(args.arg1)))
    elif args.tool == "get_system_status":
        print(json.dumps(gw.get_system_status()))
    elif args.tool == "list_mcp_tools":
        print(json.dumps(gw.list_mcp_tools()))
    elif args.tool == "call_mcp_tool":
        # --arg1 = fn_name, --arg2 = JSON-encoded args
        print(json.dumps(gw.call_mcp_tool(args.arg1, args.arg2, confirmed=args.confirmed)))
