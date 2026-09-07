# Data Model: Secret Manager & IAM Module

## Entities & Interfaces

### Secrets Data Structure
| Secret Name Key | Secret ID (`secret_id`) | Description |
| :--- | :--- | :--- |
| `gemini-api-key` | `${var.secret_prefix}gemini-api-key` | Gemini API Key payload container |
| `telegram-bot-token` | `${var.secret_prefix}telegram-bot-token` | Telegram Bot Token payload container |
| `telegram-allowed-user-ids` | `${var.secret_prefix}telegram-allowed-user-ids` | Comma-separated allowed Telegram user IDs container |

### IAM Role Mapping
- **Role**: `roles/secretmanager.secretAccessor`
- **Member**: `serviceAccount:${var.service_account_email}`
- **Scope**: Per secret resource created by module.
