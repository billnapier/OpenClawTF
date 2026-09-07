# Implementation Plan: Telegram User Whitelist Audit & Admin Management Utility

## Technical Approach & Architecture

To streamline access control for OpenClaw administrators, we will author `scripts/manage_whitelist.sh`. This script interacts directly with GCP Secret Manager's `telegram-allowed-user-ids` secret payload (stored as comma-separated numeric IDs).

Supported commands:
- `list`: Displays currently allowed Telegram User IDs and secret version info.
- `add <ID>`: Validates numeric ID format, checks for duplicates, appends ID, and writes a new payload version to GCP Secret Manager.
- `remove <ID>`: Validates numeric ID format, removes ID from comma-separated payload, writes a new version to GCP Secret Manager.
- `audit`: Validates format of all whitelisted IDs and prints audit summary.

---

## File Modifications & Artifacts

### 1. `scripts/manage_whitelist.sh`
- Executable bash script implementing CLI argument parsing (`list`, `add`, `remove`, `audit`, `--help`).
- Uses `gcloud secrets versions access` to read payload and `gcloud secrets versions add` to update payload.
- Validates numeric string regex `^[0-9]+$`.
- Provides fallback / mock mode when `gcloud` is not installed or when testing locally.

---

## Verification Plan
1. Test script help output: `./scripts/manage_whitelist.sh --help`
2. Test numeric validation failure: `./scripts/manage_whitelist.sh add invalid_id` (expect returncode 1)
3. Run syntax validation with `bash -n scripts/manage_whitelist.sh`.
