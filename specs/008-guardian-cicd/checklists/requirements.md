# Quality Checklist: Guardian CI/CD Automation Requirements

- [x] **PR Plan Workflow (`.github/workflows/terraform-plan.yml`)**: Triggered on pull requests modifying `terraform/**` or `docker/**`.
- [x] **Merge Deploy Workflow (`.github/workflows/deploy.yml`)**: Triggered on push to `main` modifying `terraform/**` or `docker/**`.
- [x] **OIDC Workload Identity Federation**: Workflows authenticate via `google-github-actions/auth` using repository variables `GCP_WIF_PROVIDER` and `GCP_SERVICE_ACCOUNT`.
- [x] **Guardian Engine**: Workflows leverage `abcxyz/guardian-setup` and run `guardian terraform plan` / `guardian terraform apply` with `-storage-bucket=${{ vars.GCP_TF_STATE_BUCKET }}`.
- [x] **Artifact Registry Integration**: `deploy.yml` authenticates Docker to GCP Artifact Registry and pushes updated images tagged with `latest`.
- [x] **YAML Schema Validation**: All workflow YAML files pass syntax and schema validation cleanly.
