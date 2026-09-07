# Quickstart: Secret Seeding Gate

```bash
# Verify shell syntax
bash -n scripts/seed_secrets.sh
bash -n scripts/verify_secret_versions.sh

# Run seeding script (dry-run or with environment variables)
GCP_PROJECT_ID="your-project-id" GEMINI_API_KEY="test" TELEGRAM_BOT_TOKEN="test" ALLOWED_USER_IDS="12345678" ./scripts/seed_secrets.sh

# Run verification gate
GCP_PROJECT_ID="your-project-id" ./scripts/verify_secret_versions.sh
```
