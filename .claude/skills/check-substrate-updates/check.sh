#!/usr/bin/env bash
#
# check.sh — substrate-update full-picture drift detection.
#
# Reads substrate/consumer-workspaces.txt (or one workspace passed via
# --workspace), and for each registered workspace emits a composite verdict
# across three orthogonal categories: DRIFTED (deployed file differs from
# source-after-substitutions), MISSING (source-side file not present at its
# expected deployed path — typically a substrate addition the workspace hasn't
# picked up), and OBSOLETE (workspace file at a substrate-deployable path no
# longer in source — typically a removed or renamed skill / CAPTAIN). Verdicts
# compose (e.g. "DRIFTED + MISSING + OBSOLETE"). Per-category file lines use
# distinct prefixes (- drifted, + missing, ! obsolete) so apply.sh's
# --all-differing harvester only ever picks up DRIFTED. A per-workspace
# uncommitted-.claude/-state count is surfaced separately as a pre-flight
# warning before any apply.sh --yes invocation. Routing footer is
# per-category-conditional and tier-branched (project / subproject). The skill
# does NOT classify *why* a file drifted (local edit vs upstream advance vs
# both) — PRINCIPAL memory + the workspace's git history of .claude/ remains
# canonical for that.
#
# Usage:
#   check.sh                              # scan all workspaces in registry
#   check.sh --workspace <path>           # scan a single workspace
#   check.sh --registry <path>            # use a non-default registry file
#
# Output: human-readable per-workspace summary; exit code is always 0 on
# successful execution. Drift is informational, not failure.

set -euo pipefail

# ----- locate substrate (this script lives in <substrate>/skills/check-substrate-updates/) ---

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBSTRATE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEFAULT_REGISTRY="${SUBSTRATE_DIR}/consumer-workspaces.txt"

# ----- argument parsing ------------------------------------------------------

WORKSPACE_OVERRIDE=""
REGISTRY="$DEFAULT_REGISTRY"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace)
      [ "$#" -ge 2 ] || { echo "check.sh: error: --workspace requires a path" >&2; exit 2; }
      WORKSPACE_OVERRIDE="$2"
      shift 2
      ;;
    --registry)
      [ "$#" -ge 2 ] || { echo "check.sh: error: --registry requires a path" >&2; exit 2; }
      REGISTRY="$2"
      shift 2
      ;;
    -h|--help)
      # Sed range closes on the line ending "not failure." (the last line of
      # the head-of-file comment block above). Don't end-pattern on a fragment
      # that appears mid-line — sed -n /<start>/,/<end>/p only closes when the
      # END pattern matches a whole line, otherwise it prints to EOF.
      sed -n '/^# check\.sh/,/^# .*not failure\.$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "check.sh: error: unknown argument: $1 (try --help)" >&2
      exit 2
      ;;
  esac
done

# ----- helpers ---------------------------------------------------------------
#
# Arc 26: the hand-maintained CAPTAIN_NAMES / TEMPLATE_NAMES / SKILL_NAMES
# mirrors that used to live here were removed. Source-of-truth enumeration is
# now derived live from the substrate dir on every run — CAPTAINs and
# templates via globs against substrate/, skills via parse_skill_names_from_install
# (which parses install.sh:198-208's SKILL_NAMES array). The mirror approach
# silently drifted in Arc 25 (credential-discipline was added to install.sh
# but not to the local SKILL_NAMES mirror) — the exact failure mode Arc 26
# closes for the operator-side equivalent. See design-rev2.md §2.2 / §2.4 for
# the full rationale.

# normalize_lf: read stdin, strip \r before \n. Used on both deployed and
# source-after-substitutions sides before byte-compare so checkout-on-Windows
# CRLF doesn't false-positive as drift.
normalize_lf() {
  tr -d '\r'
}

# apply_substitutions <source-file> <deployed-rel-path> <tier> <slug>
#
# Mirrors install.sh substitutions (lines ~613–617 + ~658 in install.sh as of c37cf5a).
# If install.sh adds a new {{...}} placeholder, this function must be updated to match.
#
# Substitutions are FILE-CLASS-SCOPED — install.sh only sed-substitutes the MAJOR
# and CAPTAIN files; templates and skills are deployed verbatim via `cp` / `cp -R`
# (install.sh ~lines 681, 711). Templates and skills MUST NOT be substituted at
# check time, otherwise prose that documents the placeholder (e.g., consent-prompts.md
# referencing `{{NAME_SUFFIX}}`) creates false-positive drift. See design §2.4 table.
#
# Substitution policy by deployed-relative path:
#   .claude/MAJOR_*.md              : NAME_SUFFIX (and USER_TIER_DIR at user-tier; out of v0 scope)
#   .claude/agents/CAPTAIN_*.md     : NAME_SUFFIX
#   everything else                 : verbatim passthrough (no sed)
#
# Reads the source file, writes (substituted-or-verbatim) content to stdout.
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
      # Same sed shape install.sh uses; the '|' delimiter for USER_TIER_DIR is
      # documented but USER_TIER_DIR substitution at user-tier is out of v0 scope
      # (see SKILL.md / design §10.2).
      sed "s/{{NAME_SUFFIX}}/${name_suffix}/g" "$source_file"
      ;;
    *)
      # Templates and skills (and any future verbatim-deployed file class) — no substitution.
      cat "$source_file"
      ;;
  esac
}

# apply_substitutions_from_manifest <source-file> <deployed-rel-path> <workspace-abs>
#
# CITE: manifest-driven substitution per Arc 38 / bj5 / design.md §2.2 (A8 γ pick).
# The manifest at <workspace>/.substrate-manifest is written by install.sh at deploy
# time (substrate/install.sh write_substrate_manifest function). Format invariant:
# tab-separated <dep-rel-path>\t<token>\t<replacement>; header block carries
# tier + deployed_at + substrate_sha. If a future install.sh change rotates the
# manifest format, this function must update its parser to match. Companion cite
# at the install.sh writer site references this read-site for the format
# invariant.
#
# Fallback path: when no manifest is present at the workspace (e.g., a project-tier
# workspace deployed before Arc 38 shipped), this function calls back to the
# legacy apply_substitutions() — preserving pre-Arc-38 project-tier behavior.
apply_substitutions_from_manifest() {
  local source_file="$1"
  local dep_rel="$2"
  local ws_abs="$3"
  # Manifest lives at <workspace>/.claude/.substrate-manifest where workspace is the
  # PARENT of .claude/ (project-tier convention; check.sh normalizes user-tier
  # ws_abs to drop trailing /.claude so the same path-construction works).
  local manifest="${ws_abs}/.claude/.substrate-manifest"

  if [ ! -f "$manifest" ]; then
    # No manifest — fall back to legacy hard-coded substitution. detect_tier
    # echoes "<tier> <slug>" (space-separated; slug may be empty).
    local tier_line tier slug
    tier_line="$(detect_tier "$ws_abs")"
    tier="${tier_line%% *}"
    slug="${tier_line#* }"; slug="${slug# }"
    apply_substitutions "$source_file" "$dep_rel" "$tier" "$slug"
    return 0
  fi

  # CITE: format-version contract per Arc 40 / stoa--6n9. Header-scan rejects
  # any manifest declaring a format-version this reader does not understand.
  # If no `# format=` line is present (e.g., a manifest written by a pre-fix
  # install.sh), treat as v1 (graceful fallback for already-deployed
  # workspaces). Companion write-site: substrate/install.sh
  # write_substrate_manifest. Any install.sh that bumps v1->v2 MUST update
  # this parser in the same arc.
  local manifest_format
  manifest_format="$(grep -E '^# format=v[0-9]+' "$manifest" 2>/dev/null | head -1 | sed -E 's/^# format=(v[0-9]+).*/\1/')"
  if [ -n "$manifest_format" ] && [ "$manifest_format" != "v1" ]; then
    echo "check.sh: error: ${manifest} format=${manifest_format} unknown; this check.sh expects v1. Re-run install.sh to re-deploy with a matching manifest, or update the check-substrate-updates skill." >&2
    return 1
  fi

  # Manifest present — read every (token, replacement) entry for this deployed-rel-path
  # and apply them via a sed pipeline built as an array of -e expressions. Use | as
  # sed delimiter (avoid / collision with filesystem paths in USER_TIER_DIR
  # replacement values). Array-form avoids the eval-pipe-interpretation bug where
  # | inside the s|X|Y|g expressions would be read as a shell pipe by the eval shell.
  local sed_args=()
  local entry_path token replacement
  while IFS=$'\t' read -r entry_path token replacement; do
    # Skip comments + blanks
    case "$entry_path" in
      ""|\#*) continue ;;
    esac
    if [ "$entry_path" = "$dep_rel" ]; then
      # Defensive: refuse to substitute if either token or replacement contains | literal.
      # install.sh's writer rejects these at write time; this is a belt-and-suspenders check.
      case "$token$replacement" in
        *"|"*) continue ;;
      esac
      # Escape sed metacharacters in the replacement value before splicing it
      # into the s|...|...|g expression. Two-step (order matters):
      #   1. backslash '\' → '\\' (so any pre-existing '\' is literalized)
      #   2. ampersand '&' → '\&' (so '&' is read as literal, not "matched pattern")
      # Without step 2, a future manifest entry whose replacement contains '&'
      # would silently mangle the substitution: sed reads bare '&' in the RHS
      # of s|...|...| as a back-reference to the entire matched pattern.
      # install.sh's current writers (Arc 38 baseline) emit only {{NAME_SUFFIX}}
      # and {{USER_TIER_DIR}} replacements (neither contains '&' in any
      # plausible deploy), so the in-tree symptom is latent — but the reader
      # must always be safe. Per CATO Arc 38 rev1 c2 finding (defensive
      # read-site escape; writer may extend later). Cross-ref:
      # agents/design/stoa--ojz/design.md §2.2.
      replacement="${replacement//\\/\\\\}"
      replacement="${replacement//&/\\&}"
      sed_args+=(-e "s|${token}|${replacement}|g")
    fi
  done < "$manifest"

  if [ "${#sed_args[@]}" -eq 0 ]; then
    # No substitution entries for this file — verbatim passthrough.
    cat "$source_file"
  else
    sed "${sed_args[@]}" "$source_file"
  fi
}

# parse_skill_names_from_install: echo one skill name per line.
# Reads substrate/install.sh and extracts the SKILL_NAMES=(...) array contents.
#
# CITE: parses install.sh:198-208 (SKILL_NAMES array, multi-line form). If
# install.sh changes the array name, moves to a single-line / non-parenthesized
# form, or uses += append syntax, this function must update its awk expression
# to match. Cite mirror of the apply_substitutions() pattern above (cite-at-
# the-read-site is the durable mitigation for source-side coupling — see
# design-rev2.md §3 cite-comment policy).
#
# FAILURE-MODE SYMPTOM (rev2 P1-1, per ARGUS): if this awk returns empty for a
# substrate that has skills (i.e. install.sh:198 region exists but stdout is
# empty), the parser is broken and the run is UNTRUSTWORTHY — every MISSING
# and OBSOLETE result will be wrong. MISSING will under-report (nothing
# enumerated → nothing can be "missing"). OBSOLETE will over-report any
# deployed skill directory as "no longer in source" (the deployed-side glob
# sees the skill dir, the source-side parser returns empty, so the skill is
# classified as not-substrate-derived). The pre-Arc-26 hand-maintained
# SKILL_NAMES mirror (in the rationale block immediately above this function)
# silently drifted in Arc 25 — credential-discipline was added to install.sh
# but not to the mirror — and the bug only surfaced at apply-time, never at
# any check.sh run between. This live-parse closes that drift surface but
# substitutes a parsing-correctness surface. The cite is the durable
# mitigation; VERA Probe 5 (CURRENT regression on the three live workspaces)
# is the runtime smoke for it.
parse_skill_names_from_install() {
  local install_sh="${SUBSTRATE_DIR}/install.sh"
  [ -f "$install_sh" ] || return 1
  # awk: print every line strictly between 'SKILL_NAMES=(' and the next ')',
  # stripping whitespace and skipping blanks/comments.
  awk '
    /^SKILL_NAMES=\(/ { in_arr = 1; next }
    in_arr && /^\)/   { in_arr = 0; next }
    in_arr            {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      if ($0 == "" || $0 ~ /^#/) next
      print
    }
  ' "$install_sh"
}

# source_path_for_deployed <deployed-relative-path> <tier> <slug>
#
# Maps a workspace-relative path under .claude/ to a substrate-relative path
# under substrate/. Returns empty string if the deployed path doesn't map to
# any known substrate source (e.g. a pair-programmer MAJOR PRINCIPAL added).
#
# Examples:
#   .claude/MAJOR_POLYBIUS.md            -> MAJOR_POLYBIUS.md
#   .claude/MAJOR_PLINY_my_proj.md       -> MAJOR_PLINY.md  (subproject suffix stripped)
#   .claude/operating-disciplines.md     -> operating-disciplines.md
#   .claude/agents/CAPTAIN_ADA.md        -> CAPTAIN_ADA.md
#   .claude/agents/CAPTAIN_ADA_my_proj.md-> CAPTAIN_ADA.md  (suffix stripped)
#   .claude/templates/<name>.md          -> templates/<name>.md
#   .claude/skills/<name>/<file>         -> skills/<name>/<file>
source_path_for_deployed() {
  local dep="$1"
  local tier="$2"
  local slug="$3"
  local suffix=""

  case "$tier" in
    project|subproject) suffix="_${slug}" ;;
  esac

  # Strip .claude/ prefix (paths come in as deployed-relative under .claude/).
  local rel="${dep#.claude/}"

  case "$rel" in
    operating-disciplines.md)
      echo "operating-disciplines.md"
      ;;
    MAJOR_*.md)
      # Any deployed MAJOR maps back to its unsuffixed source name. Strip the
      # subproject suffix (present only at subproject tier) before reattaching .md.
      # MAJOR suffix rule: suffixed at subproject ONLY. ${suffix} is _${slug} for
      # project|subproject, but MAJORs are unsuffixed at project, so only strip
      # when tier=subproject. The deployed name's own suffix, if any, is what we strip.
      # Ordered AFTER operating-disciplines.md so it cannot shadow that arm.
      local mbase="${rel%.md}"            # "MAJOR_POLYBIUS_acme" or "MAJOR_POLYBIUS"
      if [ "$tier" = "subproject" ] && [ -n "$suffix" ]; then
        mbase="${mbase%${suffix}}"        # strip "_acme" -> "MAJOR_POLYBIUS"
      fi
      echo "${mbase}.md"
      ;;
    agents/CAPTAIN_*.md)
      # Extract mnemonic between CAPTAIN_ and ${suffix}.md (or .md for unsuffixed).
      local base="${rel#agents/CAPTAIN_}"
      if [ -n "$suffix" ]; then
        base="${base%${suffix}.md}"
      else
        base="${base%.md}"
      fi
      echo "CAPTAIN_${base}.md"
      ;;
    templates/*)
      echo "$rel"
      ;;
    skills/*)
      echo "$rel"
      ;;
    *)
      # Unknown deployed path — not substrate-derived.
      echo ""
      ;;
  esac
}

# detect_tier <workspace-abs-path>
#
# Echoes "<tier> <slug>" (space-separated) on stdout.
# Possible tiers: user, subproject, project, none
# Slug is empty for user and none tiers.
detect_tier() {
  local ws="$1"
  local ws_abs
  # Resolve to absolute path; on Windows MSYS / git-bash, $(cd && pwd) gives a
  # POSIX-shaped path which is what we want.
  if [ ! -d "$ws" ]; then
    echo "none "
    return 0
  fi
  ws_abs="$(cd "$ws" && pwd)"

  # User-tier: workspace IS ~/.claude (path resolves to $HOME/.claude). Out of
  # v0 scope but detected so we can surface a friendly message.
  if [ "$ws_abs" = "${HOME}/.claude" ] || [ "$ws_abs" = "${HOME}" ]; then
    echo "user "
    return 0
  fi

  if [ ! -d "${ws_abs}/.claude" ]; then
    echo "none "
    return 0
  fi

  # Subproject-tier: any MAJOR_POLYBIUS_<slug>.md present.
  local p
  for p in "${ws_abs}/.claude/MAJOR_POLYBIUS_"*.md; do
    if [ -f "$p" ]; then
      local base
      base="$(basename "$p")"
      # Strip MAJOR_POLYBIUS_ prefix and .md suffix.
      local slug="${base#MAJOR_POLYBIUS_}"
      slug="${slug%.md}"
      echo "subproject ${slug}"
      return 0
    fi
  done

  # Project-tier: unsuffixed MAJOR_POLYBIUS.md present.
  if [ -f "${ws_abs}/.claude/MAJOR_POLYBIUS.md" ]; then
    local slug
    slug="$(basename "$ws_abs" | tr '.-' '__')"
    echo "project ${slug}"
    return 0
  fi

  echo "none "
}

# enumerate_deployed <workspace-abs> <tier> <slug>
# Echoes one deployed-relative path per line for every file we expect to find
# at standard substrate-deploy locations. Existence is checked by the caller.
#
# Arc 26: source-side enumeration is fully live — CAPTAINs and templates are
# glob-derived from substrate/, skills are derived from
# parse_skill_names_from_install (which parses install.sh:198-208). No
# hand-maintained mirrors. The source-side set returned here IS the live
# ground truth; if parse_skill_names_from_install ever returns empty for a
# substrate that has skills, the parser is broken and the whole run is
# untrustworthy (see cite-comment on that function and design-rev2.md §2.3 /
# §4.6.3).
enumerate_deployed() {
  local ws="$1"
  local tier="$2"
  local slug="$3"
  local suffix=""

  case "$tier" in
    project|subproject) suffix="_${slug}" ;;
  esac

  # MAJOR files: glob substrate/MAJOR_*.md so any future MAJOR (CHIRON, HAMILTON, ...)
  # auto-discovers. MAJOR suffix rule (DIFFERENT from CAPTAINs): suffixed at
  # subproject tier ONLY; project + user tiers carry no suffix. Mirror of the
  # CAPTAIN glob below, but the MAJOR-suffix conditional replaces the CAPTAIN
  # ${suffix}. install.sh SUFFIX_MAJORS governs the same rule at deploy time.
  local majf maj_base major_suffix="" maj_count=0
  [ "$tier" = "subproject" ] && major_suffix="${suffix}"
  shopt -s nullglob
  for majf in "${SUBSTRATE_DIR}/MAJOR_"*.md; do
    maj_base="$(basename "$majf" .md)"   # "MAJOR_POLYBIUS"
    echo ".claude/${maj_base}${major_suffix}.md"
    maj_count=$((maj_count + 1))
  done
  shopt -u nullglob
  if [ "$maj_count" -eq 0 ]; then
    # FAIL-LOUD (stoa--3nh). PROCESS-SUB SITE: enumerate_deployed is consumed at
    # the caller via `< <(enumerate_deployed ...)`, so a bare `exit 2` HERE runs
    # in the process-sub subshell and does NOT abort the parent — the caller's
    # read loop reaches after-loop with rc=0 and a truncated enumeration, the
    # exact false-OBSOLETE hazard. So emit a SENTINEL as the SOLE output line and
    # return; the Pass-1 caller checks for it after the read loop and aborts in
    # check.sh main scope (where exit propagates). The MAJOR glob is FIRST in
    # enumerate_deployed, so on an empty glob nothing else is emitted (no
    # operating-disciplines/CAPTAINs/templates/skills) — a partial enumeration is
    # exactly what we refuse to hand the caller.
    printf '%s\n' '__SUBSTRATE_ENUM_ABORT__'
    return 0
  fi

  echo ".claude/operating-disciplines.md"

  # CAPTAINs: glob substrate/CAPTAIN_*.md. Suffixed at project/subproject,
  # unsuffixed at user. Replaces the dropped CAPTAIN_NAMES mirror.
  local capf cap_base
  shopt -s nullglob
  for capf in "${SUBSTRATE_DIR}/CAPTAIN_"*.md; do
    cap_base="$(basename "$capf" .md)"   # "CAPTAIN_DAEDALUS"
    cap_base="${cap_base#CAPTAIN_}"      # "DAEDALUS"
    echo ".claude/agents/CAPTAIN_${cap_base}${suffix}.md"
  done
  shopt -u nullglob

  # Templates (unsuffixed at all tiers): glob substrate/templates/*. Replaces
  # the dropped TEMPLATE_NAMES mirror.
  local tplf
  shopt -s nullglob
  for tplf in "${SUBSTRATE_DIR}/templates/"*; do
    [ -f "$tplf" ] || continue
    echo ".claude/templates/$(basename "$tplf")"
  done
  shopt -u nullglob

  # Skills: enumerate every file under each skill subtree in the source.
  # Skill names come from parse_skill_names_from_install (live-parsed from
  # install.sh:198-208); the find-walk inside each named dir is source-side
  # enumeration of per-skill files.
  local sn rel f
  while IFS= read -r sn; do
    [ -n "$sn" ] || continue
    if [ -d "${SUBSTRATE_DIR}/skills/${sn}" ]; then
      while IFS= read -r f; do
        rel="${f#${SUBSTRATE_DIR}/}"
        echo ".claude/${rel}"
      done < <(find "${SUBSTRATE_DIR}/skills/${sn}" -type f)
    fi
  done < <(parse_skill_names_from_install)
}

# enumerate_workspace_substrate_paths <workspace-abs> <tier> <slug>
# Echoes one deployed-relative path per line for every workspace file at a
# substrate-deployable path. Used by Pass 2 of check_workspace (OBSOLETE
# detection). Skills are emitted at directory level (per directive A4);
# other categories at file level.
#
# Files explicitly NOT enumerated (per directive A4):
#   - .claude/.substrate-last-check         transient state file
#   - .claude/.substrate-backups/...        apply.sh's backup tree
#   - HUMAN_*.md                            user-added instruction files
#   - .claude/agents/* not matching CAPTAIN_*.md  user-added pair-programmer agents
#   - loose files directly under .claude/skills/  not deployed by install.sh
#
# Important precedent: install.sh's prune logic (see the install.sh '--prune-obsolete' comment block + the 'pair-programmer Majors land in the same agents/' note, ~install.sh:92-93)
# deliberately excludes MAJOR_*.md from obsolete detection (pair-programmer
# MAJOR ambiguity). Directive A4 nonetheless specifies .claude/MAJOR_*.md is
# in scope for check.sh's OBSOLETE detection — a deliberate divergence
# (check.sh is informational; install.sh's prune is destructive). The
# asymmetry surfaces to the operator via the split routing footer in
# check_workspace (MAJOR_*.md OBSOLETE entries route to a manual-rm footer,
# not to install.sh --prune-obsolete which would silently no-op).
enumerate_workspace_substrate_paths() {
  local ws="$1"
  local tier="$2"
  local slug="$3"
  local suffix=""

  case "$tier" in
    project|subproject) suffix="_${slug}" ;;
  esac

  local f
  shopt -s nullglob
  # MAJORs: glob workspace dir. Per A4 these ARE in scope for OBSOLETE
  # detection (asymmetry with install.sh's prune-scope, which excludes
  # MAJORs — surfaced to operator via split routing footer).
  #
  # CITE: MAJOR glob is single-path-segment by design — matches MAJOR_*.md
  # directly under .claude/ but NOT files at .claude/custom/MAJOR_*.md (a
  # hypothetical future custom-MAJOR path). Custom MAJORs are OUT OF SCOPE
  # per Arc 29 A7 hard-lock — the base-vs-custom convention
  # (substrate/operating-disciplines.md §23 + substrate/MAJOR_POLYBIUS.md §17)
  # applies to CAPTAINs + skills + templates only; the POLYBIUS/PLINY
  # orchestrator tier is deferred to a future arc. If a future arc adds
  # custom MAJOR support, this glob site needs the same case-skip treatment
  # as the CAPTAIN site below (the .claude/agents/custom/ subdirectory
  # convention) — adapted to whatever custom-MAJOR path the future arc picks.
  # The cite is forward-looking; the glob itself is correct as written and
  # needs no change in this arc.
  for f in "${ws}/.claude/MAJOR_"*.md; do
    echo ".claude/$(basename "$f")"
  done
  if [ -f "${ws}/.claude/operating-disciplines.md" ]; then
    echo ".claude/operating-disciplines.md"
  fi

  # CAPTAINs: glob workspace dir.
  if [ -d "${ws}/.claude/agents" ]; then
    # CITE: this glob is single-path-segment (NOT recursive). It matches
    # CAPTAIN_*.md directly under .claude/agents/ but NOT files at
    # .claude/agents/custom/CAPTAIN_*.md (the custom convention path per
    # substrate/operating-disciplines.md §23 + substrate/MAJOR_POLYBIUS.md §17).
    # That non-recursion IS the base-vs-custom scoping for OBSOLETE detection.
    # If this glob is made recursive, custom CAPTAINs would surface as OBSOLETE
    # and the operator would be routed to --prune-obsolete (which D3 already
    # scopes to base, so no actual deletion would occur — but the false OBSOLETE
    # flag would mislead). The discipline is path-shape, defense at every read site.
    for f in "${ws}/.claude/agents/CAPTAIN_"*.md; do
      echo ".claude/agents/$(basename "$f")"
    done
  fi

  # Templates: glob workspace dir.
  if [ -d "${ws}/.claude/templates" ]; then
    # CITE: single-path-segment + file-only glob (the `[ -f ]` filter skips
    # directories, including .claude/templates/custom/ where custom templates
    # live per the base-vs-custom convention; see
    # substrate/operating-disciplines.md §23 + substrate/MAJOR_POLYBIUS.md §17.
    # If a future change recurses or removes the file-only filter, custom
    # templates would be flagged as OBSOLETE.
    for f in "${ws}/.claude/templates/"*; do
      [ -f "$f" ] || continue
      echo ".claude/templates/$(basename "$f")"
    done
  fi

  # Skills: directory-level (per A4).
  if [ -d "${ws}/.claude/skills" ]; then
    # CITE: skip workspace-owned custom skills per the base-vs-custom convention.
    # Custom skills use directory-name prefix `custom-` (forced by Claude Code's
    # single-level skill discovery — substrate/operating-disciplines.md §23 +
    # substrate/MAJOR_POLYBIUS.md §17). Substrate tools never see custom paths.
    # Without this case-skip, every custom skill in the workspace would be
    # classified as OBSOLETE on every check.sh run, polluting the verdict and
    # routing the operator to --prune-obsolete (which D3 also scopes correctly,
    # so no deletion — but the false OBSOLETE noise is the bug).
    local d base
    for d in "${ws}/.claude/skills/"*/; do
      base="$(basename "$d")"
      case "$base" in
        custom-*) continue ;;
      esac
      echo ".claude/skills/${base}/"
    done
  fi
  shopt -u nullglob

  # Suppress unused-var warning under set -u for tiers without suffix.
  : "$suffix"
}

# is_substrate_source_present <deployed-rel-path> <tier> <slug>
# Returns 0 if the substrate source backs this deployed path, 1 otherwise.
# For skills: present iff the skill name is in install.sh's SKILL_NAMES
# (live-parsed) — directory existence under substrate/skills/ is not
# sufficient (a skill on disk under substrate/skills/ but NOT in install.sh's
# SKILL_NAMES would be a substrate-internal inconsistency, but for OBSOLETE
# we treat "not in install.sh's SKILL_NAMES" as "not substrate-derived").
is_substrate_source_present() {
  local dep="$1"
  local tier="$2"
  local slug="$3"
  local rel="${dep#.claude/}"
  case "$rel" in
    skills/*)
      # Extract skill name (first path segment after skills/).
      local sname="${rel#skills/}"
      sname="${sname%%/*}"
      local known
      while IFS= read -r known; do
        # g38 item-3: name-match is necessary but not sufficient — require the
        # source dir to actually exist on disk too, symmetric with the default
        # branch's [ -e ] test below. A name in SKILL_NAMES whose source dir was
        # removed should NOT report as substrate-present.
        [ "$known" = "$sname" ] && [ -e "${SUBSTRATE_DIR}/skills/${sname}" ] && return 0
      done < <(parse_skill_names_from_install)
      return 1
      ;;
    *)
      local src_rel
      src_rel="$(source_path_for_deployed "$dep" "$tier" "$slug")"
      [ -n "$src_rel" ] && [ -e "${SUBSTRATE_DIR}/${src_rel}" ]
      ;;
  esac
}

# uncommitted_claude_count <workspace-abs>
# Echoes a non-negative integer (count of uncommitted .claude/ files,
# excluding .substrate-last-check) or the literal "unknown" if the workspace
# is not git-tracked or .claude/ is not under git.
#
# Per directive A5: workspace must be inside a git repo for this signal to
# work; otherwise informational "unknown" is returned, not blocking.
#
# Implementation note: uses `git status --porcelain | grep -v ... | wc -l`
# per directive A5 line 116 canonical form. `wc -l` returns 0 on empty input
# (it counts newlines), so no `|| echo 0` defang needed. `tr -d ' '` strips
# the leading whitespace BSD/GNU wc emits in some environments — same idiom
# as the line-count extraction in check_workspace (Pass 1). Safe under
# set -euo pipefail.
#
# Sibling-not-shared with apply.sh's git_uncommitted_claude (apply.sh:184-189)
# — apply.sh returns the file LIST (multi-line for display); check.sh needs
# only the COUNT (for the summary line). Inlined here per design-rev2.md §4.5.
uncommitted_claude_count() {
  local ws="$1"
  # Must be inside a git work tree.
  if ! git -C "$ws" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "unknown"
    return 0
  fi
  # .claude/ must be tracked or have any tracked files (consistent with
  # apply.sh's git_path_active helper at apply.sh:169-182).
  if ! git -C "$ws" ls-files .claude 2>/dev/null | grep -q .; then
    echo "unknown"
    return 0
  fi
  # Count porcelain lines, excluding .substrate-last-check. Per directive
  # A5; wc -l is empty-input-safe (returns 0).
  #
  # Defect-fix (ADA, post-design-rev2): `grep -v` exits 1 when NO lines are
  # selected (e.g. git status produces empty stdout, or the only output line
  # is .substrate-last-check itself). Under `set -euo pipefail` that
  # propagates to the pipeline exit and then to the calling command
  # substitution, killing the run. Defang with `|| true` on grep — the
  # downstream `wc -l` still correctly counts 0 lines on empty input, which
  # is the intended return value. Surfaced upward to PLINY in the verdict.
  git -C "$ws" status --porcelain -- .claude 2>/dev/null \
    | { grep -v '\.substrate-last-check$' || true; } \
    | wc -l \
    | tr -d ' '
}

# emit_uncommitted_warning_if_needed <count> <workspace-abs>
# If the uncommitted count is a positive integer, emit the directive-A6
# warning text. "unknown" and "0" are no-ops.
emit_uncommitted_warning_if_needed() {
  local count="$1"
  local ws_abs="$2"
  case "$count" in
    unknown|0) return 0 ;;
  esac
  # count >= 1 — emit warning per directive A6.
  echo
  printf "  WARNING: workspace has %s uncommitted .claude/ changes. apply.sh --yes\n" "$count"
  echo   "  will auto-commit-then-overwrite; preserve the local edits via git history."
  printf "  Inspect with: cd %s && git status --short .claude/\n" "$ws_abs"
}

# read_state_file <workspace-abs>
# Echoes "<last_check_timestamp>|<last_check_against_sha>" or empty if absent.
read_state_file() {
  local ws="$1"
  local sf="${ws}/.claude/.substrate-last-check"
  [ -f "$sf" ] || { echo ""; return 0; }
  local ts="" sha=""
  while IFS='=' read -r k v; do
    case "$k" in
      last_check_timestamp)   ts="$v" ;;
      last_check_against_sha) sha="$v" ;;
    esac
  done < "$sf"
  echo "${ts}|${sha}"
}

# write_state_file <workspace-abs> <sha>
write_state_file() {
  local ws="$1"
  local sha="$2"
  local sf="${ws}/.claude/.substrate-last-check"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  cat > "$sf" <<EOF
last_check_timestamp=${now}
last_check_against_sha=${sha}
EOF
}

# substrate_head_sha: short SHA of the substrate repo HEAD (or "unknown").
substrate_head_sha() {
  if git -C "$SUBSTRATE_DIR" rev-parse --short HEAD >/dev/null 2>&1; then
    git -C "$SUBSTRATE_DIR" rev-parse --short HEAD
  else
    echo "unknown"
  fi
}

# check_workspace <workspace-input>
# Runs the per-workspace check; prints the summary block; updates state file.
check_workspace() {
  local ws_in="$1"
  local ws_abs
  if [ ! -e "$ws_in" ]; then
    printf "%-40s NOT-FOUND (path does not exist: %s)\n" "$(basename "$ws_in")" "$ws_in"
    return 0
  fi
  ws_abs="$(cd "$ws_in" && pwd)"
  local label
  label="$(basename "$ws_abs")"

  # Tier detection.
  local tier_line tier slug
  tier_line="$(detect_tier "$ws_abs")"
  tier="${tier_line%% *}"
  slug="${tier_line#* }"
  slug="${slug# }"  # trim leading space if slug empty

  if [ "$tier" = "none" ]; then
    printf "%-40s NOT-STOA-DEPLOYED (no .claude/MAJOR_POLYBIUS*.md found)\n" "$label"
    return 0
  fi

  if [ "$tier" = "user" ]; then
    # CITE: Arc 38 (bj5; A8) — user-tier check via .substrate-manifest. The
    # manifest is written by install.sh at deploy time (substrate/install.sh
    # write_substrate_manifest). Fall back to the friendly out-of-scope message
    # if the manifest is absent (the workspace was deployed before Arc 38
    # shipped). Manifest present → proceed with normal Pass 1/2/3 logic; the
    # only changed call site is apply_substitutions -> apply_substitutions_from_manifest.
    #
    # NORMALIZE ws_abs to the PARENT of .claude/ so Pass 1/2/3 path
    # construction (which prepends .claude/ via enumerate_deployed +
    # enumerate_workspace_substrate_paths) matches project-tier shape. The
    # registry line MAY be either $HOME or $HOME/.claude — detect_tier accepts
    # both, but the rest of check.sh assumes <workspace>/.claude/<deployed-rel>
    # so we normalize away the trailing /.claude here. (Ground-check finding
    # during Arc 38 build: original design assumed Pass 1 worked transparently
    # at user-tier; in fact it constructed double-.claude/ paths until this
    # normalization landed. Documented in build verdict.)
    if [ "${ws_abs%/.claude}" != "$ws_abs" ]; then
      ws_abs="${ws_abs%/.claude}"
    fi
    local manifest="${ws_abs}/.claude/.substrate-manifest"
    if [ ! -f "$manifest" ]; then
      printf "%-40s USER-TIER (manifest missing — re-run install.sh --target user to deploy)\n" "$label"
      echo "  The Arc 38 bj5 extension uses a manifest at <workspace>/.claude/.substrate-manifest"
      echo "  to record substitutions applied by install.sh. The current deploy predates"
      echo "  the manifest. Re-run install.sh --target user to write the manifest, then"
      echo "  re-run check.sh."
      return 0
    fi
    # Manifest present — fall through to Pass 1/2/3 below.
  fi

  # ----- Pass 1: DRIFTED + MISSING ------------------------------------------
  #
  # Walk the source-side enumeration. For each expected-deployed path:
  #   - file absent at workspace -> MISSING (append to missing_files)
  #   - file present, source gone (racing-edit edge) -> OBSOLETE on the
  #     workspace side (partition by MAJOR vs prunable)
  #   - file present, byte-equal to source-after-substitutions -> CURRENT
  #   - file present, differs -> DRIFTED (with line-count delta)
  #
  # The source-side enumeration IS the live ground truth (design-rev2.md
  # §4.6.3 / §2.3 cite-comment): if parse_skill_names_from_install ever
  # returns empty for a substrate that has skills, the parser is broken and
  # the whole run is untrustworthy.
  local drifted_files=()           # was differs_files
  local drifted_deltas=()          # was differs_deltas
  local missing_files=()           # NEW (Arc 26)
  local obsolete_prunable_files=() # NEW: OBSOLETE routable to install.sh --prune-obsolete
  local obsolete_major_files=()    # NEW: OBSOLETE MAJOR_*.md (install.sh excludes from prune)
  local current_count=0
  local total=0

  local dep src_rel src_abs deployed_path
  local enum_aborted=0
  while IFS= read -r dep; do
    [ -n "$dep" ] || continue
    # FAIL-LOUD (stoa--3nh): enumerate_deployed emits this sentinel as its sole
    # line when the source MAJOR_*.md glob is empty. A bare exit inside the
    # process-sub would NOT abort us here; catch the sentinel and abort below in
    # this (check_workspace) scope, which is called directly from main so exit
    # propagates.
    if [ "$dep" = "__SUBSTRATE_ENUM_ABORT__" ]; then enum_aborted=1; break; fi
    total=$((total + 1))
    deployed_path="${ws_abs}/${dep}"
    if [ ! -f "$deployed_path" ]; then
      missing_files+=("$dep")
      continue
    fi
    src_rel="$(source_path_for_deployed "$dep" "$tier" "$slug")"
    if [ -z "$src_rel" ]; then
      # Unknown — shouldn't happen since enumerate_deployed only emits
      # substrate-derived paths. Skip defensively.
      continue
    fi
    src_abs="${SUBSTRATE_DIR}/${src_rel}"
    if [ ! -f "$src_abs" ]; then
      # Source file gone despite being enumerated as an expected deployed.
      # Under Arc 26's live-parsing enumeration this is now impossible for
      # skills (parser only emits names whose source exists) and very rare
      # for CAPTAINs/templates/MAJORs (enumerate_deployed globs the source
      # side directly). If it ever does happen (racing-edit during a
      # substrate-update), surface as OBSOLETE on the workspace side rather
      # than DRIFTED. Pass 2 dedup handles the cross-pass case.
      case "$dep" in
        .claude/MAJOR_*.md)
          obsolete_major_files+=("$dep") ;;
        *)
          obsolete_prunable_files+=("$dep") ;;
      esac
      continue
    fi

    # Byte-compare deployed (LF-normalized) to source-after-substitutions
    # (LF-normalized). Arc 38 (bj5; A8): manifest-driven substitution at user-tier
    # via apply_substitutions_from_manifest; project-tier + subproject-tier fall
    # through the same call (manifest may be present from a fresh install or
    # absent in which case the function delegates to legacy apply_substitutions).
    local dep_norm src_norm
    dep_norm="$(normalize_lf < "$deployed_path")"
    src_norm="$(apply_substitutions_from_manifest "$src_abs" "$dep" "$ws_abs" | normalize_lf)"

    if [ "$dep_norm" = "$src_norm" ]; then
      current_count=$((current_count + 1))
    else
      # Compute line-count delta (source - deployed).
      local dep_lines src_lines delta sign
      dep_lines="$(printf '%s' "$dep_norm" | wc -l | tr -d ' ')"
      src_lines="$(printf '%s' "$src_norm" | wc -l | tr -d ' ')"
      delta=$((src_lines - dep_lines))
      if [ "$delta" -ge 0 ]; then
        sign="+"
      else
        sign=""
      fi
      drifted_files+=("$dep")
      drifted_deltas+=("${sign}${delta} lines")
    fi
  done < <(enumerate_deployed "$ws_abs" "$tier" "$slug")
  if [ "$enum_aborted" -eq 1 ]; then
    # FAIL-LOUD (stoa--3nh): the sentinel fired — zero MAJOR_*.md globbed from the
    # source. The enumeration is untrustworthy (every MISSING/OBSOLETE result
    # downstream would be wrong), so refuse to continue. check_workspace is called
    # directly from main, so this exit aborts the run (rc=2) — NOT a silent
    # rc=0-with-truncated-enumeration.
    echo "check.sh: FATAL: zero MAJOR_*.md globbed from ${SUBSTRATE_DIR} — substrate checkout incomplete; enumeration is untrustworthy (every MISSING/OBSOLETE result would be wrong). Aborting." >&2
    exit 2
  fi

  # ----- Pass 2: OBSOLETE (with split routing) ------------------------------
  #
  # Walk the workspace-side enumeration; flag files at substrate-deployable
  # paths whose source is no longer present. Partition OBSOLETE entries into
  # MAJOR_*.md (manual-rm — install.sh excludes from prune) and everything
  # else (install.sh --prune-obsolete handles).
  local ws_dep already_obsolete of
  while IFS= read -r ws_dep; do
    [ -n "$ws_dep" ] || continue

    # Dedupe against any OBSOLETE entries Pass 1's racing-edit branch already
    # populated. Guarded against empty-array phantom-string iteration under
    # set -u (design-rev2.md P1-3).
    already_obsolete=0
    if [ "${#obsolete_prunable_files[@]}" -gt 0 ]; then
      for of in "${obsolete_prunable_files[@]}"; do
        [ "$of" = "$ws_dep" ] && { already_obsolete=1; break; }
      done
    fi
    if [ "$already_obsolete" -eq 0 ] && [ "${#obsolete_major_files[@]}" -gt 0 ]; then
      for of in "${obsolete_major_files[@]}"; do
        [ "$of" = "$ws_dep" ] && { already_obsolete=1; break; }
      done
    fi
    [ "$already_obsolete" -eq 1 ] && continue

    if ! is_substrate_source_present "$ws_dep" "$tier" "$slug"; then
      # Partition: MAJOR_*.md basenames go to manual-rm bucket; everything
      # else goes to install.sh --prune-obsolete bucket. install.sh (the 'pair-programmer Majors land in the same agents/' note + --prune-obsolete handling)
      # deliberately excludes MAJORs from prune (pair-programmer
      # MAJOR ambiguity); emitting install.sh --prune-obsolete for a
      # flagged-OBSOLETE MAJOR would silently no-op — actively misleading.
      case "$ws_dep" in
        .claude/MAJOR_*.md)
          obsolete_major_files+=("$ws_dep")
          ;;
        *)
          obsolete_prunable_files+=("$ws_dep")
          ;;
      esac
    fi
  done < <(enumerate_workspace_substrate_paths "$ws_abs" "$tier" "$slug")

  # ----- Pass 3: uncommitted .claude/ state ---------------------------------
  local uncommitted
  uncommitted="$(uncommitted_claude_count "$ws_abs")"

  # ----- Verdict computation ------------------------------------------------
  #
  # Per directive A6: <verdict> (<N> drifted, <M> missing, <K> obsolete; <U> uncommitted)
  # Token order: drifted -> missing -> obsolete.
  local n_drifted=${#drifted_files[@]}
  local n_missing=${#missing_files[@]}
  local n_obsolete=$(( ${#obsolete_prunable_files[@]} + ${#obsolete_major_files[@]} ))
  local verdict_parts=()
  local verdict

  [ "$n_drifted"  -gt 0 ] && verdict_parts+=("DRIFTED")
  [ "$n_missing"  -gt 0 ] && verdict_parts+=("MISSING")
  [ "$n_obsolete" -gt 0 ] && verdict_parts+=("OBSOLETE")

  # Join with " + " per locked directive A6 composite form. Explicit case
  # form instead of `IFS=' + '; echo "${arr[*]}"` — bash multi-char IFS uses
  # only the FIRST char as separator, so the IFS form would produce
  # " "-separated tokens, not " + "-separated. Case form is unambiguous and
  # matches the directive's literal " + " separator.
  case "${#verdict_parts[@]}" in
    0) verdict="CURRENT" ;;
    1) verdict="${verdict_parts[0]}" ;;
    2) verdict="${verdict_parts[0]} + ${verdict_parts[1]}" ;;
    3) verdict="${verdict_parts[0]} + ${verdict_parts[1]} + ${verdict_parts[2]}" ;;
  esac

  # Format the uncommitted suffix per directive A6.
  local uncommitted_suffix
  if [ "$uncommitted" = "unknown" ]; then
    uncommitted_suffix="; uncommitted-state: unknown (workspace not git-tracked)"
  else
    uncommitted_suffix="; ${uncommitted} uncommitted"
  fi

  # ----- Emit summary -------------------------------------------------------
  local sha
  sha="$(substrate_head_sha)"
  local state ts last_sha
  state="$(read_state_file "$ws_abs")"
  ts="${state%%|*}"
  last_sha="${state##*|}"

  if [ "$verdict" = "CURRENT" ]; then
    printf "%-40s CURRENT (0 drifted, 0 missing, 0 obsolete%s)\n" "$label" "$uncommitted_suffix"
    if [ -n "$ts" ]; then
      printf "  Last check: %s (against substrate sha %s)\n" "$ts" "$last_sha"
    fi
    # Surface uncommitted warning even on CURRENT (per directive A6's
    # always-emit-on-uncommitted shape).
    emit_uncommitted_warning_if_needed "$uncommitted" "$ws_abs"
  else
    printf "%-40s %s (%d drifted, %d missing, %d obsolete%s)\n" \
      "$label" "$verdict" "$n_drifted" "$n_missing" "$n_obsolete" "$uncommitted_suffix"

    # Per-category detail blocks (only for non-zero categories).
    # PREFIX DISCIPLINE (design-rev2.md P0-3): each category uses a DISTINCT
    # prefix so apply.sh's blind harvest of "  - "* matches ONLY DRIFTED.
    # apply.sh stays untouched (deliverable 6) and cannot accidentally
    # deploy MISSING files via cp at apply.sh:370.
    #   DRIFTED:  "  - "  (two-space + dash + space) — apply.sh:218 harvests this
    #   MISSING:  "  + "  (two-space + plus  + space) — visual: "this needs adding"
    #   OBSOLETE: "  ! "  (two-space + bang  + space) — visual: "this needs attention"
    if [ "$n_drifted" -gt 0 ]; then
      echo "  DRIFTED:"
      local i
      for ((i=0; i<n_drifted; i++)); do
        printf "  - %-50s (%s)\n" "${drifted_files[$i]}" "${drifted_deltas[$i]}"
      done
    fi
    if [ "$n_missing" -gt 0 ]; then
      echo "  MISSING:"
      local m
      for m in "${missing_files[@]}"; do
        printf "  + %-50s (new in source)\n" "$m"
      done
    fi
    if [ "$n_obsolete" -gt 0 ]; then
      echo "  OBSOLETE:"
      # Emit prunable first, MAJORs second — preserves visual contiguity.
      if [ "${#obsolete_prunable_files[@]}" -gt 0 ]; then
        local op
        for op in "${obsolete_prunable_files[@]}"; do
          printf "  ! %-50s (dropped from source)\n" "$op"
        done
      fi
      if [ "${#obsolete_major_files[@]}" -gt 0 ]; then
        local om
        for om in "${obsolete_major_files[@]}"; do
          printf "  ! %-50s (dropped from source; manual-rm — see footer)\n" "$om"
        done
      fi
    fi

    # State-info lines.
    echo
    if [ -n "$ts" ]; then
      printf "  Last check: %s (against substrate sha %s)\n" "$ts" "$last_sha"
    fi
    printf "  Current substrate HEAD: %s\n" "$sha"

    # Routing footer (per directive A6). Per-category-conditional — emitting
    # an apply.sh line for a workspace with zero DRIFTED would actively
    # confuse the operator. Tier-branched install.sh footer per design-rev2.md
    # P2-1 (subproject uses --parent-dir + --subproject; project uses
    # --project-dir).
    echo
    if [ "$n_drifted" -gt 0 ]; then
      printf "  Run apply.sh --workspace %s for drifted.\n" "$ws_abs"
    fi
    if [ "$n_missing" -gt 0 ]; then
      case "$tier" in
        subproject)
          local parent_dir="${ws_abs%/${slug}}"
          printf "  Run install.sh --target subproject --parent-dir %s --subproject %s for missing.\n" \
            "$parent_dir" "$slug"
          ;;
        *)
          printf "  Run install.sh --target %s --project-dir %s for missing.\n" "$tier" "$ws_abs"
          ;;
      esac
    fi
    if [ "${#obsolete_prunable_files[@]}" -gt 0 ]; then
      case "$tier" in
        subproject)
          local parent_dir2="${ws_abs%/${slug}}"
          printf "  Run install.sh --target subproject --parent-dir %s --subproject %s --prune-obsolete for obsolete (destructive — confirm).\n" \
            "$parent_dir2" "$slug"
          ;;
        *)
          printf "  Run install.sh --target %s --project-dir %s --prune-obsolete for obsolete (destructive — confirm).\n" \
            "$tier" "$ws_abs"
          ;;
      esac
    fi
    if [ "${#obsolete_major_files[@]}" -gt 0 ]; then
      # MAJOR_*.md is deliberately excluded from install.sh's prune scope
      # (install.sh: the 'pair-programmer Majors land in the same agents/' note, ~L92-93 — re-grep that literal if line numbers drift).
      # check.sh nonetheless surfaces flagged MAJORs per directive A4.
      # Manual rm is the safer path; emit a dedicated routing block so the
      # operator isn't sent to a no-op install.sh prune.
      echo "  MAJOR_*.md OBSOLETE entries require manual rm — install.sh --prune-obsolete"
      echo "  deliberately excludes MAJORs (pair-programmer agents share the directory)."
      local om2
      for om2 in "${obsolete_major_files[@]}"; do
        printf "    rm %s/%s\n" "$ws_abs" "$om2"
      done
    fi

    emit_uncommitted_warning_if_needed "$uncommitted" "$ws_abs"
  fi

  # Update state file.
  write_state_file "$ws_abs" "$sha"
}

# ----- main ------------------------------------------------------------------

if [ -n "$WORKSPACE_OVERRIDE" ]; then
  check_workspace "$WORKSPACE_OVERRIDE"
  exit 0
fi

if [ ! -f "$REGISTRY" ]; then
  echo "check.sh: error: registry not found: $REGISTRY" >&2
  exit 2
fi

while IFS= read -r line || [ -n "$line" ]; do
  # Strip trailing CR (Windows line endings on the registry file).
  line="${line%$'\r'}"
  # Skip blank lines and comments.
  case "$line" in
    ""|\#*) continue ;;
  esac
  check_workspace "$line"
  echo
done < "$REGISTRY"
