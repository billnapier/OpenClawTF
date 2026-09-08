# Data Model: Google Workspace MCP Server Integration

## Entities & Schemas

### 1. GCP Secret Payload (`google-workspace-credentials`)
```json
{
  "type": "authorized_user",
  "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
  "client_secret": "YOUR_CLIENT_SECRET",
  "refresh_token": "YOUR_REFRESH_TOKEN",
  "scopes": [
    "https://www.googleapis.com/auth/gmail.modify",
    "https://www.googleapis.com/auth/calendar",
    "https://www.googleapis.com/auth/drive.readonly",
    "https://www.googleapis.com/auth/documents",
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/tasks",
    "https://www.googleapis.com/auth/contacts.readonly"
  ]
}
```

---

### 2. MCP JSON-RPC Request Contract (stdio Pipe)
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "calendar_create_event",
    "arguments": {
      "summary": "Team Sync & Q3 Planning",
      "start_time": "2026-09-08T14:00:00Z",
      "end_time": "2026-09-08T15:00:00Z",
      "attendees": ["alice@company.com", "bob@company.com"],
      "conference": true
    }
  }
}
```

---

### 3. MCP JSON-RPC Response Contract
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"status\":\"success\",\"event_id\":\"evt_12345\",\"hangout_link\":\"https://meet.google.com/abc-defg-hij\"}"
      }
    ]
  }
}
```

---

### 4. Vector Memory Workspace Document Entry (`vector_memory.db`)
* **`document_id`**: String (e.g. `gdrive_file_id_998877`)
* **`source_type`**: String (`gdrive_doc`, `gmail_thread`, `gsheet_table`)
* **`title`**: String (`Q3 Financial Strategy`)
* **`chunk_index`**: Integer (`0`, `1`, `2`...)
* **`content_text`**: String (Parsed document text)
* **`embedding_vector`**: BLOB (Gemini text-embedding-004 float array)
* **`last_synced`**: Integer (Unix epoch timestamp)
