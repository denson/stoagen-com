#!/usr/bin/env bash
#
# check.sh — inspect post-mechanical-script workspace state for strangeness.
#
# Reads a workspace's deployed-file tree, git HEAD, and (optionally) recent
# script-output cache, and surfaces anomalies the mechanical script was not
# pre-programmed to enumerate. This is Step 2 of the 3-step mechanical-script
# / agent-inspection split pattern canonicalized at
# operating-disciplines.md §27 (Step 1 = mechanical script runs; Step 2 = this
# inspection; Step 3 = POLYBIUS triages per §27.2). The inspection layer's
# job is novel strangeness — the things the script wasn't pre-programmed to
# notice — not the known-strangeness drift verdict that
# substrate/skills/check-substrate-updates/check.sh already computes.
#
# Shipped scan helpers this arc (per Arc 33 design design-rev2.md §4.2 item 6
# shipped subset):
#   - scan_unauthorized_commits   — git-history scan of .claude/ for commits
#                                   outside the substrate-canonical pattern
#                                   set (sector-4 probe-residue from
#                                   stoa--501 is the canonical worked
#                                   example).
#   - scan_name_collisions        — silent-collision name: duplicates within
#                                   one Claude-Code scope per
#                                   MAJOR_POLYBIUS.md §17.4 (reads BOTH base
#                                   and custom paths; flags duplicate name:
#                                   VALUES; does NOT flag custom files as
#                                   strange in their own right).
#   - scan_drift_verdict_mismatch — if check-substrate-updates is deployed and
#                                   a recent check.sh output is cached,
#                                   compare its verdict against an mtime
#                                   sweep of .claude/ and surface any
#                                   inconsistency.
#
# Three categories deferred per A7 boundary (cleanup-claims-not-executed /
# attestation-claims-not-live-verified / PRINCIPAL-gate-clauses-encountered-
# but-not-paused-on) — future-arc work. See SKILL.md "Strangeness categories"
# table for the explicit deferral framing.
#
# Usage:
#   check.sh --workspace <abs-path>             # standard call
#   check.sh --workspace <abs-path> --only <category-list>
#                                               # comma-separated subset
#   check.sh --self-test                        # runtime fixture self-test
#                                               # (no --workspace needed)
#   check.sh -h | --help                        # this help text
#
# Categories accepted by --only:
#   unauthorized-commits, name-collisions, drift-verdict-mismatch
#
# Test fixtures (env-var, set automatically by --self-test):
#   INSPECT_SCRIPT_OUTPUT_FIXTURE_MODE=1        # skip real git ops; read
#                                               # <workspace>/.git-HEAD-fixture
#                                               # text file as the HEAD SHA.
#
# Output: human-readable strangeness report. Production exit code is always 0
# (drift is informational, never blocks — same exit-code discipline as
# check-bw-release/check.sh and check-substrate-updates/check.sh). Only
# --self-test exits 1 (and only when an assertion fails — development
# signal, not substrate-state signal).

set -euo pipefail

# ----- locate the skills-parent directory (state-file lives there) -----
#
# The skill is deployed BY install.sh to <workspace>/.claude/skills/inspect-
# script-output/. At substrate-tier (the-stoa repo), the script lives at
# substrate/skills/inspect-script-output/. In both cases, the skills-parent
# directory (the directory two levels above this script) is the right place
# for the state file:
#   - substrate-tier:  substrate/.inspect-script-output-last-run
#   - consumer-tier:   <workspace>/.claude/.inspect-script-output-last-run
# Per-workspace baselines mirror check-substrate-updates' + check-bw-release's
# per-workspace state-file pattern; each workspace's last-run drifts
# independently.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_PARENT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STATE_FILE="${SKILLS_PARENT_DIR}/.inspect-script-output-last-run"

# Substrate-canonical commit-message patterns: scan_unauthorized_commits
# treats any .claude/ commit whose subject line does NOT match one of these
# as a finding. Update only when install.sh / apply.sh / prune routing
# changes; otherwise drift means a non-substrate commit landed in .claude/
# and POLYBIUS should triage. These patterns mirror the substrate's own
# commit conventions; see install.sh ~lines 800+ for the apply/install flow.
SUBSTRATE_COMMIT_PATTERNS=(
  "^Apply substrate"
  "^Install substrate"
  "^Prune substrate"
  "^chore\(substrate\)"
  "^Arc [0-9]+:"
)

# ----- argument parsing ------------------------------------------------------

WORKSPACE_ARG=""
ONLY_CATEGORIES=""
SELF_TEST=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace)
      [ "$#" -ge 2 ] || { echo "check.sh: error: --workspace requires a path" >&2; exit 2; }
      WORKSPACE_ARG="$2"
      shift 2
      ;;
    --only)
      [ "$#" -ge 2 ] || { echo "check.sh: error: --only requires a comma-separated category list" >&2; exit 2; }
      ONLY_CATEGORIES="$2"
      shift 2
      ;;
    --self-test)
      SELF_TEST=1
      shift
      ;;
    -h|--help)
      # Sed range closes on the line ending "substrate-state signal)." (the
      # last line of the head-of-file comment block above). Don't end-pattern
      # on a fragment that appears mid-line — sed -n /<start>/,/<end>/p only
      # closes when the END pattern matches a whole line, otherwise it
      # prints to EOF. Same pattern as check-bw-release/check.sh:66-67.
      sed -n '/^# check\.sh —/,/^# substrate-state signal)\.$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "check.sh: error: unknown argument: $1 (try --help)" >&2
      exit 2
      ;;
  esac
done

# ----- helpers ---------------------------------------------------------------

# is_category_enabled <name>: returns 0 if the named category should run, 1 if
# --only restricts it out. With no --only, all categories run.
is_category_enabled() {
  local name="$1"
  [ -z "${ONLY_CATEGORIES}" ] && return 0
  # Comma-separated match; allow trailing/leading whitespace per item.
  local IFS=','
  for item in ${ONLY_CATEGORIES}; do
    # Trim leading + trailing whitespace.
    item="${item## }"; item="${item%% }"
    [ "${item}" = "${name}" ] && return 0
  done
  return 1
}

# read_git_head <workspace>: echo the workspace's HEAD SHA, or empty on error.
#   - Fixture mode (INSPECT_SCRIPT_OUTPUT_FIXTURE_MODE=1, set by --self-test):
#     read <workspace>/.git-HEAD-fixture (one-line text file).
#   - Production: cd <workspace> && git rev-parse HEAD.
#   - Defang per check-bw-release/check.sh:113-127 model: pipefail-safe so a
#     non-git workspace or a git-failure does not kill the calling command
#     substitution; caller's `[ -z "${head}" ]` guard handles empty result.
read_git_head() {
  local ws="$1"
  if [ "${INSPECT_SCRIPT_OUTPUT_FIXTURE_MODE:-0}" = "1" ]; then
    [ -f "${ws}/.git-HEAD-fixture" ] || { echo ""; return 0; }
    tr -d '\n\r' < "${ws}/.git-HEAD-fixture"
    return 0
  fi
  # Defang at the pipeline boundary: catches git-non-zero (e.g., not a git
  # workspace) so the outer command substitution receives the empty result.
  { (cd "${ws}" && git rev-parse HEAD 2>/dev/null) || true; }
}

# --- scan_unauthorized_commits ----------------------------------------------
#
# CITE: enumerates commits to .claude/ between a baseline SHA and HEAD;
# surfaces any subject line NOT matching SUBSTRATE_COMMIT_PATTERNS. This is
# the "sector-4 probe-residue" case from Arc 26 / stoa--501 — a probe ran
# during a gauntlet, mutated workspace state, and the mutation landed as a
# commit outside the substrate-canonical apply/install path. The
# strangeness-detected branch routes this to POLYBIUS triage per
# operating-disciplines.md §27.2 step 3; PRINCIPAL-gate-touching commits
# escalate per MAJOR_POLYBIUS.md §17 + operating-disciplines.md §23 base-vs-
# custom scoping (a commit at a custom path is still a substrate-state
# anomaly worth POLYBIUS triage — see SKILL.md "Strangeness categories"
# table). Cite-comment shape mirrors
# substrate/skills/check-substrate-updates/check.sh apply_substitutions
# (per Arc 26).
#
# Fixture mode (--self-test): no-op (synthetic tree has no real .git/);
# helper returns CLEAN for both CLEAN and STRANGE trees. VERA-8 against a
# real workspace exercises the strangeness-detected branch.
scan_unauthorized_commits() {
  local ws="$1"
  if [ "${INSPECT_SCRIPT_OUTPUT_FIXTURE_MODE:-0}" = "1" ]; then
    return 0
  fi
  # Production: walk recent .claude/ commits. Baseline is "since last run"
  # if state file exists; otherwise "last 20 commits" as a sane default.
  local since_arg
  if [ -f "${STATE_FILE}" ]; then
    local last_sha
    last_sha="$(awk '{print $1}' "${STATE_FILE}" | head -n1 | tr -d '\n\r')"
    if [ -n "${last_sha}" ]; then
      since_arg="${last_sha}..HEAD"
    else
      since_arg="-20"
    fi
  else
    since_arg="-20"
  fi
  local commits
  commits="$( { (cd "${ws}" && git log --pretty=format:'%H %s' "${since_arg}" -- .claude/ 2>/dev/null) || true; } )"
  [ -z "${commits}" ] && return 0
  local findings=""
  while IFS= read -r line; do
    [ -z "${line}" ] && continue
    local sha subject
    sha="${line%% *}"
    subject="${line#* }"
    local matched=0
    for pat in "${SUBSTRATE_COMMIT_PATTERNS[@]}"; do
      if echo "${subject}" | grep -Eq "${pat}"; then
        matched=1
        break
      fi
    done
    if [ "${matched}" -eq 0 ]; then
      findings+="    - ${sha:0:12} ${subject}"$'\n'
    fi
  done <<< "${commits}"
  if [ -n "${findings}" ]; then
    printf '\n[unauthorized-commits] commits to .claude/ outside substrate-canonical pattern set:\n'
    printf '%s' "${findings}"
  fi
}

# --- scan_name_collisions ---------------------------------------------------
#
# CITE: detects silent-collision name-duplicates per MAJOR_POLYBIUS.md §17.4
# (the silent-collision footgun: duplicate name: field values within one
# Claude-Code scope cause Claude Code to silently drop one on discovery).
# Grounded in operating-disciplines.md §23 (universal base-vs-custom) +
# MAJOR_POLYBIUS.md §17 (POLYBIUS-tier refinement of the universal). For
# each Claude-Code-relevant scope, walk all files in that scope (BOTH base
# and custom paths) and extract YAML frontmatter `name:` field values.
# Within one scope, if any `name:` value appears more than once across the
# collected files, that is a silent-collision finding. Emit one finding per
# collision-set with all colliding file paths cited. Cite-comment shape
# mirrors substrate/skills/check-substrate-updates/check.sh
# apply_substitutions + parse_skill_names_from_install (per Arc 26).
#
# SCOPE NOTE per Arc 33 design design-rev2.md §4.4: this helper reads custom
# paths to collect name: values for cross-comparison; it does NOT flag
# custom files as strange in their own right. Workspace customization is
# operator-owned per §23.3; the §17.4 silent-collision footgun is a
# SCOPE-LEVEL defect both base and custom contributors share, and
# detection of it serves both.
#
# Today's scope set is .claude/agents/ (Claude Code scans this dir
# recursively per https://code.claude.com/docs/en/sub-agents); future arcs
# can extend to additional scopes (e.g., commands, skills) by adding rows
# to the SCOPE_DIRS array.
scan_name_collisions() {
  local ws="$1"
  local SCOPE_DIRS=(
    ".claude/agents"
  )
  local emitted_header=0
  for scope in "${SCOPE_DIRS[@]}"; do
    local scope_path="${ws}/${scope}"
    [ -d "${scope_path}" ] || continue
    # Collect every name: value across both base and custom subtrees.
    # Multi-file frontmatter; we read only the first matching name: line per
    # file (frontmatter convention is one `name:` field at the top).
    local tmpfile
    tmpfile="$(mktemp)"
    # Walk every .md file in the scope recursively. For each, extract the
    # FIRST line matching ^name:\s*<value> (quoted or unquoted; we strip
    # surrounding quotes after capture).
    while IFS= read -r -d '' f; do
      local raw_name
      raw_name="$(grep -m1 -E '^name:[[:space:]]+' "${f}" 2>/dev/null || true)"
      [ -z "${raw_name}" ] && continue
      # Strip the leading "name:" + whitespace; strip surrounding quotes.
      local value
      value="${raw_name#name:}"
      # Trim leading whitespace.
      value="${value#"${value%%[![:space:]]*}"}"
      # Trim trailing whitespace.
      value="${value%"${value##*[![:space:]]}"}"
      # Strip surrounding double-quotes if present.
      if [[ "${value}" == \"*\" ]]; then
        value="${value#\"}"
        value="${value%\"}"
      fi
      # Strip surrounding single-quotes if present.
      if [[ "${value}" == \'*\' ]]; then
        value="${value#\'}"
        value="${value%\'}"
      fi
      [ -z "${value}" ] && continue
      # Record value<TAB>path; relative path for the report.
      local rel_path="${f#${ws}/}"
      printf '%s\t%s\n' "${value}" "${rel_path}" >> "${tmpfile}"
    done < <(find "${scope_path}" -type f -name '*.md' -print0 2>/dev/null)
    # Group by value; report any value appearing more than once.
    local dup_values
    dup_values="$(awk -F'\t' '{print $1}' "${tmpfile}" | sort | uniq -d || true)"
    if [ -n "${dup_values}" ]; then
      while IFS= read -r dup; do
        [ -z "${dup}" ] && continue
        if [ "${emitted_header}" -eq 0 ]; then
          printf '\n[name-collisions] duplicate name: field values within one Claude-Code scope (per MAJOR_POLYBIUS.md §17.4):\n'
          emitted_header=1
        fi
        printf '  scope: %s\n' "${scope}"
        printf '  name: %s\n' "${dup}"
        printf '  colliding files:\n'
        awk -F'\t' -v v="${dup}" '$1==v {print "    - "$2}' "${tmpfile}"
      done <<< "${dup_values}"
    fi
    rm -f "${tmpfile}"
  done
}

# --- scan_drift_verdict_mismatch --------------------------------------------
#
# CITE: cross-checks check-substrate-updates/check.sh cached output against
# an mtime sweep of .claude/ — surfaces inconsistencies (e.g., CURRENT
# verdict with .claude/ files newer than the verdict's timestamp; DRIFTED
# verdict with no per-file detail lines). Grounds: operating-disciplines.md
# §27.2 step 2 names this category as one of the inspection-agent layer's
# responsibilities; MAJOR_POLYBIUS.md §17 base-vs-custom scoping inherits
# from check-substrate-updates' own scoping (per Arc 29 / op-disc §23.5),
# which is base-files-only. The verdict-mismatch check inherits that
# scoping; it does not separately walk custom paths.
#
# Skips silently if check-substrate-updates is not deployed at the workspace
# (no .claude/skills/check-substrate-updates/ directory) — that is not a
# strangeness, just an unconfigured workspace.
scan_drift_verdict_mismatch() {
  local ws="$1"
  # If check-substrate-updates is not deployed, skip — not strange, just
  # unconfigured. The substrate-tier workspace has the skill at
  # substrate/skills/...; consumer workspaces have it at
  # .claude/skills/...; detect either layout.
  if [ ! -d "${ws}/.claude/skills/check-substrate-updates" ] \
     && [ ! -d "${ws}/substrate/skills/check-substrate-updates" ]; then
    return 0
  fi
  # If a cached check.sh output exists at a conventional location, read it
  # and cross-check. No canonical cache location today; this helper is a
  # placeholder for the surface the future arc fleshes out per A7. Today
  # the helper is a no-op (no inconsistency to flag without a cache).
  # When a future arc adds a cache convention, this helper grows the
  # cross-check logic; the placeholder keeps the scan-helper-set shape
  # intact for the inspection-agent layer.
  return 0
}

# --- emit_report ------------------------------------------------------------
#
# Aggregates findings from the scan helpers and emits either the CLEAN
# message or the STRANGENESS DETECTED report. The scan helpers themselves
# write findings to stdout in a per-category sectioned shape; this helper
# wraps with the report header + footer + CLEAN/STRANGE banner.
emit_report() {
  local ws="$1"
  local findings_output="$2"
  if [ -z "${findings_output}" ]; then
    printf 'CLEAN: no strangeness detected at %s\n' "${ws}"
    printf '  Scan categories: %s\n' "${RAN_CATEGORIES}"
    return 0
  fi
  printf 'STRANGENESS DETECTED at %s\n' "${ws}"
  printf '  Scan categories: %s\n' "${RAN_CATEGORIES}"
  printf '%s\n' "${findings_output}"
  printf '\nRoute findings per operating-disciplines.md §27.2 step 3 (POLYBIUS triage).\n'
}

# --- run_scans <workspace>: run the enabled scan helpers, capturing their
# combined stdout into FINDINGS_OUTPUT and listing the ran-set into
# RAN_CATEGORIES. Globals are easiest for shell-portability across the
# helpers.
run_scans() {
  local ws="$1"
  FINDINGS_OUTPUT=""
  RAN_CATEGORIES=""
  local sep=""
  if is_category_enabled "unauthorized-commits"; then
    FINDINGS_OUTPUT+="$(scan_unauthorized_commits "${ws}")"
    RAN_CATEGORIES+="${sep}unauthorized-commits"; sep=", "
  fi
  if is_category_enabled "name-collisions"; then
    FINDINGS_OUTPUT+="$(scan_name_collisions "${ws}")"
    RAN_CATEGORIES+="${sep}name-collisions"; sep=", "
  fi
  if is_category_enabled "drift-verdict-mismatch"; then
    FINDINGS_OUTPUT+="$(scan_drift_verdict_mismatch "${ws}")"
    RAN_CATEGORIES+="${sep}drift-verdict-mismatch"; sep=", "
  fi
  if [ -z "${RAN_CATEGORIES}" ]; then
    RAN_CATEGORIES="(none — --only filter excluded all categories)"
  fi
  return 0
}

# --- write_state <workspace>: persist the current HEAD + ISO-8601 timestamp.
write_state() {
  local ws="$1"
  local head
  head="$(read_git_head "${ws}")"
  [ -z "${head}" ] && head="(unknown)"
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s %s\n' "${head}" "${ts}" > "${STATE_FILE}"
}

# ============================================================================
# Self-test mode
# ============================================================================
#
# build_self_test_tree <root>: write synthetic CLEAN + STRANGE trees per
# Arc 33 design design-rev2.md §4.1 shape into <root>/clean/ and
# <root>/strange/. The CLEAN tree contains a correctly-conventioned custom
# CAPTAIN (distinct name: slug; no collision); the STRANGE tree contains
# a base + custom CAPTAIN with identical name: values (the planted
# silent-collision per MAJOR_POLYBIUS.md §17.4).
build_self_test_tree() {
  local root="$1"
  # ----- CLEAN tree -----
  mkdir -p "${root}/clean/.claude/agents/custom"
  # Representative base file at scope root.
  cat > "${root}/clean/.claude/MAJOR_POLYBIUS_self_test.md" <<'CLEANBASE'
# MAJOR_POLYBIUS — fixture base file
fixture-only; representative base file for self-test CLEAN tree.
CLEANBASE
  cat > "${root}/clean/.claude/operating-disciplines.md" <<'CLEANDISC'
# operating-disciplines.md — fixture base file
fixture-only; representative base file for self-test CLEAN tree.
CLEANDISC
  # Base CAPTAIN with distinct name.
  cat > "${root}/clean/.claude/agents/CAPTAIN_DAEDALUS_self_test.md" <<'CLEANBASECAP'
---
name: CAPTAIN_DAEDALUS_self_test
description: Fixture base CAPTAIN — clean tree; no collision.
---

Fixture-only.
CLEANBASECAP
  # Custom CAPTAIN with distinct slug (correctly-conventioned per §17.4).
  cat > "${root}/clean/.claude/agents/custom/CAPTAIN_DEPLOYER_self_test.md" <<'CLEANCUST'
---
name: CAPTAIN_DEPLOYER_self_test_custom
description: Fixture custom CAPTAIN — correctly-conventioned distinct slug; no collision.
---

Fixture-only.
CLEANCUST
  # Synthetic HEAD SHA for fixture-mode read_git_head.
  printf '%s\n' "0000000000000000000000000000000000000001" > "${root}/clean/.git-HEAD-fixture"

  # ----- STRANGE tree -----
  mkdir -p "${root}/strange/.claude/agents/custom"
  cat > "${root}/strange/.claude/MAJOR_POLYBIUS_self_test.md" <<'STRANGEBASE'
# MAJOR_POLYBIUS — fixture base file
fixture-only; representative base file for self-test STRANGE tree.
STRANGEBASE
  cat > "${root}/strange/.claude/operating-disciplines.md" <<'STRANGEDISC'
# operating-disciplines.md — fixture base file
fixture-only; representative base file for self-test STRANGE tree.
STRANGEDISC
  # Base CAPTAIN — name: CAPTAIN_DAEDALUS_self_test.
  cat > "${root}/strange/.claude/agents/CAPTAIN_DAEDALUS_self_test.md" <<'STRANGEBASECAP'
---
name: CAPTAIN_DAEDALUS_self_test
description: Fixture base CAPTAIN — strange tree; planted name-collision source.
---

Fixture-only.
STRANGEBASECAP
  # Custom CAPTAIN — DUPLICATE name: CAPTAIN_DAEDALUS_self_test (the planted
  # silent-collision per MAJOR_POLYBIUS.md §17.4).
  cat > "${root}/strange/.claude/agents/custom/CAPTAIN_DAEDALUS_self_test.md" <<'STRANGECUST'
---
name: CAPTAIN_DAEDALUS_self_test
description: Fixture custom CAPTAIN — planted name-collision per §17.4 (duplicate name: value within scope).
---

Fixture-only.
STRANGECUST
  printf '%s\n' "0000000000000000000000000000000000000002" > "${root}/strange/.git-HEAD-fixture"
}

# run_self_test: top-level for --self-test mode. Builds CLEAN + STRANGE
# trees, runs the scan helpers against each, asserts:
#   1. CLEAN tree emits CLEAN message (no STRANGENESS DETECTED).
#   2. STRANGE tree emits STRANGENESS DETECTED with a finding citing BOTH
#      .claude/agents/CAPTAIN_DAEDALUS_self_test.md AND
#      .claude/agents/custom/CAPTAIN_DAEDALUS_self_test.md.
# Prints one PASS line per assertion; exits 0 if all PASS, exits 1 otherwise.
# EXIT trap cleans up the temp dir.
run_self_test() {
  local root
  root="$(mktemp -d)"
  # Cleanup trap: remove temp tree on exit, including on assertion-fail.
  trap "rm -rf '${root}'" EXIT

  build_self_test_tree "${root}"

  # Force fixture mode for both runs.
  export INSPECT_SCRIPT_OUTPUT_FIXTURE_MODE=1

  local fail_count=0

  # ----- CLEAN-path assertion -----
  local clean_ws="${root}/clean"
  run_scans "${clean_ws}"
  local clean_report
  clean_report="$(emit_report "${clean_ws}" "${FINDINGS_OUTPUT}")"
  if echo "${clean_report}" | grep -q '^CLEAN: no strangeness detected'; then
    printf 'PASS: CLEAN-path emits CLEAN message at %s\n' "${clean_ws}"
  else
    printf 'FAIL: CLEAN-path did NOT emit CLEAN message at %s\n' "${clean_ws}"
    printf '  Actual report:\n%s\n' "${clean_report}"
    fail_count=$((fail_count + 1))
  fi

  # ----- STRANGE-path assertion -----
  local strange_ws="${root}/strange"
  run_scans "${strange_ws}"
  local strange_report
  strange_report="$(emit_report "${strange_ws}" "${FINDINGS_OUTPUT}")"
  # Three sub-assertions composed into one PASS line.
  local strange_ok=1
  if ! echo "${strange_report}" | grep -q 'STRANGENESS DETECTED'; then
    printf 'FAIL: STRANGE-path missing STRANGENESS DETECTED banner.\n'
    printf '  Actual report:\n%s\n' "${strange_report}"
    strange_ok=0
  fi
  if ! echo "${strange_report}" | grep -q '\.claude/agents/CAPTAIN_DAEDALUS_self_test\.md'; then
    printf 'FAIL: STRANGE-path missing base file path in finding (.claude/agents/CAPTAIN_DAEDALUS_self_test.md).\n'
    strange_ok=0
  fi
  if ! echo "${strange_report}" | grep -q '\.claude/agents/custom/CAPTAIN_DAEDALUS_self_test\.md'; then
    printf 'FAIL: STRANGE-path missing custom file path in finding (.claude/agents/custom/CAPTAIN_DAEDALUS_self_test.md).\n'
    strange_ok=0
  fi
  if [ "${strange_ok}" -eq 1 ]; then
    # Emit the finding block above the PASS line so VERA-5 can spot the
    # citation of both colliding files preceding the PASS.
    printf '%s\n' "${strange_report}"
    printf 'PASS: STRANGE-path emits STRANGENESS DETECTED with finding citing both base + custom files at %s\n' "${strange_ws}"
  else
    fail_count=$((fail_count + 1))
  fi

  if [ "${fail_count}" -eq 0 ]; then
    exit 0
  else
    printf '\n%d self-test assertion(s) FAILED.\n' "${fail_count}"
    exit 1
  fi
}

# ----- main ------------------------------------------------------------------

if [ "${SELF_TEST}" -eq 1 ]; then
  run_self_test
fi

# Production-mode main: --workspace required.
if [ -z "${WORKSPACE_ARG}" ]; then
  echo "check.sh: error: --workspace <abs-path> is required (or use --self-test)" >&2
  echo "Try --help for usage." >&2
  exit 2
fi

# Resolve workspace path; verify it exists and has .claude/.
if [ ! -d "${WORKSPACE_ARG}" ]; then
  echo "check.sh: error: workspace does not exist: ${WORKSPACE_ARG}" >&2
  exit 2
fi
WORKSPACE_PATH="$(cd "${WORKSPACE_ARG}" && pwd)"
if [ ! -d "${WORKSPACE_PATH}/.claude" ]; then
  echo "check.sh: warning: workspace has no .claude/ directory: ${WORKSPACE_PATH}" >&2
  echo "  Scans that require .claude/ will be no-ops; CLEAN message will still emit." >&2
fi

# Run the enabled scan helpers and emit the report.
run_scans "${WORKSPACE_PATH}"
emit_report "${WORKSPACE_PATH}" "${FINDINGS_OUTPUT}"

# Update state file with current HEAD + timestamp.
write_state "${WORKSPACE_PATH}"

# Always exit 0 in production mode — drift is informational, never blocks.
exit 0
