# Feature Specification: Secret Manager & IAM Module

## Feature Overview & Objectives
The goal of this feature is to create a modular Terraform module (`terraform/modules/secrets`) that provisions GCP Secret Manager resources for OpenClaw runtime secrets (`gemini-api-key`, `telegram-bot-token`, `telegram-allowed-user-ids`) and binds `roles/secretmanager.secretAccessor` permissions to the runtime service account identity.

This ensures sensitive credentials are stored securely outside source code and container images, enabling keyless dynamic access via Application Default Credentials (ADC) at container startup.

## User Stories & Acceptance Scenarios

### User Story 1: GCP Secret Resource Provisioning
* **As a** Cloud Administrator,
* **I want** Secret Manager secret declarations automatically managed via Terraform,
* **So that** secret containers exist before application bootstrap without manual GCP Console setup.

#### Scenario 1.1: Automatic Secret Declarations
* **Given** valid GCP credentials and target service account email,
* **When** `terraform apply` is executed for the `secrets` module,
* **Then** three GCP Secret Manager resources are created:
  - `gemini-api-key`
  - `telegram-bot-token`
  - `telegram-allowed-user-ids`
  with automatic replication policies enabled.

### User Story 2: Zero-Trust IAM Access Control
* **As a** Security Engineer,
* **I want** IAM Secret Accessor permissions granted strictly to the designated GCE service account,
* **So that** only the OpenClaw container runtime can read the secret payloads.

#### Scenario 2.1: Secret Accessor IAM Binding
* **Given** a designated GCE service account email,
* **When** the `secrets` module is applied,
* **Then** IAM bindings grant `roles/secretmanager.secretAccessor` to `serviceAccount:<service_account_email>` for all three secrets.

---

## Requirements & Functional Specifications

### 1. Inputs & Variables (`terraform/modules/secrets/variables.tf`)
| Name | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `project_id` | `string` | N/A (Required) | The GCP Project ID. |
| `service_account_email` | `string` | N/A (Required) | GCE runtime Service Account email to receive Secret Accessor IAM bindings. |
| `secret_prefix` | `string` | `""` | Optional prefix for secret IDs to avoid naming collisions across environments. |

### 2. Outputs (`terraform/modules/secrets/outputs.tf`)
| Name | Description |
| :--- | :--- |
| `secret_ids` | Map of secret key names to their GCP Secret Manager resource IDs. |
| `secret_names` | Map of secret key names to their fully qualified secret names (`projects/.../secrets/...`). |

### 3. Resource Definitions (`terraform/modules/secrets/main.tf`)
- `google_secret_manager_secret.gemini_api_key`: Secret resource for Gemini API key.
- `google_secret_manager_secret.telegram_bot_token`: Secret resource for Telegram Bot Token.
- `google_secret_manager_secret.telegram_allowed_user_ids`: Secret resource for allowed Telegram numeric user IDs.
- `google_secret_manager_secret_iam_member.accessor_bindings`: `roles/secretmanager.secretAccessor` bindings for each secret assigned to `var.service_account_email`.

---

## Edge Cases & Failure Modes
- **Invalid Service Account Format**: Passing an empty or malformed service account email will fail IAM member formatting.
- **Existing Secret Collisions**: If a secret ID already exists in the GCP project outside Terraform tracking, creation will fail. Use unique secret prefixes if needed.
- **Empty Secret Versions**: Creating secret resources does not populate secret versions (payloads). Pre-boot seeding or manual seeding of secret payloads is required before VM execution.

---

## Dependencies
- GCP Secret Manager API (`secretmanager.googleapis.com`) enabled in target project.
- `roles/secretmanager.admin` permissions for Terraform execution context.

---

## Success Criteria & Validation
- Executing `terraform fmt -check` and `terraform validate` inside `terraform/modules/secrets` completes successfully.
- Module exports map of secret IDs and names for downstream consumption.
