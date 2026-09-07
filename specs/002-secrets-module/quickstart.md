# Quickstart: Secret Manager & IAM Module

## Module Invocation Example

```hcl
module "secrets" {
  source = "./modules/secrets"

  project_id            = "my-gcp-project-id"
  service_account_email = "openclaw-sa@my-gcp-project-id.iam.gserviceaccount.com"
  secret_prefix         = "openclaw-"
}
```

## Validation & Testing

```bash
cd terraform/modules/secrets
terraform init -backend=false
terraform fmt -check
terraform validate
```
