# Per-CAPTAIN seat-identity in the dispatch brief — instruction module

> Relocated from `MAJOR_PLINY.md` §5.12 (CONDITIONAL — read at a worktree-resident CAPTAIN
> dispatch). Provenance: debloat Arc 48 cut `agents/design/arc-48/design-rev1.md` + epic
> `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.10`. The slim-core residue is the §5.12 stub +
> routing-map row (worktree-resident CAPTAIN dispatch) + relocation-index row in §4.2.

When you dispatch a CAPTAIN to a worktree-resident build (typically CAPTAIN_ADA inside `.claude/worktrees/arc-N-build/`, but applicable to any CAPTAIN that direct-commits during the gauntlet — DAEDALUS landing a design.md, a CAPTAIN landing a verdict artifact, etc.), the brief MUST name the exact seat-identity string the CAPTAIN writes into the `Co-Authored-By:` trailer of each commit per `operating-disciplines.md` §28. The brief carries the identity as a structured field; the CAPTAIN writes it verbatim into the commit's HEREDOC body.

**The dispatch-brief field shape:**

```
seat-identity: CAPTAIN_<MNEMONIC>_<project-slug> <captain-<mnemonic>@<project-slug>.local>
```

Worked example for an ADA dispatch in the-stoa project:

```
seat-identity: CAPTAIN_ADA_the-stoa <captain-ada@the-stoa.local>
```

The CAPTAIN's commit message then writes the trailer verbatim:

```
Co-Authored-By: CAPTAIN_ADA_the-stoa <captain-ada@the-stoa.local>
```

PLINY names the project-slug per the project the gauntlet runs in (`the-stoa`, `ariadne-core`, etc. — the project's canonical slug; per-project convention recorded in that project's `CLAUDE.md` or substrate config). The CAPTAIN does NOT infer the slug; PLINY's brief is the source of truth.

**Why the brief carries the identity (not the CAPTAIN inferring it).** Two failure modes the brief-as-source-of-truth closes:

- **Per-project drift.** Without a brief-named identity, each CAPTAIN would have to infer the project-slug from the working directory path, the git remote, or the bw prefix — three different surfaces that may disagree (e.g., the working directory is `the-stoa` but the GitHub remote is `the-stoa.git`; the substrate project-slug convention may differ). Brief-named is unambiguous.
- **Cross-project CAPTAIN dispatches.** A future workflow might dispatch a CAPTAIN to operate against a different project's worktree (e.g., a CAPTAIN_ADA in `ariadne-core-workspace` dispatched from `the-stoa` PLINY). The brief names the seat-identity per the target project, not the dispatching PLINY's project.

**Cross-references:**

- `operating-disciplines.md` §28 — the substrate-canonical home for the trailer convention (the rule, the format, the scope, the squash-merge preservation property, the read-discipline pairing).
- `MAJOR_PLINY.md` §5.2 (ADA brief preamble — grounding-check enumeration) — the brief shape this section extends with the new `seat-identity:` field.
- `CAPTAIN_ADA.md` §5.5 — the per-seat application (CAPTAIN_ADA writes the trailer at commit time per the brief-supplied identity).
- `MAJOR_PLINY.md` §5.10 (signoff-accuracy) — verification that Arc N's own gauntlet commits carry the trailer per the convention being shipped (when an arc self-applies §28).
