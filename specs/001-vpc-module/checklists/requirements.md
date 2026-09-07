# Quality Checklist: VPC & Networking Module Requirements

- [x] **Custom VPC Definition**: `google_compute_network` is defined with `auto_create_subnetworks = false`.
- [x] **Private Subnet Definition**: `google_compute_subnetwork` is defined with configurable `ip_cidr_range` defaulting to `10.0.1.0/24`.
- [x] **Private Google Access**: `private_ip_google_access = true` is explicitly enabled on the subnetwork.
- [x] **Cloud Router**: `google_compute_router` is defined in the target region and attached to the VPC.
- [x] **Cloud NAT Gateway**: `google_compute_router_nat` is defined with `nat_ip_allocate_option = "AUTO_ONLY"` and `source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"`.
- [x] **Variable Declarations**: All variables (`project_id`, `region`, `network_name`, `subnet_name`, `subnet_cidr`) have explicit type constraints and descriptive docstrings.
- [x] **Module Outputs**: Export `network_id`, `network_name`, `network_self_link`, `subnet_id`, `subnet_name`, `subnet_self_link`.
- [x] **HCL Formatting & Validation**: HCL files pass `terraform fmt -check` and `terraform validate`.
