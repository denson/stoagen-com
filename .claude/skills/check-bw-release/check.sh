#!/usr/bin/env bash
#
# check.sh — check for new bw upstream releases and surface the 3-axis
# impact-classification template when one is found.
#
# Queries the bw GitHub releases API for the current latest tag, compares
# to a per-workspace baseline stored at .bw-release-last-check (in the
# directory two levels above this script — substrate/ at substrate-tier,
# <workspace>/.claude/ at consumer-tier), and prints either a "current"
# message or a "new release detected" message with changelog pointer +
# axis template + suggested next action (per operating-disciplines.md
# §22 bw-upgrade discipline). Single-target skill (one upstream feed);
# per-workspace baselines (mirrors check-substrate-updates' per-workspace
# state-file pattern). First invocation bootstraps the baseline (no "new
# release detected" on first run); subsequent invocations compare
# upstream-latest to the stored baseline.
#
# Usage:
#   check.sh                                       # standard call
#   check.sh --force-check                         # no-op today; forward-compat reserved
#   check.sh --baseline <tag>                      # override baseline for testing / recovery
#   check.sh -h | --help                           # this help text
#
# Test fixtures (env-var override, single invocation scope):
#   BW_RELEASE_CHECK_LATEST_OVERRIDE=<tag>         # skip API call; use this as upstream-latest
#   BW_RELEASE_CHECK_BASELINE_OVERRIDE=<tag>       # skip state-file read; use this as baseline
#
# Output: human-readable; exit code is always 0 on successful execution.
# Drift is informational, not failure.

set -euo pipefail

# ----- locate the skills-parent directory (state-file lives there) -----
#
# The skill is deployed BY install.sh to <workspace>/.claude/skills/check-bw-release/.
# At substrate-tier (the-stoa repo), the script lives at
# substrate/skills/check-bw-release/. In both cases, the skills-parent
# directory (the directory two levels above this script) is the right
# place for the state file:
#   - substrate-tier:  substrate/.bw-release-last-check
#   - consumer-tier:   <workspace>/.claude/.bw-release-last-check
# Per-workspace baselines mirror check-substrate-updates' per-workspace
# state-file pattern; each workspace's baseline drifts independently.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_PARENT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STATE_FILE="${SKILLS_PARENT_DIR}/.bw-release-last-check"

# ----- argument parsing ------------------------------------------------------

FORCE_CHECK=0
BASELINE_OVERRIDE_ARG=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force-check)
      FORCE_CHECK=1
      shift
      ;;
    --baseline)
      [ "$#" -ge 2 ] || { echo "check.sh: error: --baseline requires a tag" >&2; exit 2; }
      BASELINE_OVERRIDE_ARG="$2"
      shift 2
      ;;
    -h|--help)
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

# fetch_latest_release_tag: echo the latest release tag, or empty string on
# failure (network, parse error, or upstream contract change).
#
# CITE: queries https://api.github.com/repos/jallum/beadwork/releases/latest
# and parses the .tag_name field. If GitHub rotates the releases endpoint, or
# if jallum/beadwork ever moves to a different org or repo name, this function
# must update both the URL and (if the response shape changes) the parse. The
# cite-at-the-read-site pattern is the durable mitigation for source-side
# coupling — surfaces the linkage at the read site, not at code-review time.
# Same mitigation pattern as check-substrate-updates/check.sh
# apply_substitutions and parse_skill_names_from_install (per Arc 26). See
# operating-disciplines.md §22 Step 2 for the broader "verify changelog
# claims empirically" discipline this skill implements (the registry surprise
# at stoa--s6n 2026-05-17 is the canonical worked example).
#
# Python (not jq): the substrate's established cross-platform dependency is
# Python (see operating-disciplines.md §13 PYTHONUTF8=1 discipline). jq is
# not a guaranteed dependency on consumer workspaces. If a future maintainer
# is tempted to "improve" this to jq, the dependency surface changes and
# this cite-comment is the surface that flags it at the read site.
#
# FAILURE-MODE (actual runtime, defang per ARGUS rev1 verdict
# 2026-05-17T03:07:43Z LBR-1): under `set -euo pipefail`, an unguarded
# `curl | python3` pipeline that fails (curl non-200, network unreachable,
# python parse error on unexpected JSON shape, etc.) would propagate via
# pipefail and kill the calling command substitution via `set -e`. The
# `{ ... ; } || true` wrapper at the pipeline boundary catches both
# curl-non-zero and python-non-zero exits; the function then echoes
# whatever python wrote to stdout (empty string on parse error, since
# python's `pass` swallows the exception in the inline script). The
# caller's `[ -z "${latest}" ]` guard fires on the defanged empty result
# and emits the "could not reach upstream" message. Same defang shape as
# check-substrate-updates/check.sh:489-500 (which defangs grep-empty
# pipeline exit under pipefail). This is informational tooling, not
# blocking — drift is not failure.
fetch_latest_release_tag() {
  if [ -n "${BW_RELEASE_CHECK_LATEST_OVERRIDE:-}" ]; then
    echo "${BW_RELEASE_CHECK_LATEST_OVERRIDE}"
    return 0
  fi
  # Defang at the pipeline boundary: catches curl-non-zero AND python-
  # non-zero; downstream sees the python stdout (empty on parse error).
  { curl -fsSL --max-time 8 "https://api.github.com/repos/jallum/beadwork/releases/latest" 2>/dev/null \
      | python3 -c "import json,sys
try:
  print(json.load(sys.stdin).get('tag_name',''))
except Exception:
  pass" 2>/dev/null
  } || true
}

# read_baseline: echo the stored baseline tag, or empty if absent.
read_baseline() {
  if [ -n "${BW_RELEASE_CHECK_BASELINE_OVERRIDE:-}" ]; then
    echo "${BW_RELEASE_CHECK_BASELINE_OVERRIDE}"
    return 0
  fi
  if [ -n "${BASELINE_OVERRIDE_ARG}" ]; then
    echo "${BASELINE_OVERRIDE_ARG}"
    return 0
  fi
  [ -f "${STATE_FILE}" ] || { echo ""; return 0; }
  tr -d '\n\r' < "${STATE_FILE}"
}

# write_baseline <tag>: persist the tag as the new baseline.
write_baseline() {
  printf '%s\n' "$1" > "${STATE_FILE}"
}

# emit_axis_template <new-tag> <old-tag>: print the 3-axis classification
# template + suggested next action. Verbatim copy of operating-disciplines.md
# §22.2 axes; if §22.2 changes, this template updates to match.
emit_axis_template() {
  local new="$1"
  local old="$2"
  cat <<EOF

NEW BW RELEASE DETECTED
  Current upstream:  ${new}
  Stored baseline:   ${old}
  Release notes:     https://github.com/jallum/beadwork/releases/tag/${new}

Classify each feature in the changelog by impact axis (per operating-disciplines.md §22.2):

  [ ] DEPLOYMENT-SIDE — Dockerfile bumps, install.sh re-runs, SHA256 updates
                       at any deployed environment (e.g., ariadne--c71).
  [ ] SUBSTRATE-SIDE  — obsoletes substrate canon? enables new substrate
                       pattern? warrants a new section?
  [ ] WORKSPACE-SIDE  — subprocess-call-site regression risk (bw_ingest.py-
                       class)? exit-code semantic changes?

Suggested next action: file one ticket per impact axis TOUCHED (per §22 Step 3).
"No action needed for this axis" is a valid review note for an untouched axis.

Update the baseline once tickets are filed:
  echo '${new}' > "${STATE_FILE}"
EOF
}

# emit_current_message <tag>: print the "current" message.
emit_current_message() {
  printf 'Current bw release: %s (baseline matches). No action needed.\n' "$1"
}

# emit_unreachable_message: print the "could not check" message.
emit_unreachable_message() {
  cat <<EOF
check-bw-release: could not reach https://api.github.com/repos/jallum/beadwork/releases/latest
  Check network connectivity and rate limits (60/hour unauthenticated).
  Re-run with --force-check if a future caching mechanism caches a failure.
EOF
}

# ----- main ------------------------------------------------------------------

# FORCE_CHECK is a forward-compat no-op today (state file is just a tag, not
# a timestamp; no rate-limiting/caching to bypass). Reserved for if a future
# arc adds caching. Suppress unused-var warning under set -u.
: "${FORCE_CHECK}"

latest="$(fetch_latest_release_tag)"
if [ -z "${latest}" ]; then
  emit_unreachable_message
  exit 0
fi

baseline="$(read_baseline)"

# First invocation: bootstrap the baseline silently. No "new release detected"
# on first run — the skill's job is to surface CHANGES, not initial state.
if [ -z "${baseline}" ]; then
  write_baseline "${latest}"
  emit_current_message "${latest}"
  echo "  (baseline bootstrapped on first invocation)"
  exit 0
fi

if [ "${latest}" = "${baseline}" ]; then
  emit_current_message "${latest}"
  exit 0
fi

emit_axis_template "${latest}" "${baseline}"
exit 0
