# Surface-and-wait polling pattern + multi-arc autonomous mode — instruction module

> Relocated from `MAJOR_PLINY.md` §6.2 + §6.2a (CONDITIONAL — read when surfacing-and-waiting on
> POLYBIUS, OR in a multi-arc autonomous engagement). Provenance: debloat Arc 48 cut
> `agents/design/arc-48/design-rev1.md` + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.10`.
> The slim-core residue is the §6.2 stub (real heading line — spec-cited; names the anti-pattern in
> one line) + routing-map row (surface-and-wait / multi-arc autonomous) + relocation-index row in
> §4.2.

## 6.2 Surface-and-wait polling pattern (Arc 18)

POLYBIUS polls bw on its own cron during the engagement and surfaces meaningful state transitions to the PRINCIPAL. **You do not poll continuously.** The asymmetric polling discipline is precise:

- **Heads-down work (do NOT poll):** when you're executing the directive's phases, focused on the work, no question outstanding, no blocker — just write status comments at phase transitions and continue. POLYBIUS is polling and will pick up your comments within ~5 min. Don't burn polling tokens defensively.
- **Surface-and-wait (DO poll):** when you've written a question to POLYBIUS via bw and cannot continue without the response. The trigger is precise: *"I sent a comment with a question; I cannot continue without the response; I am now waiting."*

When the surface-and-wait trigger fires, set up your own polling cron:

```
CronCreate {
  cron: "*/5 * * * *",
  recurring: true,
  prompt: |
    [scheduled poll fire — checking POLYBIUS for response on <epic-id>]
    Run: cd <repo> && bw show <epic-id> 2>&1 | tail -30
    Report any new comments from POLYBIUS since last check.
    If nothing new: "no response yet from POLYBIUS."
    If POLYBIUS responded: surface the comment + decide whether to act / wait / surface back to PRINCIPAL.
}
```

Cancel via `CronDelete <job-id>` the **moment** POLYBIUS responds and you resume work. Don't leave a polling cron running while you're heads-down — the asymmetric discipline keeps the channel efficient.

**Anti-pattern:** polling between phases when nothing is blocked. Phase transitions where you have no surface to make and no waiting required: just comment status, continue. Polling overhead during normal work is a token-burn that doesn't earn its cost.

(Cross-ref: `operating-disciplines.md` §19.7 — Idle retrospective-narrative confabulation; the canonical orchestrator-scan procedure §19.7.3 names is the canonical scan this surface-and-wait pattern operates against.)

Anchor: Arcs 16 + 17 shipped with this exact pattern — PLINY worked heads-down through 5 phases each; POLYBIUS picked up phase-transition comments via its own polling cron and surfaced meaningful transitions to the PRINCIPAL; PLINY only polled when surfacing a real question, which for both arcs (locked Phase A decisions) happened zero times.

## 6.2a Multi-arc autonomous mode (per stoa--bn8, Arcs 39-41 proto-canon evidence)

The surface-and-wait default above is the right shape for single-arc dispatches, first-contact engagements, and any context where PRINCIPAL is actively driving. When PRINCIPAL has explicitly delegated a **multi-arc engagement** to user-tier (typically via priming-paste establishing the cross-tier coordination), polling-cron-at-PLINY is permitted as an alternative mode — same hygiene as `MAJOR_POLYBIUS.md` polling per `operating-disciplines.md` §7.2 + §11 step 1.5 renewal.

**When this mode applies (load-bearing — do NOT widen):**

- PRINCIPAL has explicitly delegated multi-arc work to user-tier (priming-paste named the engagement; user-tier POLYBIUS is the coordination authority).
- The engagement spans ≥2 arcs (single-arc work stays under the surface-and-wait default — the polling-cron overhead does not earn its cost on a single arc).
- PLINY's cron monitors a named coordination ticket for `[for: pliny-the-stoa]` dispatch signals (NOT a free-polling cron that scans bw broadly).

**The standby pattern (within a multi-arc engagement, between arcs):**

Between arcs in a multi-arc engagement, PLINY's polling-cron remains active but PLINY is idle awaiting next dispatch. The cron auto-acknowledges routine heartbeats via comment-only posts (no engagement-substance); PLINY engages on substance only when a `[for: pliny-the-stoa]` dispatch signal lands. Same standby-cadence-keeps-channel-warm pattern §11 establishes for POLYBIUS-side polling.

**Reuse existing cron infrastructure.** Do NOT create new crons for a multi-arc engagement if a prior priming established them — reuse jobids from the priming-paste (e.g., PLINY-side polling + renewal pair created at activation). Same `MAJOR_PLINY.md` Arc 36 / Arc 38 / Arc 41 directive `A9 LOCKED` pattern.

Anchor: `stoa--bn8` (2026-05-18 multi-arc autonomous sequence Arcs 39+40+41 — priming established polling-cron-at-PLINY for cross-tier bw-signal dispatch; pattern HELD CLEANLY across all 3 arcs; discipline-shipped arc Arc 42; cross-ref `stoa--bbi` refined-principle thesis evidence for proto-canon-promotion). Recover via `bw show stoa--bn8`.
