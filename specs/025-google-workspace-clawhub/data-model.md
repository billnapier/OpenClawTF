# Data Model: Google Workspace Integration via `gog`

This feature has no new persistent database entities — it's a subprocess-dispatch layer between Gemini Function Calling and the `gog` CLI. The "data model" here is the tool-name-to-CLI-invocation mapping `tool_gateway.py` must implement, plus the small amount of runtime configuration state it depends on.

## Entity: Tool Declaration

What `model_router.get_tools()` returns to `telegram_daemon.query_gemini()` as Gemini `function_declarations`. Replaces the currently-nonexistent `ToolGateway.list_mcp_tools()` (see research.md Decision 6).

| Field | Description |
|---|---|
| `name` | Stable function name Gemini calls, e.g. `calendar_get_events` (existing name, already referenced at `telegram_daemon.py:137` — keep it to avoid touching that call site) |
| `description` | Natural-language description Gemini uses to decide when to call it |
| `inputSchema` | JSON Schema for arguments; sanitized by the existing `sanitize_schema()` before being sent to Gemini — no change needed there |
| `readonly` | New field (not part of Gemini's schema, stripped before sending) — drives whether `tool_gateway.py` passes `--readonly` and whether the confirm-before-mutate flow is required |

## Entity: Tool Call → `gog` Invocation Mapping

What `ToolGateway.call_mcp_tool(fn_name, args_json)` must implement (replacing the currently-nonexistent method, research.md Decision 6). Each row is a Gemini function name mapped to a `gog` subprocess invocation:

| `fn_name` (Gemini-facing) | `gog` command | Mutating? |
|---|---|---|
| `calendar_get_events` | `gog calendar events primary --from <time_min> --to <time_max> --json --no-input` | No |
| `calendar_create_event` | `gog calendar create primary --summary <summary> --from <start> --to <end> --json --no-input` | **Yes** |
| `list_messages` | `gog gmail search '<query>' --max <max> --json --no-input` | No |
| `send_message` | `gog gmail send --to <to> --subject <subject> --body-file <tmpfile> --json --no-input` | **Yes** |
| `search_drive_files` | `gog drive search '<query>' --max <max> --json --no-input` | No |
| `tasks_list` | `gog tasks list --json --no-input` | No |
| `tasks_add` | `gog tasks add <tasklistId> --title <title> [--due <due>] --json --no-input` | **Yes** |
| `tasks_complete` | `gog tasks done <tasklistId> <taskId> --json --no-input` | **Yes** |

`calendar_get_events` and `send_message`/`list_messages` keep their existing names since `telegram_daemon.py:137` and the `/gmail`, `/calendar`, `/drive` slash-command handlers (`telegram_daemon.py:225-270`) already reference them by name — only their *implementation* is dead today, not their call sites.

All invocations pass `--account $GOG_ACCOUNT` implicitly via the environment (Decision 10, research.md) rather than as an explicit flag per call.

> **T001 verification note**: this mapping was cross-checked against `gogcli.sh` docs and `github.com/openclaw/gogcli` (web research; no live `gog schema --json` available in this sandbox — see research.md Decision 8's verification note for detail and what remains unconfirmed). No drift found for the command/flag names above; re-verify against the real binary on first deploy.

## Entity: Invocation Result

Normalized return shape from `ToolGateway.call_mcp_tool()`, matching the existing convention used by `execute_python`/`write_file` (`{"status": ..., ...}`) so `telegram_daemon.py`'s existing `tool_res.get("output", {})` access pattern keeps working unchanged:

| Field | Description |
|---|---|
| `status` | `"success"`, `"error"`, `"auth_required"`, or `"rate_limited"` — mapped from `gog`'s exit code (research.md Decision 9) |
| `output` | Parsed JSON from `gog`'s stdout on success (dict or list, service-dependent) |
| `error` | Human-readable message on failure — never a raw stack trace or raw stderr dump |
| `exit_code` | Raw `gog` exit code, for logging/debugging only |

## Entity: Mutation Confirmation State

Ephemeral, in-memory, per-conversation-turn state (not persisted) needed to implement "confirm before mutating" (research.md Decision 7): when Gemini calls a mutating function, `tool_gateway.py` does not execute it immediately — it returns a `status: "confirmation_required"` result with a human-readable summary of the pending action, which `query_gemini()`'s turn-2 synthesis surfaces to the user as a question. The actual execution happens only on the user's next affirmative reply. Exact mechanics (how the pending action is round-tripped to the next turn) are a task-breakdown-time design decision, not fixed here — flag for `/speckit.tasks`.

## Configuration (environment, not a data entity but load-bearing)

| Variable | Source | Purpose |
|---|---|---|
| `GOG_ACCOUNT` | Set in `docker/entrypoint.sh` from a Terraform-declared value | Default Google account for all `gog` invocations |
| `GOG_HOME` | `/mnt/disks/openclaw-data/gogcli` (persistent disk) | Where `gog` stores its encrypted token state |
| `GOG_KEYRING_BACKEND` | `file` | Forces the file backend over the unavailable platform keyring |
| `GOG_KEYRING_PASSWORD` | Fetched from GCP Secret Manager (`gog-keyring-password`) at container startup | Decrypts the token file; see research.md Decision 4 |
