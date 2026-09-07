# Technical Research: Multi-Tenant RBAC

## Role Matrix & Hierarchy
- `Admin`: Full access (`*`, admin commands, tool execution, cron, secrets, reset).
- `StandardUser`: Standard chat, memory commands (`/remember`, `/search`), read-only status commands.
- `ReadOnly`: Read-only queries (`/model status`, `/rbac status`).
- Storage path: `/mnt/disks/openclaw-data/config/roles.json`.
