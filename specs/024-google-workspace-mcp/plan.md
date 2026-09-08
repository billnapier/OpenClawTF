# Implementation Plan: Google Workspace MCP Integration

## Executive Summary
This plan details the technical architecture and implementation strategy for integrating Google Workspace tools (Gmail, Drive, Calendar, Docs, Sheets, Tasks, Contacts) into OpenClaw via an isolated Model Context Protocol (MCP) Server, adhering strictly to **OpenClaw Constitution v1.4.0 (Principle 10)**.

---

## Technical Context & Integration Strategy

```
+-------------------------------------------------------------------------+
|                      OpenClaw Compute Container                         |
|                                                                         |
|  +------------------+         +------------------+                      |
|  | Telegram Daemon  |         | Control UI       |                      |
|  +--------+---------+         +--------+---------+                      |
|           |                            |                                |
|           v                            v                                |
|  +-----------------------------------------------+                      |
|  |           Gemini 2.5 Flash Model Router       |                      |
|  +------------------------+----------------------+                      |
|                           |                                             |
|                           v                                             |
|  +-----------------------------------------------+                      |
|  |           Tool Execution Gateway              |                      |
|  |            (tool_gateway.py)                  |                      |
|  +------------------------+----------------------+                      |
|                           |                                             |
|               JSON-RPC over stdio pipe                                  |
|                           |                                             |
|                           v                                             |
|  +-----------------------------------------------+                      |
|  |    Google Workspace MCP Subprocess Server     |                      |
|  |    (google-workspace-mcp package)             |                      |
|  +------------------------+----------------------+                      |
|                           |                                             |
|                           v                                             |
|  +-----------------------------------------------+                      |
|  |       Google Workspace REST APIs              |                      |
|  |   (Gmail, Calendar, Drive, Docs, Sheets, etc) |                      |
|  +-----------------------------------------------+                      |
+-------------------------------------------------------------------------+
```

---

## Constitution Compliance Gates (OpenClaw Constitution v1.4.0)

* **Principle 1 (Infrastructure as Code)**: Secret Manager resources for `google-workspace-credentials` declared in `terraform/modules/secrets/main.tf`. PASS.
* **Principle 2 (GitOps Actuation)**: All changes actuated via GitHub Actions PR checks and Guardian plan/apply. PASS.
* **Principle 3 (Keyless Auth & Secret Management)**: OAuth credentials dynamically ingested from GCP Secret Manager via `docker/entrypoint.sh`. PASS.
* **Principle 6 (Explicit Version Pinning)**: `google-workspace-mcp` pinned to explicit release version in `docker/Dockerfile`. PASS.
* **Principle 7 (Documentation & Onboarding Parity)**: Setup documented in `docs/Quickstart.md` and automated in `openclaw.bootstrap`. PASS.
* **Principle 9 (Immutable Read-Only Container Binaries)**: MCP binaries built into container image during build phase. PASS.
* **Principle 10 (MCP Extension Architecture)**: Third-party Workspace integration implemented as an isolated MCP Server communicating via JSON-RPC stdio. PASS.

---

## Implementation Breakdown

### Phase 1: Terraform & Secret Pipeline Setup
* Add `google-workspace-credentials` secret resource to `terraform/modules/secrets/main.tf`.
* Update `docker/entrypoint.sh` to extract `GOOGLE_WORKSPACE_CREDENTIALS` payload.

### Phase 2: Container Dependency & MCP Server Packaging
* Add `google-workspace-mcp` and `mcp` SDK to `docker/Dockerfile` with explicit version pinning.
* Create MCP bridge wrapper script `scripts/gworkspace_mcp_bridge.py`.

### Phase 3: Tool Gateway & Gemini Integration
* Update `scripts/tool_gateway.py` to register MCP tools into Gemini function definitions.
* Implement stdio JSON-RPC message passing and 10s execution timeout handling.

### Phase 4: Vector Memory RAG Workspace Sync
* Create `scripts/sync_gworkspace_vector_memory.py` to ingest Drive docs and email threads into `vector_memory.db`.
* Register optional cron job in `scripts/cron_gateway.py`.

### Phase 5: Verification & Testing
* Create automated test suite `scripts/test_gworkspace_mcp.sh` to validate MCP server startup, tool schema discovery, JSON-RPC RPC dispatch, and mock API response handling.
