# Data Model: Vector Memory Schema

## SQLite Table: `memories`

```sql
CREATE TABLE IF NOT EXISTS memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    text TEXT NOT NULL,
    embedding TEXT NOT NULL, -- JSON-encoded float array
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
