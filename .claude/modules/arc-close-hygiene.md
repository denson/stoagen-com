# Arc-close hygiene — signoff-accuracy + paste archival — instruction module

> Relocated from `MAJOR_PLINY.md` §5.10 + §5.11 (CONDITIONAL — read at arc close). Provenance:
> debloat Arc 48 cut `agents/design/arc-48/design-rev1.md` + epic `bw show stoa--xyb` / cut ticket
> `bw show stoa--xyb.10`. The slim-core residue is the §5.10 (real heading line — spec-cited) +
> §5.11 stubs + routing-map row (arc close) + relocation-index row in §4.2. The §5.10.1/.2/.3 +
> §5.11.1/.2/.3 N=1 provenance compresses to the `Anchor:` lines below.

## 5.10 Signoff-accuracy — verify cleanup claims before posting

When you post a signoff (the arc-close comment that closes the work-unit ticket and hands history to future POLYBIUSes), claims about cleanup actions — branch deletion, worktree removal, file cleanup, environment teardown — MUST be verified before the signoff is posted. Sign what you did, not what you intended.

**The rule:** before posting any signoff that names a cleanup action, run the verification command that confirms the action's effect on disk. Specifically:

- **Branch deletion claims** — verify with `git branch` (local) and `git ls-remote --heads origin <branch>` (remote). The branch should NOT appear in the local list; `git ls-remote` should return an empty result for the named branch.
- **Worktree removal claims** — verify with `git worktree list` (the registration) **AND** `[ ! -d .claude/worktrees/arc-<N>-build ]` (the directory itself). On Windows the registration can be gone while the directory survives as an orphan — `git worktree remove` succeeds in de-registering but a file lock blocks the rmdir ("Permission denied" / "Device or resource busy", stoa--7ap). A signoff that claims "worktree removed" MUST assert BOTH that the registration is gone AND that the directory is gone; if the directory survives, run the `pre-branch-hygiene.md` §5.9.4 orphan-removal retry before posting, or post a signoff that honestly names the orphan (the choice-(a)/choice-(b) rule below). The cleanup *command sequence* that produces this state lives in `pre-branch-hygiene.md` §5.9.4; this §5.10 bullet is the verify-before-claim half.
- **File cleanup claims** — verify with `ls <path>` or `git status` for tracked files. The named file/directory should NOT exist (or, for tracked files, should show as deleted in `git status`).
- **Process / cron / scheduled-job teardown** — verify with the inverse of the scheduling command. `CronList` for cron; `bw show <ticket>` for in-flight bw work; `git worktree list` for in-flight worktrees.
- **Squash-merge `--body` override discipline** — when merging via `gh pr merge --squash`, NEVER pass a custom `--body` that omits the source commits' `Co-Authored-By:` trailers. Either omit `--body` (GitHub's default auto-concatenates source-commit bodies, preserving trailers per `operating-disciplines.md` §28.3) OR include the trailers explicitly in the `--body` HEREDOC. Anti-pattern: a custom `--body` with a clean summary but no trailer lines silently drops the §28 seat-identity signal on the squash commit. Empirical anchor: Arc 37 `bb12806` (2026-05-17); worked example at `operating-disciplines.md` §28.3.1.

If a verification command surfaces state inconsistent with the cleanup claim, **do not post the signoff with the claim.** Either: (a) do the cleanup action, re-verify, then post; or (b) post a signoff that honestly names the state observed ("PR #N merged; cleanup of worktree at `<path>` deferred — open work-unit ticket `<id>` filed for the cleanup"). Choice (a) is preferred; choice (b) is honest-fallback when the cleanup action cannot be completed in this session.

**Why verify-before-claim is load-bearing for signoffs specifically:** a signoff is forward-anchored. Future POLYBIUSes reading the ticket trail use the signoff as the canonical record of what was done. An inaccurate signoff propagates as false history — future POLYBIUS reads "worktree removed, branches deleted" and proceeds on that premise; the next arc fails the pre-branch hygiene check (§5.9 check 1) when the stale branch turns up, and the cost is the surface-and-adjudicate cycle the §5.9 discipline exists to prevent. The error compounds across arcs.

**Cross-references (live):** §5.9 (pre-branch hygiene at the opening arc beat; this §5.10 is the closing-beat sibling); `operating-disciplines.md` §19.6 (attestation-confabulation discipline at the universal-seat root cause — §5.10 is the PLINY-application); `operating-disciplines.md` §24 (Arc 30 pre-branch hygiene cross-ref + thin pointer to §5.10); `MAJOR_PLINY.md` §6.1 (bw command syntax) + `operating-disciplines.md` §12 (bw cookbook) — the `bw comment` + `bw close --reason` commands the signoff is posted with.

Anchor: `stoa--ads` — Arc 29 signoff (2026-05-17) claimed worktree-removed + branches-deleted; neither was done; caught by user-tier POLYBIUS on the Arc 31 pre-branch hygiene check; required a manual cleanup sequence before Arc 31 could dispatch. N=1 bit-by-it (defect class signoff-cleanup-claim-vs-state); enters substrate canon off-gate per `operating-disciplines.md` §6.7.1 on the 2026-05-17 PRINCIPAL articulation; accretes per §6.7.1. Recover via `bw show stoa--ads`.

## 5.11 HUMAN_paste-*.md archival on arc close

When an arc closes (PR merged, work-unit ticket closed, signoff posted per §5.10), the arc-specific activation paste files at the workspace root — `HUMAN_paste-pliny-arc-<N>-instruction.md` and `HUMAN_paste-polybius-arc-<N>-instruction.md` — are moved into the arc's archive directory at `substrate/arcs/arc-<N>/pastes/`. Workspace root carries only the live `HUMAN_paste-orchestrator-instruction.md` (the non-arc-scoped default activation paste, refreshed in place per `MAJOR_POLYBIUS.md` §4.5 + §6) and the activation paste files for arcs that are still in flight.

The discipline mirrors and prefix-aligns with the existing `substrate/arcs/arc-<N>-build-directive.md` archival pattern: each arc's directive lives at `substrate/arcs/` as a flat file `arc-<N>-build-directive.md`; this convention places each arc's activation pastes in a sibling `arc-<N>/pastes/` subdirectory under the same parent. Both artifacts share the `arc-<N>` prefix, so a future POLYBIUS looking for "what activated Arc 27" runs `ls substrate/arcs/ | grep arc-27` and finds the flat-file directive `arc-27-build-directive.md` AND the subdirectory `arc-27/` adjacent in the listing. The two artifacts are co-located by prefix at the same `substrate/arcs/` parent level rather than nested inside an arc-number subdirectory (the bare-number form `substrate/arcs/27/` was rejected because it would have hidden the directive — which lives at the flat path — from `ls substrate/arcs/27/`).

**The cleanup action at arc close (PLINY runs after PR merge, before posting signoff per §5.10):**

```
mkdir -p substrate/arcs/arc-<N>/pastes
git mv HUMAN_paste-pliny-arc-<N>-instruction.md substrate/arcs/arc-<N>/pastes/
git mv HUMAN_paste-polybius-arc-<N>-instruction.md substrate/arcs/arc-<N>/pastes/
git commit -m "Arc <N>: archive activation pastes to substrate/arcs/arc-<N>/pastes/"
git push
```

`git mv` preserves the file's git-history continuity so a future reader walking `git log --follow substrate/arcs/arc-<N>/pastes/HUMAN_paste-pliny-arc-<N>-instruction.md` sees the file's full lifecycle from initial dispatch-tracking commit through the archival move. Plain `mv` + `git rm` + `git add` would break this property; `git mv` is load-bearing.

**Signoff-accuracy verification (cross-ref to §5.10):** the §5.10 signoff verifies cleanup claims before posting. The paste-archival action is a new "file cleanup" sub-case §5.10 surfaces. Concretely, before posting the signoff PLINY runs both:

```
ls substrate/arcs/arc-<N>/pastes/                                      # must show both arc-<N> paste files
ls HUMAN_paste-pliny-arc-<N>-instruction.md HUMAN_paste-polybius-arc-<N>-instruction.md 2>/dev/null   # must return empty (or "No such file") — two args to one ls call for shell portability (bash + PowerShell)
```

If either check surfaces inconsistent state, the signoff is NOT posted with the cleanup claim — same rule as §5.10's branch-deletion / worktree-removal verifications. Either complete the archival action, re-verify, then post; or post a signoff that honestly names the state observed.

**Self-application exception.** When the arc itself encodes or touches the archival convention (the originating canon-shipping arc, or a future arc that revises §5.11), ADA may bundle the paste archival INTO the gauntlet build commit rather than waiting for a standalone post-merge commit. The two shapes produce equivalent end-state (pastes archived; workspace root clean; `git log --follow` walks the rename); the choice is which commit carries the archival. Arc 34 (this section's originating arc) self-applied this way. Both shapes are authorized under `MAJOR_POLYBIUS.md` §18.1 "Arc directive + activation paste tracking commits."

**Forward-only convention.** This discipline applies to Arc 34 and forward. The ~24 historical paste files at workspace root from Arcs 21-33 are NOT backfilled by this convention — historical pastes are honest artifacts of when they were authored, and a bulk-rename of all of them would (a) muddy the git history for those arcs, (b) require a one-off operational sweep that is itself a separate scope, and (c) gain little for future POLYBIUSes who can still find historical pastes via `git log` + filesystem grep. If a future user-tier POLYBIUS surfaces a real reader-friction case for the historical accumulation, a separate housekeeping ticket can address backfill as its own scoped operation.

**Cross-references (live):** §5.10 (signoff-accuracy — §5.11's cleanup action is verified by §5.10's rule); §5.9 (pre-branch hygiene — §5.11 fires at the closing arc-boundary, §5.9 at the opening; the two are paired); `MAJOR_POLYBIUS.md` §4.5 (durable-substrate-with-short-prompts — the paste files §5.11 archives are the on-disk substrate §4.5 authorizes); `MAJOR_POLYBIUS.md` §15 (N=1 honest-scope); `operating-disciplines.md` §6.7.1 (canon-promotion gate).

Anchor: `stoa--f37` (2026-05-17 user-tier POLYBIUS end-of-session hygiene audit, folded as C2 in Arc 34; observable state: `ls HUMAN_paste-*.md` at workspace root returned 24 files spanning arcs 21-34). N=1 bit-by-it (defect class workspace-root accumulation); enters substrate canon off-gate per `operating-disciplines.md` §6.7.1 on the Arc 34 directive A3 LOCK; accretes per §6.7.1. Recover via `bw show stoa--f37`.
