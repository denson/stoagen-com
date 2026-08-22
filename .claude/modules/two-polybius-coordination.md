# Two-POLYBIUS async coordination via bw polling — instruction module

> Relocated from `operating-disciplines.md` §7 (CONDITIONAL — read when two POLYBIUS seats
> coordinate async via bw polling; CAPTAINs never coordinate two-POLYBIUS). Provenance:
> composition-layer spec `bw show stoa--xyb.4`; debloat Arc 47 cut `agents/design/arc-47/design-rev2.md`
> + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.8`. The slim-core residue is the §7 stub
> (which keeps §7.1/§7.2/§7.3/§7.4/§7.5/§7.7 as real heading lines for cross-ref resolution) +
> relocation-index row in `operating-disciplines.md` §0.5. The §7.6 empirical lineage compresses to
> `Anchor: ariadne--m20, stoa--e39` (recover via `bw show`).

When two POLYBIUS seats — typically user-tier + project-tier, or parent + sub-project — share a coordination ticket, polling makes bw a near-real-time async channel. Five sub-disciplines apply: peer-failure detection (radio-check), responsiveness adjustment (adaptive cadence), polling architecture (unified vs per-engagement), data-flow direction (write boundaries), and coordination routing (`[for:]` tags). Each is captured below.

This whole section is the universal-team layer. POLYBIUS-tier specific framings cross-ref back here; see `MAJOR_POLYBIUS.md` §7.1 (write boundaries), §7.4 (polling capability), §3 (alternate routing target).

### 7.1 Radio-check protocol

When two seats are coordinating async via polling, neither can tell the other has stopped responding without an explicit liveness signal. The radio-check protocol gives each peer a way to detect peer-failure within a bounded time without burning attention on routine heartbeats.

NOTE — distinct from `operating-disciplines.md` §38: §7.1's `[radio-check <self-seat-slug>]` is the PERIODIC two-POLYBIUS peer-failure handshake; §38's `[radio-check] [for: <seat>]` is the ON-DEMAND seat-liveness ping. Same token prefix, different protocol.

Five beats:

1. **Initialization handshake.** When two seats begin coordinating on a shared ticket, each posts a `[radio-check <self-seat-slug>]` comment naming its cron id and current cadence. Both ack on first poll (a one-line "saw your radio-check; proceeding" comment). The handshake confirms both ends are polling and the channel is live.
2. **Routine heartbeats.** Every ≤30 minutes of session-time, each peer posts a one-line state comment on the coordination ticket. These do not require ack — they are visible-by-poll. Heartbeats are cheap; they prevent peer-silence false alarms during legitimately quiet phases.
3. **Missed-check escalation.** If a peer is silent > 60 minutes AND the coordination ticket is open, the still-active peer surfaces "lost contact with `<peer>`" to PRINCIPAL. Peer-silence is the only universal escalation that fires automatically; everything else is event-driven.
4. **Closure handshake.** When the coordination ticket closes, both peers post a final `[radio-check <self-seat-slug> standing down]` comment and run `CronDelete` on their polling cron(s) for this engagement. The closure handshake is what prevents zombie crons polling a closed ticket forever.
5. **Author-tag convention (POLYBIUS-on-POLYBIUS coordination).** Every coordination comment posted by a POLYBIUS instance carries an explicit sender tag. Three forms cover the cases:
   - Self-heartbeat: `[radio-check <self-seat-slug>]` — form unchanged from beat 1; slug-normalization rule below applies.
   - Cross-seat addressed: `[for: <recipient-seat-slug>] [from: <sender-seat-slug>]` — both tags mandatory. This expands the prior `[for:]` convention (currently §7.4) from cross-tier upward only (project→user) to bidirectional; `[from:]` is new in Arc 36.
   - Own-bw substantive (not addressed to a specific peer): `[from: <self-seat-slug>]` — for status updates, gauntlet phase comments, decisions logged in own bw without a specific recipient.

   **Slug normalization:** lowercase, hyphenated, no whitespace. Example slugs: `user-tier-polybius`, `polybius-the-stoa`, `polybius-ariadne-core`. The slug matches the role-file slug used by `substrate/templates/autonomous-mode-activation-template.md`. Display-form names (e.g., "user-tier POLYBIUS") may appear in prose within comment bodies; the LEADING tag always uses the slug.

   **Scope:** the convention applies to POLYBIUS instances only (user-tier POLYBIUS, project-tier POLYBIUS, sub-project POLYBIUS). PLINY, CAPTAINs, and pair-programmer Majors are NOT required to author-tag — their substantive comments do not enter the timeline-arithmetic that drives radio-check / heartbeat thresholds. See §7.7 for the parsing procedure and the empirical anchor.

   The convention exists so peers reading the timeline can attribute each POLYBIUS comment to its sender without inferring from timestamp + content — the inference step that failed in the 2026-05-04 stoa--e39 empirical (~25-min coordination stall during arc-21 §5.4 review handoff).

### 7.2 Adaptive polling cadence

Coordination is not uniformly active. A multi-hour arc has bursts of activity (phase transitions, surfaced ambiguities, decision points) and quiet stretches (heads-down work, review, waiting on a peer). A single fixed cadence either over-polls (during quiet) or under-polls (during active) — both fail.

Three regimes:

| Regime | Cadence | When |
|---|---|---|
| Active | `*/2 * * * *` | rapid back-and-forth; surfaced question pending; phase transition imminent |
| Default | `*/5 * * * *` | the standard polling cadence; works for most coordination |
| Quiet | `*/15-30 * * * *` | confirmed-quiet stretch; both peers heads-down; nothing pending |

Peers signal complexity on incoming comments via tags: `[complexity: simple]`, `[complexity: medium]`, `[complexity: complex]`. The tag is advisory — it tells the receiving peer how much processing the comment will take and whether a follow-up burst is likely.

**Cadence-switching is per-seat unilateral.** Each peer reads complexity tags on incoming comments and adjusts ITS OWN cron via `CronDelete` + `CronCreate`. There is no negotiation protocol. Both peers converge to the new cadence within one cycle of the slower of the two cadences in play.

**Cadence-up worst-case staleness.** If the receiving peer is on `*/30` (quiet) and a complexity tag arrives that warrants `*/2` (active), the peer will not see the tag for up to one full cycle of its CURRENT cadence — i.e., up to 30 minutes. The active section runs at degraded responsiveness for that bounded window before the slower peer notices. We accept this: the alternative (a synchronization protocol where peers negotiate cadence-up) is more failure-prone than the bounded delay. Protocol-induced bugs cost more than bounded staleness.

**Dual-channel mitigation.** When posting a complexity tag that would justify cadence-up, the POSTING peer ALSO posts an explicit `[cadence: active]` comment on the same fire. Two channels reduce miss-probability; worst-case staleness is unchanged; perceived responsiveness improves.

**Cost framing.** Default cadence is 12 fires/hour; active is 30; quiet is 2-4. The cost difference is small in tokens. The reason for adaptive cadence is not cost — it is matching responsiveness to actual coordination demand so PRINCIPAL-attention surfaces stay timely without burning fire-budget on dead air.

**Cloud-cron limitation.** Cloud scheduled tasks have a 1-hour minimum cadence; the active/quiet regimes do not apply. The workaround: a single fixed-hourly cloud cron that escalates to a local active-cadence cron when an active phase begins. No cloud-cron template ships in the substrate; treat cloud as the documented limitation, not a deliverable.

### 7.3 Unified polling pattern

When a single POLYBIUS seat is coordinating with multiple peers across multiple bw stores at the same cadence — typically user-tier POLYBIUS watching several project-tier engagements — the default is ONE cron walking all watched stores per fire (not N separate crons).

Per-fire procedure:

1. `cd` to each watched store in turn.
2. `bw sync` to pull peer comments.
3. `bw show <watched-tickets>` for each store; aggregate new content since the last fire.
4. Aggregate signals: new substantive comments, radio-check freshness windows, self-heartbeat-due timers, escalation-trigger conditions.
5. Act per the aggregated state — surface to PRINCIPAL on meaningful transitions; otherwise silent.

Cost framing: ~Nx fewer fires than N separate crons when cadences match, modestly bigger context per fire, well within fire budgets. The trade-off: a single shared cadence across all watched engagements. When one watched engagement needs faster polling (active mode per §7.2) while another is quiet, two crons are appropriate. The default is unified; split per-engagement when the cadence trade-off justifies it.

### 7.4 Cross-tier coordination routing

The `[for: <recipient-seat-slug>] [from: <sender-seat-slug>]` tag pair marks an addressed POLYBIUS comment — either direction across any POLYBIUS pair. The most common use is cross-tier upward (project-tier → user-tier needing cross-project context, an empirical anchor from another project, or a sanity check that benefits from upper-tier visibility): the project-tier seat posts on a ticket in YOUR OWN bw prefixed with `[for: user-tier-polybius] [from: <self-seat-slug>]`. The upper-tier seat polls down via unified poll (§7.3) and responds on the same ticket within poll cadence (~5 min default). This is the cross-tier-coordination-meets-in-lower-tier pattern (§7.5 + `MAJOR_POLYBIUS.md` §7.1).

The same tag pair is also used for in-tier peer addressing (e.g., user-tier POLYBIUS addressing project-tier POLYBIUS on a project-tier coordination ticket: `[for: polybius-the-stoa] [from: user-tier-polybius]`) — Arc 36 promoted the convention to bidirectional. The `[from:]` tag is mandatory on every addressed comment per §7.1 beat 5; see §7.7 for the parsing procedure that consumes both tags.

PRINCIPAL is exception-handler:

- Project-direction calls → PRINCIPAL.
- Ship/no-ship for substantial public-facing work → PRINCIPAL.
- Strategic seat input (cross-project priority, ambiguous PRINCIPAL preference) → PRINCIPAL.
- Cross-project context, empirical anchors, sanity checks → upper-tier POLYBIUS via `[for:]` tag.
- Routine technical/operational decisions → handle yourself.

**Universal escalation triggers** (any seat, autonomous mode, surface to PRINCIPAL): substance disagreement after one round-trip with peer; authorship/copyright/PRINCIPAL-final-say content; irreducible ambiguity that blocks progress; peer silence > 60 minutes on an open coordination ticket; arc closure (when shipping public-facing work).

Empirical anchor: 2026-05-04 — workspace POLYBIUS got the convention via an ad-hoc relay file; the-stoa POLYBIUS did not (until this substrate update). Ad-hoc relay-file conveying is brittle; substrate-canonical convention propagates on install.

(Cross-ref: §29 NEW Arc 37 — Multi-team interoperation; §29 extends the cross-tier routing convention to the across-workspace layer.)

### 7.5 Cross-tier write boundaries

Each tier writes its own bw and downward; never upward. Coordination always meets in the lower tier's bw. The asymmetric scoping keeps each tier's working memory bounded — project-tier writing to user-tier accumulates cross-project context that defeats the bounded-context property.

| Seat | Reads | Writes |
|---|---|---|
| User-tier POLYBIUS | u-- + all project-tier (downward) | u-- + all project-tier (downward) |
| Project-tier (workspace, sub-project) | own project bw | own project bw |

User-tier descends; project-tier never ascends. The same recursive asymmetry applies parent-project / sub-project: parent sees sub-project's bw; sub-project does not see parent's by default.

**Read-exception (preserved across tiers):** project-tier work that is system-architecture-shaped (a meta-team arc) may PULL from user-tier beadwork as input. This is a READ-only exception — never a write exception. The "never ascends" rule on writes holds without exception. If a project-tier seat ever needs to write upward, the correct path is the `[for: <upper-seat>]` tag pattern in §7.4 — post in your own bw; the upper seat polls down.

**Cross-ref to MAJOR_POLYBIUS §7.1:** `MAJOR_POLYBIUS.md` §7.1 carries the same rule framed for the POLYBIUS seat specifically; this section is the universal-team layer. Bidirectional.

(Cross-ref: §29 NEW Arc 37 — the no-upward-writes rule applies recursively at the workspace boundary per §29.4.)

### 7.7 bw-timeline parsing: author-attribution via tags

When a POLYBIUS peer reads a bw timeline to compute "last own activity" / "last peer activity" / "missed-check threshold" (§7.1 beats 2 and 3), the attribution step is load-bearing. A misattributed comment causes silent coordination stalls — the failure mode that surfaced in the 2026-05-04 stoa--e39 empirical (project-tier POLYBIUS attributed a `[for: POLYBIUS_the_stoa]` peer comment as own self-heartbeat; ~25-min review-handoff stall before the misread was caught).

**Parse-by-tag, not by inference.** Every POLYBIUS coordination comment carries a `[from: <seat-slug>]` or `[radio-check <seat-slug>]` tag per §7.1 beat 5. Read the tag first; do NOT infer authorship from timestamp, content pattern, or position. Timestamp-and-content inference is exactly what failed in the e39 empirical.

**Procedure (executed per fire of the polling cron — encoded mechanically at `substrate/templates/polling-cron-prompt-template.md` STEP 1.5):**

For each new comment in the timeline since the last fire, extract the leading tag and classify into one of four cases:

1. **`[radio-check <slug>]`** — POLYBIUS heartbeat by `<slug>`. Slug-match against `{{SELF_SEAT_SLUG}}` and `{{PEER_SEAT_SLUG}}` (lowercase, hyphenated, whitespace-tolerant comparison): on self-match, this is own heartbeat → contributes to `last_self_activity`. On peer-match, this is peer heartbeat → contributes to `last_peer_activity`.

2. **`[for: <slug-Y>] [from: <slug-X>]`** — addressed POLYBIUS comment by `<slug-X>` to `<slug-Y>`. Same slug-match procedure: `<slug-X>` self-match contributes to `last_self_activity`; `<slug-X>` peer-match contributes to `last_peer_activity`. The `<slug-Y>` recipient tag is advisory for readers — it does NOT enter timeline-arithmetic.

3. **`[from: <slug-X>]`** — own-bw substantive POLYBIUS comment by `<slug-X>`, no specific recipient. Same slug-match: self-match → `last_self_activity`; peer-match → `last_peer_activity`.

4. **Untagged, OR tag-slug does not match a known POLYBIUS slug** — non-POLYBIUS comment (PLINY phase status, CAPTAIN verdicts, pair-programmer outputs, legacy pre-Arc-36 POLYBIUS comments). These are SUBSTANCE comments — they do NOT enter `last_self_activity` / `last_peer_activity` timeline-arithmetic. They may be substance-load-bearing for OTHER reads (the substantive content of the comment is read for its own value); they simply do not contribute to coordination-attentiveness signals.

**Compute peer-silence threshold and self-heartbeat-due timing from tagged-POLYBIUS comments only.** This is the load-bearing rule: only case-1, case-2, and case-3 (with slug-match) contribute timestamps to `last_self_activity` / `last_peer_activity`. Case-4 comments do NOT.

**Why non-POLYBIUS comments are excluded.** PLINY / CAPTAIN comments are SUBSTANCE comments (gauntlet phase status, ambiguity surfaces, dispatch results) — not coordination-attribution comments. Including them in `last_peer_activity` would defeat the radio-check protocol (peer-silence threshold would never fire because PLINY comments would mask actual POLYBIUS silence). The protocol intentionally tracks POLYBIUS-on-POLYBIUS attentiveness as a separate signal from team activity-volume.

**Self-misattribution guard.** Never assume the most recent comment is "yours" by timestamp proximity. Always verify by tag-slug match. The e39 empirical was precisely this misattribution shape.

**Worked example (Arc 36 itself).** Arc 36 IS the first worked example under this canon. During this arc's coordination on `stoa--jru`, POLYBIUS_the_stoa's heartbeats carry `[from: polybius-the-stoa]` per §7.1 beat 5; cross-tier comments to user-tier POLYBIUS carry `[for: user-tier-polybius] [from: polybius-the-stoa]`. A peer reading the stoa--jru timeline applies this §7.7 procedure to attribute each coordination comment without inference.

**N=1 provenance (per §6.7.1).** The empirical anchor is single — the 2026-05-04 stoa--e39 misread (~25-min stall). Informal-partial-adoption of `[radio-check <slug>]` tags has been in practice across Arcs 32-35 (N=4 bit-by-it of the legacy form). Worked-when-applied with full canon is N=0 prior to Arc 36; Arc 36's self-application is the first observation. Future arcs operating under §7.7 + §7.1 beat 5 either succeed and accrete the worked-when-applied count, or surface a fresh failure mode and surface back to the canon-promotion gate per §6.7.1. The fix is in canon NOW because PRINCIPAL declared (under the no-deferrals stance, 2026-05-17) and the e39 empirical is a single concrete bit-by-it; structural-lesson status accretes over future engagement-evidence per §6.7.1.

**Future scope.** Extending the convention to PLINY / CAPTAIN / pair-programmer Majors (i.e., promoting case-4 attribution to first-class timeline-arithmetic) is hard-locked OUT of Arc 36 per A2.5 + A14. A future arc may extend with explicit scope expansion if a recurring gauntlet-pacing failure mode surfaces. The mechanical-enforcement layer (pre-comment hook, CI lint) is also hard-locked OUT per A14 — Arc 36 ships prose canon + parser-step template per §27's mechanical-narrow + agent-inspection pattern; mechanical enforcement is a future arc IF non-compliance recurs.

### 7.6 Empirical lineage

Anchor: `ariadne--m20`, `stoa--e39` — the radio-check + adaptive-cadence + unified-poll + write-boundary disciplines surfaced together during the ariadne--m20 autonomous-mode coordination on 2026-05-04 (handshake, heartbeats, write-boundary catch by PRINCIPAL, closure handshake). The stoa--e39 misattribution stall (2026-05-04, ~25-min) is the §7.7 anchor. Recover via `bw show ariadne--m20` / `bw show stoa--e39`.
