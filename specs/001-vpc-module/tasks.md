# Tasks: VPC & Networking Module

## Phase 1: Module Foundation & Provider Configuration
- [x] Task 1.1: Create `terraform/modules/vpc/versions.tf` specifying required Terraform version (`>= 1.5.0`) and Google provider (`hashicorp/google >= 5.0.0, < 7.0.0`).
- [x] Task 1.2: Create `terraform/modules/vpc/variables.tf` declaring `project_id`, `region`, `network_name`, `subnet_name`, and `subnet_cidr` with regex validation.

## Phase 2: Core VPC & Subnetwork Provisioning (User Story 1)
- [x] Task 2.1: Implement `google_compute_network` resource in `terraform/modules/vpc/main.tf` with `auto_create_subnetworks = false`.
- [x] Task 2.2: Implement `google_compute_subnetwork` resource in `terraform/modules/vpc/main.tf` using variable `subnet_cidr` and `private_ip_google_access = true`.

## Phase 3: Cloud Router & Cloud NAT Egress (User Story 2)
- [x] Task 3.1: Implement `google_compute_router` resource in `terraform/modules/vpc/main.tf` bound to the VPC network and region.
- [x] Task 3.2: Implement `google_compute_router_nat` resource in `terraform/modules/vpc/main.tf` with `nat_ip_allocate_option = "AUTO_ONLY"` and `source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"`.

## Phase 4: Output Declarations & Verification
- [x] Task 4.1: Create `terraform/modules/vpc/outputs.tf` exporting network and subnet identifiers, names, and self-links.
- [x] Task 4.2: Execute `terraform fmt` and `terraform validate` to verify HCL syntax and schema compliance.
