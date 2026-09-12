# Research: CLI Chat Interface for OpenClaw Agent

## Technical Decisions

### 1. Command surface: extend the existing `openclaw` unified CLI
- **Decision**: Add a `chat` subcommand to the existing `scripts/openclaw` dispatcher (which already implements `channels`, `gateway`, `models`, `doctor` via `argparse` subparsers), rather than shipping a new standalone entry-point script.
  - One-shot: `openclaw chat "<message>"` (or `openclaw chat --message "..."`) — sends one message, prints the response, exits.
  - Interactive REPL: `openclaw chat` with no message argument (or `openclaw chat --interactive`) — opens a `while True` prompt loop until the user types `/exit` (or `/quit`) or sends Ctrl-D/Ctrl-C (SIGINT/EOF), per FR-004.
  - `openclaw chat --help` doubles as the "single built-in help command" required by SC-004.
- **Rationale**: `scripts/openclaw` is already the established single entry point operators use on the host; Principle 8 (Prefer Native Framework Capabilities & Maximum Component Reuse) directs new capabilities to extend existing abstractions rather than create parallel ones. Adding a subcommand keeps one binary, one help system, one place operators look.
- **Alternatives considered**: A brand-new `scripts/cli_chat_daemon.py` script — rejected as unnecessary duplication of the dispatcher `scripts/openclaw` already provides.

### 2. Channel adapter reuse
- **Decision**: Add a `CLIAdapter(ChannelAdapter)` class to `scripts/channel_gateway.py`, following the same shape as `TelegramAdapter`/`DiscordAdapter`. Because the CLI's authorization boundary is "already has an authenticated SSH session" (FR-009) rather than a per-platform user-ID whitelist, `CLIAdapter.is_authorized()` is overridden to always return `True` — the whitelist mechanism the base class was built for (`allowed_user_ids_env`) does not apply to a channel with no separate credential; the process's real OS user is used only as a `user_id` label for auditing (FR-006), never as an authorization check.
- **Important finding (documented so implementation and review don't assume otherwise)**: `scripts/telegram_daemon.py` — the only channel with a live production message loop today — does **not** actually instantiate `TelegramAdapter`/`ChannelAdapter` from `scripts/channel_gateway.py`. It re-implements its own inline whitelist check (`get_allowed_user_ids()` / manual `if allowed_ids and user_id not in allowed_ids`) directly in `process_update()`. `channel_gateway.py` is currently exercised only by its own CLI entrypoint and `scripts/test_channel_adapters.sh`; it is not wired into any live chat flow. This means the CLI feature, by actually instantiating and using `CLIAdapter` from within its message-handling path, will be the *first* channel to genuinely exercise the `ChannelAdapter` abstraction end-to-end rather than merely maintaining a parallel unused implementation of it. This is called out so a reviewer doesn't reject the plan on the assumption Telegram already proves the pattern in production — it doesn't yet.
- **Rationale for reusing the pattern anyway**: Principle 8 requires reuse of established abstractions when they can achieve the desired outcome, and `ChannelAdapter`'s shape (per-channel authorization + message normalization) fits the CLI channel's needs even though its authorization predicate differs from the whitelist model. Diverging from the pattern here would compound the existing drift (an adapter class two channels define but don't use) rather than correct it.
- **Alternatives considered**: Skip `ChannelAdapter` entirely and hand-roll CLI message handling the way `telegram_daemon.py` does — rejected because it would be the second channel to bypass the shared abstraction, making the drift the norm instead of the exception; the task's explicit direction is to reuse the pattern unless there's a concrete blocker, and none was found (the only wrinkle — no whitelist — is handled by an authorization override, not by abandoning the base class).

### 3. Conversation persistence: reuse the vector memory engine
- **Decision**: Persist CLI conversation turns via `scripts/vector_memory.py`'s `VectorMemoryEngine`, using a fixed `session_id` scoped to the CLI channel (e.g. `"cli:<hostname>"` or simply `"cli"` for the single-operator-host assumption in the spec) so every invocation — REPL or one-shot — reads and writes the same row set, satisfying FR-002/FR-007's "one continuing thread per host" requirement. Each turn (`user` message and `agent` response) is written via `add_memory()`, tagged with a `role` field.
- **Important finding**: `VectorMemoryEngine` is a **semantic similarity store**, not an ordered transcript store — `search_memory()` returns the top-k rows by cosine similarity to a query, not the chronological last-N turns, and nothing in the codebase today calls it from a live chat path (`telegram_daemon.py`'s `query_gemini()` sends only the current prompt with no history injection at all — Telegram currently has zero persisted multi-turn context, despite FR-002-equivalent expectations for Telegram-style channels). To satisfy "context from earlier turns" (SC-002) reliably for a linear back-and-forth conversation (not just topically-similar recall), the CLI integration needs recency-ordered retrieval, not just similarity search.
- **Resolution**: Use the `memories` table's existing `created_at` column and `session_id` filter to fetch the most recent N turns in chronological order (a straightforward `SELECT ... WHERE session_id = ? ORDER BY created_at DESC LIMIT N`) for inclusion in the prompt sent to `model_router`/Gemini, in addition to (optionally) semantic search for older, topically-relevant turns beyond that recency window. This requires a small additive method on `VectorMemoryEngine` (e.g. `get_recent(session_id, limit)`) — extending the existing engine, not replacing it or standing up new storage.
- **Rationale**: Principle 4 (Decoupled State & Data Persistence) already designates SQLite-backed engines like `vector_memory.py` on the persistent disk as the pattern for conversation memory; Principle 8 directs reuse over new infrastructure. The gap found (similarity-only retrieval) is a small, additive extension, not a fundamental mismatch — it does not justify building a parallel persistence layer.
- **Alternatives considered**: A new flat-file/JSON transcript log per host — rejected as duplicate infrastructure for a need `vector_memory.py`'s schema already covers with one added accessor. Using only `search_memory()` as-is — rejected because similarity ranking can surface an old, topically-similar turn ahead of the immediately preceding turn, which would violate the "refers back to something said earlier in the same session" acceptance scenario (User Story 1, Scenario 2) for the common case of a direct follow-up.

### 4. Authorization: SSH boundary, no new credential
- **Decision**: No code-level authentication check is added for CLI access beyond OS-level SSH login — `CLIAdapter.is_authorized()` always returns `True` (see #2). `scripts/rbac_gateway.py` (multi-tenant role/permission model) is **not** invoked for the base "can this person chat at all" gate, because FR-009 explicitly states SSH session is the sole boundary and no per-person allow-list is introduced.
- **Rationale**: FR-003/FR-009 are unambiguous; layering RBAC role checks on top would reintroduce the "separate CLI-specific credential" the spec explicitly rules out. `rbac_gateway.py` remains available for future finer-grained action permissions but is out of scope here.
- **Alternatives considered**: Requiring an RBAC role lookup per CLI user (as Telegram-adjacent RBAC spec 020 does for its own scope) — rejected as contradicting FR-009 directly.

### 5. Input validation
- **Decision**: Validate at the CLI entry point before any network/model call: reject input that (a) fails UTF-8 decoding, (b) contains a NUL byte or other non-text control bytes indicative of binary data, or (c) exceeds a defined maximum message length (proposed: 8,000 characters, matching a generous single-turn chat message ceiling well under typical model context limits). Rejections print a clear one-line error to stderr and exit non-zero (one-shot) or re-prompt without crashing the REPL (interactive), satisfying FR-010 and the "never hang silently" philosophy of FR-005.
- **Rationale**: Straightforward, no new dependency; matches the "reject up front with a clear error" resolution already baked into the spec's clarifications.
- **Alternatives considered**: Deferring validation to the model backend and surfacing whatever error it returns — rejected because a hung or malformed request could stall indefinitely (violates FR-005), and backend error messages are not guaranteed to be human-readable.

### 6. Model routing / backend call
- **Decision**: Reuse `scripts/model_router.py`'s `ModelRouter` exactly as `telegram_daemon.py` does today (`get_model()`, `get_tools()`), and reuse the same Gemini `generateContent` request/function-calling turn-2 pattern from `query_gemini()` in `telegram_daemon.py`, factored so both Telegram and CLI call a shared function rather than duplicating the ~100-line request/tool-call/turn-2 logic inline in two places.
- **Rationale**: Principle 8 reuse; also reduces the risk of the two channels' Gemini-calling logic drifting apart (already a lesson learned from the `ChannelAdapter`/`vector_memory` drift noted above).
- **Alternatives considered**: Copy-pasting `query_gemini()` into the CLI code path — rejected as exactly the kind of duplication Principle 8 prohibits; flagged as a light refactor (extract shared helper, e.g. into a small `scripts/agent_query.py` or as a function `telegram_daemon.py` exports) rather than a new subsystem.

### 7. Error handling for backend unavailability
- **Decision**: Wrap the model call with the same `try/except` + timeout pattern already used in `telegram_daemon.py` (`urllib.request.urlopen(..., timeout=30)`), surfacing a clear "Agent backend unreachable: <reason>" message to the terminal (FR-005) instead of Telegram's send-and-forget error logging.
- **Rationale**: Matches existing timeout/error conventions; no new pattern needed.

### 8. Audit/observability parity (FR-006)
- **Decision**: Use `scripts/otel_tracing.py`'s `OTelTracer` for CLI chat interactions, tagging spans with `channel=cli`, plus `print(..., flush=True)` status/audit lines matching `telegram_daemon.py`'s existing `[DAEMON ...]`-style log conventions (adapted to a `[CLI ...]` prefix) so CLI interactions get audit visibility comparable to Telegram's.
- **Important finding**: Like `channel_gateway.py` and `vector_memory.py`, `otel_tracing.py` is **not currently called from `telegram_daemon.py`'s live message loop** — `process_update()`/`query_gemini()` only use `print(..., flush=True)` logging, no `OTelTracer` spans. So "the same level of audit/observability detail already applied to other channels" (FR-006) in practice today means the `print`-based logging pattern, not OTel spans. Given this, the CLI plan adopts the `print`-based logging Telegram genuinely uses as the FR-006 parity baseline (mandatory), and additionally wires in `OTelTracer` as a forward-looking improvement consistent with Principle 8 reuse — since the module exists specifically for this purpose and costs nothing extra to call from a brand-new code path. This should not block the plan; it is called out so reviewers don't expect the CLI to match an OTel-based trail that Telegram doesn't actually produce today.
- **Rationale**: Principle 8 reuse; keeps a single observability pipeline available across channels even though only CLI exercises it initially.
- **Alternatives considered**: A separate CLI-only log file — rejected as a parallel, inconsistent audit trail.

## Summary of Reuse vs. New Code

| Concern | Reused as-is | Reused with small extension | New |
|---|---|---|---|
| Command entry point | `scripts/openclaw` dispatcher | add `chat` subparser | — |
| Channel abstraction | `ChannelAdapter` base class | add `CLIAdapter` subclass (override `is_authorized`) | — |
| Conversation persistence | `VectorMemoryEngine` SQLite schema/`add_memory` | add `get_recent()` chronological accessor | — |
| Model routing | `ModelRouter` | — | — |
| Agent/tool-call request logic | — | extract shared helper from `telegram_daemon.query_gemini()` | — |
| Authorization | SSH (OS-level, outside app code) | — | — |
| Input validation | — | — | new validator function (UTF-8/size/binary checks) |
| Observability | `otel_tracing.py` | tag `channel=cli` | — |

No new standalone infrastructure (no new database, no new daemon process, no new auth system) is introduced. All identified gaps are additive extensions to existing modules.
