# Data Model: Storage Module

## Resource Schema

### `google_compute_disk.openclaw_data`
| Field | Type | Description |
| :--- | :--- | :--- |
| `name` | `string` | Disk name (`var.disk_name`) |
| `type` | `string` | GCP Disk type (`var.disk_type`) |
| `size` | `number` | Size in GB (`var.disk_size_gb`) |
| `zone` | `string` | GCP Zonal placement (`var.zone`) |
| `labels` | `map(string)` | Tagging metadata |
