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
    VPC & Networking Module         :active, p2a1, 2026-09-07, 1d
    Secret Manager & IAM Module     :active, p2a2, 2026-09-07, 1d
    Persistent Disk Storage Module  :active, p2a3, 2026-09-07, 1d
    section Phase 2B: Compute Integration
    GCE Compute Module & Startup    :p2b, after p2a1, 1d
    section Phase 3: Container & Seeding
    Dockerfile & Artifact Reg Push  :p3a, after p2b, 1d
    Secret Payload Seeding Gate     :p3b, after p3a, 1d
    section Phase 4: Guardian CI/CD
    Guardian Plan & Deploy Workflows:p4a, after p3b, 1d
    section Phase 5: Release & Handover
    Pipeline & Disk Immutability Test:p5a, after p4a, 1d
    Access Audit & Runbook Handover :p5b, after p5a, 1d
```

---

## 2. Detailed Phase Tasks

### Phase 0: Environment & CI/CD Bootstrap *(Complete)*
* **GCS Terraform State Backend**: Provision initial Google Cloud Storage bucket for centralized Terraform state locking.
* **Workload Identity Federation (WIF)**: Set up initial GCP Workload Identity Pool and Provider for keyless GitHub Actions OIDC authentication.
* **Deployment Service Account**: Create Guardian CI/CD deployment service account with required IAM roles (`roles/storage.admin`, `roles/compute.admin`, `roles/secretmanager.admin`).

### Phase 1: Architecture & Specification *(Complete)*
* **Architecture Specs**: Finalized specs for Ubuntu 24.04 GCE VM, detached persistent disk, GCP Artifact Registry, direct Gemini API keys, Telegram bot gateway, and `abcxyz/guardian` GitOps CI/CD.

### Phase 2A: Parallel Modular IaC (Foundation)
* `modules/vpc`: VPC network, private subnet, Cloud Router, Cloud NAT (authored & validated concurrently).
* `modules/secrets`: Secret Manager resource definitions (`gemini-api-key`, `telegram-bot-token`, `telegram-allowed-user-ids`) and IAM Secret Accessor bindings.
* `modules/storage`: Standalone `google_compute_disk` persistent disk definition (`/mnt/disks/openclaw-data`).

### Phase 2B: Modular IaC (Compute Integration)
* `modules/compute`: `google_compute_instance` definition integrating VPC subnetwork, attached persistent disk, and `metadata_startup_script`.

### Phase 3: Containerization & Pre-Boot Seeding Gate
* `docker/Dockerfile`: Application container definition for OpenClaw.
* **Artifact Registry Image Push**: Build container image and push initial version to GCP Artifact Registry before VM provisioning.
* **Secret Payload Seeding Gate**: Seed Secret Manager with initial secret versions (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USER_IDS`) to prevent boot-time secret fetching errors.
* `docker/startup-script.sh`: VM bootstrap script to mount `/dev/disk/by-id/google-openclaw-data` to `/mnt/disks/openclaw-data`, fetch secrets from GCP Secret Manager, pull image from GCP Artifact Registry, and launch Docker container.

### Phase 4: Guardian CI/CD Automation Setup
* `.github/workflows/terraform-plan.yml`: Configure PR checks using `abcxyz/guardian-setup` to execute `guardian terraform plan -dir=terraform -storage=<GCS_STATE_BUCKET>`.
* `.github/workflows/deploy.yml`: Configure merge workflow using `abcxyz/guardian-setup` to run `guardian terraform apply`, build/push container image updates, and refresh GCE container service.

### Phase 5: Release Verification & Operational Handover
* **GitOps Pipeline Dry-Run**: Validate `terraform-plan.yml` on PR and `deploy.yml` on merge.
* **Disk Immutability & Persistence Test**: Execute simulated VM replacement (`terraform apply -replace`) and verify SQLite database state on persistent disk survives intact across VM recreation.
* **Access Control Verification**: Audit Telegram bot whitelist enforcement by verifying rejection behavior for unauthorized Telegram User IDs (per CUJ 3).
* **Operational Runbook & Handover**: Document secret rotation procedures, disk backup snapshots, and emergency rollback runbooks.
