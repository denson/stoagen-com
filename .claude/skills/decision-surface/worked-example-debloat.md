---
title: "Worked example — the substrate debloat decision surface"
demonstrates: "How the decision-surface skill is supposed to work end-to-end: frame a decision as PROBLEM vs DILEMMA, ground every call in the real source before proposing, surface honest proposed→grounded revisions, illuminate (don't fake a recommendation on) the genuine value-tradeoffs, and render it as an interactive surface the human works."
skills: ["decision-surface", "interactive-html-preview"]
author: Denson Smith
date: 2026-06-04
status: canonical worked example (real run, not a mock)
---

# Worked example — the substrate debloat decision surface

> This is a **real run**, captured verbatim from the 2026-06-04 session, not an illustration written after the fact. It is the founding worked example for the `decision-surface` skill (still to be formalized) and the headline anchor for `interactive-html-preview` (its Part-2 rendering layer). Read it to learn *how the skill behaves*, then reproduce the moves.

## 1. The decision

**Task:** the substrate's `operating-disciplines.md` had grown to 37 top-level disciplines / ~1675 lines. The PRINCIPAL named this "the most important upgrade" — debloat it by sorting every discipline into one of four dispositions:

- **ENCODE** — a mechanical *process* → make a workflow / hook / cron *run* it, then delete the prose.
- **CONSOLIDATE** — irreducible judgment/value → keep as prose but trim/merge.
- **KEEP** — load-bearing / architectural / just-shipped / already-tight → leave it.
- **CUT** — redundant / stale / niche → relocate or remove from universal canon.

## 2. The first move: problem vs dilemma (the skill's core distinction)

Before touching anything, split the decision:

- **Most of it is a PROBLEM** — "what is the right disposition for §N?" has a findable answer. For a problem the skill's job is *cognitive offload*: go find the answer and bring it back.
- **A few rows are genuine DILEMMAs** — value-tradeoffs with no right answer (e.g. §1: *merge the five anti-pattern stances into one tight section, or keep them as five emphatic separate ones?* — that trades length against rhetorical force, a value-call). For a dilemma the skill's job is *agency support*: illuminate the tradeoff, state your lean, and **refuse to fake a recommendation** — the human owns the value-call.

The surface marks the dilemma rows with ⚠ and, on those rows only, the recommendation explicitly declines to decide for the human. This is principle-level: **never launder a value-call as an analytical answer.** (Corporate-delusion failure mode: pretending a dilemma is a problem so someone can be "right.")

## 3. Principle #1 in action — talk is cheap, clarify before you write

The skill's first principle: *when in doubt, ask/clarify before writing.* Applied here: before fanning out 34 write-ups, two worked rows (§7 ENCODE, §34 CONSOLIDATE) were drafted by hand as the **gold standard** and shown to the PRINCIPAL to confirm the depth/format. Only after that confirmation did the batch run. Cheap clarification up front; no 34-way rework.

## 4. The load-bearing lesson: GROUND before you propose

The first-draft dispositions were proposed **from memory** (a quick categorization of all 37). That is the trap. The skill's discipline is the opposite:

> **Do not propose from memory. Make each call read the real source first.**

Mechanically: a fan-out **workflow** (`Workflow` tool) spawned **one agent per discipline**. Each agent's mandatory STEP 1 was to `Read` the actual §-text from disk (`docs/_debloat-sections/<n>.md`) *before* drafting its `why` + `recommendation`, and to return a `revisedDisposition` if the real text changed the call. 34 agents, ~104s, all `readOk:true`.

**The result is the whole point:** grounding revised **11 of 34 dispositions**, almost all in one direction —

| disposition | proposed (from memory) | grounded (read the text) |
|---|---|---|
| encode | 10 | **4** |
| consolidate | 14 | 13 |
| keep | 11 | **19** |
| cut | 2 | 1 |

The from-memory pass was **systematically too aggressive**. Reading the text surfaced what memory couldn't see: a prior arc (Arc 47) had *already* debloated ~8 sections into slim stubs pointing at conditional modules — so "encode/consolidate" was proposing work already done, and several "encode" targets (§0.5 a lookup table, §12 a syntax reference) were category errors (not processes at all). **The revision IS the value the surface delivered.** A from-memory surface would have confidently pointed at the wrong work.

This is the `verify-don't-assume` discipline made operational: *a description (or a memory) tells you what something is for; only reading the real thing tells you what it is.*

## 5. Surface honest revisions — don't hide that the first pass was wrong

Every revised row renders the transition transparently, e.g. §21:

> **`GROUNDED: CONSOLIDATE  ↻ was proposed: cut`**

…with the agent's reasoning in the recommendation panel. The grouping, filtering, and the footer mix all compute on the **grounded** disposition, not the original guess. The skill does not quietly overwrite its first answer — it shows the correction, because *where grounding moved the call* is itself decision-relevant signal for the human.

## 6. The rendering layer (interactive-html-preview, Part-2)

The decision logic is the substance; the interactive surface is the view. Mechanics (verified, see the `interactive-html-preview` skill):

- **Self-contained HTML** (`docs/debloat-decision-surface.html`) — opens in any browser (consumer-tier fallback) *and* renders in Preview.
- **markdown=truth / HTML=view** — the 37 write-ups live in a generated data file (`docs/writeups.js`, `window.WRITEUPS`), regenerated from the workflow output by `docs/_gen_writeups.py`; the full §-texts in `docs/disciplines-text.js`. The HTML is the rich view over agent-readable data.
- **Per-row affordances** — grounded disposition badge (+ revision trail), ⚠ dilemma flag, three collapsible panels (`why we have it` / `recommendation` / `full §-text`), and a `localStorage`-persisted "your call" dropdown so the surface is a *working tool* across reloads.
- **Build → serve → render → verify loop** — served via `.claude/launch.json` (`python -m http.server`), then verified in Preview by querying the live DOM (`.card` count = 37, 0 pending write-ups, 11 revision badges, 0 console errors) — **not** assumed from the screenshot.

## 7. Dogfood angle — this run also tested the debloat thesis on itself

The debloat initiative's thesis is "encode process into running structure so prose can be deleted." This run *was* an instance of that: the 34 write-ups were authored by a **workflow** (process → structure), and the run answered two open capability questions empirically:

1. **Custom-workflow agents CAN read local files** (all 34 `readOk:true`) — unlike `deep-research` (web-only). This unblocks reverse-porting the adversarial-verify pattern to read the repo + `bw`.
2. **Workflow `args` arrives as a JSON *string*, not an array** — the first launch failed on `args.map`; a one-line `JSON.parse` guard fixed it. Now a known gotcha, not a surprise.

Both banked in `docs/capability-registry.md` under the verify-then-record methodology.

## 8. Artifacts produced (paths)

| Artifact | Path | Role |
|---|---|---|
| The surface | `docs/debloat-decision-surface.html` | self-contained interactive decision surface + final documentation artifact |
| Write-up data | `docs/writeups.js` | `window.WRITEUPS` — 34 workflow-authored + 3 hand-authored; markdown=truth source |
| §-text data | `docs/disciplines-text.js` | `window.DISCIPLINE_TEXTS` — full section texts for the expand panels |
| Generator | `docs/_gen_writeups.py` | rebuilds `writeups.js` from the workflow output (run with `PYTHONUTF8=1`) |
| Workflow script | `…/workflows/scripts/debloat-writeups-wf_e91fcffe-5a0.js` | the fan-out: one grounded agent per discipline |
| Capability findings | `docs/capability-registry.md` | workflow-can-read-local + args-is-a-string |

## 9. The reusable method (what a future decision-surface run does)

1. **Frame the decision** and split rows into PROBLEM (find the answer) vs DILEMMA (illuminate, don't decide).
2. **Clarify format/depth cheaply** — hand-author 1–2 gold-standard rows, confirm with the human, *then* scale.
3. **Ground before proposing** — fan out a workflow; each agent reads the real source first and may return a `revisedDisposition`. Never let the surface ship from-memory calls.
4. **Compute and display on the grounded answer**, and **show the proposed→grounded revisions** — the correction is signal, not embarrassment.
5. **On dilemma rows, refuse to fake a recommendation** — present the tradeoff and your lean; the value-call is the human's.
6. **Render as a working tool** (interactive-html-preview): self-contained, markdown=truth/HTML=view, persisted human input, verified in Preview against the live DOM.
7. **Hand it to the human to work**, then act on *their* calls — the surface decides nothing; it illuminates so they can.

## 10. Honest notes

- The from-memory first pass was wrong on ~30% of rows. That is not a failure of the method — it is *why the method exists*. A decision surface that proposes without grounding is worse than no surface, because it is confidently wrong.
- The genuine remaining encode surface turned out to be ~4 sections (§7, §11, §13, §28), and even those are *partial* (encode the mechanism, keep the judgment). The 37-card grid overstated the work; grounding right-sized it.
- This worked example will seed the `decision-surface` SKILL.md when that skill is formalized (gauntlet-shipped). Until then it is the canonical reference for the behavior.
