# Autonomous-mode-setup checklist — instruction module

> **⚠ AUTONOMOUS MODE PAUSED (2026-06-05, PRINCIPAL).** Do NOT run this autonomous-mode setup checklist (polling crons, renewal crons, unattended operation) right now. Operate **co-driven (HITL)** instead. Reason: `stoa--x4j` (autonomous gauntlet can silently block on a sub-agent permission prompt, indistinguishable from a stall). Reversible — remove this banner and restore when `stoa--x4j` lands. (Attended coordination polling between peer seats with a human in the loop is a separate mechanism and is unaffected.)

> Relocated from `operating-disciplines.md` §11 (CONDITIONAL — read when a seat detects an
> autonomous-mode trigger that applies to itself and must run the entry setup). Provenance:
> composition-layer spec `bw show stoa--xyb.4`; debloat Arc 47 cut `agents/design/arc-47/design-rev2.md`
> + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.8`. The slim-core residue is the §11
> stub + relocation-index row in `operating-disciplines.md` §0.5.

When a seat detects an autonomous-mode trigger that applies to itself (bare trigger, or self-qualified trigger), it runs this seven-step setup procedure on entry. Do not begin polling until all seven are in place; if any item cannot be completed, surface to PRINCIPAL with what is needed before proceeding.

**1. Polling cron.** `CronCreate` the cron appropriate to the seat's role:

- Project-tier POLYBIUS: poll own bw for active tickets, peer comments, MAJOR_PLINY status. Default cadence `*/5 * * * *` (per §7.2 default regime).
- User-tier POLYBIUS: unified poll across all watched bw stores per §7.3.
- MAJOR_PLINY: poll own bw + the dispatched ticket(s) during gauntlet rounds (per `MAJOR_PLINY.md` §6.2 surface-and-wait pattern).

The cron prompt body comes from `substrate/templates/polling-cron-prompt-template.md`; fill the slots per the engagement.

**1.5 Schedule renewal.** Polling crons created via `CronCreate` have a documented expiry of 168 hours (7 days) for recurring tasks per Claude Code docs (https://code.claude.com/docs/en/scheduled-tasks §Seven-day expiry: "Recurring tasks automatically expire 7 days after creation. The task fires one final time, then deletes itself."). To prevent silent loss of the polling cron on multi-day engagements, schedule a one-shot renewal cron at +144 hours (= 168 - 24h buffer) from polling-cron creation. The 24h buffer (= `{{RENEWAL_BUFFER_HOURS}}`) absorbs renewal-fire jitter, session-offline windows, and clock skew. (One-shot tasks are not subject to the 7-day cap — the cap applies only to recurring tasks per the docs; one-shot tasks expire when their scheduled time passes.)

**Renewal-cron prompt body — engagement-specific, slot values inline.** The renewal-cron prompt body is generated at autonomous-mode-setup time with ALL slot values pre-substituted (no template-reference at fire time). The substituted body carries: every slot the polling cron carries (so a replacement polling cron can be re-created from it deterministically); the polling cron's id (`{{POLLING_CRON_ID}}` — for deterministic self-discovery at fire time); and the renewal-cron's own next-renewal scheduling parameters.

Renewal-cron prompt body template (substitute at setup time, not at fire time):

````
[scheduled renewal fire — {{SELF_SEAT_SLUG}} polling-cron rotation on
{{COORDINATION_TICKET}}; current polling cron {{POLLING_CRON_ID}};
renewal cron self]

STEP 1 — find current polling cron (deterministic).
CronList; find the entry whose cron-id == {{POLLING_CRON_ID}}.
(Exact-match on cron-id, not text-search on prompt-body — the CronList
prompt-body display is truncated to ~80 chars and is not load-bearing
for matching.) If the cron is not found in CronList: see STEP 1a.

STEP 1a — polling-cron-missing branch (session-lifecycle no-op; rev5
terminating-shape: explicit self-CronDelete REMOVED).
If {{POLLING_CRON_ID}} is absent from CronList, this renewal cron has
outlived its paired polling cron — almost certainly because the polling
cron died on a session-lifecycle event (fresh conversation, /clear,
session exit). (With F4 shipped, cadence-switch rotations of the
polling cron also rotate THIS renewal cron in lock-step at the polling-
cron-template STEP 4 site, so a cadence-switch can no longer be the
cause of {{POLLING_CRON_ID}}-not-in-CronList.) The correct response is
no-op AND exit: post a single bw comment on {{COORDINATION_TICKET}}
noting the orphan-renewal observation, then exit. No explicit
self-CronDelete is needed — this renewal cron was CronCreate'd with
recurring: false (one-shot), and per Claude Code docs
(https://code.claude.com/docs/en/scheduled-tasks "Set a one-time
reminder" section: "Claude schedules a single-fire task that deletes
itself after running") the cron is removed by the runtime after this
fire completes. The polling cron will be re-created when
{{SELF_SEAT_NAME}} next re-enters autonomous mode at the operator's
next session activation (per MAJOR_POLYBIUS.md §9 step 7 long-running-
engagement polling re-setup, which requests PRINCIPAL consent; OR per
MAJOR_POLYBIUS.md §13.4 step 2 if PRINCIPAL re-issues the autonomous-
mode trigger); that re-entry will create a fresh renewal cron paired
with the fresh polling cron via this same §11 step 1.5. Comment to post:
  bw comment {{COORDINATION_TICKET}} "[from: {{SELF_SEAT_SLUG}}] renewal
  cron fired without a paired polling cron (id {{POLLING_CRON_ID}} not
  in CronList — session-lifecycle event likely; cadence-switch path
  ruled out by F4 lock-step rotation). Exiting; one-shot auto-delete
  removes this cron from the session per Claude Code docs. Awaiting next
  autonomous-mode entry per MAJOR_POLYBIUS.md §9 step 7 (PRINCIPAL
  consent required) or §13.4 (PRINCIPAL re-trigger)."
Exit.

STEP 2 — CronCreate replacement polling cron.
CronCreate a NEW recurring cron with cadence {{CADENCE}} and the
polling-cron prompt body with slot values inline (the same engagement-
specific body the original polling cron carried — slot values are pre-
substituted into this renewal-cron prompt at setup time and carried
inline through fire). The polling cron's {{RENEWAL_CRON_ID}} slot is
substituted with the OLD/current paired renewal cron's id (i.e., the
renewal cron currently executing this STEP — which will self-clean
via one-shot auto-delete after this fire per Claude Code docs); the
slot will be re-bound to the live <new_renewal_cron_id> in STEP 4a
(rev5 hygiene optimization). Let the returned id be <new_polling_cron_id>.

STEP 3 — CronDelete {{POLLING_CRON_ID}} (the now-superseded polling cron).
Post on {{COORDINATION_TICKET}}:
  bw comment {{COORDINATION_TICKET}} "[from: {{SELF_SEAT_SLUG}}] cron
  renewed: superseded {{POLLING_CRON_ID}} with <new_polling_cron_id>;
  cadence {{CADENCE}} unchanged."

STEP 4 — CronCreate next renewal one-shot (LOCAL-TIME arithmetic).
Compute the next-renewal fire time in LOCAL time:
  next_renewal_local = NOW (interpreted in local tz) + 144 hours.
Per Claude Code docs https://code.claude.com/docs/en/scheduled-tasks:
"All times are interpreted in your local timezone." A cron expression
emitted from UTC arithmetic would fire at the wrong wall-clock moment
by the UTC-local offset (potentially up to ~12h off the intended +144h
window, eroding the 24h buffer). Always compute and emit in local time.
CronCreate a one-shot cron with cron-expression for next_renewal_local,
recurring: false, durable: true. The prompt body for this new renewal
is THIS SAME renewal-cron prompt body with ONE substitution:
  - replace {{POLLING_CRON_ID}} with <new_polling_cron_id>
The {{RENEWAL_CRON_ID}} slot inside the renewal cron's own body is no
longer consumed at fire time (STEP 1a removed the self-CronDelete that
was its only reader); it may be left as a placeholder marker, as its
old value, or removed entirely — its value is now informational only
and ADA-discretion. All other slot values carry through unchanged.
Let the returned id be <new_renewal_cron_id>.

STEP 4a — re-bind the new polling cron's {{RENEWAL_CRON_ID}} slot
(F4 lock-step composition; best-effort framing).
The new polling cron created in STEP 2 was substituted with a "best-
effort cleanup id" placeholder for {{RENEWAL_CRON_ID}} (the slot's
semantics — see polling-cron-prompt-template.md substitution-slot
table). To keep the polling cron's cadence-switch STEP 4.1 best-effort
`CronDelete {{RENEWAL_CRON_ID}}` pointing at the live renewal cron
(so the explicit delete actually succeeds rather than relying on
one-shot auto-delete as the fallback), CronDelete <new_polling_cron_id>
and CronCreate it AGAIN with {{RENEWAL_CRON_ID}} = <new_renewal_cron_id>.
Let the returned id be <final_polling_cron_id>. The re-bind is a
hygiene optimization — the cron pair survives without it (STEP 4.1's
CronDelete no-ops on the stale id; the orphan renewal cron self-cleans
via one-shot auto-delete at +144h) — but the re-bind keeps the
cadence-switch path tidy and avoids accumulating short-lived orphan
renewal crons inside an engagement that cadence-switches frequently.
SHIP STEP 4a.

STEP 5 — log renewal-chain extension.
Post on {{COORDINATION_TICKET}}:
  bw comment {{COORDINATION_TICKET}} "[from: {{SELF_SEAT_SLUG}}] renewal
  chain extended: new polling cron <final_polling_cron_id>; next renewal
  cron <new_renewal_cron_id> (one-shot at +144h LOCAL, durable: true).
  Polling cron carries new renewal id in {{RENEWAL_CRON_ID}} slot for
  best-effort cleanup on cadence-switch; renewal cron's own
  {{RENEWAL_CRON_ID}} slot is informational-only per terminating-shape
  (no fire-time consumer)."

Exit.
````

**Renewal-cron CronCreate parameters (load-bearing).**
- `cron`: a 5-field expression evaluating to +144h from polling-cron creation, computed in the operator's LOCAL timezone (per Claude Code docs https://code.claude.com/docs/en/scheduled-tasks "All times are interpreted in your local timezone"). Compute the wall-clock time in local tz and emit the cron expression for that single minute. Example: if polling cron is created at local time `2026-05-17 17:50` (operator's local tz, NO Z suffix — Z would imply UTC and mis-fire by the local-UTC offset), renewal cron fires at local time `2026-05-23 17:50`; emit cron expression `50 17 23 5 *` (minute=50, hour=17, day=23, month=5, any-day-of-week). NO Z suffix on either timestamp.
- `recurring`: `false` (one-shot — the renewal fires once, performs STEPs 1-5, and exits; the next renewal in the chain is created inside STEP 4).
- `durable`: `true`. Documented in the `CronCreate` tool schema as "persist to .claude/scheduled_tasks.json and survive restarts." See the failure-mode acceptance below for the open bug at design time and why the design encodes `durable: true` as honest-intent rather than load-bearing recovery.

Record both cron ids (initial polling cron + first renewal cron) in the radio-check initialization handshake on the coordination ticket per §7.1 beat 1. Subsequent renewal-fire rotations log to the same ticket per STEPs 3 and 5 above.

**Slot-lifecycle note (terminating-shape; minimum-CronCreate-count setup).** The polling-cron template gains TWO substitution slots that support the lock-step composition with the cadence-switching pattern (per the polling-cron-prompt-template STEP 4 extension): `{{RENEWAL_CRON_ID}}` and `{{RENEWAL_CRON_PROMPT_BODY}}`. The setup-time dance populates both slots via a chicken/egg-resolving sequence.

The lifecycle has two layers. Layer 1 is the prompt-body literal itself — the renewal-cron prompt body is generated at autonomous-mode setup time with all engagement-specific slot values pre-substituted (the inline-slot-values shape), then captured as a literal string. Layer 2 is the cron-id cross-references between the two crons — the renewal cron needs to know the polling cron's id (used at STEP 1 exact-match self-discovery; load-bearing); the polling cron carries the renewal cron's id as a best-effort cleanup hint in its `{{RENEWAL_CRON_ID}}` slot (used at cadence-switch STEP 4.1 to CronDelete the paired renewal cron; tolerates stale id per the terminating-shape acceptance below).

**Terminating-shape — load-bearing structural property.** Earlier revisions of the renewal design grew a multi-step re-bind dance out of a chicken/egg dependency that no longer exists: the renewal cron's STEP 1a explicit self-CronDelete required the renewal cron's body to carry its own id as an inline slot value, which forced the dance to re-bind the polling cron AND the renewal cron with mutually-known ids — generating an infinite re-bind regress at the polling cron's two RENEWAL-pointing slots. With one-shot auto-delete confirmed reliable per Claude Code docs (https://code.claude.com/docs/en/scheduled-tasks "Set a one-time reminder": "Claude schedules a single-fire task that deletes itself after running"), the renewal cron's STEP 1a no longer needs an explicit self-CronDelete; the runtime removes the cron after fire completes. This removes the renewal cron's RENEWAL_CRON_ID-in-own-body dependency entirely and collapses the setup dance to 4-step minimum and the cadence-switch dance to 2-step minimum (per the polling-cron-prompt-template STEP 4).

**Setup-time ordering (terminating-shape — 4-step minimum CronCreate count).** Two ids must be threaded through the dance: the renewal cron's body needs the LIVE polling cron's id (load-bearing for STEP 1 self-discovery) and the polling cron's `{{RENEWAL_CRON_ID}}` slot needs the live renewal cron's id (best-effort cleanup; tolerates staleness). The renewal cron's own id is no longer threaded into its own body (STEP 1a's explicit self-CronDelete removed; one-shot auto-delete handles cleanup). The 4-step dance is the minimum that resolves both required threadings without infinite regress.

  0. Generate the renewal-cron prompt body literal text from the renewal-cron template above (the renewal-cron STEPs 1-5 block). Substitute ALL engagement-specific slot values inline EXCEPT the polling-cron cross-reference + cadence, which become PLACEHOLDERS at this stage:
       `{{POLLING_CRON_ID}}` = `<PLACEHOLDER:POLLING_CRON_ID>`
       `{{CADENCE}}` = `<PLACEHOLDER:CADENCE>` (for STEP 4.2 cadence-switch re-substitution at fire time)
     The renewal cron's own `{{RENEWAL_CRON_ID}}` slot is ADA-discretion (no fire-time consumer): pass through as a placeholder, leave as the template default, or omit; the renewal cron does not consume the value at fire time. Capture the substituted-with-placeholders literal as `RENEWAL_CRON_PROMPT_BODY_LITERAL` for use in subsequent steps.
  1. CronCreate polling cron with `{{RENEWAL_CRON_ID}}` = `<PLACEHOLDER:RENEWAL_CRON_ID>` (placeholder; re-bound in step 3) and `{{RENEWAL_CRON_PROMPT_BODY}}` = `RENEWAL_CRON_PROMPT_BODY_LITERAL`.
     → returned id = `<polling_id_v1>`
  2. CronCreate renewal cron with prompt body = `RENEWAL_CRON_PROMPT_BODY_LITERAL` with `<PLACEHOLDER:POLLING_CRON_ID>` → `<polling_id_v1>` and `<PLACEHOLDER:CADENCE>` → the engagement cadence. recurring: false; +144h LOCAL cron expression per the renewal-cron STEP 4 arithmetic.
     → returned id = `<renewal_id_v1>`
  3. CronDelete `<polling_id_v1>`; CronCreate polling cron AGAIN with the same body except `{{RENEWAL_CRON_ID}}` = `<renewal_id_v1>`. `{{RENEWAL_CRON_PROMPT_BODY}}` is the same literal from step 1 (still carries `<PLACEHOLDER:POLLING_CRON_ID>` + `<PLACEHOLDER:CADENCE>` markers — that is correct, the polling cron uses this slot ONLY for STEP 4.2 cadence-switch re-substitution, not at any current-fire-time consumer).
     → returned id = `<final_polling_id>`
  4. CronDelete `<renewal_id_v1>`; CronCreate renewal cron AGAIN with body = `RENEWAL_CRON_PROMPT_BODY_LITERAL` with `<PLACEHOLDER:POLLING_CRON_ID>` → `<final_polling_id>` and `<PLACEHOLDER:CADENCE>` → cadence. recurring: false; the +144h LOCAL cron expression (re-computed from "now" at step 4 — minutes of setup latency are absorbed by the 24h buffer).
     → returned id = `<final_renewal_id>` (this is the renewal cron that goes into the radio-check initialization handshake; the `<final_polling_id>` is the polling cron)

The 4-step dance is the terminating shape. Extending to 5 steps with a re-CronCreate of the polling cron AGAIN to bind `{{RENEWAL_CRON_ID}}` to `<final_renewal_id>` would return `<truly_final_polling_id>`, which the renewal cron's body does NOT carry — its STEP 1 would then fail at +144h. Fixing that requires step 6 = re-CronCreate renewal cron with `<truly_final_polling_id>`, which returns `<truly_final_renewal_id>`, which the polling cron does NOT carry. Infinite regress. The terminating shape stops at 4 steps with explicit acceptance of the one-time polling-cron-slot stale-id residual: the polling cron `<final_polling_id>` carries `{{RENEWAL_CRON_ID}}` = `<renewal_id_v1>` (DEAD; CronDeleted in step 4). At the first cadence-switch, STEP 4.1's `CronDelete {{RENEWAL_CRON_ID}}` against the dead id no-ops gracefully; the live `<final_renewal_id>` is orphaned-relative-to-the-polling-cron's-slot but self-cleans via one-shot auto-delete at +144h. The slot converges to a LIVE id only at the +144h renewal-chain extension event via the renewal cron's STEP 4a hygiene re-bind.

(Implementation note: the placeholder-substitution approach above treats the prompt body as a string-templating exercise — substitute literal `<PLACEHOLDER:POLLING_CRON_ID>` and `<PLACEHOLDER:RENEWAL_CRON_ID>` markers with the returned cron ids at the moment they are known. ADA may choose any equivalent representation — `{{POLLING_CRON_ID}}`-style braces with a sentinel value, named-group regex substitution, or any other deterministic mechanism — as long as the post-substitution body contains the actual cron ids literally and the un-substituted placeholder cannot survive into a CronCreate prompt that an executing renewal cron would read.)

**Failure-mode acceptance (broader than a single-failure-mode framing).** The renewal mechanism protects against the +168h cron-expiry boundary. It does NOT, by itself, protect against session-lifecycle events:

1. **Cron-expiry boundary (the +168h window).** Addressed by the renewal chain: at +144h the renewal cron fires, rotates the polling cron, and schedules the next renewal at +144h-from-now. Steady-state continuous protection while the session stays alive and active.

2. **Renewal-chain break across multi-day continuous outage.** If the session is offline through BOTH the renewal fire AND the +168h cron expiry that follows (only possible when an autonomous engagement is left offline for > 6 days), the polling cron expires before the next renewal fires. Recovery is via peer-side radio-check escalation per §7.1 beat 3 (> 60-min peer-silence threshold fires; peer surfaces "lost contact with `<peer>`" to PRINCIPAL).

3. **Session-lifecycle event — fresh conversation, /clear, session exit.** Per Claude Code docs (Limitations section): "Starting a fresh conversation clears all session-scoped tasks. Resuming with `claude --resume` or `claude --continue` restores tasks that have not expired." Per `MAJOR_POLYBIUS.md` §7.4: polling crons are session-only (`durable: false` by default) and die when the session exits. The renewal cron uses `durable: true` as honest intent (documented tool-schema parameter; would survive session restart when working) — but is subject to the open bug at anthropics/claude-code issue #40228 (opened 2026-03-28, unresolved at design time) where `durable: true` does not currently persist.

   **Bug #40228 surveillance state (Arc 41, 2026-05-18):** the `durable: true` parameter encoded above is honest-intent — it works when the bug is fixed without canon revision (the parameter is documented schema; the persistence is the runtime defect). Watch state: bug #40228 remains OPEN at anthropics/claude-code; no recovery-discipline canon change is baked in at §11 step 1.5; recovery rests on `MAJOR_POLYBIUS.md` §9 step 7 PRINCIPAL-consent re-setup. If the bug is fixed in a Claude Code release, the canon does NOT need revision — `durable: true` becomes load-bearing-as-documented rather than honest-intent-only. No reassessment ticket required until bug closure.

   **Recovery path (load-bearing; works regardless of the durable bug; PRINCIPAL-consent-required, NOT transparent re-bootstrap):** the polling cron is session-only by canon; when the session exits or a fresh conversation starts, both the polling cron and the renewal cron are lost. Recovery is NOT transparent. The load-bearing recovery cite is `MAJOR_POLYBIUS.md` §9 step 7 (Activation checklist long-running-engagement entry): "If this engagement is long-running (multi-session arc work, cross-tier coordination, an active PLINY in a separate session): **request PRINCIPAL consent and set up a polling cron per §7.4**." On the operator's next session activation, POLYBIUS executes §9 of the activation checklist, which (a) reads bw state, (b) detects an open coordination ticket on a long-running engagement, (c) **requests PRINCIPAL consent** to re-setup the polling cron, (d) on consent, runs the §11 setup checklist including this step 1.5, which creates a NEW polling cron paired with a NEW renewal cron. The renewal mechanism is re-bootstrapped from a clean slate. Alternative recovery path: PRINCIPAL re-issues the autonomous-mode trigger ("go autonomous on this work") — `MAJOR_POLYBIUS.md` §13.4 step 2 detects the trigger and routes through the same §11 setup checklist. Both paths converge on §11 step 1.5; both require PRINCIPAL action (consent OR trigger). Neither is transparent.

   If a renewal cron from a prior session survives (durable bug eventually fixed) and fires in a session that has already created a fresh polling cron via §9 step 7 or §13.4 re-entry, STEP 1a's no-op-and-exit branch handles the orphan-renewal cleanly — the renewal cron posts the orphan-observation comment and exits; one-shot auto-delete per Claude Code docs removes the cron from the session after fire completes, so the stale chain does not perpetuate alongside the fresh chain.

   The session-lifecycle failure mode is therefore NOT a multi-day outage — it is any fresh-conversation start at any time, recovered consent-mediated (not transparent) by the operator's next session activation running §9 step 7 (or by PRINCIPAL's autonomous-mode re-trigger routing §13.4 step 2). The renewal mechanism does not need to protect against it directly; it composes with the §9 step 7 / §13.4 recovery paths. STEP 1a's no-op-and-exit is the seam where the orphan-renewal-from-prior-session meets the fresh chain.

4. **Cadence-switch × renewal composition.** Without the lock-step rotation fix, polling-cron-template STEP 4 cadence-switch (CronDelete old + CronCreate new at new cadence) would leave the paired renewal cron's inline `{{POLLING_CRON_ID}}` + `{{CADENCE}}` slot values stale. At +144h the renewal cron's STEP 1 exact-match would no-op AND STEP 1a would mis-classify the case as session-lifecycle (the polling cron is alive at the new id, not session-dead) AND the replacement polling cron from the cadence-switch would have no successor renewal cron. The renewal chain dies silently AND the new chain never starts. Recovery: same as scenario 3 above (peer-side radio-check on >60 min self-silence, then PRINCIPAL-consent-mediated re-setup) — but AFTER silent expiry of the new polling cron at +168h. The polling-cron-template STEP 4 lock-step rotation fix eliminates this scenario by rotating BOTH crons in lock-step: cadence-switch CronDeletes old polling AND old renewal, CronCreates new polling AND new renewal, with cross-referenced slot values populated per the slot-lifecycle note above. With the fix shipped (and the `{{RENEWAL_CRON_PROMPT_BODY}}` slot supplying the source so STEP 4.2 can CronCreate deterministically), cadence-switching composes cleanly with the renewal mechanism.

   **Partial-failure-state surface of the cadence-switch dance.** The terminating-shape cadence-switch is a TWO CronCreate-operation dance per cadence-switch (STEP 4.1 polling rotate → STEP 4.2 renewal rotate; no re-bind sub-steps — one-shot auto-delete handles orphan cleanup; polling cron's `{{RENEWAL_CRON_ID}}` slot tolerates one-cycle staleness per the best-effort semantics). If the polling cron's prompt-body execution is interrupted between STEP 4.1 and STEP 4.2 (session crash, tool failure mid-fire, context exhaustion within the fire), the cron pair is left in an intermediate state — e.g., STEP 4.1 completes leaving a new polling cron alive with stale `{{RENEWAL_CRON_ID}}` pointing at the just-CronDelete'd old renewal cron, and no live paired renewal cron at all (the `<new_renewal_cron_id>` that STEP 4.2 would have created is never created). Recovery from any such partial-failure state is via the SAME peer-side radio-check escalation surface as the broader cron-mechanism-failure modes: §7.1 beat 3 — when the self-silence threshold (>60 min) trips on the polling-cron side, the peer POLYBIUS surfaces "lost contact with `<peer>`" to PRINCIPAL, and PRINCIPAL re-issues the autonomous-mode trigger (routing through `MAJOR_POLYBIUS.md` §13.4 step 2 → §11 setup checklist including step 1.5), OR the operator's next session activation runs `MAJOR_POLYBIUS.md` §9 step 7 (long-running-engagement polling re-setup; PRINCIPAL-consent-required). Either path converges on a clean §11 setup that creates a fresh polling-cron + renewal-cron pair from scratch, discarding any intermediate-state artifacts — the orphan renewal cron from the partial state self-cleans via one-shot auto-delete at +144h (terminating-shape; no explicit cleanup needed). No new recovery infrastructure is required — the broader cron-mechanism failure-mode recovery surface already covers this partial-failure-state shape. The cost is the same as scenario 3: PRINCIPAL-consent-required, not transparent; recovery latency is bounded by the >60 min peer-silence threshold + the operator's next-session activation cadence.

No additional watchdog cron ships — the alternative (peer-side renewal monitoring, separate watcher cron, double-cron belt-and-suspenders) adds the same coordination-dependency problems Option 2 was rejected for in the A7 decision matrix. Bounded staleness is acceptable; protocol-induced bugs cost more. The renewal cron is the per-seat unilateral mechanism; §9 step 7 / §13.4 re-entry is the cross-session-lifecycle mechanism; polling-cron-template STEP 4 lock-step rotation is the cadence-switch composition mechanism; together they cover the failure modes the design accepts.

This mirrors the per-seat-unilateral cadence-switching pattern in §7.2 ("Cadence-switching is per-seat unilateral. Each peer reads complexity tags on incoming comments and adjusts ITS OWN cron"). Each seat renews its OWN polling cron unilaterally; no cross-seat renewal coordination exists.

Cross-ref to template: the polling-cron-prompt template at `substrate/templates/polling-cron-prompt-template.md` does NOT carry in-fire renewal logic — cron-expiry handling lives in this step 1.5 instead. See the end-of-file pointer note at the template for the back-cite. The template's STEP 4 cadence-switch path performs the lock-step rotation of both crons per the slot-lifecycle note above; the template's substitution-slot table carries `{{RENEWAL_CRON_ID}}` + `{{RENEWAL_CRON_PROMPT_BODY}}` to support the composition.

Cross-ref to recovery paths: `MAJOR_POLYBIUS.md` §9 step 7 (long-running-engagement polling re-setup, PRINCIPAL-consent-required) is the load-bearing recovery path for session-lifecycle loss of the cron pair on the operator's next session activation while autonomous-mode is still desired. `MAJOR_POLYBIUS.md` §13.4 step 2 (autonomous-mode trigger detection → §11 setup) is the recovery path when PRINCIPAL re-issues the autonomous-mode trigger. Both converge on the §11 setup checklist including this step 1.5. The §13.4 note carried by Arc 36 closes the loop by mentioning renewal-cron presence as part of setup-complete confirmation.

**2. Radio-check pattern with peer seats** (per §7.1):

- Initialization handshake on shared coordination ticket.
- Routine heartbeats every ≤30 min.
- Missed-check escalation > 60 min.
- Closure handshake on ticket close.

**3. Cross-tier coordination convention** (per §7.4):

- `[for: <upper-seat>]` tag on own-bw comments to request cross-project context.
- Upper seat polls down; you never write up.
- PRINCIPAL is exception-handler.

**4. Bw write-boundary discipline** (per §7.5):

- Each tier writes own bw and downward; never upward.
- Coordination meets in the lower tier's bw.

**5. Activation paste discipline** (per §8 + `MAJOR_POLYBIUS.md` §5.1/§5.5):

- Positive references only when activating downstream agents.
- Filename varies by install mode (cheatsheet at `substrate/templates/activation-paste-cheatsheet.md`).

**6. Bw storage model awareness** (per §9):

- bw lives on the `beadwork` orphan branch, not a `.bw/` directory.
- Detection: `bw prime` self-reports OR `git branch -a | grep beadwork`.
- Never `git checkout beadwork` from the main worktree.

**Setup-complete confirmation.** After all seven are in place, post a setup-complete comment on the engagement's coordination ticket naming: cron id, cadence, escalation triggers, peer name, expected duration. Surface the same to PRINCIPAL once. From this point forward, routine status flows via bw; PRINCIPAL only sees the universal-escalation-trigger surfaces (§10) until the engagement closes or the autonomous-mode trigger is reversed.

**Cross-ref:** §25 PRINCIPAL-gate discipline — autonomous-mode setup does NOT relax PRINCIPAL-gates. If downstream encounters a PRINCIPAL-gated clause, the workflow PAUSES per §25.3 regardless of operating engagement.

**Teardown procedure** (autonomous → HITL trigger detected): `CronDelete` the polling cron(s) for this engagement. Post final `[radio-check <self-seat-slug> standing down]` on the coordination ticket(s). Confirm to PRINCIPAL: "back in the loop; teardown complete; scope: <global | per-seat name>". Per-seat teardown affects only the named seat's coordination crons; sibling seats keep their own crons.

**7. Mode declaration in directives.** Every arc directive declares its expected operating mode in the dispatch frame (the existing pattern across Arcs 21-36; this step makes the convention explicit). The directive's dispatch frame names the operating mode per phase. Typical pattern:

- Phase 1 (Design) — Mode 1 × Autonomous (DAEDALUS heads-down on design.md per the directive's locked envelope).
- Phase 2 (Build) — Mode 1 × Autonomous (ADA heads-down on the worktree).
- Phase 3 (Verify) — Mode 1 × Autonomous (VERA + CATO + ZENO parallel).
- Phase 4 (Ship) — Mode 1 with PRINCIPAL surface for ship/no-ship if the work is public-facing (otherwise autonomous-ship per `u--7yg.11`).

A directive that does not name the mode explicitly inherits semi-autonomous (Mode 1 × Autonomous) per the default. A directive that names a per-phase override (e.g., "Phase 2 runs in HITL because the build touches credential-shaped code per §20.3 refusal-as-signal") overrides the default for that phase only. Default for arc dispatches is **semi-autonomous** per Arc 21's A4 (PRINCIPAL-AFK during multi-session arc work).

**8. Mid-engagement mode transitions.** When the mode changes mid-engagement, the seat that calls the transition posts a `[mode-change <new-mode>] [from: <self-seat-slug>]` comment on the coordination ticket. Peer seat reads + adapts on its next poll. Example: PLINY calls "regress to Mode 2 — surfaced ambiguity that needs PRINCIPAL judgment" → posts `[mode-change mode-2] [from: pliny-the-stoa]` → POLYBIUS reads on its next poll and adapts (e.g., increases polling cadence to active per §7.2 because Mode 2 typically has higher coordination volume).

The mode-change comment is a coordination signal; it does NOT itself transition the engagement. The transition is effected by the receiving seat's adapted behavior (e.g., POLYBIUS engaging PRINCIPAL chat-side; PLINY pausing the next CAPTAIN dispatch until the ambiguity resolves). The signal-then-adapt pattern preserves the cooperative-yield property §18.3 names: no seat can push-interrupt a running peer; the mode-change comment yields at the receiving seat's next poll.

Tag-parser interaction (per §7.7): the `[from: <self-seat-slug>]` clause in the mode-change tag classifies under §7.7 case 3 (`[from: <slug>]` slug-match → the tagged comment contributes to `last_self_activity` / `last_peer_activity` timeline-arithmetic as a coordination-attentiveness signal). This is INTENDED: a mode-change comment IS evidence that the peer is alive AND announcing a coordination-attentive action; counting it as a heartbeat-equivalent for missed-check thresholds is the correct behavior. Mode-change comments thus serve dual function — coordination signal (substance) AND liveness signal (timeline-arithmetic).

**9. Downward-propagation rule (Arc 21 A4 recap).** A parent seat's mode propagates to dispatched subagents unless explicitly overridden in the dispatch brief. This is the existing Arc 21 A4 canon at `MAJOR_POLYBIUS.md` §13.3; recapped here for cross-section completeness. Concretely:

- If user-tier POLYBIUS is in semi-autonomous and dispatches PLINY for an arc, PLINY inherits semi-autonomous unless the directive declares HITL for Phase X.
- If PLINY is in semi-autonomous and dispatches a CAPTAIN, the CAPTAIN inherits semi-autonomous unless the dispatch brief declares HITL for the CAPTAIN's scope.
- The override is explicit, in the dispatch brief; silent override is a directive bug.

Cross-refs for steps 7-9: `operating-disciplines.md` §10 (engagement axis + progression sequence + transition triggers — co-landed this arc); `MAJOR_PLINY.md` §5.1 (operating-mode awareness in the dispatch brief — the directive convention step 7 makes explicit); `MAJOR_POLYBIUS.md` §13.3 (Mode propagation across nested tiers — the downward-propagation canon home); `operating-disciplines.md` §7.2 (Adaptive polling cadence — peer adaptation on mode-change signal interacts with cadence regime selection); `operating-disciplines.md` §7.7 (bw-timeline parsing — the case 3 classification that counts mode-change tags as liveness signals); Arc 21 directive A4 (empirical anchor for downward-propagation rule).
