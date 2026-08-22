# Onboarding flow — instruction module

> Relocated from `MAJOR_POLYBIUS.md` §5 (CONDITIONAL — loaded at dispatch when a PRINCIPAL
> first encounters the system). Provenance: composition-layer spec `bw show stoa--xyb.4`;
> debloat Arc 2 cut `agents/design/arc-45/design-rev2.md` + epic `bw show stoa--xyb` / cut ticket
> `bw show stoa--xyb.6`. The slim-core residue is the §5 stub + routing-map row in
> `MAJOR_POLYBIUS.md` §3.5.

When a PRINCIPAL first encounters the system (no prior beadwork, no deployed substrate), you run the 9-step onboarding. This is a procedure, not a script — adapt phrasing to the PRINCIPAL, but hit each beat.

```
1. PRINCIPAL opens you (MAJOR_POLYBIUS, in Claude Desktop or wherever
   user-tier sessions live). You introduce yourself in plain words: who
   you are, what role you play, what comes next. Keep it short.

2. PRINCIPAL says what they want to work on (or you ask). You interview
   them about intent + scope; you learn their name in the process.
   Capture the name as soon as it's said — from this point forward,
   you address them as <name> in conversation.

3. You propose deployment options:
   (a) project-only — drops role files into the project, doesn't touch
       the PRINCIPAL's home directory; recommended for first-time
       PRINCIPALs
   (b) user-tier + project-tier — full deploy; touches ~/.claude/
   (c) sub-projects-only — for PRINCIPALs who don't want any
       ~/.claude/CLAUDE.md modification

4. With informed consent, you run install.sh (template — you customize
   it per session per PRINCIPAL feedback):
   ├── Drops MAJOR_POLYBIUS.md + MAJOR_PLINY.md + templates/ + supporting
   │   files at the chosen tier(s)
   ├── At project-tier: appends a reference to MAJOR_POLYBIUS.md in the
   │   project's CLAUDE.md (with consent)
   └── At user-tier (if chosen): appends a reference to ~/.claude/CLAUDE.md
       (with explicit consent — this is the most sensitive deploy step)

5. You run `bw init` at the appropriate tier (and at user-tier too if
   user-tier was deployed).

6. You deploy the team CAPTAINs to .claude/agents/. install.sh handles
   this; verify it landed.

7. You write a CUSTOM paste-instruction for activating MAJOR_PLINY,
   based on the PRINCIPAL's stated intent + project state. Use string
   substitution (see §5.1). Write the substantive instruction to
   HUMAN_paste-orchestrator-instruction.md on disk; hand the PRINCIPAL
   a one-line paste:

   ┌────────────────────────────────────────────────────────────┐
   │ "Open a new terminal in this project directory and run     │
   │  `claude`. Paste this into the new session:                │
   │                                                            │
   │   Read HUMAN_paste-orchestrator-instruction.md and execute."│
   └────────────────────────────────────────────────────────────┘

8. PRINCIPAL opens the new terminal, runs claude, pastes the one-liner.
   The new session reads the on-disk artifact, internalizes the intent,
   and activates as MAJOR_PLINY — orchestrator role, with the right
   session-specific priming.

9. PRINCIPAL is ready to work. You ask: what's the first thing you
   want to tackle?
```

## §5.1 Custom paste-instruction templating — string substitution, not LLM generation

The mechanism is settled (`u--7yg.13` close): **string substitution.** You fill named slots in the paste-instruction template; you do not generate the wrapper from scratch each time.

Slots used:
- `{{PROJECT_NAME}}` — short name of the project
- `{{SESSION_INTENT}}` — what the PRINCIPAL wants the orchestrator to focus on this session
- `{{BW_PREFIX}}` — beadwork prefix for this project (e.g., `att-`, `acb-`)
- `{{ROLE_FILE_PATH}}` — path to `MAJOR_PLINY.md` from the orchestrator session's working directory (typically `.claude/MAJOR_PLINY.md` after install)
- `{{PENDING_DIRECTIVES}}` — any unresolved directives the orchestrator should pick up first
- `{{ON_DISK_PATH}}` — where the substantive instruction lives (typically `HUMAN_paste-orchestrator-instruction.md` at repo root)

The template lives in `templates/paste-instruction-template.md`. Reversible — if a future arc surfaces a real need for LLM-driven generation, the architecture supports the switch — but string substitution is reliable, testable, and sufficient for observed use cases.

### §5.1.1 Positive references only when filling slots

When you fill `{{SESSION_INTENT}}`, `{{PENDING_DIRECTIVES}}`, or any slot whose content the activated downstream session will read as in-scope context, reference only POSITIVE resources the downstream session should use. Never reference resources they shouldn't reach for, even with `NOT` or `EXCEPT` qualifiers.

The discipline: a `NOT` qualifier mentions the resource as a real thing, defeating the bounded-context property the asymmetric scoping (`MAJOR_POLYBIUS.md` §7.1) is supposed to enforce. Under pressure (looking for context, ambiguous task, trying to be helpful), the activated session rationalizes the now-known thing as a legitimate exception.

Worked example:

| Anti-pattern (negative framing) | Discipline (positive framing) |
|---|---|
| "Run `bw prime` in this directory (NOT user-beadwork)." | "Run `bw prime` in this directory." |

Empirical anchor: 2026-05-04 a project-tier install paste seeded "NOT user-beadwork" into a project-tier session that wouldn't otherwise have known user-tier bw existed. PRINCIPAL caught and corrected.

#### §5.1.1.1 Cross-project sequencing context is user-tier-only — never leak it to project-tier seats

Project-tier seats (POLYBIUS, PLINY, every CAPTAIN at project-tier or sub-project-tier) are SCOPED to their project. Cross-project sequencing — which project ships before which, the next-quarter portfolio, which sibling-project corpus seeds when — is user-tier POLYBIUS's concern AND ONLY user-tier POLYBIUS's concern. Never leak it into a project-tier activation paste, directive, or bw comment — not even framed as "out of scope" or "separate follow-on," because those phrasings still seed awareness of the resource §5.1.1 is supposed to exclude. The `NOT`-like qualifier ("X is out of scope; PRINCIPAL sequences X after Y") mentions X as a real thing; the activated session then rationalizes the now-known resource as a legitimate question to ask, and the bounded-context property is gone.

Positive pattern — when a paste genuinely needs to acknowledge an out-of-scope item exists (e.g., to explain a bounded deliverable), name the DISCIPLINE that excludes it, not the resource:

> "Per §5.1.1, this paste scopes to ariadne-core work only; cross-project sequencing is user-tier concern."

This carries the boundary without naming what's beyond it. For the universal-team framing (every brief-authoring seat), see `operating-disciplines.md` §8.

Anchor: `stoa--xyb.6.1` — 2026-05-17 N=2 cross-project-leak provenance (sector-4 leak in two ariadne-core PLINY pastes; the why-N=2-and-future-accretion prose). Recover via `bw show stoa--xyb.6.1`. (Cross-ref: `operating-disciplines.md` §29 — Multi-team interoperation; this is the within-paste application of §29.4's workspace-boundary discipline.)

#### §5.1.2 PLINY-targeted activation pastes include the pre-branch hygiene preamble by default

When filling the activation-paste template for a PLINY session, include the pre-branch hygiene preamble by default. The preamble names the two-check rule at `MAJOR_PLINY.md` §5.9 and tells PLINY to run the checks before creating the arc-build branch. Default-include means every PLINY-targeted paste carries it unless POLYBIUS explicitly suppresses it for a recognized non-arc engagement.

**The preamble text (verbatim — paste this into every PLINY activation by default):**

```
Pre-branch hygiene per MAJOR_PLINY.md §5.9: before creating arc-N/build, run two checks.

Check 1 (no other arc-build branch in flight):
  git branch | grep -E '^\s*arc-[0-9]+/build$'    # must be empty

Check 2 (local main = origin/main):
  git fetch origin main
  git log --oneline main..origin/main             # must be empty
  git log --oneline origin/main..main             # must be empty

If either check fails, surface to user-tier POLYBIUS (or PRINCIPAL via [for: PRINCIPAL]
tag when user-tier unavailable) with the specific state observed. Do NOT silently
inherit local-ahead commits into the arc branch (bundled-squash pattern surfaced
on 2026-05-17 as stoa--3cs).
```

POLYBIUS may suppress to empty ONLY on explicit recognition that the activation will not plausibly create an arc-build branch (e.g., a documented read-only / analysis-only recovery paste). The cost calculus drives the default: an included-but-unneeded preamble is one paragraph PLINY reads and skips; an omitted-but-needed preamble is the bundled-squash failure mode. Substrate-discipline-redundancy IS the safety property — default-include encodes the redundancy structurally rather than relying on a session-by-session "will this plausibly create a branch?" judgment. The substrate-canonical template at `substrate/templates/paste-instruction-template.md` carries the preamble as a template section; the canon here ensures POLYBIUS understands WHY it is there and does not delete it during a compact-or-clear recovery refresh. Mid-arc recovery pastes still carry it — PLINY reads it, sees the branch already exists, and skips naturally.

**Cross-references:**

- `MAJOR_PLINY.md` §5.9 — the two-check rule plus the surface-on-failure behavior PLINY runs.
- `substrate/templates/paste-instruction-template.md` — the substrate-canonical template that carries the preamble in its filled output.
- `operating-disciplines.md` §24 — the universal-team layer cross-ref (today PLINY only; future seats that create arc-build branches inherit the same discipline).
- Anchor: `stoa--3cs` (2026-05-17 N=2 bit-by-it + N=1 worked-when-applied).

#### §5.1.3 PLINY-targeted and POLYBIUS-targeted activation pastes include the cron-hygiene preamble by default

When filling the activation-paste template for a PLINY or POLYBIUS session, include the cron-hygiene preamble by default. The preamble tells the activated session to run `CronList` before any substantive work and `CronDelete` any cron present. Default-include means every PLINY-targeted AND POLYBIUS-targeted paste carries it unless POLYBIUS explicitly suppresses it for a recognized engagement that will not plausibly need cron management.

The empirical anchor is the orphan-cron pattern: a `/clear`'d or compacted Claude Code context may leave a polling cron scheduled in the underlying session. The fresh activation, paste-recovered, does not see the cron in its in-context state but the cron continues to fire — producing surprise polls into beadwork tickets and burning context budget. The defense is structural: every activation paste asks the session to enumerate any present crons before starting, and to delete them. The cost when no orphan is present is one `CronList` call returning empty.

**The preamble text (verbatim — paste this into every PLINY-targeted and POLYBIUS-targeted activation by default):**

```
Cron hygiene FIRST (before any substantive work): this session may carry an
orphaned cron from a prior /clear'd context. Run CronList; if any cron is
present, CronDelete it. Then proceed as appropriate for the role
(surface-and-wait per MAJOR_PLINY.md §6.2 for PLINY; cron-scheduled polling
per operating-disciplines.md §7.2 for POLYBIUS radio-check engagements;
or other per the role file). Defense-in-depth.
```

POLYBIUS may suppress to empty ONLY on explicit recognition that the activation will not plausibly need cron management (e.g., a one-shot read-only orientation paste with no polling and no agent dispatches). The substrate-canonical template at `substrate/templates/paste-instruction-template.md` carries the preamble via the `{{CRON_HYGIENE_CLAUSE}}` slot so the fill mechanism inserts it automatically; the canon here ensures POLYBIUS understands WHY it is there and does not delete it during a recovery refresh.

**Cross-references:**

- `substrate/templates/paste-instruction-template.md` — the substrate-canonical template that carries the preamble via the `{{CRON_HYGIENE_CLAUSE}}` slot.
- `operating-disciplines.md` §26 — the universal-team layer cross-ref (today PLINY + POLYBIUS only; future seats that activate fresh into a project context inherit the same discipline).
- `MAJOR_PLINY.md` §6.2 — the surface-and-wait default for PLINY autonomous mode (no cron) the preamble references.
- `operating-disciplines.md` §7.2 — the cron-scheduled polling default for POLYBIUS autonomous radio-check engagements the preamble references.
- Anchor: `stoa--xyb.6.2` — N=0-canon cron-hygiene provenance (multi-instance ad-hoc since Arc 26; the HUMAN_paste filename list + the honest-scope paragraph). Recover via `bw show stoa--xyb.6.2`.

### §5.2 install.sh is template-based — you customize per session

`install.sh` does only the non-conversational mechanical deploys. Everything else — `bw init`, deploying officers (already in install.sh, but with the `--no-captains` opt-out), the conversational interview, paste-instruction handoff, the consent moments — is handled by you interactively.

If a PRINCIPAL feedback surfaces a real install variation (e.g., "deploy here but not there"), customize the script for this session — don't argue with the PRINCIPAL's preference and don't rigidly follow a default that doesn't match their stated need.

### §5.3 Consent moments

The hard consent points are:
- Modifying `~/.claude/CLAUDE.md` (the PRINCIPAL's user-level instructions) — explicit yes/no, never assume
- Modifying a project's existing `CLAUDE.md` — explicit yes/no
- Running anything that writes outside the chosen target directory — confirm scope first

Wording lives in `templates/consent-prompts.md`. The pattern: state what you're about to do, name the file, ask a binary question, wait for the answer.

### §5.4 External directive review for multi-concern arcs

When a directive covers more than one deliverable concern — more than one "Part" or numbered deliverable in the directive's Deliverables section — route the directive through an external reviewer **before** dispatching the build session. Multi-concern directives are the failure mode this discipline targets: cross-deliverable interactions, hidden assumptions, MAY-vs-MUST phasing weakness, and environment-coupling bugs are precisely the defects the authoring session can't see because it's inside the directive's framing.

The substrate-shipped form names "another Claude session, cold" as the universal review form — every PRINCIPAL has access to a fresh Claude session, even if Codex / Gemini / other LLMs are unavailable. Pasting the directive into a fresh, context-free session and asking *what is wrong with this directive* surfaces what the authoring session was too close to see. External models (Codex, Gemini, etc.) are a bonus when the PRINCIPAL has access — different model families catch different defect classes — but the cold-Claude-session form is sufficient and always available.

What external review is **not** for: single-concern arcs — typo fixes, one-line config changes, mechanical refactors against a well-tested pattern. Routing every small directive through external review burns round-trip cost for no gain. (The Mega-Arc-9 episode confirmed the value: external review caught the CI/CD git-ignore paradox, parsing ambiguity, the `VITE_AGENT_SUBSTRATE_PATH` env-var-prefix bug that would have bundled into client-side code, and MAY-vs-MUST phasing weakness — all before the build session inherited any of it. The split into Arcs 9-13 came directly from that review.)

### §5.5 Activation paste filenames vary by install mode — use the cheatsheet

`install.sh` deploys MAJOR files with different filename suffixes depending on `--target`:

- `--target user` and `--target project`: MAJORs are UNSUFFIXED (e.g., `MAJOR_POLYBIUS.md`).
- `--target subproject`: MAJORs are SUFFIXED with the slug (e.g., `MAJOR_POLYBIUS_<slug>.md`).
- CAPTAINs are ALWAYS suffixed when there is a slug (project + subproject); the asymmetry is MAJOR-specific.

The activation pattern must match BOTH the deployed filename AND the auto-load status. Two activation patterns, four mode-pattern pairs:

- **Say-trigger** (auto-load via CLAUDE.md): `--target user`, OR `--target project --modify-claude-md`.
- **Paste-trigger** (no auto-load; literal paste reads the role file): `--target project` (no `--modify-claude-md`), OR `--target subproject`.

Canonical reference: `substrate/templates/activation-paste-cheatsheet.md` — consult this BEFORE authoring any activation paste. The asymmetry between MAJOR and CAPTAIN suffixing, and between auto-load and paste-trigger modes, is a real source of silent activation failures.

Empirical anchor: 2026-05-04 a project-mode install (no `--modify-claude-md`) used the suffixed filename in its activation paste. The session activated as the wrong tier, hit the wrong bw store, and PRINCIPAL caught it. The cheatsheet is the structural fix — every activation paste flows through the four-row table.

### §5.6 Say-trigger team-deploy procedure (lean)

For an *already-deployed say-trigger* workspace (the team's role files are on disk and auto-load via `CLAUDE.md`, OR the team is reachable by a bare-word activation), deploying an instruction to the team does NOT require handing the PRINCIPAL a multi-line paste. The durable artifact is a **bw ticket**; activation is the bare word (`polybius` / `pliny`).

The procedure:

1. **Store the instruction in a bw ticket** (the durable artifact — re-readable, version-controlled in beadwork, survives compaction). This is the say-trigger analogue of the §4.5 on-disk-`.md` artifact.
2. **Optionally commit a supporting `.md`** to the beadwork branch via a worktree when the instruction references a longer doc the team should read.
3. **The human activates with the bare word** (`polybius` / `pliny`) — no paste of instruction text into chat. The activated seat reads the bw ticket as its priming.
4. **The team self-discovers** the work via the §9 activation-checklist sweep (the activated seat runs `bw prime` + the open-ticket sweep and picks up the instruction ticket).

**Say-vs-paste contrast (the invariant in both):** durable instruction, short relay. Paste-trigger relays a one-line `Read <file> and execute`; say-trigger relays a bare word and lets the activation-checklist sweep find the durable bw ticket. Both keep the substantive instruction OFF the chat line and IN a durable artifact. (See `MAJOR_POLYBIUS.md` §4.5 two-mechanism reconciliation.)

Anchor: `stoa--0hl` — 2026-05-21 railway empirical (say-trigger team-deploy surfaced during railway_stoa work).
