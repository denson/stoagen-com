# Stoa git hooks — candidate runbook (opt-in, DEFAULT-OFF)

This directory holds **candidate** git hooks the Stoa substrate ships. `install.sh`
deploys them to `<dest>/.claude/githooks-candidate/` as inert candidate scripts.
They are **NEVER auto-installed into any `.git/hooks/`** — a candidate script sitting
in `githooks-candidate/` is not on any hook path and is never fired by git. Arming a
hook is a separate, explicit, per-clone operator step (below).

> Authored by Denson Smith. The `Co-Authored-By:` lines inside `prepare-commit-msg`
> are CAPTAIN **seat-identity metadata** (operating-disciplines.md §28.4) — the
> example trailer values the hook writes — NOT authorship claims for this file.

## `prepare-commit-msg` — per-CAPTAIN seat-identity trailer backstop

`operating-disciplines.md §28`. An opt-in safety-net that appends the seat
`Co-Authored-By` trailer to a commit message when a seat declared itself this
session, idempotently, **without ever touching `Author:`**.

### What it does

- Reads ONLY the session-local `STOA_SEAT_TRAILER` env var. It does NOT read commit
  content, the branch name, file names, or any other (potentially attacker-supplied)
  surface. When `STOA_SEAT_TRAILER` is unset, the hook is a clean no-op.
- Shape-gates the value against the canonical
  `Co-Authored-By: CAPTAIN_<X>_<slug> <captain-<x>@<slug>.local>` pattern and rejects
  (no-op) anything malformed. The value is never `eval`'d and never expanded into
  command position — it is handed to `git interpret-trailers --if-exists=addIfDifferent`
  as a single quoted `--trailer` data literal.
- Appends ONLY the `Co-Authored-By` trailer. It NEVER calls `git config user.*`, never
  sets `GIT_AUTHOR_*`, and never touches the commit `Author:` field — `Author:` stays
  the PRINCIPAL's configured identity per the absolute never-override rule.
- `--if-exists=addIfDifferent` makes it idempotent: a trailer a CAPTAIN already wrote
  by hand (CAPTAIN_ADA.md §5.5) is NOT duplicated, but a DIFFERENT CAPTAIN's trailer on
  the same commit IS appended (multi-CAPTAIN commits work).

### FAIL-OPEN contract (load-bearing — do not change)

`prepare-commit-msg` **aborts the commit on any non-zero exit**, and — unlike
`pre-commit` — it is **NOT suppressed by `--no-verify`**
(https://git-scm.com/docs/githooks). A buggy hook here would brick EVERY commit,
including emergency ones, with no escape hatch. The hook therefore **exits 0 on every
code path**. Even if `interpret-trailers` errors, the message is left untouched and the
hook still exits 0. Do not add `set -e`; do not introduce a non-zero exit path.

### Arming it (per-clone, operator-explicit — two methods)

**Method A — copy into `.git/hooks/` (simplest):**

```sh
cp .claude/githooks-candidate/prepare-commit-msg .git/hooks/prepare-commit-msg
chmod +x .git/hooks/prepare-commit-msg
```

**Method B — point `core.hooksPath` at the candidate dir** (arms every candidate hook
in the dir at once; use only if you want all of them):

```sh
git config core.hooksPath .claude/githooks-candidate
```

To **disarm**: delete `.git/hooks/prepare-commit-msg` (method A) or
`git config --unset core.hooksPath` (method B).

### Windows pitfalls

- **Line endings.** The hook must ship with LF line endings; a `#!/bin/sh` hook with
  CRLF can fail to execute under some shells. The colocated `.gitattributes` pins
  `prepare-commit-msg text eol=lf` so it stays LF regardless of `core.autocrlf`. If you
  copy it manually, confirm LF (`file prepare-commit-msg` should say "POSIX shell
  script", not "with CRLF line terminators").
- **Exec bit.** `chmod +x` after copying (method A). An unexecutable hook is silently
  skipped by git — harmless (fail-open) but the trailer won't be added.

### Setting `STOA_SEAT_TRAILER`

The hook consumes `STOA_SEAT_TRAILER`; nothing in the substrate sets it yet (that is
`stoa--w6d`'s seat-identity-promotion concern). Until a seat activation exports it, the
armed hook is a permanent (harmless) no-op. To use it manually in a session:

```sh
export STOA_SEAT_TRAILER='Co-Authored-By: CAPTAIN_ADA_the-stoa <captain-ada@the-stoa.local>'
```

### Coordination with `stoa--w6d` (committer sub-identity)

This hook writes the **trailer** (the squash-merge-surviving seat signal, §28.3).
`stoa--w6d` sets the **committer** (`GIT_COMMITTER_*` — the `git blame`/`git log`
readable seat signal). The two compose without conflict on different layers; neither
touches `Author:`. The design recommends a w6d-enabled activation set both the session
seat-marker and `STOA_SEAT_TRAILER` together (same source) so a w6d session also feeds
this hook. The hook does not presume w6d is shipped — when `STOA_SEAT_TRAILER` is unset
it is a clean no-op, so it ships independently and composes when w6d lands.
