# Technical Research: Google Workspace MCP Server Integration

## Technical Decisions & Rationale

### 1. Integration Package Selection
* **Decision**: Adopt the standard open-source `google-workspace-mcp` package run natively via `uvx` (`uvx --from google-workspace-mcp google-workspace-worker`) inside the immutable Docker container image (`docker/Dockerfile`), pinned strictly to explicit release version (`google-workspace-mcp==1.2.0`).
* **Rationale**:
  * **Principle 10 Compliance**: Fully implements Model Context Protocol (MCP) over standard JSON-RPC `stdio` process pipes.
  * **Principle 6 Compliance**: Version is explicitly pinned in `Dockerfile` to eliminate floating dependency risks.
  * **Zero Local Bridge / Wrapper Code**: No custom bridge script (`gworkspace_mcp_bridge.py`) exists; `tool_gateway.py` communicates directly as an MCP Client over stdio with the native package worker.
  * **Broad Tool Surface**: Provides pre-built, tested tool definitions for Gmail, Google Calendar, Google Drive, Google Docs, Google Sheets, Google Tasks, and Google Contacts.
* **Alternatives Considered**:
  * Custom bridge or custom `FastMCP` script: Rejected to eliminate technical debt and schema duplication.
  * Remote GCP Cloud Run MCP Endpoint: Deferred; stdio local process communication inside VM/container is faster and simpler for OpenClaw's architecture.

---

### 2. Secret & Credential Persistence
* **Decision**: Store Google OAuth Client IDs, Client Secrets, and User Refresh Tokens in GCP Secret Manager under `google-workspace-credentials` and `google-calendar-credentials`.
* **Rationale**:
  * **Principle 3 Compliance**: No hardcoded credentials or local secrets in repo.
  * **Principle 1 Compliance**: Managed declaratively via Terraform in `terraform/modules/secrets/main.tf`.
  * **Runtime Ingestion**: `docker/entrypoint.sh` fetches the secret payload at container startup and populates environment variables / JSON credentials for the MCP server.

---

### 3. Tool Gateway Integration Architecture
* **Decision**: Extend `scripts/tool_gateway.py` to act as an MCP Client proxy over stdio JSON-RPC.
* **Rationale**:
  * **Principle 8 Compliance**: Reuses the established `ToolGateway` process invocation model.
  * **Timeout & Error Safety**: Enforces a strict 10.0-second timeout per JSON-RPC request and captures stdio/stderr safely.
  * **Gemini LLM Function Calling**: Dispatches tool definitions from `google_workspace_mcp` directly to Gemini model router (`model_router.py`).
