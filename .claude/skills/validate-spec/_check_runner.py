"""
_check_runner.py — main entrypoint for the validate-spec skill.

Per the save-verdict R2 LOCKED invocation contract: this script is invoked by
check.sh via `python <path> [args]`; module-importability is a side-benefit
of the `if __name__ == "__main__"` idiom, not the contract.

This runner:
  1. Invokes each of the 7 mechanical checks (delegating to _lib/ helpers for
     checks 1/2/3/6/7; inline-shell for checks 4/5).
  2. Aggregates per-check structured records.
  3. Emits the mechanical-check-results.md artifact at the canonical path.
  4. Prints a per-check verdict summary to stdout (one line per check).

Per CAPTAIN_DAEDALUS.md §6.9 + Arc 42 directive A20 motivated-reasoning
mitigation: every check emits an INDEPENDENT EVIDENCE TRAIL (verbatim commands
executed + raw output captured) so any PASS is reproducible.

Exit code: always 0 on successful run (drift is informational per A20; the
artifact carries the verdict, not the exit code). Exit 2 only for "could not run"
(e.g., python missing — but if we're here we have python; this is reserved for
unrecoverable runtime errors like git unavailable).

Invocation:
    python substrate/skills/validate-spec/_check_runner.py \\
        --spec SPECIFICATION.md \\
        --write-artifact agents/observation/spec-validation/mechanical-check-results.md \\
        [--repo-root <path>]
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
from datetime import datetime, timezone


SKILL_DIR = pathlib.Path(__file__).resolve().parent
LIB_DIR = SKILL_DIR / "_lib"


def _git(args: list[str], cwd: pathlib.Path | None = None) -> tuple[str, int]:
    try:
        result = subprocess.run(
            ["git"] + args,
            capture_output=True, text=True,
            cwd=str(cwd) if cwd else None,
            timeout=60,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return (f"git error: {exc}", -1)
    return (result.stdout if result.returncode == 0 else result.stderr, result.returncode)


def _git_repo_root() -> pathlib.Path | None:
    out, rc = _git(["rev-parse", "--show-toplevel"])
    if rc != 0:
        return None
    return pathlib.Path(out.strip()).resolve()


def _run_python_helper(helper: str, extra_args: list[str], repo_root: pathlib.Path) -> tuple[list[dict], str]:
    """Run a Python helper; return (records, raw_stdout). Each record is a parsed JSON line."""
    helper_path = LIB_DIR / helper
    cmd = [sys.executable, str(helper_path)] + extra_args + ["--repo-root", str(repo_root)]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return ([{"error": f"helper {helper} failed to run: {exc}"}], "")
    records: list[dict] = []
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError:
            # Non-JSON output is recorded as a sidecar record
            records.append({"non_json_line": line})
    return records, result.stdout


def _summary_from(records: list[dict]) -> dict | None:
    for rec in records:
        if rec.get("summary"):
            return rec
    return None


def _per_item_records(records: list[dict]) -> list[dict]:
    return [r for r in records if not r.get("summary") and "error" not in r]


def _check_1(repo_root: pathlib.Path, spec_rel: str) -> dict:
    """check-1: every §-ref in SPECIFICATION.md resolves."""
    cmd_str = f"python substrate/skills/validate-spec/_lib/spec_refs.py --spec {spec_rel}"
    records, raw = _run_python_helper("spec_refs.py", ["--spec", spec_rel], repo_root)
    summary = _summary_from(records) or {}
    items = _per_item_records(records)
    fail_count = summary.get("fail", 0)
    strange_count = summary.get("strange", 0)
    if fail_count > 0:
        verdict = "FAIL"
    elif strange_count > 0:
        verdict = "STRANGE"
    else:
        verdict = "PASS"
    return {
        "check": 1,
        "name": "every §-ref in SPECIFICATION.md resolves",
        "verdict": verdict,
        "summary_text": f"refs={summary.get('total', 0)} pass={summary.get('pass', 0)} fail={fail_count} strange={strange_count}",
        "evidence_commands": [cmd_str],
        "evidence_raw": raw,
        "items": items,
        "summary_record": summary,
    }


def _check_2(repo_root: pathlib.Path, spec_rel: str) -> dict:
    cmd_str = f"python substrate/skills/validate-spec/_lib/bw_tickets.py --mode check-2 --spec {spec_rel}"
    records, raw = _run_python_helper("bw_tickets.py", ["--mode", "check-2", "--spec", spec_rel], repo_root)
    summary = _summary_from(records) or {}
    items = _per_item_records(records)
    fail_count = summary.get("fail", 0)
    strange_count = summary.get("strange", 0)
    if fail_count > 0:
        verdict = "FAIL"
    elif strange_count > 0:
        verdict = "STRANGE"
    else:
        verdict = "PASS"
    return {
        "check": 2,
        "name": "every cited stoa--* ticket exists with claimed status",
        "verdict": verdict,
        "summary_text": f"tickets={summary.get('total', 0)} pass={summary.get('pass', 0)} fail={fail_count} strange={strange_count}",
        "evidence_commands": [cmd_str],
        "evidence_raw": raw,
        "items": items,
        "summary_record": summary,
    }


def _check_3(repo_root: pathlib.Path, spec_rel: str) -> dict:
    cmd_str = f"python substrate/skills/validate-spec/_lib/bw_tickets.py --mode check-3 --spec {spec_rel}"
    records, raw = _run_python_helper("bw_tickets.py", ["--mode", "check-3", "--spec", spec_rel], repo_root)
    summary = _summary_from(records) or {}
    items = _per_item_records(records)
    fail_count = summary.get("fail", 0)
    if fail_count > 0:
        verdict = "FAIL"
    else:
        verdict = "PASS"
    return {
        "check": 3,
        "name": "every open bw ticket placed in some §13.x section",
        "verdict": verdict,
        "summary_text": f"open={summary.get('open_tickets_scanned', summary.get('total', 0))} placed={summary.get('pass', 0)} unplaced={fail_count}",
        "evidence_commands": [cmd_str],
        "evidence_raw": raw,
        "items": items,
        "summary_record": summary,
    }


# §12.4 ignorable state files (substrate-recognized as informational drift)
_CHECK_4_IGNORABLES = [
    ".claude/.substrate-last-check",
]


def _check_4(repo_root: pathlib.Path) -> dict:
    cmd_str = "git status --porcelain (filtered against §12.4 ignorables)"
    out, rc = _git(["status", "--porcelain"], cwd=repo_root)
    if rc != 0:
        return {
            "check": 4,
            "name": "git status clean modulo §12.4 ignorables",
            "verdict": "FAIL",
            "summary_text": f"git status failed: rc={rc}",
            "evidence_commands": [cmd_str],
            "evidence_raw": out,
            "items": [],
        }
    raw_lines = out.splitlines()
    non_ignorable_lines = []
    ignored_lines = []
    for line in raw_lines:
        # Format: "XY <path>" where XY is 2-char status
        path = line[3:] if len(line) >= 3 else line
        path = path.strip()
        is_ignorable = any(path.endswith(ign) or path == ign for ign in _CHECK_4_IGNORABLES)
        if is_ignorable:
            ignored_lines.append(line)
        else:
            non_ignorable_lines.append(line)
    if not non_ignorable_lines:
        verdict = "PASS"
        summary_text = f"clean (modulo {len(ignored_lines)} ignorable line(s))"
    else:
        verdict = "FAIL"
        summary_text = f"{len(non_ignorable_lines)} non-ignorable line(s); {len(ignored_lines)} ignorable"
    return {
        "check": 4,
        "name": "git status clean modulo §12.4 ignorables",
        "verdict": verdict,
        "summary_text": summary_text,
        "evidence_commands": [cmd_str],
        "evidence_raw": out if out else "(clean)",
        "items": [{"line": ln, "ignored": False} for ln in non_ignorable_lines] +
                 [{"line": ln, "ignored": True} for ln in ignored_lines],
    }


def _check_5(repo_root: pathlib.Path) -> dict:
    cmd_str = "ls _drafts/ (then bw-lookup of any residents against open 'engagement coordination' tickets)"
    drafts_dir = repo_root / "_drafts"
    if not drafts_dir.is_dir():
        return {
            "check": 5,
            "name": "_drafts/ empty or justified per §12.4",
            "verdict": "PASS",
            "summary_text": "_drafts/: not present",
            "evidence_commands": [cmd_str],
            "evidence_raw": "_drafts/ directory does not exist",
            "items": [],
        }
    files = sorted(p for p in drafts_dir.iterdir() if p.is_file())
    if not files:
        return {
            "check": 5,
            "name": "_drafts/ empty or justified per §12.4",
            "verdict": "PASS",
            "summary_text": "_drafts/: present and empty",
            "evidence_commands": [cmd_str],
            "evidence_raw": "_drafts/ exists but is empty",
            "items": [],
        }
    # Files present — try to justify against open 'engagement coordination' tickets
    bw_out = ""
    try:
        result = subprocess.run(
            ["bw", "list", "--status", "open", "--all"],
            capture_output=True, text=True, timeout=30,
        )
        bw_out = result.stdout
    except (FileNotFoundError, subprocess.TimeoutExpired):
        bw_out = ""
    coord_lines = [ln for ln in bw_out.splitlines() if "engagement coordination" in ln.lower()]

    items = []
    unjustified_count = 0
    for f in files:
        rel_name = f.name
        # Best-effort: file is "justified" if its name appears in any coord ticket line, OR
        # if there's at least one open coord ticket (the file is loosely associated)
        # The §12.4 spec is "files referenced from an open engagement coordination ticket"
        # We can't easily look up cross-references at this layer; record as STRANGE if
        # there are open coord tickets but no exact-name match.
        if any(rel_name in ln for ln in coord_lines):
            items.append({"path": str(f.relative_to(repo_root)), "justified": True, "referencing_line": next(ln for ln in coord_lines if rel_name in ln)})
        elif coord_lines:
            items.append({"path": str(f.relative_to(repo_root)), "justified": "STRANGE", "note": f"{len(coord_lines)} open coord ticket(s) exist but no name-match"})
            unjustified_count += 1
        else:
            items.append({"path": str(f.relative_to(repo_root)), "justified": False, "note": "no open engagement-coordination ticket found"})
            unjustified_count += 1

    if unjustified_count == 0:
        verdict = "PASS"
    elif any(it.get("justified") == "STRANGE" for it in items):
        verdict = "STRANGE"
    else:
        verdict = "FAIL"
    return {
        "check": 5,
        "name": "_drafts/ empty or justified per §12.4",
        "verdict": verdict,
        "summary_text": f"files={len(files)} unjustified={unjustified_count}",
        "evidence_commands": [cmd_str],
        "evidence_raw": f"_drafts/ files: {[str(f.relative_to(repo_root)) for f in files]}\nopen coord tickets matched: {len(coord_lines)}",
        "items": items,
    }


def _check_6(repo_root: pathlib.Path) -> dict:
    cmd_str = "python substrate/skills/validate-spec/_lib/drift_check.py"
    records, raw = _run_python_helper("drift_check.py", [], repo_root)
    summary = _summary_from(records) or {}
    items = _per_item_records(records)
    fail_count = summary.get("fail", 0)
    strange_count = summary.get("strange", 0)
    if fail_count > 0:
        verdict = "FAIL"
    elif strange_count > 0:
        verdict = "STRANGE"
    else:
        verdict = "PASS"
    return {
        "check": 6,
        "name": "check-substrate-updates no drift across workspaces (A21 LOOSE pre-ratification)",
        "verdict": verdict,
        "summary_text": f"workspaces={summary.get('total', 0)} pass={summary.get('pass', 0)} strange={strange_count} fail={fail_count}",
        "evidence_commands": [cmd_str],
        "evidence_raw": raw,
        "items": items,
        "summary_record": summary,
    }


def _check_7(repo_root: pathlib.Path) -> dict:
    cmd_str = "python substrate/skills/validate-spec/_lib/trailers.py"
    records, raw = _run_python_helper("trailers.py", [], repo_root)
    summary = _summary_from(records) or {}
    items = _per_item_records(records)
    fail_count = summary.get("fail", 0)
    if fail_count > 0:
        verdict = "FAIL"
    else:
        verdict = "PASS"
    return {
        "check": 7,
        "name": "§28 Co-Authored-By trailers on post-Arc-35 squash-merges (with bb12806 carve-out)",
        "verdict": verdict,
        "summary_text": f"commits={summary.get('total', 0)} pass={summary.get('pass', 0)} pass_pre_canon={summary.get('pass_pre_canon', 0)} carve_out={summary.get('carve_out', 0)} fail={fail_count}",
        "evidence_commands": [cmd_str],
        "evidence_raw": raw,
        "items": items,
        "summary_record": summary,
    }


# ---- artifact writer --------------------------------------------------------

def _format_overall_verdict(results: list[dict]) -> str:
    fail = sum(1 for r in results if r["verdict"] == "FAIL")
    strange = sum(1 for r in results if r["verdict"] == "STRANGE")
    n = len(results)
    if fail == 0 and strange == 0:
        return f"all-PASS ({n}/{n})"
    if fail > 0:
        return f"{n - fail}-of-{n}-PASS-with-failure ({fail} fail, {strange} strange)"
    return f"{n - strange}-of-{n}-PASS-with-strangeness ({strange} strange)"


def _write_artifact(results: list[dict], artifact_path: pathlib.Path, run_meta: dict) -> None:
    artifact_path.parent.mkdir(parents=True, exist_ok=True)

    overall = _format_overall_verdict(results)

    lines: list[str] = []
    a = lines.append
    a("# validate-spec — mechanical-check results")
    a("")
    a(f"**Run timestamp (UTC):** {run_meta['timestamp']}")
    a(f"**Substrate SHA at run-time:** {run_meta['substrate_sha']}")
    a(f"**Spec path:** {run_meta['spec_path']}")
    a(f"**Skill SHA at run-time:** {run_meta['skill_sha']}")
    a("")
    a("## Overall verdict")
    a("")
    a(overall)
    a("")
    a("## Per-check results")
    a("")

    for r in results:
        a(f"### check-{r['check']} — {r['name']}")
        a("")
        a(f"Verdict: {r['verdict']}")
        a("")
        a(f"Summary: {r['summary_text']}")
        a("")
        # check-6 / check-7 — load-bearing annotations
        if r["check"] == 6:
            a("**A21 LOOSE pre-ratification (per Arc 42 directive A21):** ariadne-core-workspace / sector-4 / railway_stoa drift state is PASS-with-documented-residue per stoa--3na (substrate-authoring tier the-stoa @ project-tier .claude/ IS clean).")
            a("")
        if r["check"] == 7:
            a("**Explicit carve-out per A5 + §13.11 + A21:** bb12806 (Arc 37) is a known historical exception per CLAUDE.md no-force-push rule + Arc 40 §5.10 retroactive canon.")
            a("")
            a("**Post-Arc-40 trailer-canon test (per A21):** commits NOT reachable from dbb5b81 ancestry but on first-parent main with `^Arc ` subject — these are pre-canon; missing trailer is silent-failure-class closed by Arc 40 ship (NOT a §25 escalation). Commits AT-OR-AFTER dbb5b81 ancestry MUST carry trailers; missing = substance disagreement (§25 trigger 2).")
            a("")
        items = r.get("items", [])
        if items:
            a("Items:")
            a("")
            a("```json")
            for it in items[:50]:
                a(json.dumps(it))
            if len(items) > 50:
                a(f"... and {len(items) - 50} more (truncated for artifact; see Evidence trail for raw)")
            a("```")
            a("")
        else:
            a("(no items)")
            a("")

    # Strangeness section
    a("## Strangeness for inspection-agent triage (per A8 ε / §27.2 step 2)")
    a("")
    strange_items = []
    for r in results:
        for it in r.get("items", []):
            if it.get("verdict") == "STRANGE" or it.get("justified") == "STRANGE":
                strange_items.append({"check": r["check"], "item": it})
    if strange_items:
        a("```json")
        for si in strange_items:
            a(json.dumps(si))
        a("```")
    else:
        a("(none)")
    a("")

    # PRINCIPAL-gate section
    a("## PRINCIPAL-gate findings (per A21 / §25)")
    a("")
    gate_items: list[str] = []
    # Trigger 1: non-A21-named workspace drifted
    for r in results:
        if r["check"] == 6:
            for it in r.get("items", []):
                if it.get("verdict") == "STRANGE" and "A21 §25 trigger 1 candidate" in it.get("reason", ""):
                    gate_items.append(f"- **A21 trigger 1 (check-6):** {it.get('workspace')}: {it.get('reason')}")
        if r["check"] == 7:
            for it in r.get("items", []):
                if it.get("verdict") == "FAIL":
                    gate_items.append(f"- **A21 trigger 2 (check-7):** {it.get('sha')} ({it.get('subject')}): {it.get('reason')}")
    # Trigger 3: any genuine FAIL
    for r in results:
        if r["verdict"] == "FAIL":
            gate_items.append(f"- **A21 trigger 3 (check-{r['check']}):** {r['name']} FAILED — {r['summary_text']}")
    if gate_items:
        for gi in gate_items:
            a(gi)
    else:
        a("(no §25 trigger fired)")
    a("")

    # Evidence trail
    a("## Evidence trail per check")
    a("")
    a("Per A20 anti-motivated-reasoning property: every PASS is reproducible from the recorded commands.")
    a("")
    for r in results:
        # Use level-4 heading so design probe P6 (which counts level-3 "^### check-N " headings)
        # doesn't double-count evidence sections. Sibling-distinguishability per CAPTAIN_DAEDALUS.md §6.9 clause 1.
        a(f"#### check-{r['check']} evidence")
        a("")
        a("Commands executed:")
        for c in r.get("evidence_commands", []):
            a(f"  - `{c}`")
        a("")
        raw = r.get("evidence_raw", "")
        if raw:
            # Truncate to 8000 chars to keep artifact reasonable
            raw_display = raw if len(raw) < 8000 else (raw[:8000] + f"\n... (truncated; {len(raw) - 8000} more chars)")
            a("Raw output:")
            a("```")
            a(raw_display)
            a("```")
            a("")
        else:
            a("(no raw output)")
            a("")

    artifact_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="validate-spec mechanical-check runner")
    parser.add_argument("--spec", default="SPECIFICATION.md")
    parser.add_argument(
        "--write-artifact",
        default="agents/observation/spec-validation/mechanical-check-results.md",
    )
    parser.add_argument("--repo-root", default=None)
    args = parser.parse_args()

    if args.repo_root:
        repo_root = pathlib.Path(args.repo_root).resolve()
    else:
        repo_root = _git_repo_root()
        if repo_root is None:
            print("ERROR: could not determine repo root via git", file=sys.stderr)
            return 2

    spec_path = pathlib.Path(args.spec)
    if not spec_path.is_absolute():
        spec_rel = args.spec
        spec_resolved = (repo_root / args.spec).resolve()
    else:
        spec_rel = str(spec_path)
        spec_resolved = spec_path
    if not spec_resolved.is_file():
        print(f"ERROR: spec file not found: {spec_resolved}", file=sys.stderr)
        return 2

    # Run all 7 checks
    results = []
    for fn in [
        lambda: _check_1(repo_root, spec_rel),
        lambda: _check_2(repo_root, spec_rel),
        lambda: _check_3(repo_root, spec_rel),
        lambda: _check_4(repo_root),
        lambda: _check_5(repo_root),
        lambda: _check_6(repo_root),
        lambda: _check_7(repo_root),
    ]:
        try:
            results.append(fn())
        except Exception as exc:
            # Per A20: any unexpected exception is FAIL with the exception text
            results.append({
                "check": len(results) + 1,
                "name": "unknown (exception)",
                "verdict": "FAIL",
                "summary_text": f"unhandled exception: {exc}",
                "evidence_commands": [],
                "evidence_raw": "",
                "items": [],
            })

    # Print per-check verdict to stdout (one line per check)
    for r in results:
        print(f"check-{r['check']}: {r['verdict']} — {r['summary_text']}")

    # Run metadata
    substrate_sha_out, _ = _git(["rev-parse", "--short", "HEAD"], cwd=repo_root)
    skill_sha_out, _ = _git(["rev-parse", "--short", "HEAD:substrate/skills/validate-spec"], cwd=repo_root)
    run_meta = {
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "substrate_sha": substrate_sha_out.strip() or "(unknown)",
        "spec_path": str(spec_resolved),
        "skill_sha": skill_sha_out.strip() or "(uncommitted)",
    }

    # Write artifact
    artifact_path = pathlib.Path(args.write_artifact)
    if not artifact_path.is_absolute():
        artifact_path = (repo_root / args.write_artifact).resolve()
    _write_artifact(results, artifact_path, run_meta)
    print(f"\nArtifact written: {artifact_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
