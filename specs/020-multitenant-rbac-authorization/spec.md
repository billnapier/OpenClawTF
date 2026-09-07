# Feature Specification: Multi-Tenant Authorization & RBAC Gateway

## Feature Overview & Objectives
The goal of this feature is to extend OpenClaw's simple user whitelisting mechanism into a robust Multi-Tenant Role-Based Access Control (RBAC) gateway.

Instead of binary allow/deny decisions, users are assigned granular roles (`Admin`, `StandardUser`, `ReadOnly`) mapping to permitted operations (e.g., executing system administrative commands, reading memory, running tools, or triggering LLM prompts). Role mappings are dynamically fetched from Secret Manager (`telegram-user-roles`) or managed locally on persistent disk (`/mnt/disks/openclaw-data/config/roles.json`).

---

## User Stories & Acceptance Scenarios

### User Story 1: Granular Role Enforcement Across Slash Commands & Tools
* **As a** Cloud Administrator,
* **I want** to restrict sensitive system commands (`/reset`, `/cron`, `/model`, secret updates, shell tools) to `Admin` users while permitting basic LLM chat to `StandardUser`,
* **So that** unauthorized or standard users cannot mutate infrastructure state or access sensitive tools.

#### Scenario 1.1: Admin Command Attempt by Standard User
* **Given** a user mapped to `StandardUser` role in `roles.json`,
* **When** the user sends an admin command such as `/cron add ...`,
* **Then** the RBAC gateway intercepts the request and responds with a permission denied message indicating required role `Admin`.

#### Scenario 1.2: Dynamic Role Reloading Without Restart
* **Given** an updated `roles.json` on disk or updated secret payload,
* **When** an admin sends `/rbac reload`,
* **Then** the RBAC gateway re-indexes user roles in memory without restarting the bot container or breaking long-polling connections.

---

## Technical Constraints & Safety Bounds
- **Default Role**: Unrecognized users in the whitelist default to `ReadOnly` or are rejected outright if not whitelisted.
- **Audit Logging**: All denied authorization attempts are logged to Cloud Logging with user ID, requested action, and assigned role.

---

## Success Criteria & Validation
- Modular `RBACGateway` middleware implemented for command and tool routing.
- Schema definition for `roles.json` with role hierarchy (`Admin` > `StandardUser` > `ReadOnly`).
- Slash command `/rbac status` and `/rbac reload` implemented for admins.
- Executable test script `scripts/test_rbac_authorization.sh` verifying permission matrix enforcement and dynamic reloading.
