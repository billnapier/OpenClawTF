#!/usr/bin/env bash
set -eo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || true)}"

if [ -z "$PROJECT_ID" ]; then
  echo "[ERROR] GCP Project ID is missing. Set GCP_PROJECT_ID environment variable." >&2
  exit 1
fi

echo "[PRE-FLIGHT GATE] Verifying required GCP Secret Manager versions for project '$PROJECT_ID'..."

REQUIRED_SECRETS=(
  "gemini-api-key"
  "telegram-bot-token"
  "telegram-allowed-user-ids"
)

FAILED=0

for secret_id in "${REQUIRED_SECRETS[@]}"; do
  echo -n "Checking secret '$secret_id'... "
  
  if ! gcloud secrets describe "$secret_id" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "[FAIL] Secret container '$secret_id' does not exist!"
    FAILED=1
    continue
  fi

  ENABLED_COUNT=$(gcloud secrets versions list "$secret_id" --project="$PROJECT_ID" --filter="STATE=ENABLED" --format="value(name)" 2>/dev/null | wc -l || echo "0")

  if [ "$ENABLED_COUNT" -gt 0 ]; then
    echo "[PASS] $ENABLED_COUNT enabled version(s) present."
  else
    echo "[FAIL] No enabled secret versions found for '$secret_id'!"
    FAILED=1
  fi
done

if [ "$FAILED" -ne 0 ]; then
  echo "" >&2
  echo "[ERROR] Pre-flight secret validation failed! One or more secrets lack active payload versions." >&2
  echo "Remediation: Run 'scripts/seed_secrets.sh' or manually add secret payload versions via GCP Console or gcloud CLI before provisioning compute resources." >&2
  exit 1
fi

echo ""
echo "[PASS] All secret payloads present and enabled."
exit 0
