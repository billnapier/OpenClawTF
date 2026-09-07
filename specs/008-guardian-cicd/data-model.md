# Data Model: Guardian CI/CD Automation

## Required GitHub Variables & Secrets
- `${{ vars.GCP_PROJECT_ID }}`: GCP Project ID.
- `${{ vars.GCP_REGION }}`: GCP Region (e.g. `us-central1`).
- `${{ vars.GCP_WIF_PROVIDER }}`: Full resource name of Workload Identity Provider.
- `${{ vars.GCP_SERVICE_ACCOUNT }}`: Email of deployment Service Account.
- `${{ vars.GCP_TF_STATE_BUCKET }}`: GCS Bucket name for Terraform remote state.

## Workflow Triggers
- `pull_request`: targeting `main`, path filters `['terraform/**', 'docker/**', '.github/workflows/**']`.
- `push`: to `main`, path filters `['terraform/**', 'docker/**', '.github/workflows/**']`.
