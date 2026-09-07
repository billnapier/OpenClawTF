<!-- SYNC IMPACT REPORT
Version change: Initial → v1.0.0
Modified principles: None (Initial Creation)
Added sections:
  - Principle 1: Infrastructure as Code (Terraform)
  - Principle 2: GitOps Actuation via Guardian
  - Principle 3: Keyless Auth & Least Privilege Secrets
  - Principle 4: Decoupled State & Data Persistence
  - Principle 5: Containerized Artifact Supply Chain
Removed sections: None
Templates requiring updates:
  - .specify/templates/plan-template.md (✅ updated / aligned)
  - .specify/templates/spec-template.md (✅ updated / aligned)
  - .specify/templates/tasks-template.md (✅ updated / aligned)
Follow-up TODOs: None
-->

# OpenClawTF Project Constitution

**Version**: v1.0.0  
**Ratification Date**: 2026-09-06  
**Last Amended Date**: 2026-09-06  

---

## Executive Summary

The OpenClawTF Constitution establishes the foundational engineering principles, security standards, and operational governance for the OpenClaw / NanoGemClaw GCP deployment framework. All contributions, design specs, implementation plans, and CI/CD pipelines MUST strictly comply with this document.

---

## Core Engineering Principles

### Principle 1: Infrastructure as Code (Terraform)

All GCP infrastructure resources MUST be declared using modular Terraform (HCL) within the `terraform/` directory. Direct manual modification of infrastructure via the GCP Console or CLI ("click ops") is strictly prohibited. Infrastructure configurations MUST be modularized into discrete, single-responsibility modules (`vpc`, `iam`, `secrets`, `storage`, `compute`).

*Rationale: Infrastructure as Code ensures 100% reproducible, auditable, and version-controlled cloud environments.*

### Principle 2: GitOps Actuation via `abcxyz/guardian`

All infrastructure changes MUST be planned and applied exclusively via automated GitHub Actions workflows using `github.com/abcxyz/guardian`. Direct local `terraform apply` executions against production GCP projects are prohibited.

* Pull Requests MUST run `guardian terraform plan` to generate a non-destructive execution preview.
* Merges to the `main` branch MUST execute `guardian terraform apply` for controlled deployment actuation.

*Rationale: Enforces peer review, automated status checks, and auditable deployment history for all infrastructure mutations.*

### Principle 3: Keyless Auth & Least Privilege Secrets

Static GCP Service Account JSON keys are strictly forbidden. All authentication between GitHub Actions and GCP MUST use **Workload Identity Federation (WIF)** over OpenID Connect (OIDC).

Sensitive application configuration (e.g., `GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`) MUST be stored in GCP Secret Manager. Runtime containers MUST fetch secrets dynamically at startup via metadata identity; hardcoding secrets in environment files or git repositories is forbidden.

*Rationale: Prevents credential leaks and minimizes attack surfaces through short-lived tokens and scoped IAM roles.*

### Principle 4: Decoupled State & Data Persistence

Application state, SQLite database files, conversation memory, and persistent logs MUST be stored on independent, detached GCP Persistent Disks (`google_compute_disk`) mounted to VM host storage. Compute instances (VMs) MUST be treated as ephemeral; replacing or updating a GCE instance MUST NEVER cause data loss.

*Rationale: Guarantees business continuity and state preservation across VM updates, auto-healing, or OS upgrades.*

### Principle 5: Containerized Artifact Supply Chain

Application runtimes MUST be packaged as immutable Docker container images built via GitHub Actions and published to GCP Artifact Registry. Deployments MUST pull tagged or SHA-pinned container images rather than building software directly on target VM hosts.

*Rationale: Ensures consistent container runtimes and eliminates host-level dependency drift.*

---

## Governance & Amendment Policy

1. **Source of Truth**: This Constitution is the supreme authority for technical decisions in `billnapier/OpenClawTF`.
2. **Amendment Process**: Amendments to this Constitution require a Pull Request detailing the proposed change, rationale, and a Sync Impact Report updating all affected templates and documentation.
3. **Versioning Policy**:
   * **MAJOR** (e.g., v1.0.0 → v2.0.0): Incompatible principle removals or foundational architecture redefinitions.
   * **MINOR** (e.g., v1.0.0 → v1.1.0): New principles, expanded compliance checks, or structural additions.
   * **PATCH** (e.g., v1.0.0 → v1.0.1): Clarifications, wording refinements, or typo fixes.
4. **Compliance Enforcement**: All Pull Requests MUST be validated against this Constitution prior to merging into `main`.
