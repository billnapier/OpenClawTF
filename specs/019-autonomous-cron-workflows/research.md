# Technical Research: Autonomous Cron Scheduler

## Concurrency & Locking Strategy
- **SQLite Locking**: Uses `cron_locks` table with primary key `job_id` and timestamp lock expiration.
- **Persistence**: Store cron jobs in SQLite database (`/mnt/disks/openclaw-data/cron.db`) to survive restarts.
- **Dispatch**: Output pushed to target channel adapter (Telegram/Discord).
