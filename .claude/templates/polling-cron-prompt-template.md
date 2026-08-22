---
author: Denson Smith
---

# Polling-cron-prompt template

> **⚠ AUTONOMOUS MODE PAUSED (2026-06-05, PRINCIPAL).** This is the cron body for AUTONOMOUS-mode peer-polling, which is paused right now — do NOT schedule autonomous polling crons. Run engagements **co-driven (HITL)** instead. Reason + restore condition: `stoa--x4j` (autonomous gauntlet can silently block on a permission prompt). Reversible — remove this banner when `stoa--x4j` is fixed.

The cron-prompt body POLYBIUS uses when scheduling a polling cron for a coordination engagement with a peer POLYBIUS seat — peer-to-peer async via bw, the pattern `operating-disciplines.md` §7 codifies.

When to use this template:

- You (POLYBIUS) are entering an autonomous-mode coordination with a peer (typically user-tier ↔ project-tier, or parent ↔ sub-project) and have just run the autonomous-mode-setup checklist (`operating-disciplines.md` §11).
- Step 1 of that checklist (polling cron) requires a fire-loop body. This template is that body.
- You fill the slots, hand the result to `CronCreate` as the `prompt` field, and record the returned cron id on the engagement's coordination ticket as part of the radio-check initialization handshake.

This template assumes peer-polling. Single-seat polling (POLYBIUS polling for new tickets without a coordinating peer) uses a different cron prompt — out of scope here.

---

## Substitution slots

| Slot | Meaning | Example |
|---|---|---|
| `{{COORDINATION_TICKET}}` | bw ticket id of the shared coordination ticket | `<example>--pbz` |
| `{{WATCHED_STORES}}` | list of bw store directories walked per fire (one entry for single-store; multiple for unified poll) | `["/path/to/project-a", "/path/to/project-b"]` |
| `{{WATCHED_TICKETS}}` | per-store list of ticket ids to inspect each fire | `[["<example>--pbz", "<example>--abc"], ["<other>--xyz"]]` |
| `{{PEER_SEAT_NAME}}` | descriptive name of the peer | `user-tier POLYBIUS` |
| `{{SELF_SEAT_NAME}}` | own seat descriptive name | `project-tier POLYBIUS_<project>` |
| `{{SELF_SEAT_SLUG}}` | normalized lowercase-hyphenated slug for own seat (LEADING tag uses this; display-form name uses `{{SELF_SEAT_NAME}}`) | `polybius-the-stoa` |
| `{{PEER_SEAT_SLUG}}` | normalized lowercase-hyphenated slug for peer seat | `user-tier-polybius` |
| `{{CRON_ID}}` | the cron id this prompt is wired to (filled in after `CronCreate` returns) | `e6a08d54` |
| `{{RENEWAL_CRON_ID}}` | id of the paired one-shot renewal cron scheduled per `operating-disciplines.md` §11 step 1.5. **Best-effort semantics:** the slot value is used at cadence-switch STEP 4.1 for `CronDelete {{RENEWAL_CRON_ID}}` as a hygiene optimization — the explicit delete keeps the cron table tidy when the slot value is fresh, and no-ops gracefully when the slot value is stale. Staleness is bounded by the renewal cron's +144h one-shot auto-delete per Claude Code docs (https://code.claude.com/docs/en/scheduled-tasks "Set a one-time reminder": single-fire tasks auto-delete after running), which guarantees orphan cleanup even when STEP 4.1's CronDelete no-ops. Populated AFTER initial setup per the §11 step 1.5 slot-lifecycle 4-step dance (the slot may carry a one-time-stale value between setup and the first cadence-switch — see §11 step 1.5 terminating-shape acceptance prose). | `<renewal-id>` (e.g., `a1b2c3d4`) |
| `{{RENEWAL_CRON_PROMPT_BODY}}` | full renewal-cron prompt body as inline literal text — the complete, slot-substituted body the paired renewal cron carries (per `operating-disciplines.md` §11 step 1.5 renewal-cron template, with all engagement-specific slot values pre-substituted at setup time). Sourced at autonomous-mode-setup time per §11 step 1.5 slot-lifecycle dance (renewal-cron prompt body is generated FIRST as a literal string with placeholders for `{{POLLING_CRON_ID}}` and `{{CADENCE}}`, captured as this slot's literal value, then folded into the polling cron's body at the dance's CronCreate steps). Consumed at cadence-switch by STEP 4.2 (cadence-switch renewal CronCreate) — the polling cron uses this literal body to deterministically CronCreate the fresh renewal cron at the new cadence, re-substituting the internal `{{POLLING_CRON_ID}}` placeholder to the NEW polling-cron-id captured from STEP 4.1's CronCreate return and the internal `{{CADENCE}}` placeholder to the new cadence. The internal `{{RENEWAL_CRON_ID}}` slot inside the literal has no fire-time consumer (STEP 1a no longer self-CronDeletes); ADA-discretion on representation (placeholder, default value, or omitted). | `<multi-line literal — the full ~80-line renewal-cron prompt body the paired renewal cron was CronCreate'd with at setup time; see §11 step 1.5 worked example for the literal text>` |
| `{{RENEWAL_BUFFER_HOURS}}` | hours-before-expiry threshold for the renewal cron fire-time per `operating-disciplines.md` §11 step 1.5; default `24` (1-day buffer) absorbs renewal-fire jitter, session-offline windows, and clock skew against the 168h recurring-task expiry; configurable per directive A8 if a future engagement needs a different buffer. Referenced inline in §11 step 1.5 prose; not consumed at fire-time in this template (the +144h arithmetic is computed at setup time and at each renewal-fire's STEP 4 from `168 - RENEWAL_BUFFER_HOURS`). | `24` |
| `{{ALARM_THRESHOLD_MINUTES}}` | peer-silence escalation threshold | `60` |
| `{{HEARTBEAT_INTERVAL_MINUTES}}` | self-heartbeat refresh interval | `30` |
| `{{CADENCE}}` | the cron cadence this fire-loop runs at | `*/5 * * * *` |
| `{{ESCALATION_TRIGGERS}}` | engagement-specific escalation list | `project-direction, ship/no-ship, substance disagreement, authorship, ambiguity, peer-silence` |

Defaults: `{{ALARM_THRESHOLD_MINUTES}}` = `60`, `{{HEARTBEAT_INTERVAL_MINUTES}}` = `30`, `{{CADENCE}}` = `*/5 * * * *`, `{{RENEWAL_BUFFER_HOURS}}` = `24`.

Display-form slots (`{{SELF_SEAT_NAME}}` / `{{PEER_SEAT_NAME}}`) are used in human-readable prose within comment bodies; SLUG slots are used in the LEADING author tag per `operating-disciplines.md` §7.1 beat 5. Both must be supplied at template substitution time. The `{{RENEWAL_CRON_ID}}` slot is used by STEP 4.1 (cadence-switch) as a best-effort cleanup hint — it identifies the paired renewal cron for explicit CronDelete on rotation, tolerating staleness because one-shot auto-delete handles orphan cleanup as a fallback (terminating-shape). The `{{RENEWAL_CRON_PROMPT_BODY}}` slot carries the paired renewal cron's complete prompt-body text as an inline literal — STEP 4.2 uses it to CronCreate the FRESH renewal cron at cadence-switch time without referencing any template file (preserving the inline-slot-values shape) and without recovering the body from CronList (preserving the deterministic non-text-search shape). See `operating-disciplines.md` §11 step 1.5 slot-lifecycle note for the post-setup substitution sequence covering both new slots.

---

## Template body

```
[scheduled poll fire — ticket {{COORDINATION_TICKET}}; {{SELF_SEAT_NAME}}
watching peer {{PEER_SEAT_NAME}}; cron {{CRON_ID}}; cadence {{CADENCE}}]

STEP 1 — substantive read.
For each store in {{WATCHED_STORES}}:
  cd <store>
  bw sync 2>&1 | tail -5
  for ticket in <store's entry from {{WATCHED_TICKETS}}>:
    bw show <ticket> 2>&1 | tail -40
Aggregate new substantive comments since last fire (peer comments, status
changes, new sub-tickets, complexity tags, cadence tags). Record the
aggregated state for STEPs 1.5-6.

STEP 1.5 — author-attribute aggregated comments.
For each new comment in the aggregated state from STEP 1, extract the
leading author tag per operating-disciplines.md §7.7 (four-case procedure):
  - [radio-check <slug>]: POLYBIUS heartbeat by <slug>
  - [for: <slug-Y>] [from: <slug-X>]: POLYBIUS comment by <slug-X> to <slug-Y>
  - [from: <slug-X>]: POLYBIUS comment by <slug-X>
  - other / no tag: non-POLYBIUS or legacy — does NOT enter timeline-arithmetic

Build two timestamp lists, slug-matching against the substitution slots
(whitespace-tolerant, case-insensitive on the right-hand side — e.g., a
tag accidentally posted as `[from: User-Tier-POLYBIUS]` still matches
`user-tier-polybius`):
  - last_self_activity: most recent comment where author-slug == {{SELF_SEAT_SLUG}}
  - last_peer_activity: most recent comment where author-slug == {{PEER_SEAT_SLUG}}

These two derived timestamps drive STEP 2 (peer-silence escalation) and
STEP 3 (self-heartbeat refresh). Without explicit POLYBIUS attribution,
neither computation is reliable — the 2026-05-04 stoa--e39 empirical.

STEP 2 — peer-silence escalation.
Compute time-since-last-peer-activity from `last_peer_activity` per STEP 1.5.
If > {{ALARM_THRESHOLD_MINUTES}} minutes AND {{COORDINATION_TICKET}} is open:
  Surface to PRINCIPAL: "lost contact with {{PEER_SEAT_NAME}}; last seen
  <timestamp> on <ticket-id>; coordination ticket {{COORDINATION_TICKET}}
  still open."
Else: continue.

STEP 3 — self-radio-check refresh.
Compute time-since-last-self-activity from `last_self_activity` per STEP 1.5.
If > {{HEARTBEAT_INTERVAL_MINUTES}} minutes:
  bw comment {{COORDINATION_TICKET}} "[radio-check {{SELF_SEAT_SLUG}}]
  cron {{CRON_ID}} cadence {{CADENCE}} — <one-line state>"
Else: continue.

STEP 4 — cadence-tag detection (with renewal-cron lock-step rotation
per F4 + terminating-shape collapse).
Scan aggregated state for [complexity: ...] or [cadence: ...] tags posted
since last fire.
If a tag warrants a cadence change (active / default / quiet per
operating-disciplines.md §7.2):

  STEP 4.1 — rotate polling cron at new cadence + best-effort cleanup
  of paired renewal cron.
  CronDelete {{CRON_ID}}
  CronDelete {{RENEWAL_CRON_ID}} (best-effort hygiene; no-ops gracefully
    against stale id per terminating-shape — see substitution-slot table
    above and operating-disciplines.md §11 step 1.5 terminating-shape
    acceptance prose. The orphan renewal cron self-cleans via one-shot
    auto-delete at +144h if this CronDelete no-ops.)
  CronCreate at the new cadence with this same prompt body (slot
  {{CRON_ID}} updated to the new id, {{CADENCE}} updated to the new
  schedule, {{RENEWAL_CRON_ID}} will be re-substituted at STEP 4.2
  return — see below). Let returned id be <new_polling_cron_id>.

  STEP 4.2 — rotate paired renewal cron at new POLLING_CRON_ID + CADENCE.
  CronCreate a fresh renewal cron deterministically from the inline
  literal slot value {{RENEWAL_CRON_PROMPT_BODY}}:
    prompt = {{RENEWAL_CRON_PROMPT_BODY}} with internal placeholders
             re-substituted:
               {{POLLING_CRON_ID}} → <new_polling_cron_id>
               {{CADENCE}} → <new cadence>
               {{RENEWAL_CRON_ID}} → ADA-discretion (terminating-shape:
                 no fire-time consumer; pass through unchanged, set to
                 placeholder, or omit)
    cron = wall-clock for NOW + 144 hours in LOCAL timezone (emit a
           5-field expression for that minute, no UTC conversion — per
           Claude Code docs all times interpreted local; jitter absorbed
           by the 24h buffer)
    recurring = false
    durable = true
  All other engagement-specific slot values inside
  {{RENEWAL_CRON_PROMPT_BODY}} (e.g., {{COORDINATION_TICKET}},
  {{WATCHED_STORES}}, {{SELF_SEAT_SLUG}}, {{PEER_SEAT_SLUG}}, etc.)
  carry through unchanged — they were pre-substituted as literals at
  setup time per operating-disciplines.md §11 step 1.5 slot-lifecycle
  and remain valid across the cadence-switch (only the cron-id pair
  and the cadence rotate). Let returned id be <new_renewal_cron_id>.

  STEP 4.5 — log cadence-change with lock-step pair.
  bw comment {{COORDINATION_TICKET}} "[cadence-change {{SELF_SEAT_SLUG}}]
  switching to <new cadence>; new polling cron <new_polling_cron_id>
  superseding {{CRON_ID}}; new renewal cron <new_renewal_cron_id>
  superseding {{RENEWAL_CRON_ID}} (one-shot at +144h LOCAL, durable:
  true); F4 lock-step rotation per operating-disciplines.md §11 step
  1.5, terminating-shape (2-step dance; one-shot auto-delete as
  orphan-cleanup fallback)."

Else: continue.

Sub-step ordering note (terminating-shape — operational detail for the
in-fire two-CronCreate dance). STEP 4.1 must precede STEP 4.2 because
STEP 4.2's CronCreate of the fresh renewal cron requires
<new_polling_cron_id> substituted into the renewal body's
<PLACEHOLDER:POLLING_CRON_ID> marker (so the new renewal cron's STEP 1
self-discovery at +144h finds the live polling cron). The new polling
cron in STEP 4.1 is CronCreate'd carrying its {{RENEWAL_CRON_ID}} slot
substituted with the value AT SUBSTITUTION TIME — which is the current
{{RENEWAL_CRON_ID}} (the about-to-be-CronDeleted-by-STEP-4.1 old renewal
cron). After STEP 4.1 completes the new polling cron is alive with the
DEAD old renewal id in its slot. After STEP 4.2 completes the new
renewal cron is alive and points at the LIVE new polling cron, but
the new polling cron's {{RENEWAL_CRON_ID}} slot still points at the
dead old renewal id — NOT re-bound (terminating-shape; no STEP 4.3
exists). The new polling cron's slot is stale-by-one-cycle; the live
new renewal cron is orphaned-relative-to-the-polling-cron's-slot but
self-cleans via one-shot auto-delete at +144h. At the next
cadence-switch, STEP 4.1's `CronDelete {{RENEWAL_CRON_ID}}` against
the dead id no-ops gracefully. The slot converges to a LIVE id only
at the next +144h renewal-fire's STEP 4a hygiene re-bind (per
operating-disciplines.md §11 step 1.5 STEP 4a), not at the next
cadence-switch. This is the terminating-shape trade-off named
explicitly: one stale-id residual per cadence-switch cycle at the
polling cron's {{RENEWAL_CRON_ID}} slot, in exchange for cadence-switch-
dance termination (no STEP 4.3 + STEP 4.4 re-bind regress); same
acceptance as the setup-dance terminating shape per §11 step 1.5;
consistent design across both the setup and cadence-switch surfaces.

STEP 5 — closure detection.
Read {{COORDINATION_TICKET}} status from aggregated state.
If status == closed:
  bw comment {{COORDINATION_TICKET}} "[radio-check {{SELF_SEAT_SLUG}}
  standing down] cron {{CRON_ID}} terminating; engagement complete."
  CronDelete {{CRON_ID}}
  exit fire-loop (cron will not fire again)
Else: continue.

STEP 6 — escalation triggers.
If aggregated state contains a substantive event matching any of:
  {{ESCALATION_TRIGGERS}}
Surface that event to PRINCIPAL with:
  - the triggering event (one line)
  - the ticket(s) where it surfaced
  - what {{SELF_SEAT_NAME}} proposes / is blocked on / needs decided
Else: silent. The cron tool fires only when the REPL is idle, so silent
fires do not interrupt active work; they pick up between turns.

STEP 6.5 — PRINCIPAL-gate detection (operating-disciplines.md §25).
Scan aggregated state for evidence of a PRINCIPAL-gated clause that
hasn't been adjudicated. Patterns to match (per §25.3):
  - "PRINCIPAL-discretion per design §X"
  - "PRINCIPAL ratifies before <phase>"
  - "blocked-on-PRINCIPAL"
  - any clause where PRINCIPAL input is structurally required for
    the workflow to proceed correctly and PRINCIPAL has not yet
    provided that input
If matched AND not yet adjudicated by PRINCIPAL:
  PushNotification: "PRINCIPAL-gate encountered on <ticket>; clause:
  <verbatim>; workflow paused per §25 pending PRINCIPAL
  authorization."
  Do NOT advance workflow state. Do NOT mark dependent tickets as
  unblocked. Do NOT dispatch downstream seats whose work would cross
  the gate. The cron continues to fire (will re-detect on next pass)
  until PRINCIPAL adjudicates the gate.
Else: continue.
PushNotification scope reference: operating-disciplines.md §18.5
(PushNotification only for PRINCIPAL-actionable events; a gate-
detection is exactly that by definition of §25.3).

End of fire-loop.
```

---

## Usage example

Suppose the autonomous-mode setup fills the slots:

- `{{COORDINATION_TICKET}}` = `<example>--abc`
- `{{WATCHED_STORES}}` = `["/home/user/project-foo", "/home/user/project-bar"]`
- `{{WATCHED_TICKETS}}` = `[["<example>--abc", "<example>--def"], ["<other>--xyz"]]`
- `{{PEER_SEAT_NAME}}` = `user-tier POLYBIUS`
- `{{SELF_SEAT_NAME}}` = `project-tier POLYBIUS_foo`
- `{{SELF_SEAT_SLUG}}` = `polybius-the-stoa`
- `{{PEER_SEAT_SLUG}}` = `user-tier-polybius`
- `{{CRON_ID}}` = `<filled after CronCreate>`
- `{{RENEWAL_CRON_ID}}` = `a1b2c3d4` (example renewal cron id — best-effort cleanup hint, may be one-cycle-stale per terminating-shape; orphan cleanup via one-shot auto-delete; populated post-setup per `operating-disciplines.md` §11 step 1.5 slot-lifecycle 4-step dance)
- `{{RENEWAL_CRON_PROMPT_BODY}}` = `<full ~80-line renewal-cron prompt body literal, with placeholder markers for POLLING_CRON_ID and CADENCE — see operating-disciplines.md §11 step 1.5 worked example for the literal text; this slot's value is captured at autonomous-mode-setup time per the slot-lifecycle 4-step dance and inlined into the polling cron at dance step 1>`
- `{{ALARM_THRESHOLD_MINUTES}}` = `60`
- `{{HEARTBEAT_INTERVAL_MINUTES}}` = `30`
- `{{CADENCE}}` = `*/5 * * * *`
- `{{ESCALATION_TRIGGERS}}` = `project-direction, ship/no-ship, substance disagreement after one round, authorship/copyright content, irreducible ambiguity, peer-silence > 60 min`

POLYBIUS substitutes the slots into the body and calls:

```
CronCreate {
  cron: "*/5 * * * *",
  recurring: true,
  prompt: <substituted body>,
}
```

The returned cron id is recorded in the radio-check initialization handshake on `<example>--abc` (display-form name "project-tier POLYBIUS_foo" can still appear in the comment body's prose for readability; the LEADING tag uses the slug per `operating-disciplines.md` §7.1 beat 5. Both cron ids appear in the handshake per §11 step 1.5 record-both-cron-ids requirement):

```
bw comment <example>--abc "[radio-check polybius-the-stoa]
polling cron <returned-id> cadence */5 * * * * watching {<example>--abc, <example>--def}
+ {<other>--xyz}; renewal cron a1b2c3d4 (one-shot at +144h LOCAL, durable: true,
per operating-disciplines.md §11 step 1.5); expected duration ~3 hours;
standing by for handshake ack."
```

The empirical lineage for this protocol stack lives in the §7.6 PROVENANCE Anchor `ariadne--m20` / `stoa--e39` (the §7 body, including §7.6, relocated to `.claude/modules/two-polybius-coordination.md` in the Arc 47 op-disc cut; `bw show ariadne--m20` / `bw show stoa--e39` for the lived-experience anchor).

---

## Cron expiry handling

Cron expiry is handled OUT OF THIS TEMPLATE. CronCreate's recurring-task expiry is empirically confirmed at 168 hours (7 days) per Claude Code docs (https://code.claude.com/docs/en/scheduled-tasks §Seven-day expiry). Renewal is via a separate one-shot renewal cron scheduled at autonomous-mode-setup time per `operating-disciplines.md` §11 step 1.5 — no in-fire renewal logic exists in this template. See §11 step 1.5 for the renewal-cron prompt body and the failure-mode acceptance (peer-side radio-check recovery; no additional watchdog ships).

The CronList primitive (per the 2026-05-17 Arc 36 spike on stoa--jru) exposes neither backward-looking fields (`start_time`/`created_at`/`age`) nor forward-looking fields (`expires_at`/`next_fire`/`valid_until`), and no CronUpdate primitive exists — so in-fire arithmetic against expiry is not implementable. The §11 step 1.5 setup-time scheduled renewal is the structural workaround.
