# Data Model & Infrastructure Resource Mapping: VPC Module

## Resource Relationship Hierarchy

```
google_compute_network (vpc)
 └── google_compute_subnetwork (subnet) [private_ip_google_access = true]
 └── google_compute_router (router)
      └── google_compute_router_nat (nat) [nat_ip_allocate_option = AUTO_ONLY]
```

## Input Schema (`variables.tf`)

| Field Name | Type | Required / Default | Constraints & Description |
| :--- | :--- | :--- | :--- |
| `project_id` | `string` | **Required** | GCP project ID hosting the network resources. |
| `region` | `string` | `"us-central1"` | GCP region for subnetwork, router, and Cloud NAT. |
| `network_name` | `string` | `"openclaw-vpc"` | Resource name for custom VPC network. |
| `subnet_name` | `string` | `"openclaw-subnet"` | Resource name for private subnetwork. |
| `subnet_cidr` | `string` | `"10.0.1.0/24"` | Valid IPv4 CIDR range for subnetwork. |

## Output Schema (`outputs.tf`)

| Field Name | Type | Source Resource Attribute | Description |
| :--- | :--- | :--- | :--- |
| `network_id` | `string` | `google_compute_network.vpc.id` | VPC network resource identifier. |
| `network_name` | `string` | `google_compute_network.vpc.name` | VPC network name. |
| `network_self_link` | `string` | `google_compute_network.vpc.self_link` | Fully qualified VPC self-link URL. |
| `subnet_id` | `string` | `google_compute_subnetwork.subnet.id` | Subnetwork resource identifier. |
| `subnet_name` | `string` | `google_compute_subnetwork.subnet.name` | Subnetwork resource name. |
| `subnet_self_link` | `string` | `google_compute_subnetwork.subnet.self_link` | Fully qualified subnetwork self-link URL. |
