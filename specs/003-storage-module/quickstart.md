# Quickstart: Storage Module

## Usage Example

```hcl
module "storage" {
  source = "./modules/storage"

  project_id   = "my-gcp-project-id"
  zone         = "us-central1-a"
  disk_name    = "openclaw-data"
  disk_type    = "pd-ssd"
  disk_size_gb = 20
}
```

## Validation & Testing

```bash
cd terraform/modules/storage
terraform init -backend=false
terraform fmt -check
terraform validate
```
