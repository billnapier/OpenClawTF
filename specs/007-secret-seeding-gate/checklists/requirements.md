# Quality Checklist: Secret Payload Seeding Gate Requirements

- [ ] **Seeding Script (`scripts/seed_secrets.sh`)**: Script accepts secret values and populates Secret Manager versions for `gemini-api-key`, `telegram-bot-token`, and `telegram-allowed-user-ids`.
- [ ] **Numeric Telegram ID Validation**: Seeding script validates that `TELEGRAM_ALLOWED_USER_IDS` is formatted as a comma-separated list of numeric Telegram IDs.
- [ ] **Verification Gate Script (`scripts/verify_secret_versions.sh`)**: Script checks GCP Secret Manager API to assert at least 1 `ENABLED` secret version exists per secret ID.
- [ ] **Pre-Flight Execution**: Verification script exits with status `0` on success and status `1` with actionable remediation logs on failure.
- [ ] **Idempotent Execution**: Running seeding and verification scripts multiple times succeeds without producing errors or duplicate invalid payload states.
