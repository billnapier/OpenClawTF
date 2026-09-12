#!/usr/bin/env bash
set -eo pipefail

echo "[ENTRYPOINT] Initializing OpenClaw Runtime Environment..."

PROJECT_ID="${GCP_PROJECT_ID:-$(curl -s -H 'Metadata-Flavor: Google' 'http://metadata.google.internal/computeMetadata/v1/project/project-id' 2>/dev/null || echo "")}"

# Helper to fetch secret from GCP Secret Manager via gcloud / ADC
fetch_secret() {
  local secret_name="$1"
  local max_retries=3
  local count=0
  local backoff=2
  local value=""

  local project_args=()
  if [ -n "$PROJECT_ID" ]; then
    project_args=(--project="$PROJECT_ID")
  fi

  while [ $count -lt $max_retries ]; do
    if value=$(gcloud secrets versions access latest --secret="$secret_name" "${project_args[@]}" 2>/dev/null); then
      echo "$value"
      return 0
    fi
    count=$((count + 1))
    echo "[ENTRYPOINT WARNING] Failed to fetch secret '$secret_name' (Attempt $count/$max_retries). Retrying in ${backoff}s..." >&2
    sleep $backoff
    backoff=$((backoff * 2 + 1))
  done

  echo "[ENTRYPOINT ERROR] Unable to resolve secret '$secret_name' after $max_retries attempts." >&2
  return 1
}

# Fetch required secrets if not already populated in environment
if [ -z "$GEMINI_API_KEY" ]; then
  GEMINI_API_KEY=$(fetch_secret "gemini-api-key" || fetch_secret "openclaw-gemini-api-key" || true)
  export GEMINI_API_KEY
fi

if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
  TELEGRAM_BOT_TOKEN=$(fetch_secret "telegram-bot-token" || fetch_secret "openclaw-telegram-bot-token" || true)
  export TELEGRAM_BOT_TOKEN
fi

if [ -z "$TELEGRAM_ALLOWED_USER_IDS" ]; then
  TELEGRAM_ALLOWED_USER_IDS=$(fetch_secret "telegram-allowed-user-ids" || fetch_secret "openclaw-telegram-allowed-user-ids" || true)
  export TELEGRAM_ALLOWED_USER_IDS
fi

# --- Google Workspace (`gog`) configuration (Spec 025) ---
export GOG_KEYRING_BACKEND="file"
export GOG_HOME="${GOG_HOME:-/mnt/disks/openclaw-data/gogcli}"

if [ -z "$GOG_KEYRING_PASSWORD" ]; then
  GOG_KEYRING_PASSWORD=$(fetch_secret "gog-keyring-password" || true)
  export GOG_KEYRING_PASSWORD
fi

# GOG_ACCOUNT isn't sensitive, but Secret Manager is the only config-delivery
# path this container has (docker run passes no -e flags at all), so it's
# fetched the same way as every other value here.
if [ -z "$GOG_ACCOUNT" ]; then
  GOG_ACCOUNT=$(fetch_secret "gog-account" || true)
  export GOG_ACCOUNT
fi

mkdir -p "$GOG_HOME"

if command -v gog >/dev/null 2>&1; then
  if ! gog auth doctor --check --no-input >/tmp/gog-auth-doctor.log 2>&1; then
    echo "[ENTRYPOINT WARNING] 'gog auth doctor --check' failed — Google Workspace tools may be unavailable until re-authenticated. See docs/Quickstart.md." >&2
    cat /tmp/gog-auth-doctor.log >&2 || true
  else
    echo "[ENTRYPOINT] gog auth doctor check passed."
  fi
else
  echo "[ENTRYPOINT WARNING] 'gog' binary not found on PATH — Google Workspace tools will be unavailable." >&2
fi

# Ensure data directory exists on persistent disk mount
DATA_DIR="${DATA_DIR:-/mnt/disks/openclaw-data}"
mkdir -p "$DATA_DIR"

# Signal handling for graceful shutdown
cleanup() {
  echo "[ENTRYPOINT] Caught SIGTERM/SIGINT signal. Initiating graceful shutdown..."
  if [ -n "$APP_PID" ]; then
    echo "[ENTRYPOINT] Sending SIGTERM to application process (PID $APP_PID)..."
    kill -TERM "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
  echo "[ENTRYPOINT] Graceful shutdown completed. Exiting."
  exit 0
}

trap cleanup SIGTERM SIGINT

echo "[ENTRYPOINT] Starting OpenClaw Services..."

# Execute main application process (or command passed to docker container)
if [ "$#" -gt 0 ]; then
  "$@" &
  APP_PID=$!
else
  echo "[ENTRYPOINT] Launching OpenClaw Control UI Web Gateway..."
  python3 /app/scripts/control_gateway.py &
  CONTROL_PID=$!

  echo "[ENTRYPOINT] Launching OpenClaw Telegram Bot Daemon..."
  python3 /app/scripts/telegram_daemon.py &
  APP_PID=$!
fi

wait "$APP_PID"

