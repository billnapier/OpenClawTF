# OpenClaw Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-09-12

## Active Technologies
- Python 3 (matches existing `scripts/*.py`); `gog` itself is a prebuilt Go binary, not compiled in this repo + `gog` CLI binary (pinned release tag, installed via direct GitHub release download in `docker/Dockerfile`) — no new Python package dependencies (025-google-workspace-clawhub)
- `gog`'s own encrypted token file, stored under `/mnt/disks/openclaw-data/gogcli` (persistent disk, Principle 4) — no new SQLite tables or application-level storage (025-google-workspace-clawhub)

- Python 3 (matches existing `scripts/*.py` — no version pin found repo-wide beyond `#!/usr/bin/env python3`; follows existing convention) + Standard library only (`argparse`, `sqlite3` via `vector_memory.py`, `urllib.request` via the shared Gemini-call helper) — no new third-party dependency introduced, consistent with existing `scripts/*.py` modules. (026-cli-chat-interface)

## Project Structure

```text
src/
tests/
```

## Commands

cd src [ONLY COMMANDS FOR ACTIVE TECHNOLOGIES][ONLY COMMANDS FOR ACTIVE TECHNOLOGIES] pytest [ONLY COMMANDS FOR ACTIVE TECHNOLOGIES][ONLY COMMANDS FOR ACTIVE TECHNOLOGIES] ruff check .

## Code Style

Python 3 (matches existing `scripts/*.py` — no version pin found repo-wide beyond `#!/usr/bin/env python3`; follows existing convention): Follow standard conventions

## Recent Changes
- 025-google-workspace-clawhub: Added Python 3 (matches existing `scripts/*.py`); `gog` itself is a prebuilt Go binary, not compiled in this repo + `gog` CLI binary (pinned release tag, installed via direct GitHub release download in `docker/Dockerfile`) — no new Python package dependencies

- 026-cli-chat-interface: Added Python 3 (matches existing `scripts/*.py` — no version pin found repo-wide beyond `#!/usr/bin/env python3`; follows existing convention) + Standard library only (`argparse`, `sqlite3` via `vector_memory.py`, `urllib.request` via the shared Gemini-call helper) — no new third-party dependency introduced, consistent with existing `scripts/*.py` modules.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
