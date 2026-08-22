---
author: Denson Smith
---

# Autonomous-mode activation template

> **⚠ AUTONOMOUS MODE PAUSED (2026-06-05, PRINCIPAL).** Do NOT use this template to activate a seat into autonomous / unattended mode right now. Run the engagement **co-driven (HITL — user-tier/PRINCIPAL in the loop)** instead, via the standard `paste-instruction-template.md`. Reason: `stoa--x4j` — in autonomous mode the gauntlet can silently block on a sub-agent permission prompt, indistinguishable from a stall over bw. Temporary + reversible: **remove this banner and restore autonomous activation when `stoa--x4j` is fixed.**

Paste-instruction template POLYBIUS instances reference when activating a downstream seat in autonomous mode. The downstream seat reads the filled paste-instruction on entry and uses it to run the autonomous-mode-setup checklist (`operating-disciplines.md` §11) before any substantive work begins.

When to use this template:

- You (POLYBIUS) are dispatching a downstream seat (PLINY, a CAPTAIN, a sub-project POLYBIUS) into an engagement that PRINCIPAL has declared autonomous.
- The downstream seat needs the engagement-specific context (coordination ticket, peer name, polling cadence) baked into its activation so it does not need to re-derive it.
- You substitute the slots, write the filled instruction to disk under `HUMAN_paste-<seat>-instruction.md`, and hand the human (or paste yourself, if you are activating directly) a one-line pointer per the durable-substrate-with-short-prompts pattern (`MAJOR_POLYBIUS.md` §4.5).

This template is for the AUTONOMOUS-mode activation specifically. HITL-mode activation uses the existing `paste-instruction-template.md` without the autonomous-specific scaffold.

---

## Substitution slots

| Slot | Meaning | Example |
|---|---|---|
| `{{ENGAGEMENT_NAME}}` | short descriptor of the work | `arc-21 build` |
| `{{COORDINATION_TICKET}}` | bw ticket id of the shared coordination ticket | `<example>--abc` |
| `{{PEER_SEAT_NAME}}` | name of the upper-tier coordinating peer | `user-tier POLYBIUS` |
| `{{PEER_CRON_ID}}` | peer's cron id, if known (else `unknown`) | `e6a08d54` |
| `{{POLLING_CADENCE}}` | the cron cadence to schedule | `*/5 * * * *` |
| `{{ESCALATION_TRIGGERS}}` | engagement-specific surface-to-PRINCIPAL list | `project-direction, ship/no-ship, substance disagreement after one round, authorship/copyright content, irreducible ambiguity, peer-silence > 60 min` |

---

## Template body

```
You are entering AUTONOMOUS mode for {{ENGAGEMENT_NAME}}. Coordinate
with {{PEER_SEAT_NAME}} async via bw on {{COORDINATION_TICKET}}.
PRINCIPAL is exception-handler.

Run the seven-step autonomous-mode-setup checklist from
operating-disciplines.md §11 before beginning substantive work:

1. Polling cron — schedule via CronCreate at cadence
   {{POLLING_CADENCE}}. The cron prompt body comes from
   substrate/templates/polling-cron-prompt-template.md — fill its slots
   with this engagement's values ({{COORDINATION_TICKET}},
   {{PEER_SEAT_NAME}}, etc.) and pass the substituted body to
   CronCreate. Record the returned cron id; you will reference it in
   the radio-check initialization handshake (step 2).

2. Radio-check pattern with {{PEER_SEAT_NAME}}
   (operating-disciplines.md §7.1) — post initialization handshake on
   {{COORDINATION_TICKET}} naming your cron id and cadence. Peer's
   cron id (if known): {{PEER_CRON_ID}}. Heartbeat every <=30 min.
   Escalate peer-silence > 60 min to PRINCIPAL.
   All coordination comments use the author-tag convention from
   operating-disciplines.md §7.1 beat 5: `[from: <self-seat-slug>]` on
   every coordination post; `[for: <recipient-slug>] [from: <self-slug>]`
   on addressed comments; `[radio-check <self-slug>]` on heartbeats.

3. Cross-tier coordination convention (operating-disciplines.md §7.4)
   — when you need cross-project context, post `[for: <upper-seat>]`
   tagged comments on a relevant ticket in your OWN bw. Upper-tier
   peer polls down. You never write up.

4. Bw write-boundary discipline (operating-disciplines.md §7.5) — write
   only to your own bw and downward; never upward. Coordination meets
   in the lower tier's bw.

5. Activation paste discipline (operating-disciplines.md §8 +
   MAJOR_POLYBIUS.md §5.1.1 + §5.5) — when you author downstream briefs
   or activation pastes for further dispatches, use positive references
   only. Filename varies by install mode — consult
   substrate/templates/activation-paste-cheatsheet.md before authoring
   any activation paste.

6. Bw storage model (operating-disciplines.md §9) — bw lives on the
   `beadwork` orphan branch; detect via `bw prime` self-report or
   `git branch -a | grep beadwork`. Never `git checkout beadwork` from
   the main worktree.

PRINCIPAL-gate standing condition (operating-disciplines.md §25):
autonomous mode does NOT relax PRINCIPAL-gates. If downstream — at
any phase of this engagement — encounters a PRINCIPAL-gated clause
in the directive or in any sub-dispatch (per §25.3: any clause where
PRINCIPAL input is structurally required for the workflow to
proceed correctly), HALT and escalate to PRINCIPAL immediately
rather than proceed-then-flag. Autonomous-mode escalation cadence
(§10) and PRINCIPAL-gate authorization (§25) are orthogonal
disciplines; the cadence relaxation in autonomous mode does not
authorize crossing gates.

Once all seven are in place, post a setup-complete comment on
{{COORDINATION_TICKET}} with: cron id, cadence, escalation triggers,
peer name, expected duration. From this point forward, routine status
flows via bw; PRINCIPAL only sees the universal escalation triggers
({{ESCALATION_TRIGGERS}}) until the engagement closes or PRINCIPAL
declares autonomous->HITL.

Post the initialization handshake on {{COORDINATION_TICKET}} once
setup completes:

  bw comment {{COORDINATION_TICKET}} "[radio-check <self-seat-slug>] cron <id>
  cadence {{POLLING_CADENCE}} — autonomous setup complete; standing by
  for handshake ack from {{PEER_SEAT_NAME}}."
```
