# Architecture Plan: Compute Integration & Boot Script Module

## Proposed Architecture
The Compute module provisions a Container-Optimized OS (COS) GCE instance inside a private subnet, attaches the pre-existing persistent disk (`openclaw-data`), assigns the GCE runtime Service Account identity, and injects an automated startup script template.

### Directory Structure
```
terraform/modules/compute/
├── main.tf                            # GCE Instance resource declaration
├── variables.tf                       # Module inputs
├── outputs.tf                         # Module outputs (instance_id, instance_name, internal_ip)
├── versions.tf                        # Provider & Terraform constraints
└── templates/
    └── startup-script.sh.tftpl        # Bootstrap startup script template
```

## Step-by-Step Implementation Strategy

1. **Versions Configuration (`versions.tf`)**:
   - Required terraform `>= 1.5.0`.
   - Required `google` provider `>= 5.0.0, < 7.0.0`.

2. **Input Variable Specifications (`variables.tf`)**:
   - `project_id`: Required string.
   - `zone`: String default `"us-central1-a"`.
   - `instance_name`: String default `"openclaw-vm"`.
   - `machine_type`: String default `"e2-standard-2"`.
   - `subnetwork_id`: Required string.
   - `persistent_disk_name`: Required string.
   - `service_account_email`: Required string.
   - `container_image`: Required string.

3. **Startup Script Template (`templates/startup-script.sh.tftpl`)**:
   - Shell script that formats persistent disk if unformatted (`mkfs.ext4`), mounts to `/mnt/disks/openclaw-data`, fetches secrets via ADC if needed or configures runtime environment, and launches the container via Docker.

4. **Compute Instance Definition (`main.tf`)**:
   - Declare `google_compute_instance.openclaw_vm`.
   - Boot disk: `image = "cos-cloud/cos-stable"`.
   - Attached disk: `source = var.persistent_disk_name`, `device_name = "openclaw-data"`, `mode = "READ_WRITE"`.
   - Network interface: `subnetwork = var.subnetwork_id` (no `access_config` for private VM).
   - Service Account: `email = var.service_account_email`, `scopes = ["cloud-platform"]`.
   - Metadata: `startup-script = templatefile("${path.module}/templates/startup-script.sh.tftpl", { ... })`.

5. **Output Definitions (`outputs.tf`)**:
   - `instance_id`, `instance_name`, `instance_self_link`, `internal_ip`.

6. **Validation Plan**:
   - `terraform fmt -check` and `terraform validate` inside `terraform/modules/compute`.
