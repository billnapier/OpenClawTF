# Feature Specification: Interactive Quickstart & Onboarding Skill

## Feature Overview & Objectives
The goal of this feature is to create a dedicated, interactive onboarding and bootstrapping skill (`nanogemclaw.bootstrap` / `openclaw.quickstart`) for Antigravity that automates GCP infrastructure enablement, Workload Identity Federation (WIF) provisioning, and GitHub repository configuration. 

Per **Constitution Principle 7**, this skill MUST maintain 100% functional parity with [`docs/Quickstart.md`](../../docs/Quickstart.md), assume reasonable defaults for all input parameters, prompt the user for bulk confirmation/edits before taking action, and conduct step-by-step interviews for missing manual secrets.

---

## User Stories & Acceptance Scenarios

### User Story 1: Default Context Detection & Bulk Confirmation
* **As a** Cloud Engineer,
* **I want to** start the onboarding skill and see pre-detected reasonable defaults for GCP and GitHub settings,
* **So that** I can review and confirm or change inputs in a single step without manually re-typing existing project details.

#### Scenario 1.1: Environment Parameter Auto-Detection
* **Given** an active `gcloud` login and local git repository context,
* **When** the quickstart skill is initialized,
* **Then** it automatically detects `GCP_PROJECT_ID` (via `gcloud config get-value project`), `GITHUB_REPO` (via `git remote get-url origin`), sets default `GCP_REGION` to `"us-central1"`, `GCP_ZONE` to `"us-central1-a"`, and `GCP_TF_STATE_BUCKET` to `"${GCP_PROJECT_ID}-tfstate"`.
* **And** it displays a single summary table requesting user confirmation or overrides prior to executing any commands.

---

### User Story 2: Interactive Secret Interview
* **As a** Cloud Engineer,
* **I want** the skill to guide me through providing required manual secrets step-by-step,
* **So that** I know exactly where and how to obtain each credential without leaving the AI workspace.

#### Scenario 2.1: Sequential Secret Gathering
* **Given** bulk parameter confirmation is complete,
* **When** missing secret credentials (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `ALLOWED_USER_IDS`) are evaluated,
* **Then** the skill asks for each missing secret one at a time, providing direct web links or bot handles (e.g. [@BotFather](https://t.me/BotFather) and [@userinfobot](https://t.me/userinfobot)) for retrieval.

---

### User Story 3: Automated GCP Infrastructure & WIF Provisioning
* **As a** Cloud Engineer,
* **I want** the skill to provision GCP APIs, remote state storage, deployer Service Accounts, and WIF bindings,
* **So that** GitHub Actions can execute keyless Terraform plans and applies without manual GCP console setup.

#### Scenario 3.1: Automated gcloud Actuation
* **Given** confirmed parameters and collected secrets,
* **When** execution starts,
* **Then** the skill enables required APIs (`compute`, `secretmanager`, `iam`, `iamcredentials`, `cloudresourcemanager`, `artifactregistry`, `sts`), creates the GCS state bucket, creates service account `terraform-deployer`, grants required IAM roles, and establishes the OIDC Workload Identity Pool and Provider.

---

### User Story 4: GitHub Secrets & Variables Configuration
* **As a** Cloud Engineer,
* **I want** GitHub repository secrets and environment variables automatically populated,
* **So that** `abcxyz/guardian` CI/CD workflows run out of the box.

#### Scenario 4.1: Automated GitHub Setting Population
* **Given** active WIF provider paths and secret values,
* **When** GitHub configuration executes,
* **Then** the skill uses `gh` CLI commands to populate variables (`GCP_PROJECT_ID`, `GCP_REGION`, `GCP_ZONE`, `GCP_TF_STATE_BUCKET`, `GCP_WIF_PROVIDER`, `GCP_SERVICE_ACCOUNT`, `ALLOWED_USER_IDS`) and secrets (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`).

---

## Functional Requirements & Inputs/Outputs

### 1. Configurable Parameters & Defaults
| Parameter Name | Default Detection Strategy | User Prompt Requirement |
| :--- | :--- | :--- |
| `GCP_PROJECT_ID` | Output of `gcloud config get-value project` | Bulk Confirmation |
| `GITHUB_REPO` | Extracted from `git remote get-url origin` (`owner/repo`) | Bulk Confirmation |
| `GCP_REGION` | Default `"us-central1"` | Bulk Confirmation |
| `GCP_ZONE` | Default `"us-central1-a"` | Bulk Confirmation |
| `GCP_TF_STATE_BUCKET` | Default `"${GCP_PROJECT_ID}-tfstate"` | Bulk Confirmation |
| `GEMINI_API_KEY` | None (User input required) | Sequential Interview |
| `TELEGRAM_BOT_TOKEN` | None (User input required) | Sequential Interview |
| `ALLOWED_USER_IDS` | None (User input required) | Sequential Interview |

---

## Dependencies & Compliance

- **Constitution Principle 7**: Quickstart documentation ([`docs/Quickstart.md`](../../docs/Quickstart.md)) and the onboarding skill (`nanogemclaw.bootstrap`) MUST remain strictly in sync.
- **Keyless Security (Principle 3)**: Authentication between GitHub Actions and GCP MUST use Workload Identity Federation (WIF).
- **Prerequisites**: `gcloud` CLI authenticated with active GCP permissions, `gh` CLI authenticated with GitHub repository write permissions.

---

## Success Criteria & Validation
- Executing `./scripts/verify_wif_bootstrap.sh` verifies all GCP APIs, GCS state bucket, Service Account, and WIF bindings exist and are functional.
- GitHub repository has all required secrets and variables set for `abcxyz/guardian` workflow execution.
