# Pre-branch hygiene + arc-build worktree convention — instruction module

> Relocated from `MAJOR_PLINY.md` §5.9 + §5.9.4 (CONDITIONAL — read at arc-build branch creation).
> Provenance: debloat Arc 48 cut `agents/design/arc-48/design-rev1.md` + epic `bw show stoa--xyb` /
> cut ticket `bw show stoa--xyb.10`. The slim-core residue is the §5.9 + §5.9.4 stubs (both kept as
> real heading lines — substrate-cited) + routing-map row (arc-build branch creation) +
> relocation-index row in §4.2. The §5.9.1/.2/.3 + §5.9.4.1 N=1 provenance compresses to the
> `Anchor:` lines below.

## 5.9 Pre-branch hygiene — the two-check rule before creating an arc-build branch

Before you create a new arc-build branch (`git checkout -b arc-N/build` or equivalent), run two checks. If either fails, pause and surface — do NOT silently inherit local-ahead state into the arc branch.

**The two-check rule (PRINCIPAL-articulated 2026-05-17):**

1. **No other arc-build branch is in flight.** The prior arc's branch must be merged AND deleted before a new one is created. PRINCIPAL's framing:

   > "at most one team working on a repo at any one time"
   >
   > "pliny can't create more than one branch to work with until the other is committed and merged"

   Detection: `git branch | grep -E '^\s*arc-[0-9]+/build$'` should return at most the branch you are about to create (i.e., zero results before creation). Long-running PR branches that have not yet merged are a fail signal.

2. **Local main equals origin/main.** No unpushed commits in either direction.

   ```
   git fetch origin main
   git log --oneline main..origin/main      # must be empty
   git log --oneline origin/main..main      # must be empty
   ```

   Both commands return empty on a clean working tree synchronized with origin. If `main..origin/main` is non-empty, origin has commits local does not — pull or rebase first per operator discretion. If `origin/main..main` is non-empty, local has commits origin does not — push them first under their own PR, NOT bundled into the arc branch.

**On failure of either check, surface — do not silently proceed.** Post a comment on the arc's work-unit ticket tagged `[for: user-tier POLYBIUS]` (or `[for: PRINCIPAL]` when user-tier POLYBIUS is unavailable) naming the specific state observed and the adjudication ask. Worked surfacing shape:

> "Pre-branch check 2 failed: `origin/main..main` shows 3 unpushed commits (`abc1234 chore: ...`, `def5678 docs: ...`, `9abcdef fix: ...`). Recommend pushing these under their own PR first so they do not get absorbed into the arc-N squash. Adjudication ask: (a) push under their own PR first then re-run check; (b) discard if not wanted; (c) something else?"

The surface-on-failure behavior is load-bearing. Silently choosing one of the options (e.g., "I'll just push them") would re-introduce the exact failure mode the discipline closes — operator did not see the state; future POLYBIUS reading the git history sees a bundle they did not authorize.

**Cross-references (live):**

- Activation paste convention: `MAJOR_POLYBIUS.md` §5.1.2 carries the convention that PLINY-targeted activation pastes include the pre-branch hygiene preamble. The substrate-canonical template `substrate/templates/paste-instruction-template.md` carries the preamble as a mandatory section. Both are paste-side redundancy; this §5.9 prose is the substantive source of truth.
- Universal-team layer: `operating-disciplines.md` §24 carries the brief universal-team framing — today PLINY is the only seat that creates arc-build branches under the gauntlet pipeline; if a future seat ever does, the discipline applies to that seat too.
- `MAJOR_PLINY.md` §6.1 (bw command syntax) + `operating-disciplines.md` §12 (bw cookbook) — the `bw comment` and `[for: ...]` tag conventions used in the surface-on-failure step.
- `operating-disciplines.md` §6.7.1 — the N=1 canon-promotion gate.

Anchor: `stoa--3cs` (work-unit ticket carrying the discipline shape + 2026-05-17 scope-expansion comment + N=2 bit-by-it + N=1 worked-when-applied citations; PR #46 + PR #8 bit-by-it cases; PR #9 / `stoa--ads` Arc 29 worked-when-applied case). N=1 provenance + accretion path: PRINCIPAL declared this discipline 2026-05-17 (project-direction authority); it enters substrate canon off-gate per `operating-disciplines.md` §6.7.1, with future-evidence accretion required for "structural lesson" promotion. Recover via `bw show stoa--3cs`.

## 5.9.4 Arc-build worktree convention — separate worktree at .claude/worktrees/arc-N-build/

After the two-check rule passes (§5.9 check 1 + check 2), create the arc-build branch in a SEPARATE worktree at `.claude/worktrees/arc-N-build/`. The main worktree stays on main. Concretely:

```
git worktree add .claude/worktrees/arc-N-build -b arc-N/build
cd .claude/worktrees/arc-N-build
```

Subsequent arc-build work happens entirely within `.claude/worktrees/arc-N-build/`. The main worktree at the project root stays on main throughout the arc — which means user-tier POLYBIUS (or any concurrent operator in the main worktree) can land housekeeping work, read git history, or run substrate-check workflows in main without colliding with PLINY's arc-build checkout.

**Why separate worktree by default:** the alternative is creating the arc-build branch in the main worktree (`git checkout -b arc-N/build` from the project root). The main worktree's checkout then flips to `arc-N/build` for the duration of the arc. Two failure modes follow:

- **Concurrent-operator collision.** User-tier POLYBIUS operating in the main worktree finds the checkout is no longer main; any commits land on `arc-N/build` instead of main. The cost in 2026-05-17 Arc 31: user-tier POLYBIUS had to hold position rather than land housekeeping commits.
- **Cleanup is less mechanical.** Removing a separate worktree is a single `git worktree remove` call; cleaning up after a main-worktree checkout-flip requires a checkout-back-to-main step plus the branch-deletion sequence. The §5.10 signoff-accuracy check (verify cleanup) is simpler when the cleanup is mechanical.

**At arc close, the cleanup sequence (PLINY runs after PR merge, before posting signoff):**

```
# Run this from the MAIN worktree root — NEVER while cwd is inside
# .claude/worktrees/arc-N-build (an inside-cwd process IS the Windows file lock
# that makes `git worktree remove` leave an orphan dir — stoa--7ap, claude-code
# #41740 / #32747). cd to the repo root first.

git worktree remove .claude/worktrees/arc-N-build || git worktree remove --force .claude/worktrees/arc-N-build

# Windows: `git worktree remove` can DE-REGISTER the worktree (`git worktree list`
# shows it gone) yet FAIL to delete the directory — observed "Permission denied"
# (Arc 2) and "Device or resource busy" (Arc 3). Assert the DIRECTORY is gone,
# not just the registration; retry the orphan-dir removal if it survived.
if [ -d .claude/worktrees/arc-N-build ]; then
  git worktree prune
  rm -rf .claude/worktrees/arc-N-build
fi
[ ! -d .claude/worktrees/arc-N-build ] || { echo "ORPHAN: worktree dir still present at .claude/worktrees/arc-N-build — a process likely holds a lock (cwd inside? MCP handle?). Resolve before posting signoff." >&2; }

git branch -D arc-N/build
git push origin --delete arc-N/build
```

**Windows orphan-dir root cause (stoa--7ap).** On Windows `git worktree remove` fails with **"Permission denied"** (observed Arc 2) or **"Device or resource busy"** (observed Arc 3) when a process holds a lock on the worktree directory — most commonly **a process whose cwd is inside the worktree** (the agent itself), or an MCP server holding a handle ([claude-code #41740](https://github.com/anthropics/claude-code/issues/41740), [#32747](https://github.com/anthropics/claude-code/issues/32747)). The remove can still *de-register* the worktree (so `git worktree list` no longer shows it) while leaving the directory on disk as an invisible orphan. The mitigation is in the fence above: run from the main root (never cwd-inside), `git worktree remove` (force-fallback), then `git worktree prune` + `rm -rf` the orphan if the dir survived, then **assert the directory itself is gone** — not just the registration.

The `rm -rf` targets a **fixed literal template path** `.claude/worktrees/arc-N-build` (the `arc-N` is substituted to a concrete arc number at author time, not a runtime `$VAR`) per `operating-disciplines.md` §8.6 — verbatim re-execution does not permission-pause on a variable expansion.

The §5.10 signoff-accuracy discipline requires PLINY to verify each of these completed before posting the signoff: `git worktree list` should not show `.claude/worktrees/arc-N-build` **AND** `[ ! -d .claude/worktrees/arc-N-build ]` must hold (the directory itself is gone, not just the registration — on Windows the registration can be gone while the orphan dir survives, per the root-cause note above); `git branch` should not show `arc-N/build`; `git ls-remote --heads origin arc-N/build` should return empty. The verification commands are stable across arcs because the worktree path and branch name follow the same template every time.

Anchor: `stoa--32b.1` (2026-05-17 Arc 31 divergence — PLINY operated `arc-31/build` in the main workspace path; the checkout flipped main→arc-31/build; user-tier POLYBIUS held position). De-facto pattern Arcs 26-30 (N=5 bit-by-it, separate worktrees shipped clean); Arc 31 N=1 bit-by-it of the failure mode. Enters substrate canon off-gate per `operating-disciplines.md` §6.7.1 on the 2026-05-17 project-direction declaration; accretes per §6.7.1. Recover via `bw show stoa--32b.1`.
