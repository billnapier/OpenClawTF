# Quality Checklist: Containerization & Artifact Registry Requirements

- [x] **Artifact Registry Module**: `google_artifact_registry_repository` defined with `format = "DOCKER"` and configurable repository ID (default `"openclaw"`).
- [x] **Module Variables & Outputs**: Module accepts `project_id`, `region`, `repository_id` and exports `repository_url`.
- [x] **Dockerfile Optimization**: Multi-stage build producing lean container image without baked-in secrets or credentials.
- [x] **Runtime Secret Fetching**: `entrypoint.sh` dynamically fetches `gemini-api-key`, `telegram-bot-token`, and `telegram-allowed-user-ids` using Application Default Credentials (ADC).
- [x] **Graceful Signal Handling**: `entrypoint.sh` traps `SIGTERM` and `SIGINT` signals to flush SQLite buffers on `/mnt/disks/openclaw-data` before container termination.
- [x] **Exponential Backoff**: Entrypoint retries secret fetching and API long-polling on initial startup failure (2s, 5s, 10s backoff).
- [x] **HCL Formatting & Validation**: `terraform fmt -check` and `terraform validate` pass for `terraform/modules/artifact_registry`.
