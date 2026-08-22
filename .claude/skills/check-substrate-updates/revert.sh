#!/usr/bin/env bash
#
# revert.sh — undo the most recent substrate-update apply in a workspace.
#
# Usage:
#   revert.sh --workspace <path>                       # auto-detect git path or backup-dir
#   revert.sh --workspace <path> --timestamp <T>       # restore from specific backup-dir timestamp
#   revert.sh --workspace <path> --files <f1> ...      # restore individual files only
#   revert.sh --workspace <path> --yes                 # skip confirmation
#
# Detection mirrors apply.sh: if the workspace is a git repo and .claude/ is
# tracked, use git revert against the last "chore(substrate): apply substrate
# updates" commit. Otherwise restore from <ws>/.claude/.substrate-backups/.
#
# CITE: as of Arc 38 (bj5; A8), user-tier workspaces are in-scope for revert.sh.
# The script is tier-agnostic — it operates on the --workspace path regardless of
# tier; the existing git/backup-dir detection handles both. The user-tier
# substitution-tracking (manifest at <workspace>/.substrate-manifest) is not
# involved at revert time (revert restores byte-for-byte from git or backup-dir).
# Cross-ref: agents/design/stoa--ojz/design.md §2.4.3.

set -euo pipefail

WORKSPACE=""
TIMESTAMP=""
FILES=()
ASSUME_YES=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace)
      [ "$#" -ge 2 ] || { echo "revert.sh: error: --workspace requires a path" >&2; exit 2; }
      WORKSPACE="$2"; shift 2 ;;
    --timestamp)
      [ "$#" -ge 2 ] || { echo "revert.sh: error: --timestamp requires a value" >&2; exit 2; }
      TIMESTAMP="$2"; shift 2 ;;
    --files)
      [ "$#" -ge 2 ] || { echo "revert.sh: error: --files requires a path" >&2; exit 2; }
      FILES+=("$2"); shift 2 ;;
    --yes)
      ASSUME_YES=1; shift ;;
    -h|--help)
      sed -n '/^# revert\.sh/,/^# Detection mirrors.*$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "revert.sh: error: unknown argument: $1 (try --help)" >&2; exit 2 ;;
  esac
done

[ -n "$WORKSPACE" ] || { echo "revert.sh: error: --workspace is required" >&2; exit 2; }
[ -d "$WORKSPACE" ] || { echo "revert.sh: error: workspace does not exist: $WORKSPACE" >&2; exit 2; }
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

# NORMALIZE WORKSPACE to the PARENT of .claude/ so all downstream path
# construction (backup_root="${WORKSPACE}/.claude/.substrate-backups" at
# line ~107, dest="${WORKSPACE}/${f}" in the restore loop) matches the
# project-tier shape. The --workspace arg MAY be either $HOME or $HOME/.claude
# (user-tier) — both should resolve to the same canonical WORKSPACE value
# (parent-of-.claude). This is the same 3-line strip applied in apply.sh
# (~lines 255-263) and check.sh (~lines 705-707) — lifted verbatim per Arc 38
# rev1 fix (VERA falsifying-probe finding: revert.sh at user-tier constructed
# <ws>/.claude/.claude/.substrate-backups before this normalization landed).
# Cross-ref: agents/design/stoa--ojz/design.md §2.4.3 (the design's claim
# 'revert.sh works at user-tier transparently' was falsified — this 3-line
# strip is the minimal fix that restores the claim).
if [ "${WORKSPACE%/.claude}" != "$WORKSPACE" ]; then
  WORKSPACE="${WORKSPACE%/.claude}"
fi

# ----- detect path -----------------------------------------------------------

USE_GIT=0
if git -C "$WORKSPACE" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
   && git -C "$WORKSPACE" ls-files .claude 2>/dev/null | grep -q .; then
  USE_GIT=1
fi

confirm() {
  local msg="$1"
  if [ "$ASSUME_YES" -eq 1 ]; then return 0; fi
  printf "%s [y/N] " "$msg"
  if ! read -r answer </dev/tty; then return 1; fi
  case "$answer" in y|Y|yes) return 0 ;; *) return 1 ;; esac
}

# ----- git path --------------------------------------------------------------

if [ "$USE_GIT" -eq 1 ]; then
  apply_sha="$(git -C "$WORKSPACE" log --grep "chore(substrate): apply substrate updates" -n 1 --format=%H 2>/dev/null || true)"
  if [ -z "$apply_sha" ]; then
    echo "revert.sh: no apply commit found in workspace git history (looked for 'chore(substrate): apply substrate updates')." >&2
    exit 2
  fi

  if [ "${#FILES[@]}" -gt 0 ]; then
    parent="$(git -C "$WORKSPACE" rev-parse "${apply_sha}^" 2>/dev/null || true)"
    if [ -z "$parent" ]; then
      echo "revert.sh: cannot determine parent of apply commit ${apply_sha}" >&2
      exit 2
    fi
    confirm "Revert ${#FILES[@]} file(s) to state at ${parent} (parent of apply commit ${apply_sha})?" || { echo "aborted."; exit 0; }
    for f in "${FILES[@]}"; do
      git -C "$WORKSPACE" checkout "$parent" -- "$f"
      echo "restored: $f (from $parent)"
    done
    git -C "$WORKSPACE" commit -m "chore(substrate): revert per-file from ${apply_sha}" >/dev/null || true
  else
    confirm "Revert apply commit ${apply_sha}? (creates a new revert commit)" || { echo "aborted."; exit 0; }
    git -C "$WORKSPACE" revert --no-edit "$apply_sha"
    echo "reverted: ${apply_sha}"
  fi
  exit 0
fi

# ----- backup-dir path -------------------------------------------------------

backup_root="${WORKSPACE}/.claude/.substrate-backups"
if [ ! -d "$backup_root" ]; then
  echo "revert.sh: no backup directory found at $backup_root (and workspace not git-tracked)." >&2
  exit 2
fi

if [ -n "$TIMESTAMP" ]; then
  pick="${backup_root}/${TIMESTAMP}"
else
  # Most recent timestamp dir (lexicographic sort works for ISO-8601 stamps).
  pick="$(ls -1 "$backup_root" 2>/dev/null | sort | tail -n 1)"
  pick="${backup_root}/${pick}"
fi
if [ ! -d "$pick" ]; then
  echo "revert.sh: backup-dir not found: $pick" >&2
  exit 2
fi

confirm "Restore from backup ${pick}?" || { echo "aborted."; exit 0; }

if [ "${#FILES[@]}" -gt 0 ]; then
  for f in "${FILES[@]}"; do
    src="${pick}/${f}"
    dest="${WORKSPACE}/${f}"
    if [ ! -f "$src" ]; then
      echo "revert.sh: warning: $f not present in backup $pick — skipping" >&2
      continue
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "restored: $f (from $pick)"
  done
else
  # Restore every file present in the backup tree.
  while IFS= read -r src; do
    rel="${src#${pick}/}"
    dest="${WORKSPACE}/${rel}"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "restored: $rel (from $pick)"
  done < <(find "$pick" -type f)
fi

exit 0
