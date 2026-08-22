"""
trailers.py — check-7: git log trailer-detection with bb12806 carve-out
              + post-Arc-40 ancestry-from-dbb5b81 enforcement.

Walks first-parent main commits matching '^Arc ' subjects (squash-merge ships).
For each commit:
    (a) bb12806* short-SHA → CARVE-OUT (Arc 37; documented historical exception
        per CLAUDE.md no-force-push rule + Arc 40 §5.10 retroactive canon)
    (b) commit reachable from dbb5b81 (Arc 40 ship — the canon-shipping commit
        itself; dbb5b81 IS the canon-shipping anchor): if trailer absent →
        FAIL (A21 §25 PRINCIPAL-gate trigger 2 = substance disagreement)
    (c) commit NOT reachable from dbb5b81 (pre-Arc-40 timeline): missing trailer
        is silent failure being closed by Arc 40 ship — record as PASS-PRE-CANON
        (not a §25 escalation; documented timeline-position annotation)

Empirical anchor (live ground-checked 2026-05-18):
    git log -1 --pretty='%(trailers:key=Co-Authored-By)' dbb5b81
        → "Co-authored-by: CAPTAIN_DAEDALUS_the-stoa <...>" (lowercase-by)
    git log -1 --pretty='%(trailers:key=Co-Authored-By)' bb12806
        → "" (empty — historical exception per carve-out)

CRITICAL: git's %(trailers:key=...) formatter case-canonicalizes output to
"Co-authored-by:" regardless of what the commit author wrote. Helper code
MUST use case-insensitive trailer-key match (per §1.1.a empirical-anchor honesty).

Invocation:
    python substrate/skills/validate-spec/_lib/trailers.py [--repo-root <path>]

Output: JSONL per-commit records + summary.
Exit code: always 0 on successful run.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys


# Carve-out SHA (short, prefix-match to avoid brittleness if git default
# short-SHA length changes between versions)
_CARVE_OUT_SHA_PREFIX = "bb12806"

# Canon-shipping commit: Arc 40 ship (dbb5b81). Commits reachable from this
# (i.e., ancestors OR dbb5b81 itself) are PRE-CANON; commits NOT reachable
# from dbb5b81 (i.e., authored AFTER dbb5b81) are POST-CANON and MUST carry trailers.
_CANON_SHIPPING_SHA = "dbb5b81"

# Re-match trailer-key case-insensitively
_RE_CO_AUTHORED_BY = re.compile(r"co-authored-by:", re.IGNORECASE)


def _git_repo_root() -> pathlib.Path | None:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        )
        return pathlib.Path(result.stdout.strip()).resolve()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def _git(args: list[str], repo_root: pathlib.Path) -> tuple[str, int]:
    try:
        result = subprocess.run(
            ["git"] + args,
            capture_output=True, text=True, cwd=str(repo_root), timeout=60,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return (f"git error: {exc}", -1)
    return (result.stdout if result.returncode == 0 else result.stderr, result.returncode)


def _list_arc_squash_merges(repo_root: pathlib.Path) -> list[tuple[str, str]]:
    """Return [(short_sha, subject), ...] for first-parent main commits matching '^Arc '."""
    out, rc = _git(
        ["log", "--first-parent", "main", "--grep=^Arc ", "--pretty=%h %s"],
        repo_root,
    )
    if rc != 0:
        return []
    commits = []
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split(" ", 1)
        if len(parts) == 2:
            commits.append((parts[0], parts[1]))
    return commits


def _commit_trailers(short_sha: str, repo_root: pathlib.Path) -> str:
    """Return raw trailer output for a commit."""
    out, _ = _git(
        ["log", "-1", "--pretty=%(trailers:key=Co-Authored-By)", short_sha],
        repo_root,
    )
    return out


def _is_reachable_from(commit: str, ancestor: str, repo_root: pathlib.Path) -> bool:
    """True if `ancestor` is an ancestor of `commit` OR equal to it.

    Used to determine whether `commit` is in the post-canon timeline (ancestor
    NOT reachable from commit → commit was authored before ancestor).

    Returns True if `commit` has `ancestor` as an ancestor (commit is post-canon
    OR equal to canon-shipping commit); False if `ancestor` is NOT an ancestor
    (commit is pre-canon).
    """
    # git merge-base --is-ancestor <ancestor> <commit> exits 0 if ancestor is reachable from commit
    _, rc = _git(
        ["merge-base", "--is-ancestor", ancestor, commit],
        repo_root,
    )
    return rc == 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="check-7: trailer detection for post-Arc-35 squash-merges (with bb12806 carve-out)"
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

    commits = _list_arc_squash_merges(repo_root)

    pass_count = 0
    pass_pre_canon_count = 0
    carve_out_count = 0
    fail_count = 0

    for short_sha, subject in commits:
        # Check carve-out FIRST — bb12806 is the documented historical exception
        if short_sha.startswith(_CARVE_OUT_SHA_PREFIX):
            record = {
                "sha": short_sha,
                "subject": subject,
                "trailer_present": False,
                "verdict": "CARVE-OUT",
                "reason": f"bb12806 historical exception per CLAUDE.md no-force-push + Arc 40 §5.10 retroactive canon",
            }
            carve_out_count += 1
            print(json.dumps(record))
            continue

        trailers_raw = _commit_trailers(short_sha, repo_root)
        trailer_present = bool(_RE_CO_AUTHORED_BY.search(trailers_raw))

        # Determine pre/post canon timeline-position via ancestry from dbb5b81
        # If dbb5b81 is reachable from this commit (or equal), commit is post-canon (or AT canon)
        # If dbb5b81 NOT reachable, commit is pre-canon
        post_canon = _is_reachable_from(short_sha, _CANON_SHIPPING_SHA, repo_root)

        if trailer_present:
            record = {
                "sha": short_sha,
                "subject": subject,
                "trailer_present": True,
                "trailer_raw": trailers_raw.strip()[:300],
                "post_canon": post_canon,
                "verdict": "PASS",
                "reason": "trailer present",
            }
            pass_count += 1
        else:
            if post_canon:
                # POST-canon commit missing trailer = substance disagreement = §25 gate trigger 2
                record = {
                    "sha": short_sha,
                    "subject": subject,
                    "trailer_present": False,
                    "post_canon": True,
                    "verdict": "FAIL",
                    "reason": f"POST-Arc-40 commit (reachable from {_CANON_SHIPPING_SHA}) MISSING trailer — A21 §25 PRINCIPAL-gate trigger 2 (substance disagreement; Arc 40 §5.10 canon should have prevented)",
                }
                fail_count += 1
            else:
                # PRE-canon commit missing trailer = silent failure being closed by Arc 40
                record = {
                    "sha": short_sha,
                    "subject": subject,
                    "trailer_present": False,
                    "post_canon": False,
                    "verdict": "PASS-PRE-CANON",
                    "reason": f"PRE-Arc-40 commit (not reachable from {_CANON_SHIPPING_SHA}); missing trailer is silent-failure-class closed by Arc 40 ship — NOT a §25 escalation",
                }
                pass_pre_canon_count += 1

        print(json.dumps(record))

    summary = {
        "summary": True,
        "mode": "check-7",
        "total": pass_count + pass_pre_canon_count + carve_out_count + fail_count,
        "pass": pass_count,
        "pass_pre_canon": pass_pre_canon_count,
        "carve_out": carve_out_count,
        "fail": fail_count,
        "carve_out_sha_prefix": _CARVE_OUT_SHA_PREFIX,
        "canon_shipping_sha": _CANON_SHIPPING_SHA,
    }
    print(json.dumps(summary))
    return 0


if __name__ == "__main__":
    sys.exit(main())
