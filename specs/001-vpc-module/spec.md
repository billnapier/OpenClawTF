# Feature Specification: VPC & Networking Module

## Feature Overview & Objectives
The goal of this feature is to create a modular, reusable Terraform module (`terraform/modules/vpc`) that provisions a custom Virtual Private Cloud (VPC) network, private subnetwork, Cloud Router, and Cloud NAT gateway on Google Cloud Platform. 

This foundation guarantees that OpenClaw compute workloads operate within an isolated, private network perimeter without public IP exposure on GCE instances, while enabling full outbound HTTPS egress for Telegram long-polling and Google Gemini API communication.

## User Stories & Acceptance Scenarios

### User Story 1: Isolated Network Perimeter
* **As a** Cloud Administrator,
* **I want to** provision a custom VPC network and private subnetwork,
* **So that** OpenClaw instances have no direct inbound access from the public internet.

#### Scenario 1.1: Custom VPC Subnet Creation
* **Given** valid GCP credentials and project configuration,
* **When** `terraform apply` is executed for the `vpc` module,
* **Then** a custom `google_compute_network` with `auto_create_subnetworks = false` is created, along with a `google_compute_subnetwork` using the specified CIDR block (default `10.0.1.0/24`) and `private_ip_google_access = true`.

### User Story 2: Secure Outbound NAT Egress
* **As a** Cloud Administrator,
* **I want** Cloud Router and Cloud NAT automatically provisioned within the VPC,
* **So that** private VM instances can reach external APIs (`api.telegram.org` and `generativelanguage.googleapis.com`) without allocating external public IPs to the VM.

#### Scenario 2.1: Cloud NAT Configuration
* **Given** an existing custom VPC network and subnetwork,
* **When** the `vpc` module is applied,
* **Then** a Cloud Router (`google_compute_router`) and Cloud NAT (`google_compute_router_nat`) are provisioned with `source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"` and `nat_ip_allocate_option = "AUTO_ONLY"`.

---

## Requirements & Functional Specifications

### 1. Inputs & Variables (`terraform/modules/vpc/variables.tf`)
| Name | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `project_id` | `string` | N/A (Required) | The GCP Project ID where network resources are provisioned. |
| `region` | `string` | `"us-central1"` | GCP region for subnetwork and NAT router. |
| `network_name` | `string` | `"openclaw-vpc"` | Name of the custom VPC network. |
| `subnet_name` | `string` | `"openclaw-subnet"` | Name of the private subnetwork. |
| `subnet_cidr` | `string` | `"10.0.1.0/24"` | Primary IPv4 CIDR range for the private subnetwork. |

### 2. Outputs (`terraform/modules/vpc/outputs.tf`)
| Name | Description |
| :--- | :--- |
| `network_id` | The ID of the provisioned VPC network. |
| `network_name` | The name of the provisioned VPC network. |
| `network_self_link` | The self-link URL of the provisioned VPC network. |
| `subnet_id` | The ID of the private subnetwork. |
| `subnet_name` | The name of the private subnetwork. |
| `subnet_self_link` | The self-link URL of the private subnetwork. |

### 3. Resource Definitions (`terraform/modules/vpc/main.tf`)
- `google_compute_network.vpc`: Custom VPC network (`auto_create_subnetworks = false`).
- `google_compute_subnetwork.subnet`: Private subnetwork with `private_ip_google_access = true`.
- `google_compute_router.router`: Cloud Router tied to the VPC network.
- `google_compute_router_nat.nat`: Cloud NAT attached to Cloud Router enabling outbound NAT for all subnets.

---

## Edge Cases & Failure Modes
- **CIDR Overlap**: Attempting to provision subnet CIDRs that collide with existing VPC networks in the project will cause Terraform apply failures. Add explicit validation for IPv4 CIDR syntax.
- **Quota Exceeded**: Exceeding project quotas for Cloud NAT or Routers in the target region will produce GCP API errors.
- **Missing Google Access**: Disabling `private_ip_google_access` breaks direct API access to GCP services via private Google IP ranges.

---

## Dependencies
- GCP Provider configured with valid project ID and authentication credentials.
- `roles/compute.networkAdmin` or equivalent IAM permissions.

---

## Success Criteria & Validation
- Executing `terraform fmt -check` and `terraform validate` inside `terraform/modules/vpc` completes with zero syntax or type errors.
- Module cleanly exports `network_name`, `subnet_name`, and `subnet_self_link` for downstream consumption by compute modules.
