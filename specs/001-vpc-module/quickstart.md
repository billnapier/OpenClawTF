# Quickstart Guide: VPC & Networking Module

## Prerequisites
- Terraform `>= 1.5.0` installed locally.
- Google Cloud SDK (`gcloud`) authenticated with target GCP project.

## Usage Example

Add the module declaration to your Terraform configuration:

```hcl
module "vpc" {
  source = "./terraform/modules/vpc"

  project_id   = "your-gcp-project-id"
  region       = "us-central1"
  network_name = "openclaw-vpc"
  subnet_name  = "openclaw-subnet"
  subnet_cidr  = "10.0.1.0/24"
}
```

## Validation Instructions

Navigate to the module directory and validate syntax:

```bash
cd terraform/modules/vpc
terraform init -backend=false
terraform fmt -check
terraform validate
```
