# Feature Specification: Guardian CI/CD Automation Setup

## Feature Overview & Objectives
The goal of this feature is to establish automated GitOps CI/CD workflows (`.github/workflows/terraform-plan.yml` and `.github/workflows/deploy.yml`) using Google's official `abcxyz/guardian` action suite and Workload Identity Federation (WIF) keyless authentication.

The PR workflow executes `guardian terraform plan` on pull requests, posting HCL plan diffs as PR comments. The merge workflow executes `guardian terraform apply` on pushes to `main`, builds/pushes container image updates to GCP Artifact Registry, and refreshes the container service.

---

## User Stories & Acceptance Scenarios

### User Story 1: Keyless Pull Request Plan Validation
* **As a** DevOps Engineer,
* **I want** pull requests to automatically authenticate via WIF and run Guardian Terraform Plan,
* **So that** infrastructure changes are previewed and commented on PRs without handling static GCP service account keys.

#### Scenario 1.1: Automated PR Plan Workflow
* **Given** a Pull Request targeting `main`,
* **When** changes are pushed,
* **Then** `.github/workflows/terraform-plan.yml` authenticates via OIDC WIF provider, runs `guardian terraform plan -dir=terraform -storage=<GCS_STATE_BUCKET>`, and posts the formatted plan comment to the PR.

---

### User Story 2: Automated Merge Deployment & Container Refresh
* **As a** Cloud Administrator,
* **I want** merges to `main` to apply Terraform updates and deploy container updates automatically,
* **So that** infrastructure and application state stay synchronized with source control.

#### Scenario 2.1: Automated Merge Deploy Workflow
* **Given** a merged PR on `main`,
* **When** `.github/workflows/deploy.yml` executes,
* **Then** it runs `guardian terraform apply`, builds and pushes the updated Docker container image to Artifact Registry, and updates GCE container metadata.

---

## Functional Requirements & Specifications

### 1. PR Plan Workflow (`.github/workflows/terraform-plan.yml`)
- Trigger: `pull_request` targeting `main` with paths `terraform/**`, `docker/**`.
- Steps: Checkout repo, OIDC auth via `google-github-actions/auth` using WIF, `abcxyz/guardian-setup`, `guardian terraform plan`.

### 2. Merge Deploy Workflow (`.github/workflows/deploy.yml`)
- Trigger: `push` to `main` with paths `terraform/**`, `docker/**`.
- Steps: Checkout repo, OIDC auth via `google-github-actions/auth` using WIF, `abcxyz/guardian-setup`, `guardian terraform apply`, Docker image build & push to GCP Artifact Registry.

---

## Edge Cases & Failure Modes
- **State Lock Contention**: Concurrent runs on GCS state bucket return state lock errors. Guardian handles retry logic and workflow fails gracefully with actionable log output.
- **WIF Token Expiration**: Long-running jobs handle token refreshes automatically via GitHub Actions OIDC context.

---

## Success Criteria & Validation
- Workflow syntax passes GitHub Actions linter (`actionlint` / YAML schema validation).
- Workflows correctly reference `GCP_WIF_PROVIDER`, `GCP_SERVICE_ACCOUNT`, and `GCP_TF_STATE_BUCKET` GitHub environment variables.
