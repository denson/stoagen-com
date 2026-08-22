---
author: Denson Smith
---

# Handoff-doc template — POLYBIUS multi-artifact handoff (index)

The template MAJOR_POLYBIUS fills per handoff to produce the index doc for a multi-artifact handoff. The index doc is one component of the handoff (per `substrate/MAJOR_POLYBIUS.md` §16.3); the bw tickets, retro docs, design artifacts, commits, and role files / disciplines are the rest. The index doc CITES the others — it does not restate them.

Architecture authority: `user-beadwork/plans/three-role-recursive-architecture.md` (v2). The discipline lives at `substrate/MAJOR_POLYBIUS.md` §16 (POLYBIUS session lifecycle). The durable-substrate-with-short-prompts pattern (§4.5) is the parent discipline this template extends to handoffs.

---

## When to fill this template

- A POLYBIUS session is about to spin down (Mode 2 new-session trigger per §16.2) and the next POLYBIUS will spin up against the handoff.
- Or: the running session is keeping the handoff doc current as Mode 1 default (handoff + compaction) — re-fill periodically as engagement intent shifts.

The template is for Mode 2 handoffs specifically (full multi-artifact handoff at a session boundary). Mode 1 in-session refreshes are a lighter case — the same template works, but typically only the `{{ONE_PARAGRAPH_STATE}}`, `{{RECOMMENDATION_MENU}}`, and `{{STATE_SHAPES_BEHAVIOR}}` slots get re-filled per refresh.

---

## Substitution slots

| Slot | Meaning | Example |
|---|---|---|
| `{{HANDOFF_DATE}}` | UTC date in `YYYY-MM-DD` form; also used in filename | `2026-05-16` |
| `{{HANDOFF_FOR}}` | the next session this handoff is for (tier + role) | `the next user-tier POLYBIUS session resuming this multi-workspace engagement after compaction or session boundary` |
| `{{AUTHOR_SESSION}}` | description of the authoring session with engagement date | `the user-tier POLYBIUS in this conversation, 2026-05-16 UTC` |
| `{{SUPERSEDES_HANDOFF}}` | path to the prior handoff this one supersedes (optional; omit clause if none) | `HANDOFF_POLYBIUS_2026-05-14.md` |
| `{{LIVE_RELAY_STATUS}}` | whether the authoring session is being kept alive as a relay channel + intent (per Mode 3 of MAJOR_POLYBIUS.md §16.2); explicit "no relay" is also valid | `kept alive by PRINCIPAL as a relay channel during the transition` |
| `{{ONE_PARAGRAPH_STATE}}` | one paragraph summarizing where things stand at handoff time | `The user-tier engagement of 2026-05-15→16 produced four landed deliverables...` |
| `{{RECOMMENDATION_MENU}}` | numbered menu of 3-5 likely next-actions (recommendation, not prescription) | `1. Resume sector-4 game build... 2. Apply Arc-25 drift in consumer workspaces... 3. ...` |
| `{{LOAD_BEARING_CONTEXT}}` | per-topic sections of load-bearing engagement context — typically 1-4 sections per handoff | (free-form sections) |
| `{{BW_REPO_TABLE}}` | markdown table: name + local path + bw prefix + last-arc commit | (table) |
| `{{HITL_PAUSED_QUEUE}}` | enumeration of open HITL-paused-pre-dispatch tickets the next session should surface to PRINCIPAL on first turn; empty is fine (explicit "no open HITL-paused tickets" is better than silence) | `- stoa--jru (Arc 22 coordination hygiene, paused 2026-05-04 awaiting PRINCIPAL adjudication of design-rev2; surface on first turn if PRINCIPAL has bandwidth for Arc 22 disposition).` |
| `{{STATE_SHAPES_BEHAVIOR}}` | bullet list of state facts that shape POLYBIUS behavior in the next session | `- The credential-discipline canon is now load-bearing...` |
| `{{MEMORIES_CITE_DONT_RESTATE}}` | pointers to durable memories the next session should consult rather than re-deriving | `- Provide pastes proactively...` |
| `{{HYGIENE_LOOSE_ENDS}}` | non-blocking loose ends the next session should know about | `- One A3 directive inaccuracy...` |
| `{{HONEST_CAVEATS}}` | caveats about what this handoff does NOT carry | `- Curated, not exhaustive. The conversation transcript carries diagnostic-level detail not captured here...` |

### Per-slot rationale

A future POLYBIUS reading this template should understand *why* each slot is filled the way it is.

- **`{{HANDOFF_DATE}}`** is the disambiguator. The filename convention is `HANDOFF_POLYBIUS_<date>.md`; suffix `_eod` / `_v2` / etc. for multi-handoff days.
- **`{{HANDOFF_FOR}}`** scopes the audience explicitly. A handoff written "for the next user-tier POLYBIUS" reads differently than one written "for project-tier POLYBIUS picking up Arc N." Specificity reduces the reader's first-turn ambiguity.
- **`{{AUTHOR_SESSION}}`** + the engagement date is load-bearing for the live-relay-status case: a reader needs to know which session authored this and when, to know whether to route conversational nuance back through PRINCIPAL.
- **`{{SUPERSEDES_HANDOFF}}`** lets the chain be walkable. Cite-don't-restate: the prior handoff's resolved threads stay in that handoff; this one names the supersession explicitly.
- **`{{LIVE_RELAY_STATUS}}`** is the load-bearing slot for Mode 2 / Mode 3 transitions. Empty is fine when no relay is active; explicit "no relay" is better than silence.
- **`{{ONE_PARAGRAPH_STATE}}`** is the highest-value-per-token slot. A reader who only reads this paragraph should be able to act. Press for specificity; vague paragraphs produce vague next sessions.
- **`{{RECOMMENDATION_MENU}}`** is recommendation-not-prescription per the handoff convention. The next session may choose differently; the menu shows the reasonable next steps.
- **`{{LOAD_BEARING_CONTEXT}}`** is the variable-shape part — what landed in the engagement, what is in-flight, what is open. The morning's `HANDOFF_POLYBIUS_2026-05-16.md` had four sections (credential arc, dev Ariadne deployment, CI workflow, bw repo table). Future handoffs will have different topics.
- **`{{BW_REPO_TABLE}}`** is the navigation aid. A new POLYBIUS picking up cross-workspace state needs to know which bw repos exist and where they live.
- **`{{HITL_PAUSED_QUEUE}}`** captures open work that is paused awaiting PRINCIPAL adjudication. Per `MAJOR_POLYBIUS.md` §9 step 3, the activated session sweeps for HITL-paused indicators at session-start; the handoff doc's HITL-paused-queue section pre-populates that sweep so the next session does not need to re-derive the queue from scratch. Empirical anchor: `stoa--jru` (Arc 22) sat paused-pre-dispatch from 2026-05-04 to 2026-05-17 because no carrier surfaced the open-paused state to fresh POLYBIUS sessions; both the §9 step (fresh-activation carrier) and this template section (handoff carrier) are the defense-in-depth pair Arc 34 / C4 encodes.
- **`{{STATE_SHAPES_BEHAVIOR}}`** captures the "watch out for" items that aren't a single ticket but shape every decision the next session makes (e.g., "credential-discipline canon is now load-bearing").
- **`{{MEMORIES_CITE_DONT_RESTATE}}`** is the cite-don't-duplicate discipline applied to memories. The durable memory layer (`~/.claude/CLAUDE.md`, project `MEMORY.md`, bw tickets) holds the substance; the handoff points.
- **`{{HYGIENE_LOOSE_ENDS}}`** + **`{{HONEST_CAVEATS}}`** keep the handoff honest. Naming what didn't ship and what isn't captured prevents the next session from acting on a false sense of completeness.

---

## Template body

```
# HANDOFF — POLYBIUS — {{HANDOFF_DATE}}

**For:** {{HANDOFF_FOR}}
**Author:** {{AUTHOR_SESSION}}
**Supersedes:** {{SUPERSEDES_HANDOFF}}{{SUPERSEDES_CLAUSE}}
**Authoring discipline:** `substrate/MAJOR_POLYBIUS.md` §16.3 (multi-artifact handoff shape).

---

## Live relay channel status

{{LIVE_RELAY_STATUS}}

---

## Where things stand — one paragraph

{{ONE_PARAGRAPH_STATE}}

## What you'd most likely do next (recommendation, not prescription)

{{RECOMMENDATION_MENU}}

## Load-bearing engagement context

{{LOAD_BEARING_CONTEXT}}

## Where the bw repos live

{{BW_REPO_TABLE}}

## HITL-paused queue

{{HITL_PAUSED_QUEUE}}

## State that shapes POLYBIUS behavior

{{STATE_SHAPES_BEHAVIOR}}

## Memories that shape POLYBIUS — cite, don't duplicate

{{MEMORIES_CITE_DONT_RESTATE}}

## Hygiene loose ends

{{HYGIENE_LOOSE_ENDS}}

## Honest caveats

{{HONEST_CAVEATS}}

End handoff.
```

`{{SUPERSEDES_CLAUSE}}` expands to ` — most of its open threads are now resolved or evolved; cite-don't-restate.` when `{{SUPERSEDES_HANDOFF}}` is named; otherwise both slot and clause expand to empty and the `**Supersedes:**` line is omitted entirely.

---

## Worked example

The canonical example is `HANDOFF_POLYBIUS_2026-05-16.md` at the repo root. Read that file to see the slots filled with real engagement content — credential discipline (Arc 25) as `{{LOAD_BEARING_CONTEXT}}` section 1, dev Ariadne deployment as section 2, CI workflow as section 3, the bw repo table at the bottom of context, and the recommendation menu at the top.

That handoff was authored before this template existed — it is the de-facto template the slotted form is abstracted from. Per Arc 27 directive A8, existing handoff docs are NOT retroactively reformatted to fit this template; the template is forward-only.

---

## Where the filled handoff lives

POLYBIUS writes the filled handoff to `HANDOFF_POLYBIUS_{{HANDOFF_DATE}}.md` at the project / user-tier root (the same level as `CLAUDE.md` for the relevant tier). Suffix `_eod` / `_v2` / etc. for multi-handoff days.

The PRINCIPAL pastes the filled handoff (or its one-line pointer per the durable-substrate-with-short-prompts pattern, `MAJOR_POLYBIUS.md` §4.5) to a fresh POLYBIUS session at the start of the next engagement.

---

## When to refresh the on-disk handoff

Per `MAJOR_POLYBIUS.md` §16.2 Mode 1 (handoff + compaction): keep the handoff current as session intent shifts materially. Concretely:

- After a `/compact` event that left the session re-orienting against a stale handoff.
- After a substantive engagement phase closes (an arc ships, a multi-workspace propagation lands, a thread the recommendation-menu pointed at gets done).
- When new pending directives or bw tickets accumulate that the next session should pick up first.

Refreshing is cheap; running the next session against a stale handoff is not. Same discipline as the paste-instruction refresh discipline (`MAJOR_POLYBIUS.md` §6 + `substrate/templates/paste-instruction-template.md` "When to refresh the on-disk copy").

---

## Why a slotted template rather than re-authoring from scratch each time

The morning's `HANDOFF_POLYBIUS_2026-05-16.md` is the de-facto template; the next handoff under that convention would re-invent the structure each time. The slotted form makes the structure explicit, reviewable, and version-controllable — the same reasons `paste-instruction-template.md` is slotted (per its "Why string substitution" section).

The template stays under `substrate/templates/`; changes appear in diff history. Slot values are visible separately from the template structure; if a handoff is hard to read, the failure point is usually a slot that was filled vaguely (most often `{{ONE_PARAGRAPH_STATE}}` or `{{LOAD_BEARING_CONTEXT}}`), not the structure itself.

If a future workflow surfaces a real need for an LLM-generated handoff (e.g., the slot set stops being expressive enough for some class of engagement), revisit then. Until that signal arrives, this is the answer.
