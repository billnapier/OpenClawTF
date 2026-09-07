# Technical Research: Sandboxed Tool Execution

## Security & Timeout Controls
- **Subprocess Isolation**: Subprocess execution via `subprocess.run` with `timeout=10`.
- **Output Capping**: Limit stdout/stderr to 2048 bytes (2KB) max to prevent memory bloat.
- **Path Traversal Shield**: Reject any file path resolving outside designated allowed directories (`/mnt/disks/openclaw-data`, `/tmp`).
