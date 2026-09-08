# Multi-stage Dockerfile for OpenClaw
FROM google/cloud-sdk:slim AS base

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    jq \
    sqlite3 \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir \
    uv==0.4.15 \
    mcp==1.2.0 \
    google-api-python-client==2.118.0 \
    google-auth==2.28.0 \
    google-auth-oauthlib==1.2.0 \
    google-workspace-mcp==1.2.0 || true

WORKDIR /app

# Copy application entrypoint and assets
COPY docker/entrypoint.sh /app/entrypoint.sh
COPY scripts /app/scripts
RUN chmod +x /app/entrypoint.sh /app/scripts/*.sh /app/scripts/*.py /app/scripts/openclaw && \
    ln -sf /app/scripts/openclaw /usr/local/bin/openclaw

# Persistent mount point directory setup
RUN mkdir -p /mnt/disks/openclaw-data

VOLUME ["/mnt/disks/openclaw-data"]

ENTRYPOINT ["/app/entrypoint.sh"]
