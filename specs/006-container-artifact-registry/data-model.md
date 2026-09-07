# Data Model: Artifact Registry & Container Runtime

## Terraform Module Schema (`artifact_registry`)
- `repository_id` (string): Unique identifier for the repository (default: `"openclaw"`).
- `format` (string): Set to `"DOCKER"`.
- `location` (string): GCP region (e.g. `us-central1`).
- `description` (string): Optional repository description.

## Environment Variables schema (`entrypoint.sh`)
- `GEMINI_API_KEY` (string): Injected secret.
- `TELEGRAM_BOT_TOKEN` (string): Injected secret.
- `TELEGRAM_ALLOWED_USER_IDS` (string): Injected secret.
