# Quality Checklist: High Availability Failover Requirements

- [ ] **Failover Verifier Script (`scripts/verify_ha_failover.sh`)**: Script supporting `--primary` and `--standby` instance targeting, disk detachment, and re-attachment.
- [ ] **Long-Polling Conflict Safeguard**: Lock file/secret check preventing simultaneous bot polling during node transition.
- [ ] **SQLite Database Handover Verification**: Automated verification confirming database files (`memory.db`, `vector_memory.db`, `cron.db`) open cleanly post-failover.
- [ ] **Failover Latency Target**: Execution completes within 60 seconds.
- [ ] **Verification Test (`scripts/test_ha_failover.sh`)**: Executable simulation test asserting instance transition and database integrity.
