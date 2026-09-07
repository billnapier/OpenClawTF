# Feature Specification: Multi-Channel Transport Gateway (Telegram & Discord Adapter)

## Feature Overview & Objectives
The goal of this feature is to refactor OpenClaw's channel gateway into a modular `ChannelAdapter` architecture that decouples transport mechanics from core intelligence logic. 

This enables OpenClaw to concurrently support Discord Bot API integration alongside Telegram long-polling, while maintaining unified access whitelist enforcement, ADC secret management (`DISCORD_BOT_TOKEN`, `DISCORD_ALLOWED_USER_IDS`), and persistent conversation state on `/mnt/disks/openclaw-data`.

---

## User Stories & Acceptance Scenarios

### User Story 1: Modular Channel Adapter Architecture
* **As a** Developer,
* **I want** a unified `ChannelAdapter` abstraction interface,
* **So that** new chat platforms (Discord, Webhooks) can be added without duplicating core agent, memory, or LLM code.

#### Scenario 1.1: Multi-Channel Ingestion & Dispatch
* **Given** the core OpenClaw engine,
* **When** messages arrive from Telegram or Discord,
* **Then** the platform adapter normalizes incoming events into a standard `UserMessage` struct, dispatches to the agent engine, and formats responses appropriately for the originating channel.

---

### User Story 2: Discord Channel Integration & Whitelist Parity
* **As a** Cloud Administrator,
* **I want** to enable Discord support using GCP Secret Manager credentials,
* **So that** authorized users on Discord can interact with OpenClaw under the same zero-trust whitelist guarantees as Telegram.

#### Scenario 2.1: Discord Authorization & Secret Fetching
* **Given** `DISCORD_BOT_TOKEN` and `DISCORD_ALLOWED_USER_IDS` stored in GCP Secret Manager,
* **When** the container boots,
* **Then** the Discord adapter initializes polling/gateway connections, verifies incoming user IDs against `DISCORD_ALLOWED_USER_IDS`, rejects unauthorized access attempt with user ID feedback (matching CUJ 3), and routes authorized messages to OpenClaw.

---

## Success Criteria & Validation
- Abstract `ChannelAdapter` base interface implemented.
- Telegram gateway refactored to implement `ChannelAdapter`.
- Discord gateway adapter implemented using long-polling/gateway connection.
- GCP Secret Manager module updated for `discord-bot-token` and `discord-allowed-user-ids`.
- Zero-trust access rejection parity maintained on Discord (CUJ 3 compliance).
- Executable validation script `scripts/test_channel_adapters.sh` created to verify message routing, access control rejection, and multi-channel handling.
