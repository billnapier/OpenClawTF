# Technical Research: Multi-Channel Transport Abstraction

## Architecture Decoupling
- Abstract `UserMessage` struct normalizes `channel_type`, `user_id`, `chat_id`, and `text`.
- Platform adapters encapsulate API-specific secrets fetched from GCP Secret Manager (`openclaw-telegram-*`, `openclaw-discord-*`).
- Access rejection behavior returns standard unauthorized response message across all transport channels.
