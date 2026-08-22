#!/usr/bin/env bash
#
# pretooluse-clean-tree-before-branch.sh — PreToolUse hard gate (design-rev1 §5.1b).
#
# Blocks arc-build branch creation when the working tree is dirty, per the
# clean-tree-before-branch discipline (operating-disciplines.md §24 arc-build
# branch hygiene; MAJOR_PLINY §5.9 / MAJOR_POLYBIUS §18). Arc-build branches
# are created from a CLEAN tree so the resulting diff is wholly attributable to
# the arc — a dirty starting tree silently folds unrelated changes into the
# arc's diff, defeating CATO's review-against-intent.
#
# REGISTRATION (settings-hooks.json template): PreToolUse, narrowed to the
# branch-creating git verbs via `if: "Bash(git *)"` (the doc-blessed matcher;
# the script then discriminates the create-a-branch verbs from tool_input.command
# so the deny message can name the dirty paths — the authoring rule).
#
# FAIL-OPEN (design §4 / ARGUS R5): on any script error (no python3, no git,
# malformed event) this allows the branch creation.

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null)" || exit 0
# shellcheck source=/dev/null
. "${HOOK_DIR}/_hooklib.sh" 2>/dev/null || exit 0

read_stdin_event

CMD="$(event_field tool_input.command)" || allow
[ -n "$CMD" ] || allow

# Fire only on a command that CREATES a branch / worktree. Match the create
# verbs specifically (not every git call):
#   git checkout -b <name>      git switch -c <name>
#   git branch <name>           git worktree add <path> [<branch>]
# `git branch` with no extra arg (a LIST) must NOT fire; require a following
# token. We test the command string for the create shapes.
creates_branch=0
case "$CMD" in
  *"git checkout -b "*|*"git switch -c "*|*"git worktree add "*) creates_branch=1 ;;
esac
# `git branch <name>` — a bare `git branch` or `git branch -a/-l/--list/-d`
# is not a create. Require a non-flag token after `git branch`.
if [ "$creates_branch" -eq 0 ]; then
  case "$CMD" in
    *"git branch "*)
      # Extract the token following 'git branch'.
      rest="${CMD#*git branch }"
      first_tok="${rest%% *}"
      case "$first_tok" in
        ""|-*) : ;;          # bare list / flag form -> not a create
        *) creates_branch=1 ;;
      esac
      ;;
  esac
fi
[ "$creates_branch" -eq 1 ] || allow

CWD="$(event_field cwd)" || CWD=""
[ -n "$CWD" ] || CWD="$(pwd)"

# Run the clean-tree check in the relevant repo. If git status itself fails
# (not a repo, no git), FAIL-OPEN.
STATUS="$(git -C "$CWD" status --porcelain 2>/dev/null)" || allow

# Empty porcelain => clean tree => allow. (We do not carve out an
# "expected-untracked" set here — the discipline is a clean tree; the operator
# commits/stashes/cleans first. A future arc may add an expected-untracked
# allowance if it proves needed.)
[ -z "$STATUS" ] && allow

# Dirty tree -> DENY with the dirty paths listed inline (self-contained).
n="$(printf '%s\n' "$STATUS" | grep -c '^' )"
# Cap the listed paths so the message stays readable; note the total count.
paths="$(printf '%s\n' "$STATUS" | head -20 | sed 's/^/    /')"
extra=""
if [ "$n" -gt 20 ]; then extra="
    ... and $((n - 20)) more"; fi

emit_deny "Branch creation blocked: the working tree in ${CWD} is dirty (${n} modified/untracked path(s)). Per the arc-build branch-hygiene discipline, arc-build branches are created from a CLEAN tree so the diff is wholly attributable to the arc. Commit, stash, or clean the listed paths first, then create the branch.
Dirty paths:
${paths}${extra}"
