# Quality Checklist: Compute Integration & Boot Script Module Requirements

- [ ] **Container-Optimized OS**: Boot disk specifies image family `cos-cloud/cos-stable`.
- [ ] **Private Subnet Attachment**: `network_interface` references `var.subnetwork_id` and excludes `access_config` block (no public IP).
- [ ] **Persistent Disk Attachment**: `attached_disk` references `var.persistent_disk_name` with `device_name = "openclaw-data"` and `mode = "READ_WRITE"`.
- [ ] **Service Account Assignment**: `service_account` specifies `email = var.service_account_email` and `scopes = ["cloud-platform"]`.
- [ ] **Startup Script Injection**: `metadata_startup_script` correctly populates bootstrap script template.
- [ ] **Variable Declarations**: `project_id`, `zone`, `instance_name`, `machine_type`, `subnetwork_id`, `persistent_disk_name`, `service_account_email`, `container_image` defined with type constraints.
- [ ] **Module Outputs**: Export `instance_id`, `instance_name`, `instance_self_link`, `internal_ip`.
- [ ] **HCL Formatting & Validation**: HCL files pass `terraform fmt -check` and `terraform validate`.
