#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# OpenClaw Telegram Whitelist Admin & Audit Utility
# ==============================================================================

PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || echo "mock-project-id")}"
SECRET_NAME="${SECRET_NAME:-telegram-allowed-user-ids}"

usage() {
  cat <<EOF
Usage: $0 <command> [args]

Commands:
  list                 List currently whitelisted Telegram User IDs
  add <USER_ID>        Add a numeric Telegram User ID to the whitelist
  remove <USER_ID>     Remove a numeric Telegram User ID from the whitelist
  audit                Audit current whitelist format and integrity
  --help               Display this help message
EOF
  exit 1
}

validate_user_id() {
  local id="$1"
  if [[ ! "$id" =~ ^[0-9]+$ ]]; then
    echo "Error: Telegram User ID must be a numeric string." >&2
    exit 1
  fi
}

get_current_payload() {
  if command -v gcloud &>/dev/null && gcloud secrets describe "${SECRET_NAME}" --project="${PROJECT_ID}" &>/dev/null; then
    gcloud secrets versions access latest --secret="${SECRET_NAME}" --project="${PROJECT_ID}" 2>/dev/null || echo ""
  else
    echo "123456789,987654321"
  fi
}

update_payload() {
  local new_payload="$1"
  if command -v gcloud &>/dev/null && gcloud secrets describe "${SECRET_NAME}" --project="${PROJECT_ID}" &>/dev/null; then
    echo -n "${new_payload}" | gcloud secrets versions add "${SECRET_NAME}" --data-file=- --project="${PROJECT_ID}" >/dev/null
    echo "[✓] Successfully updated GCP Secret '${SECRET_NAME}' version in project '${PROJECT_ID}'."
  else
    echo "[i] [DRY-RUN / MOCK MODE] Updated Secret '${SECRET_NAME}' payload to: ${new_payload}"
  fi
}

cmd_list() {
  echo "======================================================================"
  echo "         OpenClaw Telegram User Whitelist Inventory                   "
  echo "======================================================================"
  echo "Project ID  : ${PROJECT_ID}"
  echo "Secret Name : ${SECRET_NAME}"
  echo "----------------------------------------------------------------------"
  
  local payload
  payload=$(get_current_payload)

  if [[ -z "$payload" ]]; then
    echo "[!] Whitelist is currently empty."
    return
  fi

  echo "Allowed Telegram User IDs:"
  IFS=',' read -ra ADDR <<< "$payload"
  for id in "${ADDR[@]}"; do
    local clean_id
    clean_id=$(echo "$id" | xargs)
    if [[ -n "$clean_id" ]]; then
      echo "  - ${clean_id}"
    fi
  done
  echo "----------------------------------------------------------------------"
  echo "Total Users: ${#ADDR[@]}"
  echo "======================================================================"
}

cmd_add() {
  local new_id="${1:-}"
  if [[ -z "$new_id" ]]; then
    echo "Error: Missing required <USER_ID> argument." >&2
    usage
  fi
  validate_user_id "$new_id"

  local payload
  payload=$(get_current_payload)

  IFS=',' read -ra ADDR <<< "$payload"
  for id in "${ADDR[@]}"; do
    if [[ "$(echo "$id" | xargs)" == "$new_id" ]]; then
      echo "[!] User ID '${new_id}' is already present in the whitelist. No changes made."
      exit 0
    fi
  done

  local updated_payload
  if [[ -z "$payload" ]]; then
    updated_payload="$new_id"
  else
    updated_payload="${payload},${new_id}"
  fi

  update_payload "$updated_payload"
  echo "[✓] Successfully added Telegram User ID '${new_id}' to whitelist."
}

cmd_remove() {
  local target_id="${1:-}"
  if [[ -z "$target_id" ]]; then
    echo "Error: Missing required <USER_ID> argument." >&2
    usage
  fi
  validate_user_id "$target_id"

  local payload
  payload=$(get_current_payload)

  if [[ -z "$payload" ]]; then
    echo "[!] Whitelist is currently empty. No changes made."
    exit 0
  fi

  local new_list=()
  local found=0
  IFS=',' read -ra ADDR <<< "$payload"
  for id in "${ADDR[@]}"; do
    local clean_id
    clean_id=$(echo "$id" | xargs)
    if [[ "$clean_id" == "$target_id" ]]; then
      found=1
    elif [[ -n "$clean_id" ]]; then
      new_list+=("$clean_id")
    fi
  done

  if [[ $found -eq 0 ]]; then
    echo "[!] User ID '${target_id}' was not found in the whitelist. No changes made."
    exit 0
  fi

  local updated_payload
  updated_payload=$(IFS=, ; echo "${new_list[*]}")

  update_payload "$updated_payload"
  echo "[✓] Successfully removed Telegram User ID '${target_id}' from whitelist."
}

cmd_audit() {
  echo "======================================================================"
  echo "            OpenClaw Telegram Access Whitelist Audit                  "
  echo "======================================================================"
  local payload
  payload=$(get_current_payload)

  if [[ -z "$payload" ]]; then
    echo "[!] Whitelist payload is empty."
    exit 0
  fi

  local invalid_count=0
  local valid_count=0
  IFS=',' read -ra ADDR <<< "$payload"
  for id in "${ADDR[@]}"; do
    local clean_id
    clean_id=$(echo "$id" | xargs)
    if [[ "$clean_id" =~ ^[0-9]+$ ]]; then
      valid_count=$((valid_count + 1))
    else
      echo "[!] INVALID ID FORMAT DETECTED: '${clean_id}'"
      invalid_count=$((invalid_count + 1))
    fi
  done

  echo "Audit Results:"
  echo "  - Valid Numeric IDs : ${valid_count}"
  echo "  - Invalid Formats   : ${invalid_count}"
  echo "----------------------------------------------------------------------"
  if [[ $invalid_count -eq 0 ]]; then
    echo "[✓] AUDIT PASSED: All whitelisted user IDs are strictly numeric."
  else
    echo "[!] AUDIT FAILED: Non-numeric entries found in secret payload."
    exit 1
  fi
  echo "======================================================================"
}

COMMAND="${1:-}"
case "$COMMAND" in
  list)
    cmd_list
    ;;
  add)
    cmd_add "${2:-}"
    ;;
  remove)
    cmd_remove "${2:-}"
    ;;
  audit)
    cmd_audit
    ;;
  --help|-h)
    usage
    ;;
  *)
    echo "Error: Unknown command '${COMMAND}'" >&2
    usage
    ;;
esac
