# Quality Checklist: Persistent Disk Storage Module Requirements

- [ ] **Persistent Disk Definition**: `google_compute_disk` defined with configurable `name`, `type`, `size`, and `zone`.
- [ ] **Default Parameters**: Default `disk_type = "pd-ssd"`, default `disk_size_gb = 20`.
- [ ] **Resource Labeling**: Labels applied including `environment` and `app = "openclaw"`.
- [ ] **Zone Alignment**: Module accepts explicit `zone` variable matching target VM compute zone.
- [ ] **Variable Declarations**: `project_id`, `zone`, `disk_name`, `disk_type`, `disk_size_gb`, `labels` defined with types and validation.
- [ ] **Module Outputs**: Export `disk_id`, `disk_name`, `disk_self_link`, `disk_size_gb`.
- [ ] **HCL Formatting & Validation**: HCL files pass `terraform fmt -check` and `terraform validate`.
