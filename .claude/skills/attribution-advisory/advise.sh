#!/usr/bin/env bash
#
# advise.sh — Stoa attribution-advisory: a REPORT-ONLY, NEVER-BLOCKING diff scanner.
#
# WHAT THIS IS. A deterministic, operator-invoked reporter that scans a unified
# diff for attribution changes and writes a durable report. It is NOT a hook and
# NOT a gate. It CANNOT block, deny, or fail a commit — the report-only property
# is STRUCTURAL: this script always terminates with a zero status, contains no
# reachable non-zero termination path, and never emits any permission-decision
# JSON. Even if a future operator mis-registered it as a PreToolUse hook, a
# zero-status script that emits no permission-decision output is treated as ALLOW.
#
# It replaces the retired authorship deny-gate (Arc stoa--p0e; see
# substrate/v1-historical/hooks/RETIREMENT.md). The retired gate only ever checked
# direction-1 (an agent naming a non-PRINCIPAL in its OWN new artifact). This
# advisory's PRIMARY check covers direction-2 — the plagiarism / license-breach
# direction: a diff hunk that MODIFIES or DELETES an EXISTING attribution line.
#
# PRIMARY (name-agnostic): any REMOVED (`-`) line that matches an attribution
#   pattern (author/copyright/license/... field, a `Copyright <year> <Name>` form,
#   or an SPDX id) is flagged. Name-agnostic because changing a line that already
#   carried a name is rarely legitimate. It does NOT consult the allow-list.
# SECONDARY (best-effort courtesy): a NEW (`+`) author-like field assignment whose
#   value is NOT on the PRINCIPAL allow-list, in a non-vendored path. FAIL-OPEN:
#   if the allow-list is absent/empty, SECONDARY is skipped (PRIMARY still runs).
#
# INVOCATION:
#   bash advise.sh                       # default: scan `git diff --cached`
#   bash advise.sh --range <BASE>..<HEAD>
#   bash advise.sh --diff-file <path.diff>
#   git diff <range> | bash advise.sh --stdin
# FLAGS:
#   --report-out <path>          report destination (default <workspace>/.claude/attribution-advisory-report.md)
#   --principal-identity <path>  allow-list override (default <workspace>/.claude/hooks/principal-identity;
#                                also settable via STOA_PRINCIPAL_IDENTITY_FILE — used by the test runner
#                                for a hermetic list)
#
# FAIL-OPEN throughout: any error (no python3, unreadable diff, no git) degrades to
# an empty/clean report and a zero exit — never an error that blocks the operator.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || echo .)"
# Deployed at <workspace>/.claude/skills/attribution-advisory/advise.sh, so the
# workspace root is three levels up. Resolved from the script's own location so
# the tool works regardless of the caller's cwd.
WORKSPACE="$(cd "${SCRIPT_DIR}/../../.." 2>/dev/null && pwd || echo .)"

MODE="cached"          # cached | range | difffile | stdin
RANGE=""
DIFF_FILE=""
REPORT_OUT="${WORKSPACE}/.claude/attribution-advisory-report.md"
PRINCIPAL_ID_FILE="${STOA_PRINCIPAL_IDENTITY_FILE:-${WORKSPACE}/.claude/hooks/principal-identity}"

# A value-taking option must be followed by a REAL value — not end-of-args and not
# another --flag. Without this guard `--diff-file --report-out X` would silently
# swallow `--report-out` as the diff-file path. When the expected value is missing
# or is itself a --flag, we WARN to stderr and fall back to the safe default: we do
# NOT consume the next token, do NOT error, and do NOT change the exit status. This
# preserves the load-bearing never-block / always-exit-0 contract (§ the-never-blocks
# contract) while closing the silent next-flag-swallow footgun.
_val_ok() {  # true iff the token is present AND not empty AND not itself a --flag
  case "${1-__STOA_MISSING__}" in
    ""|__STOA_MISSING__|--*) return 1 ;;
    *)                       return 0 ;;
  esac
}
_warn_opt() {  # $1 = option name, $2 = the offending next token (may be empty)
  printf '%s\n' "attribution-advisory: warning: ${1} expects a value but none was given (next token: '${2:-<end-of-args>}'); ignoring it and using the default." >&2
}

while [ "$#" -gt 0 ]; do
  case "${1:-}" in
    --diff-file)
      if _val_ok "${2-__STOA_MISSING__}"; then MODE="difffile"; DIFF_FILE="$2"; shift 2
      else _warn_opt --diff-file "${2:-}"; shift; fi ;;
    --range)
      if _val_ok "${2-__STOA_MISSING__}"; then MODE="range"; RANGE="$2"; shift 2
      else _warn_opt --range "${2:-}"; shift; fi ;;
    --stdin)              MODE="stdin";                        shift ;;
    --report-out)
      if _val_ok "${2-__STOA_MISSING__}"; then REPORT_OUT="$2"; shift 2
      else _warn_opt --report-out "${2:-}"; shift; fi ;;
    --principal-identity)
      if _val_ok "${2-__STOA_MISSING__}"; then PRINCIPAL_ID_FILE="$2"; shift 2
      else _warn_opt --principal-identity "${2:-}"; shift; fi ;;
    *)                                                        shift ;;   # ignore unknown args; never error
  esac
done

SCAN_LABEL="git diff --cached"
case "$MODE" in
  difffile) SCAN_LABEL="diff-file ${DIFF_FILE}" ;;
  range)    SCAN_LABEL="range ${RANGE}" ;;
  stdin)    SCAN_LABEL="stdin" ;;
esac

# Capture the diff into a temp file (a stable input for the scanner). mktemp gives
# a private name; we remove it by that name at the end.
DIFF_TMP="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/stoa-attr-advisory.$$.diff")"

case "$MODE" in
  difffile) [ -n "${DIFF_FILE}" ] && [ -f "${DIFF_FILE}" ] && cat "${DIFF_FILE}" > "${DIFF_TMP}" 2>/dev/null || : ;;
  range)    git -C "${WORKSPACE}" diff "${RANGE}" > "${DIFF_TMP}" 2>/dev/null || : ;;
  stdin)    cat > "${DIFF_TMP}" 2>/dev/null || : ;;
  cached)   git -C "${WORKSPACE}" diff --cached > "${DIFF_TMP}" 2>/dev/null || : ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  # FAIL-OPEN: no scanner runtime. Write a clean report + a zero exit.
  mkdir -p "$(dirname "${REPORT_OUT}")" 2>/dev/null || :
  {
    echo "# Attribution advisory report"
    echo "scanned: ${SCAN_LABEL} · at: (python3 absent) · findings: 0"
    echo "(This is a REPORT, not a block. Nothing was prevented.)"
    echo ""
    echo "python3 is not available on this target, so the advisory scan was skipped (fail-open)."
  } > "${REPORT_OUT}" 2>/dev/null || :
  rm -f "${DIFF_TMP}" 2>/dev/null || :
  echo "attribution-advisory: 0 findings (python3 absent — advisory skipped, fail-open)"
  exit 0
fi

DIFF_FILE_PATH="${DIFF_TMP}" REPORT_OUT="${REPORT_OUT}" PRINCIPAL_ID_FILE="${PRINCIPAL_ID_FILE}" SCAN_LABEL="${SCAN_LABEL}" python3 -c '
import sys, os, re, datetime

diff_path  = os.environ.get("DIFF_FILE_PATH", "")
report_out = os.environ.get("REPORT_OUT", "")
pid_file   = os.environ.get("PRINCIPAL_ID_FILE", "")
scan_label = os.environ.get("SCAN_LABEL", "(unknown)")

try:
    with open(diff_path, "r", errors="replace") as fh:
        diff = fh.read()
except Exception:
    diff = ""

# --- attribution term set: mirrors _hooklib.sh extract_author_fields (SSoT), plus
#     the diff-surface additions license/licensed/attribution/@author/@copyright/SPDX. ---
FIELDS = ["authors","author","owner","creator","created_by","maintainers","maintainer",
          "by","copyright","holder","vendor","publisher","license","licensed","attribution"]
key = "|".join(FIELDS)
field_pat     = re.compile(r"(?i)(?<![A-Za-z0-9_])[\"\x27]?(" + key + r")[\"\x27]?\s*[:=]\s*(.*)$")
at_pat        = re.compile(r"(?i)@(author|copyright)\b")
spdx_pat      = re.compile(r"SPDX-License-Identifier\s*:")
# separator-less copyright: keyword case-insensitive, REQUIRED 4-digit year, then a
# CASE-SENSITIVE capitalized name run (keeps lowercase prose out). Mirrors _hooklib cpat.
copyright_pat = re.compile(r"(?<![A-Za-z0-9_])(?i:copyright)\s+(?:(?:\(c\)|\(C\)|©)\s*)?(?:\d{4}(?:\s*[-,]\s*\d{4})?\s+)([A-Z][A-Za-z.\x27-]*(?:\s+[A-Z][A-Za-z.\x27-]*)*)")

def is_attribution_line(text):
    return bool(field_pat.search(text) or at_pat.search(text) or spdx_pat.search(text) or copyright_pat.search(text))

def clean_one(tok):
    tok = tok.strip()
    m = re.match(r"^[\"\x27](.*?)[\"\x27]", tok)
    if m:
        return m.group(1).strip()
    tok = re.sub(r"^-\s*", "", tok)
    tok = re.split(r"\s#", tok, 1)[0]
    tok = re.split(r"[,}\]]", tok, 1)[0]
    return tok.strip().strip(chr(34) + chr(39)).strip()

def extract_fields(text):
    out = []
    m = field_pat.search(text)
    if not m:
        return out
    field = m.group(1)
    raw = m.group(2).strip()
    if not raw:
        return out
    if raw[:1] == "[":
        inner = raw[1:].split("]", 1)[0]
        for piece in inner.split(","):
            v = clean_one(piece)
            if not v or v[:2] == "{{" or v[:1] in ("<", "$"):
                continue
            out.append((field, v))
        return out
    if raw[:2] == "{{" or raw[:1] in ("<", "$", "{"):
        return out
    val = clean_one(raw.split(",", 1)[0])
    if not val or val[:2] == "{{" or val[:1] in ("<", "$"):
        return out
    out.append((field, val))
    return out

VENDORED = ["node_modules/","vendor/","third_party/","third-party/","thirdparty/",
            "dist/","build/",".venv/","venv/","site-packages/","external/","deps/",
            ".git/","v1-historical/"]
def is_vendored(path):
    return any(v in path for v in VENDORED)

# PRINCIPAL allow-list. Absent OR empty -> SECONDARY disabled (fail-open, the SAFE
# direction for a report-only tool: no noisy false SECONDARY findings).
principals = set()
try:
    with open(pid_file, "r", errors="replace") as fh:
        for line in fh:
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            principals.add(s.lower())
except Exception:
    principals = set()
secondary_enabled = bool(principals)

cur_path = None
cur_hunk = ""
primary = []
secondary = []

for raw in diff.splitlines():
    if raw.startswith("+++ "):
        p = raw[4:].split("\t")[0].strip()
        if p.startswith("b/"):
            p = p[2:]
        cur_path = p
        continue
    if raw.startswith("--- "):
        continue
    if raw.startswith("@@"):
        m = re.match(r"(@@ .*? @@)", raw)
        cur_hunk = m.group(1) if m else raw.rstrip()
        continue
    if raw[:1] in ("", " "):
        continue
    if raw.startswith(("diff ", "index ", "rename ", "similarity ", "new file",
                       "deleted file", "old mode", "new mode", "Binary ", "\\ No newline")):
        continue
    if raw.startswith("-"):
        content = raw[1:]
        if is_attribution_line(content):
            primary.append((cur_path or "(unknown)", cur_hunk, content))
        continue
    if raw.startswith("+"):
        content = raw[1:]
        if secondary_enabled and cur_path and not is_vendored(cur_path):
            for field, value in extract_fields(content):
                if value.lower() not in principals:
                    secondary.append((cur_path, field, value))
        continue

ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
n = len(primary) + len(secondary)
L = []
L.append("# Attribution advisory report")
L.append("scanned: %s · at: %s · findings: %d" % (scan_label, ts, n))
L.append("(This is a REPORT, not a block. Nothing was prevented. Review each finding below.)")
L.append("")
if primary:
    L.append("## PRIMARY — an existing attribution line was MODIFIED or DELETED")
    for path, hunk, content in primary:
        L.append("- file: %s  (hunk %s)" % (path, hunk))
        L.append("  removed: `%s`" % content.strip())
        L.append("  WHY: modifying/deleting a line that already carried an author/copyright/license")
        L.append("       attribution is almost never legitimate — it is the plagiarism / license-breach")
        L.append("       direction (another author\x27s credit erased or replaced).")
        L.append("  WHAT TO CHECK: confirm this change is legitimate (e.g. correcting YOUR OWN name, a")
        L.append("       routine copyright-year bump, or a license reformat); otherwise restore the")
        L.append("       original attribution before committing.")
    L.append("")
if secondary:
    L.append("## SECONDARY — a NEW non-PRINCIPAL author-like field (outside vendored paths)")
    for path, field, value in secondary:
        L.append("- file: %s  (added)" % path)
        L.append("  field: %s = \"%s\"" % (field, value))
        L.append("  WHY: a new author/owner/creator/... field naming someone who is not the PRINCIPAL,")
        L.append("       in a non-vendored path, may be a mis-attribution of the PRINCIPAL\x27s own work.")
        L.append("  WHAT TO CHECK: if this is a CITED source author, move it to prose/citation; if it is")
        L.append("       a legitimate PRINCIPAL identity, add it to .claude/hooks/principal-identity.")
    L.append("")
if n == 0:
    L.append("No attribution findings. (clean)")
    L.append("")
report = "\n".join(L) + "\n"

try:
    d = os.path.dirname(report_out)
    if d and not os.path.isdir(d):
        os.makedirs(d, exist_ok=True)
    with open(report_out, "w") as fh:
        fh.write(report)
except Exception:
    pass

if n == 0:
    sys.stdout.write("attribution-advisory: 0 findings (clean) — see %s\n" % report_out)
else:
    sys.stdout.write("attribution-advisory: %d finding(s) — see %s\n" % (n, report_out))
' 2>/dev/null || :

rm -f "${DIFF_TMP}" 2>/dev/null || :
exit 0
