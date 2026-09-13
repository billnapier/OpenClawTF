# Quickstart & Manual Setup Guide: OpenClaw on GCP

This document outlines all manual prerequisites, initial environment setup steps, secret configurations, and GitOps CI/CD onboarding required before deploying OpenClaw using Terraform on Google Cloud Platform.

> 💡 **Interactive QuickStart Option**:  
> Per Constitution **Principle 7**, you can execute this setup interactively using the **Antigravity Onboarding Skill** (`@[openclaw.bootstrap]`). The skill detects reasonable defaults for your project, allows you to confirm or change inputs in bulk, and executes these steps automatically.

---

## 1. Local Prerequisites & GCP Authentication

Ensure the following local CLI tools are installed:
- [Google Cloud SDK (`gcloud`)](https://cloud.google.com/sdk/docs/install)
- [Terraform `>= 1.5.0`](https://developer.hashicorp.com/terraform/downloads)
- [GitHub CLI (`gh`)](https://cli.github.com/)

Authenticate `gcloud` and set your active project:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <YOUR_GCP_PROJECT_ID>
```

---

## 2. Manual Step 1: Enable the Two Bootstrap GCP APIs

Terraform manages API enablement (`terraform/services.tf`), but it can't enable the two APIs it needs in order to enable anything else. Turn those on by hand once:

```bash
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  serviceusage.googleapis.com
```

Everything else — `compute`, `secretmanager`, `iam`, `iamcredentials`, `artifactregistry`, `sts`, `iap`, `logging`, `monitoring` — is declared in `terraform/services.tf` and enabled on the first `terraform apply`. Enabling an already-enabled API is a no-op, so projects that were set up manually before this was codified adopt cleanly with no import step.

> `iap.googleapis.com` is what lets the deploy workflow's container-redeploy step reach the VM over an IAP tunnel (the instance has no public IP). The matching firewall rule for `35.235.240.0/20` on `tcp:22` is created by the VPC module.

> **Google Workspace APIs** (Gmail, Calendar, Drive, etc.) are enabled separately as part of the ClawHub `gog` skill installation. See [Google Integration](#google-workspace-integration) below.

---

## 3. Manual Step 2: Create Remote State GCS Bucket

Terraform state must be stored securely in Google Cloud Storage with uniform bucket-level access and locking:

```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET_NAME="${PROJECT_ID}-tfstate"

gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --location=us-central1 \
  --uniform-bucket-level-access
```

---

## 4. Manual Step 3: Populate GCP Secret Manager

OpenClaw requires secrets stored in GCP Secret Manager prior to VM provisioning. Runtime containers fetch these secrets directly via Application Default Credentials (ADC).

### A. Gemini API Key
Obtain an API key from Google AI Studio and store it:

```bash
echo -n "YOUR_GEMINI_API_KEY" | gcloud secrets create gemini-api-key --data-file=-
```

### B. Telegram Bot Token
Obtain a bot token from [@BotFather](https://t.me/BotFather) on Telegram and store it:

```bash
echo -n "YOUR_TELEGRAM_BOT_TOKEN" | gcloud secrets create telegram-bot-token --data-file=-
```

### C. Allowed Telegram User IDs
Specify a comma-separated list of numerical Telegram User IDs permitted to interact with the bot:

```bash
echo -n "123456789,987654321" | gcloud secrets create telegram-allowed-user-ids --data-file=-
```

---

## 5. Manual Step 4: Configure Workload Identity Federation (WIF) & GitHub Secrets

To allow GitHub Actions to run keyless Terraform plans and applies via `abcxyz/guardian`, configure Workload Identity Federation.

### A. Create Workload Identity Pool & Provider

```bash
# Create Pool
gcloud iam workload-identity-pools create "github-pool" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

### B. Set Up GitHub Repository Secrets & Variables

In your GitHub Repository settings (`Settings > Secrets and variables > Actions`), add the following:

| Secret / Variable Name | Type | Description / Value Example |
| :--- | :--- | :--- |
| `GCP_PROJECT_ID` | Secret | Your GCP Project ID (e.g. `openclaw-prod-12345`) |
| `GCP_TF_STATE_BUCKET` | Secret | GCS bucket created in Step 2 (e.g. `openclaw-prod-12345-tfstate`) |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Secret | `projects/<PROJECT_NUM>/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| `GCP_SERVICE_ACCOUNT` | Secret | Email of the deployment Service Account with `roles/owner` or required deployment IAM roles |

---

## 6. Local Terraform Module Validation

To validate individual module HCL configurations locally (e.g., VPC network module):

```bash
cd terraform/modules/vpc
terraform init -backend=false
terraform fmt -check
terraform validate
```

---

## 7. Operational Workflow

Once manual setup steps 1–4 are complete:
1. Open a Pull Request on GitHub to trigger `terraform-plan.yml` (Guardian plan).
2. Review the plan output posted automatically by the Guardian bot on your PR.
3. Merge the PR into `main` to trigger `deploy.yml` (Guardian apply & image deployment).

---

## 7a. CLI Chat Interface

Once OpenClaw is deployed, an operator with an authenticated SSH session on the host can converse with the agent directly from the terminal via the `openclaw chat` subcommand — no separate CLI login or credential is required.

**One-shot usage:**

```bash
openclaw chat "What's on my calendar today?"
```

Prints the agent's response and exits. The message and response are persisted to the same continuing CLI conversation thread that interactive sessions read/write.

**Interactive usage (REPL):**

```bash
openclaw chat
```

Opens a prompt loop that carries context across turns. Exit with any of:
- `/exit` or `/quit` (typed command)
- Ctrl-D (EOF)
- Ctrl-C (SIGINT)

All three terminate cleanly with no orphaned processes. There is no idle timeout.

**Authorization model:** the CLI channel's sole authorization boundary is an authenticated SSH session on the host itself — the same boundary already governing shell access. No separate CLI-specific credential, whitelist, or network-reachable entry point is introduced; the OS user is recorded only as an audit label.

**Built-in help:**

```bash
openclaw chat --help
```

See `specs/026-cli-chat-interface/quickstart.md` for full usage detail, verification steps, and notes on channel isolation (CLI and Telegram conversations are independent threads).

---

## Google Workspace Integration

OpenClaw integrates with Google Workspace (Gmail, Calendar, Drive, Tasks) via the ClawHub `gog` CLI (`github.com/openclaw/gogcli`), invoked as a normal subprocess from `scripts/tool_gateway.py` — no custom MCP server. Ask the bot naturally ("what's on my calendar today?"); Gemini function-calling routes the request to `gog`. Mutating actions (creating events, sending mail, adding/completing tasks) always pause for an explicit confirmation reply before executing.

### One-time setup (per Constitution Principle 7)

This is a manual, one-time step — the OAuth consent flow requires a real browser and cannot run headlessly or in CI. See `specs/025-google-workspace-clawhub/quickstart.md` for full detail; summary:

1. Generate a keyring passphrase and store it in Secret Manager (the encrypted token file's passphrase, not the OAuth token itself — Principle 3):
   ```bash
   openssl rand -base64 32 | gcloud secrets create gog-keyring-password --data-file=-
   ```
2. Stage `client_secret.json` on the host, then into the container:
   ```bash
   gcloud compute scp client_secret.json openclaw-vm:/tmp/ --zone <zone> --tunnel-through-iap
   gcloud compute ssh openclaw-vm --zone <zone> --tunnel-through-iap
   sudo docker cp /tmp/client_secret.json openclaw-container:/tmp/client_secret.json
   ```

   > **`docker exec` does not inherit the environment `entrypoint.sh` exports.** The daemon has `GOG_HOME` etc. because entrypoint spawned it; a fresh `exec` session gets none of it. Set them explicitly or `gog` will write the token to the container's *ephemeral* filesystem, where it looks fine until the next deploy silently discards it. The passphrase is fetched inside the container because `gcloud` isn't installed on the COS host.

   The host is headless, so use `gog`'s two-step remote flow — step 1 prints a URL you can approve on any device (a phone is fine), step 2 exchanges the code:

   ```bash
   # step 1 - prints a consent URL
   sudo docker exec openclaw-container sh -c '
     export GOG_KEYRING_BACKEND=file
     export GOG_HOME=/mnt/disks/openclaw-data/gogcli
     export GOG_KEYRING_PASSWORD=$(gcloud secrets versions access latest --secret=gog-keyring-password)
     gog auth credentials set /tmp/client_secret.json
     gog auth add you@example.com --services gmail,calendar,drive,tasks,contacts --remote --step 1
   '

   # approve the printed URL in any browser. It redirects to a 127.0.0.1 address
   # that will fail to load - expected; the code is in that URL. Copy it whole,
   # including the state parameter.

   # step 2 - exchange it
   sudo docker exec openclaw-container sh -c '
     export GOG_KEYRING_BACKEND=file
     export GOG_HOME=/mnt/disks/openclaw-data/gogcli
     export GOG_KEYRING_PASSWORD=$(gcloud secrets versions access latest --secret=gog-keyring-password)
     gog auth add you@example.com --services gmail,calendar,drive,tasks,contacts \
       --remote --step 2 --auth-url "<the full redirect URL>"
   '

   # clean up - the file is only an input to `credentials set`; gog copies what
   # it needs into its own store under GOG_HOME
   sudo docker exec openclaw-container shred -u /tmp/client_secret.json
   shred -u /tmp/client_secret.json
   ```

   Scope can be narrowed if you'd rather not grant full access — `--gmail-scope=read-send`, `--drive-scope=readonly`, or `--readonly` for read-only across the board.
3. Verify:
   ```bash
   GOG_KEYRING_BACKEND=file GOG_KEYRING_PASSWORD=<passphrase> GOG_HOME=/mnt/disks/openclaw-data/gogcli \
     gog auth doctor --check --no-input
   ```
4. Seed the account email as its own Secret Manager value (not passed via `docker run` — the container has no `-e` flags at all; it fetches everything from Secret Manager at boot, same as `GOG_KEYRING_PASSWORD`):
   ```bash
   echo -n "you@example.com" | gcloud secrets versions add gog-account --data-file=-
   ```
   `gog` itself reads the `GOG_ACCOUNT` env var natively once `entrypoint.sh` exports it, so no `--account` flag is needed per call.

The container's `docker/entrypoint.sh` fetches `GOG_KEYRING_PASSWORD` from Secret Manager at startup (same pattern as `GEMINI_API_KEY`) and runs `gog auth doctor --check --no-input` as a startup sanity check, logging a warning (not crashing) on failure.

> **Note**: the `gog` binary is pinned and installed at image build time in `docker/Dockerfile` (not a runtime download). Its exact version/flags were verified via `github.com/openclaw/gogcli` docs research at implementation time (no live binary available in that environment) — see `specs/025-google-workspace-clawhub/research.md` Decision 8 for what to re-check against a real deployment.
