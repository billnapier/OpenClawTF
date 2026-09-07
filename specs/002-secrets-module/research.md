# Research & Design Decisions: Secret Manager & IAM Module

## Key Architectural Decisions

1. **Automatic Secret Replication**:
   - GCP Secret Manager supports user-managed and automatic replication policies.
   - For OpenClaw, automatic replication (`replication { auto {} }`) ensures simple multi-region resilience without manual region management.

2. **Per-Secret IAM Member Bindings**:
   - `google_secret_manager_secret_iam_member` is preferred over `google_secret_manager_secret_iam_policy` or `google_project_iam_member` to follow the principle of least privilege at the secret resource scope.

3. **Separation of Secret Containers and Secret Payloads**:
   - Terraform manages secret metadata/containers only. Secret payload versions should be created separately via CLI or Secret Manager API to prevent sensitive credentials from leaking into Terraform state files.
