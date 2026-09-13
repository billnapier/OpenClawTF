# Quickstart: Google Workspace Integration via `gog`

## Prerequisites

- A GCP OAuth 2.0 Client ID (Desktop app type) with the Gmail, Calendar, Drive, Tasks, and Contacts APIs enabled on the underlying GCP project, downloaded as `client_secret.json`.
- The OpenClaw host/VM already deployed (this feature does not change Terraform networking/compute — only adds one Secret Manager entry, see below).

## One-time setup (manual, per Constitution Principle 7 — also wired into `skills/openclaw.bootstrap/SKILL.md`)

1. Generate a strong random passphrase and store it as a new secret:
   ```bash
   openssl rand -base64 32 | gcloud secrets create gog-keyring-password --data-file=-
   ```
2. Run the grant inside the container on the host (that's where `gog` and `GOG_HOME` are; `entrypoint.sh` already exports the keyring vars, so they don't need repeating). The host is headless, so use the two-step `--remote` flow — the default flow tries to open a browser and fails:
   ```bash
   gcloud compute scp client_secret.json openclaw-vm:/tmp/ --zone <zone> --tunnel-through-iap
   gcloud compute ssh openclaw-vm --zone <zone> --tunnel-through-iap
   sudo docker exec -it openclaw-container bash

   gog auth credentials set /tmp/client_secret.json
   gog auth add you@example.com --services gmail,calendar,drive,tasks,contacts --remote --step 1
   # approve the printed URL in any browser, then paste the (failing) redirect URL back:
   gog auth add you@example.com --services gmail,calendar,drive,tasks,contacts --remote --step 2 --auth-url "<redirect URL>"
   ```

   > Verified against `gog v0.40.0` on the deployed host. Earlier revisions of this file documented `gog auth credentials <file>` and a single-shot `gog auth add` from web research — neither matches the real binary: `credentials` takes a `set` subcommand, and a headless host needs `--remote --step 1`/`--step 2`.
3. Verify:
   ```bash
   GOG_KEYRING_BACKEND=file GOG_KEYRING_PASSWORD=<...> GOG_HOME=/mnt/disks/openclaw-data/gogcli \
     gog auth doctor --check --no-input
   ```
4. Seed the account email as its own Secret Manager secret (`gog-account`) — the container receives no `docker run -e` flags at all; every value here, sensitive or not, is fetched from Secret Manager by `entrypoint.sh` at boot:
   ```bash
   echo -n "you@example.com" | gcloud secrets versions add gog-account --data-file=-
   ```
   `gog` reads `GOG_ACCOUNT` natively once exported, so no `--account` flag is needed per call.

## Usage (once deployed)

From Telegram, ask naturally: *"What's on my calendar today?"*, *"Do I have unread email about the Q3 budget?"*, *"Add 'review PR #42' to my task list."* Mutating requests (sending mail, creating events, adding tasks) will be echoed back for confirmation before they execute.

## Test scenario

`scripts/test_gworkspace_clawhub.sh` (to be created in the implementation phase) should, at minimum:
- Verify `gog auth doctor --check --no-input` exits `0` in a correctly configured environment.
- Verify `ToolGateway.call_mcp_tool("calendar_get_events", ...)` returns `status: "success"` with parsed JSON against a live-or-stubbed `gog` call.
- Verify a simulated `gog` exit code `4` maps to `status: "auth_required"` with a clear message, not a raw error.
- Verify a mutating call (e.g. `send_message`) returns `status: "confirmation_required"` on first invocation rather than executing immediately.
