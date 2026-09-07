#!/bin/bash
set -euo pipefail

echo "=========================================="
echo " OpenClaw WIF & Infrastructure Verification "
echo "=========================================="

PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -z "$PROJECT_ID" ]; then
  echo "❌ FAIL: No GCP project configured in gcloud CLI."
  exit 1
fi
echo "✓ GCP Project ID: $PROJECT_ID"

# Check GCP APIs
REQUIRED_APIS=(
  "compute.googleapis.com"
  "secretmanager.googleapis.com"
  "iam.googleapis.com"
  "iamcredentials.googleapis.com"
  "artifactregistry.googleapis.com"
  "cloudresourcemanager.googleapis.com"
  "sts.googleapis.com"
)

echo "Checking GCP APIs..."
ENABLED_SERVICES=$(gcloud services list --enabled --format="value(config.name)")
for api in "${REQUIRED_APIS[@]}"; do
  if echo "$ENABLED_SERVICES" | grep -q "$api"; then
    echo "  ✓ API Enabled: $api"
  else
    echo "  ❌ MISSING API: $api"
  fi
done

# Check Remote State Bucket
BUCKET_NAME="${PROJECT_ID}-tfstate"
if gcloud storage buckets describe "gs://${BUCKET_NAME}" &>/dev/null; then
  echo "✓ GCS State Bucket Exists: gs://${BUCKET_NAME}"
else
  echo "  ❌ MISSING Bucket: gs://${BUCKET_NAME}"
fi

# Check Secrets
REQUIRED_SECRETS=("gemini-api-key" "telegram-bot-token" "telegram-allowed-user-ids")
echo "Checking GCP Secret Manager secrets..."
for secret in "${REQUIRED_SECRETS[@]}"; do
  if gcloud secrets describe "$secret" &>/dev/null; then
    echo "  ✓ Secret Exists: $secret"
  else
    echo "  ❌ MISSING Secret: $secret"
  fi
done

echo "=========================================="
echo " Verification Complete "
echo "=========================================="
