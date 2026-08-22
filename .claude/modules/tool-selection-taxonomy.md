# Tool-selection taxonomy — instruction module

> CONDITIONAL module (CHANNEL 2). Read when an orchestrator is routing a piece of work
> across the team's repertoire — deciding HOW the work is structured (subagents / skills /
> agent-teams / dynamic-workflow / classic gauntlet / Mode-2 pairing), not just WHO does it.
> The always-loaded pointer that names POLYBIUS as the seat applying this is
> `MAJOR_POLYBIUS.md` §19.3.1. This is calibrated routing GUIDANCE, not a decision tree
> (cf. §19.3 "names the framing, not a decision tree") and not battle-proven canon — it is
> promoted from N=1 evidence and accretes per `operating-disciplines.md` §6.7.1.

## The third routing axis

The orchestrator routes work along three axes: WHO does it (which seat), WHERE human
attention is required (the scarce-resource gate), and HOW it is structured (which
orchestration primitive). The primitives are a control-vs-flexibility spectrum of one idea,
not rivals: subagents and skills (turn-by-turn, the orchestrator holds the plan), agent-teams
(long-running peers coordinating via a shared task list — bw), dynamic-workflows (the plan
moved into a script: repeatable + context-cheap, at the cost of mid-run flexibility), the
classic gauntlet (the substrate's control living in PLINY's judgment), and Mode-2 pairing
(continuous human direction). Routing HOW is the tool-selection call this module supports.

## When to use what (the calibration)

Grounded in observed cost from three prototype runs (N=1 — treat the token figures as
illustrative, calibrate per workspace; do not promote them as guarantees):

| Tool | Cost (N=1 observed) | Use for | Don't use for |
|---|---|---|---|
| Deterministic gate (in-script) | ~0 tokens | reducible disciplines: authorship fields, voice grep, pre-branch git, cron | anything needing judgment |
| Checker agent (focused) | ~34k tokens / check | the judgment edge a regex cannot reach (prose / meta attribution) | bulk reducible checks (use the gate) |
| Cheap review workflow (2 agents) | ~54k / ~1 min | grouping / sanity, decomposition checks | correctness-critical verification |
| Full gauntlet-workflow (>=3 seats) | ~200k / ~7 min | correctness-critical design / build | trivial changes |
| Classic PLINY gauntlet (no workflow) | per-arc | HITL-mid-pipeline + cross-session arcs | parallel fan-out (it cannot) |
| Mode-2 pairing (no workflow) | conversational | unknown shape ("the shape is not yet known") | known-shape execution |

The economic shape (N=1): deterministic gates are the free workhorse; agent-checkers are the
~34k specialist; the workflow-gauntlet trades roughly 4x the tokens for a deeper catch — spend
it where correctness matters. These ratios are the session's single data point, not a settled
cost model.

## Task-type taxonomy — coding AND non-coding

Work is organized by task SHAPE, not by domain: a code migration and a document-corpus
restructure run through identical machinery because orchestration is about shape, not content.
This is why the substrate is a direction-scarce-work machine, not merely a coding tool — and
why non-coding work often benefits more, since its generation is even cheaper and its
bottleneck even more purely direction.

| # | Task shape | Mode / workflow shape | Where human attention goes (the gate) | Coding example | Non-coding example |
|---|---|---|---|---|---|
| 1 | Single-target build (known shape) | Mode 1 gauntlet as a linear stage-workflow (A -> HARD STOP -> B) | approve the design at the HARD STOP; ship / no-ship | implement a feature; fix a bug | write a specific doc; produce a named analysis |
| 2 | Fan-out audit (many items, same check) | parallel / pipeline fan-out -> synthesize -> completeness-critic | read the synthesized findings; decide what to act on | audit every endpoint for auth; find all deprecated-API uses | check every doc section for a claim; authorship-audit every marketplace entry |
| 3 | Migration at scale (many items, transform each) | pipeline + worktree isolation -> verify each -> synthesize | approve the transform on a sample before unleashing all | rename a symbol across 500 files; codemod an API | re-template every doc; re-tag a ticket corpus |
| 4 | Exploration (unknown shape) | Mode-2 pairing — NOT a workflow | continuous: the human IS the direction | spike an approach; prototype a design | draft positioning; sketch a structure |
| 5 | Decision among options | judge-panel: parallel N options -> parallel judges -> synthesize | the decision itself (the run prepares + scores; the human chooses) | pick an architecture among 3; choose a library | pick a strategy; choose a direction |
| 6 | Review of existing work | dimensions in parallel -> adversarially verify each -> review-surface | read the review-surface; adjudicate disputed findings | review a PR / diff; security-review | fact-check a report; audit a plan |
| 7 | Research / synthesis | multi-modal sweep -> fetch -> cross-check / vote -> synthesize | frame the question; read the cited report | research an API's current behavior; find known-bug fixes | literature synthesis; a cited briefing |
| 8 | Discipline-enforcement | gate / checker embedded as a pass-condition in any of the above | none, when it passes — that is the point | authorship / voice / security-pattern gate | authorship / attribution gate on docs; citation-validity gate |

Reading the table: rows 1-3 are GENERATION shapes (build / audit / migrate); rows 5-7 are
JUDGMENT-SUPPORT shapes (decide / review / research); row 4 is the ANTI-WORKFLOW — never
fan-out to FIND direction (unknown shape goes to Mode-2 pairing, not a scripted fan-out);
row 8 is the cross-cutting enforcement layer that rides INSIDE the others. In every row the
"where human attention goes" column is the load-bearing design choice — that column names the
scarce resource being spent, and it is the reason a shape maps to a primitive.

Two domain notes:
- Coding leans on rows 1-3 + 6 + 8; the gauntlet's correctness checkers (VERA / ZENO) earn
  their keep because generation is abundant but not reliably correct.
- Non-coding leans on rows 5-7 + 8, and the discipline-enforcement layer is disproportionately
  valuable: authorship / attribution, citation validity, and voice / brand consistency are the
  recurring failure modes of abundant prose generation, and most are deterministically gateable
  (free).

## Honesty / accretion

This taxonomy and its cost figures enter canon on PRINCIPAL direction (the `stoa--3c9`
promotion act) off a single working session's evidence — three prototype runs
(`wf_01ba8f65-6dc` review, `wf_0c5fa492-e9e` gauntlet-design, `wf_ee8c98f8-04d`
discipline-gate). It is calibrated guidance the team refines, not a rigid decision tree and
not a settled cost model. Promotion to "structural lesson" status still requires the
`operating-disciplines.md` §6.7.1 accretion bar (multiple observations across distinct task
shapes; controlled comparison; substrate-level pattern). Until then, the orchestrator treats
this as the default framing to reason FROM, surfacing to the human when a task does not fit a
named shape rather than forcing a fit.

## Cross-references

- `MAJOR_POLYBIUS.md` §19.3.1 — the always-loaded pointer that names POLYBIUS as the
  tool-selector seat applying this taxonomy (the routing-rule home).
- `operating-disciplines.md` §6.7.1 — the N=1 accretion gate this promotion is honest about.
- `operating-disciplines.md` §33 + `.claude/modules/README.md` — the composition layer that
  makes this a CONDITIONAL disk module.
- `substrate/skills/workflow-composer/SKILL.md` — the HOW-TO-MAKE + HOW-TO-RUN layer that sits
  inside the row-1/2/3/6 workflow shapes; this module is the WHEN-TO-RECOMMEND layer above it.
- Provenance: `docs/sessions/2026-05-30-stoa-workflows-integration-strategy.md` §2 + §3 (the
  N=1 strategy proposal this promotes); `stoa--3c9` (the promotion arc).
