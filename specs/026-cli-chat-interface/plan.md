# Implementation Plan: CLI Chat Interface for OpenClaw Agent

**Branch**: `026-cli-chat-interface` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/026-cli-chat-interface/spec.md`

## Summary

Add a `chat` subcommand to the existing `scripts/openclaw` unified CLI so an SSH-authenticated operator can converse with the OpenClaw agent directly from the terminal, in both a persistent interactive REPL and a one-shot single-message form, both reading/writing one continuing conversation thread per host. The technical approach is deliberately additive: a new `CLIAdapter(ChannelAdapter)` in `scripts/channel_gateway.py` follows the same abstraction `TelegramAdapter`/`DiscordAdapter` already define (Spec 017), and conversation persistence reuses the existing `VectorMemoryEngine` SQLite store in `scripts/vector_memory.py` (Spec 015) with one additive `role` column and one additive `get_recent()` accessor for chronological (not just similarity-ranked) context retrieval. No new database, daemon, or authentication system is introduced — SSH login on the host is the entire authorization boundary (FR-009), enforced outside the application by host `sshd`/OS access control, not by new application code.

Research surfaced that `ChannelAdapter` and `VectorMemoryEngine` are not currently exercised by Telegram's live message loop (`scripts/telegram_daemon.py` re-implements its own whitelist check and has no persisted conversation history at all today) — see `research.md` for the full finding. The plan still follows the reuse directive: this feature becomes the first to genuinely wire these existing abstractions into a live chat path, which corrects the drift rather than compounding it.

## Technical Context

**Language/Version**: Python 3 (matches existing `scripts/*.py` — no version pin found repo-wide beyond `#!/usr/bin/env python3`; follows existing convention)
**Primary Dependencies**: Standard library only (`argparse`, `sqlite3` via `vector_memory.py`, `urllib.request` via the shared Gemini-call helper) — no new third-party dependency introduced, consistent with existing `scripts/*.py` modules.
**Storage**: SQLite, reusing `scripts/vector_memory.py`'s `memories` table on the persistent disk (`VECTOR_DB_PATH` env var, defaulting per Spec 015 to a path under `/mnt/disks/openclaw-data/` in production per Principle 4). No new storage engine.
**Testing**: Bash-driven verification scripts matching repo convention (`scripts/test_cli_chat.sh`, modeled on `scripts/test_channel_adapters.sh` / `scripts/test_vector_memory.sh`).
**Target Platform**: Linux server (the OpenClaw GCE host itself) — CLI runs locally on-host only; explicitly NOT exposed as a network-reachable client (FR-003).
**Project Type**: Single project — extension of the existing flat `scripts/` layout (no `src/`, `frontend/`, `backend/` split in this repo).
**Performance Goals**: SC-001 — first response to a simple message within 5 seconds under normal operating conditions (matches existing Telegram/Gemini call latency expectations; no new performance budget introduced).
**Constraints**: No idle timeout on the interactive session (FR-004); input validation must reject malformed/oversized input before any network call, synchronously and fast (FR-010); must not be reachable as a network client (FR-003) — enforced by shipping only as a local CLI subcommand with no listening socket.
**Scale/Scope**: Single-operator host assumption per spec.md Assumptions; one continuing CLI thread per host (not per OS user) — small, fixed scale, no concurrency/multi-tenancy design needed for this release.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Applicability | Status |
|---|---|---|
| 1. Infrastructure as Code (Terraform) | N/A — no new GCP infra resources; feature is application code shipped inside the existing container image. | PASS (N/A) |
| 2. GitOps Actuation via `abcxyz/guardian` | N/A — no Terraform changes. | PASS (N/A) |
| 3. Keyless Auth & Least Privilege Secrets | CLI reuses the already-fetched `GEMINI_API_KEY` from Secret Manager via the existing runtime env; no new secret introduced. | PASS |
| 4. Decoupled State & Data Persistence | Conversation history persists via `vector_memory.py`'s SQLite store on the persistent disk, not on ephemeral compute or in-process memory. | PASS |
| 5. Containerized Artifact Supply Chain | `chat` subcommand ships inside the existing `scripts/openclaw` file, built into the same container image; no host-side install step. | PASS |
| 6. Explicit Version Pinning & LLM Verification | No new dependencies/pins introduced (stdlib only). | PASS (N/A) |
| 7. Synchronized Manual Setup Docs & Onboarding Skill | No new manual GCP setup step is introduced (CLI works with existing deployment); `quickstart.md` documents usage. If any operator-facing setup note is later found necessary, `docs/Quickstart.md` must be updated in the same change — tracked as a task-phase checklist item. | PASS (pending task-phase confirmation) |
| 8. Prefer Native Framework Capabilities & Maximum Component Reuse | Core driver of this plan: reuses `ChannelAdapter`, `VectorMemoryEngine`, `ModelRouter`, and (for the shared Gemini-call logic) a to-be-extracted helper from `telegram_daemon.py`, rather than new parallel implementations. | PASS |
| 9. Immutable Read-Only Container Image Binaries | `chat` subcommand code lives in the read-only image (`scripts/openclaw`); only the SQLite DB file lives on persistent disk. | PASS |
| 10. Extension Architecture Selection Framework | N/A — this feature adds no new external tool/service integration (no Google Workspace, no new MCP server); it extends the existing Gemini chat path Telegram already uses. | PASS (N/A) |
| 11. Production-Grade Engineering & No Unapproved Workarounds | Input validation, explicit error surfacing (FR-005/FR-010), and no string-matching-in-place-of-function-calling shortcuts are used — the plan reuses the existing native Gemini function-calling turn-2 flow as-is. | PASS |

No violations requiring justification. Complexity Tracking section below is empty by design.

## Project Structure

### Documentation (this feature)

```text
specs/026-cli-chat-interface/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md         # Phase 1 output
├── quickstart.md         # Phase 1 output
└── checklists/
    └── requirements.md   # Already present (spec quality checklist)
```

(No `contracts/` directory: consistent with this repo's established precedent for CLI/infrastructure-shaped features — see `specs/015-vector-memory-engine/`, `specs/017-multichannel-gateway/`, `specs/020-multitenant-rbac-authorization/`, none of which produced a `contracts/` dir, since this project does not expose a REST/GraphQL API surface for these features. The CLI's "contract" is its subcommand surface, documented in `quickstart.md`.)

### Source Code (repository root)

```text
scripts/
├── openclaw                # MODIFIED: add `chat` subparser + cmd_chat() (one-shot & REPL modes)
├── channel_gateway.py       # MODIFIED: add CLIAdapter(ChannelAdapter)
├── vector_memory.py         # MODIFIED: add `role` column (additive) + get_recent() accessor
├── telegram_daemon.py       # MODIFIED (light refactor): extract shared Gemini-call/tool-loop
│                             #   logic (currently query_gemini()) into a reusable helper so
│                             #   both Telegram and CLI call one implementation, not two.
├── model_router.py          # UNCHANGED — reused as-is via ModelRouter
├── rbac_gateway.py          # UNCHANGED — explicitly not invoked for CLI's base auth gate (FR-009)
├── otel_tracing.py          # UNCHANGED — OTelTracer reused as-is, called from the new CLI path
└── test_cli_chat.sh         # NEW: verification script (one-shot, REPL multi-turn, cross-invocation
                              #   persistence, malformed/oversized input rejection, backend-unreachable
                              #   error path)
```

**Structure Decision**: Single flat `scripts/` project, matching every prior OpenClaw feature spec (015, 017, 020). No new top-level directory. The feature is realized as targeted modifications to four existing files plus one new test script — no new standalone script/daemon, consistent with the reuse-first approach directed for this feature and required by Principle 8.

## Complexity Tracking

*No entries — no Constitution Check violations require justification.*
