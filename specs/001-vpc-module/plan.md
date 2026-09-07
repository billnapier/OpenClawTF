# Architecture Plan: VPC & Networking Module

## Proposed Architecture
The VPC & Networking module creates a dedicated network perimeter within GCP for OpenClaw components.

### Directory Structure
```
terraform/modules/vpc/
├── main.tf        # Definition of Network, Subnetwork, Router, and NAT resources
├── variables.tf   # Module inputs with types and validations
├── outputs.tf     # Module outputs for downstream module consumption
└── versions.tf    # Required terraform and provider version constraints
```

## Step-by-Step Implementation Strategy

1. **Versions Configuration (`versions.tf`)**:
   - Specify required terraform version `>= 1.5.0`.
   - Specify `google` provider constraint `>= 5.0.0, < 7.0.0`.

2. **Input Variable Specifications (`variables.tf`)**:
   - `project_id`: Required string.
   - `region`: String with default `"us-central1"`.
   - `network_name`: String with default `"openclaw-vpc"`.
   - `subnet_name`: String with default `"openclaw-subnet"`.
   - `subnet_cidr`: String with default `"10.0.1.0/24"` and CIDR regex validation.

3. **Core Network & NAT Resources (`main.tf`)**:
   - `google_compute_network.vpc`: `auto_create_subnetworks = false`.
   - `google_compute_subnetwork.subnet`: Connected to `google_compute_network.vpc.id`, `private_ip_google_access = true`.
   - `google_compute_router.router`: Tied to network and region.
   - `google_compute_router_nat.nat`: Attached to router with `nat_ip_allocate_option = "AUTO_ONLY"` and `source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"`.

4. **Output Definitions (`outputs.tf`)**:
   - Export network IDs, names, self links, and subnet IDs, names, self links.

5. **Validation Plan**:
   - Execute `terraform fmt -check` and `terraform validate` in `terraform/modules/vpc`.
