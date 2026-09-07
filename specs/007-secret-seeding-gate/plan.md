# Implementation Plan: Secret Payload Seeding Gate

## Architecture Overview
This plan defines the secret seeding gate automation to prevent GCE container startup crashes:
1. **Seeding Script (`scripts/seed_secrets.sh`)**: Script that idempotently populates secret payloads (`openclaw-gemini-api-key`, `openclaw-telegram-bot-token`, `openclaw-telegram-allowed-user-ids`) into GCP Secret Manager using `gcloud`.
2. **Pre-flight Gate (`scripts/verify_secret_versions.sh`)**: Pre-flight assertion script verifying that active versions exist for all 3 secrets in GCP Secret Manager prior to terraform compute deployment.

## Technical Components
- **`scripts/seed_secrets.sh`**: Takes environment variables or CLI flags (`PROJECT_ID`, `GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `ALLOWED_USER_IDS`), checks existing payload, and adds secret versions idempotently.
- **`scripts/verify_secret_versions.sh`**: Inspects secret version status for target project and returns 0 if valid, or exit code 1 with actionable errors if unseeded.

## Verification & Testing Strategy
1. Shell script syntax validation with `bash -n scripts/seed_secrets.sh` and `bash -n scripts/verify_secret_versions.sh`.
2. Verify executable permissions on both scripts (`chmod +x`).
