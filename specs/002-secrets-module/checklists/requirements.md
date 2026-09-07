# Quality Checklist: Secret Manager & IAM Module Requirements

- [ ] **Secret Manager Resources**: `google_secret_manager_secret` defined for `gemini-api-key`, `telegram-bot-token`, `telegram-allowed-user-ids`.
- [ ] **Replication Policy**: `replication { auto {} }` is specified on all secret resources.
- [ ] **IAM Access Grant**: `google_secret_manager_secret_iam_member` grants `roles/secretmanager.secretAccessor` to `var.service_account_email`.
- [ ] **Variable Declarations**: `project_id`, `service_account_email`, and optional `secret_prefix` defined with types and validation.
- [ ] **Module Outputs**: Export map of secret IDs and names.
- [ ] **Zero Hardcoded Secrets**: Module HCL contains no plain-text secret values or credentials.
- [ ] **HCL Formatting & Validation**: HCL files pass `terraform fmt -check` and `terraform validate`.
