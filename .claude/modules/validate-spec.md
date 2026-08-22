# validate-spec — mechanical-check pass for SPECIFICATION.md (instruction/when-to-use wrapper)

> Read by POLYBIUS when asked to "validate the spec / run the mechanical checks". Provenance:
> Arc 64 / `stoa--p41.2` Workstream B. This module REPLACES the `validate-spec` *skill's* SKILL.md
> (removed from the model-invokable skill menu / `SKILL_NAMES`); the executable script
> `substrate/skills/validate-spec/check.sh` (+ `_check_runner.py` + `_lib`) STAYS callable as a
> retained operator tool (deployed via the `install.sh` carve-out, exempted from the prune scan).
> This is an instruction wrapper over the retained script, NOT a script-drop.
> Anchor: `stoa--p41.2`.

## When to invoke

Invoke `validate-spec` when:

- The PRINCIPAL asks to validate the spec / "run the mechanical checks" / "are we still meeting spec".
- A substrate canon edit has landed and you want to confirm none of the 7 mechanical invariants broke.
- Pre-stellation (Pass 10) sanity sweep — confirm spec-met BEFORE behavioral validation.
- After a multi-arc autonomous engagement closes — confirm the team's bookkeeping is intact.

Do **not** invoke for:

- Behavioral-correctness validation (that is Pass 10 stellation; this is mechanical only).
- Spec-meaning validation (does the spec say the right things?) — that is PRINCIPAL judgment.
- Auto-fixing drift (the script is read-only; remediation routes through `check-substrate-updates apply.sh` for substrate drift, through POLYBIUS for spec / bw-ticket / git-state drift).

## How to invoke (the retained script)

```bash
bash .claude/skills/validate-spec/check.sh
```

(At the-stoa substrate tier the source path is `substrate/skills/validate-spec/check.sh`; at a consumer workspace the deployed path is `.claude/skills/validate-spec/check.sh`.) Default: runs against `SPECIFICATION.md` at the repo root; writes the artifact to `agents/observation/spec-validation/mechanical-check-results.md`. Optional flags `--spec <alternate-spec-path>` and `--write-artifact <alternate-artifact-path>`. The script prints a per-check verdict line per check (`check-N: PASS|FAIL|STRANGE — <one-line evidence>`) and writes a structured artifact with per-item tables + verbatim evidence trail. **Exit code is always 0 on successful execution per A20** (drift is informational; the artifact carries the verdict). Exit 2 is reserved for "could not run" (python or git missing).

The 7 mechanical checks: §-reference resolution, cited `stoa--<id>` ticket existence + status, open-ticket §13.x placement, `git status` clean modulo §12.4 ignorables, `_drafts/` empty-or-justified, `check-substrate-updates` no-drift (A21 LOOSE pre-ratification for ariadne / sector-4 / railway_stoa per `stoa--3na`), and §28 Co-Authored-By trailers on post-Arc-35 squash-merges (with the explicit `bb12806` carve-out). Full per-check criteria live in the script + `SPECIFICATION.md` §13.11.

## Strangeness-triage routing (operating-disciplines.md §27 step 3)

When the artifact carries `STRANGE`-verdict items or non-empty `PRINCIPAL-gate findings`, POLYBIUS routes per `operating-disciplines.md` §27.2 step 3 (the mechanical-script / agent-inspection split — script runs, inspection-agent reads strangeness, POLYBIUS triages):

- **Routine technical-tier findings → POLYBIUS fixes inline** (e.g., a §-reference anchor the resolver did not normalize — update the resolver, re-run, check returns PASS; a fix-now per `MAJOR_POLYBIUS.md` §4.8).
- First-run strangeness is GOOD signal (the team is authoring its own falsification criteria); do NOT auto-PASS items POLYBIUS cannot independently verify.

## A21 PRINCIPAL-gate escalation (operating-disciplines.md §25.3 BLOCK-not-TAG)

Three pre-flagged gates PAUSE the workflow and escalate to user-tier-polybius (per `operating-disciplines.md` §25 + A21):

1. **check-6 strict-vs-loose divergence.** Any workspace OUTSIDE the A21 LOOSE pre-named list (ariadne / sector-4 / railway_stoa per `stoa--3na`) emits a non-`CURRENT` composite. Surface `[for: user-tier-polybius]` + cite the artifact's check-6 table. Do NOT auto-resolve; the PRINCIPAL chooses interpretation.
2. **check-7 post-Arc-40 trailer-canon failure.** Any commit reachable from `dbb5b81` ancestry that emits empty Co-Authored-By trailers — a canon gap, NOT a typo. Surface `[for: user-tier-polybius]` + cite the failing commit SHA + the `MAJOR_PLINY.md` §5.10 canon site that should have prevented it. Substance disagreement; do NOT fix-and-ship.
3. **Any mechanical check genuinely FAILS** (not STRANGE; FAIL). Surface with the failing evidence; the PRINCIPAL ratifies fix-now-this-arc vs document-as-residue-and-ship vs spec-edit-and-re-run.

POLYBIUS makes the routing call; the script emits the structured artifact; the PRINCIPAL is the exception-handler when a gate fires.

## Cross-references

- `substrate/skills/validate-spec/check.sh` — the retained executable (this module wraps it).
- `operating-disciplines.md` §27 (mechanical-script / agent-inspection split) + §25 (PRINCIPAL-gate, A21 routing partner) + §28 (Co-Authored-By trailer canon, check-7 verifies against).
- `mechanical-inspection-split.md` — the §27 pattern-canon module.
- `SPECIFICATION.md` §13.11 (Pass 9 spec) + §13.13 (spec-met criteria) + §13.16 (definition of done).
