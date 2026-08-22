#!/usr/bin/env bash
#
# sessionstart-compact-reprime.sh — SessionStart(matcher:compact) reprime
# (design-rev1 §5.5 / Stage 2 / stoa--xyb.7; Stage-1 ARGUS R2 deferred to here).
#
# Registered under SessionStart with matcher "compact". On a compact-triggered
# session resume it (best-effort) re-injects the orchestrator's standing
# engagement context — its seat, the open epic, the polling cadence, and the
# "dispatch NOMOS on orchestrator outputs" reminder — so a just-compacted
# orchestrator is re-primed.
#
# LIVE HOOK SURFACE — THE LOAD-BEARING CAVEAT (web-verified 2026-05-23, no fix
# through changelog v2.1.150):
#   SessionStart(matcher:compact) `additionalContext` is BROKEN — issue #15174
#   (closed-as-DUPLICATE, v2.0.72–v2.0.76): the hook EXECUTES but its output is
#   NOT injected into context after compaction completes. The issue's own
#   documented impact: "Blocks multi-agent orchestration systems that need role
#   reminders" — exactly this use case. Its named workaround: "Add reminders
#   directly to CLAUDE.md, which DOES get loaded after compaction."
# THEREFORE this hook does NOT reliably do its job on current versions. It ships
# anyway because (a) it is the CORRECT mechanism and is FORWARD-COMPATIBLE (it
# starts working the moment #15174 is fixed) and (b) it is HARMLESS when broken
# (executes, output dropped, no side effect). The RELIABLE post-compaction
# reprime is NOT this hook — it is CLAUDE.md (the platform-blessed
# post-compaction carrier) + the polling cron (fresh harness-fired input that
# survives compaction by construction, the stoa--xyb.5 founding principle). This
# hook is best-effort and documents the dependency. See README.md §6.
#
# PAYLOAD SOURCE: the engagement-specific reprime is read from a deployed config
# (.claude/hooks/reprime-context, one block of text) so the payload is not
# hard-coded to one engagement; absent the config it injects a generic role
# reprime (still self-contained per op-disc §34).
#
# SAFETY: SessionStart hooks run on every matching session start — keep them
# fast. This is a read-config-and-emit. It NEVER blocks session start. On any
# error it emits nothing (no reprime, no harm) — FAIL-OPEN.

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null)" || exit 0
# shellcheck source=/dev/null
. "${HOOK_DIR}/_hooklib.sh" 2>/dev/null || exit 0

read_stdin_event

# Locate the optional engagement-reprime config (deployed alongside the hooks).
# Prefer the cwd tier, fall back to the user tier; absent both, use the generic
# reprime below.
CWD="$(event_field cwd)" || CWD=""
REPRIME=""
for c in "${CWD}/.claude/hooks/reprime-context" "${HOME}/.claude/hooks/reprime-context"; do
  if [ -f "$c" ]; then
    REPRIME="$(cat "$c" 2>/dev/null)" || REPRIME=""
    [ -n "$REPRIME" ] && break
  fi
done

# Generic self-contained reprime (op-disc §34: WHY it fired + WHAT to do, inline)
# used when no engagement config is deployed.
if [ -z "$REPRIME" ]; then
  REPRIME='Context was just compacted. You are an orchestrator on a Stoa team (MAJOR_POLYBIUS / MAJOR_PLINY). Re-anchor before acting: re-read your role file for your seat identity and dispatch protocol; read your open epic and active arc from bw (bw list --status open --all; bw show <epic>) rather than from memory — bw is the durable record, your in-head state was just wiped. Resume the polling cadence per MAJOR_PLINY.md §5.8. When a sub-agent returns, dispatch CAPTAIN_NOMOS to confirm the output conforms to bw ground truth before propagating it (orchestrator outputs have no other independent checker). If CAPTAIN_NOMOS is not deployed in this workspace, treat that last reminder as a no-op.'
fi

# Build the SessionStart additionalContext JSON. Encode via python3 so embedded
# quotes/newlines are escaped. If python3 is gone, FAIL-OPEN (emit nothing).
REPRIME_JSON="$(R="$REPRIME" python3 -c 'import os,json,sys; sys.stdout.write(json.dumps(os.environ["R"]))' 2>/dev/null)" || exit 0
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$REPRIME_JSON"
exit 0
