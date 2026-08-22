---
name: whoami
description: |
  Report this Stoa seat's session-identity by reading the `$CLAUDE_CODE_SESSION_ID` environment variable. A terminal seat (POLYBIUS / PLINY or any session) discovers its OWN session-id; a sub-agent CAPTAIN (ADA / VERA / CATO / ARGUS / DAEDALUS / …) discovers its CALLER's session-id (the dispatching terminal's sid). FAILS LOUD (clear stderr + non-zero exit) if the variable is empty/unset — never emits a blank or guessed sid, and has no workaround fallback. Feeds the session-identity sign-everywhere convention (operating-disciplines.md §28.9) and the seat registry (`stoa--reg`) desktop self-record path.

  Invoke when a seat needs to discover its own session-id / caller-sid for signing a bw comment, self-recording to the seat registry, or answering "what is my session identity". Windows + Claude Code Desktop (builder tier); also runs anywhere Python 3 + the env var are present.
author: Denson Smith
---

# whoami — discover this seat's session-identity (stoa--p7c, Arc 67)

> **Identity comes from the runtime, not a workaround.** `whoami` reads the `$CLAUDE_CODE_SESSION_ID` environment variable and returns it — no derivation, no filesystem traversal, no guessing. The runtime supplies the value; whoami just reads it and FAILS LOUD if it is absent.

## The tool: `whoami.py` (ships in this skill dir)

```bash
python .claude/skills/whoami/whoami.py                      # bare sid on stdout (exit 0)
python .claude/skills/whoami/whoami.py --role terminal      # -> sid=<value>
python .claude/skills/whoami/whoami.py --role subagent      # -> caller-sid=<value>
python .claude/skills/whoami/whoami.py --role terminal --json   # -> {"kind":"terminal","session_id":"<value>"}
python .claude/skills/whoami/whoami.py --role subagent --json   # -> {"kind":"subagent","caller_sid":"<value>"}
```

A bare shell read is equivalent for the value itself:
```bash
echo $CLAUDE_CODE_SESSION_ID
```

## What the value means

`$CLAUDE_CODE_SESSION_ID` is:
- a **terminal seat's OWN session-id** (POLYBIUS / PLINY, any `--session-id`-launched or desktop-created session), and
- a **sub-agent's CALLER session-id** (the dispatching terminal's sid — a sub-agent inherits its caller's sid; that IS the capability).

The runtime sets the value. **No env var discriminates a terminal seat from a sub-agent** — the seat knows its class STRUCTURALLY (a MAJOR is a terminal seat by construction; a CAPTAIN dispatched via the Agent tool is a sub-agent by construction). The `--role terminal|subagent` flag is supplied by the CALLER from its known class and selects ONLY the output label (`sid=` vs `caller-sid=`); the underlying value is the same env var either way. With no `--role`, whoami prints the bare value and notes (on stderr) that the §28.9 convention selects the label.

## The FAIL-LOUD contract (the MUST)

If `$CLAUDE_CODE_SESSION_ID` is **empty or unset**, `whoami`:
- prints `whoami: $CLAUDE_CODE_SESSION_ID is not set; cannot determine session identity` to **stderr**,
- exits **non-zero (exit 2)**,
- prints **NO sid to stdout** (no blank, no guess),
- attempts **NO fallback** (there is no derivation or filesystem workaround to fall back to, by design).

A missing-identity condition is a LOUD failure, never a silent or confident-wrong sign-tag. This is the only failure path: either the runtime gave us a sid or it did not.

## The §28.9 sub-agent sign-tag this feeds

A sub-agent CAPTAIN signs every bw comment (op-disc §28.9):
```
[from: CAPTAIN_<MNEMONIC>_<slug> (subagent) | caller-sid $CLAUDE_CODE_SESSION_ID]
```
(There is NO per-instance agent-id in v1 — `type + caller-sid` suffices for provenance/audit; two concurrent same-type sub-agents under one caller sign identically, which is accepted for the audit goal. A terminal seat signs `[from: <Name> | sid $CLAUDE_CODE_SESSION_ID | <project>]`.)

## Desktop self-record (the HYBRID DC1 fallback)

Desktop-UI sessions are created outside the team launcher, so it cannot pin their session-id. Those seats SELF-RECORD on activation: run `whoami` to get the sid from `$CLAUDE_CODE_SESSION_ID`, then call `record-seat.ps1` (in the team-launcher skill) with that sid to write their registry row. The env var makes this robust — it always returns the real runtime sid.

## Deployment requirement

`whoami` requires **Claude Code >= v2.1.132**, where `$CLAUDE_CODE_SESSION_ID` went **native** — set by the Claude Code runtime in every Bash subprocess / hook / execution context, zero config, out of the box in every session (changelog: "Added CLAUDE_CODE_SESSION_ID environment variable to the Bash tool subprocess environment, matching the session_id passed to hooks"). The pre-v2.1.132 `SessionStart`-hook injection (writing the var into the shell env via `CLAUDE_ENV_FILE`) is an **obsolete workaround, not the current mechanism** — current deployments get the var natively regardless of hook-arming, so sign-everywhere works on a fresh consumer install. Below the v2.1.132 floor (or in a non-Claude-Code context), the var is absent and `whoami` FAIL-LOUDs (safe).

## WEAK-1 — the one runtime dependency (re-verify if Claude Code changes)

Identity rests entirely on `$CLAUDE_CODE_SESSION_ID`. **If a future Claude Code update changes its *semantics*** — gives a sub-agent its OWN sid instead of the caller's, or otherwise re-defines the value — whoami's value silently changes meaning. The FAIL-LOUD MUST catches the var *disappearing* loudly (whoami exits non-zero rather than emitting a wrong sid), but it cannot catch a *semantic change* (var still set, different meaning). **If a Claude Code update changes its session/env semantics, re-verify NOMOS C1/C2/C3** (terminal own-sid + sub-agent caller-sid). This future-semantics drift is the genuine residual; the present-day mechanism is the native runtime var (above), not a fragile hook.

## Cross-references
- `operating-disciplines.md` §28.9 — the session-identity sign-everywhere convention this feeds.
- `team-launcher` skill (`record-seat.ps1`) — the registry write helper; the desktop self-record path calls it with this sid.
- `stoa--reg` — the seat registry ticket (the durable roster these sids populate).
- `stoa--p7c` — the arc that landed this skill (the env-var identity scheme; the earlier derive-from-transcript approach was retired in favor of the runtime variable).
