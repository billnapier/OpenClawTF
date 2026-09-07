# Research & Design Decisions: Compute Module

## Key Architectural Decisions

1. **Container-Optimized OS (COS)**:
   - COS is GCP's lightweight, security-hardened image optimized for running Docker containers out-of-the-box.

2. **No Public IP Address (Private Subnet)**:
   - Eliminating public IPv4 addresses on the VM minimizes external attack vectors. Outbound Internet access for pulling container images and calling APIs (Gemini, Telegram) is routed securely through Cloud NAT.

3. **Predictable Persistent Disk Mounting**:
   - GCE maps persistent disk device names under `/dev/disk/by-id/google-<device_name>`.
   - Setting `device_name = "openclaw-data"` ensures the startup script can always locate `/dev/disk/by-id/google-openclaw-data` reliably regardless of device node assignment order.
