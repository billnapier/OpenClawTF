# Implementation Plan: Multi-Channel Transport Gateway (Telegram & Discord Adapter)

## Architecture & Design
This feature introduces an abstract `ChannelAdapter` pattern for unifying multi-platform message ingestion (Telegram & Discord).

### Core Components
1. **Multi-Channel Gateway Module (`scripts/channel_gateway.py`)**:
   - `ChannelAdapter` base class: defines `fetch_messages`, `send_message`, `verify_whitelist`.
   - `TelegramAdapter` & `DiscordAdapter` implementations.
   - Enforces user ID authorization against platform whitelist (`TELEGRAM_ALLOWED_USER_IDS`, `DISCORD_ALLOWED_USER_IDS`).

2. **Validation Suite (`scripts/test_channel_adapters.sh`)**:
   - Tests message normalization, multi-channel dispatch, and zero-trust whitelist rejection parity.
