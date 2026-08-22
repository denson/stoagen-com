#!/usr/bin/env bash
#
# pretooluse-no-dash-m-bw-comment.sh — PreToolUse hard gate (design-rev1 §5.1c).
#
# Blocks the `bw comment <id> -m "..."` footgun. `bw comment` takes the body as
# a POSITIONAL argument; `-m` does NOT exist (git muscle memory). Written with
# `-m`, the literal `-m` lands as the comment body and the real text is dropped
# (operating-disciplines.md §12 + §12.2). This is a silent data-loss footgun:
# the comment appears to post but carries the wrong body.
#
# REGISTRATION (settings-hooks.json template): PreToolUse, narrowed via
# `if: "Bash(bw comment*)"`. The script then confirms a `-m` token is present
# before denying (so `bw comment <id> "text"` — the correct positional form —
# always passes).
#
# FAIL-OPEN (design §4 / ARGUS R5): on any script error this allows.

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null)" || exit 0
# shellcheck source=/dev/null
. "${HOOK_DIR}/_hooklib.sh" 2>/dev/null || exit 0

read_stdin_event

CMD="$(event_field tool_input.command)" || allow
[ -n "$CMD" ] || allow

# Must be a `bw comment` invocation.
case "$CMD" in
  *"bw comment "*) : ;;
  *) allow ;;
esac

# The footgun is `bw comment <id> -m "..."` — `-m` appearing as a FLAG token
# where the positional body should be. To distinguish that from a body that
# merely MENTIONS "-m" inside its quoted text (e.g.
# `bw comment <id> "use git commit -m"`), we check whether `-m` is the FIRST
# token AFTER the ticket id. A `-m` inside the positional body comes after the
# opening quote and is never the first post-id token, so it does not match.
#
# Deterministic tokenizer on whitespace (the footgun never quotes the id or the
# `-m` flag, so simple whitespace splitting is sufficient and avoids false
# positives on quoted body content). after = everything past "bw comment ".
after="${CMD#*bw comment }"
# Read the first two whitespace-separated tokens: <id> then <next>.
# shellcheck disable=SC2086
set -- $after
id_tok="${1:-}"
next_tok="${2:-}"
case "$next_tok" in
  -m|-m=*|-m\"*|-m\'*)
    # The token immediately after the ticket id is a -m flag -> the footgun.
    emit_deny "bw comment blocked: \`bw comment\` takes the comment body as a POSITIONAL argument, never \`-m\`. You wrote \`bw comment ${id_tok} -m ...\`. With \`-m\`, the literal \"-m\" is captured as the comment body and your actual text is dropped (silent data loss). Re-run as: bw comment ${id_tok} \"<text>\"  (the body in double quotes immediately after the ticket id, no -m). Git muscle memory says \`git commit -m\`; bw does not."
    ;;
esac

allow
