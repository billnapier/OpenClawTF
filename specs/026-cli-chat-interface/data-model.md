# Data Model: CLI Chat Interface

No new database, table, or storage engine is introduced. This feature reuses the existing `memories` table owned by `scripts/vector_memory.py` (see `specs/015-vector-memory-engine/data-model.md`), with one additive column and one additive accessor method.

## Reused SQLite Table: `memories` (owned by `scripts/vector_memory.py`)

```sql
CREATE TABLE IF NOT EXISTS memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,      -- e.g. "cli" for the single CLI thread; "telegram:<chat_id>" etc. for other channels
    text TEXT NOT NULL,            -- message content (user turn or agent turn)
    embedding TEXT NOT NULL,       -- JSON-encoded float array (existing column, unchanged)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    role TEXT DEFAULT 'user'       -- NEW: 'user' | 'agent' — distinguishes who spoke a given turn
);
```

- **`role` (new column, additive migration)**: Existing rows (if any) default to `'user'` on migration; the CLI integration is the first writer to populate `'agent'` rows consistently, since `telegram_daemon.py` never wrote persisted turns at all (see research.md #3). Adding this column is backward compatible — `search_memory()` and existing callers that don't reference `role` are unaffected.

## New accessor on `VectorMemoryEngine` (additive, in `scripts/vector_memory.py`)

```python
def get_recent(self, session_id="default", limit=20):
    """Return the last `limit` turns for session_id in chronological order (oldest first),
    for inclusion as linear conversation context — complements search_memory()'s
    similarity-ranked retrieval, which is not sufficient on its own for 'refers back to
    the immediately preceding turn' recall (see research.md #3)."""
```

No change to `add_memory()`'s signature is required beyond passing `role` through; `session_id` continues to be the sole partition key, consistent with how Telegram/Discord would key their own conversations if/when they start persisting (out of scope here).

## Conceptual Entities (from spec.md "Key Entities")

### Chat Session
- **Represented as**: a `session_id` value (`"cli"`, or `"cli:<hostname>"` if the deployment ever needs host disambiguation — single fixed value per FR-002/FR-007's "one continuing thread per host").
- **Fields**: no separate session row exists; a session is the set of `memories` rows sharing that `session_id`, ordered by `created_at`.
- **Lifecycle**: created implicitly on first write; never expires (FR-004 — no idle timeout); spans process boundaries because it lives in SQLite, not in-memory (satisfies FR-002/FR-007's cross-invocation persistence).

### Message
- **Represented as**: one `memories` row.
- **Fields**: `text` (content), `role` (`user` | `agent` — sender), `created_at` (timestamp), `session_id` (implicitly identifies channel as `cli`).
- **Validation**: `text` MUST be valid UTF-8, non-binary, and ≤ the configured max length (proposed 8,000 chars) before being written or sent to the model — enforced by a new validator at the CLI entry point (see research.md #5), not by the `memories` schema itself (schema stays a plain `TEXT` column; validation is an application-layer gate before `add_memory()` is ever called for user input).

### Channel
- **Represented as**: the `CLIAdapter` class in `scripts/channel_gateway.py` (new, alongside existing `TelegramAdapter`/`DiscordAdapter`), and the fixed `session_id` prefix `"cli"` used when reading/writing `memories`.
- **Fields/behavior inherited from `ChannelAdapter`**: `channel_name` ("cli"), `is_authorized()` (overridden to always `True` per the SSH-boundary model — see research.md #2 and #4), `process_message()` (normalizes CLI input into the same shape Telegram/Discord adapters produce, for consistency of downstream handling even though only the CLI code path currently calls it for real).

## State Transitions

None beyond simple append-only history: a session has no explicit state machine (no "open"/"closed"/"expired" states per FR-004 — it is always available). The only transition worth naming is per-message validation:

```
raw input → [validate: UTF-8? size OK? not binary?] → reject (FR-010) | accept → CLIAdapter.process_message() → model call → agent response → persisted (both turns) → printed to terminal
```
