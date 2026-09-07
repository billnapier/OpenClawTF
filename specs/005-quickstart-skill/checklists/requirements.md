# Quality Checklist: Quickstart Skill Requirements

- [ ] **Default Parameter Auto-Detection**: Auto-detect `GCP_PROJECT_ID`, `GITHUB_REPO`, `GCP_REGION`, `GCP_ZONE`, and `GCP_TF_STATE_BUCKET`.
- [ ] **Bulk Confirmation Interface**: Display all auto-detected defaults in a single summary message asking the user to confirm or modify.
- [ ] **Sequential Secret Interview**: Prompt for `GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, and `ALLOWED_USER_IDS` interactively one-by-one with instructions.
- [ ] **GCP API Enablement**: Command suite enables `compute`, `secretmanager`, `iam`, `iamcredentials`, `cloudresourcemanager`, `artifactregistry`, and `sts` APIs.
- [ ] **Remote State Storage**: Provision GCS bucket with uniform bucket-level access and locking.
- [ ] **Workload Identity Federation (WIF)**: Create WIF Pool `github-pool` and OIDC Provider `github-provider` with subject mapping.
- [ ] **IAM Policy Bindings**: Create Service Account `terraform-deployer` and grant required administrative deployment roles and WIF impersonation bindings.
- [ ] **GitHub Repository Settings**: Populate GitHub variables (`GCP_PROJECT_ID`, `GCP_REGION`, `GCP_ZONE`, `GCP_TF_STATE_BUCKET`, `GCP_WIF_PROVIDER`, `GCP_SERVICE_ACCOUNT`, `ALLOWED_USER_IDS`) and secrets (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`).
- [ ] **Documentation Parity**: Maintain 100% functional parity with `docs/Quickstart.md` per Constitution Principle 7.
