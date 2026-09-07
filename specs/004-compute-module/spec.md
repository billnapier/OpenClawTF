# Feature Specification: Compute Integration & Boot Script Module

## Feature Overview & Objectives
The goal of this feature is to create a modular Terraform module (`terraform/modules/compute`) that provisions a Google Compute Engine (GCE) instance running Container-Optimized OS (COS). 

The module integrates the private VPC subnetwork from `modules/vpc`, attaches the standalone persistent disk from `modules/storage`, configures the GCE service account identity for Secret Manager access from `modules/secrets`, and injects a VM `metadata_startup_script` template to handle idempotent disk mounting, secret loading, and container orchestration.

## User Stories & Acceptance Scenarios

### User Story 1: Secure Container-Optimized Compute Node
* **As a** Cloud Administrator,
* **I want** a GCE VM instance provisioned in a private subnetwork with no public IP address,
* **So that** the OpenClaw service has zero public inbound attack surface.

#### Scenario 1.1: Private Subnet Compute Provisioning
* **Given** valid VPC subnet ID and persistent disk self-link,
* **When** `terraform apply` is executed for the `compute` module,
* **Then** a `google_compute_instance` is created running `cos-cloud/cos-stable`, attached strictly to the private subnetwork with `access_config` omitted (no external IP address).

### User Story 2: Persistent Storage Attachment & Device Naming
* **As a** System Administrator,
* **I want** the standalone persistent disk attached to the compute VM under a predictable device name,
* **So that** startup scripts can reliably locate and mount `/dev/disk/by-id/google-openclaw-data`.

#### Scenario 2.1: Predictable Disk Attachment
* **Given** an existing `google_compute_disk` resource,
* **When** the `compute` module is applied,
* **Then** the disk is declared in `attached_disk` with `device_name = "openclaw-data"` and `mode = "READ_WRITE"`.

### User Story 3: Startup Metadata Script Injection
* **As a** DevOps Engineer,
* **I want** a custom VM startup script template injected via metadata,
* **So that** the VM automatically mounts the persistent disk, authenticates to GCP Artifact Registry, pulls the OpenClaw image, fetches secrets via ADC, and starts Docker on boot.

#### Scenario 3.1: Startup Script Metadata Injection
* **Given** template parameters for image repository and secret names,
* **When** the GCE instance boots,
* **Then** `metadata_startup_script` executes disk formatting check (`blkid`), mounts to `/mnt/disks/openclaw-data`, and launches the OpenClaw container.

---

## Requirements & Functional Specifications

### 1. Inputs & Variables (`terraform/modules/compute/variables.tf`)
| Name | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `project_id` | `string` | N/A (Required) | The GCP Project ID. |
| `zone` | `string` | `"us-central1-a"` | GCP Zone for the GCE instance. |
| `instance_name` | `string` | `"openclaw-vm"` | Name of the GCE VM instance. |
| `machine_type` | `string` | `"e2-standard-2"` | GCE machine type (default `e2-standard-2`). |
| `subnetwork_id` | `string` | N/A (Required) | Self-link or ID of the private subnetwork from `modules/vpc`. |
| `persistent_disk_name` | `string` | N/A (Required) | Disk name from `modules/storage` for `attached_disk`. |
| `service_account_email` | `string` | N/A (Required) | Service account email with Secret Accessor role. |
| `container_image` | `string` | N/A (Required) | Container image URI (e.g. Artifact Registry URI). |

### 2. Outputs (`terraform/modules/compute/outputs.tf`)
| Name | Description |
| :--- | :--- |
| `instance_id` | Unique ID of the created GCE instance. |
| `instance_name` | Name of the created GCE instance. |
| `instance_self_link` | Self-link URL of the created GCE instance. |
| `internal_ip` | Primary private IPv4 address of the instance. |

### 3. Resource Definitions (`terraform/modules/compute/main.tf`)
- `google_compute_instance.openclaw_vm`: GCE Instance resource.
- `boot_disk`: Container-Optimized OS (`cos-cloud/cos-stable`).
- `attached_disk`: Detached persistent disk attachment (`device_name = "openclaw-data"`).
- `network_interface`: Configured with `subnetwork = var.subnetwork_id`, without `access_config` block.
- `service_account`: Service account email assigned with scope `["cloud-platform"]`.
- `metadata_startup_script`: Renders bootstrap shell script template.

---

## Edge Cases & Failure Modes
- **Disk Device Name Drift**: If `device_name` in `attached_disk` differs from the device path expected in `startup-script.sh`, disk mounting fails at boot. Ensure exact match (`google-openclaw-data`).
- **Missing Cloud NAT**: Provisioning VM in private subnet without Cloud NAT prevents Docker image pulls from Artifact Registry.
- **Service Account Permissions**: Inadequate IAM permissions on the assigned service account cause `403 Forbidden` errors during Secret Manager fetching.

---

## Dependencies
- Prerequisites: `modules/vpc`, `modules/storage`, and `modules/secrets` created and outputs exported.
- Container image pushed to Artifact Registry or accessible public registry.

---

## Success Criteria & Validation
- `terraform fmt -check` and `terraform validate` pass inside `terraform/modules/compute`.
- VM correctly defined without external IP address and attached to `openclaw-data` persistent disk.
