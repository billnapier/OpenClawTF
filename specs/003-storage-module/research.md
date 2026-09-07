# Research & Design Decisions: Storage Module

## Key Architectural Decisions

1. **Standalone Disk vs Attached Inline Disk**:
   - Defining `google_compute_disk` as a standalone resource outside `google_compute_instance` ensures the disk lifecycle is detached from VM lifecycle. Recreating the compute instance will not delete the storage volume.

2. **Performance Selection (`pd-ssd`)**:
   - `pd-ssd` provides consistent random IOPS required for concurrent SQLite WAL transactions and vector database access.

3. **Zone Co-Location**:
   - GCP GCE persistent disks are zonal resources. The compute VM and persistent disk must reside in the exact same GCP zone (e.g. `us-central1-a`).
