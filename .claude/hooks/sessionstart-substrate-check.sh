#!/usr/bin/env bash
#
# sessionstart-substrate-check.sh — SessionStart(matcher:startup|resume)
# deterministic substrate/bw drift trigger (Arc 63 / stoa--p41.2 / design-rev2 §2.1).
#
# Registered under SessionStart with matcher "startup|resume". On a normal
# session start or resume it (best-effort) runs the CHECK logic of the two
# substrate-maintenance tools — check-substrate-updates/check.sh (substrate
# drift) and check-bw-release/check.sh (bw upstream release) — once per
# session-start under disposition-#2 guardrails:
#   THROTTLE        ~once/day via a stamp file (.substrate-check-hook-stamp,
#                   DISTINCT from check.sh's own .substrate-last-check state).
#   SURFACE-ON-SIGNAL-ONLY  emit additionalContext ONLY when a check reports
#                   drift; stay SILENT (emit nothing) when current.
#   NON-BLOCKING / FAIL-OPEN  every step is guarded; any error emits nothing
#                   and never blocks the session start.
#
# WHY THIS HOOK (vs the model invoking the check skills): Arc 63 retired
# check-substrate-updates + check-bw-release from SKILL_NAMES — they are no
# longer model-invokable skills (no SKILL.md → not Skill-tool-discoverable).
# Their drift detection now fires deterministically here at session start.
# The tools' scripts (check.sh / apply.sh / revert.sh) stay on disk under
# .claude/skills/check-*/ (deployed via the install.sh carve-out) so apply/
# revert remain available on-demand. See substrate/modules/{substrate-update-
# check,bw-upgrade}.md and .claude/hooks/README.md §6.
#
# LIVE HOOK SURFACE: SessionStart(startup|resume) additionalContext IS a working
# injection channel as of claude v2.1.170 (the BROKEN channel is the `compact`
# matcher — issue #15174 — used by the sibling sessionstart-compact-reprime.sh,
# NOT this hook). This hook therefore reaches the model on the startup/resume
# path. As a P-FALLBACK that survives even an additionalContext regression, the
# hook ALSO writes a non-additionalContext signal file
# (.claude/.substrate-drift-signal) that the Stop self-check + CLAUDE.md read
# (design-rev2 §2.8) — so drift surfaces even if additionalContext ever breaks.
#
# SAFETY: SessionStart hooks run on every matching session start — keep them
# fast. Each check.sh call is wrapped in `timeout 10`. Throttled to ~once/day.
# It NEVER blocks session start. On any error it emits nothing — FAIL-OPEN.

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null)" || exit 0
# shellcheck source=/dev/null
. "${HOOK_DIR}/_hooklib.sh" 2>/dev/null || exit 0

read_stdin_event

CWD="$(event_field cwd)" || CWD=""
[ -n "$CWD" ] || exit 0   # no cwd → cannot locate the workspace; FAIL-OPEN.

# ---------------------------------------------------------------------------
# THROTTLE: run at most ~once/day. The stamp is DISTINCT from check.sh's own
# .substrate-last-check (that file is the check's per-workspace drift baseline;
# this one is the hook's per-session-start throttle). If the stamp is younger
# than 24h, skip the checks entirely (emit nothing) — but still surface any
# pre-existing drift signal as an additionalContext convenience (the GUARANTEED
# carrier is the Stop reader; this is the working-channel convenience only).
# ---------------------------------------------------------------------------
STAMP="${CWD}/.claude/.substrate-check-hook-stamp"
SIGNAL="${CWD}/.claude/.substrate-drift-signal"

stamp_fresh() {
  # 0 (true) if the stamp exists and is younger than 24h.
  [ -f "$STAMP" ] || return 1
  local now mtime age
  now="$(date +%s 2>/dev/null)" || return 1
  mtime="$(date -r "$STAMP" +%s 2>/dev/null)" || mtime=""
  [ -n "$mtime" ] || return 1
  age=$(( now - mtime ))
  [ "$age" -ge 0 ] && [ "$age" -lt 86400 ]
}

emit_signal_convenience() {
  # Throttled path: do NOT re-run the checks, but if a drift signal is already
  # on disk, re-surface it via additionalContext (convenience only — NOT the F1
  # carrier). Stay silent if no signal file.
  if [ -f "$SIGNAL" ]; then
    local body
    body="$(cat "$SIGNAL" 2>/dev/null)" || body=""
    if [ -n "$body" ]; then
      local ctx="Substrate-drift signal is present (.claude/.substrate-drift-signal): ${body} — surface this to the PRINCIPAL/operator; do not auto-apply. Run check-substrate-updates/check.sh --workspace . (or apply.sh) per the body."
      local json
      json="$(C="$ctx" python3 -c 'import os,json,sys; sys.stdout.write(json.dumps(os.environ["C"]))' 2>/dev/null)" || exit 0
      printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$json"
    fi
  fi
  exit 0
}

if stamp_fresh; then
  emit_signal_convenience
fi

# Refresh the throttle stamp BEFORE running the checks so a slow/looping check
# cannot cause the hook to fire repeatedly within the throttle window. Best-
# effort; a failed stamp write is non-fatal (worst case: the check runs again
# next start).
mkdir -p "${CWD}/.claude" 2>/dev/null || true
: > "$STAMP" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Resolve the check.sh scripts. EDIT 1 (design-rev2 §2.1): try the consumer
# tier (.claude/skills/check-*/), fall back to the-stoa SUBSTRATE-tier dogfood
# path (substrate/skills/check-*/). Both paths are STABLE under Option C (the
# dirs do not move). Use whichever resolves as -x.
# ---------------------------------------------------------------------------
SUB_CHECK="${CWD}/.claude/skills/check-substrate-updates/check.sh"   # consumer tier
BW_CHECK="${CWD}/.claude/skills/check-bw-release/check.sh"
[ -x "$SUB_CHECK" ] || SUB_CHECK="${CWD}/substrate/skills/check-substrate-updates/check.sh"
[ -x "$BW_CHECK" ]  || BW_CHECK="${CWD}/substrate/skills/check-bw-release/check.sh"

SUB_OUT=""
BW_OUT=""
[ -x "$SUB_CHECK" ] && { SUB_OUT="$(timeout 10 "$SUB_CHECK" --workspace "$CWD" 2>/dev/null)" || SUB_OUT=""; }
[ -x "$BW_CHECK" ]  && { BW_OUT="$(timeout 10 "$BW_CHECK" 2>/dev/null)" || BW_OUT=""; }

# ---------------------------------------------------------------------------
# Decide drift. check-substrate-updates/check.sh prints a per-workspace verdict
# composing DRIFTED / MISSING / OBSOLETE; "current"/no-diff workspaces produce
# none of those tokens. check-bw-release prints "new release detected" on drift
# and a "current" line otherwise. Treat the presence of those drift tokens as
# the SIGNAL; absence → silent.
# ---------------------------------------------------------------------------
DRIFT_BODY=""
if printf '%s' "$SUB_OUT" | grep -qiE 'DRIFTED|MISSING|OBSOLETE'; then
  DRIFT_BODY="substrate drift detected — run check-substrate-updates/check.sh --workspace . to review; apply with apply.sh --workspace . --all-differing (revert.sh undoes the last apply). PRINCIPAL-gated; do not auto-apply."
fi
if printf '%s' "$BW_OUT" | grep -qiE 'new release detected'; then
  if [ -n "$DRIFT_BODY" ]; then
    DRIFT_BODY="${DRIFT_BODY} ALSO: a new bw release is available — run check-bw-release/check.sh and classify per bw-upgrade.md §22.2."
  else
    DRIFT_BODY="a new bw release is available — run check-bw-release/check.sh and classify per bw-upgrade.md §22.2 before adoption."
  fi
fi

# ---------------------------------------------------------------------------
# No drift → SILENT and clear any stale signal (the check is now authoritative
# that there is no drift). This is also the F1 self-clear contract: the Stop
# reader stops surfacing once a clean check removes the signal (design §2.8).
# ---------------------------------------------------------------------------
if [ -z "$DRIFT_BODY" ]; then
  rm -f "$SIGNAL" 2>/dev/null || true
  exit 0
fi

# Drift → write the P-FALLBACK signal file (the GUARANTEED non-additionalContext
# carrier the Stop self-check + CLAUDE.md read, design §2.8) AND emit the
# additionalContext (working-channel surface on startup|resume). The signal
# body states WHY/WHAT inline (op-disc §34) so any reader is self-contained.
printf '%s\n' "$DRIFT_BODY" > "$SIGNAL" 2>/dev/null || true

CTX="Substrate/bw drift detected at session start: ${DRIFT_BODY}"
CTX_JSON="$(C="$CTX" python3 -c 'import os,json,sys; sys.stdout.write(json.dumps(os.environ["C"]))' 2>/dev/null)" || exit 0
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$CTX_JSON"
exit 0
