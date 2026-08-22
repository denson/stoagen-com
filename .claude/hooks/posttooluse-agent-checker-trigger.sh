#!/usr/bin/env bash
#
# posttooluse-agent-checker-trigger.sh — PostToolUse-on-Agent NOMOS-dispatch
# reminder (design-rev1 §5.2 / Stage 2 / stoa--xyb.7).
#
# Registered under PostToolUse with matcher "Agent". Fires in the PARENT
# (orchestrator) context when a sub-agent returns — the doc-blessed pattern for
# injecting context into the parent after a subagent returns (SDK hooks docs:
# "use a PostToolUse hook on the Agent tool"; SubagentStop CANNOT inject).
# Best-effort: it reminds the orchestrator to dispatch CAPTAIN_NOMOS against the
# returned sub-agent's output before propagating it.
#
# LIVE HOOK SURFACE — THE LOAD-BEARING CAVEAT (web-verified 2026-05-23, no fix
# through changelog v2.1.150):
#   PostToolUse `additionalContext` is BROKEN in shipping versions — it may not
#   reach the model (issue #55889 OPEN v2.1.123, regression from v2.1.9 where it
#   was "added but not actually wired up"; #18427 CLOSED-not-planned, the broader
#   "PostToolUse cannot inject context visible to Claude"; #19432 PreToolUse).
#   The `permissionDecision:"deny"` and Stop `decision:"block"`+`reason` channels
#   are CONFIRMED WORKING in the same versions.
# THEREFORE this hook is BEST-EFFORT and is NOT the reliable carrier of the
# NOMOS reminder. The reliable carrier is the Stage-1 Stop self-check
# (stop-self-check.sh, clause A — `decision:"block"`+`reason`, a working
# channel), which already reminds the orchestrator to dispatch NOMOS at
# turn-end. This hook is FORWARD-COMPATIBLE: the payload is correct and starts
# working the moment the platform fixes #55889, and is HARMLESS when broken
# (the additionalContext is simply dropped). See substrate/hooks/README.md §6.
#
# RECURSION GUARD: the hook must NOT remind "run NOMOS" when the sub-agent that
# just returned IS NOMOS (else a NOMOS-checks-NOMOS prompt). Two layers, but
# only ONE is active today:
#   (1) ACTIVE — the layer-1 agent_type match. Inspect the event's agent_type
#       for a NOMOS seat name and no-op (allow, no additionalContext) on a
#       match. This is the live guard.
#   (2) FORWARD-COMPATIBLE / NOT-YET-ARMED — a one-deep session-sentinel read.
#       The layer-2 branch below READS a `.nomos-sentinels/<session>` sentinel
#       and suppresses re-firing if present, BUT nothing in the substrate WRITES
#       that sentinel today (unlike the Stage-1 Stop sentinel, which self-writes
#       in stop-self-check.sh). So layer-2 is INERT-but-harmless: the read never
#       finds a file, the branch never fires. It activates only once a future
#       arc adds an orchestrator-writes-sentinel-on-NOMOS-dispatch site (the same
#       arc that promotes these best-effort hooks to load-bearing once upstream
#       #55889 closes). The session-sentinel design is kept here because the
#       parent-on-return event's population of agent_type is UNCONFIRMED per the
#       SDK docs (which only promise agent_type "when the hook fires INSIDE a
#       subagent"), so a write-site is the planned belt-and-suspenders for the
#       case layer-1 cannot see the returning seat. TODAY layer-1 is the guard.
#       The failure mode if layer-1 ever misses (and layer-2 is still unarmed)
#       is bounded — one no-op reminder the orchestrator reads and recognizes as
#       not-applicable; NOMOS is a leaf and cannot dispatch a further NOMOS, so
#       there is no loop. That bounded-failure property is why shipping layer-2
#       inert is acceptable for this arc.
#
# FAIL-OPEN: on any script error (no python3, malformed event, missing field)
# emit nothing and allow — consistent with the Stage-1 contract. A best-effort
# reminder that fails open simply does not remind; the Stop channel still does.

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null)" || exit 0
# shellcheck source=/dev/null
. "${HOOK_DIR}/_hooklib.sh" 2>/dev/null || exit 0

read_stdin_event

# --- recursion guard, layer 1: agent_type names NOMOS -> no-op -----------------
# The returning sub-agent's identity may appear under several field names across
# versions; check the documented ones. Case-insensitive, {{NAME_SUFFIX}}-
# tolerant match on CAPTAIN_NOMOS*.
RETURNING=""
for f in tool_input.subagent_type tool_input.agent_type agent_type tool_response.agent_type; do
  v="$(event_field "$f")" || v=""
  if [ -n "$v" ]; then RETURNING="$v"; break; fi
done
case "$(printf '%s' "$RETURNING" | tr '[:upper:]' '[:lower:]')" in
  *captain_nomos*|*nomos*) allow ;;   # NOMOS returned — do NOT remind to run NOMOS
esac

# --- recursion guard, layer 2: session sentinel (FORWARD-COMPATIBLE / INERT) ---
# This branch READS a per-session sentinel and would suppress re-firing if a
# NOMOS dispatch were flagged in flight for this session. It is INERT TODAY:
# nothing in the substrate WRITES a `.nomos-sentinels/<session>` file (unlike the
# Stage-1 Stop sentinel, which self-writes in stop-self-check.sh), so the read at
# the bottom of this block never finds a file and the suppress never fires. The
# read path is kept ready for a future arc that adds an orchestrator-writes-
# sentinel-on-NOMOS-dispatch site (the layer-1 agent_type match is the ACTIVE
# guard until then). The sentinel is best-effort scratch; if we cannot establish
# the dir we still emit (the layer-1 guard + the bounded-failure property — NOMOS
# is a leaf, worst case one no-op reminder — cover the gap).
SESSION="$(event_field session_id)" || SESSION=""
CWD="$(event_field cwd)" || CWD=""
SENTINEL_DIR=""
for d in "${CWD}/.claude/hooks/.nomos-sentinels" "${HOME}/.claude/hooks/.nomos-sentinels" "${TMPDIR:-/tmp}/stoa-nomos-sentinels"; do
  parent="$(dirname "$d")"
  if [ -d "$parent" ] || mkdir -p "$d" 2>/dev/null; then
    mkdir -p "$d" 2>/dev/null && { SENTINEL_DIR="$d"; break; }
  fi
done
if [ -n "$SENTINEL_DIR" ] && [ -n "$SESSION" ]; then
  # Opportunistic stale sweep (>1 day) so the dir does not grow unboundedly.
  find "$SENTINEL_DIR" -type f -mtime +1 -delete 2>/dev/null || true
  SKEY="$(printf '%s' "$SESSION" | tr -c 'A-Za-z0-9._-' '_')"
  SENTINEL="${SENTINEL_DIR}/${SKEY}"
  # If a NOMOS dispatch is already flagged in flight this session, suppress.
  [ -f "$SENTINEL" ] && allow
fi

# --- emit the best-effort reminder (op-disc §34: WHY + WHAT, self-contained) ---
CONTEXT='A sub-agent just returned. Per the cross-check discipline, orchestrator outputs and the propagation of a sub-agent verdict have no other independent checker. BEFORE you act on or propagate this sub-agent output against bw, dispatch CAPTAIN_NOMOS with the returned verdict + the relevant bw ticket id(s) and have it confirm the output conforms to bw ground truth (ticket-state consistency; claimed-vs-actual commit SHAs; claimed cleanup; PRINCIPAL-gate ratification evidence). If NOMOS returns DIVERGENT, do NOT propagate — route per the re-decompose remediation in modules/incomplete-unverifiable-routing.md (SIZE-DERAIL -> split; WRONG-SPEC/BLOCKED/IMPOSSIBLE -> escalate). This hook cannot dispatch NOMOS for you (hooks cannot dispatch sub-agents); you must issue the dispatch yourself. (If CAPTAIN_NOMOS is not deployed in this workspace, treat this as a no-op reminder.)'

# Build the PostToolUse additionalContext JSON. Encode via python3 so embedded
# quotes/newlines are escaped. If python3 is gone, FAIL-OPEN (emit nothing).
CONTEXT_JSON="$(CTX="$CONTEXT" python3 -c 'import os,json,sys; sys.stdout.write(json.dumps(os.environ["CTX"]))' 2>/dev/null)" || allow
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s}}\n' "$CONTEXT_JSON"
exit 0
