# Data Model: Compute Module

## Resource Schema

### `google_compute_instance.openclaw_vm`
| Property | Value / Source | Description |
| :--- | :--- | :--- |
| `name` | `var.instance_name` | Name of VM instance |
| `machine_type` | `var.machine_type` | Instance hardware profile |
| `zone` | `var.zone` | GCP Zonal placement |
| `boot_disk` | `cos-cloud/cos-stable` | OS Image |
| `attached_disk` | `var.persistent_disk_name` | Persistent data disk |
| `network_interface` | `var.subnetwork_id` | Private Subnet link |
| `service_account` | `var.service_account_email` | Identity with `cloud-platform` scope |
| `metadata.startup-script` | Template render | Automated bootstrap script |
