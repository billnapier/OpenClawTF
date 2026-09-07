# Quickstart: Tool Execution Gateway

## Run Verification Tests

```bash
bash scripts/test_tool_execution.sh
```

## Available Tools
- `execute_python`: Run sandboxed Python snippets (10s limit, 2KB output cap).
- `read_file` / `write_file`: File access restricted to `/mnt/disks/openclaw-data` and `/tmp`.
- `get_system_status`: Inspect host GCE container CPU/RAM/disk metrics.
