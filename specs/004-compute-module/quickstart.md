# Quickstart: Compute Module

## Usage Example

```hcl
module "compute" {
  source = "./modules/compute"

  project_id            = "my-gcp-project-id"
  zone                  = "us-central1-a"
  instance_name         = "openclaw-vm"
  machine_type          = "e2-standard-2"
  subnetwork_id         = module.vpc.subnet_id
  persistent_disk_name = module.storage.disk_name
  service_account_email = "openclaw-sa@my-gcp-project-id.iam.gserviceaccount.com"
  container_image       = "us-central1-docker.pkg.dev/my-gcp-project-id/openclaw/agent:latest"
}
```

## Validation & Testing

```bash
cd terraform/modules/compute
terraform init -backend=false
terraform fmt -check
terraform validate
```
