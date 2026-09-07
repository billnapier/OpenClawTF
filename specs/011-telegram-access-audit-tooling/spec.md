# Feature Specification: Telegram User Whitelist Audit & Admin Management Utility

## Feature Overview & Objectives
The goal of this feature is to streamline access control management for OpenClaw administrators by providing a dedicated, automated management utility (`scripts/manage_whitelist.sh`). The script will allow administrators to audit, validate, add, remove, and list allowed Telegram User IDs stored in GCP Secret Manager (`telegram-allowed-user-ids`), eliminating manual secret manipulation errors and ensuring zero downtime when updating user access permissions.

---

## User Stories & Acceptance Scenarios

### User Story 1: Command-Line Whitelist Audit & Inspection
* **As a** Cloud Administrator,
* **I want** to list and audit currently whitelisted Telegram User IDs via a CLI utility (`scripts/manage_whitelist.sh list`),
* **So that** I can easily inspect active user permissions and secret version history without manual GCP Console navigation.

#### Scenario 1.1: Listing Whitelisted User IDs
* **Given** an active Secret Manager secret `telegram-allowed-user-ids`,
* **When** `./scripts/manage_whitelist.sh list` is executed,
* **Then** the script displays a clean formatted table of allowed numeric Telegram User IDs and active secret version information.

---

### User Story 2: Safe Whitelist Addition & Removal
* **As a** Cloud Administrator,
* **I want** to add or remove Telegram User IDs using `./scripts/manage_whitelist.sh add <ID>` and `./scripts/manage_whitelist.sh remove <ID>`,
* **So that** new users are granted access instantly with numeric ID validation, duplicate prevention, and zero service interruption.

#### Scenario 2.1: Adding a Valid Telegram User ID
* **Given** a valid numeric Telegram User ID (e.g. `987654321`),
* **When** `./scripts/manage_whitelist.sh add 987654321` is run,
* **Then** the utility validates the ID format, appends it to the list without duplicates, writes a new version to GCP Secret Manager, and outputs success confirmation.

#### Scenario 2.2: Rejecting Invalid Telegram User ID Format
* **Given** an invalid user ID string (e.g. `invalid_user`),
* **When** `./scripts/manage_whitelist.sh add invalid_user` is run,
* **Then** the utility aborts with error code `1` and outputs `"Error: Telegram User ID must be a numeric string."`

---

## Success Criteria & Validation
- Executable script `scripts/manage_whitelist.sh` created supporting `list`, `add`, `remove`, and `audit` subcommands.
- Strict numeric regex validation enforcing proper Telegram ID formats.
- Integration tests in script verifying correct Secret Manager payload formatting (comma-separated ID strings).
