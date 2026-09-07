#!/usr/bin/env bash
set -eo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || true)}"
GEMINI_API_KEY="${GEMINI_API_KEY:-}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
ALLOWED_USER_IDS="${ALLOWED_USER_IDS:-}"

if [ -z "$PROJECT_ID" ]; then
  echo "[ERROR] GCP Project ID is missing. Set GCP_PROJECT_ID environment variable." >&2
  exit 1
fi

echo "[SEED_SECRETS] Starting idempotent secret payload seeding for project '$PROJECT_ID'..."

# Validate numeric CSV format for ALLOWED_USER_IDS if provided
if [ -n "$ALLOWED_USER_IDS" ]; then
  if ! [[ "$ALLOWED_USER_IDS" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
    echo "[ERROR] ALLOWED_USER_IDS must be a comma-separated list of numeric IDs (e.g. 12345678,98765432)." >&2
    exit 1
  fi
fi

seed_secret_payload() {
  local secret_id="$1"
  local secret_value="$2"

  if [ -z "$secret_value" ]; then
    echo "[SKIP] No payload provided for '$secret_id'. Skipping seeding."
    return 0
  fi

  echo "[SEEDING] Processing secret '$secret_id'..."
  
  # Check if secret resource exists
  if ! gcloud secrets describe "$secret_id" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "[SEEDING] Secret '$secret_id' container does not exist yet. It will be created by Terraform." >&2
    return 0
  fi

  # Check if an active version already exists
  local latest_version
  latest_version=$(gcloud secrets versions list "$secret_id" --project="$PROJECT_ID" --filter="STATE=ENABLED" --format="value(name)" --limit=1 2>/dev/null || true)

  if [ -n "$latest_version" ]; then
    local current_val
    current_val=$(gcloud secrets versions access "$latest_version" --secret="$secret_id" --project="$PROJECT_ID" 2>/dev/null || true)
    if [ "$current_val" = "$secret_value" ]; then
      echo "[OK] Secret '$secret_id' latest payload already matches. Skipping new version creation."
      return 0
    fi
  fi

  echo "[UPDATE] Adding new payload version to secret '$secret_id'..."
  echo -n "$secret_value" | gcloud secrets versions add "$secret_id" --project="$PROJECT_ID" --data-file=- >/dev/null
  echo "[SUCCESS] Secret '$secret_id' version seeded successfully."
}

seed_secret_payload "openclaw-gemini-api-key" "$GEMINI_API_KEY"
seed_secret_payload "openclaw-telegram-bot-token" "$TELEGRAM_BOT_TOKEN"
seed_secret_payload "openclaw-telegram-allowed-user-ids" "$ALLOWED_USER_IDS"

echo "[SEED_SECRETS] Seeding completed."
