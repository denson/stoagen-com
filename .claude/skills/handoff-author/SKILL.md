---
name: handoff-author
description: |
  Author a session-handoff document before /compact or session close, so a future agent (same seat, fresh session, no working memory) can orient quickly via low-token overview + indirection to durable substrate detail. Invoke when told to "prepare for handoff," "prepare for compaction," "write a handoff," "snapshot before /compact," or any equivalent. The handoff is the continuity-of-identity layer (per operating-disciplines.md §30 four-layer identity model): it preserves the in-flight work-state across context resets while pointing at memories (alignment layer) and bw substrate (detail layer) that persist independently. **Mandatorily** records the prior-generation session id for /resume per SPECIFICATION.md §10.1 generational-lineage architecture (recording is mandatory not optional per 2026-05-17 PRINCIPAL ratification of SPEC_AUDIT C1; if the session id is genuinely unrecoverable, explicitly note the truncation in the handoff).

  Applies to any agent that wants semi-persistence across compactions — most commonly orchestrator-tier seats (POLYBIUS, PLINY, pair-programmer MAJORs) but also any specialist preserved over long timescales. Triggers on phrasings like "we're approaching context limit — handoff time," "before I /compact, write a handoff," "session-end snapshot," "summarize for the next me."
author: Denson Smith
---

# Handoff-author skill

## When to invoke

- Before invoking `/compact` to reduce conversation context
- Before closing a session that another agent (typically the same seat in a fresh session) will resume
- Periodically during long-running engagements as a checkpoint
- When PRINCIPAL explicitly asks for one

This is NOT a checklist; it is six **guiding principles** that shape what to write. The principles trade off — judgment determines which dominates in any given handoff.

## The six principles

1. **Highest value-per-token first.** A handoff is read by a context-starved agent; the first 200 tokens determine whether they orient correctly. Lead with the load-bearing context — what's in flight, what's just-closed, what immediate decision the next session faces. Background and history come later or as references.

2. **Indirection over inlining.** Reference bw tickets by ID + short description; reference memories by topic, not content; reference durable artifacts by path. The handoff is the *overview*; the detail lives in substrate. A 50-line handoff that points at 10 bw tickets is more useful than a 500-line handoff that inlines them — because the next session can drill into exactly the tickets the work needs, not waste tokens loading detail it won't use.

3. **Write for the context-free reader.** Assume the next agent has only the role file + memories — no prior conversation history. Concepts that were established mid-conversation must be self-contained or explicitly referenced. "The thing we discussed yesterday" fails; "the bw-fit matrix extension at stoa--tvc" works.

4. **Curate based on what they'll need.** Don't dump everything you have; dump what advances the work from here. The test: *if I woke up cold right now and read this handoff, what would I most need to know to keep moving?* Things from earlier in the session that no longer matter — omit. Things that matter only as background context — reference, don't inline.

5. **Cite, don't duplicate.** Cross-reference memories that are load-bearing for the current work; don't restate them. Memories are durable across compactions; the handoff doesn't replace them. The handoff says "see `feedback_radio_check_pattern_for_polybius_coordination.md` for the discipline applied here" — not the discipline's full text.

6. **Honor the value/effort tradeoff.** A 5-minute handoff that captures 80% of the value beats a 30-minute handoff that captures 95%. Ideal is unattainable; good is the target. Author the handoff at the level of effort the next session can afford. If you're about to /compact under time pressure, a short crisp handoff beats a thorough delayed one.

## Suggested procedure (adapt to context — not a template)

This procedure is a *starting point*, not a template. Skip steps that don't apply; expand steps that need more.

1. **Identify the agent role + scope** — POLYBIUS-session handoff vs PLINY-arc handoff vs specialist handoff. Different scopes lead with different content.
2. **Snapshot current state** — what's in flight (background dispatches, open arcs, paused PLINY sessions); what just-closed (recent merges, ticket closes, decisions made).
3. **Identify open decisions** — what does the next session face? Pending ratifications, queued dispositions, awaiting-PRINCIPAL items.
4. **Reference load-bearing context** — by indirection. Memories, bw tickets, durable artifacts on disk. Short descriptions; the next agent reads detail on demand.
5. **Surface any non-obvious state** — uncommitted work, branches not yet merged, processes that survived a session boundary, conventions established mid-engagement.
6. **Record prior-generation session id(s) for /resume (MANDATORY).** Per the the-stoa `SPECIFICATION.md` §10.1 generational-lineage architecture, capture the session id(s) in a "Generational lineage" section of the handoff. Recording is mandatory, not optional — the /resume lineage is load-bearing for the spec's "current generation creates successor generation" framing; absent the recorded session id, successor generations cannot `/resume` the prior-generation seats and the lineage truncates. The successor reads the handoff, decides whether `/resume` is the right entry path vs fresh session + activation paste, and proceeds accordingly. The session id is the prior generation's `claude` invocation identifier (typically visible in the prior session's terminal title or via `claude --session` invocation). If the session id is genuinely unrecoverable (terminal closed before capture, no persistent record), explicitly note the truncation in the handoff so the successor knows the `/resume` option is unavailable for this lineage step. The invocation discipline (when to `/resume` vs when to spawn fresh, what to do if the recorded id is stale) is a separate canon gap tracked separately.
7. **Write to a durable location** — workspace-root `HANDOFF_<role>_<date>.md` is a reasonable default; vary by convention. The file persists; it doesn't need to live in bw if the workspace git is fine.

## What handoffs are NOT

- **Not a transcript.** A transcript is high-token, low-value-per-token; the next agent doesn't need to relive the conversation.
- **Not a TIMING_LOG.** TIMING_LOGs are arc-close retrospectives (estimate vs actual; lessons). Handoffs are session-close snapshots (where we are; what's next).
- **Not exhaustive.** The principles above explicitly trade thoroughness for crispness. A handoff that tries to capture everything fails the value-per-token test.
- **Not a substitute for memories.** Memories carry user-alignment + standing disciplines. Handoffs carry work-state. Both are needed; neither replaces the other.

## How this interacts with other substrate layers (the four-layer identity model)

| Layer | Persistence | Role | Cross-ref |
|---|---|---|---|
| Role file | Permanent, loaded every session | Universal identity (what kind of agent you are) | `substrate/MAJOR_*.md`, `substrate/CAPTAIN_*.md` |
| Memories | Permanent, accumulated by interaction | User-alignment (how to serve THIS specific PRINCIPAL) | `~/.claude/CLAUDE.md` (user-tier) + project `.claude/CLAUDE.md` (project-tier) |
| **Handoff (this skill)** | Periodic, manually authored | Work-state continuity (where we are mid-engagement) | `HANDOFF_<role>_<date>.md` at workspace root |
| bw substrate | Durable across sessions | Detail (full ticket bodies, arc history, verdict trails) | `beadwork` orphan branch via `bw show <id>` |

The four layers together let an agent be **semi-persistent**: identity continues across compactions and sessions, even though the working memory resets each time. The handoff is the bridge — without it, the successor session has the role file (universal identity) + memories (PRINCIPAL-alignment) + bw substrate (full project history) but no orientation on WHAT IS IN FLIGHT RIGHT NOW. The handoff supplies that orientation in 200-500 tokens; the successor then drills into bw on demand for detail.

Full canon: `operating-disciplines.md` §30 (NEW Arc 37 — Four-layer identity model).

## Worked examples

The examples below are SHORT illustrations of the principles, not production-grade handoffs. They show the discipline (highest-value-first, indirection, citing memories by path, etc.); a real handoff for a multi-week engagement may be 2-3x longer with more cross-refs.

### Example 1 — POLYBIUS session-end handoff (cross-session continuity)

Context: user-tier POLYBIUS approaching context limit after a multi-day substrate-canonification engagement; authoring handoff so a fresh session tomorrow can resume.

```markdown
# HANDOFF — user-tier POLYBIUS — 2026-05-18

## In flight (read first)

- **Arc 37 (substrate canonification batch, 6 candidates).** PR open at github.com/<user>/the-stoa/pull/N; SHIP verdict from PLINY pending PRINCIPAL ratification. Next session: confirm PRINCIPAL ratification, then merge + close source tickets per A18. See `stoa--7e3` ticket comments for arc-close coordination.
- **Cross-project context.** Railway_stoa Phase 2 deploy unblocked by Arc 35 trailer landing; ariadne-core search backlog at `ariadne--92x` waiting on this session's next-arc directive.

## Just closed

- Arc 36 v2 (coordination hygiene) shipped 2026-05-17 (PR #16); SKILL_NAMES verified post-deploy at all three target modes.
- Pre-branch hygiene verified clean before arc-37/build creation; full state recorded in `stoa--7e3` comments.

## Open decisions for next session

1. Arc 38 directive authoring — `stoa--bj5` is queued per the Pass 4 workplan; needs scope-locking conversation with PRINCIPAL before dispatch.
2. Routine substrate-update check at consumer workspaces — last check 2026-05-15; cadence allows next check tomorrow.

## Load-bearing context (cite, don't duplicate)

- **Forge/shop framing canon at `MAJOR_POLYBIUS.md` §19** — Arc 37 just shipped this; routing decisions now have explicit canon.
- **Four-layer identity model at `operating-disciplines.md` §30** — Arc 37 shipped; the handoff layer is the one this doc IS.
- Memory: `feedback_no_deferrals_stance.md` — PRINCIPAL's 2026-05-17 fix-now declaration; applies to all bug-triage going forward.

## Non-obvious state

- The arc-37/build worktree is cleaned up; local + remote branch deleted. Verified per §5.10 signoff-accuracy.
- `cron 8299ee0f` (the autonomous-mode polling cron) was torn down at arc close per §11 Teardown.

## Generational lineage

Prior session id: `7c5fdafd-29f4-4484-874a-11ece115de16` (synthetic UUID-shape; real session ids are obtainable via the prior session's `claude --session` invocation or terminal title). Successor: decide whether `claude --resume 7c5fdafd-29f4-4484-874a-11ece115de16` is the right entry path (continuity benefit) vs fresh session + activation paste (clean state benefit). For this engagement, fresh session likely preferred — Arc 37 ship is a clean boundary.
```

### Example 2 — PLINY mid-arc handoff (compaction during long arc)

Context: PLINY mid-Arc 38, approaching context limit during Phase 3 verify; authoring handoff so a /compact'd session can resume the same arc without losing phase-state.

```markdown
# HANDOFF — PLINY-the-stoa — 2026-05-20 (mid-Arc 38, Phase 3)

## In flight (read first)

- **Arc 38 (stoa--bj5 substrate-tool reorg).** Worktree at `.claude/worktrees/arc-38-build/`; branch `arc-38/build`. Phase 3 verify in progress: VERA dispatched 23 min ago on bw-poll watch; CATO dispatched 8 min ago; ZENO not yet dispatched (waiting for VERA verdict). See `stoa--bj5.7` for active coordination.

## Just closed

- Phase 2 build (ADA) PASSED 67 min ago; commit `4f8a2d1` on arc-38/build carries all locked content per `agents/design/arc-38/design.md`.

## Open decisions for next session

1. VERA verdict (any moment) — if PASS, dispatch ZENO; if PARTIAL/FAIL, surface to user-tier POLYBIUS per surface-and-wait.
2. CATO verdict (likely within 15 min) — same disposition logic.

## Load-bearing context (cite, don't duplicate)

- Directive at `substrate/arcs/arc-38-build-directive.md`; A1-A14 LOCKED.
- Design at `agents/design/arc-38/design.md` — committed in arc-38/build at `e7c1f9a`; ARGUS round 1 PASS at `stoa--bj5.5`.

## Non-obvious state

- ADA's commit carries the Co-Authored-By trailer per §28 (verified post-commit).
- Pre-branch hygiene PASSED before arc-38/build creation (logged `stoa--bj5.2`).
- bw-poll cron 9c3d8f1a fires every 5 min; do NOT delete until Phase 4 close.

## Generational lineage

Prior session id: `<session-id>`. Successor: `claude --resume <session-id>` recommended — mid-arc /compact recovery benefits from in-context state continuity; no clean boundary for fresh-session reset until Phase 4 close.
```

### Example 3 — Specialist preservation handoff (CAPTAIN-level continuity)

Context: a CAPTAIN holding accumulated context from a complex multi-engagement (rare; typically CAPTAINs are one-shot per dispatch — but for specialized seats like a pair-programmer Major engaged on a long debugging session, the pattern applies).

```markdown
# HANDOFF — pair-programmer MAJOR_ATHENA — 2026-05-19 (sector-4 debugging session)

## In flight (read first)

- **Investigating intermittent timeout at sector-4 `/api/v1/search`.** Two reproducible failure modes isolated: (1) cold-start cache miss > 3s, (2) concurrent-write contention on the search index during ingest. Root cause for (1) settled (cache warm-up missing on Railway deploy); (2) still investigating — instrumentation patch deployed 30 min ago, awaiting next failure to confirm hypothesis.

## Just closed

- Failure mode (1) fix queued — `s4--7m3` filed for a Railway-deploy startup-hook addition.
- Initial confused theory ("upstream rate limit") ruled out by `feedback_correlation_not_causation.md`-shaped investigation.

## Open decisions for next session

1. Wait for next failure-mode (2) event; collect new instrumentation trace; confirm/refute concurrent-write hypothesis.
2. If confirmed: file fix ticket; if refuted: re-scope investigation.

## Load-bearing context (cite, don't duplicate)

- Sector-4 architecture overview at `s4--arch-overview` ticket.
- Memory: `feedback_railway_cold_start_patterns.md` — Railway's cold-start behavior on free tier (which sector-4 is on).
- Instrumentation patch commit `b9f4e22` on `debug/timeout-investigation` branch (NOT merged; debugging-only).

## Non-obvious state

- The `debug/timeout-investigation` branch is local-only; do NOT push (carries diagnostic-only code).
- PRINCIPAL is HITL on this engagement — surface findings, do not autonomously ship fixes.

## Generational lineage

Prior session id: `<session-id>`. Successor: `claude --resume <session-id>` recommended for short-window resumption (debugging context dense); fresh session if more than ~48h has passed (cache-warmth-context decays).
```

## Cross-references

- `operating-disciplines.md` §30 (NEW Arc 37 — Four-layer identity model) — the handoff layer's canon home; this skill is the operational shape of §30.3's handoff layer.
- `MAJOR_CHIRON.md` §7 (the agent-author capability) — agent authoring lives in the CHIRON seat; handoffs are an output of an agent, not the agent itself.
- `substrate/skills/tier2-project-onboarding/` — sibling skill for new-project orientation.
- `MAJOR_POLYBIUS.md` §16 (POLYBIUS session lifecycle) — the lifecycle disciplines this skill operates within.
- `MAJOR_POLYBIUS.md` §16.3 (Handoff is multi-artifact, not single-doc) — the canon home for principle 5's "cite, don't duplicate" wording; this skill's principle 5 reuses §16.3's exact phrasing because the discipline is identical. The handoff doc this skill authors is the INDEX (low-token overview); bw tickets + retro docs + design artifacts + commits are the linked durable artifacts §16.3 names.
- `MAJOR_PLINY.md` §6.2 (Surface-and-wait polling pattern) — PLINY's polling pattern interacts with handoff authoring during long arcs.
- `~/.claude/CLAUDE.md` + project `.claude/CLAUDE.md` — the memory layer this skill cross-references via principle 5 ("cite, don't duplicate").
- `HANDOFF_*.md` files at workspace root — the canonical output location.
- the-stoa `SPECIFICATION.md` §10.1 + §12.5 — generational-lineage architecture the suggested-procedure step 6 implements.
- Empirical anchor: existing `HANDOFF_POLYBIUS_2026-05-14.md` + `HANDOFF_POLYBIUS_2026-05-16.md` at the-stoa workspace root — informal handoffs that pre-date this skill; the skill formalizes the pattern.
