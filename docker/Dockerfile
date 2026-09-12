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

# Install the `gog` CLI (github.com/openclaw/gogcli) — pinned release, verified checksum.
# Spec 025 (Google Workspace Integration): tool_gateway.py shells out to this binary.
#
# Version/flag pin provenance (T001): this environment has no installable/runnable `gog`
# binary and no way to run `gog schema --json` live, so the pinned tag and the flags
# tool_gateway.py assumes (--json/--no-input/--from/--to/--summary/--body-file/etc., and
# the exit-code taxonomy 0/2/4/5/6/7/8) were verified via web research against
# https://github.com/openclaw/gogcli/releases and https://gogcli.sh docs instead of a live
# binary — see specs/025-google-workspace-clawhub/research.md Decision 8's verification
# note. GOG_VERSION below matched the latest published tag as of 2026-09-12. RE-VERIFY
# against the real binary (`gog schema --json`, `gog --version`) on first actual deploy
# before trusting this pin blindly.
ARG GOG_VERSION=v0.40.0
RUN set -eo pipefail; \
    curl -fsSL -o /tmp/gogcli.tar.gz "https://github.com/openclaw/gogcli/releases/download/${GOG_VERSION}/gogcli_${GOG_VERSION#v}_linux_amd64.tar.gz" && \
    curl -fsSL -o /tmp/checksums.txt "https://github.com/openclaw/gogcli/releases/download/${GOG_VERSION}/checksums.txt" && \
    (cd /tmp && grep "gogcli_${GOG_VERSION#v}_linux_amd64.tar.gz" checksums.txt | sha256sum -c -) && \
    tar -xzf /tmp/gogcli.tar.gz -C /tmp && \
    install -m 0755 /tmp/gog /usr/local/bin/gog && \
    rm -f /tmp/gogcli.tar.gz /tmp/checksums.txt /tmp/gog

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
