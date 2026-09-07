# Architecture Plan: Secret Manager & IAM Module

## Proposed Architecture
The Secret Manager & IAM module provisions GCP Secret Manager resources for OpenClaw runtime credentials (`gemini-api-key`, `telegram-bot-token`, `telegram-allowed-user-ids`) and binds `roles/secretmanager.secretAccessor` IAM permissions to the designated GCE service account identity.

### Directory Structure
```
terraform/modules/secrets/
├── main.tf        # Secret Manager resources & IAM accessor bindings
├── variables.tf   # Module inputs (project_id, service_account_email, secret_prefix)
├── outputs.tf     # Map exports of secret IDs and names
└── versions.tf    # Required terraform and provider version constraints
```

## Step-by-Step Implementation Strategy

1. **Versions Configuration (`versions.tf`)**:
   - Specify required terraform version `>= 1.5.0`.
   - Specify `google` provider constraint `>= 5.0.0, < 7.0.0`.

2. **Input Variable Specifications (`variables.tf`)**:
   - `project_id`: Required string GCP Project ID.
   - `service_account_email`: Required string GCE service account email.
   - `secret_prefix`: Optional string prefix (default `""`).

3. **Secret Resources & IAM Bindings (`main.tf`)**:
   - Define secrets list or individual resources (`gemini-api-key`, `telegram-bot-token`, `telegram-allowed-user-ids`) with automatic replication (`automatic = true`).
   - Define `google_secret_manager_secret_iam_member` resources granting `roles/secretmanager.secretAccessor` to `serviceAccount:${var.service_account_email}`.

4. **Output Definitions (`outputs.tf`)**:
   - Export `secret_ids` and `secret_names` as maps.

5. **Validation Plan**:
   - Execute `terraform fmt -check` and `terraform validate` in `terraform/modules/secrets`.
