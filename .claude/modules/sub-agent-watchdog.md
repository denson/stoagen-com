# Sub-agent watchdog protocol — instruction module

> Relocated from `MAJOR_PLINY.md` §5.3 (CONDITIONAL — read when a dispatched CAPTAIN may be
> stalling). Provenance: debloat Arc 48 cut `agents/design/arc-48/design-rev1.md` + epic
> `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.10`. The slim-core residue is the §5.3 stub +
> routing-map row (CAPTAIN-may-stall) + relocation-index row in §4.2.

PLINY dispatches sub-agents (CAPTAINs) via the `Agent` tool; these can stall mid-dispatch — recon loops on too-large input, output-side context saturation, platform-side streaming hangs. PLINY is responsible for watchdog-killing stalled dispatches. The post-mortem-driven empirical signature gives a precise three-condition predicate.

**Stall predicate (all three conditions hold):**

- **Token budget threshold:** > 50k tokens consumed by the sub-agent.
- **Tool use threshold:** > 20 tool calls executed.
- **Critical predicate:** NO `Write` or `Edit` on the deliverable path the dispatch named.

When all three hold, kill the agent and surface to POLYBIUS for routing. The signature is empirically derived from m5e arc DAEDALUS rev3 stalls — sub-agent reads input at ~31k tokens, re-reads 4 times, never reaches `Write`.

**Wall-clock fallback:** if Claude Code does not expose token / tool-use counts to the parent session, the watchdog reduces to a wall-clock heuristic — surface a stall when a CAPTAIN dispatch exceeds an empirically-tuned wall-clock budget without producing a `Write` / `Edit` on the deliverable path. Tune the budget per-CAPTAIN based on empirical run times for that seat.

**Zero-burn = POSSIBLE-PERMISSION-PAUSE, not confirmed stall.** The three-condition predicate above cannot fire on a PERMISSION-PAUSED sub-agent: a seat blocked at an unanswered permission prompt (e.g. a destructive probe command that tripped the bash-permission heuristic — `operating-disciplines.md` §8.6) burns ~0 further tokens and executes ~0 further tool calls, so it FAILS the `>50k tokens` / `>20 tool calls` thresholds and is never killed — it just hangs silently (the `stoa--x4j` autonomous-mode failure). The two signatures differ: a CONFIRMED stall shows token/tool-use burn CLIMBING with no `Write`/`Edit` landing; a PERMISSION-PAUSE shows burn FLAT-AT-ZERO with no `Write`/`Edit`. Where the parent can read these counts, treat zero-progress-WITH-zero-burn as the cheap first hypothesis POSSIBLE-PERMISSION-PAUSE and check whether a dispatched seat authored a destructive shell command with `$VAR`/`${VAR}` expansion (§8.6) — NOT an auto-kill. Where only the wall-clock fallback is available (no counts), the parent cannot mechanically separate the two; a peer-silence escalation should name BOTH causes ("stalled OR permission-paused") and an out-of-band terminal check resolves which. (Telemetry caveat: per the open question this module flags, token/tool counts may not be exposed to the parent — when they are not, this classification degrades to the wall-clock + name-both-causes path.)

**On kill:** capture the JSONL transcript per `operating-disciplines.md` §14 (Sub-agent diagnostic transcript discipline) BEFORE the process exits. The transcript is the only direct evidence of what the agent was doing at stall time.

**Open question (carried forward, not resolved):** platform-side telemetry exposure — does Claude Code surface sub-agent token / tool-use counts to the parent session? If yes, threshold-based watchdog. If no, wall-clock-only watchdog. This implementation question stays open in the substrate; the protocol shape (predicate + on-kill transcript capture) is the discipline.

Anchor: `stoa--dyb` Item 1 — empirical signature from `agents/design/ariadne--m5e/post-mortem-daedalus-rev3-stall.md` (in ariadne-core-workspace, 2026-05-07; 12.7 KB; 6+ DAEDALUS rev3 stalls with concrete telemetry signatures). Recover via `bw show stoa--dyb`.
