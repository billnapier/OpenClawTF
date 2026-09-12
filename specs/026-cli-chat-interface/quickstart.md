# Quickstart: CLI Chat Interface

## Prerequisites
- An authenticated SSH session on the OpenClaw host (this is the entire authorization boundary — see FR-003/FR-009).
- OpenClaw already deployed with `GEMINI_API_KEY` configured (same requirement as the Telegram channel).

## One-shot usage

```bash
openclaw chat "What's on my calendar today?"
```

Prints the agent's response and exits. The message and response are persisted to the same continuing CLI conversation thread that interactive sessions read/write.

## Interactive usage (REPL)

```bash
openclaw chat
```

Opens a prompt loop:

```
OpenClaw CLI Chat (type /exit or Ctrl-D to quit)
> What's on my calendar today?
<agent response>
> and tomorrow?
<agent response, aware of prior turn>
> /exit
```

Exit with `/exit`, `/quit`, Ctrl-D (EOF), or Ctrl-C (SIGINT) — all terminate cleanly with no orphaned processes (FR-004).

## Built-in help (no external docs required — SC-004)

```bash
openclaw chat --help
```

## Continuity across invocations

```bash
openclaw chat "Remember that my flight is on the 20th."
# ...later, new terminal, next day...
openclaw chat "When is my flight again?"
# Response reflects context from the earlier one-shot invocation.
```

## Verification

```bash
bash scripts/test_cli_chat.sh
```

(New test script, following the existing convention of `scripts/test_channel_adapters.sh` and `scripts/test_vector_memory.sh` — exercises: one-shot round trip, REPL multi-turn context, cross-invocation persistence, malformed/oversized input rejection, and backend-unavailable error surfacing.)

## Notes
- CLI and Telegram conversations are independent threads (FR-008) — a CLI session never automatically includes Telegram history or vice versa.
- There is no separate CLI login/token — anyone who can SSH into the host can run `openclaw chat` immediately (FR-009). This mirrors the single-operator-host assumption in spec.md; a shared multi-user host does not get per-OS-user thread separation in this release.
