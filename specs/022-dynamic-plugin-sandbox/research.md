# Technical Research: Dynamic Plugin Architecture

## Plugin Specifications
- **Plugin Location**: `/mnt/disks/openclaw-data/plugins/<plugin_name>.py`
- **Execution Isolation**: Process isolation via `subprocess.run(timeout=5)`.
- **Manifest Interface**: Each plugin exposes `PLUGIN_META = {"name": ..., "description": ...}` and `run(**kwargs)`.
