#!/usr/bin/env bash
#
# stop-self-check.sh — Stop hook self-check backstop (design-rev1 §5.2).
#
# Fires at the end of an orchestrator turn. Injects a short self-check
# checklist the orchestrator must address before the turn ends. This is a
# BACKSTOP, not a pre-action gate: the load-bearing pre-action checks
# (author-field, clean-tree, no-`-m`) live on PreToolUse precisely because they
# must fire BEFORE the action, and Stop fires after. The self-check covers the
# things that have no single pre-action tool-call to gate.
#
# LIVE HOOK SURFACE (verified 2026-05-23, code.claude.com/docs/en/hooks): Stop
# supports only top-level `decision`/`reason` — it does NOT support
# additionalContext. The checklist therefore rides the `reason` field of a
# `decision:"block"`. (This is the design §2 / §5.2 minor-drift adaptation.)
#
# SEAT-TAG SCOPE (per Arc 46 Stage-1 brief): the §7.7 seat-tag canary is NOT
# checked here — it is POLYBIUS-only by canon (operating-disciplines.md §7.7
# scope) and was mis-scoped against PLINY outputs (ARGUS r1/r2). Stage 2
# (Arc 50 / stoa--xyb.7) shipped CAPTAIN_NOMOS as the ground-truth auditor that
# checks orchestrator outputs by DIRECT bw-state comparison (not the seat-tag).
# Clause A below was authored to DEGRADE GRACEFULLY and needs no Stage-2 edit:
# where NOMOS is deployed the checker reminder is operative; where it is not yet
# deployed the reminder reads as a no-op ("treat as satisfied") — so it never
# instructs a broken dispatch in either state.
#
# INFINITE-BLOCK GUARD: a Stop hook that always blocks would trap the turn in a
# loop (the model addresses the checklist, tries to stop again, gets blocked
# again). So this blocks AT MOST ONCE per (session, turn): it writes a per-turn
# sentinel keyed on the session id + the transcript's current size; if the
# sentinel for this turn already exists, it ALLOWS the stop. The sentinel dir
# is cleaned of stale entries opportunistically (design §9 weak-point: sentinel
# staleness; bounded here by a 1-day age sweep).
#
# FAIL-OPEN (design §4 / ARGUS R5): on any script error this allows the stop.

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null)" || exit 0
# shellcheck source=/dev/null
. "${HOOK_DIR}/_hooklib.sh" 2>/dev/null || exit 0

read_stdin_event

# Respect the documented stop_hook_active guard: if the harness signals it is
# already in a Stop-hook continuation, do NOT block again (avoids the loop the
# platform itself warns about). Treat the string "true" as active.
ACTIVE="$(event_field stop_hook_active)" || ACTIVE=""
[ "$ACTIVE" = "true" ] && allow

SESSION="$(event_field session_id)" || SESSION=""
TRANSCRIPT="$(event_field transcript_path)" || TRANSCRIPT=""

# Sentinel directory: prefer the cwd's tier, fall back to the user tier, then
# /tmp. We only need a writable scratch location keyed on session.
CWD="$(event_field cwd)" || CWD=""
SENTINEL_DIR=""
for d in "${CWD}/.claude/hooks/.stop-sentinels" "${HOME}/.claude/hooks/.stop-sentinels" "${TMPDIR:-/tmp}/stoa-stop-sentinels"; do
  parent="$(dirname "$d")"
  if [ -d "$parent" ] || mkdir -p "$d" 2>/dev/null; then
    mkdir -p "$d" 2>/dev/null && { SENTINEL_DIR="$d"; break; }
  fi
done
# If we cannot establish a sentinel dir we cannot guard against the loop, so
# FAIL-OPEN (allow) rather than risk trapping the turn.
[ -n "$SENTINEL_DIR" ] || allow

# Opportunistic stale-sentinel sweep (>1 day old). Bounded cleanup so the dir
# does not grow unboundedly across sessions (design §9 sentinel-staleness).
find "$SENTINEL_DIR" -type f -mtime +1 -delete 2>/dev/null || true

# Turn key: session id + transcript size (changes every turn, so we block once
# per turn, not once per session). Fall back to session-only if unavailable.
TKEY="$SESSION"
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  tsize="$(wc -c < "$TRANSCRIPT" 2>/dev/null | tr -d '[:space:]')" || tsize=""
  [ -n "$tsize" ] && TKEY="${SESSION}-${tsize}"
fi
# Sanitize the key for use as a filename.
TKEY="$(printf '%s' "$TKEY" | tr -c 'A-Za-z0-9._-' '_')"
[ -n "$TKEY" ] || allow
SENTINEL="${SENTINEL_DIR}/${TKEY}"

# Already checked this turn -> allow the stop (no infinite block).
[ -f "$SENTINEL" ] && allow

# Mark this turn as checked, then block once with the checklist.
: > "$SENTINEL" 2>/dev/null || true

REASON='Self-check before ending this turn (Stoa Stop backstop):
(A) If you closed an arc, posted an activation paste, committed, or issued a directive this turn, the ground-truth checker (CAPTAIN_NOMOS) has been or is being dispatched against that orchestrator output — orchestrator outputs have no other independent checker. (If NOMOS is not yet deployed in this workspace, this is a no-op reminder; treat as satisfied.)
(B) No PreToolUse gate was worked around by reshaping a command to dodge its matcher (e.g. splitting a git commit, renaming a bw flag). The gates exist to catch the authorship / clean-tree / bw-comment footguns; dodging one re-opens the footgun.
(C) Any commit you landed this turn carries the seat-identity Co-Authored-By trailer your dispatch brief named, and its Author: is the PRINCIPAL.
If all three hold, restate "self-check A/B/C clear" and stop. If any fails, fix it now before stopping.'

# (D) SUBSTRATE-DRIFT SIGNAL reader (Arc 63 / stoa--p41.2; design-rev2 §2.8 — the
# F1 P-FALLBACK reader). The SessionStart(startup|resume) substrate-check hook
# writes .claude/.substrate-drift-signal on drift; this is the GUARANTEED non-
# additionalContext carrier — the signal rides the SAME decision:"block"+reason
# JSON the A/B/C checklist already uses, so it surfaces even if additionalContext
# regresses. The reader runs AFTER the infinite-block guard (the sentinel check
# above), so it inherits the once-per-turn semantics (no loop). It does NOT clear
# the signal — clearing is the check's job (a clean SessionStart check rm's it; a
# Stop fire is not evidence the drift was resolved). FAIL-OPEN: any read failure
# leaves REASON as the unchanged A/B/C.
SIG_FILE="${CWD}/.claude/.substrate-drift-signal"
if [ -f "$SIG_FILE" ]; then
  SIG_BODY="$(cat "$SIG_FILE" 2>/dev/null)" || SIG_BODY=""
  if [ -n "$SIG_BODY" ]; then
    REASON="${REASON}
(D) SUBSTRATE-DRIFT SIGNAL present (.claude/.substrate-drift-signal): ${SIG_BODY}
    This is informational/non-blocking — surface it to the PRINCIPAL/operator; do not auto-apply.
    Run check-substrate-updates/check.sh --workspace . (or apply.sh) per the body."
  fi
fi

# (E) GAUNTLET-BY-DEFAULT detector (Arc 68 / stoa--pk4 — the structural-detection
# layer for the AR-7 failure shape). Appended the SAME way clause (D) is appended,
# riding the SAME decision:"block"+reason working channel as A/B/C/D. This is a
# REMINDER-class clause (like A's "treat as no-op if NOMOS not deployed" degradation),
# NOT a transcript-parsing classifier: it does NOT mechanically inspect the transcript
# to PROVE "POLYBIUS dispatched CAPTAINs without a PLINY." It therefore fires on EVERY
# orchestrator-class Stop turn (the ACCEPTED ADVISORY branch — DoD bullet 4 is met by
# the clause TEXT reaching the model on the working channel, NOT by selective AR-7
# detection; C3). The PRINCIPAL accepted this detection-not-prevention residual
# (Option A). The legitimate-early-arc-solo carve-out line keeps the bounded false-
# positive cost the same as the other reminder clauses. FAIL-OPEN preserved.
REASON="${REASON}
(E) If THIS turn you (a POLYBIUS- or PLINY-class seat) dispatched CAPTAINs via the Agent tool, confirm a PLINY orchestrator is in the chain (you are not a POLYBIUS that spawned CAPTAINs directly) AND the gauntlet shape is the full DAEDALUS->ARGUS->ADA->VERA->CATO->NOMOS unless an explicit POLYBIUS/PRINCIPAL waiver is recorded on bw. A solo-with-one-checker close is the AR-7 failure shape (stoa--pk4) — if that is what happened, STOP and route through the gauntlet or record the waiver before ending the turn. (Legitimate early-arc solo build-sessions where no CAPTAINs exist: this does not apply — proceed.)"

# Build the Stop block JSON (decision:"block" + reason). Encode the reason via
# python3 so embedded quotes/newlines are escaped. If python3 is gone, FAIL-OPEN.
REASON_JSON="$(REASON="$REASON" python3 -c 'import os,json,sys; sys.stdout.write(json.dumps(os.environ["REASON"]))' 2>/dev/null)" || allow
printf '{"decision":"block","reason":%s}\n' "$REASON_JSON"
exit 0
