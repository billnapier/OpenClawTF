# Research: Google Workspace Integration via `gog`

## Decision 1: `gog` is a real, published, standalone CLI — not an MCP-style agent bridge

`gog` (package `gogcli`, ClawHub listing `steipete/gog`, source `github.com/openclaw/gogcli`) is an actively maintained Go binary (latest tag `v0.40.0`, 2026-09-11) with a documented, stable command surface and 5.5k+ ClawHub installs. It is invoked as a normal OS subprocess — `gog <service> <action> [args] --json --no-input` — and prints a single JSON document to stdout per call. This is materially different from Spec 024's approach (a persistent MCP server process speaking stdio JSON-RPC), and avoids exactly the protocol-handshake fragility that sank that attempt: there is no long-lived server, no custom RPC framing, and no schema translation layer between `gog`'s JSON and Gemini — `tool_gateway.py` just shells out per call like it already does for `execute_python`.

**Rationale**: Satisfies Principle 10 (ClawHub-first for Google integrations) for real, not just declaratively. **Alternatives considered**: re-attempt an MCP server (rejected — same failure mode as Spec 024); hand-roll a Python `google-api-python-client` integration (rejected — Principle 8, duplicates what `gog` already solves, including OAuth lifecycle).

## Decision 2: Install the `gog` binary into the image at build time, pinned

Install via direct GitHub release binary (`gogcli_<version>_linux_amd64.tar.gz` + `checksums.txt` verification) in `docker/Dockerfile`, pinned to an explicit tag (Principle 6 — no `@latest`). Rejected `brew install` (Homebrew is heavyweight and unusual in a minimal `apt`-based Debian image) and `go install` (would require adding a full Go toolchain to the build stage for one binary). The binary itself stays in the read-only image (Principle 9); only its runtime *state* goes to the persistent disk (Decision 3).

## Decision 3: Credential storage — encrypted file backend on the persistent disk, not the platform keyring

`gog`'s default token storage uses the OS keyring (GNOME Keyring / macOS Keychain via D-Bus Secret Service), which is unavailable in a minimal headless container — and is a **known-broken combination**: upstream issues [#389](https://github.com/openclaw/gogcli/issues/389) and [#268](https://github.com/openclaw/gogcli/issues/268) document the file-keyring passphrase prompt hanging or being silently unrecognized specifically in non-TTY headless environments unless configured explicitly. The documented fix is to force the encrypted file backend and supply the passphrase via environment variable rather than an interactive prompt:

```
GOG_KEYRING_BACKEND=file
GOG_KEYRING_PASSWORD=<passphrase>
GOG_HOME=/mnt/disks/openclaw-data/gogcli
```

`GOG_HOME` is explicitly documented as configurable for exactly this container use case ("You can set `GOG_HOME` to a custom path like `/persist/gogcli` when running with docker") and maps directly onto this project's existing persistent-disk convention (Principle 4) — the encrypted token file survives VM/container replacement; the binary does not need to.

**Operational note carried into tasks**: because the OpenClaw daemon runs as a container process (effectively a systemd-managed service), `GOG_KEYRING_PASSWORD` must be injected into *that* process's environment directly (e.g. `docker/entrypoint.sh`) — a value only present in an interactive login shell does not reach it.

## Decision 4: `GOG_KEYRING_PASSWORD` is a secret and belongs in GCP Secret Manager — correcting spec.md

spec.md's Constitutional Alignment section states "no secrets are stored in GCP Secret Manager for Google Workspace." That's true of the OAuth *token* itself (`gog` manages its lifecycle, encrypted, on the persistent disk) — but it is not true of the passphrase protecting that encrypted file. Per this project's own Principle 3 ("sensitive application configuration... MUST be stored in GCP Secret Manager... fetched dynamically at startup"), `GOG_KEYRING_PASSWORD` must be treated exactly like `GEMINI_API_KEY`/`TELEGRAM_BOT_TOKEN`: a new secret (e.g. `gog-keyring-password`) added to `terraform/modules/secrets/main.tf`, fetched at container startup in `docker/entrypoint.sh`. This is a small, additive Terraform change, not a new pattern. **plan.md's Constitution Check reflects this correction rather than repeating spec.md's claim as-is.**

## Decision 5: The one-time OAuth grant cannot be automated — it's an onboarding step

`gog auth credentials <client_secret.json>` (loading a GCP OAuth client) followed by `gog auth add <email> --services ...` requires a real browser-based consent flow from the account owner; it cannot run unattended in CI or at container startup. This is a manual, one-time setup step — documented in `docs/Quickstart.md` and wired into `skills/openclaw.bootstrap/SKILL.md` per Principle 7, matching spec.md's own "Dependencies & Blockers" framing. `gog auth doctor --check --no-input` is a real, documented health-check command — use it both in the bootstrap skill's verification step and as a container-startup sanity check (log a clear warning, don't crash the daemon, if it fails).

## Decision 6: `tool_gateway.py` needs two new real methods — replacing dead code, not adding alongside it

Tracing the current codebase found that Spec 024's revert left **dangling references**, not a clean rollback: `scripts/model_router.py:83` calls `gw.list_mcp_tools()` and `scripts/telegram_daemon.py:143` calls `gw.call_mcp_tool(...)` — neither method exists on `ToolGateway` (`scripts/tool_gateway.py`, 92 lines, only defines `execute_python`, `write_file`, `read_file`, `get_system_status`). In practice today: `model_router.get_tools()` swallows the resulting `AttributeError` in a bare `except Exception: pass` and returns `[]`, so Gemini is silently given zero tools and never attempts calendar/Gmail/Drive queries via natural language — while the hardcoded `/calendar`, `/gmail`, `/drive` Telegram slash commands (`telegram_daemon.py:226-270`) call `gw.call_mcp_tool()` directly with **no** exception handling and would crash with an uncaught `AttributeError` if a user actually sent one. The bot's own `/status` reply text ("Workspace MCP Integration: Active") is currently false.

This spec's implementation is therefore not purely additive — it's the fix. `list_mcp_tools()` and `call_mcp_tool(fn_name, args_json)` need real implementations backed by `gog` subprocess calls (see data-model.md for the name→CLI mapping), replacing the dangling calls in place so the existing `telegram_daemon.py` wiring (tool declarations → Gemini function-calling → turn-2 synthesis, already fixed for history-injection in Spec 026) starts working end-to-end rather than needing a parallel new code path.

## Decision 7: Read/write safety — confirm before mutating actions

`gog`'s own documented convention is "confirm before sending mail or creating events." Mutating calls (`gmail send`, `gmail drafts send`, `calendar create`/`update`, `sheets update`/`append`/`clear`, `tasks add`/`update`/`done`) require an explicit user-facing confirmation step before `tool_gateway.py` actually invokes them — consistent with spec.md's own User Story phrasing ("Schedule a meeting with Sarah at 2pm tomorrow" implies a propose-then-confirm flow, not silent action). Read-only calls (`gmail search`, `calendar events`, `drive search`, `contacts list`, `sheets get`, `docs cat`/`export`, `tasks list`) should additionally pass `--readonly` as a defense-in-depth guard even though the calling code should already be routing only query-shaped intents there.

## Decision 8: Command surface for the three spec'd user stories — all confirmed to exist

- **Calendar (US1)**: `gog calendar events <calendarId> --from <iso> --to <iso> --json`, `gog calendar create <calendarId> --summary ... --from ... --to ...`.
- **Gmail (US2)**: `gog gmail search '<query>' --max N --json`, `gog gmail messages search '<query>' --json` for individual message detail.
- **Tasks (US3)**: `gog tasks list --json`, `gog tasks add <tasklistId> --title T [--notes N] [--due RFC3339|YYYY-MM-DD]`, `gog tasks done <tasklistId> <taskId>`.

All three are documented, real subcommands — no NEEDS CLARIFICATION remains on command availability. Exact flag names should still be re-verified against `gog schema --json` (the tool's own live introspection command, per its docs "the running command tree is the source of truth") at implementation time, since a doc snapshot can drift from the pinned binary version.

> **T001 verification note (2026-09-12, implementation time)**: This build environment has no installable/runnable `gog` binary, so `gog schema --json` could not be executed live. As a substitute, the following were confirmed via web research against the project's own published docs:
> - `https://github.com/openclaw/gogcli/releases` — `v0.40.0` (2026-09-11) is still the latest tag, matching this doc's snapshot. No version drift.
> - `https://gogcli.sh/automation.html` — global flags `--json`, `--plain`, `--no-input`, `--readonly`, `--account`, `--no-cache` confirmed as documented. Exit code taxonomy confirmed byte-for-byte: `0 ok`, `2 usage`, `4 auth_required`, `5 not_found`, `6 permission_denied`, `7 rate_limited`, `8 retryable` (plus `1 error`, `3 empty_results`, `10 config`, `11 orphaned`, `130 cancelled`, which this feature does not branch on) — this doc's and data-model.md's exit-code assumptions are correct as written.
> - Command names and flag shapes confirmed via `docs/commands/gog-calendar*.md`, gmail-workflows.html, and search-indexed docs snippets: `gog calendar create [primary] --summary ... --from ... --to ...`, `gog gmail send --to ... --subject ... --body-file <path|->`, `gog tasks add <tasklistId> --title ... --due <RFC3339|YYYY-MM-DD>`, `gog tasks done <tasklistId> <taskId>` — all consistent with the mapping table below.
> - **Not independently verified**: the exact release-asset filenames for `v0.40.0` (GitHub's asset list failed to render during this research; the `gogcli_<version>_linux_amd64.tar.gz` + `checksums.txt` naming in T002/Dockerfile is the project's prior assumption plus standard `goreleaser` convention, not a byte-for-byte confirmed filename).
> - **This is docs-research verification, not a live `gog schema --json` run.** Re-run `gog schema --json` against the real installed binary on first actual deployment and diff against this table before relying on it in production.

## Decision 9: Exit codes and I/O contract for `tool_gateway.py` to branch on

`gog` documents a stable exit-code taxonomy: `0` success, `2` invalid args, `4` auth missing/expired, `5` not found, `6` permission denied, `7` rate limited, `8` transient failure. Primary JSON goes to stdout; prompts/warnings/diagnostics go to stderr — "automation should branch on exit status rather than human error text." `list_mcp_tools()`/`call_mcp_tool()` should map `4` to a clear "please re-authenticate" user-facing message (rather than a raw stack trace), and `7`/`8` to a single bounded retry, matching this project's existing "clear error, never hang or crash on the user" pattern (established for the CLI channel in Spec 026).

## Decision 10: Account/identity model — single shared Google account (assumption, not a blocker)

spec.md's Technical Approach doesn't address multi-user identity mapping, and nothing in the current whitelist model (`TELEGRAM_ALLOWED_USER_IDS`) maps a Telegram user to a distinct Google account. Consistent with this project's established single-operator deployment pattern (see Spec 026's Assumptions), this plan assumes **one shared Google account** (`GOG_ACCOUNT` env var, set once during onboarding) used for all authorized Telegram users — not a per-user OAuth grant system. If multi-account support is ever needed, `gog`'s `--account` flag already supports it; that's a future extension, not something this spec needs to build.
