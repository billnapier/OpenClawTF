# Architecture Plan: Interactive Quickstart & Onboarding Skill

## Proposed Architecture
This feature creates an interactive onboarding skill (`skills/nanogemclaw.bootstrap/SKILL.md`) and a verification script (`scripts/verify_wif_bootstrap.sh`) to automate GCP infrastructure setup, secret injection, WIF provisioning, and GitHub configuration in 100% parity with `docs/Quickstart.md`.

### Directory Structure
```
skills/
└── nanogemclaw.bootstrap/
    └── SKILL.md                     # Antigravity interactive onboarding skill
scripts/
└── verify_wif_bootstrap.sh         # Automated validation script for GCP APIs, buckets, secrets, and WIF
specs/
└── 005-quickstart-skill/            # Spec design artifacts
    ├── spec.md
    ├── plan.md
    ├── research.md
    ├── data-model.md
    ├── quickstart.md
    └── tasks.md
```

## Step-by-Step Implementation Strategy

1. **Quickstart Onboarding Skill (`skills/nanogemclaw.bootstrap/SKILL.md`)**:
   - Environment Parameter Auto-Detection (GCP Project ID, Repo name, Region, Zone, State bucket).
   - Bulk Confirmation step presenting all detected settings in a single markdown table.
   - Sequential Secret Interview for missing credentials (`GEMINI_API_KEY`, `TELEGRAM_BOT_TOKEN`, `ALLOWED_USER_IDS`).
   - Automated `gcloud` actuation (enable APIs, GCS state bucket, Service Account, WIF pool/provider).
   - Automated `gh` CLI actuation (populate GitHub repository variables and secrets).

2. **Verification Script (`scripts/verify_wif_bootstrap.sh`)**:
   - Shell script that queries GCP APIs (`gcloud services list`), GCS bucket status (`gcloud storage buckets describe`), Service Account existence, WIF pool status, and GitHub secrets/variables (`gh variable list`, `gh secret list`) to report status.

3. **Validation Plan**:
   - Verify script syntax with `bash -n scripts/verify_wif_bootstrap.sh`.
   - Verify skill file structure and compliance with Constitution Principle 7.
