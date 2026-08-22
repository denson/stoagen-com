---
name: attribution-advisory
description: |
  Report-only, NEVER-BLOCKING attribution advisory. Scans a unified diff and surfaces attribution changes into a durable report at `.claude/attribution-advisory-report.md` — it NEVER denies, blocks, or fails a commit. Its PRIMARY check flags a diff hunk that MODIFIES or DELETES an existing author/copyright/license/attribution line (the plagiarism / license-breach direction — another author's credit erased or replaced). Its SECONDARY best-effort check flags a NEW non-PRINCIPAL author-like field in a non-vendored path, using the `.claude/hooks/principal-identity` allow-list (fail-open when absent). Replaces the retired authorship deny-gate (Arc stoa--p0e).

  Invoke when reviewing a diff / staged changes / a branch range for attribution integrity before a commit or merge — e.g. "check this diff for attribution problems", "did any license or copyright line change", "run the attribution advisory". Operator- or gauntlet-seat-invoked. Requires bash + python3 (the wrapper is a bash script — `#!/usr/bin/env bash` with `set -o pipefail`; the scanner is python3).
author: Denson Smith
---

# attribution-advisory — report-only attribution scanner (Arc stoa--p0e)

> **This is a REPORT, not a gate.** `advise.sh` writes a report and exits zero. It
> is a skill, never registered as a hook, and by construction it cannot deny,
> block, or fail any commit. It replaced the retired authorship deny-gate
> (`pretooluse-author-field-audit.sh` — see
> `substrate/v1-historical/hooks/RETIREMENT.md`). The retired gate only checked
> direction-1 (an agent naming a non-PRINCIPAL in its OWN new artifact); this
> advisory's PRIMARY check covers direction-2, the plagiarism / license-breach
> direction the deny-gate never checked.

## The tool: `advise.sh` (ships in this skill dir)

```
bash .claude/skills/attribution-advisory/advise.sh                     # scan `git diff --cached` (staged)
bash .claude/skills/attribution-advisory/advise.sh --range <BASE>..<HEAD>
bash .claude/skills/attribution-advisory/advise.sh --diff-file <path.diff>
git diff <range> | bash .claude/skills/attribution-advisory/advise.sh --stdin
```

Flags:
- `--report-out <path>` — report destination (default
  `<workspace>/.claude/attribution-advisory-report.md`, overwritten per run).
- `--principal-identity <path>` — allow-list override for the SECONDARY check
  (default `<workspace>/.claude/hooks/principal-identity`; also settable via
  `STOA_PRINCIPAL_IDENTITY_FILE`, used by the test runner for a hermetic list).

## Output

- **stdout:** a one-line summary —
  `attribution-advisory: N finding(s) — see .claude/attribution-advisory-report.md`
  (or `... 0 findings (clean) ...`).
- **report file:** `<workspace>/.claude/attribution-advisory-report.md`, the durable
  artifact the operator / user-tier reads. Each finding states, inline, WHY it fired
  and WHAT to check (per the substrate authoring rule, hooks README §2).

## What it flags

- **PRIMARY (name-agnostic):** any REMOVED (`-`) diff line matching an attribution
  pattern — an `author`/`authors`/`owner`/`creator`/`created_by`/`maintainer`/
  `maintainers`/`by`/`copyright`/`holder`/`vendor`/`publisher`/`license`/`licensed`/
  `attribution` field assignment, a separator-less `Copyright <year> <Name>` form,
  an `@author`/`@copyright` tag, or an `SPDX-License-Identifier`. Name-agnostic on
  purpose: changing a line that already carried a name is rarely legitimate, so the
  false-positive rate is naturally low. Because it is name-agnostic it WILL fire on
  a legitimate copyright-year bump, a license reformat, or a PRINCIPAL self-name
  correction — that is EXPECTED under report-only; the report's "WHAT TO CHECK" line
  names these legitimate cases. PRIMARY does NOT consult the allow-list.
- **SECONDARY (best-effort courtesy):** a NEW (`+`) author-like field assignment
  whose value is NOT on the `.claude/hooks/principal-identity` allow-list, in a
  path that is not vendored/imported (`node_modules/`, `vendor/`, `third_party/`,
  `dist/`, `build/`, `.venv/`, `site-packages/`, `v1-historical/`, …). **FAIL-OPEN:**
  if the allow-list is absent or empty, SECONDARY is skipped entirely (PRIMARY still
  runs). SECONDARY is an unratified convenience, not a threat-ratified mitigation.

## The never-blocks contract (structural)

- `advise.sh` is a **skill**, never registered in any `settings-hooks.json` — it is
  never on a PreToolUse path.
- It **always terminates with a zero status**: no reachable non-zero termination
  path, and it emits no permission-decision output. Even if a future operator
  mis-registered it as a hook, a zero-status script emitting no permission-decision
  JSON is treated as ALLOW — it cannot block by construction.
- It **FAIL-OPENs** on every error (no python3, unreadable diff, no git): it degrades
  to an empty/clean report and a zero exit, never an error that blocks the operator.

## Limits (best-effort, accepted)

- Line-anchored: a multi-line/wrapped attribution edit, or an attribution smuggled
  past the field-anchored regex, can be missed (false-negative). Report-only +
  `CLAUDE.md` doctrine stays PRIMARY → acceptable (nothing-has-to-be-100%).
- The classic plagiarism vector — copying external OSS into a NEW file with the
  upstream header STRIPPED — produces no removed attribution line and no added
  non-PRINCIPAL field, so both checks stay silent (a structural false-negative
  inherent to diff-scoping).

## Self-check corpus

`tests/run-attribution-advisory-tests.sh` runs the REAL `advise.sh` against the
`tests/fixtures/*.diff` corpus (P1 flag / P2 clean / never-denies / SECONDARY /
vendored-exclusion / negative controls). Run:

```bash
bash .claude/skills/attribution-advisory/tests/run-attribution-advisory-tests.sh
```
