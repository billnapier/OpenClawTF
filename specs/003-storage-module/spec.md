# Feature Specification: Persistent Disk Storage Module

## Feature Overview & Objectives
The goal of this feature is to create a modular Terraform module (`terraform/modules/storage`) that provisions a standalone Google Compute Engine persistent disk (`openclaw-data`).

This disk stores agent conversation memory, SQLite WAL databases (`memory.db`), and vector indices at `/mnt/disks/openclaw-data`. The disk is decoupled from the VM lifecycle, ensuring state immutability across compute instance replacements, scale events, or image updates.

## User Stories & Acceptance Scenarios

### User Story 1: Decoupled State Preservation
* **As a** System Administrator,
* **I want** application data stored on an independent persistent disk,
* **So that** replacing or recreating the GCE VM instance never results in lost conversation context or database corruption.

#### Scenario 1.1: Standalone Persistent Disk Provisioning
* **Given** a target GCP zone and disk size parameters,
* **When** `terraform apply` is executed for the `storage` module,
* **Then** a standalone `google_compute_disk` resource named `openclaw-data` is created with disk type `pd-ssd` (or `pd-standard`), size of `20GB` (configurable), and standard environment labels.

#### Scenario 1.2: Lifecycle Protection
* **Given** an existing provisioned persistent disk,
* **When** a `terraform destroy` or VM replacement occurs,
* **Then** the persistent disk resource configuration prevents accidental deletion of application state.

---

## Requirements & Functional Specifications

### 1. Inputs & Variables (`terraform/modules/storage/variables.tf`)
| Name | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `project_id` | `string` | N/A (Required) | The GCP Project ID. |
| `zone` | `string` | `"us-central1-a"` | GCP Zone where the persistent disk is provisioned. |
| `disk_name` | `string` | `"openclaw-data"` | Name of the GCP Persistent Disk. |
| `disk_type` | `string` | `"pd-ssd"` | Disk type (`pd-ssd`, `pd-balanced`, `pd-standard`). |
| `disk_size_gb` | `number` | `20` | Size of the persistent disk in gigabytes. |
| `labels` | `map(string)` | `{ environment = "production", app = "openclaw" }` | Key-value labels applied to the disk. |

### 2. Outputs (`terraform/modules/storage/outputs.tf`)
| Name | Description |
| :--- | :--- |
| `disk_id` | The unique ID of the provisioned GCP persistent disk. |
| `disk_name` | The name of the provisioned persistent disk. |
| `disk_self_link` | The self-link URL of the persistent disk. |
| `disk_size_gb` | The allocated size of the persistent disk in gigabytes. |

### 3. Resource Definitions (`terraform/modules/storage/main.tf`)
- `google_compute_disk.openclaw_data`: Standalone persistent disk definition with explicit `type`, `size`, `zone`, `labels`, and `description`.

---

## Edge Cases & Failure Modes
- **Zone Mismatch**: Provisioning the persistent disk in a zone different from the compute instance will fail during instance disk attachment. The disk module zone must match the VM zone.
- **Accidental Deletion**: Running `terraform destroy` without snapshotting could erase SQLite data. Lifecycle rules and operational snapshots protect against accidental loss.

---

## Dependencies
- GCP Compute Engine API (`compute.googleapis.com`) enabled.
- `roles/compute.storageAdmin` or `roles/compute.admin` IAM permissions.

---

## Success Criteria & Validation
- `terraform fmt -check` and `terraform validate` inside `terraform/modules/storage` pass without errors.
- Module exports `disk_name`, `disk_id`, and `disk_self_link` for consumption by `modules/compute`.
