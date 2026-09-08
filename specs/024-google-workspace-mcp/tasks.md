# Implementation Tasks: Google Workspace MCP Integration

## Phase 1: Setup & Terraform Prerequisites
- [x] T001 Declare `google-workspace-credentials` secret resource in `terraform/modules/secrets/main.tf`
- [x] T002 Update `docker/entrypoint.sh` to dynamically fetch and export `GOOGLE_WORKSPACE_CREDENTIALS` from Secret Manager

## Phase 2: Foundational MCP Package & Dependencies
- [x] T003 [P] Add `google-workspace-mcp` package with pinned version to `docker/Dockerfile`
- [x] T004 Implement MCP bridge initializer script `scripts/gworkspace_mcp_bridge.py`

## Phase 3: User Story 1 - Isolated Workspace MCP Server & Tool Gateway Integration
- [x] T005 [US1] Extend `scripts/tool_gateway.py` with stdio JSON-RPC MCP proxy execution and 10s execution timeout limits
- [x] T006 [US1] Register Workspace MCP tool declarations with `scripts/model_router.py` for Gemini function calling

## Phase 4: User Story 2 - Conversational Calendar, Gmail, & Drive Automation
- [x] T007 [US2] Implement Google Calendar tool handlers (`calendar_list_events`, `calendar_create_event`) in `scripts/telegram_daemon.py`
- [x] T008 [US2] Implement Gmail & Drive tool handlers (`gmail_search`, `gmail_send`, `drive_search_files`) in `scripts/telegram_daemon.py`

## Phase 5: User Story 3 - Expanded Workspace Tools (Docs, Sheets, Tasks, Contacts & Vector RAG)
- [x] T009 [US3] Implement Docs, Sheets, Tasks, and Contacts tool handlers (`docs_create`, `sheets_append_row`, `tasks_create`, `contacts_lookup`)
- [x] T010 [US3] Create Vector Memory RAG workspace document ingestion script `scripts/sync_gworkspace_vector_memory.py`

## Phase 6: Polish, Documentation, & Verification
- [x] T011 Create automated test suite `scripts/test_gworkspace_mcp.sh` to validate MCP server initialization and JSON-RPC dispatch
- [x] T012 Update `docs/Quickstart.md` and `skills/openclaw.bootstrap/SKILL.md` for synchronized manual and automated onboarding per Principle 7
