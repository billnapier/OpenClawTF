# Research & Technical Decisions: VPC & Networking Module

## 1. Overview & Architecture Selection
To achieve an isolated network perimeter for OpenClaw compute workloads while allowing outbound communication to Telegram servers (`api.telegram.org`) and Google Gemini endpoints (`generativelanguage.googleapis.com`), we employ Google Cloud Platform's VPC architecture:
- **Custom VPC Network (`google_compute_network`)**: Configured with `auto_create_subnetworks = false` to enforce explicit subnet management and prevent default public subnets from being created.
- **Private Subnetwork (`google_compute_subnetwork`)**: Created in the target region with `private_ip_google_access = true` enabling compute instances without public IPs to reach Google Cloud APIs directly via internal routing.
- **Cloud Router (`google_compute_router`)**: Provides control plane for routing and NAT dynamic mapping within the VPC region.
- **Cloud NAT (`google_compute_router_nat`)**: Allocates automated egress IPs (`AUTO_ONLY`) for outbound traffic from all primary subnetwork IP ranges, keeping internal VM instances hidden from direct inbound access.

## 2. GCP Terraform Provider & Versioning
- **Provider**: `hashicorp/google`
- **Version Constraint**: `>= 5.0.0, < 7.0.0`
- **Terraform Version**: `>= 1.5.0`

## 3. Variable Validation Strategy
- `subnet_cidr`: Uses regex validation `^([0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$` to ensure valid IPv4 CIDR notation (e.g. `10.0.1.0/24`).

## 4. Key Security & Compliance Rules
- No external IP allocation (`nat_ip_allocate_option = "AUTO_ONLY"`).
- Direct inbound access blocked by default (custom VPC without default firewall rules allows default ingress deny).
