# Data Model: Model Router Session & State

## Session Model State Schema

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `session_id` | String | `"default"` | Telegram chat/session identifier |
| `active_model` | String | `"gemini-2.5-flash"` | Active LLM model name |
| `fallback_model` | String | `"gemini-2.5-flash"` | Secondary model when 429 occurs |
| `last_switch_timestamp` | Integer | Epoch time | Last slash command toggle time |
