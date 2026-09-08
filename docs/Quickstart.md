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

## 2. Manual Step 1: Enable Required GCP APIs

Run the following command to enable all necessary Google Cloud API services:

```bash
gcloud services enable \
  compute.googleapis.com \
  secretmanager.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  artifactregistry.googleapis.com \
  cloudresourcemanager.googleapis.com \
  sts.googleapis.com \
  gmail.googleapis.com \
  calendar-json.googleapis.com \
  drive.googleapis.com \
  docs.googleapis.com \
  sheets.googleapis.com \
  tasks.googleapis.com \
  people.googleapis.com
```

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

### D. Google Workspace MCP OAuth Credentials
To enable the Google Workspace MCP Server (Gmail, Calendar, Drive, Docs, Sheets, Tasks, Contacts), generate OAuth 2.0 Client credentials in Google Cloud Console (`APIs & Services > Credentials`), download the JSON file, and seed it into Secret Manager:

```bash
gcloud secrets create google-workspace-credentials --data-file="/path/to/workspace-credentials.json"
```

Once seeded, OpenClaw automatically initializes the native Google Workspace MCP Server (`uvx --from google-workspace-mcp google-workspace-worker`) over stdio JSON-RPC per **Principle 10**.

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
