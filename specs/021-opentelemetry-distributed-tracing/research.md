# Technical Research: OpenTelemetry & GCP Cloud Trace

## Trace & Sanitization Policy
- **Span Redaction**: Strip keys `GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `DISCORD_BOT_TOKEN` from trace attributes.
- **Span Hierarchy**: `root` -> `channel.receive` -> `rbac.authorize` -> `vector.search` -> `gemini.generate_content` -> `channel.reply`.
- **Exporting**: Batch span processor to avoid overhead on request latency path.
