#!/usr/bin/env bash
#
# run-attribution-advisory-tests.sh — regression corpus for the attribution-advisory
# skill (Arc stoa--p0e). Exercises the REAL advise.sh (no reimplementation) against
# the fixtures/*.diff corpus and asserts the design §10 acceptance bar:
#
#   P1  MUST FLAG   — a modified/deleted existing copyright line -> a PRIMARY finding.
#   P2  MUST NOT    — a new-file PRINCIPAL author field -> 0 findings.
#   P4  NEVER DENY  — every input exits zero + emits no permission-decision output.
#   s1  SECONDARY   — a new non-PRINCIPAL author field (non-vendored) -> SECONDARY.
#   s2  VENDORED    — the same field under node_modules/ -> excluded, 0 findings.
#   n1  NEGATIVE    — an added prose line discussing copyright -> 0 findings.
#   n2  YEAR-BUMP   — a copyright-year bump -> PRIMARY DOES fire (accepted r5 false-
#                     positive; pinned as KNOWN, documented behavior, not a regression).
#
# Exit 0 = all pass. Exit 1 = at least one assertion failed (a regression).
#
# HERMETIC allow-list: the runner writes its OWN principal-identity list (containing
# the PRINCIPAL tokens) into the scratch dir and passes it via --principal-identity,
# so the corpus does not depend on the target's real allow-list.
#
# CLEANUP: a single fixed-literal scratch root, re-typed in the destructive rm (no
# $VAR-derived path in the rm) per operating-disciplines.md §8.6.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ADVISE="${SCRIPT_DIR}/../advise.sh"
FIX="${SCRIPT_DIR}/fixtures"

SCRATCH="${TMPDIR:-/tmp}/stoa-p0e-attr-advisory-test"
cleanup() {
  # Fixed-literal scratch root in the destructive op — no $VAR-derived path.
  rm -rf "${TMPDIR:-/tmp}/stoa-p0e-attr-advisory-test" 2>/dev/null || true
}
trap cleanup EXIT

rm -rf "$SCRATCH" 2>/dev/null || true
mkdir -p "$SCRATCH" || { echo "FATAL: cannot create scratch dir $SCRATCH"; exit 2; }

ALLOWLIST="${SCRATCH}/principal-identity"
{
  echo "# test allow-list"
  echo "denson"
  echo "densonsmith2@gmail.com"
  echo "Denson Smith"
} > "$ALLOWLIST"

REPORT="${SCRATCH}/report.md"
FAILS=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; FAILS=$((FAILS + 1)); }

run() {
  # run <fixture-file> ; captures stdout in OUT, exit code in RC, report in $REPORT
  : > "$REPORT" 2>/dev/null || true
  OUT="$(bash "$ADVISE" --diff-file "$1" --report-out "$REPORT" --principal-identity "$ALLOWLIST" 2>/dev/null)"
  RC=$?
}

# --- P1: MUST FLAG (PRIMARY) ---
run "${FIX}/p1-edit-copyright.diff"
[ "$RC" -eq 0 ] && pass "P1 exit 0" || fail "P1 expected exit 0, got $RC"
grep -q "## PRIMARY" "$REPORT"        && pass "P1 has PRIMARY section" || fail "P1 missing PRIMARY section"
grep -q "LICENSE" "$REPORT"           && pass "P1 names LICENSE"       || fail "P1 missing LICENSE"
grep -q "Jane Doe" "$REPORT"          && pass "P1 shows removed line"  || fail "P1 missing removed 'Jane Doe'"
grep -q "findings: 0" "$REPORT"       && fail "P1 unexpectedly 0 findings" || pass "P1 findings >= 1"

# --- P2: MUST NOT FLAG (clean) ---
run "${FIX}/p2-newfile-principal.diff"
[ "$RC" -eq 0 ] && pass "P2 exit 0" || fail "P2 expected exit 0, got $RC"
grep -q "findings: 0" "$REPORT"       && pass "P2 reports 0 findings" || fail "P2 expected 0 findings"
grep -q "## PRIMARY" "$REPORT"        && fail "P2 unexpected PRIMARY"  || pass "P2 no PRIMARY"
grep -q "## SECONDARY" "$REPORT"      && fail "P2 unexpected SECONDARY (principal on allow-list)" || pass "P2 no SECONDARY"

# --- s1: SECONDARY flags a non-PRINCIPAL new author field ---
run "${FIX}/s1-newfile-nonprincipal.diff"
[ "$RC" -eq 0 ] && pass "s1 exit 0" || fail "s1 expected exit 0, got $RC"
grep -q "## SECONDARY" "$REPORT"      && pass "s1 has SECONDARY section" || fail "s1 missing SECONDARY"
grep -q "Mallory Example" "$REPORT"   && pass "s1 names the value"       || fail "s1 missing 'Mallory Example'"

# --- s2: vendored path excluded ---
run "${FIX}/s2-vendored-nonprincipal.diff"
[ "$RC" -eq 0 ] && pass "s2 exit 0" || fail "s2 expected exit 0, got $RC"
grep -q "findings: 0" "$REPORT"       && pass "s2 excluded (0 findings)" || fail "s2 expected 0 findings (vendored)"

# --- n1: prose discussing copyright -> no finding ---
run "${FIX}/n1-copyright-prose.diff"
[ "$RC" -eq 0 ] && pass "n1 exit 0" || fail "n1 expected exit 0, got $RC"
grep -q "findings: 0" "$REPORT"       && pass "n1 no finding" || fail "n1 expected 0 findings (prose)"

# --- n2: year-bump -> PRIMARY DOES fire (accepted r5 false-positive, documented) ---
run "${FIX}/n2-year-bump.diff"
[ "$RC" -eq 0 ] && pass "n2 exit 0" || fail "n2 expected exit 0, got $RC"
grep -q "## PRIMARY" "$REPORT"        && pass "n2 PRIMARY fires (accepted name-agnostic r5)" || fail "n2 expected PRIMARY (name-agnostic)"

# --- P4: NEVER DENY / NEVER non-zero (report-only proven) ---
# four inputs: flagging, clean, empty, malformed
p4_check() {
  # $1 = label ; stdin carries the diff ; asserts exit 0 + no deny tokens
  local label="$1" o rc
  o="$(cat | bash "$ADVISE" --stdin --report-out "$REPORT" --principal-identity "$ALLOWLIST" 2>/dev/null)"; rc=$?
  [ "$rc" -eq 0 ] && pass "P4 $label exit 0" || fail "P4 $label expected exit 0, got $rc"
  if printf '%s' "$o" | grep -qE 'permissionDecision|"deny"'; then fail "P4 $label stdout carried a deny token"; else pass "P4 $label stdout clean"; fi
  if grep -qE 'permissionDecision|"deny"' "$REPORT" 2>/dev/null; then fail "P4 $label report carried a deny token"; else pass "P4 $label report clean"; fi
}
cat "${FIX}/p1-edit-copyright.diff" | p4_check "flagging"
cat "${FIX}/p2-newfile-principal.diff" | p4_check "clean"
printf '' | p4_check "empty"
printf 'not a diff\n@@ garbage\n' | p4_check "malformed"

# --- Static assert: advise.sh has no reachable deny / non-zero-exit path ---
if grep -nE 'exit [12]|permissionDecision|"deny"' "$ADVISE" >/dev/null 2>&1; then
  fail "advise.sh contains a reachable deny / non-zero-exit token (report-only property broken)"
else
  pass "advise.sh static: no exit 1/2, no permissionDecision, no deny token"
fi

echo "----"
if [ "$FAILS" -eq 0 ]; then
  echo "ALL PASS"
  exit 0
else
  echo "FAILURES: $FAILS"
  exit 1
fi
