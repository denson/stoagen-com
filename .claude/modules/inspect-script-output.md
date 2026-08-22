# inspect-script-output — the inspection-agent layer (step 2 of the §27 split; instruction wrapper)

> Read by POLYBIUS as step 2 of the §27 mechanical-script / agent-inspection split. Provenance:
> Arc 64 / `stoa--p41.2` Workstream B. This module REPLACES the `inspect-script-output` *skill's*
> SKILL.md (removed from the model-invokable skill menu / `SKILL_NAMES`); the executable script
> `substrate/skills/inspect-script-output/check.sh` STAYS callable as a retained operator tool
> (deployed via the `install.sh` carve-out, exempted from the prune scan). Instruction wrapper over
> the retained script, NOT a script-drop. Anchor: `stoa--p41.2`, `stoa--32b.2` (the empirical home).

> Pattern canon: `mechanical-inspection-split.md` §27.2; this module is the run-the-inspection-script operational entry.

## When to use

Invoke when:

- An operator has just run `apply.sh` or `install.sh` against a registered workspace and wants the post-mechanical state inspected before posting any signoff that names a workspace-cleanup claim (`MAJOR_PLINY.md` §5.10 partner).
- A POLYBIUS session is doing a periodic substrate-state check and wants the strangeness surface beyond what `check-substrate-updates/check.sh` pre-enumerates.
- Before kicking off a new substrate-adoption arc, sanity-check that the workspace is in a clean recognizable state (no silent name collisions, no unauthorized commits to `.claude/`, no drift verdicts that mismatch the underlying file state).

Do **not** invoke for:

- Substituting for `substrate/skills/check-substrate-updates/check.sh` (that computes the *known-strangeness* drift verdict; this scans for *novel* strangeness on top of it — run both).
- Auto-fixing anything. This is informational only; the script writes to stdout and exits 0. Triage + fix routing is step 3 (POLYBIUS judgment per `operating-disciplines.md` §27.2 step 3).

## How to invoke (the retained script)

```bash
.claude/skills/inspect-script-output/check.sh --workspace <abs-path>
```

(At the-stoa substrate tier the source path is `substrate/skills/inspect-script-output/check.sh`; at a consumer workspace the deployed path is `.claude/skills/inspect-script-output/check.sh`.) A `--self-test` mode generates a synthetic CLEAN + STRANGE tree in a temp dir at runtime and cleans up before returning (no tracked fixtures). The script emits a structured strangeness report; POLYBIUS triages the findings.

## Triage routing

Strangeness findings route per `operating-disciplines.md` §27.2 step 3 (the same routing the `validate-spec.md` module documents): routine technical-tier findings → POLYBIUS fixes inline; PRINCIPAL-gate findings → escalate to user-tier-polybius per `operating-disciplines.md` §25.3 BLOCK-not-TAG. This module is step 2 (run the inspection script + read strangeness); the pattern canon for the full 3-step split lives in `mechanical-inspection-split.md` §27.

## Cross-references

- `substrate/skills/inspect-script-output/check.sh` — the retained executable (this module wraps it).
- `mechanical-inspection-split.md` §27.2 (3-step pattern canon) + §27.5 (worked-example provenance).
- `operating-disciplines.md` §27 (mechanical-script / agent-inspection split) + §25 (PRINCIPAL-gate).
- `MAJOR_PLINY.md` §5.10 (signoff-accuracy partner).
