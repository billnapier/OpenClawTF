---
name: openclaw.bootstrap
description: Automated end-to-end setup of GCP infrastructure, Workload Identity Federation (WIF), GCP secrets, and GitHub repo secrets/variables for OpenClaw.
version: 1.1.0
---

# OpenClaw Onboarding & Infrastructure Bootstrapper

This skill automates the setup of Google Cloud Platform (GCP) infrastructure, GCP Secret Manager payloads, Workload Identity Federation (WIF) OIDC authentication, and GitHub Actions repository secrets/variables for OpenClaw.

Per **Constitution Principle 7**, this skill maintains 100% functional parity with `docs/Quickstart.md`.

---

## Workflow Steps

### Step 1: Context Detection & Bulk Confirmation
1. Detect active GCP project ID via `gcloud config get-value project`.
2. Detect remote GitHub repository name via `git remote get-url origin`.
3. Set sensible default region (`us-central1`), zone (`us-central1-a`), and state bucket name (`<project_id>-tfstate`).
4. Display a markdown summary table of detected values and request bulk confirmation or overrides from the user before executing any state-mutating actions.

### Step 2: Sequential Secret Interview
Interactively ask the user for required credentials one at a time:
1. **Gemini API Key** (from Google AI Studio).
2. **Telegram Bot Token** (from [@BotFather](https://t.me/BotFather)).
3. **Allowed Telegram User IDs** (comma-separated, obtained via [@userinfobot](https://t.me/userinfobot)).

> **Google Workspace**: Gmail, Calendar, Drive, and Tasks integration uses the **ClawHub `gog` skill** — NOT GCP Secret Manager credentials. Ask the user if they want to set up Google Workspace access, and if so, guide them to run `gog auth login` after bootstrap completes (Spec 025).

### Step 3: GCP Infrastructure & WIF Actuation
Run `gcloud` commands to:
1. Enable GCP APIs: `compute`, `secretmanager`, `iam`, `iamcredentials`, `artifactregistry`, `cloudresourcemanager`, `sts`.
2. Create GCS remote state bucket `gs://<project_id>-tfstate` with uniform bucket-level access.
3. Seed secrets in GCP Secret Manager (`gemini-api-key`, `telegram-bot-token`, `telegram-allowed-user-ids`).
4. Provision deployment Service Account `terraform-deployer` and assign `roles/owner` or required deployment roles.
5. Create Workload Identity Pool `github-pool` and Provider `github-provider` mapping repository claims.

> **Note**: Google Workspace APIs (`gmail`, `calendar-json`, `drive`, etc.) are NOT enabled here. They are managed by the ClawHub `gog` skill when the user runs `gog auth login` (Spec 025).

### Step 4: GitHub Secrets & Variables Configuration
Run `gh` CLI commands to set:
- Variables: `GCP_PROJECT_ID`, `GCP_REGION`, `GCP_ZONE`, `GCP_TF_STATE_BUCKET`, `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT`.
- Secrets: `GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `ALLOWED_USER_IDS`.

### Step 5: Final Validation
Execute `./scripts/verify_wif_bootstrap.sh` to confirm all components are provisioned and operational.
