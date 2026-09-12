# Tasks: Google Workspace Integration (ClawHub + gog)

**Input**: Design documents from `/specs/025-google-workspace-clawhub/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md (all present)

**Tests**: Included. `scripts/test_gworkspace_clawhub.sh` is explicitly called out in spec.md's Success Criteria and plan.md's Project Structure, and quickstart.md's "Test scenario" section enumerates the minimum assertions it must contain — this is a requested deliverable, not optional scaffolding.

**Organization**: Tasks are grouped by user story (US1 Calendar, US2 Gmail, US3 Tasks — spec.md's three prioritized stories) to enable independent implementation and testing of each. `search_drive_files` is part of the shared tool-mapping table (data-model.md) but is not one of spec.md's three prioritized stories, so its dispatch is implemented generically in the Foundational phase rather than getting its own story phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 (Calendar, P1), US2 (Gmail, P2), US3 (Tasks, P3)
- File paths are exact and relative to the repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify the live `gog` tool surface before anything hardcodes a version tag or flag name against it, then wire the Docker/Terraform/docs plumbing that makes an authenticated `gog` binary available to the daemon at runtime.

- [X] T001 Verify the pinned `gog` release tag and the exact flag names used throughout data-model.md's mapping table by running `gog schema --json` against a locally installed `gog` binary (or, if unavailable, checking `https://github.com/openclaw/gogcli/releases` directly) — confirm `v0.40.0` (or the current latest tag) still exists and that `gog calendar events`, `gog calendar create`, `gog gmail search`, `gog gmail send`, `gog drive search`, `gog tasks list`, `gog tasks add`, `gog tasks done` accept the flags research.md Decision 8 and data-model.md assume (`--from`/`--to`, `--summary`, `--max`, `--json`, `--no-input`, `--body-file`, etc.). Update `specs/025-google-workspace-clawhub/research.md` (Decision 8) and `specs/025-google-workspace-clawhub/data-model.md` (the mapping table) in place if anything drifted from this snapshot. This gates T002 and T008 — do not hardcode a version or flag into Dockerfile or tool_gateway.py before this task completes.
- [X] T002 [P] Pin and install the verified `gog` binary in `docker/Dockerfile`: download `gogcli_<version>_linux_amd64.tar.gz` plus `checksums.txt` from the verified GitHub release (T001), verify the checksum, and install the binary into the image alongside the existing `apt-get install` layer — no Homebrew, no `go install`. Depends on T001.
- [X] T003 [P] In `docker/entrypoint.sh`, export `GOG_KEYRING_BACKEND=file`, `GOG_HOME=/mnt/disks/openclaw-data/gogcli`, and `GOG_ACCOUNT` (from a plain env var set by Terraform, not a secret), and fetch `GOG_KEYRING_PASSWORD` via the existing `fetch_secret` helper (mirroring the `GEMINI_API_KEY` block at lines 37-40) reading the new `gog-keyring-password` secret. Also invoke `gog auth doctor --check --no-input` after the env is set, logging a warning (not crashing the daemon) if it fails, per research.md Decision 5.
- [X] T004 [P] Add a `gog-keyring-password` entry to the `locals.secrets` map in `terraform/modules/secrets/main.tf` (alongside `gemini-api-key`, `telegram-bot-token`, etc.), reusing the existing `google_secret_manager_secret`/`google_secret_manager_secret_iam_member` `for_each` pattern — no new resource blocks needed.
- [X] T005 [P] Rewrite the "Google Workspace Integration" section of `docs/Quickstart.md` (currently lines ~181-206, describing a placeholder `antigravity skill install clawhub/gog` / bare `gog auth login` flow) to match the real one-time onboarding steps in `specs/025-google-workspace-clawhub/quickstart.md`: `openssl rand -base64 32 | gcloud secrets create gog-keyring-password ...`, `GOG_KEYRING_BACKEND=file GOG_KEYRING_PASSWORD=... gog auth credentials <client_secret.json>`, `gog auth add <email> --services gmail,calendar,drive,tasks,contacts`, `gog auth doctor --check --no-input`, and setting `GOG_ACCOUNT`.
- [X] T006 [P] Update the Google Workspace callouts in `skills/openclaw.bootstrap/SKILL.md` (lines ~29 and ~39, which currently just say "run `gog auth login`") to walk through the same real commands as T005 and mention the new `gog-keyring-password` secret the bootstrap flow must ensure exists.

**Checkpoint**: `gog`'s real command surface is confirmed, the binary is installable and configurable end-to-end in the container, and onboarding docs describe the real flow.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement the two currently-nonexistent `ToolGateway` methods (research.md Decision 6) that every user story depends on. Nothing in Phase 3+ works until this phase is done — this is the fix, not an add-on.

**⚠️ CRITICAL**: No user story can be verified until this phase is complete.

- [X] T007 Implement `ToolGateway.list_mcp_tools()` in `scripts/tool_gateway.py`, returning the 8 Gemini function declarations from data-model.md's "Tool Declaration" table (`calendar_get_events`, `calendar_create_event`, `list_messages`, `send_message`, `search_drive_files`, `tasks_list`, `tasks_add`, `tasks_complete`) each with `name`, `description`, `inputSchema`, and an internal (non-Gemini-facing) `readonly` flag — replacing the method `scripts/model_router.py`'s `get_tools()` currently calls and gets a silent `AttributeError` from.
- [X] T008 Implement the `fn_name` → `gog` subprocess invocation dispatch table in `scripts/tool_gateway.py` per data-model.md's mapping (verified against T001): `calendar_get_events`→`gog calendar events primary --from ... --to ... --json --no-input`, `calendar_create_event`→`gog calendar create primary --summary ... --from ... --to ...`, `list_messages`→`gog gmail search '<query>' --max <max>`, `send_message`→`gog gmail send --to ... --subject ... --body-file <tmpfile>`, `search_drive_files`→`gog drive search '<query>' --max <max>`, `tasks_list`→`gog tasks list`, `tasks_add`→`gog tasks add <tasklistId> --title ... [--due ...]`, `tasks_complete`→`gog tasks done <tasklistId> <taskId>` — all with `--json --no-input`, inheriting `GOG_ACCOUNT`/`GOG_HOME`/`GOG_KEYRING_*` from the process environment (no per-call `--account` flag). Depends on T007, T001.
- [X] T009 Implement exit-code-to-status mapping in `scripts/tool_gateway.py` per research.md Decision 9: `0`→`status: "success"` with parsed stdout JSON as `output`; `2`→`"error"` ("invalid arguments"); `4`→`"auth_required"` (clear re-authenticate message, never a stack trace); `5`→`"error"` ("not found"); `6`→`"error"` ("permission denied"); `7`/`8`→one bounded retry, then `"error"` ("transient failure, please retry") if still failing. Always include the raw `exit_code` for logging; never surface raw stderr. Depends on T008.
- [X] T010 Implement the mutation-confirmation mechanism (data-model.md's "Mutation Confirmation State" entity) across `scripts/tool_gateway.py` and `scripts/telegram_daemon.py`: for the 4 mutating functions (`calendar_create_event`, `send_message`, `tasks_add`, `tasks_complete`), `call_mcp_tool()` does not execute on first call — it returns `{"status": "confirmation_required", "summary": "<human-readable description of the pending action>"}`. Round-trip design: keep an in-memory `PENDING_CONFIRMATIONS` dict in `telegram_daemon.py` keyed by `chat_id`, storing `{fn_name, args, expires_at}` (a short TTL, e.g. 5 minutes) when `query_gemini()`'s functionCall handling sees `confirmation_required`; on the *next* incoming message from that `chat_id`, `process_update()` checks for a live pending entry first and interprets an affirmative reply (simple case-insensitive yes/confirm/go-ahead vs. no/cancel check) as "execute the stored `fn_name`/`args` for real" (calling `call_mcp_tool` again with an internal `confirmed=True` bypass) before falling through to the normal `query_gemini(text)` path. Depends on T007-T009.
- [X] T011 Implement `ToolGateway.call_mcp_tool(fn_name, args_json)` in `scripts/tool_gateway.py` as the single public entry point wiring together T008's dispatch, T009's exit-code mapping, and T010's confirmation gate — replacing the currently-nonexistent method that `scripts/telegram_daemon.py:143` (turn-2 functionCall handling) calls. Depends on T010.
- [X] T012 Remove the hardcoded `/calendar`, `/gmail`, `/drive` slash-command branches (`text.startswith(...)` in `process_update()`, `scripts/telegram_daemon.py` lines ~225-270) and their mention in `/start`'s help text (line ~220) — explicit user requirement is natural-language-only interaction via Gemini function-calling ("what's on my calendar this week", not `/calendar`); these branches bypass Gemini entirely and duplicate the NL path T011 just made real. Depends on T011 (so the NL path is confirmed working before its bypass is deleted).
- [X] T013 Add `list_mcp_tools`/`call_mcp_tool` entries to `scripts/tool_gateway.py`'s `__main__` argparse `--tool` choices (lines ~78-92), mirroring the existing `execute_python`/`write_file`/`read_file`/`get_system_status` CLI pattern, for manual debugging. Depends on T011.

**Checkpoint**: `ToolGateway` is real; Gemini function-calling for all three user stories is wired end-to-end; the slash-command bypass is gone; `/status`'s "Workspace MCP Integration: Active" claim (line 223, addressed in Polish) is the last stale artifact.

---

## Phase 3: User Story 1 - Google Calendar Access via Natural Language (Priority: P1) 🎯 MVP

**Goal**: An authorized Telegram user can ask "What's on my calendar today?" and get real events back, and "Schedule a meeting with Sarah at 2pm tomorrow" triggers a confirm-then-create flow.

**Independent Test**: Send both phrasings above to the bot; the read query returns actual calendar data (or "no events" if none), and the create request is echoed back for confirmation and only creates the event after an affirmative reply.

### Tests for User Story 1

- [X] T014 [P] [US1] Create `scripts/test_gworkspace_clawhub.sh` (new file, following the existing `test_channel_adapters.sh`/`test_vector_memory.sh` convention: `set -eo pipefail`, `[TEST]`/`[TEST PASS]`/`[TEST SUCCESS]` echo markers) with calendar assertions: `ToolGateway.call_mcp_tool("calendar_get_events", ...)` returns `status: "success"` with parsed JSON (against a live-or-stubbed `gog` call), and `call_mcp_tool("calendar_create_event", ...)` returns `status: "confirmation_required"` on its first invocation rather than creating anything.

### Implementation for User Story 1

- [X] T015 [US1] Manually validate the full path via a deployed (or locally-run) Telegram bot per quickstart.md's Usage section: "What's on my calendar today?" returns real agenda text synthesized by Gemini's turn-2 response, and "Schedule a meeting with Sarah at 2pm tomorrow" pauses for confirmation, then creates the event only after replying affirmatively. Depends on Phase 2 completion and T014.

**Checkpoint**: User Story 1 fully functional and independently testable — this is the MVP.

---

## Phase 4: User Story 2 - Gmail Access via Natural Language (Priority: P2)

**Goal**: An authorized Telegram user can ask "Do I have any unread emails about the Q3 budget?" and get real Gmail search results; a hypothetical "send an email to X" request pauses for confirmation before sending.

**Independent Test**: Send the Gmail query above; verify real (or stubbed) search results come back through Gemini's synthesis, and that a send-mail request is not sent until confirmed.

### Tests for User Story 2

- [X] T016 [US2] Add Gmail assertions to `scripts/test_gworkspace_clawhub.sh`: `call_mcp_tool("list_messages", ...)` returns `status: "success"`; `call_mcp_tool("send_message", ...)` returns `status: "confirmation_required"` on first call and only executes on a simulated confirmed second call; a simulated `gog` exit code `4` maps to `status: "auth_required"` with a clear message (not a raw error). Depends on T014 (same file, appended after).

### Implementation for User Story 2

- [X] T017 [US2] Manually validate "Do I have unread email about the Q3 budget?" via the deployed Telegram bot returns real Gmail search results synthesized by Gemini. Depends on Phase 2 completion and T016.

**Checkpoint**: User Stories 1 and 2 both independently functional.

---

## Phase 5: User Story 3 - Google Tasks Management (Priority: P3)

**Goal**: An authorized Telegram user can say "Add 'review PR #42' to my task list" and, after confirming, have a real Google Task created; marking a task done follows the same confirm-then-execute pattern.

**Independent Test**: Send the task-creation phrase above; verify it's echoed back for confirmation and only creates the task after an affirmative reply; verify `tasks_list` and `tasks_complete` similarly round-trip correctly.

### Tests for User Story 3

- [X] T018 [US3] Add Tasks assertions to `scripts/test_gworkspace_clawhub.sh`: `call_mcp_tool("tasks_list", ...)` returns `status: "success"`; `call_mcp_tool("tasks_add", ...)` and `call_mcp_tool("tasks_complete", ...)` both return `status: "confirmation_required"` on first call and execute only once confirmed. Depends on T016 (same file, appended after).

### Implementation for User Story 3

- [X] T019 [US3] Manually validate "Add 'review PR #42' to my task list" via the deployed Telegram bot: confirmation prompt shown, confirming creates the real task, and a follow-up "mark it done" exercises the `tasks_complete` confirm-then-execute path. Depends on Phase 2 completion and T018.

**Checkpoint**: All three user stories independently functional — full feature scope delivered.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Close out the remaining stale artifacts and validate the whole feature end-to-end.

- [X] T020 Add a `gog auth doctor --check --no-input` exit-`0` assertion to `scripts/test_gworkspace_clawhub.sh` (quickstart.md's first Test scenario bullet) and `chmod +x` the script per the repo's `test_*.sh` convention. Depends on T018.
- [X] T021 [P] Update `/status`'s reply text in `scripts/telegram_daemon.py` (line ~223, currently "Workspace MCP Integration: Active") to accurately describe the `gog`-backed integration rather than the never-real MCP claim.
- [X] T022 Run `scripts/test_gworkspace_clawhub.sh` end-to-end and walk through quickstart.md's full manual Usage section against a real deployment; fix any regressions found. Depends on T020, T015, T017, T019.
- [X] T023 [P] Re-check `docs/Quickstart.md` and `skills/openclaw.bootstrap/SKILL.md` (updated in T005/T006) against whatever `gog` version/flags T001 and implementation actually landed on, and correct any drift discovered along the way.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 first (version/flag verification) gates T002 and T008; T003-T006 can proceed in parallel once T001 lands.
- **Foundational (Phase 2)**: Depends on Setup (specifically T001) — BLOCKS all user stories. T007→T008→T009→T010→T011 is a strict same-file sequential chain in `scripts/tool_gateway.py`; T012 (telegram_daemon.py cleanup) and T013 (CLI wiring) depend on T011.
- **User Stories (Phase 3-5)**: All depend on Foundational (Phase 2) completion. Each story's test task appends to the same `scripts/test_gworkspace_clawhub.sh` file created in T014, so US2's test task depends on US1's, and US3's on US2's (sequential appends, not parallel, despite each being the "first parallel task" within its own story).
- **Polish (Phase 6)**: Depends on all three user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Phase 2 — no dependency on US2/US3.
- **User Story 2 (P2)**: Can start after Phase 2 — independently testable; its test task is appended after US1's test task in the shared test script (file-ordering dependency only, not a functional one).
- **User Story 3 (P3)**: Can start after Phase 2 — independently testable; same file-ordering note as US2.

### Parallel Opportunities

- T002, T003, T004, T005, T006 (Setup, once T001 lands) — all different files.
- T021 and T023 (Polish) can run in parallel with each other and with T022.
- Within Phase 2, T007-T013 are a same-file sequential chain, not parallelizable.

---

## Parallel Example: Setup Phase

```bash
# After T001 (gog version/flag verification) completes, launch together:
Task: "Pin and install gog binary in docker/Dockerfile"
Task: "Export GOG_* env vars and fetch gog-keyring-password in docker/entrypoint.sh"
Task: "Add gog-keyring-password secret to terraform/modules/secrets/main.tf"
Task: "Rewrite Google Workspace section of docs/Quickstart.md"
Task: "Update Google Workspace callouts in skills/openclaw.bootstrap/SKILL.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (gog version verified, Docker/Terraform/docs plumbing in place).
2. Complete Phase 2: Foundational (`ToolGateway` real methods, confirm-before-mutate, slash-command removal) — CRITICAL, blocks everything.
3. Complete Phase 3: User Story 1 (Calendar).
4. **STOP and VALIDATE**: Confirm Calendar NL queries and confirm-then-create both work end-to-end via Telegram.
5. Deploy/demo if ready — this alone is a usable MVP.

### Incremental Delivery

1. Setup + Foundational → integration substrate ready (Gemini actually gets tools; nothing crashes on `/calendar` anymore because it no longer exists).
2. Add US1 (Calendar) → validate independently → MVP.
3. Add US2 (Gmail) → validate independently.
4. Add US3 (Tasks) → validate independently.
5. Polish → close out stale `/status` text, re-verify docs against whatever `gog` version T001 confirmed, run the full test script.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks.
- `search_drive_files` has no dedicated user-story phase (not one of spec.md's three prioritized stories) — its dispatch is covered generically by T007/T008/T009 in the Foundational phase.
- T001 (gog version/flag verification) and T012 (slash-command removal) are both explicit, separately-called-out requirements from the orchestrator brief — do not fold either into a larger task or skip them.
- Commit after each task or logical group; stop at any checkpoint to validate a story independently.
