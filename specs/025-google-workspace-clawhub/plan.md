# Implementation Plan: Google Workspace Integration (ClawHub + gog)

**Branch**: `025-google-workspace-clawhub` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/025-google-workspace-clawhub/spec.md`

## Summary

Replace the abandoned Spec 024 MCP subprocess approach with `gog` — a real, published, actively maintained Go CLI (ClawHub `steipete/gog`, `github.com/openclaw/gogcli`, v0.40.0) — invoked as a normal subprocess from `tool_gateway.py`. Research (research.md) found this isn't purely additive: Spec 024's revert left `model_router.py` and `telegram_daemon.py` calling two `ToolGateway` methods (`list_mcp_tools`, `call_mcp_tool`) that don't exist, so Gemini currently gets zero Workspace tools and the `/calendar`/`/gmail`/`/drive` Telegram slash commands would crash if invoked. This plan implements those two methods for real, backed by `gog`, which both delivers the three spec'd user stories (Calendar, Gmail, Tasks — all confirmed to exist in `gog`'s real command surface) and fixes the currently-broken integration in place.

## Technical Context

**Language/Version**: Python 3 (matches existing `scripts/*.py`); `gog` itself is a prebuilt Go binary, not compiled in this repo
**Primary Dependencies**: `gog` CLI binary (pinned release tag, installed via direct GitHub release download in `docker/Dockerfile`) — no new Python package dependencies
**Storage**: `gog`'s own encrypted token file, stored under `/mnt/disks/openclaw-data/gogcli` (persistent disk, Principle 4) — no new SQLite tables or application-level storage
**Testing**: Bash integration test script (`scripts/test_gworkspace_clawhub.sh`), matching this repo's existing `test_*.sh` convention (see `scripts/test_channel_adapters.sh`, `scripts/test_vector_memory.sh`)
**Target Platform**: Linux container (`google/cloud-sdk:slim` base, per existing `docker/Dockerfile`) — headless, no desktop keyring available
**Project Type**: Single project (existing `scripts/` tree; no new top-level directories)
**Performance Goals**: No new explicit target beyond existing daemon responsiveness; `gog` calls are synchronous subprocess invocations bounded by the existing `tool_gateway.py` timeout convention
**Constraints**: OAuth grant step is inherently interactive (real Google consent flow) and cannot be automated — it's a documented one-time onboarding step (quickstart.md), not a runtime constraint
**Scale/Scope**: Single shared Google account per deployment (research.md Decision 10) — not a multi-tenant, per-Telegram-user OAuth system

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| 1. Infrastructure as Code | PASS | One additive Terraform secret resource (`gog-keyring-password`); no manual GCP console steps |
| 2. GitOps via Guardian | PASS | Terraform change goes through the existing PR → `guardian plan` → merge → `guardian apply` flow, no direct `terraform apply` |
| 3. Keyless Auth & Secret Management | PASS, with a correction | spec.md claims zero GCP Secret Manager usage for this feature; research.md Decision 4 corrects this — `GOG_KEYRING_PASSWORD` must be a Secret Manager secret, fetched at container startup exactly like `GEMINI_API_KEY`. Still fully compliant with the *principle* (no hardcoded secrets, no static keys) — just not with spec.md's overstated claim, which this plan supersedes |
| 4. Decoupled State & Data Persistence | PASS | `gog`'s encrypted token state lives at `GOG_HOME=/mnt/disks/openclaw-data/gogcli`, not baked into the image or lost on VM replacement |
| 5. Containerized Artifact Supply Chain | PASS | `gog` binary installed into the image at build time via `docker/Dockerfile`, not downloaded at runtime |
| 6. Explicit Version Pinning | PASS (actionable) | Pin to `gog`'s current release tag (`v0.40.0` as of this research; implementation MUST verify the exact tag still exists in `github.com/openclaw/gogcli/releases` before pinning, not assume this doc snapshot is current) |
| 7. Synchronized Setup Docs & Onboarding Skill | PASS (actionable) | quickstart.md written; `docs/Quickstart.md` and `skills/openclaw.bootstrap/SKILL.md` MUST be updated in the same change (tasks.md to enumerate) |
| 8. Prefer Native Framework Capabilities | PASS | Reuses `tool_gateway.py`'s existing subprocess-dispatch pattern (`execute_python` already shells out); no new bridge abstraction invented |
| 9. Immutable Read-Only Container | PASS | Binary in image; only token *state* on persistent disk, matching the same pattern as SQLite data today |
| 10. Extension Architecture Selection Framework | PASS | ClawHub `gog` skill evaluated and selected first, per the mandated order; this plan documents that MCP was already tried (Spec 024) and is explicitly excluded for Google integrations per the amended principle text |
| 11. Production-Grade Engineering | PASS (actionable) | Confirm-before-mutate (research.md Decision 7) and clear exit-code-based error messages (Decision 9) replace the "silent `except: pass`" pattern currently in `model_router.get_tools()`, which this plan explicitly calls out as needing to go away, not be preserved |

No unjustified violations — Complexity Tracking table omitted.

## Project Structure

### Documentation (this feature)

```text
specs/025-google-workspace-clawhub/
├── plan.md              # This file
├── research.md           # Phase 0 output
├── data-model.md          # Phase 1 output
├── quickstart.md          # Phase 1 output
└── tasks.md               # Phase 2 output (/speckit.tasks — not created by this command)
```

### Source Code (repository root)

```text
scripts/
├── tool_gateway.py       # MODIFIED: add real list_mcp_tools() and call_mcp_tool(fn_name, args_json),
│                          #   backed by `gog` subprocess calls, replacing the two currently-dangling
│                          #   method references (research.md Decision 6)
├── model_router.py        # UNCHANGED: get_tools() already calls list_mcp_tools(); starts working
│                          #   once that method exists for real
├── telegram_daemon.py     # MODIFIED: query_gemini()'s functionCall handling already calls
│                          #   call_mcp_tool() and needs no change — it starts working once that
│                          #   method exists for real. But REMOVE the hardcoded /calendar, /gmail,
│                          #   /drive slash-command branches (text.startswith(...) in
│                          #   process_update(), ~lines 225-270) and their mention in /start's help
│                          #   text — explicit user preference is natural-language-only interaction
│                          #   ("what's on my calendar this week", not "/calendar"); these branches
│                          #   were never requested by spec.md and would bypass Gemini entirely,
│                          #   duplicating the real NL path this feature implements
└── test_gworkspace_clawhub.sh  # NEW: integration test script (see quickstart.md Test scenario)

docker/
└── Dockerfile             # MODIFIED: install pinned `gog` binary (GitHub release download + checksum)

docker/entrypoint.sh        # MODIFIED: fetch `gog-keyring-password` from Secret Manager, export
                             # GOG_KEYRING_BACKEND=file, GOG_HOME, GOG_KEYRING_PASSWORD, GOG_ACCOUNT

terraform/modules/secrets/main.tf  # MODIFIED: add `gog-keyring-password` secret resource

docs/Quickstart.md           # MODIFIED: add the manual gog auth setup steps (Principle 7)
skills/openclaw.bootstrap/SKILL.md  # MODIFIED: add interactive gog auth onboarding + verification
```

**Structure Decision**: No new top-level directories. This feature is scoped to filling in two currently-broken methods on the existing `ToolGateway` class plus the supporting Docker/Terraform/docs plumbing to make `gog` available to them — it deliberately does not touch `telegram_daemon.py` or `model_router.py`'s call sites, since those are already correctly wired and only failing because the methods they call don't exist yet.
