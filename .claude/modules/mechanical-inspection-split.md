# Mechanical-script / agent-inspection split — instruction module

> Relocated from `operating-disciplines.md` §27 (CONDITIONAL — read when designing a script-based
> workflow and deciding where intelligence lives across mechanical / recognition / triage layers).
> Provenance: composition-layer spec `bw show stoa--xyb.4`; debloat Arc 47 cut
> `agents/design/arc-47/design-rev2.md` + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.8`.
> The slim-core residue is the §27 stub (names §27.2 in prose for substrate citers) +
> relocation-index row in `operating-disciplines.md` §0.5. The §27.6 N=1 provenance compresses to
> `Anchor: stoa--32b.2, stoa--dxw, stoa--s6n, stoa--ads` (recover via `bw show`).

Mechanical scripts stay narrow; recognition-of-strangeness moves to an LLM-grade inspection-agent run AFTER the mechanical operation; POLYBIUS triages the resulting findings against §25 PRINCIPAL-gate discipline. This section is distinct from §11 (autonomous-mode-setup cadence axis) and §25 (PRINCIPAL-gate authorization axis) — it is an *architecture-axis* discipline naming where intelligence lives across the mechanical / recognition / triage layers of a script-based workflow. Same disambiguation shape §25 carries when crossing the cadence-axis canon at §10 / §11.

### 27.1 The discipline (PRINCIPAL declaration)

PRINCIPAL declared this discipline 2026-05-16 after the Arc 26 ship (`stoa--dxw`) + the `stoa--501` revert sequence surfaced the script-bloat trajectory. The declaration verbatim (from `bw show stoa--32b.2` ticket body):

> *"We are spending way too much time trying to get script workflows perfect when the answer is to run the script, then run an agent with a script to check what happened including anything strange and then let polybius fix any of the strangeness with human approval if necessary."*

This is project-direction authority per §6.7.1 honest-scope framing (see §27.6 for the N=1 accretion path). The load-bearing architectural framing comes from `docs/sessions/2026-05-16-substrate-update-architecture-reframe--retro.md` §8 (PRINCIPAL's prose on where intelligence lives — mechanical scripts vs. recognition-agents) and §9 (synthesis with §7's gate discipline, now shipped as §25).

### 27.2 The 3-step pattern

1. **Mechanical script** runs — `apply.sh` / `install.sh` / deploy workflows / etc. Deterministic, narrow. Stays small over time; does NOT grow recognition logic. Owner: the workspace's `.claude/skills/` deployed scripts; or `substrate/install.sh` at substrate-tier.
2. **Inspection agent** runs a verification script + reads the result + workspace state + surfaces anything strange — including things the script wasn't pre-programmed to enumerate. LLM-grade recognition, not pattern-match. Owner: POLYBIUS-invoked skill (worked example: `substrate/skills/inspect-script-output/`); respects base-vs-custom scoping per §23 / `MAJOR_POLYBIUS.md` §17.
3. **POLYBIUS triage** — routes findings:
   - **Routine technical-tier findings** → POLYBIUS fixes inline per fix-now `MAJOR_POLYBIUS.md` §4.8 + the user-tier-approves-tech-decisions discipline.
   - **PRINCIPAL-gate findings** → workflow PAUSES per §25.3 BLOCK-not-TAG; autonomous mode does NOT relax. Owner: POLYBIUS; PRINCIPAL is exception-handler.

The distinguishing property vs. intelligence-in-script: the script enumerates KNOWN strangeness (the categories it was pre-programmed to detect); the inspection agent finds NOVEL strangeness (the things the script wasn't pre-programmed to notice). Adding a new known-strangeness category to a script grows the script; the inspection-agent layer absorbs novel strangeness without script growth.

### 27.3 When to apply + A7 boundary

**When to apply.** Substrate-update flow (post-`apply.sh` / post-`install.sh`); deploy workflows (when one lands at this team in the future); future script-based workflows where the recognition surface is unbounded or grows. The discipline framing (per Arc 33 directive A4): **when designing a script-based workflow, prefer mechanical-narrow + inspection-agent over make-script-comprehensive.**

**A7 boundary (load-bearing — names what Arc 33 does NOT do):**

- Arc 33 establishes the COMPONENT (the skill at `substrate/skills/inspect-script-output/`) + the worked-example deployment (substrate-update flow, via `--self-test` runtime fixture) + this canon section.
- Arc 33 does NOT mechanically enforce §25 / §19.6 / `MAJOR_PLINY.md` §5.10 / `MAJOR_POLYBIUS.md` §17 — per-discipline integration is INCREMENTAL future-arc work.
- Arc 33 does NOT unwind Arc 26's `check.sh` additions. The script stays as-is; the inspection-agent pattern is the *forward* shape. Future migration of `check.sh` recognition logic into the inspection-agent layer is a separate arc when the pattern proves out.
- Arc 33 does NOT build inspection-agents for every existing script. The worked example is ONE; concrete adoption is incremental.
- Arc 33 does NOT promote the inspection-agent layer to a CAPTAIN seat (Option γ / CAPTAIN_INSPECTOR) — deferred per Arc 33 directive A2 to a future arc when the skill pattern proves out across multiple domains AND gauntlet-pipeline integration is warranted.

### 27.4 Per-seat behavior

| Seat | Role in the 3-step pattern | Cross-ref |
|---|---|---|
| Mechanical-script author (DAEDALUS designing; ADA building) | Design scripts to STAY mechanical-narrow. When a new recognition surface is needed, design the inspection-agent layer, not a script extension. | `CAPTAIN_DAEDALUS.md` §6, `CAPTAIN_ADA.md` (build envelope) |
| Inspection-agent (skill or CAPTAIN) | Read post-mechanical state; surface strangeness; respect §23 / `MAJOR_POLYBIUS.md` §17 scoping. | `inspect-script-output.md` (Arc 64: operational module over the retained `substrate/skills/inspect-script-output/check.sh`; SKILL.md retired) |
| POLYBIUS (triage) | Route routine findings to fix-now; route PRINCIPAL-gate findings to PAUSE per §25.3. | `MAJOR_POLYBIUS.md` §4.8 (fix-now), `operating-disciplines.md` §25 |
| PRINCIPAL | Disposition on gated findings per §25.3; project-direction calls on architectural promotions. | `operating-disciplines.md` §25 |

### 27.5 Worked example

Arc 33 ships `substrate/skills/inspect-script-output/` as the substrate-update-flow worked example. The skill's `--self-test` mode builds a synthetic strangeness tree in a temp dir at runtime; the planted-strangeness case exercises `MAJOR_POLYBIUS.md` §17.4 silent-collision detection (duplicate `name:` field values within one Claude-Code scope). No fixture files are tracked under the skill directory — the test surface lives inside the `check.sh` code (`build_self_test_tree` function) and is exercised via `check.sh --self-test`. See `inspect-script-output.md` (Arc 64: the run-the-inspection-script operational entry; the SKILL.md was retired from the skill menu but `check.sh` stays callable) for the invocation surface; see `agents/design/arc-33/design-rev2.md` for the load-bearing design and the rejected-alternatives rationale.

### 27.6 N=1 provenance + accretion path

Anchor: `stoa--32b.2, stoa--dxw, stoa--s6n, stoa--ads` — N=1 provenance + accretion path. Per §6.7.1 honest-scope: PRINCIPAL declared this discipline 2026-05-16 (project-direction authority, captured at `docs/sessions/2026-05-16-substrate-update-architecture-reframe--retro.md` §8 and at `bw show stoa--32b.2` ticket body). The discipline enters substrate canon off-gate on PRINCIPAL's project-direction authority per §6.7.1, with future-evidence-accretion against the §6.7.1 gate still required for promotion to "structural lesson" status.

Supporting evidence at the time of this writing:

- **N=2 bit-by-it of make-script-comprehensive (negative anchor).** Arc 26 (`stoa--dxw`) extended `substrate/skills/check-substrate-updates/check.sh` from **489 → 893 lines** to add MISSING + OBSOLETE + uncommitted-state detection — the load-bearing script-bloat anchor cited here is the Arc 26 ship specifically. Arc 28 (`stoa--s6n`) added further `check-bw-release/check.sh` logic for the bw-upgrade discipline. The current live line count of `substrate/skills/check-substrate-updates/check.sh` is 934 lines — that count is downstream of Arc 26 (it includes Arc 29's base-vs-custom additions); the cited 489 → 893 anchor is the Arc 26 ship.
- **N=1 small-scope inspection-shape precedent (positive anchor).** `substrate/skills/check-bw-release/` (Arc 28) ships a small inspection-shape skill that is working without script-bloat. Single instance today; Arc 33's worked example accretes the second instance.
- **N=multi cross-discipline coverage (future-arc accretion surface).** §25 + §19.6 + `MAJOR_PLINY.md` §5.10 + `MAJOR_POLYBIUS.md` §17 + `MAJOR_PLINY.md` §5.9.4 all benefit from mechanical-script-then-agent-inspection enforcement at future arcs. Today none are mechanically enforced (per Arc 33 A7); the pattern's future-arc adoption is the accretion path against §6.7.1.

The discipline is in NOW because PRINCIPAL named it; structural-lesson confidence accretes over future arcs that apply the pattern at new domains (deploy workflows, build verification, etc.) AND across the per-discipline mechanical-enforcement integrations the A7 boundary defers. **Do NOT over-generalize beyond what PRINCIPAL named.** The pattern is *prefer mechanical-narrow + inspection-agent over make-script-comprehensive WHEN designing script-based workflows*, NOT *all scripts must have inspection-agents now*. Same N=1 framing as Arc 27's `MAJOR_POLYBIUS.md` §16.6, Arc 28's `operating-disciplines.md` §22.3, Arc 29's `MAJOR_POLYBIUS.md` §17.5, Arc 30's `MAJOR_PLINY.md` §5.9.3, Arc 31's `operating-disciplines.md` §25.6, and Arc 32's `operating-disciplines.md` §19.6 / `MAJOR_PLINY.md` §5.10 / `MAJOR_PLINY.md` §5.9.4.

### 27.7 Cross-references

- `operating-disciplines.md` §10 (operating engagement — cadence axis) + §11 (autonomous-mode-setup checklist) — the cadence-discipline canon this section is *distinct from* (architecture axis, not cadence axis). Same disambiguation shape §25 uses when crossing §10 / §11.
- `operating-disciplines.md` §25 (PRINCIPAL-gate discipline) — the triage-step partner; Step 3 of the 3-step pattern hands gated findings to PRINCIPAL per §25.3 BLOCK-not-TAG. Folding §25 into §27 would conflate gate-axis with architecture-axis disciplines; the two cross-reference each other and stand as separate loci.
- `operating-disciplines.md` §19.6 (attestation-confabulation) — future-integration partner; the inspection-agent layer is the WHERE that COULD verify attestation claims at attestation time. NOT shipped Arc 33 per A7.
- `operating-disciplines.md` §23 (base-vs-custom universal) + `MAJOR_POLYBIUS.md` §17 (POLYBIUS refinement, including §17.4 silent-collision footgun) — the scoping discipline the inspection-agent layer respects + the load-bearing canon for the `scan_name_collisions` helper in the worked example.
- `operating-disciplines.md` §6.7.1 — the N=1 canon-promotion gate this section enters off-gate on PRINCIPAL's 2026-05-16 declaration.
- `MAJOR_PLINY.md` §5.10 (signoff-accuracy) — future-integration partner; the inspection-agent layer COULD verify cleanup claims pre-signoff. NOT shipped Arc 33 per A7.
- `MAJOR_POLYBIUS.md` §4.8 (fix-now) — the routine-finding routing rule for Step 3 of the 3-step pattern.
- `substrate/skills/inspect-script-output/` — Arc 33's worked-example deployment.
- `substrate/skills/check-bw-release/` (Arc 28) — small-scope precedent for inspection-shape skills.
- `substrate/skills/check-substrate-updates/` (Arc 26 + 29) — the script-bloat empirical anchor referenced but NOT modified per A7.
- `stoa--32b.2` (Arc 33 work-unit ticket); `stoa--32b.1` (sibling Arc 31 / §25); `stoa--dxw` (Arc 26 empirical anchor); `stoa--501` (post-hoc cleanup); `stoa--s6n` (Arc 28 / check-bw-release precedent); `stoa--ads` (Arc 29 / base-vs-custom — live 934 count downstream).
- `docs/sessions/2026-05-16-substrate-update-architecture-reframe--retro.md` §8 + §9 — load-bearing source.
