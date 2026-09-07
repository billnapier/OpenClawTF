# Feature Specification: Containerization & Artifact Registry Module

## Feature Overview & Objectives
The goal of this feature is to create the containerization baseline for OpenClaw (`docker/Dockerfile` and runtime entrypoint) along with a modular Terraform module (`terraform/modules/artifact_registry`) that provisions a GCP Artifact Registry repository.

The container image encapsulates the OpenClaw service, uses Application Default Credentials (ADC) via the GCE service account identity to fetch runtime secrets from GCP Secret Manager, mounts `/mnt/disks/openclaw-data` for persistent memory storage, and handles `SIGTERM`/`SIGINT` signals gracefully to flush SQLite database state.

---

## User Stories & Acceptance Scenarios

### User Story 1: Production Container Definition & Entrypoint
* **As a** DevOps Engineer,
* **I want to** build a minimal, secure container image for OpenClaw,
* **So that** the application executes predictably across GCE compute environments with dynamic secret injection.

#### Scenario 1.1: Multi-stage Container Build
* **Given** the application repository context,
* **When** `docker build -f docker/Dockerfile` is executed,
* **Then** an image is produced containing all required runtime dependencies, exposing no hardcoded secrets, and defining an entrypoint script (`docker/entrypoint.sh`).

#### Scenario 1.2: Dynamic Secret Loading & Graceful Shutdown
* **Given** the container is launched on GCE with ADC credentials,
* **When** `entrypoint.sh` executes,
* **Then** it fetches `GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, and `TELEGRAM_ALLOWED_USER_IDS` from Secret Manager, injects them into process environment variables, and traps `SIGTERM`/`SIGINT` to safely stop long-polling and flush SQLite WAL databases before exit.

---

### User Story 2: GCP Artifact Registry Module
* **As a** Cloud Administrator,
* **I want** a dedicated Terraform module (`terraform/modules/artifact_registry`) provisioning a Docker repository in GCP,
* **So that** built container images can be pushed and pulled securely via IAM without public access.

#### Scenario 2.1: Artifact Registry Creation
* **Given** target GCP project and region configuration,
* **When** `terraform apply` is executed for `artifact_registry`,
* **Then** a `google_artifact_registry_repository` is provisioned with format `"DOCKER"` and repository ID `"openclaw"`.

---

## Functional Requirements & Specifications

### 1. Terraform Module (`terraform/modules/artifact_registry`)
- **Inputs**: `project_id`, `region`, `repository_id` (default `"openclaw"`), `description`.
- **Outputs**: `repository_id`, `repository_url`, `repository_name`.
- **Resources**: `google_artifact_registry_repository.openclaw_repo` with `format = "DOCKER"`.

### 2. Container Assets (`docker/`)
- `docker/Dockerfile`: Standardized multi-stage container file.
- `docker/entrypoint.sh`: Shell script fetching Secret Manager secrets via `gcloud` or GCP client API, starting OpenClaw bot engine, and catching process termination signals.

---

## Edge Cases & Failure Modes
- **Secret Manager Access Error**: If the VM service account lacks Secret Accessor permissions, `entrypoint.sh` logs an explicit authentication error and retries with exponential backoff (2s, 5s, 10s).
- **SQLite Database Lock**: Unexpected termination without catching `SIGTERM` can leave WAL locks on `/mnt/disks/openclaw-data`. The entrypoint trap ensures graceful closure.

---

## Success Criteria & Validation
- Container builds cleanly without errors.
- `terraform validate` and `terraform fmt -check` pass in `terraform/modules/artifact_registry`.
- Image can be pushed to GCP Artifact Registry URL format `<region>-docker.pkg.dev/<project>/<repo>/app:latest`.
