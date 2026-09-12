# Feature Specification: CLI Chat Interface for OpenClaw Agent

**Feature Branch**: `026-cli-chat-interface`
**Created**: 2026-09-12
**Status**: Draft
**Input**: User description: "I'd like to be able to "chat" with my openclaw agent from linux command line as well as telegram"

## Clarifications

### Session 2026-09-12

- Q: When you start a new CLI chat invocation (a new terminal, or later that day), should it continue the same ongoing conversation thread, or always start fresh? → A: One continuous thread — every CLI invocation (interactive or one-shot) reads/writes the same persistent conversation history for the host, so context carries forward across separate terminal sessions.
- Q: Should an idle interactive CLI session (REPL) automatically time out and exit after a period of inactivity? → A: No explicit timeout — the session only ends when the user exits explicitly or the SSH connection drops.
- Q: How should the CLI handle malformed or oversized input (binary data, invalid UTF-8, an extremely long single message)? → A: Reject with a clear error before sending it to the agent — consistent with FR-005's "clear error, never hang silently" philosophy.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Interactive Terminal Conversation (Priority: P1)

As the operator of an OpenClaw deployment, I want to open a chat session with my agent directly from a Linux terminal, so that I can interact with it without opening Telegram or any other messaging app.

**Why this priority**: This is the core capability requested — without it, there is no CLI channel at all. It is the minimum slice that delivers value on its own.

**Independent Test**: Can be fully tested by running the CLI chat command on a host where OpenClaw is deployed, sending a message, and confirming a response is printed to the terminal — independent of any other channel working.

**Acceptance Scenarios**:

1. **Given** OpenClaw is deployed and reachable on the host, **When** the user starts the CLI chat command and types a message, **Then** the agent's response is printed back to the terminal.
2. **Given** an open CLI chat session, **When** the user sends a follow-up message that refers back to something said earlier in the same session, **Then** the agent's response reflects awareness of that earlier context.
3. **Given** an open CLI chat session, **When** the user issues an explicit exit command (or sends an interrupt), **Then** the session ends cleanly with no orphaned background processes.

---

### User Story 2 - Access Limited to the Host Itself (Priority: P1)

As the administrator of the OpenClaw deployment, I want the CLI chat command only usable by someone who already has an authenticated SSH session on the host where OpenClaw runs, so that adding a CLI channel doesn't create a new, weaker way in beyond what host-level access control already governs.

**Why this priority**: OpenClaw's existing channels enforce a strict guarantee that only trusted people can reach the agent; shipping a CLI channel that skips this would regress that guarantee, so this ships alongside Story 1, not after it.

**Independent Test**: Can be fully tested by confirming the CLI chat command is only reachable from a shell on the OpenClaw host itself (not from an arbitrary laptop over the network), independent of whether Story 1's happy path works.

**Acceptance Scenarios**:

1. **Given** a user with no SSH access to the host, **When** they have no way to obtain a shell on it, **Then** they have no path to reach the CLI chat command at all.
2. **Given** a user with an active, authenticated SSH session on the host, **When** they run the CLI chat command, **Then** access is granted immediately with no separate CLI-specific credential required.

---

### Edge Cases

- What happens when the agent backend is temporarily unavailable during an active CLI session — does the user get a clear error, or does the terminal hang silently?
- What happens if the same user has a CLI session and a Telegram session open at the same time — can responses ever be misdirected or duplicated across the two?
- Malformed or oversized input (binary data, invalid UTF-8, an extremely long single message) is rejected with a clear error before being sent to the agent (see FR-010).
- What happens when a user runs the CLI chat command with no network/backend connectivity at all?
- On a shared, multi-user host, the CLI does not distinguish between different OS users' SSH sessions (per FR-009) — anyone who can SSH in shares the same authorized access and the same continuing conversation thread (per FR-002); this is why the SSH-boundary model assumes a single-operator host (see Assumptions).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a command-line interface that lets an authorized user send text messages to the OpenClaw agent and see its responses in the same terminal.
- **FR-002**: System MUST retain conversation context across multiple messages within a single CLI session, and MUST persist that context across separate CLI invocations (a new terminal, a later one-shot command) so the agent can refer back to earlier turns from a prior invocation, not just the current one.
- **FR-003**: System MUST restrict the CLI chat command to users who already have an authenticated SSH session on the host where OpenClaw runs; it MUST NOT be reachable or usable as a remote/network client from an arbitrary machine (e.g. a user's laptop) without first establishing that SSH session.
- **FR-004**: System MUST let the user end an interactive CLI chat session explicitly (exit command or interrupt) without leaving orphaned processes or corrupted session state; the system MUST NOT impose an automatic idle timeout — a session remains open until the user exits it or the underlying SSH connection drops.
- **FR-005**: System MUST surface a clear, human-readable error when the agent backend is unreachable or fails to respond, rather than hanging indefinitely.
- **FR-006**: System MUST record CLI chat interactions with the same level of audit/observability detail already applied to other channels.
- **FR-007**: System MUST support both a persistent interactive session (a REPL the user stays inside for multi-turn conversation) and a one-shot single-message invocation (a single command that sends one message, prints the response, and exits) as two ways to reach the same, single, continuing CLI conversation thread (per FR-002) — a one-shot message today is visible as prior context in an interactive session started tomorrow, and vice versa.
- **FR-008**: System MUST treat CLI sessions and Telegram sessions for the same person as independent conversation threads by default — a CLI session does not automatically inherit or share context from that person's Telegram conversation, or vice versa.
- **FR-009**: System MUST treat "having an authenticated SSH session on the OpenClaw host" as the sole authorization boundary for CLI access — no separate CLI-specific credential, token, or per-person allow-list is introduced; anyone who can SSH into the host is authorized to use the CLI chat command.
- **FR-010**: System MUST validate CLI input before forwarding it to the agent, rejecting invalid input (malformed/non-UTF-8 text, binary data, or a message exceeding a defined size limit) with a clear error message rather than forwarding it or hanging.

### Key Entities

- **Chat Session**: An ongoing conversation between one user and the agent on a given channel; holds the sequence of turns exchanged and how long it has been open. For the CLI channel, this is a single persistent thread per host that survives across separate CLI invocations, not scoped to one process's lifetime.
- **Message**: A single unit of exchange within a session — its text content, sender, timestamp, and originating channel.
- **Channel**: A specific surface through which a user reaches the agent (CLI, Telegram, etc.); each channel enforces the same authorization guarantee before a session may begin.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An authorized user can start a CLI chat session and receive the agent's response to a simple message within 5 seconds under normal operating conditions.
- **SC-002**: In a multi-turn CLI conversation, the agent's responses correctly reflect context from earlier turns in that same session at least 95% of the time.
- **SC-003**: 100% of CLI chat attempts originating outside an authenticated SSH session on the host fail to reach the agent (there is no network-reachable entry point for CLI chat from off-host).
- **SC-004**: A user who has never used the CLI chat feature before can start their first conversation using only a single built-in help command — no external documentation required.

## Assumptions

- **Independent conversation threads**: CLI and Telegram are treated as separate conversation contexts for the same person in this release. Sharing context automatically across channels is a larger design problem (session identity mapping, concurrency) and is deferred to a future feature rather than blocking this one.
- **SSH as the trust boundary**: The CLI is a tool you run after already having a shell on the OpenClaw host — not a client you run from an arbitrary laptop talking to the agent over the network. This mirrors how the intended use is a single-operator deployment; a shared multi-user host with per-user distinction is out of scope (see Edge Cases) and can be revisited if that situation arises.
