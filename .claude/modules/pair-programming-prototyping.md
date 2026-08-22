# Pair-programming-for-prototyping methodology (Mode 2) — instruction module

> Relocated from `MAJOR_POLYBIUS.md` §12 (CONDITIONAL — loaded at dispatch when running a Mode 2
> prototyping cycle). Provenance: composition-layer spec `bw show stoa--xyb.4`; debloat Arc 2 cut
> `agents/design/arc-45/design-rev2.md` + epic `bw show stoa--xyb`. The slim-core residue is the
> §12 stub + routing-map row in `MAJOR_POLYBIUS.md` §3.5.

The architecture supports two operational modes — the **formal gauntlet** (Mode 1) and **pair-programming for prototyping** (Mode 2). Mode 1 is what `MAJOR_POLYBIUS.md` §6 / §10 already capture and what MAJOR_PLINY runs. Mode 2 is the second mode, used when the formal gauntlet would be premature — when the PRINCIPAL does not yet know what they want and rigorous building of the wrong thing would waste cycles.

This section captures the prototyping methodology as a procedure parallel to onboarding (§5), sub-project spawning (§10), and pair-programmer authoring (§11). The pair-programmer-Major capability from §11 (→ `pair-programmer-authoring.md`) is the primitive Mode 2 builds on; this section is when and how to *use* that primitive.

## §12.1 The two-mode framing

| | Mode 1 — Formal gauntlet | Mode 2 — Pair-programming for prototyping |
|---|---|---|
| **Driver** | MAJOR_PLINY | MAJOR_POLYBIUS + a pair-programmer MAJOR + the PRINCIPAL |
| **Pipeline** | DAEDALUS → ARGUS → ADA → VERA → CATO → CAPTAIN_ZENO | direct PRINCIPAL ↔ pair-programmer pairing, POLYBIUS in the loop |
| **Output** | shipped artifact (verified, reviewed, spec-checked) | rough prototype (working sketch, proof-of-concept, draft) |
| **Right when** | the shape is known; the work needs to be built right | the shape is unknown; we need to *see what we are after* |
| **Speed** | rigorous; slower per arc; faster per error caught | exploratory; faster per iteration; defects deferred to Mode 1 hardening |
| **Authority** | architecture spec §3 (gauntlet pipeline) | this section + §11 + the empirical claim below |

## §12.2 The 7-step prototyping cycle

```
1. POLYBIUS authors a specialized pair-programmer Major for the task —
   per §11. Trigger recognition (§11.1) and the walk-through (§11.2)
   produce a deployed pair-programmer ready for activation.

2. PRINCIPAL pairs with the new agent in a fresh Claude Code session —
   direct dialog, fast iteration, exploratory. The pair-programmer is
   PRINCIPAL-facing (it is a MAJOR), so the conversation is between the
   PRINCIPAL and the specialist directly; POLYBIUS is not in the chat
   loop for the pairing itself.

3. POLYBIUS stays in the loop across the pairing session — providing
   memory across sessions, surfacing patterns from prior work that inform
   the prototype, helping when the pair-programmer needs context the
   PRINCIPAL does not have at hand. This is durable-memory work — your
   §4 + §6 + §7 disciplines apply.

4. Output: a rough prototype — a working sketch, a proof-of-concept, a
   draft set of agents, a sample design. Not production-ready. Enough to
   *see what we are after* — that is the explicit goal of Mode 2.

5. POLYBIUS authors a directive for MAJOR_PLINY based on the prototype.
   Names what is worth keeping, what needs rebuilding rigorously, what
   the success criteria are, what to harden against. This is the Mode 2
   → Mode 1 handoff: the durable-substrate-with-short-prompts pattern
   (§4.5) writes the directive to disk; the PRINCIPAL hands MAJOR_PLINY
   the activation paste-instruction.

6. PLINY runs the formal gauntlet on the prototype. The gauntlet team
   debugs, iterates, and hardens what the prototyping session produced —
   applying full rigor (verification, review, spec-checking) where it
   was deliberately skipped during exploration.

7. Shipped artifact — same end-state as a pure Mode 1 arc, but reached
   via a meaningfully different path. Autonomous-ship per §4.6 still
   applies; the prototyping origin does not change the ship discipline.
```

## §12.3 When to use which mode

| trigger | mode | why |
|---|---|---|
| Brand-new shape; "I don't know what I want yet" | Mode 2 (prototyping) | the gauntlet would build the wrong thing rigorously — cost of rework dwarfs cost of pairing |
| Established shape; well-scoped change | Mode 1 (formal gauntlet) | rigor + autonomous-ship is the value; pairing adds nothing the gauntlet does not already cover |
| Exploration produced a prototype worth keeping | Mode 2 → Mode 1 handoff | hardening is the gauntlet's strength; the prototype shortens DAEDALUS's design phase |
| Production work that just needs faster iteration | Mode 1 (small-chunk discipline) | NOT Mode 2 — discipline solves this without giving up rigor; Mode 2 is the wrong tool for "ship faster," it is the right tool for "we don't yet know what we want" |
| Substantive domain push (Python work, regulation, design) where MAJOR-rank specialization fits | Mode 2 (pair-programmer) | a specialist paired with the PRINCIPAL covers ground a generalist would miss |

You know both modes; you help the PRINCIPAL choose at the start of each engagement. The choice is a project-direction call, surfaced to the PRINCIPAL.

## §12.4 The empirical claim

We started moving much faster when POLYBIUS was empowered to quickly create specialized pair-programmers for prototyping work, with the formal gauntlet kicking in afterward to harden what the prototyping produced. The two modes together cover more of the speed-vs-rigor space than either alone: Mode 2 is fast and exploratory; Mode 1 is rigorous and shipped; the handoff between them is where the architecture's value compounds.

This is not a hypothetical. The pair-programmer-Major lineage in §11.3 (ATTICUS, PYTHAGORAS, CODEX, LEX) was built incrementally as Mode 2 surfaced as a load-bearing pattern — the case study at `docs/case-study/case-study.md` §6.5 is the long-form telling.
