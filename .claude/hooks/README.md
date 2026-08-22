# Enforcement hooks — the deterministic tier of the Stoa enforcement layer

This directory holds **harness-owned PreToolUse / Stop hook scripts**: the deterministic,
compaction-immune tier of the Stoa enforcement layer (design `bw show stoa--xyb.5`; design-rev1
at `agents/design/arc-46/design-rev1.md`). It is the detailed reference for the hook tier; the
always-loaded one-paragraph authoring rule lives at `operating-disciplines.md` §34.

This file is itself a deployed artifact (it lands at `.claude/hooks/README.md` after `install.sh`
runs) — the canon's detail is loaded on-demand the same way every module's detail is, keeping the
always-loaded §34 rule thin. That dogfood mirrors `modules/README.md` (§33).

> Provenance: enforcement-layer design + the cron-survives-compaction principle `bw show stoa--xyb.5`;
> composition-layer mechanism (the deploy-class idiom this mirrors) `bw show stoa--xyb.4`. Shipped
> Arc 46 (debloat Arc 3) — Stage 1 (deterministic tier).

---

## 1. Why these exist — adherence that survives compaction

Arcs 44–45 cut role-file bloat by relocating content into the composition layer. That cut is only
safe if **adherence to the surviving rules survives context compaction**. A hook is *harness-fired,
not model-fired*: it executes regardless of what the model's compacted context still holds. That is
the load-bearing property — the deterministic gates here enforce three load-bearing footguns even
when the agent that triggered them has forgotten the rule.

The tier is **defense-in-depth**, not the whole defense. The prose disciplines (global CLAUDE.md
authorship rule, `operating-disciplines.md` §12 / §24) remain the primary defense; these gates are
the deterministic backstop for the regressions the prose alone has let through.

---

## 2. THE AUTHORING RULE (the load-bearing convention for every trigger payload)

**Every trigger payload — a hook `permissionDecisionReason`, a Stop `reason`, a PostToolUse
`additionalContext`, or a cron prompt body — MUST state, self-contained inline:**

1. **WHY it fired** — what was blocked / what the trigger is checking, and
2. **WHAT to do** — the concrete next action to proceed.

**Never a bare pointer** ("see §X.Y.Z", "per the discipline"). A pointer fails after compaction:
the trigger's entire value is that it re-tells the rule the agent has forgotten, and an agent that
has compacted cannot follow a pointer to a section it no longer holds. The payload must carry the
instruction, not a reference to it.

Worked examples (all from the gates in this directory):

- clean-tree deny: names the *dirty paths inline* and the three resolution verbs (commit / stash /
  clean), not "see the branch-hygiene discipline".
- no-`-m` deny: shows the *wrong form*, the *correct positional form*, and *why* the footgun loses
  data — inline, in the message.

When you author a new trigger payload anywhere in the substrate, this is the rule it must obey.

---

## 3. The script contract (uniform across all gates)

- **Input:** one JSON hook event on **stdin** (`tool_name`, `tool_input.command`, `session_id`,
  `cwd`, `transcript_path`, ...). Parsed with `python3` (POSIX-portable, assumed present per
  `operating-disciplines.md` §13; `jq` is NOT assumed). Shared helpers: `_hooklib.sh` (not a hook
  itself — leading underscore, never registered).
- **PreToolUse output:** allow = exit 0, no stdout (normal permission flow). deny = exit 0 with
  stdout JSON `hookSpecificOutput.{hookEventName:"PreToolUse", permissionDecision:"deny",
  permissionDecisionReason:"<self-contained message>"}`. (exit-0 + JSON is chosen over exit 2 so the
  precise model-facing reason is carried; exit 2 only forwards stderr.)
- **Stop output:** allow = exit 0, no stdout. block = exit 0 with stdout JSON
  `{decision:"block", reason:"<self-contained checklist>"}`. Stop does NOT support
  `additionalContext` (live-verified 2026-05-23) — the checklist rides `reason`.
- **FAIL-OPEN on script error.** Any internal error (no python3, malformed event, no git,
  unreadable config) → the script allows the tool call. This is a deliberate inversion of the usual
  "fail closed for safety": a fail-CLOSED gate that errors would block every gated tool call in the
  live session and **brick the running team**; a fail-OPEN gate degrades to today's no-enforcement
  baseline, which is safe. (Design §4 / ARGUS R5.)

---

## 4. The gates and triggers

**Stage 1 — the deterministic tier (PreToolUse deny / Stop block; WORKING channels).**

| Script | Event | Narrowing `if` | Blocks |
|---|---|---|---|
| `pretooluse-clean-tree-before-branch.sh` | PreToolUse | `Bash(git *)` | arc-build branch / worktree creation when the tree is dirty |
| `pretooluse-no-dash-m-bw-comment.sh` | PreToolUse | `Bash(bw comment*)` | the `bw comment <id> -m "..."` data-loss footgun |
| `stop-self-check.sh` | Stop | (none) | once per turn: a self-check backstop (checker-dispatched? gate not dodged? commit attributed?) |

**Stage 2 — the judgment tier (best-effort `additionalContext` reminders; the channel is upstream-broken — see §6).** These do NOT block or deny; they (best-effort) REMIND the orchestrator to act. Their reliability backstops are the WORKING channels above + cron + CLAUDE.md, never the additionalContext channel itself.

| Script | Event | Matcher | Reminds (best-effort) |
|---|---|---|---|
| `posttooluse-agent-checker-trigger.sh` | PostToolUse | `Agent` | on a sub-agent return (parent context): dispatch CAPTAIN_NOMOS to confirm the returned output conforms to bw ground truth before propagating it. Recursion-guarded by the **active** layer-1 `agent_type` match (no-op on a NOMOS return), plus a **forward-compatible / not-yet-armed** layer-2 session-sentinel fallback (see §6.1). |
| `sessionstart-compact-reprime.sh` | SessionStart | `compact` | on a compact-triggered resume: re-prime the orchestrator's standing engagement context (seat, open epic, polling cadence, dispatch-NOMOS reminder). Payload from `.claude/hooks/reprime-context` if present, else a generic role reprime. |
| `sessionstart-substrate-check.sh` (Arc 63) | SessionStart | `startup\|resume` | on a normal start/resume: run check-substrate-updates + check-bw-release CHECK logic once/session-start (throttled ~once/day, silent-when-current, fail-open) and surface drift. **NOT a best-effort hook** — its `startup\|resume` additionalContext is a WORKING channel (v2.1.170; §6 NARROW SCOPE) AND it writes a P-FALLBACK `.substrate-drift-signal` read by the Stop self-check clause (D) + CLAUDE.md, so drift surfaces off-additionalContext too. Listed here as a SessionStart sibling, but it is a reliable carrier, not Stage-2 best-effort. |

The PRINCIPAL allow-list the **attribution-advisory skill's SECONDARY check** reads is
`.claude/hooks/principal-identity` (one name/email per line; `#` comments + blanks ignored),
written at install time. It is the skill's CONFIG (the PRINCIPAL identity the advisory compares NEW
author-like field values against) — **not an author-like field of any repo artifact**. The advisory
only REPORTS a value not on the list; it never blocks.

### Retired gates (Arc — stoa--p0e)

The authorship deny-gate `pretooluse-author-field-audit.sh` (formerly a `PreToolUse` /
`Bash(git commit*)` gate that could DENY a commit) was **retired** in Arc `stoa--p0e` per the
PRINCIPAL SCOPE-RESHAPE ruling. The script + its regression corpus are archived under
`substrate/v1-historical/hooks/` — see `substrate/v1-historical/hooks/RETIREMENT.md` for the WHY.
Its replacement is the **report-only `attribution-advisory` skill**
(`substrate/skills/attribution-advisory/`), which surfaces attribution-line MODIFY/DELETE hunks (the
plagiarism / license-breach direction) into `.claude/attribution-advisory-report.md` and NEVER
denies. The `.claude/hooks/principal-identity` allow-list survives the retirement — the advisory's
SECONDARY check reuses it.

---

## 5. SAFETY ARCHITECTURE — source-only, default-OFF, never the running session

**The HARD SAFETY CONSTRAINT (design-rev1 §8).** These scripts are substrate SOURCE. Deploying the
*scripts* to a `.claude/hooks/` directory is **INERT**: Claude Code only fires hooks that are
**registered in a `.claude/settings.json`**. No Stoa arc and no `install.sh` run auto-writes a live
`settings.json`. The scripts sit dormant on disk until an operator explicitly arms them.

- **Arming is a separate, operator-gated, DEFAULT-OFF step.** `install.sh --enable-hooks` (default
  OFF) is the only path that merges the candidate `settings-hooks.json` block into the target's
  `.claude/settings.json`. When the flag is OFF (the default), **no hooks are registered** — the
  scripts and the candidate template deploy, nothing is armed.
- **Even with `--enable-hooks`, the merge targets the INSTALL TARGET, never the running build
  session.** And at **user tier** the target `~/.claude/settings.json` IS the running session's
  config — so `--enable-hooks` at user tier is doubly guarded: it is off by default AND the install
  prints the merge as a MANUAL instruction rather than auto-writing `~/.claude/settings.json`
  (ARGUS r4). An agent never auto-writes a live `~/.claude/settings.json`.
- **Isolation testing only.** Test the gates by feeding synthetic stdin JSON to the scripts
  directly, or by deploying to a THROWAWAY target dir / `git clone --no-local` scratch repo. Never
  run `--enable-hooks` against anything but a throwaway. Never edit a live `.claude/settings.json`
  by hand from inside a build.
- **Why this matters:** a PreToolUse gate on `git commit` / branch-create armed into the *running*
  team's own `settings.json` would gate the running team's OWN operations — gating the very session
  doing the build. That is a no-experiments-on-real-agents violation in spirit (the live canonical
  seats are the "real agent").

### Arming the hooks intentionally (operator runbook)

When an operator genuinely wants the gates live on a target workspace:

1. Inspect the candidate block at `<target>/.claude/templates/settings-hooks.json`.
2. Either run `install.sh ... --enable-hooks` (project tier — merges into the TARGET's
   `<target>/.claude/settings.json`, never the running session), OR at user tier follow the printed
   manual-merge instruction to merge the block into `~/.claude/settings.json` yourself.
3. Confirm `.claude/hooks/principal-identity` lists every valid PRINCIPAL name/email (the
   `attribution-advisory` skill's SECONDARY check REPORTS — never denies — any NEW author-field
   value not on the list, with a widen-the-list note in the advisory report).
4. The gates are now live for that workspace's sessions. To disarm, remove the `hooks` block from
   that `settings.json`.

---

## 6. The `additionalContext` injection bug — why the Stage-2 hooks are best-effort

The two Stage-2 judgment-tier hooks (`posttooluse-agent-checker-trigger.sh`, `sessionstart-compact-reprime.sh`)
inject their reminder/reprime via the `additionalContext` channel. **Those specific channels are broken
upstream across current shipping versions** (web-verified 2026-05-23; the PostToolUse/PreToolUse + the
SessionStart-`compact` regressions persist through changelog **v2.1.170**):

> **NARROW SCOPE (Arc 63 / stoa--p41.2).** The breakage is matcher/event-specific — it is NOT that
> `additionalContext` is universally dead. The **SessionStart `startup|resume`** matcher's
> `additionalContext` IS a WORKING injection channel as of **v2.1.170** (only the `compact` matcher,
> #15174, is broken). That is why the Arc-63 `sessionstart-substrate-check.sh` hook (matcher
> `startup|resume`) reaches the model on a normal start/resume and is NOT a Stage-2 best-effort hook —
> it ships with a working primary surface PLUS a non-additionalContext P-FALLBACK (the
> `.substrate-drift-signal` file read by the Stop self-check clause (D) + CLAUDE.md), so its drift
> surface holds even if the channel ever regresses. The table below covers only the still-broken
> PostToolUse/PreToolUse + SessionStart-`compact` cases.

| Issue | State | Scope | What it confirms |
|---|---|---|---|
| [#55889](https://github.com/anthropics/claude-code/issues/55889) | OPEN (`bug` + `has repro`), v2.1.123 | PostToolUse / PreToolUse `additionalContext` (regression from v2.1.9 "added but not actually wired up") | The PostToolUse `additionalContext` payload may NOT reach the model. The reporter explicitly notes `permissionDecision:"deny"` + `permissionDecisionReason` DO reach the model on deny — i.e. the Stage-1 deny channel is unaffected. |
| [#18427](https://github.com/anthropics/claude-code/issues/18427) | CLOSED-not-planned (Jan 2026) | broader, matcher-agnostic: "PostToolUse cannot inject context visible to Claude" | The broadest confirmation — PostToolUse context injection is not a supported path, independent of matcher. Strengthens (does not narrow) the finding. |
| [#19432](https://github.com/anthropics/claude-code/issues/19432) | reported Jan 2026 | PreToolUse `additionalContext` dropped | Companion confirmation on the sibling event. |
| [#15174](https://github.com/anthropics/claude-code/issues/15174) | CLOSED-as-duplicate, v2.0.72–v2.0.76 | SessionStart(matcher:`compact`) `additionalContext` | The hook EXECUTES but its output is NOT injected after compaction. Documented impact: "Blocks multi-agent orchestration systems that need role reminders." Named workaround: "Add reminders directly to CLAUDE.md, which DOES get loaded after compaction." |

**The design posture (design-rev1 arc-50 §2 / §5.2 / §5.5).** Both Stage-2 hooks are shipped
**best-effort + forward-compatible + harmless-when-broken**: the payloads are correct and start
working the moment the upstream issues close; when broken, the output is simply dropped (no side
effect). They are NOT the reliable carriers. Every Stage-2 behavior that MUST happen rests on a
WORKING channel instead:

- **NOMOS-dispatch reminder** — the reliable carrier is the Stage-1 **Stop self-check**
  (`stop-self-check.sh`, clause A — `decision:"block"` + `reason`, a working channel), which reminds
  the orchestrator to dispatch NOMOS at turn-end. The PostToolUse-on-Agent hook reminds *earlier* (at
  sub-agent return) IF/when the platform fixes #55889 / #18427.
- **Post-compaction reprime** — the reliable carriers are **CLAUDE.md** (loaded after compaction —
  the #15174 issue's own named workaround) and the **polling cron**
  (`templates/polling-cron-prompt-template.md` — fresh harness-fired input that survives compaction
  by construction, the `bw show stoa--xyb.5` founding principle). The SessionStart-compact hook is a
  forward-compatible supplement, not the guarantee.

**When to revisit.** When #55889 / #18427 / #15174 close (or a changelog entry restores
`additionalContext` injection), re-test the two Stage-2 hooks end-to-end and promote them from
best-effort to load-bearing carriers. Until then they document the dependency and serve as the
tripwire for that future arc.

### 6.1 The NOMOS-trigger recursion guard — layer-1 active, layer-2 not-yet-armed

`posttooluse-agent-checker-trigger.sh` must not remind "run NOMOS" when the sub-agent that just
returned IS NOMOS. It carries a two-layer guard, but **only layer-1 is active today**:

- **Layer-1 (ACTIVE) — `agent_type` match.** The hook inspects the return event's `agent_type`
  fields for a NOMOS seat name and no-ops on a match. This is the live guard.
- **Layer-2 (FORWARD-COMPATIBLE / NOT-YET-ARMED) — session-sentinel.** The hook also READS a
  per-session `.nomos-sentinels/<session>` sentinel and would suppress re-firing if one were present.
  **It is INERT today: nothing in the substrate WRITES that sentinel** (contrast the Stage-1 Stop
  sentinel, which self-writes in `stop-self-check.sh`). The read never finds a file, so the branch
  never fires. Layer-2 activates only once a future arc adds an orchestrator-writes-sentinel-on-
  NOMOS-dispatch site — the same promotion arc that fixes the best-effort `additionalContext` channel
  once #55889 closes (§6). The read path ships now so that arc only has to add the write side.

**Why shipping layer-2 inert is harmless.** The session-sentinel exists as a belt-and-suspenders for
the case where layer-1 cannot see the returning seat (the parent-on-return event's population of
`agent_type` is UNCONFIRMED per the SDK docs, which promise `agent_type` only "when the hook fires
INSIDE a subagent"). Even with layer-2 unarmed, the worst case is bounded: if layer-1 ever misses,
the orchestrator gets one no-op reminder it reads and recognizes as not-applicable. NOMOS is a leaf
and cannot dispatch a further NOMOS, so there is no loop. The bounded-failure property is why this
arc ships layer-2's read path ahead of its write site.

---

## 7. The `.md` frontmatter-only narrowing (Arc 65 / stoa--z2b) — HISTORICAL (retired gate)

> **HISTORICAL to the RETIRED gate (Arc stoa--p0e).** This section documents the `.md`-matcher
> narrowing of `pretooluse-author-field-audit.sh`, which was RETIRED (see "Retired gates" in §4 and
> `substrate/v1-historical/hooks/RETIREMENT.md`). It is preserved as the durable record of the z2b
> narrowing lore — the `classify_author_file` / `extract_author_fields` functions it describes still
> exist in `_hooklib.sh` but are now DEAD (no surviving caller). Read it as history, not as an
> active-gate reference.

The author-field gate (`pretooluse-author-field-audit.sh` sub-check 2) used to treat **every** `*.md`
file as an author-encoding file and run the multiline, anywhere-in-blob author-field regex over its
whole text. That regex fires on any of 12 author-like field words followed by `:` / `=` ANYWHERE — so
it false-positived on `.md` **body prose** that merely *discusses* authorship rather than declaring a
structured author field. (Examples that tripped the OLD gate, written here with the value portion as a
`<…>` placeholder so this README itself passes the gate: a seat-attribution line of the form
`Authored by: <a seat name plus the PRINCIPAL>`; a verdict authorship-AUDIT line of the form
`author = <PRINCIPAL, no other person>`.) None of those is a real violation — the only PERSON named was
the PRINCIPAL, and a seat name is not a person.

Arc 65 narrows the `.md` matcher. Membership AND extraction mode now come from ONE function,
`classify_author_file` in `_hooklib.sh`, so the two can never disagree.

**WHAT it covers now (unchanged value, plus the narrowed `.md` window):**

- **Config files — UNCHANGED, whole-file scan (`cfg` mode):** `plugin.json`, `marketplace.json`,
  `package.json`, `pyproject.toml`, `setup.py`, `Cargo.toml`, `Gemfile`, `composer.json`, `NOTICE`,
  `CITATION.cff`, `metadata.json`, `manifest.json`, `LICENSE` / `LICENSE.*` — **INCLUDING `LICENSE.md`
  and `*.claude-plugin/*.md` plugin docs**, which are config-class and keep the whole-file scan. The
  `cfg` extraction is byte-identical to pre-Arc-65.
- **Prose `.md` — NARROWED, frontmatter only (`md` mode):** an author-like field is matched ONLY in the
  leading YAML frontmatter block (`--- ... ---`), at YAML line-start, with a `:` separator. A `.md` with
  no frontmatter matches nothing.

**WHAT it deliberately no longer matches (the explicit delegation — C3):** author-like words in a PROSE
`.md` **body** (verdict authorship-AUDIT lines, `§28` seat-attribution docs, directive "Authored by"
attribution lines, security/ownership discussion prose).

- **WHY:** those are the structural site of authorship-*discussion*, not authorship-*claims*. Matching
  them was the bug (stoa--z2b). There is no mechanical predicate that admits a real body
  `Author: <some person>` line while rejecting the discussion prose — they are the same lexical surface,
  so any rule re-covering body lines re-opens the false-positive. **No body badge-line convention is
  added.**
- **WHERE the residual goes:** the prose discipline (the global CLAUDE.md authorship rule) + the
  pre-commit / pre-push **manual audit checklist** + NOMOS / human review. Stated plainly: **the gate is
  a backstop, not the whole defense.** A body author-attribution line (an `Author` word with a value) in
  a prose `.md` is OUT of mechanical scope by design.

**The collision carve-out (stated explicitly):** `LICENSE.md` and `*.claude-plugin/*.md` are NOT
prose-md — they are config-class and keep whole-file coverage (so a body copyright-or-author attribution
naming a non-PRINCIPAL in those two classes still BLOCKs). By contrast `NOTICE.md` and other
`<config-basename>.md` files ARE prose-md (basename not in the literal config list), so their body author
line is the delegated residual above. The carve-out is encoded as `case`-arm ORDER (config arms tested
FIRST) and is mechanically guarded by the regression corpus, not just by comment.

**The regression corpus** (now ARCHIVED at `substrate/v1-historical/hooks/tests/` after the Arc
`stoa--p0e` retirement) was the guard for both directions of this narrowing (false-positives pass;
true-positives — including the two collision classes — block). It was **source-only** (it did not
deploy). It still runs against the archived script + the surviving `_hooklib.sh`:
`bash substrate/v1-historical/hooks/tests/run-author-gate-tests.sh`.
