# Implementation Plan: Guardian CI/CD Automation Setup

## Architecture Overview
This plan defines the setup for GitOps CI/CD automation workflows using Google `abcxyz/guardian` and WIF keyless authentication:
1. **PR Plan Workflow (`.github/workflows/terraform-plan.yml`)**: Triggered on pull requests modifying `terraform/**` or `docker/**`. Uses WIF for keyless GCP authentication, executes `guardian terraform plan`, and comments plan diffs on PRs.
2. **Merge Deploy Workflow (`.github/workflows/deploy.yml`)**: Triggered on merges to `main`. Uses WIF, executes `guardian terraform apply`, builds/pushes Docker images to Artifact Registry, and updates GCE compute instance metadata.

## Technical Components
- **`.github/workflows/terraform-plan.yml`**: GitHub Actions YAML for PR planning.
- **`.github/workflows/deploy.yml`**: GitHub Actions YAML for merge deployment.

## Verification & Testing Strategy
1. YAML syntax and GitHub Actions schema validation using `python3 -c "import yaml"` or `actionlint`.
2. Verify all secrets/variables (`GCP_WIF_PROVIDER`, `GCP_SERVICE_ACCOUNT`, `GCP_TF_STATE_BUCKET`, `GCP_PROJECT_ID`, `GCP_REGION`) are referenced correctly.
