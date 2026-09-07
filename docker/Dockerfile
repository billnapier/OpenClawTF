# Multi-stage Dockerfile for OpenClaw
FROM google/cloud-sdk:slim AS base

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    jq \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy application entrypoint and assets
COPY docker/entrypoint.sh /app/entrypoint.sh
COPY scripts /app/scripts
RUN chmod +x /app/entrypoint.sh /app/scripts/*.sh /app/scripts/*.py

# Persistent mount point directory setup
RUN mkdir -p /mnt/disks/openclaw-data

VOLUME ["/mnt/disks/openclaw-data"]

ENTRYPOINT ["/app/entrypoint.sh"]
