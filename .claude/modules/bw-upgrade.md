# bw-upgrade discipline — instruction module

> Relocated from `operating-disciplines.md` §22 (CONDITIONAL — read when a new bw release is
> tagged upstream and POLYBIUS handles the upgrade across deployment / substrate / workspace
> surfaces). Provenance: composition-layer spec `bw show stoa--xyb.4`; debloat Arc 47 cut
> `agents/design/arc-47/design-rev2.md` + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.8`.
> The slim-core residue is the §22 stub (names §22.2 in prose for substrate citers) +
> relocation-index row in `operating-disciplines.md` §0.5. The §22.3 N=1 provenance compresses to
> `Anchor: stoa--s6n` (recover via `bw show`).

bw is upstream-tagged. Future bw releases will land features that touch the substrate at deployment, substrate, or workspace surfaces. The discipline below names the 5-step process for handling each release plus the 3-axis impact-classification frame that informs filing.

### 22.1 The 5-step process

1. **Trigger.** A new bw release is tagged upstream. Detection is either manual (operator visits the releases page) or via `substrate/skills/check-bw-release/check.sh` (see §22.4 below) run directly on-demand, fired by the SessionStart substrate-check hook, or via operator-scheduled cron. The trigger step is INFORMATIONAL — what fires next is POLYBIUS judgment.

2. **Review.** Read the upstream changelog. Classify each feature by impact axis (see §22.2). Surface anything load-bearing to PRINCIPAL for project-direction before filing.

   - **Verify changelog claims empirically before locking adoption decisions.** Changelog prose is the upstream's intent; CLI behavior on the install in question is the operational reality. The two can diverge — silently. Run the relevant primitives against the local install BEFORE writing directive A-decisions that LOCK the adoption shape. The verify-then-execute discipline (`MAJOR_POLYBIUS.md` §4.3) is the universal framing; this sub-bullet is the bw-upgrade-specific cut.

     **Worked example (canonical, N=1 anchor for this discipline):** `stoa--s6n` 2026-05-17. The bw 0.13.0 changelog described a "host-local repository registry; auto-registers repos after successful commands." Arc 28's directive A2 B.1 LOCKED `bw registry list` as the replacement for `substrate/consumer-workspaces.txt`. PLINY ran a verify-then-execute probe before dispatching DAEDALUS: on this Windows install, `bw registry list` returned empty regardless of `registry.auto=true`, fresh `bw init`, every invocation path. The "silent on failure" branch was firing (confirmed against `gh pr view 125 -R jallum/beadwork`). The locked premise was empirically contradicted; user-tier POLYBIUS adjudicated descope at 02:59:14Z. The arc shipped (descoped) intact rather than building against an unusable primitive. Cross-ref: `stoa--s6n` radio-check thread (02:00:03Z + 02:03:15Z + 02:59:14Z + 03:00:04Z).

3. **File tickets.** One ticket per impact axis with a concrete action. "Track bw 0.13.0" is the `MAJOR_POLYBIUS.md` §4.8 anti-pattern; a ticket without a concrete next step is a handwave. If an axis has no concrete action (e.g., the feature is not relevant to any of our deployment / substrate / workspace surfaces), name that explicitly in the review note rather than filing a placeholder.

4. **Dispatch.** Standard arcs per workspace. Deployment-side arcs typically ship at the affected service (Railway-deployed Ariadne, etc.); substrate-side arcs ship at the-stoa via the standard gauntlet; workspace-side arcs ship at each affected workspace.

5. **Verification.** Existing substrate consumers still work; subprocess call-sites in any code (`bw_ingest.py`-class) verified under the new version. The substrate's own `check-substrate-updates` tool catches drift at the substrate-deployment layer; per-workspace test suites cover subprocess-call-site regressions. The bw-upgrade is COMPLETE when all three axes have either filed-and-shipped tickets OR explicit "no action needed for this axis" review notes (per Step 3).

### 22.2 The 3-axis impact classification

Every bw release feature falls into one (or more) of three axes:

| Axis | Question | Anchor example (0.12.3 → 0.13.0) |
|---|---|---|
| **Deployment-side** | Does this require a container / service Dockerfile bump, `install.sh` re-run, or SHA256 update at any deployed environment? | `ariadne--c71` — Railway container Dockerfile bumped from bw 0.12.3 to 0.13.0; BW_SHA256 updated; six gates green including `/api/bw` subprocess paths. |
| **Substrate-side** | Does this obsolete substrate canon (skill, role-file convention, doc section), enable a new substrate pattern, or warrant a new substrate-canon section? | `stoa--s6n` (this arc) — B.3 + B.4 land as forward-only available primitives in `MAJOR_POLYBIUS.md` §16.8; B.1 + B.2 were attempted, descoped after empirical probe (see Step 2 sub-bullet). C.1 (this section) and C.2 (the check-bw-release tool) generalize the experience. |
| **Workspace-side** | Does this risk subprocess-call-site regression in any code that shells out to bw (`bw_ingest.py`-class), break workspace-tier conventions, or change exit-code semantics in a way that affects existing scripts? | `ariadne--c71` 22:33:53Z gates 3-6 — verified the bw subprocess paths in ariadne's `/api/bw` endpoints still parse JSON correctly and return 200s. No regression detected; if any had been, a workspace-side ticket would have been filed. |

A feature MAY touch multiple axes (registry would have touched substrate + workspace — substrate via `check.sh` source-side change; workspace via the per-workspace registration semantics). When it does, file one ticket per axis touched.

### 22.3 N=1 provenance + accretion path

Anchor: `stoa--s6n` — N=1 provenance + accretion path. Per §6.7.1 honest-scope: PRINCIPAL declared this discipline 2026-05-17 (project-direction authority, captured at `stoa--s6n` thread). The discipline enters substrate canon off-gate on PRINCIPAL's project-direction authority, with future-evidence-accretion against the §6.7.1 gate still required for promotion to "structural lesson" status. Supporting evidence: `ariadne--c71` (CLOSED 2026-05-16; deployment-side worked example), `stoa--s6n` (substrate-side worked example incl. the registry descope), `ariadne--c71` 22:33:53Z gates 3-6 (workspace-side adjacent evidence). Future bw releases accrete supporting evidence per §6.7.1. Recover via `bw show stoa--s6n` / `bw show ariadne--c71`.

### 22.4 Operationalizing Step 1 — the check-bw-release tool

`substrate/skills/check-bw-release/check.sh` operationalizes Step 1 (Trigger). As of Arc 63 this is a substrate-shipped operator tool, not a Skill-tool skill (its SKILL.md was removed) — run `check.sh` directly, or let the SessionStart substrate-check hook fire it at session start. On-demand or operator-scheduled cron: queries the bw GitHub releases API for the current latest tag, compares to a per-workspace baseline stored at `.bw-release-last-check` (two levels above the script — `substrate/` at substrate-tier, `<workspace>/.claude/` at consumer-tier), and surfaces a "new release detected" message with the 3-axis classification template (per §22.2) and a suggested next action ("file tickets per impact axis") when the tags differ. When tags match, prints a short "current" message.

The tool exists; the operator decides whether to cron it (no cron defaults per directive A7). Classification + filing is POLYBIUS judgment (Steps 2-5); the tool does not autonomously file tickets.

### 22.5 Cross-references

- `MAJOR_POLYBIUS.md` §4.3 (verify-then-execute) — the universal framing the Step 2 sub-bullet specializes for bw upgrades.
- `MAJOR_POLYBIUS.md` §4.8 (fix-now) — the discipline against filing placeholder tickets in Step 3.
- `operating-disciplines.md` §6.7.1 (the N=1 canon-promotion gate this section enters off-gate on PRINCIPAL declaration).
- `operating-disciplines.md` §12 (bw cookbook) — for full bw command syntax used in Step 5 verification.
- `operating-disciplines.md` §13 (Windows Python environment) — relevant when check-bw-release's Python JSON-parse is invoked at user-tier on Windows.
- `MAJOR_POLYBIUS.md` §16.8 (bw 0.13.0 available primitives) — the substrate-side adoption decision the 5-step process produced for the 0.12.3 → 0.13.0 release.
- `substrate/skills/check-bw-release/check.sh` — Step 1 operationalization (run directly or via the SessionStart substrate-check hook; no longer a Skill-tool skill as of Arc 63).
