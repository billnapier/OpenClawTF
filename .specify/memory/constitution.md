<!-- SYNC IMPACT REPORT
Version change: v1.2.0 → v1.3.0
Modified principles: None
Added sections:
  - Principle 8: Prefer Native Framework Capabilities & Maximum Component Reuse
  - Principle 9: Immutable Read-Only Container Image Binaries
Removed sections: None
Templates requiring updates:
  - docs/Quickstart.md (✅ checked / aligned)
  - skills/openclaw.bootstrap/SKILL.md (✅ checked / aligned)
Follow-up TODOs: None
-->

# OpenClawTF Project Constitution

**Version**: v1.3.0  
**Ratification Date**: 2026-09-06  
**Last Amended Date**: 2026-09-07  

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

### Principle 6: Explicit Version Pinning & LLM Verification

All software dependencies—including Terraform provider versions, Terraform module sources, GitHub Actions (`uses: action@vX.Y.Z`), Docker base images, and package ecosystem libraries—MUST specify explicit, real, pinned version numbers. Unpinned or floating version specifiers (such as `@latest`, `@main`, `^x.y.z`, or `~> x.y`) are strictly prohibited in production configurations.

Furthermore, the AI coding assistant / LLM MUST actively verify that all referenced version strings exist in public registries or release APIs before committing configuration code.

*Rationale: Prevents supply chain vulnerability exposure, silent breaking changes, and non-deterministic deployment build failures.*

### Principle 7: Synchronized Manual Setup Documentation & Interactive Onboarding Skill

All required manual configuration and GCP setup prerequisites MUST be documented in human-readable Markdown format in `docs/Quickstart.md` (and related module quickstarts). Furthermore, a dedicated executable onboarding skill (e.g., `openclaw.bootstrap` / QuickStart skill) MUST be provided to allow users to interactively perform or verify the setup with Antigravity.

The onboarding skill MUST assume sensible defaults for all input parameters, explicitly prompt the user to review and confirm or change those parameters prior to execution, and maintain strict functional parity with `docs/Quickstart.md` at all times. Whenever manual setup procedures change, `docs/Quickstart.md` and the onboarding skill MUST be updated simultaneously.

*Rationale: Ensures seamless developer onboarding, eliminates documentation drift, and reduces setup friction for cloud infrastructure deployment.*

### Principle 8: Prefer Native Framework Capabilities & Maximum Component Reuse

Custom one-off scripts, ad-hoc hacks, or duplicate custom implementations MUST NOT be created when existing native OpenClaw framework capabilities (such as Gemini Function Calling, `tool_gateway.py`, `plugin_runner.py`, or Model Context Protocol / MCP) can achieve the desired outcome. All features and integrations MUST reuse and extend established OpenClaw abstractions.

*Rationale: Prevents non-standard ad-hoc code sprawl, reduces maintenance overhead, and maintains architectural consistency across the OpenClaw ecosystem.*

### Principle 9: Immutable Read-Only Container Image Binaries

All executable binaries, CLI tools, custom scripts, and runtime dependencies MUST be installed and packaged into the read-only Docker container image during the build phase (`Dockerfile`). Binaries and executable code MUST NOT be stored on persistent disk volumes (`/mnt/disks/openclaw-data`) or dynamically downloaded onto the host at runtime. Persistent disks MUST be reserved strictly for stateful data, database files, and application logs.

*Rationale: Guarantees container immutability, deterministic deployments, rapid VM recovery, and zero host-level executable drift.*

---

## Governance & Amendment Policy

1. **Source of Truth**: This Constitution is the supreme authority for technical decisions in `billnapier/OpenClawTF`.
2. **Amendment Process**: Amendments to this Constitution require a Pull Request detailing the proposed change, rationale, and a Sync Impact Report updating all affected templates and documentation.
3. **Versioning Policy**:
   * **MAJOR** (e.g., v1.0.0 → v2.0.0): Incompatible principle removals or foundational architecture redefinitions.
   * **MINOR** (e.g., v1.0.0 → v1.3.0): New principles, expanded compliance checks, or structural additions.
   * **PATCH** (e.g., v1.0.0 → v1.0.1): Clarifications, wording refinements, or typo fixes.
4. **Compliance Enforcement**: All Pull Requests MUST be validated against this Constitution prior to merging into `main`.
