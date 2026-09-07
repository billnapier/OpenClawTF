# Technical Research: High Availability Failover & Disk Migration

## Failover Protocol
- **Disk Detach**: `gcloud compute instances detach-disk <PRIMARY> --disk=<DISK>`
- **Disk Attach**: `gcloud compute instances attach-disk <STANDBY> --disk=<DISK>`
- **Polling Mutual Exclusion**: Ensure primary process stops polling before standby starts polling.
- **Failover SLA Target**: Total migration execution `< 60s`.
