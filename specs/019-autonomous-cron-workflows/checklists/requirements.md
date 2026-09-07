# Quality Checklist: Autonomous Cron Workflows Requirements

- [ ] **SQLite Schema (`cron.db`)**: Tables `cron_jobs` and `cron_locks` created with unique constraints and status tracking on persistent disk.
- [ ] **Slash Command Handlers**: `/cron add`, `/cron list`, `/cron delete` implemented with expression parsing and confirmation responses.
- [ ] **Background Execution Engine**: Async tick loop evaluating active cron schedules without blocking incoming chat messages.
- [ ] **Concurrency Lock Protection**: Transactional locking in SQLite preventing duplicate execution across restarts.
- [ ] **Verification Script (`scripts/test_cron_workflows.sh`)**: Automated test verifying job creation, trigger execution, lock acquisition, and result posting.
