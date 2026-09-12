# Tasks: CLI Chat Interface for OpenClaw Agent

**Input**: Design documents from `/specs/026-cli-chat-interface/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: `plan.md`'s Technical Context explicitly designates `scripts/test_cli_chat.sh` as this feature's testing strategy (matching the repo convention of `scripts/test_channel_adapters.sh` / `scripts/test_vector_memory.sh`), so test tasks ARE included below, grouped into the user story phase whose behavior they verify.

**Organization**: Tasks are grouped by user story (spec.md: US1 = Interactive Terminal Conversation, US2 = Access Limited to the Host Itself — both Priority P1) to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- File paths are absolute-relative to the repository root

## Path Conventions

Single flat `scripts/` project (no `src/`/`tests/` split — matches specs 015, 017, 020 and plan.md's Structure Decision). All paths are under `/home/napier/a/OpenClaw/scripts/` or `/home/napier/a/OpenClaw/docs/`.

---

## Phase 1: Setup

**Purpose**: Scaffold this feature's verification script so later phases only add scenarios to it, matching repo convention.

- [X] T001 Create `scripts/test_cli_chat.sh` skeleton (shebang, `set -eo pipefail`, section banner echoes, no assertions yet) modeled on `scripts/test_channel_adapters.sh`, so US1/US2/Polish phases append scenarios to an existing file rather than each creating it.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared infrastructure both US1 and US2 depend on. No user-story work should begin until this phase is complete.

**⚠️ CRITICAL**: This phase resolves Phase-1-planning open item #1 (shared Gemini helper extraction) and lays the persistence/adapter groundwork data-model.md and research.md specify.

- [X] T002 [P] Refactor `scripts/telegram_daemon.py`: generalize `query_gemini(prompt, session_id="default")` into a channel-agnostic shared helper that accepts an optional `history` parameter (a list of prior `{role, text}` turns to seed `contents` before the current prompt), while preserving its existing request/function-call/turn-2 tool-loop behavior byte-for-byte for Telegram's `process_update()` call site. This is the extraction research.md #6 and plan.md line 67 require so the CLI does not duplicate ~100 lines of tool-call/turn-2 logic — no new file is introduced (plan.md's Project Structure lists only `telegram_daemon.py` as modified for this refactor); the function stays in `telegram_daemon.py` as an importable, channel-agnostic entry point.
- [X] T003 [P] In `scripts/vector_memory.py`, add the additive `role` column to the `memories` table in `init_db()` (`role TEXT DEFAULT 'user'`) and extend `add_memory()` to accept and persist an optional `role="user"` parameter, per data-model.md's schema — existing rows/callers unaffected (backward compatible; `search_memory()` untouched).
- [X] T004 In `scripts/vector_memory.py`, add `get_recent(self, session_id="default", limit=20)` to `VectorMemoryEngine`: `SELECT ... WHERE session_id = ? ORDER BY created_at DESC LIMIT ?` re-reversed to chronological (oldest-first) order, per data-model.md — depends on T003 (same file, same table shape).
- [X] T005 [P] In `scripts/channel_gateway.py`, add `class CLIAdapter(ChannelAdapter)` with `channel_name="cli"`, overriding `is_authorized()` to always return `True` (SSH-boundary model, FR-009/FR-003 — no `allowed_user_ids_env` whitelist applies to this channel), per research.md #2/#4.

**Checkpoint**: Shared Gemini helper, persistence accessor, and adapter class all exist — US1 and US2 implementation can now begin.

---

## Phase 3: User Story 1 - Interactive Terminal Conversation (Priority: P1) 🎯 MVP

**Goal**: An authorized user can run `openclaw chat "<message>"` (one-shot) or `openclaw chat` (REPL) and converse with the agent, with context carried across turns and across separate invocations, and exit cleanly.

**Independent Test**: Run `openclaw chat "hello"` on a deployed host, confirm a printed response; then open `openclaw chat` REPL, send a follow-up referring to the prior message, confirm context-aware response; then exit via `/exit` and confirm no orphaned process.

### Implementation for User Story 1

- [X] T006 [US1] Add a `chat` subparser to `scripts/openclaw`'s `argparse` setup: optional positional `message` (one-shot when present) and a way to force REPL (`openclaw chat` with no message); `--help` text doubles as the single built-in help command required by SC-004.
- [X] T007 [US1] Add an input validator function in `scripts/openclaw` (e.g. `validate_chat_input(text)`) enforcing: valid UTF-8 decode, no NUL/binary control bytes, and a maximum length of **8,000 characters** (FR-010, research.md #5) — reject with a clear one-line stderr message before any network call.
- [X] T008 [US1] Implement the one-shot path of `cmd_chat()` in `scripts/openclaw`: validate input (T007) → instantiate `CLIAdapter` (T005) → `VectorMemoryEngine.get_recent(session_id="cli", limit=20)` (T004) for context → call the shared Gemini helper (T002) with `history=` that context → print the response to stdout → persist both the user turn and the agent turn via `add_memory(..., session_id="cli", role="user"/"agent")` (T003).
- [X] T009 [US1] Implement the REPL path of `cmd_chat()` in `scripts/openclaw`: a `while True` prompt loop reusing the same per-turn logic as T008; support exiting via `/exit` or `/quit` (typed command), Ctrl-D (`EOFError`), and Ctrl-C (`KeyboardInterrupt`) — all three terminate cleanly with no orphaned processes or corrupted session state (FR-004; concrete exit mechanisms per Phase-1-planning open item #2). No idle timeout is implemented (FR-004 explicitly prohibits one).
- [X] T010 [US1] Wrap the Gemini call in `cmd_chat()`'s one-shot and REPL paths with the existing timeout/try-except pattern (`urllib.request.urlopen(..., timeout=30)`), surfacing `"Agent backend unreachable: <reason>"` to the terminal (stderr) instead of hanging or crashing the REPL loop (FR-005).
- [X] T011 [US1] Add `[CLI ...]`-prefixed `print(..., flush=True)` audit lines around each CLI chat turn in `scripts/openclaw` (matching `telegram_daemon.py`'s `[DAEMON ...]` logging convention) plus an `OTelTracer` span tagged `channel=cli` (FR-006, research.md #8) — print-based logging is the mandatory parity baseline; OTel is an additive forward-looking improvement.
- [X] T012 [US1] Add scenarios to `scripts/test_cli_chat.sh`: one-shot round trip (send message, assert non-empty response and zero exit code), REPL multi-turn context awareness (two turns where the second refers to the first), and cross-invocation persistence (two separate `openclaw chat` process invocations share context, per FR-002/FR-007) — also assert a `"cli"`-session memory row is never returned when querying a different `session_id` (FR-008 channel-isolation spot-check).
- [X] T013 [US1] Add scenarios to `scripts/test_cli_chat.sh`: malformed/oversized input rejection (invalid UTF-8 bytes, a NUL byte, and a message > 8,000 characters, each expected to exit non-zero with a clear stderr message and make no network call) and the backend-unreachable error path (e.g. invalid `GEMINI_API_KEY` or unreachable endpoint) surfacing `"Agent backend unreachable"` rather than hanging (FR-005/FR-010).

**Checkpoint**: User Story 1 is fully functional and independently testable — `openclaw chat` works end-to-end for one-shot and REPL use.

---

## Phase 4: User Story 2 - Access Limited to the Host Itself (Priority: P1)

**Goal**: Confirm the CLI channel's sole authorization boundary is an authenticated SSH session on the host — no separate CLI credential, no network-reachable entry point — and that this is enforced through the same `CLIAdapter`/`ChannelAdapter` pathway the other channels define (not bypassed).

**Independent Test**: Confirm `CLIAdapter.is_authorized()` returns `True` for any `user_id` input (including none); confirm `openclaw chat` opens no listening socket; confirm the OS user is recorded only as an audit label, never as an access check.

### Implementation for User Story 2

- [X] T014 [US2] In `cmd_chat()` (`scripts/openclaw`), explicitly instantiate `CLIAdapter` and route each turn through `process_message()`/`is_authorized()` (T005) as part of the live turn flow — even though the result is always authorized, this makes CLI the first channel to genuinely exercise the `ChannelAdapter` abstraction end-to-end rather than defining it unused (research.md #2 finding; do not hand-roll a parallel ad hoc check the way `telegram_daemon.py` does today).
- [X] T015 [US2] In `scripts/openclaw`, tag the `[CLI ...]` audit lines and OTel span attributes (T011) with the current OS user (e.g. via `getpass.getuser()`, with a safe fallback) strictly as a label for FR-006 audit purposes — add an explicit code comment noting this value is never used in any authorization decision (FR-009).
- [X] T016 [P] [US2] Add a static/self-check scenario to `scripts/test_cli_chat.sh` (e.g. `grep`-based assertion, or a `--help`/process-inspection check) confirming the `chat` subcommand code path opens no listening socket and registers no network server, supporting FR-003's "not reachable as a network client" guarantee.
- [X] T017 [US2] Add scenarios to `scripts/test_cli_chat.sh`: `CLIAdapter.is_authorized()` returns `True` for an arbitrary/absent `user_id` (unlike `TelegramAdapter`/`DiscordAdapter`), and confirm no `CLI_ALLOWED_USER_IDS`-style env var is read or honored by the `cli` channel (FR-009 — no separate CLI-specific credential is introduced).

**Checkpoint**: Both User Story 1 and User Story 2 are independently functional — `openclaw chat` works and its only gate is SSH-level host access.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Documentation sync and full regression validation across the additive changes.

- [X] T018 [P] Update `docs/Quickstart.md`: add a new operator-facing section (after "## 7. Operational Workflow", before "## Google Workspace Integration") documenting `openclaw chat` one-shot and REPL usage, the three exit mechanisms (`/exit`/`/quit`, Ctrl-D, Ctrl-C), the SSH-boundary authorization model (no separate credential), and a pointer to `specs/026-cli-chat-interface/quickstart.md` for full detail — this satisfies Constitution Principle 7 (Synchronized Manual Setup Docs & Onboarding) per Phase-1-planning open item #3, since this is a new user-facing capability.
- [X] T019 [P] Update the module docstring at the top of `scripts/openclaw` (lines 2-10) to list `chat` alongside `channels`, `gateway`, `models`, `doctor`, `whitelist` in the usage summary.
- [X] T020 Run `scripts/test_cli_chat.sh` end-to-end plus a regression pass of `scripts/test_channel_adapters.sh` and `scripts/test_vector_memory.sh` to confirm the additive `role` column, `get_recent()`, `CLIAdapter`, and `telegram_daemon.py` refactor introduced no breakage to existing Telegram/Discord/vector-memory behavior.
- [X] T021 Manually execute every step in `specs/026-cli-chat-interface/quickstart.md` (one-shot, REPL, `--help`, cross-invocation continuity) on a representative host/shell to confirm SC-001 through SC-004 are met.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS both user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational completion. No dependency on US2.
- **User Story 2 (Phase 4)**: Depends on Foundational completion. Structurally builds on US1's `cmd_chat()` skeleton (T008/T009) since it wires `CLIAdapter.is_authorized()` into the same turn flow — implement after US1's core loop exists, even though the two stories are conceptually independent and both P1.
- **Polish (Phase 5)**: Depends on US1 and US2 both being complete.

### Within Each Phase

- Foundational: T002, T003, T005 touch different files and have no dependency on each other ([P]); T004 depends on T003 (same file, `vector_memory.py`).
- US1: T006 → T007 → T008 → T009 → T010 → T011 are sequential (all edit `scripts/openclaw`); T012/T013 (test script) depend on T006-T011 being complete.
- US2: T014 → T015 (both edit `scripts/openclaw`, depend on US1's `cmd_chat()`); T016 is independent of T014/T015 ([P]); T017 depends on T014.
- Polish: T018/T019 are independent of each other ([P]); T020 depends on all implementation tasks (T002-T017); T021 depends on T020.

### Parallel Opportunities

- T002, T003, T005 (Foundational) can run in parallel — different files, no shared dependency.
- T016 (US2) can run in parallel with T014/T015 (US2) — it's a static/independent check, not touching `scripts/openclaw`.
- T018, T019 (Polish) can run in parallel — different files.

---

## Parallel Example: Foundational Phase

```bash
# Launch these three together once Setup (T001) is done:
Task: "Refactor scripts/telegram_daemon.py to extract shared Gemini helper (T002)"
Task: "Add role column + add_memory(role=) to scripts/vector_memory.py (T003)"
Task: "Add CLIAdapter(ChannelAdapter) to scripts/channel_gateway.py (T005)"
# T004 (get_recent()) follows T003 since both touch vector_memory.py.
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001).
2. Complete Phase 2: Foundational (T002-T005) — CRITICAL, blocks both stories.
3. Complete Phase 3: User Story 1 (T006-T013).
4. **STOP and VALIDATE**: Run `scripts/test_cli_chat.sh`'s US1 scenarios; manually confirm one-shot + REPL + cross-invocation persistence.
5. This is already a demoable MVP: an operator can chat with the agent from the CLI — though note US2's explicit `CLIAdapter` wiring (T014) is deferred, so ship US1-only builds internally only, not as the final release, since FR-009's "genuinely exercise the adapter" intent is part of this spec's scope.

### Incremental Delivery

1. Setup + Foundational → foundation ready.
2. Add US1 → validate independently → MVP demo.
3. Add US2 → validate independently (SSH-boundary confirmed, adapter genuinely wired) → feature-complete.
4. Polish (docs sync + full regression) → ready to ship.

---

## Notes

- Both user stories are Priority P1 per spec.md — US2 is sequenced after US1 here only because it wires into the `cmd_chat()` code T008/T009 create, not because it is lower priority; do not skip US2 before release.
- [P] tasks = different files, no dependencies.
- [Story] label maps task to specific user story for traceability.
- No new top-level files are introduced except `scripts/test_cli_chat.sh` (per plan.md's Structure Decision) — resist creating a new `scripts/agent_query.py` or similar for the T002 extraction; keep the shared helper inside `telegram_daemon.py` as plan.md specifies.
- Commit after each task or logical group; stop at either checkpoint to validate a story independently.
- Concrete values locked in for this feature (not to be re-litigated during implementation): input size limit = 8,000 characters; REPL exit = `/exit`, Ctrl-D, Ctrl-C; `docs/Quickstart.md` is the operator-facing doc to sync (Constitution Principle 7).
