# Implementation Plan: Scheduled Autonomous Workflows & Cron Gateway

## Architecture & Design
This feature implements background cron scheduling using SQLite state and locks on `/mnt/disks/openclaw-data/cron.db`.

### Core Components
1. **Cron Engine Utility (`scripts/cron_gateway.py`)**:
   - Manages SQLite schema (`cron_jobs` and `cron_locks`).
   - Implements `/cron add`, `/cron list`, `/cron remove`, and trigger tick handler.
   - Prevents duplicate execution via atomic lock table transactions.

2. **Validation Suite (`scripts/test_cron_workflows.sh`)**:
   - Verifies job registration, list, removal, locking, and trigger dispatch logic.
