# Implementation Plan: Multi-Tenant Authorization & RBAC Gateway

## Architecture & Design
This feature provides Role-Based Access Control (RBAC) across OpenClaw commands and tool calls.

### Core Components
1. **RBAC Gateway (`scripts/rbac_gateway.py`)**:
   - Manages role assignments (`Admin`, `StandardUser`, `ReadOnly`) from `/mnt/disks/openclaw-data/config/roles.json`.
   - Evaluates command/action permission against role permissions.
   - Supports `/rbac status` and `/rbac reload`.

2. **Validation Suite (`scripts/test_rbac_authorization.sh`)**:
   - Tests permission checks for Admin vs StandardUser vs ReadOnly and dynamic role reloading.
