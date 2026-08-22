#!/usr/bin/env python3
"""whoami — report this Stoa seat's session-identity from $CLAUDE_CODE_SESSION_ID.

stoa--p7c (Arc 67), DC4. The seat's identity comes from the runtime environment variable
CLAUDE_CODE_SESSION_ID:
  - in a TERMINAL session it is the seat's OWN session-id;
  - in a SUB-AGENT it is the CALLER's session-id (the dispatching terminal's sid).

The runtime sets this value; whoami does NOT classify it (no env var discriminates a terminal
seat from a sub-agent — the seat knows its class STRUCTURALLY from its role, and the §28.9
convention selects the output label). The optional --role hint selects only the OUTPUT LABEL
(`sid=` vs `caller-sid=`); the underlying value is the same env var either way.

FAIL-LOUD contract (the MUST): if CLAUDE_CODE_SESSION_ID is empty or unset, whoami prints a
clear error to stderr naming the variable and exits non-zero (exit 2). It does NOT emit a blank
or guessed value, and there is NO workaround fallback (no derivation, no filesystem traversal) —
a missing-identity condition is a LOUD failure, never a silent or confident-wrong sign-tag.

Requires Claude Code >= v2.1.132, where CLAUDE_CODE_SESSION_ID went native (set by the runtime
in every Bash subprocess / hook, zero config). The pre-v2.1.132 SessionStart-hook injection is
an obsolete workaround, not the current mechanism. Below the floor the var is absent and whoami
FAIL-LOUDs (safe). Identity rests on $CLAUDE_CODE_SESSION_ID; if a future Claude Code update
changes its SEMANTICS (e.g. gives a sub-agent its own sid instead of the caller's), re-verify
NOMOS C1/C2/C3.
"""
import argparse
import json
import os
import sys

ENV_VAR = "CLAUDE_CODE_SESSION_ID"
EXIT_MISSING = 2


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="whoami",
        description="Report this seat's session-identity from $CLAUDE_CODE_SESSION_ID.",
    )
    parser.add_argument(
        "--role",
        choices=["terminal", "subagent"],
        default=None,
        help="Label hint (output label only): 'terminal' -> sid=<v>; 'subagent' -> caller-sid=<v>. "
        "The seat supplies this from its known class; whoami does not auto-detect the class.",
    )
    parser.add_argument(
        "--json", action="store_true", help="Emit a JSON object instead of a plain line."
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Also note that the value was sourced from $CLAUDE_CODE_SESSION_ID.",
    )
    args = parser.parse_args()

    sid = os.environ.get(ENV_VAR, "")

    # FAIL-LOUD (the MUST): empty/unset -> stderr error + non-zero exit. No fallback.
    if not sid.strip():
        sys.stderr.write(
            f"whoami: ${ENV_VAR} is not set; cannot determine session identity\n"
        )
        return EXIT_MISSING

    sid = sid.strip()

    if args.role == "terminal":
        if args.json:
            print(json.dumps({"kind": "terminal", "session_id": sid}))
        else:
            print(f"sid={sid}")
    elif args.role == "subagent":
        if args.json:
            print(json.dumps({"kind": "subagent", "caller_sid": sid}))
        else:
            print(f"caller-sid={sid}")
    else:
        # No --role: print the bare value. The §28.9 convention (keyed on the seat's
        # known class) selects the label; no env var discriminates the class.
        if args.json:
            print(json.dumps({"session_id": sid}))
        else:
            print(sid)
            sys.stderr.write(
                "whoami: bare value; the op-disc §28.9 convention (keyed on the seat's known "
                "class) selects the sid/caller-sid label. Pass --role terminal|subagent for it.\n"
            )

    if args.verbose:
        sys.stderr.write(f"whoami: value sourced from ${ENV_VAR}\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
