#!/usr/bin/env bash
#
# check.sh — validate-spec mechanical-check orchestrator.
#
# Runs the 7 mechanical checks defined at SPECIFICATION.md §13.11 + Arc 42
# directive A5 LOCKED against the current substrate state. Aggregates per-check
# verdicts + evidence trails into a structured Markdown artifact at the
# canonical path agents/observation/spec-validation/mechanical-check-results.md.
#
# The 7 checks (per A5 LOCKED):
#   check-1: every §X / §X.Y reference in SPECIFICATION.md resolves
#   check-2: every cited stoa--<id> ticket exists in bw with claimed status
#   check-3: every open bw ticket is placed in some §13.x section
#   check-4: git status clean (modulo §12.4 ignorables)
#   check-5: _drafts/ empty or justified per §12.4
#   check-6: check-substrate-updates shows no drift across consumer workspaces
#            (A21 LOOSE pre-ratification: ariadne / sector-4 / railway_stoa
#            drift accepted as documented residue per stoa--3na)
#   check-7: §28 Co-Authored-By trailers on post-Arc-35 squash-merge commits
#            with EXPLICIT CARVE-OUT for bb12806 (Arc 37 historical exception)
#
# Usage:
#   bash substrate/skills/validate-spec/check.sh [--spec <path>] [--write-artifact <path>]
#
# Defaults:
#   --spec               SPECIFICATION.md (resolved against repo root)
#   --write-artifact     agents/observation/spec-validation/mechanical-check-results.md
#
# Exit code: ALWAYS 0 on successful execution. Drift is informational per
# directive A20 — the artifact carries the verdict, not the exit code. Exit 2
# is reserved for "could not run" (e.g., python or git missing).
#
# Per CAPTAIN_DAEDALUS.md §6.9 + Arc 42 directive A20 motivated-reasoning
# mitigation: every check emits an INDEPENDENT EVIDENCE TRAIL (verbatim commands
# executed + raw output captured) so any PASS is reproducible from the artifact.

set -euo pipefail

# ----- locate substrate ------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUBSTRATE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPO_ROOT="$(cd "${SUBSTRATE_DIR}/.." && pwd)"

# ----- argument parsing ------------------------------------------------------

SPEC_PATH="SPECIFICATION.md"
ARTIFACT_PATH="agents/observation/spec-validation/mechanical-check-results.md"

print_help() {
  sed -n '3,40p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --spec)
      shift
      SPEC_PATH="${1:?--spec requires an argument}"
      shift
      ;;
    --write-artifact)
      shift
      ARTIFACT_PATH="${1:?--write-artifact requires an argument}"
      shift
      ;;
    --help|-h)
      print_help
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      print_help >&2
      exit 4
      ;;
  esac
done

# ----- preconditions ---------------------------------------------------------

if ! command -v python >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python (or python3) not found in PATH" >&2
  exit 2
fi
PYTHON_BIN="$(command -v python || command -v python3)"

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not found in PATH" >&2
  exit 2
fi

# ----- run the 7 mechanical checks via the Python runner --------------------
#
# The Python runner aggregates structured per-check records (checks 1-7),
# emits the per-check verdict to stdout (one line per check), and writes the
# Markdown artifact to ARTIFACT_PATH.
#
# Checks 1 / 2 / 3 / 6 / 7 delegate to Python helpers under _lib/ for the
# parsing-heavy paths (per save-verdict R2 LOCKED invocation contract).
# Checks 4 / 5 are pure-Python inline (trivially shell-translatable but kept
# in the runner for evidence-trail aggregation symmetry).

cd "${REPO_ROOT}"
"${PYTHON_BIN}" "${SCRIPT_DIR}/_check_runner.py" \
  --spec "${SPEC_PATH}" \
  --write-artifact "${ARTIFACT_PATH}" \
  --repo-root "${REPO_ROOT}"

# Always exit 0 on successful execution per A20
exit 0
