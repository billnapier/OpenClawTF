# Data Model: Quickstart Skill & Bootstrap Verification

## Environment Variables & Secret Specifications

### Configured Variables (`gh variable set`)
- `GCP_PROJECT_ID`: GCP Project ID
- `GCP_REGION`: Target region (e.g. `us-central1`)
- `GCP_ZONE`: Target zone (e.g. `us-central1-a`)
- `GCP_TF_STATE_BUCKET`: Remote state GCS bucket name (`${GCP_PROJECT_ID}-tfstate`)
- `GCP_WORKLOAD_IDENTITY_PROVIDER`: Full provider path (`projects/.../locations/global/workloadIdentityPools/...`)
- `GCP_SERVICE_ACCOUNT`: Terraform deployer SA email

### Configured Secrets (`gh secret set`)
- `GEMINI_API_KEY`: API key for Gemini models
- `TELEGRAM_BOT_TOKEN`: Telegram bot token
- `ALLOWED_USER_IDS`: Comma-separated allowed user IDs
