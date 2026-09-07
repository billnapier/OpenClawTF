# Deployment Implementation Roadmap: OpenClaw on GCP

This document tracks the milestones, phases, and execution schedule for provisioning and deploying **OpenClaw** on Google Cloud Platform (GCP) using Terraform and `abcxyz/guardian`.

---

## 1. Timeline & Phases Overview

```mermaid
gantt
    title Deployment Implementation Roadmap
    dateFormat  YYYY-MM-DD
    section Phase 0: CI/CD Bootstrap
    GCS State Bucket & WIF Setup     :done, p0a, 2026-09-06, 1d
    section Phase 1: Arch & Specs
    Finalize Arch & PRD Specs       :done, p1a, 2026-09-06, 1d
    section Phase 2A: Parallel IaC Foundation
    VPC & Networking Module         :done, p2a1, 2026-09-07, 1d
    Secret Manager & IAM Module     :done, p2a2, 2026-09-07, 1d
    Persistent Disk Storage Module  :done, p2a3, 2026-09-07, 1d
    section Phase 2B: Compute Integration
    GCE Compute Module & Startup    :done, p2b, 2026-09-07, 1d
    section Phase 3: Container & Seeding
    Dockerfile & Artifact Reg Push  :done, p3a, 2026-09-07, 1d
    Secret Payload Seeding Gate     :done, p3b, 2026-09-07, 1d
    section Phase 4: Guardian CI/CD
    Guardian Plan & Deploy Workflows:done, p4a, 2026-09-07, 1d
    section Phase 5: Release & Handover
    Pipeline & Disk Immutability Test:done, p5a, 2026-09-07, 1d
    Access Audit & Runbook Handover :done, p5b, 2026-09-07, 1d
    section Phase 6: Operational Resilience
    Disk Snapshot Policy (Spec 010) :done, p6a, 2026-09-07, 1d
    Telegram Whitelist Utility (Spec 011) :done, p6b, after p6a, 1d
    Cloud Monitoring & Alerts (Spec 012) :done, p6c, after p6b, 1d
    Secret Rotation Verifier (Spec 013) :done, p6d, after p6c, 1d
36:     section Phase 7 (Milestone 3): Intelligence & Multi-Channel
37:     Gemini Model Routing (Spec 014) :done, p7a, 2026-09-07, 1d
38:     Vector Memory Engine (Spec 015) :done, p7b, after p7a, 1d
39:     Tool Execution Gateway (Spec 016) :done, p7c, after p7b, 1d
40:     Multi-Channel Gateway (Spec 017) :done, p7d, after p7c, 1d
41:     Disaster Recovery Restoration (Spec 018) :done, p7e, after p7d, 1d
42:     section Phase 8 (Milestone 4): Enterprise Ops & Autonomous Workflows
43:     Autonomous Cron Workflows (Spec 019) :active, p8a, 2026-09-07, 1d
44:     Multi-Tenant RBAC Authorization (Spec 020) :p8b, after p8a, 1d
45:     OpenTelemetry Distributed Tracing (Spec 021) :p8c, after p8b, 1d
46:     Dynamic Tool Plugin Sandbox (Spec 022) :p8d, after p8c, 1d
47:     HA Failover & Migration Verifier (Spec 023) :p8e, after p8d, 1d
48: ```
49: 
50: ---
51: 
52: ## 2. Detailed Phase Tasks
53: 
54: ### Phase 0: Environment & CI/CD Bootstrap *(Complete)*
55: * **GCS Terraform State Backend**: Provision initial Google Cloud Storage bucket for centralized Terraform state locking.
56: * **Workload Identity Federation (WIF)**: Set up initial GCP Workload Identity Pool and Provider for keyless GitHub Actions OIDC authentication.
57: * **Deployment Service Account**: Create Guardian CI/CD deployment service account with required IAM roles (`roles/storage.admin`, `roles/compute.admin`, `roles/secretmanager.admin`).
58: 
59: ### Phase 1: Architecture & Specification *(Complete)*
60: * **Architecture Specs**: Finalized specs for Ubuntu 24.04 GCE VM, detached persistent disk, GCP Artifact Registry, direct Gemini API keys, Telegram bot gateway, and `abcxyz/guardian` GitOps CI/CD.
61: 
62: ### Phase 2A: Parallel Modular IaC (Foundation) *(Complete)*
63: * `modules/vpc`: VPC network, private subnet, Cloud Router, Cloud NAT (authored & validated concurrently).
64: * `modules/secrets`: Secret Manager resource definitions (`gemini-api-key`, `telegram-bot-token`, `telegram-allowed-user-ids`) and IAM Secret Accessor bindings.
65: * `modules/storage`: Standalone `google_compute_disk` persistent disk definition (`/mnt/disks/openclaw-data`).
66: 
67: ### Phase 2B: Modular IaC (Compute Integration) *(Complete)*
68: * `modules/compute`: `google_compute_instance` definition integrating VPC subnetwork, attached persistent disk, and `metadata_startup_script`.
69: 
70: ### Phase 3: Containerization & Pre-Boot Seeding Gate *(Complete)*
71: * `docker/Dockerfile`: Application container definition for OpenClaw.
72: * **Artifact Registry Image Push**: Build container image and push initial version to GCP Artifact Registry before VM provisioning.
73: * **Secret Payload Seeding Gate**: Seed Secret Manager with initial secret versions (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USER_IDS`) to prevent boot-time secret fetching errors.
74: * `docker/startup-script.sh`: VM bootstrap script to mount `/dev/disk/by-id/google-openclaw-data` to `/mnt/disks/openclaw-data`, fetch secrets from GCP Secret Manager, pull image from GCP Artifact Registry, and launch Docker container.
75: 
76: ### Phase 4: Guardian CI/CD Automation Setup *(Complete)*
77: * `.github/workflows/terraform-plan.yml`: Configure PR checks using `abcxyz/guardian-setup` to execute `guardian terraform plan -dir=terraform -storage=<GCS_STATE_BUCKET>`.
78: * `.github/workflows/deploy.yml`: Configure merge workflow using `abcxyz/guardian-setup` to run `guardian terraform apply`, build/push container image updates, and refresh GCE container service.
79: 
80: ### Phase 5: Release Verification & Operational Handover *(Complete)*
81: * **GitOps Pipeline Dry-Run**: Validate `terraform-plan.yml` on PR and `deploy.yml` on merge.
82: * **Disk Immutability & Persistence Test**: Execute simulated VM replacement (`terraform apply -replace`) and verify SQLite database state on persistent disk survives intact across VM recreation.
83: * **Access Control Verification**: Audit Telegram bot whitelist enforcement by verifying rejection behavior for unauthorized Telegram User IDs (per CUJ 3).
84: * **Operational Runbook & Handover**: Document secret rotation procedures, disk backup snapshots, and emergency rollback runbooks.
85: 
86: ### Phase 6: Day-2 Operational Resilience & Security Hardening *(Complete)*
87: * **Spec 010: Automated Disk Snapshot Policy**: Define Terraform `google_compute_resource_policy` for daily disk snapshots with 7-day retention and automated verification script (`scripts/verify_disk_snapshots.sh`).
88: * **Spec 011: Telegram Whitelist Management Utility**: Develop `scripts/manage_whitelist.sh` for auditing, validating, adding, and removing allowed Telegram User IDs in Secret Manager with zero downtime.
89: * **Spec 012: GCP Cloud Monitoring & Health Metrics**: Provision Terraform `google_monitoring_alert_policy` resources and log-based metrics for GCE container restarts, Gemini rate limits (429), and unauthorized access attempts.
90: * **Spec 013: Automated Secret Rotation & Verification**: Author `scripts/rotate_and_verify_secrets.sh` to execute safe runtime credential rotation with post-rotation container state and database health verification.
91: 
92: ### Phase 7 (Milestone 3): Advanced Intelligence, Multi-Channel Gateway & Disaster Recovery *(Complete)*
93: * **Spec 014: Gemini Multi-Model Routing & Fallback Engine**: Multi-model dynamic switching (`gemini-2.5-flash` vs `gemini-2.5-pro`) via slash commands (`/model`) and automated HTTP 429 rate-limit fallback.
94: * **Spec 015: Vector Context Search & Semantic Memory Engine**: Persistent vector embedding storage on persistent disk (`vector_memory.db`) with Gemini embedding API, `/remember`, `/search`, and RAG context injection.
95: * **Spec 016: Tool Execution Gateway & Sandboxed Runtime**: Function calling engine for Gemini with restricted Python execution sandbox, persistent disk file operations (`/mnt/disks/openclaw-data`), 10s timeout bounds, and 2KB output truncation.
96: * **Spec 017: Multi-Channel Transport Gateway (Telegram & Discord)**: Abstract `ChannelAdapter` supporting Discord Bot API long-polling alongside Telegram with zero-trust access control whitelist parity.
97: * **Spec 018: Automated Disaster Recovery & Snapshot Restoration Verifier**: `scripts/disaster_recovery_restore.sh` utility to automate point-in-time state recovery from GCP disk snapshots with post-recovery SQLite database integrity checks.
98: 
99: ### Phase 8 (Milestone 4): Enterprise Operations, Autonomous Workflows & Multi-Tenant Security *(Active)*
100: * **Spec 019: Scheduled Autonomous Workflows & Cron Gateway**: Background cron scheduler engine for recurring prompts and automated tool executions with channel notifications and SQLite execution locks on persistent disk.
101: * **Spec 020: Multi-Tenant Authorization & RBAC Gateway**: Fine-grained role-based access control (`Admin`, `User`, `Read-Only`) for multi-tenant environments with dynamic role definition reloads.
102: * **Spec 021: OpenTelemetry APM & Distributed Tracing**: Complete observability instrumentation for Gemini API latency, vector search runtime, and tool execution tracing exported to GCP Cloud Trace.
103: * **Spec 022: Dynamic Tool Plugin Sandbox & Runtime**: Plugin architecture enabling dynamic loading of custom python/js extensions stored on persistent disk (`/mnt/disks/openclaw-data/plugins`).
104: * **Spec 023: High Availability Failover & Migration Verifier**: Automated zero-downtime failover and state synchronization verifier script (`scripts/verify_ha_failover.sh`) across regional standby nodes.


