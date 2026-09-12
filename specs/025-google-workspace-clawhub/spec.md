# Feature Specification: Google Workspace Integration (ClawHub + gog)

**Spec ID**: 025  
**Status**: PLANNED  
**Supersedes**: Spec 024 (Google Workspace MCP Server — Abandoned)

## Feature Overview & Objectives

Integrate Google Workspace capabilities (Gmail, Google Calendar, Drive, Tasks, Contacts) into OpenClaw using the **ClawHub `gog` skill** and the **Antigravity skill ecosystem**, rather than a custom Model Context Protocol (MCP) subprocess.

The previous approach (Spec 024) attempted to run `google-workspace-mcp` as an isolated stdio subprocess communicating via JSON-RPC. This proved unreliable due to persistent protocol handshake failures between the MCP package, the Gemini Function Calling API, and the OpenClaw tool gateway. The `gog` ClawHub skill approach eliminates these compatibility issues by delegating Google OAuth lifecycle management to the ClawHub framework.

---

## Why ClawHub + gog Instead of MCP

| Concern | MCP Server (Spec 024 — Abandoned) | ClawHub gog Skill (This Spec) |
| :--- | :--- | :--- |
| OAuth token management | Manual `token.json` + env vars | Managed by `gog` framework |
| Process isolation | Subprocess stdio JSON-RPC | Native Antigravity skill invocation |
| Schema compatibility | Gemini Function Calling schema conflicts | Standard skill call interface |
| Credential security | Token at risk of hitting git | `gog` stores credentials out-of-tree |
| Maintenance burden | Custom MCP bridge code in `tool_gateway.py` | Zero custom bridge code |

---

## Architectural Alignment & Constitutional Principles

* **Principle 10 (Updated — ClawHub-First)**: For Google Workspace integrations, the ClawHub `gog` skill is the **preferred** mechanism. Custom MCP servers are reserved for non-Google third-party tools without a ClawHub equivalent.
* **Principle 8 (Prefer Native Framework Capabilities)**: Reuse the ClawHub/`gog` skill ecosystem rather than building a custom authentication and dispatch bridge.
* **Principle 3 (Keyless Auth & Secret Management)**: `gog` handles OAuth token refresh transparently; no secrets are stored in GCP Secret Manager for Google Workspace.
* **Principle 9 (Immutable Container)**: No runtime credential downloads or `token.json` on disk.

---

## User Stories & Acceptance Scenarios

### User Story 1: Google Calendar Access via Natural Language
* **As an** Authorized Telegram User,
* **I want** to ask *"What's on my calendar today?"* or *"Schedule a meeting with Sarah at 2pm tomorrow"*,
* **So that** OpenClaw manages my schedule directly from Telegram.

### User Story 2: Gmail Access via Natural Language
* **As an** Authorized Telegram User,
* **I want** to query *"Do I have any unread emails about the Q3 budget?"*,
* **So that** OpenClaw searches my Gmail inbox and surfaces relevant threads.

### User Story 3: Google Tasks Management
* **As an** Authorized Telegram User,
* **I want** to say *"Add 'review PR #42' to my task list"*,
* **So that** OpenClaw creates a Google Task via the `gog` skill.

---

## Technical Approach

1. **Install `clawhub/gog` skill** into the Antigravity workspace (once published to ClawHub).
2. **Authenticate** via `gog auth login` — OAuth 2.0 PKCE flow, credentials stored by `gog` outside the repository.
3. **Wire `tool_gateway.py`** to dispatch Google Workspace tool calls via `gog` skill invocations (no custom subprocess management).
4. **Gemini Function Calling** remains the dispatch layer — tool schemas defined in `tool_gateway.py` and registered with the Gemini API as before.
5. No changes to `docker/Dockerfile`, `docker/entrypoint.sh`, or Terraform modules required for the core integration.

---

## Dependencies & Blockers

* **ClawHub `gog` skill availability**: This spec is blocked until the `gog` skill is published to ClawHub and its invocation API is documented.
* **Principle 10 Constitution Amendment**: Principle 10 must be updated in `constitution.md` to reflect ClawHub-first preference over MCP for Google integrations (tracked separately).

---

## Success Criteria

* `clawhub/gog` skill installed and authenticated (`gog auth login` succeeds).
* OpenClaw Telegram bot can respond to calendar, Gmail, and Tasks queries via natural language.
* No custom MCP subprocess code in `tool_gateway.py`.
* No OAuth credentials (`token.json`, `credentials.json`) in the git repository.
* `scripts/test_gworkspace_clawhub.sh` passes end-to-end validation in CI.
