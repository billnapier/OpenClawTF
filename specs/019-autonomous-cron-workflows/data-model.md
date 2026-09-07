# Data Model: Cron Job & Lock Schema

## SQLite Tables

```sql
CREATE TABLE IF NOT EXISTS cron_jobs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    schedule TEXT NOT NULL,
    prompt TEXT NOT NULL,
    channel TEXT NOT NULL,
    status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS cron_locks (
    job_id INTEGER PRIMARY KEY,
    locked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
