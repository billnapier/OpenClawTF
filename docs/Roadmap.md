# Deployment Implementation Roadmap: OpenClaw / NanoGemClaw on GCP

This document tracks the milestones, phases, and execution schedule for provisioning and deploying **OpenClaw** (or **NanoGemClaw**) on Google Cloud Platform (GCP) using Terraform and `abcxyz/guardian`.

---

## 1. Timeline & Phases Overview

```mermaid
gantt
    title Deployment Implementation Roadmap
    dateFormat  YYYY-MM-DD
    section Phase 1: Planning & Arch
    Finalize Guardian & GCE Arch :done, p1a, 2026-09-06, 1d
    section Phase 2: Modular IaC (HCL)
    VPC, NAT & Networking Module  :active, p2a, 2026-09-07, 1d
    Secret Manager & IAM Module   :p2b, after p2a, 1d
    Persistent Disk & Storage Mod :p2c, after p2b, 1d
    GCE Compute Module & Startup  :p2d, after p2c, 1d
    section Phase 3: Container & App
    Dockerfile & Telegram Gateway :p3a, after p2d, 1d
    Startup Script & Secret Pull  :p3b, after p3a, 1d
    section Phase 4: Guardian CI/CD
    Workload Identity Setup       :p4a, after p3b, 1d
    Guardian GitHub Workflows     :p4b, after p4a, 1d
```

---

## 2. Detailed Phase Tasks

### Phase 1: Architecture & Specification *(Complete)*
* Architecture finalized for Container-Optimized OS (COS) GCE VM, detached persistent disk with idempotent `blkid` formatting, GCP Artifact Registry, runtime Secret Manager access via ADC, Telegram channel gateway with SIGTERM handlers and retry backoffs, and **`abcxyz/guardian`** GitOps CI/CD with GCE metadata container updates.

### Phase 2: Modular Terraform Infrastructure (HCL)
* `modules/vpc`: VPC network, private subnet, Cloud Router, Cloud NAT.
* `modules/secrets`: Secret Manager definitions (`gemini-api-key`, `telegram-bot-token`, `telegram-allowed-user-ids`).
* `modules/iam`: Service Accounts, Secret Accessor bindings, WIF Pool & Provider.
* `modules/storage`: Independent `google_compute_disk` resource.
* `modules/compute`: `google_compute_instance` with COS base image and metadata startup script for idempotent disk mount.

### Phase 3: Containerization & Startup Logic
* `docker/Dockerfile`: OpenClaw / NanoGemClaw application image with SIGTERM graceful shutdown and startup backoff retries.
* `docker/entrypoint.sh`: Container entrypoint fetching secrets from GCP Secret Manager API using ADC (`roles/secretmanager.secretAccessor`).
* `docker/startup-script.sh`: VM bootstrap: inspect filesystem via `blkid`, format with `mkfs.ext4` if unformatted, mount `/dev/disk/by-id/google-openclaw-data` to `/mnt/disks/openclaw-data`.

### Phase 4: Guardian CI/CD Pipeline Setup
* Set up `.github/workflows/terraform-plan.yml` using `abcxyz/guardian-setup` to run `guardian terraform plan -dir=terraform -storage=<GCS_STATE_BUCKET>`.
* Set up `.github/workflows/deploy.yml` using `abcxyz/guardian-setup` to run `guardian terraform apply -dir=terraform -storage=<GCS_STATE_BUCKET>`, build & push Docker image to GCP Artifact Registry, and trigger GCE VM container metadata update via `gcloud compute instances update-container`.
