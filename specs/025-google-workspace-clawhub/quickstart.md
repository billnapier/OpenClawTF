# Quickstart: Google Workspace Integration via `gog`

## Prerequisites

- A GCP OAuth 2.0 Client ID (Desktop app type) with the Gmail, Calendar, Drive, Tasks, and Contacts APIs enabled on the underlying GCP project, downloaded as `client_secret.json`.
- The OpenClaw host/VM already deployed (this feature does not change Terraform networking/compute — only adds one Secret Manager entry, see below).

## One-time setup (manual, per Constitution Principle 7 — also wired into `skills/openclaw.bootstrap/SKILL.md`)

1. Generate a strong random passphrase and store it as a new secret:
   ```bash
   openssl rand -base64 32 | gcloud secrets create gog-keyring-password --data-file=-
   ```
2. On a machine with a browser (this step cannot run headlessly — it's a real Google OAuth consent flow):
   ```bash
   GOG_KEYRING_BACKEND=file GOG_KEYRING_PASSWORD=<the passphrase from step 1> GOG_HOME=/mnt/disks/openclaw-data/gogcli \
     gog auth credentials /path/to/client_secret.json
   GOG_KEYRING_BACKEND=file GOG_KEYRING_PASSWORD=<...> GOG_HOME=/mnt/disks/openclaw-data/gogcli \
     gog auth add you@example.com --services gmail,calendar,drive,tasks,contacts
   ```
3. Verify:
   ```bash
   GOG_KEYRING_BACKEND=file GOG_KEYRING_PASSWORD=<...> GOG_HOME=/mnt/disks/openclaw-data/gogcli \
     gog auth doctor --check --no-input
   ```
4. Set `GOG_ACCOUNT=you@example.com` as a deployment-level env var (Terraform, alongside the other channel config) so the daemon doesn't need `--account` on every call.

## Usage (once deployed)

From Telegram, ask naturally: *"What's on my calendar today?"*, *"Do I have unread email about the Q3 budget?"*, *"Add 'review PR #42' to my task list."* Mutating requests (sending mail, creating events, adding tasks) will be echoed back for confirmation before they execute.

## Test scenario

`scripts/test_gworkspace_clawhub.sh` (to be created in the implementation phase) should, at minimum:
- Verify `gog auth doctor --check --no-input` exits `0` in a correctly configured environment.
- Verify `ToolGateway.call_mcp_tool("calendar_get_events", ...)` returns `status: "success"` with parsed JSON against a live-or-stubbed `gog` call.
- Verify a simulated `gog` exit code `4` maps to `status: "auth_required"` with a clear message, not a raw error.
- Verify a mutating call (e.g. `send_message`) returns `status: "confirmation_required"` on first invocation rather than executing immediately.
