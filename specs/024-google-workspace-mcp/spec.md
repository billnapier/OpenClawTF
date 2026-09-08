# Feature Specification: Google Workspace MCP Server Integration

## Feature Overview & Objectives
The goal of this feature is to integrate Google Workspace capabilities (Gmail, Google Drive, Google Calendar, Google Docs, Google Sheets, Google Tasks, and Google Contacts) into OpenClaw as a dedicated Model Context Protocol (MCP) Server.

In strict compliance with **Principle 10 (Extension Architecture Selection Framework)** of the OpenClaw Project Constitution (v1.4.0), all third-party integrations MUST execute as isolated MCP Servers communicating via standard JSON-RPC transport rather than direct monolithic dependencies.

This integration empowers OpenClaw to perform intelligent conversational workspace management—reading/searching/sending emails, scheduling calendar events with Google Meet links, reading/writing Drive files, authoring Docs, updating Sheets, managing Tasks, and indexing workspace documents into OpenClaw's Vector Memory Engine (`vector_memory.py`) for cross-document RAG search.

---

## Architectural Alignment & Constitutional Principles
* **Principle 10 (MCP Extension Architecture)**: Executed as an isolated Python MCP server (`scripts/gworkspace_mcp_server.py`) communicating via JSON-RPC stdio with `tool_gateway.py`.
* **Principle 1 (Infrastructure as Code)**: OAuth Client credentials, refresh tokens, and service account configs declared in Terraform (`terraform/modules/secrets/main.tf`).
* **Principle 3 (Keyless Auth & Secret Management)**: Credentials fetched dynamically at runtime from GCP Secret Manager (`google-workspace-credentials`, `google-calendar-credentials`).
* **Principle 9 (Immutable Read-Only Container)**: `google-api-python-client`, `google-auth`, and `mcp` SDK built into `docker/Dockerfile`.
* **Principle 7 (Documentation & Onboarding Parity)**: Setup instructions documented in `docs/Quickstart.md` and automated in `skills/openclaw.bootstrap/SKILL.md`.

---

## User Stories & Acceptance Scenarios

### User Story 1: Isolated Workspace MCP Server & Tool Registration
* **As an** OpenClaw AI Agent,
* **I want** to communicate with a dedicated Google Workspace MCP Server via standard JSON-RPC,
* **So that** third-party API dependencies remain isolated from core container runtimes and can be called safely by Gemini LLM.

#### Scenario 1.1: MCP Server Initialization & Capability Discovery
* **Given** an initialized OpenClaw runtime with GCP Secret Manager credentials present,
* **When** `scripts/gworkspace_mcp_server.py` starts,
* **Then** it authenticates with Google APIs and exposes standardized MCP tools (`gmail_search`, `gmail_send`, `calendar_list_events`, `calendar_create_event`, `drive_search_files`, `docs_create`, `sheets_append_row`, `tasks_create`, `contacts_lookup`) over JSON-RPC.

#### Scenario 1.2: Tool Gateway Proxying
* **Given** a user request in Telegram or Control UI requiring calendar or email actions,
* **When** `tool_gateway.py` receives a tool call request,
* **Then** it dispatches a JSON-RPC request to the MCP server process, enforces execution time limits (<10s), and returns structured JSON output to Gemini.

---

### User Story 2: Conversational Calendar, Gmail, & Drive Automation
* **As an** Authorized Telegram User,
* **I want** to query my schedule, search my inbox, and find Google Drive documents using natural language,
* **So that** I can manage my day-to-day productivity directly through OpenClaw.

#### Scenario 2.1: Checking Calendar & Creating Meetings
* **Given** an authorized Telegram user asking *"What is on my calendar today?"* or *"Schedule a meeting with Sarah tomorrow at 2 PM"*,
* **When** OpenClaw processes the message,
* **Then** it calls `calendar_list_events` or `calendar_create_event` via MCP, attaches a Google Meet link, and returns a formatted confirmation to Telegram.

#### Scenario 2.2: Email Search & Outbound Drafting
* **Given** a request like *"Find unread emails about Q3 budget and reply with a summary"*,
* **When** OpenClaw invokes `gmail_search` and `gmail_send` via MCP,
* **Then** it parses message threads, generates a summary response, and dispatches the email securely.

---

### User Story 3: Expanded Workspace Tools (Docs, Sheets, Tasks, Contacts & Vector Memory RAG)
* **As a** Power User,
* **I want** OpenClaw to interact with Docs, Sheets, Tasks, and Contacts, and index Drive files into Vector Memory,
* **So that** OpenClaw acts as an end-to-end intelligent workspace assistant.

#### Scenario 3.1: Spreadsheet Logging & Document Authoring
* **Given** a user prompt *"Save meeting notes to a new Google Doc and log task items in our tracking Google Sheet"*,
* **When** OpenClaw invokes `docs_create` and `sheets_append_row`,
* **Then** the document and spreadsheet rows are updated and URLs returned.

#### Scenario 3.2: Workspace RAG Ingestion
* **Given** documents stored in Google Drive,
* **When** `scripts/sync_gworkspace_vector_memory.py` is run or triggered via Cron (`cron_gateway.py`),
* **Then** document text is chunked, embedded, and stored in `vector_memory.db` for instant semantic search via Telegram.

---

## Technical Constraints & Safety Bounds
* **JSON-RPC Protocol**: Standard MCP stdio protocol over process pipes.
* **Process Isolation**: MCP Server runs as a isolated subprocess with timeout enforcement (10.0s per RPC call).
* **Scope Scoping**: OAuth scopes limited strictly to required Workspace APIs (`gmail.modify`, `calendar`, `drive.readonly`, `documents`, `spreadsheets`, `tasks`, `contacts.readonly`).

---

## Success Criteria & Validation
* MCP Server script `scripts/gworkspace_mcp_server.py` implemented exposing Gmail, Drive, Calendar, Docs, Sheets, Tasks, and Contacts tools.
* Tool execution gateway `scripts/tool_gateway.py` updated to proxy MCP tool calls cleanly.
* Vector memory sync script `scripts/sync_gworkspace_vector_memory.py` created for RAG document ingestion.
* Executable test script `scripts/test_gworkspace_mcp.sh` created to validate MCP server initialization, JSON-RPC communication, and mock tool executions in CI.
