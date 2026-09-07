# Architecture Proposal: OpenClaw / NanoGemClaw on GCP with Terraform & Gemini

This document presents the high-level proposal for deploying **OpenClaw** (or **NanoGemClaw**) on Google Cloud Platform (GCP) Compute Engine (GCE), integrated with the **Google Gemini API** and **Telegram**, managed via **Terraform** and **`abcxyz/guardian`**.

---

## Executive Summary

The proposed architecture establishes a secure, automated, and persistent deployment of OpenClaw on GCP. Key highlights include:

* **Infrastructure-as-Code (IaC)**: Modular HCL configuration using Terraform.
* **GitOps & Automated CI/CD**: Keyless deployment authentication via Workload Identity Federation (WIF) and automated planning/applying using `abcxyz/guardian`.
* **Zero Inbound Attack Surface**: Single GCE VM in a private subnet with Cloud NAT egress; Telegram bot operates via outbound long-polling.
* **State & Data Protection**: Agent SQLite databases and memory reside on an independent, detached GCP Persistent Disk, surviving VM replacements.
* **Secret Security**: Sensitive API keys and access tokens reside in GCP Secret Manager and are injected at runtime without persisting to disk.

---

## Document Index

For complete technical specifications, repository structure, and execution phases, refer to:

* **[Product Requirements Document (docs/PRD.md)](PRD.md)**: Product vision, user personas (Administrator & End-User), Critical User Journeys (CUJs), onboarding, access control rejection UX, and error feedback protocols.
* **[Design Document (docs/Design.md)](Design.md)**: Detailed system architecture diagram, key architectural decisions (OS/container strategy, Guardian tooling, secret injection, storage), and modular Terraform layout.
* **[Implementation Roadmap (docs/Roadmap.md)](Roadmap.md)**: Four-phase deployment roadmap, Gantt chart, and task breakdowns from planning to Guardian CI/CD automation.
