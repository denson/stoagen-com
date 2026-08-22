---
name: workflow-composer
description: |
  Compose a Stoa-aware Claude Code dynamic workflow — a JavaScript orchestration script the workflow runtime executes — that takes advantage of the substrate instead of re-deriving orchestration from scratch. This skill is the Stoa DELTA on top of the Workflow tool's own description: it ASSUMES that description for all generic mechanics and adds ONLY the substrate-specific layer. Anthropic ships the Workflow tool (whose embedded spec is the authoritative manual for the primitives, the meta skeleton, the pipeline-vs-parallel choice, the caps, and the quality-pattern catalog) plus the /deep-research example — but no composition guidance for our substrate, and no knowledge of it. The tool does NOT know the role-specialized CAPTAIN seats in the Agent registry, the gauntlet pipeline, the PASS/FAIL verdict format, the HITL/outer-loop check, or the forge/shop deployment model. This skill supplies exactly that mapping and nothing the tool already teaches: reuse CAPTAINs via agentType, structure verdicts via schema, gate human attention at stage boundaries (the runtime forbids mid-run input), emit a review-surface for the outer-loop check, return the verdict for the launching seat to land (the script cannot run bw/git), and deploy via the .claude/workflows (base/forge) vs ~/.claude/workflows (user-tier) split.

  POLYBIUS or PLINY invokes this when composing a workflow in a Stoa workspace. Triggers on requests like "compose a workflow", "write a Stoa workflow", "port this gauntlet arc to a workflow", "build a /gauntlet workflow", "fan out an audit across the codebase", "build an outer-loop review workflow", or any phrasing that maps to "author a dynamic-workflow script that uses our seats and disciplines."
author: Denson Smith
---

# workflow-composer — compose Stoa-aware dynamic workflows

> **Scope — read first.** This skill is the *delta*, not a tutorial. The `Workflow` tool's own description (loaded into context whenever the tool is available) is the authoritative manual for generic composition — the `meta` skeleton, every primitive signature (`agent`/`pipeline`/`parallel`/`phase`/`log`/`budget`/`workflow`), the `DEFAULT TO pipeline()` guidance and barrier smell-test, the concurrency/total caps, the quality-pattern catalog, and worked code examples. **Do not restate or re-derive any of that here.** This skill carries only what the tool cannot know: the Stoa substrate mapping below.

## Why this skill exists

Anthropic ships the **Workflow tool** (whose embedded spec teaches the runtime and its primitives; see also https://code.claude.com/docs/en/workflows) and one bundled example workflow, `/deep-research`. The model composes the script directly when it invokes the tool — there is no Anthropic-provided "composer" skill, and the tool knows its own primitives but does **not** know the Stoa substrate. This skill is that missing substrate layer.

This skill is the supplement. A workflow composed cold re-derives orchestration the substrate already settled and throws away our seats. A workflow composed *with this skill* does five Stoa-specific things the generic composer would miss:

1. **Reuses our CAPTAIN seats** as workflow agents via `agentType` (the runtime resolves them from the same registry the Agent tool uses), so the role files, disciplines, and tool-restrictions carry over — ARGUS still cannot `Write`; VERA still falsifies.
2. **Gates human attention at stage boundaries**, because the runtime forbids mid-run input — which turns out to be exactly our pre-build HARD-STOP gate, not a workaround.
3. **Emits a review-surface** so the outer-loop check (user-tier POLYBIUS) is fed, not starved, by the context economy that makes workflows attractive.
4. **Returns the verdict for the launching seat to land** (bw write + commit + push), because the script itself cannot run `bw` or `git`.
5. **Deploys via forge/shop**, mapping the runtime's two save locations onto our base/custom split.

The point is to keep the gauntlet's *methodology* (role specialization, redundant independent verification, the disciplines) while moving its *orchestration plumbing* onto a faster, context-cheap, deterministic substrate — for the arcs whose shape fits. It does not replace the classic PLINY-run gauntlet; see "What this skill is NOT."

## Where workflows sit among the four orchestration primitives

The Claude Code docs name **four** ways to run multi-step work, distinguished by *who holds the plan* (subagents, skills, **agent teams**, workflows — see https://code.claude.com/docs/en/workflows "When to use a workflow"). The Stoa gauntlet is not a fifth primitive; it is **a controlled composition of two existing ones**:

| Layer of the gauntlet | Generic primitive it matches | The "control" the substrate adds |
|---|---|---|
| Tier coordination (POLYBIUS ↔ floor-manager ↔ PLINY) | **agent teams** — a lead supervising long-running peer sessions, coordinating through a shared task list (for us, **bw**); teammates keep running through interruption | canonized chain-of-command, three-tier independence, surface/escalation disciplines |
| CAPTAIN execution (PLINY → DAEDALUS/ARGUS/…) | **subagents** — turn-by-turn dispatch, results land in context | canonized pipeline order, role-file disciplines, HARD STOP gates, verdict formats |

So the gauntlet is **agent-teams-for-coordination + subagents-for-execution, wrapped in the substrate's control.** A **workflow** is that same gauntlet with the control moved *into a script* instead of living in PLINY's judgment — repeatable and context-cheap, at the cost of mid-run flexibility. The four primitives are therefore a **control-vs-flexibility spectrum of one idea**, not rivals: pick the point on the spectrum that fits the task (the *when-to-recommend* judgment; the task-shape taxonomy is the when-to-recommend layer, now canon at `.claude/modules/tool-selection-taxonomy.md` (cf. `MAJOR_POLYBIUS.md` §19.3.1)).

## When to use this skill

Invoke when:

- POLYBIUS or PLINY has decided to express an arc, audit, or review as a dynamic workflow rather than a turn-by-turn PLINY dispatch.
- The work is **fan-out-shaped** (codebase-wide audit, multi-workspace canon application, a review run on every branch) — the runtime's strength and a capability the serial gauntlet lacks.
- The work is a **gauntlet pipeline whose intermediate results don't need a human between every step** — context economy + determinism are the win.
- An **outer-loop amplifier** is wanted — a "cold-audit this from N independent angles" workflow user-tier POLYBIUS launches as part of its check.

Do **not** invoke for:

- Arcs that need **human judgment mid-pipeline** (not just at stage boundaries) — those stay with the classic gauntlet under PLINY (MAJOR_PLINY.md §5). The runtime cannot pause for input.
- **Mode-2 exploration** ("we don't yet know what we want") — that is pair-programming (MAJOR_POLYBIUS.md §12), not a scripted fan-out.
- **Cross-session** work that must survive a Claude Code exit — workflow resume is same-session only; bw remains the durable cross-session layer.
- A **single-agent task** — that is an `Agent` dispatch, not a workflow.

## The runtime constraints that shape every Stoa workflow

The four runtime constraints are defined in the `Workflow` tool description — this skill does not redefine them. The **right column is the delta**: what each constraint *means for a Stoa workflow*. Read the left column as a pointer, the right as the content:

| Runtime constraint | Stoa consequence |
|---|---|
| **No mid-run user input** ("for sign-off between stages, run each stage as its own workflow") | HITL gates = **stage = workflow boundaries**. The natural seam is the pre-build HARD-STOP (ksge P4): Workflow A produces a design + audit → human/outer-loop reviews → Workflow B builds + verifies. Put no human-judgment step *inside* a stage. |
| **No filesystem/shell from the script itself** (agents read/write/run; the script only coordinates) | The script cannot run `bw` or `git`. So **the workflow returns the structured verdict; the launching seat lands it** (bw comment/close + commit + push). Keeps the ship decision in a judgment seat per MAJOR_POLYBIUS.md §4.6, not buried in a script-spawned agent. Pure data transforms (combining results into a review-surface) are fine in the script — they're variable manipulation, not side effects. |
| **≤16 concurrent agents** | Bounds fan-out throughput; a 100-item audit runs in waves of ~16. Irrelevant to the ~7-seat serial gauntlet. |
| **1,000 agents total per run** | Runaway backstop. If a designed sweep could exceed it, chunk it and `log()` what was deferred — never silently truncate. |

## The core mappings (the heart of the skill)

### Gauntlet → stage-workflows

The classic pipeline decomposes at its existing HITL seams:

- **Workflow A — design** (`STRABO → DAEDALUS → ARGUS`): a `pipeline()` ending in a design + cold audit. → **HARD STOP** for the design-review gate.
- **Workflow B — build** (`ADA → VERA → CATO → ZENO`, plus any judgment-tier seat present): a `pipeline()` ending in a built artifact + verdict + review-surface. → outer-loop review gate before ship.

This is not a workaround for "no mid-run input"; it *is* the pre-build gate ksge proved earns its cost (`stoa--7b1.7` / P4).

### CAPTAIN reuse via `agentType`

Pass `agentType` to `agent()` to run a real Stoa seat instead of the default workflow subagent:

```js
await agent(prompt, { agentType: 'CAPTAIN_ARGUS_the_stoa', schema: VERDICT })
```

The runtime resolves `agentType` from the same registry the Agent tool uses, so the seat's role file (and its tool-restrictions) apply. **Use the names as they appear in this workspace's Agent registry** — at a project-tier deployment they carry the `_<workspace-slug>` suffix (e.g. `CAPTAIN_CATO_the_stoa`); the unsuffixed base names also resolve. Confirm the available seats before composing; do not hardcode a seat (e.g. a judgment-tier seat) that is not deployed in the target workspace.

### Verdict → `schema`

Our PASS / PARTIAL / FAIL verdict format becomes a JSON Schema passed as `schema`. The runtime validates and forces a retry on mismatch, so the agent returns a typed object — no parsing, no fragile file-writing (this sidesteps the `save-verdict` Windows file-write bugs at `stoa--wq0` / `stoa--7b1.2` entirely). Minimum shape:

```js
const VERDICT = {
  type: 'object',
  required: ['verdict', 'findings', 'summary'],
  properties: {
    verdict:  { type: 'string', enum: ['PASS', 'PARTIAL', 'FAIL'] },
    summary:  { type: 'string' },
    findings: { type: 'array', items: { type: 'object', required: ['severity','claim','evidence'], properties: {
      severity: { type: 'string', enum: ['BLOCKER','MAJOR','MINOR','NIT'] },
      claim:    { type: 'string' },
      evidence: { type: 'string' },
      suggested_fix: { type: 'string' },
      confidence: { type: 'string', enum: ['high','medium','low'] },
    } } },
  },
};
```

### Review-surface for the outer loop

Context economy (results in script variables, not the launching seat's context) is the workflow's headline benefit — but it can **starve the outer-loop check** (user-tier POLYBIUS) of the raw material it uses to catch what the team missed. So the composer must have the workflow **emit a high-signal review-surface**, not just "PASS". It is the distilled residue the outer loop reads at the stage gate:

- close calls and **low-confidence** verdicts,
- findings the inner loop **filtered out, and why** (deep-research discards failed claims silently; the outer check wants to *see* the discards),
- **divergences** between independent verifiers,
- decisions the pipeline made that it was unsure about.

Build it as a plain data transform in the script (allowed — no side effects) and `return` it. Cheap to read, high catch-rate.

### Ship-discipline: workflow produces, launcher lands

Because the script cannot run `bw`/`git`, the workflow `return`s its verdict + review-surface to the launching seat. PLINY (or POLYBIUS) then writes the verdict to bw and — only on clean PASS within the autonomous-ship envelope (MAJOR_POLYBIUS.md §4.6) — commits and pushes. The human-attention gate stays where canon already puts it.

## Quality patterns to reach for

The pattern catalog itself lives in the `Workflow` tool description — this skill adds only **which substrate discipline each maps onto** (the delta):

- **Perspective-diverse verify** is *free* for us: our CAPTAINs are already differently-roled (ARGUS plan-critic vs CATO diff-reviewer vs VERA falsifier vs ZENO spec-checker). Assign each verifier a real seat rather than N identical skeptics.
- **Adversarial verify** (N skeptics, kill a finding if a majority refute) makes the multi-checker-convergence thesis (`stoa--myd`) *cheap* — run 3–5 independent verifiers where the serial gauntlet runs one.
- **Completeness critic** ("what's missing — modality not run, claim unverified?") is an automated junior of the outer-loop check; use it to tee up the human gate, not replace it.
- **Loop-until-dry** for unknown-size discovery (audits, sweeps) — keep finding until K rounds return nothing new; `log()` the tail.

Scale the pattern to the ask: a quick check is a few finders + single-vote verify; "audit thoroughly" is a larger finder pool + 3–5-vote adversarial pass + synthesis.

## Deployment (forge / shop)

Workflows are saved for reuse via the runtime's own save flow — run `/workflows`, select the run, press `s`, and pick a location in the save dialog (https://code.claude.com/docs/en/workflows#save-the-workflow-for-reuse). There is **no documented mechanism for deploying a workflow as a static source file via `install.sh`**, and as of this writing the substrate has no `install.sh` / `check-substrate-updates` wiring for `.claude/workflows/` at all. So the two save locations map onto our tiers *conceptually*, but the deploy/drift mechanism is the runtime's, not the substrate's:

| Save location | Runtime meaning | Conceptual Stoa layer |
|---|---|---|
| `.claude/workflows/` | project, shared with everyone who clones | **BASE / forge** — the home for a canonical project-shared workflow (e.g. a future `/gauntlet`). Saved via the runtime save dialog; whether `install.sh` should *also* place + drift-check a canonical workflow here is an **open question for a future arc**, not existing infrastructure. |
| `~/.claude/workflows/` | personal, every project, only this PRINCIPAL | **user-tier** — outer-loop amplifiers and personal review workflows, authored directly by the PRINCIPAL; never deployed by `install.sh`. |

Project-over-user precedence on name collision matches base-deployment semantics. A project may author **custom** workflows (the shop layer) for its own domain. (Honesty note: the `install.sh`-deploys-workflows model was an early overclaim in this skill's draft, caught by a gauntlet design-audit run on the skill itself — see `stoa--04n`.)

## Parameterizing a saved workflow with `args`

A saved workflow can take input at invocation: the script reads a global named `args`, and the PRINCIPAL (or a launching seat) invokes it as `Run /<name> on <data>` — the data arrives as structured JSON the script can use directly, no parsing. If `args` is omitted the global is `undefined`.

This is the mechanism that makes a Stoa workflow **reusable per-target instead of hand-authored per-incident.** The worked case is the goal-locked remediation workflow (cross-ref `stoa--h2z`): author a `/defeat-threat` workflow *once* whose single goal is to defeat the named threat passed as `args` — e.g. `Run /defeat-threat on M2` → `args = {threat: "M2", attack_path: "..."}`. The workflow's success criterion is the threat-coverage assertion (an *executed* attack-path probe, not a writable sentence — cross-ref `stoa--yfv.1`), so it cannot pass on a plausible-but-false claim. Same shape serves any per-target sweep (audit one path, triage one issue set) without re-authoring.

## Running a workflow — operational know-how (the *how-to-run* layer)

Composing the script is half the job; the team also owns *how to set up and run* it. The load-bearing operational facts (from the Workflow docs):

- **Pre-allowlist the commands the agents need, BEFORE the run.** Workflow subagents run in `acceptEdits` mode, so *file edits auto-approve* — but **shell commands, web fetches, and MCP tools that are not in the tool allowlist still prompt mid-run.** On an *unattended* run that prompt is an invisible stall (the run looks alive but is blocked on input no one will answer) — this is the exact failure mode of `stoa--x4j`. The fix: add the commands to the allowlist before starting, or run via `claude -p` / the Agent SDK where tool calls follow configured rules with no interactive prompt. **Pre-allowlisting is mandatory for any autonomous/overnight workflow run.**
- **Cost — run a small slice first.** Many agents = meaningfully more tokens than the same task in conversation. Before a large run, run it on one directory / one narrow question; the `/workflows` view shows per-agent token usage live, and you can stop without losing completed work. Route low-stakes stages to a smaller `/model` when the strongest is not needed.
- **Overnight is NOT a workflow.** Workflow resume is *same-session only* — exit Claude Code while a workflow runs and the next session starts it **fresh**. So a dynamic workflow is a *same-session, machine-awake* accelerator, never the unattended-overnight vehicle. For "runs while the PRINCIPAL sleeps," the mechanism is a **remote routine** (claude.ai / `RemoteTrigger`), not a workflow. Do not conflate the two.
- **Enablement.** Dynamic workflows are a research-preview feature requiring a minimum Claude Code version; on Pro they are toggled on in `/config` (Dynamic workflows row). The invocation keyword is **`ultracode`** (or natural language like "use a workflow"); the older literal keyword `workflow` applied before v2.1.160. Verify the feature is enabled in the target environment before relying on it.

## Composition procedure

1. **Place the stage boundaries** by asking *where is human attention required* (the substrate's core thesis). Each boundary is a separate workflow; no human-judgment step lives inside a stage.
2. **Confirm the available seats** in the target workspace's Agent registry; pick the `agentType` per step.
3. **Define the verdict `schema`** (extend the minimum shape above per task).
4. **Author the script** using the tool description's mechanics (the `meta` skeleton, the `pipeline`-vs-`parallel` choice, the caps) — add nothing generic this skill could omit. Stoa note: the gauntlet for a *single* target is a linear sequence of `await agent()` calls (STRABO → DAEDALUS → ARGUS), not a `pipeline()`; reach for `pipeline()`/`parallel()` only when fanning out over *many* targets.
5. **Emit a review-surface** as a data transform and `return` it alongside the verdict.
6. **Do not land in the script** — return the verdict for the launching seat to write to bw / commit.
7. **Test the run** before saving (small real target; read the result; confirm the seats fired and the schema validated).
8. **Save to the right location** only after it does what was wanted — forge (`.claude/workflows/`) for canonical, user-tier (`~/.claude/workflows/`) for personal. Promotion of a substrate-canonical workflow to forge is a **gauntlet-hardening arc** (MAJOR_POLYBIUS.md §18.2), not a direct commit.

## Honesty / N=1

- **Deterministic orchestration ≠ deterministic results.** A saved workflow repeats *which seats run, in what order, against what schema* — the agents inside are still LLM calls. Claim consistent *process*, not consistent *verdicts*.
- **Research-preview feature.** Requires the Claude Code version the docs name; verify it is enabled (`/config`) in the target environment before relying on it.
- **Battle-test before forge-promotion.** A composed workflow is a prototype until a real run proves it; promoting it to substrate canon accretes against `operating-disciplines.md` §6.7.1 like any discipline.

## What this skill is NOT

- **Not a replacement for the gauntlet.** It is an execution substrate for the gauntlet's methodology. The role files, disciplines, and verdict philosophy are the value and are untouched.
- **Not for HITL-mid-pipeline arcs.** Work needing human judgment between steps (not just at stage boundaries) stays with PLINY.
- **Not a committer.** It composes and tests; landing the verdict is the launching seat's job, and forge-promotion is a gauntlet arc.
- **Not /deep-research.** That bundled workflow is a research tool; this skill composes Stoa-specific orchestration.
- **Not a cross-session durability layer.** That is bw. Workflows are intra-session execution.
- **Not the overnight / unattended vehicle.** Workflow resume is same-session-only; close the session and it restarts fresh. Unattended-while-PRINCIPAL-sleeps work is a remote routine (claude.ai), not a workflow.
- **Not the *whole* tool-selection judgment.** This skill makes + runs workflows; *which* primitive (subagents / skills / agent-teams / workflow / classic gauntlet / Mode-2 pairing) fits a given task is the separate when-to-recommend discipline (cross-ref `.claude/modules/tool-selection-taxonomy.md` + `MAJOR_POLYBIUS.md` §19.3.1; ticket `stoa--3c9`).

## Cross-references

- https://code.claude.com/docs/en/workflows — the runtime, constraints, save-for-reuse, and bundled `/deep-research`.
- The `Workflow` tool description (in-session) — the full primitive set (`agent`/`parallel`/`pipeline`/`phase`/`schema`/`isolation`/`budget`/resume) and the pattern catalog this skill maps onto.
- `MAJOR_POLYBIUS.md` §4.6 (autonomous-ship on clean PASS) — where the launcher's land-the-verdict discipline lives.
- `MAJOR_POLYBIUS.md` §12 (Mode 1 gauntlet / Mode 2 pair-programming) — workflows are an execution substrate for Mode 1; Mode 2 is not workflow-shaped.
- `MAJOR_POLYBIUS.md` §17 + §19 (base/custom + forge/shop) — the deployment mapping.
- `MAJOR_PLINY.md` §5 (gauntlet orchestration) — the pipeline this skill ports; §5.8 background-dispatch machinery is what a workflow can shed for fitting arcs.
- `operating-disciplines.md` §6.7.1 (N=1 canon-promotion gate) — the bar a composed workflow clears before forge canon.
- Empirical anchors: `stoa--7b1.7` / ksge P4 (the pre-build HARD-STOP this skill's stage boundary implements); `stoa--myd` (multi-checker convergence the adversarial-verify pattern makes cheap); `stoa--wq0` / `stoa--7b1.2` (the save-verdict file-write bugs that `schema` retires).
- `stoa--x4j` (autonomous gauntlet silently stalls on a permission prompt) — the failure the pre-allowlist operational rule fixes.
- `stoa--h2z` (detect-critical → goal-locked remediation workflow) — the worked use-case for the `args` parameterization.
- `stoa--3c9` (orchestration tool-selection discipline) — the *when-to-recommend* layer this skill's *how-to-make* layer sits inside — now canon at `.claude/modules/tool-selection-taxonomy.md` + `MAJOR_POLYBIUS.md` §19.3.1.
- the 4-primitive comparison + `args` + the allowlist/overnight facts are current as of the 2026-06-01 Workflow docs (`stoa--04n` doc-delta comment).
