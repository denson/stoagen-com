#!/usr/bin/env bash
#
# apply.sh — write substrate updates to a deployed workspace, with per-file
# consent + diff display, git pre-commit safety net, and a running-agent
# warning when role files are touched.
#
# Usage:
#   apply.sh --workspace <path>                                # interactive walk
#   apply.sh --workspace <path> --files <f1> [--files <f2>...] # explicit list
#   apply.sh --workspace <path> --all-differing                # apply every differing file
#   apply.sh --workspace <path> ... --yes                      # skip per-file prompt; auto-commit pre-state
#   apply.sh --workspace <path> ... --overwrite-local          # apply even if user knows file was locally modified (informational)
#
# Exit codes:
#   0 — applied (or nothing to do)
#   1 — refused (uncommitted .claude/ state without --yes)
#   2 — bad arguments / setup error

set -euo pipefail

# ----- locate substrate ------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBSTRATE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# ----- argument parsing ------------------------------------------------------

WORKSPACE=""
FILES=()
ALL_DIFFERING=0
ASSUME_YES=0
OVERWRITE_LOCAL=0
DIFF_TRUNCATE_LINES=30

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace)
      [ "$#" -ge 2 ] || { echo "apply.sh: error: --workspace requires a path" >&2; exit 2; }
      WORKSPACE="$2"
      shift 2
      ;;
    --files)
      [ "$#" -ge 2 ] || { echo "apply.sh: error: --files requires a path" >&2; exit 2; }
      FILES+=("$2")
      shift 2
      ;;
    --all-differing)
      ALL_DIFFERING=1
      shift
      ;;
    --yes)
      ASSUME_YES=1
      shift
      ;;
    --overwrite-local)
      OVERWRITE_LOCAL=1
      shift
      ;;
    -h|--help)
      sed -n '/^# apply\.sh/,/^#   2 — bad arguments.*$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "apply.sh: error: unknown argument: $1 (try --help)" >&2
      exit 2
      ;;
  esac
done

[ -n "$WORKSPACE" ] || { echo "apply.sh: error: --workspace is required" >&2; exit 2; }
[ -d "$WORKSPACE" ] || { echo "apply.sh: error: workspace does not exist: $WORKSPACE" >&2; exit 2; }
WORKSPACE="$(cd "$WORKSPACE" && pwd)"

# ----- helpers (shared shape with check.sh; inlined per design §9.2) ---------

normalize_lf() { tr -d '\r'; }

# apply_substitutions <source-file> <deployed-rel-path> <tier> <slug>
# Mirrors install.sh substitutions (lines ~613–617 + ~658 in install.sh as of c37cf5a).
# If install.sh adds a new {{...}} placeholder, this function must be updated to match.
#
# Substitutions are FILE-CLASS-SCOPED: only the MAJOR and CAPTAIN files receive
# sed substitution; templates and skills are deployed verbatim via cp / cp -R
# (install.sh ~lines 681, 711). Substituting a verbatim-deployed file would
# corrupt prose that documents the placeholder. See check.sh for the canonical
# comment block; this function is the apply-side mirror.
apply_substitutions() {
  local source_file="$1"
  local dep_rel="$2"
  local tier="$3"
  local slug="$4"
  local name_suffix=""
  case "$tier" in
    project|subproject) name_suffix="_${slug}" ;;
  esac
  case "$dep_rel" in
    .claude/MAJOR_*.md|.claude/agents/CAPTAIN_*.md)
      sed "s/{{NAME_SUFFIX}}/${name_suffix}/g" "$source_file"
      ;;
    *)
      cat "$source_file"
      ;;
  esac
}

# apply_substitutions_from_manifest <source-file> <deployed-rel-path> <workspace-abs>
#
# CITE: manifest-driven substitution per Arc 38 / bj5 / design.md §2.2 (A8 γ pick).
# The manifest at <workspace>/.substrate-manifest is written by install.sh at deploy
# time. Format invariant maintained at substrate/install.sh write_substrate_manifest.
# If install.sh rotates manifest format, this parser must update. Fallback path:
# legacy apply_substitutions() for project-tier no-manifest case (pre-Arc-38
# behavior preserved). Mirror of check.sh function per existing share-via-inline
# convention (check.sh:74-80).
apply_substitutions_from_manifest() {
  local source_file="$1"
  local dep_rel="$2"
  local ws_abs="$3"
  # Manifest lives at <workspace>/.claude/.substrate-manifest (workspace = parent of .claude/).
  local manifest="${ws_abs}/.claude/.substrate-manifest"

  if [ ! -f "$manifest" ]; then
    local tier_line tier slug
    tier_line="$(detect_tier "$ws_abs")"
    tier="${tier_line%% *}"
    slug="${tier_line#* }"; slug="${slug# }"
    apply_substitutions "$source_file" "$dep_rel" "$tier" "$slug"
    return 0
  fi

  # CITE: format-version contract per Arc 40 / stoa--6n9. Mirror of check.sh
  # header-scan; rejects unknown format-version. No `# format=` line ->
  # treat as v1 (graceful fallback for pre-fix manifests). Companion
  # write-site: substrate/install.sh write_substrate_manifest. Any
  # install.sh that bumps v1->v2 MUST update this parser in the same arc.
  local manifest_format
  manifest_format="$(grep -E '^# format=v[0-9]+' "$manifest" 2>/dev/null | head -1 | sed -E 's/^# format=(v[0-9]+).*/\1/')"
  if [ -n "$manifest_format" ] && [ "$manifest_format" != "v1" ]; then
    echo "apply.sh: error: ${manifest} format=${manifest_format} unknown; this apply.sh expects v1. Re-run install.sh to re-deploy with a matching manifest, or update the check-substrate-updates skill." >&2
    return 1
  fi

  # Array-form sed args; avoids the eval-pipe-interpretation bug.
  local sed_args=()
  local entry_path token replacement
  while IFS=$'\t' read -r entry_path token replacement; do
    case "$entry_path" in
      ""|\#*) continue ;;
    esac
    if [ "$entry_path" = "$dep_rel" ]; then
      case "$token$replacement" in
        *"|"*) continue ;;
      esac
      # Escape sed metacharacters in the replacement value before splicing it
      # into the s|...|...|g expression. Two-step (order matters):
      #   1. backslash '\' → '\\' (so any pre-existing '\' is literalized)
      #   2. ampersand '&' → '\&' (so '&' is read as literal, not "matched pattern")
      # Without step 2, a future manifest entry whose replacement contains '&'
      # would silently mangle the substitution (sed reads bare '&' in the RHS
      # of s|...|...| as a back-reference to the entire matched pattern).
      # Latent in the Arc 38 baseline writers (NAME_SUFFIX + USER_TIER_DIR
      # contain no '&'). Mirror of check.sh fix per CATO rev1 c2 finding.
      # Cross-ref: agents/design/stoa--ojz/design.md §2.2.
      replacement="${replacement//\\/\\\\}"
      replacement="${replacement//&/\\&}"
      sed_args+=(-e "s|${token}|${replacement}|g")
    fi
  done < "$manifest"

  if [ "${#sed_args[@]}" -eq 0 ]; then
    cat "$source_file"
  else
    sed "${sed_args[@]}" "$source_file"
  fi
}

# source_path_for_deployed — see check.sh for the canonical comment.
source_path_for_deployed() {
  local dep="$1" tier="$2" slug="$3" suffix=""
  case "$tier" in
    project|subproject) suffix="_${slug}" ;;
  esac
  local rel="${dep#.claude/}"
  case "$rel" in
    operating-disciplines.md)              echo "operating-disciplines.md" ;;
    MAJOR_*.md)
      # Any deployed MAJOR maps back to its unsuffixed source name. Strip the
      # subproject suffix (present only at subproject tier) before reattaching .md.
      # MAJOR suffix rule: suffixed at subproject ONLY (project/user carry none),
      # so only strip when tier=subproject. Ordered AFTER operating-disciplines.md
      # so it cannot shadow that arm. Mirror of check.sh source_path_for_deployed.
      local mbase="${rel%.md}"            # "MAJOR_POLYBIUS_acme" or "MAJOR_POLYBIUS"
      if [ "$tier" = "subproject" ] && [ -n "$suffix" ]; then
        mbase="${mbase%${suffix}}"        # strip "_acme" -> "MAJOR_POLYBIUS"
      fi
      echo "${mbase}.md"
      ;;
    agents/CAPTAIN_*.md)
      local base="${rel#agents/CAPTAIN_}"
      if [ -n "$suffix" ]; then base="${base%${suffix}.md}"; else base="${base%.md}"; fi
      echo "CAPTAIN_${base}.md"
      ;;
    templates/*) echo "$rel" ;;
    skills/*)    echo "$rel" ;;
    *)           echo "" ;;
  esac
}

detect_tier() {
  local ws="$1" ws_abs
  ws_abs="$(cd "$ws" && pwd)"
  if [ "$ws_abs" = "${HOME}/.claude" ] || [ "$ws_abs" = "${HOME}" ]; then
    echo "user "
    return 0
  fi
  if [ ! -d "${ws_abs}/.claude" ]; then
    echo "none "
    return 0
  fi
  local p
  for p in "${ws_abs}/.claude/MAJOR_POLYBIUS_"*.md; do
    if [ -f "$p" ]; then
      local base slug
      base="$(basename "$p")"
      slug="${base#MAJOR_POLYBIUS_}"; slug="${slug%.md}"
      echo "subproject ${slug}"
      return 0
    fi
  done
  if [ -f "${ws_abs}/.claude/MAJOR_POLYBIUS.md" ]; then
    local slug
    slug="$(basename "$ws_abs" | tr '.-' '__')"
    echo "project ${slug}"
    return 0
  fi
  echo "none "
}

# is_role_file <deployed-rel-path> -> echoes 1 (yes) or 0 (no).
is_role_file() {
  local p="$1"
  case "$p" in
    .claude/MAJOR_*.md|.claude/agents/CAPTAIN_*.md) echo 1 ;;
    *) echo 0 ;;
  esac
}

# git_path_active <workspace>: echoes 1 if workspace is in a git repo AND .claude/
# is tracked; else 0.
git_path_active() {
  local ws="$1"
  if ! git -C "$ws" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo 0; return 0
  fi
  # Check whether .claude/ has any tracked files.
  if git -C "$ws" ls-files --error-unmatch .claude >/dev/null 2>&1; then
    echo 1
  elif git -C "$ws" ls-files .claude 2>/dev/null | grep -q .; then
    echo 1
  else
    echo 0
  fi
}

# git_uncommitted_claude <workspace>: echoes the list of uncommitted .claude/
# files (one per line). Empty stdout = clean.
git_uncommitted_claude() {
  local ws="$1"
  git -C "$ws" status --porcelain -- .claude 2>/dev/null || true
}

# ----- tier detection --------------------------------------------------------

tier_line="$(detect_tier "$WORKSPACE")"
TIER="${tier_line%% *}"
SLUG="${tier_line#* }"; SLUG="${SLUG# }"

if [ "$TIER" = "none" ]; then
  echo "apply.sh: error: workspace is not stoa-deployed (no .claude/MAJOR_POLYBIUS*.md): $WORKSPACE" >&2
  exit 2
fi
if [ "$TIER" = "user" ]; then
  # CITE: Arc 38 (bj5; A8) — user-tier apply via .substrate-manifest. If no
  # manifest, fall back to the pre-Arc-38 refusal (telling the operator to
  # re-run install.sh). Manifest present → proceed with normal apply flow;
  # the only changed call site is apply_substitutions ->
  # apply_substitutions_from_manifest.
  #
  # NORMALIZE WORKSPACE to the PARENT of .claude/ so the per-file dep_abs
  # construction (deployed_path="${WORKSPACE}/${dep}" where dep starts with
  # ".claude/") matches project-tier shape. The --workspace arg MAY be either
  # $HOME or $HOME/.claude — detect_tier accepts both, but the rest of apply.sh
  # assumes <workspace>/.claude/<deployed-rel>. Same normalization shape as
  # check.sh's user-tier branch.
  if [ "${WORKSPACE%/.claude}" != "$WORKSPACE" ]; then
    WORKSPACE="${WORKSPACE%/.claude}"
  fi
  if [ ! -f "${WORKSPACE}/.claude/.substrate-manifest" ]; then
    echo "apply.sh: error: user-tier workspace missing .claude/.substrate-manifest; re-run install.sh --target user to deploy the manifest, then re-run apply.sh." >&2
    exit 2
  fi
fi

# ----- assemble the file list to apply ---------------------------------------

if [ "$ALL_DIFFERING" -eq 1 ]; then
  if [ "${#FILES[@]}" -gt 0 ]; then
    echo "apply.sh: error: --all-differing and --files are mutually exclusive" >&2
    exit 2
  fi
  # Run check.sh against the workspace and harvest deployed-paths from its output.
  # The DRIFTED block prints lines like "  - <path>  (delta)" — extract the path.
  check_out="$("${SCRIPT_DIR}/check.sh" --workspace "$WORKSPACE" 2>/dev/null || true)"
  while IFS= read -r line; do
    case "$line" in
      "  - "*)
        # Strip leading "  - ", then strip trailing whitespace/parenthesized delta.
        path="${line#  - }"
        path="${path%%  *}"
        path="${path%%[[:space:]]*}"
        if [ -n "$path" ]; then
          FILES+=("$path")
        fi
        ;;
    esac
  done <<< "$check_out"
  if [ "${#FILES[@]}" -eq 0 ]; then
    echo "apply.sh: nothing to apply (no DIFFERS files in check.sh output)."
    exit 0
  fi
fi

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "apply.sh: error: pass --files <path> [--files <path>...] or --all-differing" >&2
  exit 2
fi

# ----- pre-deploy snapshot (git path or backup-dir fallback) -----------------

USE_GIT="$(git_path_active "$WORKSPACE")"
BACKUP_DIR=""

if [ "$USE_GIT" -eq 1 ]; then
  uncommitted="$(git_uncommitted_claude "$WORKSPACE")"
  if [ -n "$uncommitted" ]; then
    if [ "$ASSUME_YES" -eq 1 ]; then
      echo "apply.sh: auto-committing pre-existing .claude/ state before apply (--yes):"
      echo "$uncommitted" | sed 's/^/  /'
      git -C "$WORKSPACE" add .claude
      git -C "$WORKSPACE" commit -m "chore(substrate): commit pre-existing .claude/ state before substrate-update apply" >/dev/null
    else
      echo "apply.sh: refusing to apply; uncommitted .claude/ state in workspace:" >&2
      echo "$uncommitted" | sed 's/^/  /' >&2
      echo "" >&2
      echo "  Commit or stash the changes first, or re-run with --yes to auto-commit." >&2
      exit 1
    fi
  fi
else
  # Backup-dir fallback.
  ts="$(date -u +%Y-%m-%dT%H%M%SZ)"
  BACKUP_DIR="${WORKSPACE}/.claude/.substrate-backups/${ts}"
  if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
    echo "apply.sh: error: could not create backup dir: $BACKUP_DIR" >&2
    exit 2
  fi
  echo "apply.sh: backup dir: $BACKUP_DIR"
fi

# ----- per-file walk ---------------------------------------------------------

applied_files=()
applied_role_files=()
applied_role_deltas=()

for dep in "${FILES[@]}"; do
  # CITE: explicit refusal at custom-path patterns. Substrate tools never
  # touch custom files (substrate/operating-disciplines.md §23 + substrate/
  # MAJOR_POLYBIUS.md §17). check.sh's --all-differing harvester already
  # filters these out (D4); this guard catches the direct --files <path>
  # surface where an operator could pass a custom-path file explicitly.
  # Refusal (not skip) because the operator's stated intent — "apply this
  # file" — is mismatched against the convention; a silent skip would mislead.
  case "$dep" in
    .claude/agents/custom/*|\
    .claude/skills/custom-*|\
    .claude/templates/custom/*)
      echo "apply.sh: refusing to apply to custom-path file (substrate tools never touch custom — see substrate/operating-disciplines.md §23): $dep" >&2
      continue
      ;;
  esac
  src_rel="$(source_path_for_deployed "$dep" "$TIER" "$SLUG")"
  if [ -z "$src_rel" ]; then
    echo "apply.sh: skipping (not a substrate-derived path): $dep"
    continue
  fi
  src_abs="${SUBSTRATE_DIR}/${src_rel}"
  if [ ! -f "$src_abs" ]; then
    echo "apply.sh: skipping (substrate source missing): $src_rel"
    continue
  fi
  dep_abs="${WORKSPACE}/${dep}"

  # Build the substituted source content into a tempfile so we can diff and copy.
  # Arc 38 (bj5; A8): manifest-driven substitution; falls back to legacy
  # apply_substitutions when the workspace has no manifest (project-tier
  # pre-Arc-38 behavior preserved).
  tmp_src="$(mktemp)"
  apply_substitutions_from_manifest "$src_abs" "$dep" "$WORKSPACE" > "$tmp_src"

  # Optional consent prompt + diff display.
  if [ "$ASSUME_YES" -eq 0 ]; then
    deployed_disp="$dep_abs"
    [ -f "$dep_abs" ] || deployed_disp="(file does not exist on disk yet)"
    echo
    echo "File: $dep"
    echo "Deployed: $deployed_disp"
    echo
    echo "Diff (deployed -> current substrate, after expected substitutions):"
    if [ -f "$dep_abs" ]; then
      diff_full="$(diff -u "$dep_abs" "$tmp_src" 2>/dev/null || true)"
    else
      diff_full="$(diff -u /dev/null "$tmp_src" 2>/dev/null || true)"
    fi
    if [ -z "$diff_full" ]; then
      echo "  (no diff — files are byte-equal; skipping)"
      rm -f "$tmp_src"
      continue
    fi
    diff_lines=$(printf '%s\n' "$diff_full" | wc -l | tr -d ' ')
    if [ "$diff_lines" -gt "$DIFF_TRUNCATE_LINES" ]; then
      printf '%s\n' "$diff_full" | head -"$DIFF_TRUNCATE_LINES"
      echo "  ... [truncated; ${diff_lines} lines total]"
    else
      printf '%s\n' "$diff_full"
    fi
    while :; do
      printf "Apply? [y/N/show-full-diff/skip-rest] "
      if ! read -r answer </dev/tty; then
        answer="N"
      fi
      case "$answer" in
        y|Y|yes) break ;;
        ""|n|N|no) echo "  skipped: $dep"; rm -f "$tmp_src"; continue 2 ;;
        show-full-diff|f|F)
          printf '%s\n' "$diff_full"
          ;;
        skip-rest|q|Q)
          echo "  skipping remaining files."
          rm -f "$tmp_src"
          break 2
          ;;
        *) echo "  unrecognized: $answer" ;;
      esac
    done
  fi

  # Compute pre/post role-file delta BEFORE the write so we can emit the
  # running-agent warning summary.
  is_role="$(is_role_file "$dep")"
  added_lines=0
  deleted_lines=0
  if [ "$is_role" -eq 1 ] && [ -f "$dep_abs" ]; then
    # diff -u output: lines starting with + (and not +++) are additions, with - (not ---) are deletions.
    while IFS= read -r dl; do
      case "$dl" in
        +++*|---*) : ;;
        +*) added_lines=$((added_lines + 1)) ;;
        -*) deleted_lines=$((deleted_lines + 1)) ;;
      esac
    done < <(diff -u "$dep_abs" "$tmp_src" 2>/dev/null || true)
  elif [ "$is_role" -eq 1 ]; then
    # File didn't exist; everything is "added".
    added_lines=$(wc -l < "$tmp_src" | tr -d ' ')
  fi
  total_role_delta=$((added_lines + deleted_lines))

  # Perform the snapshot + write.
  if [ "$USE_GIT" -eq 0 ] && [ -f "$dep_abs" ]; then
    # Backup-dir fallback: copy old file to backup tree, preserving relative path.
    backup_target="${BACKUP_DIR}/${dep}"
    mkdir -p "$(dirname "$backup_target")"
    cp "$dep_abs" "$backup_target"
  fi
  mkdir -p "$(dirname "$dep_abs")"
  cp "$tmp_src" "$dep_abs"
  rm -f "$tmp_src"
  echo "applied: $dep"

  applied_files+=("$dep")
  if [ "$is_role" -eq 1 ]; then
    applied_role_files+=("$dep")
    applied_role_deltas+=("$total_role_delta")
  fi
done

# ----- git commit (only the apply step itself) -------------------------------

if [ "$USE_GIT" -eq 1 ] && [ "${#applied_files[@]}" -gt 0 ]; then
  uncommitted_after="$(git_uncommitted_claude "$WORKSPACE")"
  if [ -n "$uncommitted_after" ]; then
    head_short="$(git -C "$SUBSTRATE_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    file_list="$(printf '%s, ' "${applied_files[@]}")"
    file_list="${file_list%, }"
    git -C "$WORKSPACE" add .claude
    git -C "$WORKSPACE" commit -m "chore(substrate): apply substrate updates from the-stoa ${head_short}: ${file_list}" >/dev/null
    echo
    echo "committed: chore(substrate): apply substrate updates from the-stoa ${head_short}"
  fi
fi

# ----- running-agent warning tail (only if any role file was applied) --------

if [ "${#applied_role_files[@]}" -gt 0 ]; then
  # Find the maximum role-file diff size to decide substantive-vs-minor framing.
  max_delta=0
  has_substantive=0
  for d in "${applied_role_deltas[@]}"; do
    if [ "$d" -gt "$max_delta" ]; then max_delta="$d"; fi
    if [ "$d" -gt 50 ]; then has_substantive=1; fi
  done

  echo
  echo "========================================"
  echo "  SUBSTRATE UPDATE APPLIED"
  echo "========================================"
  echo
  if [ "$has_substantive" -eq 1 ]; then
    echo "Role files updated:"
    for ((i=0; i<${#applied_role_files[@]}; i++)); do
      d="${applied_role_deltas[$i]}"
      if [ "$d" -gt 50 ]; then
        echo "  - ${applied_role_files[$i]} (substantive change: ${d} lines, /clear recommended)"
      else
        echo "  - ${applied_role_files[$i]} (minor change: ${d} lines)"
      fi
    done
    echo
    echo "Currently-running agent sessions are operating on the role files they loaded"
    echo "at activation. They will continue working as before — their behavior is"
    echo "in-context, not file-bound — until /clear or a new session."
    echo
    echo "Recommendation: when you reach a natural break, /clear the running POLYBIUS"
    echo "session and re-paste activation. The new role file's behavior takes effect"
    echo "on the next session. PLINY sessions inherit the same pattern."
    echo
    echo "(For minor changes you can ignore — running sessions continue per their loaded"
    echo "behavior, and the change takes effect organically on the next role-activation.)"
  else
    echo "Role files updated (minor changes only):"
    for ((i=0; i<${#applied_role_files[@]}; i++)); do
      echo "  - ${applied_role_files[$i]} (${applied_role_deltas[$i]} lines changed)"
    done
    echo
    echo "Currently-running agent sessions are operating on the role files they loaded"
    echo "at activation. They will continue working as before — their behavior is"
    echo "in-context, not file-bound — until /clear or a new session."
    echo
    echo "For minor changes, you can let the running sessions continue per their loaded"
    echo "behavior; the change takes effect organically on the next role-activation."
    echo
    echo "(Larger role-file changes would surface a stronger /clear recommendation.)"
  fi
fi

exit 0
