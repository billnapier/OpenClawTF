# Data Model: Release Verification & Operational Handover

## Unauthorized Access Rejection Message Format (CUJ 3)
`⛔ Access Denied. Your Telegram User ID is <NUMERIC_ID>. Send this ID to your OpenClaw Administrator to request access.`

## Verification Check Items (`scripts/verify_deployment.sh`)
1. Terraform HCL validation (`terraform validate` across all modules).
2. Secret Manager pre-flight check.
3. Artifact Registry repository verification.
4. GCE Startup script disk mount assertions.
