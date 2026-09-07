# Quickstart: Containerization & Artifact Registry

```bash
# Initialize and validate Artifact Registry terraform module
cd terraform/modules/artifact_registry
terraform init -backend=false
terraform validate
terraform fmt -check

# Test entrypoint script syntax
bash -n ../../../docker/entrypoint.sh
```
