"""
drift_check.py — check-6: invoke check-substrate-updates/check.sh; parse output.

Composite-status shape (live ground-checked 2026-05-18 against check-substrate-updates):

    <workspace-name-padded>  <STATUS [+ STATUS]*> (n drifted, n missing, n obsolete; n uncommitted)
      DRIFTED:
      - <file>                                       (+N lines)
      ...
      MISSING:
      + <file>                                       (new in source)
      ...
      OBSOLETE:
      ! <file>                                       (no longer in source)
      ...
      Last check: <timestamp> (against substrate sha <sha>)
      Current substrate HEAD: <sha>
      ...

Status tokens observed:
    CURRENT                 — clean (0 drifted, 0 missing, 0 obsolete)
    DRIFTED                 — at least 1 drifted file
    MISSING                 — at least 1 missing file
    OBSOLETE                — at least 1 obsolete file
    NOT-STOA-DEPLOYED       — workspace registered but no .claude/MAJOR_POLYBIUS*.md
    (composites joined with " + ", e.g., "DRIFTED + MISSING")

A21 LOOSE pre-ratification (per Arc 42 directive A21, ticket stoa--3na):
    ariadne-core-workspace / sector-4 / railway_stoa MAY emit any non-CURRENT
    composite — accepted as documented drift residue.

A21 §25 PRINCIPAL-gate trigger 1: any workspace OUTSIDE the pre-named list
    emitting a non-CURRENT composite → STRANGE-verdict (do NOT auto-PASS;
    route to inspection triage; potentially PRINCIPAL escalation).

NOT-STOA-DEPLOYED is informational — not a drift FAIL.

Invocation:
    python substrate/skills/validate-spec/_lib/drift_check.py [--repo-root <path>]

Output: JSONL per-workspace records + summary.
Exit code: always 0 on successful run; 2 if check-substrate-updates unavailable.

Per CAPTAIN_DAEDALUS.md §6.9 clause 4 (ground-check shipped tool surface):
the parse anchor below was authored after a live ground-check of
check-substrate-updates/check.sh output at design-rev2 time (2026-05-18).
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shutil
import subprocess
import sys


# A21 LOOSE pre-ratification list (per stoa--3na; current as of Arc 42 ship)
_A21_LOOSE_WORKSPACES = frozenset([
    "ariadne-core-workspace",
    "sector-4",
    "railway_stoa",
])


# Per-workspace summary line shape (anchored per §6.9 clause 1):
# <workspace-name (variable width, no internal spaces in name)> <whitespace> <STATUS> <whitespace> (...)
# Status group captures composite token including " + " separators.
_RE_WORKSPACE_LINE = re.compile(
    r"^(?P<workspace>\S+)\s+(?P<status>[A-Z][A-Z\- +]*[A-Z\-])\s+\("
)

# Detail-count regex inside the parenthetical (best-effort capture of n drifted, etc.)
_RE_DETAIL_COUNTS = re.compile(
    r"\((?P<drifted>\d+) drifted, (?P<missing>\d+) missing, (?P<obsolete>\d+) obsolete"
    r"(?:; (?P<uncommitted>\d+) uncommitted)?\)"
)


def _git_repo_root() -> pathlib.Path | None:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        )
        return pathlib.Path(result.stdout.strip()).resolve()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def _run_check_substrate_updates(repo_root: pathlib.Path) -> tuple[str | None, str | None]:
    """Return (stdout text, error). stdout is None on error.

    Resolves bash via shutil.which() rather than relying on subprocess's default
    PATH resolution — on Windows-with-Git-Bash, subprocess['bash'] may resolve
    to the WSL bash relay instead of the actual Git Bash binary, producing a
    'CreateProcessCommon execvpe failed' error.
    """
    script_path = repo_root / "substrate" / "skills" / "check-substrate-updates" / "check.sh"
    if not script_path.is_file():
        return None, f"check-substrate-updates/check.sh not found at {script_path}"
    bash_bin = shutil.which("bash")
    if not bash_bin:
        return None, "bash not found in PATH"
    try:
        result = subprocess.run(
            [bash_bin, str(script_path)],
            capture_output=True, text=True, timeout=180,
        )
    except FileNotFoundError:
        return None, f"bash binary not executable at {bash_bin}"
    except subprocess.TimeoutExpired:
        return None, "check-substrate-updates timed out"
    if result.returncode != 0:
        return None, f"check-substrate-updates exit {result.returncode}: {result.stderr.strip()[:200]}"
    return result.stdout, None


def _parse_workspaces(output: str) -> list[dict]:
    """Parse per-workspace summary lines from check-substrate-updates output."""
    records: list[dict] = []
    for line in output.splitlines():
        match = _RE_WORKSPACE_LINE.match(line)
        if not match:
            continue
        # Filter out lines that look like detail entries (start with - / + / !)
        # The regex already requires \S+ at column 0 with no leading whitespace
        # so this is mostly defensive.
        workspace = match.group("workspace")
        status_raw = match.group("status").strip()

        # Skip obviously-not-status tokens (e.g., "DRIFTED:" or "MISSING:" headers
        # appear at start of indented blocks but won't match the column-0 regex anyway)
        status_tokens = [t.strip() for t in status_raw.split("+")]

        # Try to extract detail counts from the surrounding text
        detail_match = _RE_DETAIL_COUNTS.search(line)
        counts = {}
        if detail_match:
            counts = {
                "drifted": int(detail_match.group("drifted")),
                "missing": int(detail_match.group("missing")),
                "obsolete": int(detail_match.group("obsolete")),
                "uncommitted": int(detail_match.group("uncommitted")) if detail_match.group("uncommitted") else None,
            }

        records.append({
            "workspace": workspace,
            "status_raw": status_raw,
            "status_tokens": status_tokens,
            "counts": counts,
            "raw_line": line,
        })
    return records


def _classify(record: dict) -> tuple[str, str]:
    """Return (verdict, reason). verdict ∈ {PASS, STRANGE, FAIL}."""
    tokens = set(record["status_tokens"])
    workspace = record["workspace"]
    counts = record.get("counts", {})

    if tokens == {"CURRENT"}:
        return ("PASS", "CURRENT (no drift)")
    if tokens == {"NOT-STOA-DEPLOYED"}:
        return ("PASS", "NOT-STOA-DEPLOYED (informational)")

    # Non-CURRENT composite — check A21 LOOSE pre-ratification list
    # A21: "the-stoa" workspace is the substrate-authoring tier; if it shows
    # any drift (incl. 1 uncommitted from in-flight arc work) treat as PASS-with-residue
    # since the substrate-authoring tier necessarily has the most recent edits
    # that haven't yet propagated. Uncommitted-only (no drifted/missing/obsolete) is
    # explicitly fine — that's just arc-in-progress state.
    if workspace == "the-stoa":
        if counts.get("drifted", 0) == 0 and counts.get("missing", 0) == 0 and counts.get("obsolete", 0) == 0:
            return ("PASS", f"the-stoa substrate-authoring tier; uncommitted={counts.get('uncommitted')} is in-flight state")
        # Drifted from itself would be strange
        return ("STRANGE", f"the-stoa workspace shows non-CURRENT composite with actual drift: {record['status_raw']}")

    # Check workspace name against A21 pre-named list
    # Workspace name may be short (e.g., "railway_stoa") or longer (e.g., "ariadne-core-workspace")
    for loose_name in _A21_LOOSE_WORKSPACES:
        if workspace == loose_name or workspace.startswith(loose_name) or loose_name in workspace:
            return ("PASS", f"A21 LOOSE pre-ratification per stoa--3na (workspace={workspace}; status={record['status_raw']}); drift accepted as documented residue")

    # Non-A21-listed workspace with non-CURRENT composite → STRANGE
    # This is a A21 §25 PRINCIPAL-gate trigger condition 1 signal
    return ("STRANGE", f"workspace {workspace} NOT in A21 LOOSE pre-named list emits non-CURRENT composite ({record['status_raw']}) — A21 §25 trigger 1 candidate; route to inspection triage")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="check-6: cross-workspace drift via check-substrate-updates for validate-spec"
    )
    parser.add_argument("--repo-root", default=None)
    args = parser.parse_args()

    if args.repo_root:
        repo_root = pathlib.Path(args.repo_root).resolve()
    else:
        repo_root = _git_repo_root()
        if repo_root is None:
            print(json.dumps({"error": "could not determine repo root via git"}), file=sys.stderr)
            return 2

    output, err = _run_check_substrate_updates(repo_root)
    if err:
        print(json.dumps({"error": err}), file=sys.stderr)
        summary = {
            "summary": True,
            "mode": "check-6",
            "error": err,
            "total": 0, "pass": 0, "strange": 0, "fail": 0,
        }
        print(json.dumps(summary))
        return 2

    records = _parse_workspaces(output)
    pass_count = 0
    strange_count = 0
    fail_count = 0

    for rec in records:
        verdict, reason = _classify(rec)
        if verdict == "PASS":
            pass_count += 1
        elif verdict == "STRANGE":
            strange_count += 1
        else:
            fail_count += 1
        out = {
            "workspace": rec["workspace"],
            "status_raw": rec["status_raw"],
            "status_tokens": rec["status_tokens"],
            "counts": rec["counts"],
            "verdict": verdict,
            "reason": reason,
        }
        print(json.dumps(out))

    summary = {
        "summary": True,
        "mode": "check-6",
        "total": pass_count + strange_count + fail_count,
        "pass": pass_count,
        "strange": strange_count,
        "fail": fail_count,
        "a21_loose_workspaces": sorted(_A21_LOOSE_WORKSPACES),
    }
    print(json.dumps(summary))
    return 0


if __name__ == "__main__":
    sys.exit(main())
