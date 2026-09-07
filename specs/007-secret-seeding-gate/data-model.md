# Data Model: Secret Seeding Gate

## Target Secrets Schema
- `openclaw-gemini-api-key`: String payload (Gemini API token).
- `openclaw-telegram-bot-token`: String payload (Telegram Bot token).
- `openclaw-telegram-allowed-user-ids`: String payload (Comma-separated integer string, e.g. `12345678,87654321`).

## Script Exit Codes
- `0`: Success / Verification passed.
- `1`: Validation failed / Missing secrets / Auth error.
