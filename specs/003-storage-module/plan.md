# Architecture Plan: Persistent Disk Storage Module

## Proposed Architecture
The Persistent Disk Storage module provisions a standalone Google Compute Engine persistent disk (`openclaw-data`) to store conversation memory, SQLite databases, and vector state independently of compute instances.

### Directory Structure
```
terraform/modules/storage/
├── main.tf        # Persistent disk resource definition
├── variables.tf   # Module inputs (project_id, zone, disk_name, disk_type, disk_size_gb, labels)
├── outputs.tf     # Module outputs (disk_id, disk_name, disk_self_link, disk_size_gb)
└── versions.tf    # Required terraform and provider version constraints
```

## Step-by-Step Implementation Strategy

1. **Versions Configuration (`versions.tf`)**:
   - Required terraform `>= 1.5.0`.
   - Required `google` provider `>= 5.0.0, < 7.0.0`.

2. **Input Variable Specifications (`variables.tf`)**:
   - `project_id`: Required string.
   - `zone`: String default `"us-central1-a"`.
   - `disk_name`: String default `"openclaw-data"`.
   - `disk_type`: String default `"pd-ssd"`.
   - `disk_size_gb`: Number default `20`.
   - `labels`: Map(string) default environment/app labels.

3. **Resource Definitions (`main.tf`)**:
   - `google_compute_disk.openclaw_data`: `name`, `type`, `size`, `zone`, `labels`, `description`.

4. **Output Definitions (`outputs.tf`)**:
   - `disk_id`, `disk_name`, `disk_self_link`, `disk_size_gb`.

5. **Validation Plan**:
   - `terraform fmt -check` and `terraform validate` inside `terraform/modules/storage`.
