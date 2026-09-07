# Implementation Plan: Containerization & Artifact Registry Module

## Architecture Overview
This plan defines the setup for the OpenClaw container runtime baseline and GCP Artifact Registry module:
1. **GCP Artifact Registry Module**: Terraform module in `terraform/modules/artifact_registry` provisioning a Docker repository.
2. **Container Build System**: `docker/Dockerfile` (multi-stage build) and `docker/entrypoint.sh` for fetching secret manager parameters via GCP API/gcloud ADC and managing graceful shutdown.

## Technical Components
- **`terraform/modules/artifact_registry/main.tf`**: Defines `google_artifact_registry_repository`.
- **`terraform/modules/artifact_registry/variables.tf`**: Inputs (`project_id`, `region`, `repository_id`, `description`).
- **`terraform/modules/artifact_registry/outputs.tf`**: Outputs (`repository_id`, `repository_url`, `repository_name`).
- **`terraform/modules/artifact_registry/versions.tf`**: Terraform and google provider version constraints.
- **`docker/Dockerfile`**: Alpine/Debian base container with runtime dependencies, Python/Node runtime, and entrypoint script.
- **`docker/entrypoint.sh`**: Entrypoint wrapper handling ADC Secret Manager resolution, signal trapping (`SIGTERM`, `SIGINT`), and process execution.

## Verification & Testing Strategy
1. Validate HCL syntax and formatting with `terraform fmt -check` and `terraform validate`.
2. Verify Dockerfile syntax and linting.
3. Verify entrypoint shell script syntax (`bash -n docker/entrypoint.sh`).
