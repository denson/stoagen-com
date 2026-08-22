# save-verdict — Bash-only canonical verdict-write module

> Read by the verdict-producing seat (VERA / ARGUS / CATO) at verdict-write time.
> Provenance: Arc 64 / `stoa--p41.2` Workstream B (skills-housekeeping pass B). This
> module REPLACES the retired `save-verdict` *skill* (`substrate/skills/save-verdict/`
> — Python writer + `_lib`, `git rm`'d Arc 64). The Bash-only procedure here authors the
> verdict via `printf` redirection (no Python, no Write/Edit tool), runs an inline sha256
> round-trip, asserts the threat-coverage empty-binding guard, and **attaches the written
> verdict to the coordination ticket on beadwork** (`bw attach`) so a worktree teardown
> cannot destroy it (the Arc-62 verdict-loss fix). Retires the Python-writer bugs
> `stoa--j2i` (lowercase-p probe-id regex) / `1ne` / `xyn` / `7b1.8`.
> Resolves `stoa--7b1.1` (read-only-review-seat §4-no-Write vs §7-mandates-save-verdict):
> `printf >` is a *Bash* operation within the seat's existing Bash grant, NOT the
> `Write`/`Edit` tool §4 forbids — so §4 and §7 were never in genuine conflict.
> Anchor: `stoa--p41.2`, `stoa--xxy` (worktree-dest-pin), `stoa--yfv` B2 (empty-binding).

## (a) Canonical path convention

The verdict lands at:

```
<worktree-root>/agents/verdicts/<ticket-id>/<OFFICER>-<YYYY-MM-DDTHH-MM-SSZ>.md
```

- `<worktree-root>` MUST be the **absolute arc-worktree root** (`<repo>/.claude/worktrees/arc-<N>-build`). A sub-agent inherits the parent session cwd, so a relative/defaulted path resolves to the MAIN tree, not the worktree — landing the verdict at main `agents/verdicts/` instead of the worktree (the Arc-55 observed-live split). The PLINY dispatch brief pins the absolute worktree root (`MAJOR_PLINY.md` §5.14); the `printf` redirect writes to the path the brief names.
- `<OFFICER>` matches `^[A-Z][A-Z0-9_]*$` (uppercase officer name — VERA / ARGUS / CATO); `<ticket-id>` matches `^[a-zA-Z0-9][a-zA-Z0-9._-]*$`. These are input-hygiene / path-traversal-defense seat checks (the officer + ticket-id come from the trusted PLINY brief, not an attacker — not a §35 threat-mitigation), preserved as documented seat checks (see Q-A below).
- `<ts>` is the filename-safe timestamp: UTC `YYYY-MM-DDTHH-MM-SSZ` (colons replaced with hyphens for cross-platform filename safety).

## (b) The Bash-only write procedure (the byte-aligned region)

The procedure below is the **byte-aligned region** shared verbatim across this module AND the inline §7 blocks of `CAPTAIN_VERA.md`, `CAPTAIN_ARGUS.md`, `CAPTAIN_CATO.md` (the Q-C = C2 inline-fallback: the module is not deployed at subproject tier, so the inline copies are the always-resolvable home of the executable steps). The four copies MUST be byte-identical between the `BEGIN`/`END` sentinels modulo the documented named-slot substitutions (`<ticket-id>`, `<OFFICER>`, `<ts>`, `<verdict-body>`) — kept byte-identical across the four homes by a manual four-home `diff` (`canonical-template-alignment.md`; there is no automated cross-file gate). Do NOT alter the region in one home without re-aligning all four.

Sequence: **dest-exists guard → printf-author → inline sha256 round-trip → empty-binding threat-coverage assert → bw attach.**

Quoting caveat (proven, ARGUS / CATO): a single-quoted `printf '%s' '…'` body is literal (no `$`/backtick expansion) but cannot contain a bare apostrophe — escape each embedded apostrophe as `'\''` (close-quote, escaped-apostrophe, reopen-quote). Forbidden: a `cat <<'EOF' … EOF` heredoc (breaks on apostrophes on Windows git-bash) and any `/tmp/…` path (git-bash `/tmp` ≠ Python `/tmp`). Write the body DIRECTLY to the canonical `.md` — no separate `_body-*.tmp.md` scratch step (that two-step dance existed only to feed the retired Python `--body-path`).

<!-- SAVE-VERDICT-BYTE-ALIGNED-REGION:BEGIN -->
```bash
DEST=<worktree-root>/agents/verdicts/<ticket-id>/<OFFICER>-<ts>.md
mkdir -p "$(dirname "$DEST")"

# Dest-exists collision guard (mirrors the retired Python exit-3): do not silently
# clobber an existing same-path verdict. SAVE_VERDICT_OVERWRITE=1 is the explicit
# opt-in escape (mirrors the Python --overwrite) for a legitimate intentional re-write.
if [ -e "$DEST" ] && [ "${SAVE_VERDICT_OVERWRITE:-0}" != "1" ]; then
  echo "SAVE-VERDICT FAIL: dest exists $DEST (set SAVE_VERDICT_OVERWRITE=1 to re-write)" >&2
  exit 3
fi

# Author the verdict body via printf redirection (escape embedded apostrophes as '\'').
printf '%s' '<verdict-body>' > "$DEST"

# Inline sha256 round-trip (integrity guarantee; exit 2 on mismatch).
WANT=$(printf '%s' '<verdict-body>' | sha256sum | cut -d' ' -f1)
GOT=$(sha256sum "$DEST" | cut -d' ' -f1)
[ "$WANT" = "$GOT" ] || { echo "SAVE-VERDICT FAIL: sha256 mismatch want=$WANT got=$GOT" >&2; exit 2; }

# Threat-coverage empty-binding guard (op-disc §35 / stoa--yfv B2).
# Only when the verdict declares threat-ratified mitigations:
if [ "${TRM_COUNT:-0}" -gt 0 ]; then
  [ -n "$THREAT_PROBE_IDS" ] || { echo "SAVE-VERDICT FAIL: $TRM_COUNT threat-ratified mitigation(s) declared but no threat-coverage probe-ids (op-disc §35/yfv B2)" >&2; exit 4; }
  IFS=',' read -ra _ids <<< "$THREAT_PROBE_IDS"
  for _id in "${_ids[@]}"; do
    _id="${_id// /}"
    [ -n "$_id" ] || continue
    printf '%s' "$_id" | grep -Eq '^[pP][0-9A-Za-z._-]+$' || { echo "SAVE-VERDICT FAIL: probe-id '$_id' malformed (must match ^[pP][0-9A-Za-z._-]+\$)" >&2; exit 4; }
  done
fi

# Attach the integrity-checked verdict to beadwork (durability — survives worktree teardown).
# rc-CAPTURE the real exit code so the seat SETS the dispatch-return attach_status
# field from the ACTUAL rc (not by prose assertion). The dispatch-return field
# remains the LOCKED first-class signal PLINY keys retry off (clause d clause 1) —
# this block does NOT emit that field; it captures the rc and leaves a stderr
# breadcrumb. The seat reads $attach_rc to populate its dispatch return.
bw attach <ticket-id> "$DEST" --name "verdicts/<OFFICER>-<ts>.md"; attach_rc=$?
if [ "$attach_rc" -ne 0 ]; then
  echo "SAVE-VERDICT WARN: bw attach failed (rc=$attach_rc); verdict is integrity-verified on disk at $DEST but NOT yet on beadwork — the seat MUST emit attach_status: FAILED in its dispatch return so the orchestrator retries/escalates (clause d / durability contract)." >&2
fi
```
<!-- SAVE-VERDICT-BYTE-ALIGNED-REGION:END -->

**Exit-code map (the documented failure contract — preserves the retired Python writer's semantics):**

| Exit | Meaning |
|------|---------|
| 2 | sha256 round-trip mismatch (integrity) |
| 3 | dest-exists collision without `SAVE_VERDICT_OVERWRITE=1` opt-in |
| 4 | threat-coverage empty-binding / malformed probe-id (op-disc §35 / yfv B2) |

## (c) Inline sha256 round-trip (integrity guarantee preserved)

Immediately after the write, the seat re-hashes the on-disk file and compares to a hash of the intended body (`sha256sum` is present in this git-bash — GNU coreutils). This replaces the retired Python `write_with_verify` + step-8 re-hash with a single inline assert. Exit-2-on-mismatch is the integrity signal.

## (d) Attach-to-bw-at-write (the Arc-62 verdict-loss fix) + hardened attach-failure posture

After the sha256 check passes, the seat attaches the verdict file to the coordination ticket:

```
bw attach <ticket-id> "$DEST" --name "verdicts/<OFFICER>-<ts>.md"
```

`bw attach` stores the file's BYTES under `attachments/<ticket-id>/verdicts/<OFFICER>-<ts>.md` and commits to the beadwork orphan branch — surviving any worktree teardown. `--name` mirrors the on-disk canonical sub-path so a reader walking `attachments/<ticket>/verdicts/` sees the same layout as `agents/verdicts/<ticket>/`.

**Attach-failure posture — FAIL-LOUD-but-write-preserving, HARDENED (LOCKED).** The on-disk verdict is already integrity-checked (step c) and is the lossless retry source; the attach is the durability upgrade. The posture is NOT a hard `exit` (that would discard a valid integrity-checked artifact and brittle-block the gauntlet on a transient bw hiccup). Four locked clauses:

1. **Structured, first-class `attach_status` field in the seat's dispatch return** — NOT a scroll-past stderr echo. When `bw attach` exits non-zero, the seat's dispatch return carries:
   ```
   attach_status: FAILED
   attach_failure: bw attach exited rc=<n>; verdict integrity-verified on disk at <DEST> (sha256 <hash>); NOT yet on beadwork — orchestrator MUST retry/escalate before treating this verdict as durable.
   ```
   On success the field is `attach_status: OK` (so absence-of-field is not silently read as success). The stderr breadcrumb (`echo "SAVE-VERDICT WARN: bw attach failed (rc=$?); verdict is on disk at $DEST but NOT yet on beadwork" >&2`) stays as the human-readable trail, but the `attach_status` field is the load-bearing signal PLINY keys its retry/escalate obligation off. The byte-aligned region now CAPTURES `bw attach`'s real exit code into `attach_rc` (`; attach_rc=$?` on the attach line) so the seat SETS this dispatch-return field from the ACTUAL rc rather than asserting it by prose; the rc-capture is a durability mechanization of HOW the seat learns the attach outcome — the dispatch-return field remains the locked first-class signal, NOT replaced by the block's stderr breadcrumb.
2. **Disk artifact preserved + sha256-verified** — the attach failure does NOT discard it; it is the lossless retry source.
3. **The durability loop CLOSES AT THE ORCHESTRATOR** — see the Durability contract below.
4. **NOT hard-exit** — in-seat bounded retry (2–3× with a short backoff before emitting `attach_status: FAILED`) is the seat's OPTIONAL judgment; the durability loop never depends on it.

**Body-freeze reinforcement (`stoa--x5t`).** The `<verdict-body>` written by the §7 `printf` is FROZEN at the sha256 round-trip: the bw-attached copy is the byte-canonical attested artifact, and `attach_status`/`attach_failure` (dispatch-return-only, this clause) MUST NOT be written into that body — a post-round-trip body edit diverges the committed in-tree verdict from the attested sha (the `stoa--x5t` / `sos--yn2` defect).

> **Attestation invariant (DC4 / `stoa--x5t`).** Because the attested `<verdict-body>` excludes every field whose value is knowable only after the attach (`attach_status`/`attach_failure`), a verdict tracked in-tree has committed-sha == cited/attested-sha *by construction*. No mechanical gate enforces this beyond the §7 sha256 round-trip; the structural exclusion is the guarantee. A future arc MAY add a NOMOS-on-merge `git cat-file`-vs-attached-blob equality assertion if in-tree verdict tracking becomes universal.

### Durability contract (orchestrator obligation)

A verdict whose `attach_status` is `FAILED` is **NOT durable**. The dispatching orchestrator (PLINY) MUST, on receiving an `attach_status: FAILED` dispatch return:

1. **Retry** `bw attach <ticket> "$DEST"` from the preserved on-disk artifact (the on-disk verdict is the retry source; it is sha256-verifiable against the hash recorded in the `attach_failure` field).
2. On continued failure, **escalate** per the universal escalation triggers.
3. **Do NOT advance the gauntlet** to the next seat and **do NOT permit worktree teardown** past this verdict until attach succeeds or the failure is escalated.

This contract is durable so a FUTURE PLINY inherits it (not an ephemeral this-session intent). The orchestrator-seat half is `MAJOR_PLINY.md` §5.16 ("Verdict-attach hand-back handling").

**Teardown-coupling note (`stoa--9s6`).** Teardown-ORDERING is owned by `stoa--9s6` (out of scope for this arc); whatever teardown sequence 9s6 specifies MUST HONOR this invariant — no worktree teardown may run past a verdict whose `attach_status` is `FAILED` and unescalated. This arc STATES the invariant; 9s6 inherits the constraint.

## (e) Q-A enforcement (§15.4 seat-side HYBRID; empty-binding mechanical)

The retired Python writer enforced §15.4 verification-complexity shape validation AND the threat-coverage empty-binding check mechanically (both exit 4 before any write). The Bash-only rewrite uses a **HYBRID** (LOCKED):

- **§15.4 shape validation is now SEAT-SIDE discipline.** The seat's verdict-format section in its role file is the SSoT for the required-field matrix (INCOMPLETE ⇒ `quadrant_classification` + `coverage_description`; UNVERIFIABLE ⇒ `quadrant_classification` + `sanity_check_performed` + `recommended_next_step`, per `operating-disciplines.md` §15.4). There is no longer a pre-write mechanical exit-4 on shape; a malformed shape is caught by the seat following its role-file spec and by the downstream gauntlet (NOMOS / PLINY). Rationale: these are rare verdict shapes, the role file already specifies the required fields, and a bash re-implementation of the enum+conditional-field matrix is brittle and duplicates the role-file spec.
- **The threat-coverage empty-binding check IS PRESERVED as a mechanical guard** — the inline bash assert in the byte-aligned region above (`^[pP]` regex, exit 4 when a threat-ratified mitigation is declared with no well-formed probe-id). This is the §35 / `stoa--yfv` B2 keystone; it is cheap, high-value, single-conditional, and lives in the always-resolvable inline block so it resolves at EVERY tier including subproject.

**The `^[pP]` regex is intentional (the `stoa--j2i` fix).** The retired Python used a lowercase-only `^p[0-9A-Za-z._-]+$`, which rejected canonical uppercase probe-ids (`P-INJ`) — the live `stoa--j2i` bug. The bash assert uses `^[pP]…` (case-insensitive leading p/P) so it accepts uppercase probe-ids. This is the one place the rewrite changes behavior on purpose; the j2i bug is retired by this module.

## Threat-classification note

This module is process / role-file hardening — `not threat-ratified (process change — skill→module rehoming + verdict-durability hardening + doc-coherence repair + dest-exists clobber-guard; no runtime attacker, no attack path)` per the §35.5 self-carve-out. The path-traversal / probe-id regexes are input-hygiene (the inputs come from the trusted PLINY brief), not §35 threat-mitigations.

## Cross-references

- `CAPTAIN_VERA.md` §7 / `CAPTAIN_ARGUS.md` §7 / `CAPTAIN_CATO.md` §7 — the inline §7 procedure (byte-aligned with this module's region).
- `MAJOR_PLINY.md` §5.14 (worktree-dest-pin discipline) + §5.16 (attach hand-back / durability close at the orchestrator).
- `operating-disciplines.md` §15.4 (verification-complexity shapes — the §15.4 seat-side SSoT) + §35 / §35.5 (threat-ratification + carve-out) + §28 (cite-at-read-site SSoT).
- `canonical-template-alignment.md` (the byte-alignment discipline; the four-home byte-identity is enforced by a manual `diff`, not an automated gate).
