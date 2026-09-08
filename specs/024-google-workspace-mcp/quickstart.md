# Quickstart: Google Workspace MCP Integration

## Step 1: Enable Google APIs in GCP Console / CLI
```bash
gcloud services enable \
  gmail.googleapis.com \
  calendar-json.googleapis.com \
  drive.googleapis.com \
  docs.googleapis.com \
  sheets.googleapis.com \
  tasks.googleapis.com \
  people.googleapis.com \
  --project="YOUR_GCP_PROJECT_ID"
```

## Step 2: Seed Credentials into GCP Secret Manager
Create OAuth 2.0 Credentials file `workspace-creds.json` and seed it:
```bash
gcloud secrets create google-workspace-credentials \
  --data-file="workspace-creds.json" \
  --project="YOUR_GCP_PROJECT_ID"
```

## Step 3: Run Interactive Onboarding Skill
```bash
antigravity run openclaw.bootstrap
```
The onboarding skill automatically verifies Secret Manager bindings, builds the Docker image containing `google-workspace-mcp`, and validates tool execution.

## Step 4: Verify Integration in Telegram / Control UI
Send a message in Telegram:
> "What's on my Google Calendar for today?"
> "Find emails about Q3 roadmap"
