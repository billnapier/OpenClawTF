# Research: Guardian CI/CD Automation

## Technology Choices & Rationale
- **`abcxyz/guardian`**: Google's CLI tool designed specifically for secure Terraform plan/apply execution in GitHub Actions with state locking, comment formatting, and policy enforcement.
- **Workload Identity Federation (WIF)**: Eliminates long-lived service account key JSON files. `google-github-actions/auth` exchanges GitHub OIDC tokens for short-lived GCP OAuth tokens.
- **Container Build in CI**: Using `google-github-actions/setup-gcloud` and `docker` CLI in GitHub Actions ensures newly built container images are automatically pushed to Artifact Registry on `main` branch merges.
