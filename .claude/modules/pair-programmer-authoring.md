# Pair-programmer Major authoring — instruction module

> Relocated from `MAJOR_POLYBIUS.md` §11 (debloat Arc 2), re-homed to `MAJOR_CHIRON.md` §11 (Arc 61).
> CONDITIONAL — loaded at dispatch when authoring a pair-programmer Major. Now CHIRON-owned (the
> authoring tool moved POLYBIUS→CHIRON; POLYBIUS keeps review literacy). Provenance: composition-layer
> spec `bw show stoa--xyb.4`; debloat Arc 2 cut `agents/design/arc-45/design-rev2.md` + epic
> `bw show stoa--xyb`; re-home charter `bw show stoa--p41`. The slim-core residue is now the §11 host
> stub in `MAJOR_CHIRON.md` + the pointer at `MAJOR_POLYBIUS.md` §11 / §3.5.

Beyond the two universal MAJOR roles per tier (POLYBIUS + PLINY), the architecture supports **pair-programmer Majors authored on demand** — specialized seats POLYBIUS spawns for substantive domain work that calls for a MAJOR-rank specialist sitting alongside the PRINCIPAL. Pair-programmer Majors are not structural (no fixed roster, no per-tier slot); they are dynamic additions you author when a task's shape calls for one and the PRINCIPAL agrees.

This section is the procedure. The decision to author a pair-programmer is upstream of the procedure — see §11.1 for trigger recognition, then §11.2 for the walk-through. The methodology that pair-programmer Majors fit into (the Mode 2 / Mode 1 prototyping-then-hardening cycle) is captured in `MAJOR_POLYBIUS.md` §12 (→ `pair-programming-prototyping.md`).

## §11.1 Trigger recognition

You recognize a pair-programmer-Major signal when **two or more** of these are present:

- **Substantive domain work.** The task is not gauntlet-shaped (Mode 1 — design → critic → build → verify → review → spec-check) and not ad-hoc-shaped (a one-off CAPTAIN dispatch from your seat). It is a chunk of *work* — Python code, regulatory analysis, design exploration, a draft set of agents, a UI prototype — where the PRINCIPAL benefits from a MAJOR-rank specialist focused on this task class.
- **MAJOR-rank specialization fits.** The task's vocabulary, conventions, and quality bar warrant a specialist (Python engineering style, editorial voice, regulatory analysis posture, code-at-large design fluency). Spinning up a pair-programmer for a five-minute chore is overkill; spinning one up for a multi-session domain push is right.
- **The PRINCIPAL benefits from direct dialog with the specialist.** This is the structural reason a pair-programmer is a MAJOR (PRINCIPAL-facing) rather than a CAPTAIN (sub-agent dispatched from PLINY). The PRINCIPAL pairs with the new agent in a fresh Claude Code session — direct dialog, fast iteration.
- **Not a one-shot.** Pair-programmer Majors are reusable across sessions and (often) across projects. A truly one-shot need is better served by an `Agent` tool dispatch from your seat, not by a new role file.

If the signal fires, surface it to the PRINCIPAL — this is exactly the kind of project-direction call PRINCIPALs are the right seat for (`MAJOR_POLYBIUS.md` §4.1).

## §11.2 Walk-through procedure

Smaller than §5 (onboarding) and §10 (sub-project spawn) — substrate is already deployed, bw is already initialized, the PRINCIPAL is already in the loop.

```
1. Discuss the task with the PRINCIPAL. Confirm the trigger signals from
   §11.1. Settle the new agent's name (mnemonic) and the task scope
   together.

2. Pick the template basis. For a new pair-programmer Major: a previously
   authored pair-programmer (e.g., the deployed ~/.claude/agents/PYTHAGORAS.md
   or ATTICUS.md if one exists), or MAJOR_POLYBIUS.md as the structural
   fallback when no pair-programmer exists yet. CHIRON's agent-author
   capability (MAJOR_CHIRON.md §7, "Template-basis selection") carries the
   full table.

3. Route the authoring to MAJOR_CHIRON, whose agent-author capability
   (MAJOR_CHIRON.md §7) drafts the role file. Inputs:
   agent_type=pair_programmer_major, name, mnemonic, descriptive_role,
   specialization, responsibilities, non_responsibilities, template_basis,
   dest_path. CHIRON drafts the role file with the v2 voice-discipline check
   applied and writes it to dest_path on disk.

4. Review the draft in the working tree. Read the §1 framing for fit, read
   the §2 / §3 responsibility lists for accuracy, run the voice-check grep
   one more time as a sanity pass. Edit in place where needed. The
   working-tree-vs-committed boundary IS the review gate (no separate
   drafts/ directory).

5. Commit the new role file. Substrate-canonical pair-programmers (rare —
   ATTICUS, PYTHAGORAS, etc. are project-authored, not substrate-canonical
   — see Arc 17's out-of-scope list) commit to the substrate repo;
   project-authored pair-programmers commit to the project's git repo at
   .claude/agents/<MNEMONIC>.md.

6. Write the paste-instruction for activating the new pair-programmer in a
   fresh session. Use the durable-substrate-with-short-prompts pattern
   (§4.5): write the substantive instruction to
   HUMAN_paste-<mnemonic>-instruction.md on disk; hand the PRINCIPAL a
   one-line paste pointing at it. Pair-programmer activation prompts are
   simpler than MAJOR_PLINY's because there is no gauntlet to dispatch —
   the new MAJOR pairs directly with the PRINCIPAL.

7. Hand the PRINCIPAL the activation one-liner. The PRINCIPAL opens a new
   terminal in the project directory, runs `claude`, pastes the one-liner.
   The new session reads the on-disk artifact and activates as the
   pair-programmer Major.
```

If the new pair-programmer needs the formal gauntlet to harden its output later, that is the §12 Mode 2 → Mode 1 handoff — author a directive for MAJOR_PLINY at that point, not at pair-programmer activation.

## §11.3 Empirical lineage

Pair-programmer Majors POLYBIUS has authored across projects (illustrative, not a fixed roster):

- **ATTICUS** — meta-team editorial pair-programmer in agent-gauntlet (voice + prose review for substrate writing, role files, case studies).
- **PYTHAGORAS** — Python engineering pair-programmer (code at scope, idiomatic Python, scientific-computing fluency).
- **CODEX** — code-at-large pair-programmer (TypeScript, polyglot codebase work).
- **LEX** — regulation analysis pair-programmer (legal text, compliance posture, regulatory diff reading).

These are project-authored, not substrate-canonical — Arc 17 shipped the *capability* (this section + the agent-author skill, now CHIRON §7 after Arc 61) without committing specific instances to the substrate canon. New pair-programmers join the lineage as PRINCIPALs+POLYBIUSes spawn them; the substrate stays small.

## §11.4 Asymmetric beadwork visibility

Pair-programmer Majors are scoped to the task they were authored for. The default visibility is narrow:

- **Pair-programmer reads task-scoped bw.** It can see tickets directly relevant to the task (the activation paste-instruction names them; the pair-programmer reads them as part of activation context).
- **Pair-programmer does NOT see broader project bw by default.** Cross-task, cross-project, and user-tier bw is out of scope unless the PRINCIPAL or POLYBIUS explicitly grants visibility for a specific reason.

The asymmetry is the same shape as the user/project-tier asymmetry (`MAJOR_POLYBIUS.md` §7.1) and the parent/sub-project asymmetry (§10.3), applied to task-scope. It keeps pair-programmers focused on their task without polluting their context with cross-task work.

When a pair-programmer needs cross-task context, the PRINCIPAL or POLYBIUS provides it (paste a ticket body, summarize a related arc, name the relevant tickets in the activation prompt). Granting broader bw visibility is a pair-programmer-by-pair-programmer call, not a default.
