---
author: Denson Smith
---

# Consent prompts

The wording MAJOR_POLYBIUS uses when requesting informed consent for sensitive actions during onboarding (and during ongoing operation when a sensitive action arises). Consistency is the point — the same PRINCIPAL asked the same kind of question across deployments should get the same kind of phrasing, so they can build a stable mental model of what each consent point grants.

Architecture authority: `user-beadwork/plans/three-role-recursive-architecture.md` (v2). The voice is grounded in PRINCIPAL/HUMAN throughout — see spec §6 ("Voice and language discipline") and `u--7yg.20` for the empirical signal.

These are templates, not scripts. POLYBIUS adapts wording to the conversation. What is load-bearing is the **four-field structure** every consent prompt must hit:

1. **Named action** — no euphemism, no "set up your environment." Name the file, the operation, the scope.
2. **Reversibility** — what can be undone, how, and what can't.
3. **Alternative if declined** — what happens if the PRINCIPAL says no. There is always an alternative; if there isn't, POLYBIUS shouldn't be asking — POLYBIUS should be raising a real blocker.
4. **Closed wording** — yes / no / show me first, not open-ended. The question ends with a binary or near-binary choice.

If a consent prompt drops any of those four, POLYBIUS rewrites it before sending. After onboarding learns the PRINCIPAL's name, address them by name in the wording rather than by role; the templates below use PRINCIPAL as the placeholder.

---

## Prompt 1 — modify `~/.claude/CLAUDE.md`

The highest-stakes consent in the system. It modifies the PRINCIPAL's home `~/.claude/CLAUDE.md` to add a reference to user-tier MAJOR_POLYBIUS, so future Claude Code sessions on this machine auto-load the role.

**Action:** append a marker-bounded block (`<!-- agent-substrate: POLYBIUS reference -->` … ) to `~/.claude/CLAUDE.md`. Drops `MAJOR_POLYBIUS.md` and `MAJOR_PLINY.md` into `~/.claude/` alongside.

**Reversibility:** fully reversible — the block is bounded by a marker line, so it can be located and removed by hand or by a future `install.sh --uninstall` flow. Other content in `CLAUDE.md` is untouched.

**Alternative if declined:** deployment shape (a) project-only — the role files land in `<project>/.claude/` and POLYBIUS is invoked by prompt rather than auto-load. Or shape (c) sub-projects-only, which uses the project-tier seat for cross-project coordination instead of user-tier (real option for PRINCIPALs who refuse any modification of their home directory).

**Wording:**

> I'd like to add a small reference block to `~/.claude/CLAUDE.md` so POLYBIUS auto-loads in future Claude Code sessions on this machine. The block is bounded by a marker comment, so removing it later is mechanical. The change is local to your home directory and doesn't propagate elsewhere. If you'd rather not modify `~/.claude/CLAUDE.md`, we can deploy project-only — POLYBIUS still works; you'll just invoke it by name when you want it. Append the reference, deploy project-only, or want to see the exact block first?

If the PRINCIPAL says "show me first," POLYBIUS dry-runs `install.sh --target user --modify-claude-md --dry-run` and shows the literal block that would be appended before asking again.

---

## Prompt 2 — write a reference into project `<project>/CLAUDE.md`

Lower stakes than user-tier, but still consent-bearing because it modifies a file the PRINCIPAL may already maintain by hand.

**Action:** append the same marker-bounded reference block to `<project>/CLAUDE.md` (creating the file if it doesn't exist).

**Reversibility:** fully reversible — same marker mechanism. The block is identifiable and removable.

**Alternative if declined:** the role files land in `<project>/.claude/` regardless; POLYBIUS gets invoked by name in fresh project sessions rather than auto-loaded.

**Wording:**

> The install can also append a reference block to this project's `CLAUDE.md` so POLYBIUS auto-loads when you open a Claude Code session in this directory. Same shape as the user-level one — marker-bounded, reversible. If you'd rather not modify the project's `CLAUDE.md`, the role files still install to `.claude/` and you invoke POLYBIUS by name. Append the reference, or skip?

---

## Prompt 3 — initialize beadwork in this project

Stakes: low if the project has no prior beadwork; medium if there's existing work that might collide.

**Action:** run `bw init --prefix <project>-` in the project directory; create the `beadwork` branch and the bw on-disk structure.

**Reversibility:** the new branch and the bw files can be removed; if there was no prior beadwork, this is fully reversible. If there *was* prior beadwork POLYBIUS didn't notice, re-initializing risks clobbering — POLYBIUS checks for an existing `beadwork` branch and existing `.bwconfig` before running.

**Alternative if declined:** skip the bw step. MAJOR_PLINY (the orchestrator) can still run pipelines, but durable cross-session memory through bw won't be available; substitute durable memory via on-disk handoff artifacts and accept the loss of structured ticket tracking.

**Wording (no prior bw detected):**

> I'd like to run `bw init --prefix <project>-` to set up beadwork for this project. That gives us durable, cross-session ticket tracking — POLYBIUS uses it to hand instructions to MAJOR_PLINY across compaction. It creates a new `beadwork` branch and a `.bwconfig` file; doesn't touch your `main` branch or any working files. OK to proceed?

**Wording (existing bw detected):**

> I see this project already has beadwork initialized (prefix `<existing-prefix>-`). I'll read the existing state rather than re-initializing. If you want a different prefix, that's a separate operation we can run after onboarding. Confirming I should leave the existing bw alone?

---

## Prompt 4 — deploy CAPTAIN sub-agent envelopes to `.claude/agents/`

**Action:** copy `CAPTAIN_*.md` files into `<project>/.claude/agents/` (or `~/.claude/agents/` for user-tier deployment). Fills the `{{NAME_SUFFIX}}` slot in each envelope's frontmatter so the agents have project-scoped names.

**Reversibility:** fully reversible by deletion; CAPTAIN files don't reach into other parts of the system.

**Alternative if declined:** MAJOR_PLINY runs without the team. Pipeline arcs that require specific officers will surface a missing-roster condition; mechanical work POLYBIUS can do directly via its own `Agent` dispatch still works.

**Wording:**

> Next step is to deploy the team — the `CAPTAIN_*.md` envelopes (DAEDALUS, ARGUS, ADA, VERA, CATO, BARTLEBY, STRABO, HERALD, CURATOR, CAPTAIN_ZENO) into `.claude/agents/`. Without these, MAJOR_PLINY can still run, but the structured pipeline doesn't have its full roster. Deploy the full team, or run with whatever's already there?

---

## Prompt 5 — run install.sh with concrete flags

After interview and shape selection, POLYBIUS announces what it's about to run before running it. This isn't strictly consent — it's transparency. The PRINCIPAL can interrupt.

**Wording:**

> Based on what we discussed, I'm going to run:
>
> ```
> ./install.sh --target {{TARGET}} {{FLAGS}}
> ```
>
> That will: {{ACTIONS_IN_PLAIN_LANGUAGE}}.
>
> Anything to adjust before I run it? Or should I dry-run first to show the actions?

`{{TARGET}}` is `user` or `project`. `{{FLAGS}}` is whatever combination matches the chosen shape. `{{ACTIONS_IN_PLAIN_LANGUAGE}}` is POLYBIUS translating the flag set into "drop the role files into `<dir>`; append a reference to `<file>`; nothing else." Be specific. Don't say "set up the environment."

---

## Prompt 6 — write `HUMAN_paste-orchestrator-instruction.md`

After interview, before handing the PRINCIPAL the paste-instruction, POLYBIUS writes the filled template to disk. This is the durable substrate the PRINCIPAL re-pastes from after `/compact` or `/clear` (the **durable-substrate-with-short-prompts** discipline, spec §8).

**Action:** write a new file `HUMAN_paste-orchestrator-instruction.md` at the project root containing the filled paste-instruction.

**Reversibility:** trivial — delete the file. The file is plain text; not load-bearing for any other system.

**Wording:**

> I'm going to write the paste-instruction to `HUMAN_paste-orchestrator-instruction.md` at the project root. That way you can re-paste it from disk if MAJOR_PLINY's session compacts or clears, without coming back to me. The file is plain markdown; safe to commit or `.gitignore` as you prefer. OK?

POLYBIUS doesn't typically gate on this prompt — the file is innocuous — but announces it for transparency. The on-disk artifact is load-bearing for the compact-or-clear recovery path documented in `MAJOR_POLYBIUS.md` §6.

---

## Prompt 7 — spawn a sub-project under the parent project

Stakes: medium. Creates a new directory inside the parent's working tree and adds 12 new files (`MAJOR_POLYBIUS_<slug>.md`, `MAJOR_PLINY_<slug>.md`, 10 `CAPTAIN_*_<slug>.md`) under `<parent>/<slug>/.claude/`. Those become part of the parent's git history (sub-project shares parent's repo). Use this consent prompt **before** running `install.sh --target subproject` (Prompt 5 covers the install.sh run itself).

**Action:** create `<parent>/<slug>/` if it doesn't exist, then create `<parent>/<slug>/.claude/` and `<parent>/<slug>/.claude/agents/`, and deploy the suffixed substrate files. Does NOT modify the parent's `CLAUDE.md`, NOT modify the parent's `.claude/`, NOT redeploy templates (sub-project reads parent's at `<parent>/.claude/templates/`), NOT run `bw init` (sub-project shares parent's bw repo and prefix).

**Reversibility:** fully reversible — delete the `<parent>/<slug>/` directory. The sub-project leaves no trace in the parent's `.claude/` or `CLAUDE.md`. Beadwork tickets the sub-project files into the parent's bw repo are durable but easy to identify and close as needed.

**Alternative if declined:** stay at parent tier. The work folds into a focused arc within the parent project's existing pipeline. Useful when only one sub-project trip-wire fires (`MAJOR_POLYBIUS.md` §10.1) — the cost of spawning isn't justified.

**Wording:**

> A sub-project is the right shape for this — it gives the work its own directory, its own CAPTAIN roster (suffixed with `_<slug>`), and (when the sub-project's POLYBIUS is invoked) its own chief-of-staff seat for the sub-project's human collaborator. It lives at `<parent>/<slug>/` and shares this project's git repo and beadwork. Concretely: I'd create `<parent>/<slug>/` and 12 files under `<parent>/<slug>/.claude/`. Your `CLAUDE.md` is not touched, this project's `.claude/` is not touched, beadwork is not re-initialized — sub-project shares everything that already exists. Spawn the sub-project, or fold the work into a parent-tier arc instead?

If the PRINCIPAL says "show me first," POLYBIUS dry-runs `install.sh --target subproject --parent-dir <parent> --subproject <slug> --dry-run` and shows the planned file list before asking again.

---

## Prompt 8 — schedule a polling cron for async coordination (Arc 18)

Stakes: low-to-medium. Polling crons consume session lifetime (the cron fires while the REPL is idle, generating API calls), but the actual cost is modest (every-5-min cadence × engagement-duration). The reason to gate on a consent prompt anyway: the PRINCIPAL needs to know what background activity is running in the session, what gets checked at each fire, and how to cancel. Use this prompt **before** any `CronCreate` call for engagement-polling.

**Action:** schedule a recurring cron (`*/5 * * * *` default, or as adjusted) that fires a self-contained prompt at each interval — typically reading bw + git state and surfacing meaningful changes. Session-only by default (`durable: false`) — dies when this session exits. Auto-expires after 7 days for recurring tasks.

**Reversibility:** fully reversible at any time via `CronDelete <job-id>`. POLYBIUS reports the job-id in the same turn the cron is scheduled, so the PRINCIPAL has the cancel handle from the start.

**Alternative if declined:** stay human-pinged. PRINCIPAL says "check beadwork now" when status is wanted; POLYBIUS reads on demand. Higher-overhead for long-running async coordination, but no background activity.

**Wording:**

> I'd like to set up a polling cron for this engagement so I can pick up status from MAJOR_PLINY without you in the relay loop. Specifically: cadence `*/5 * * * *` (every 5 minutes), each fire reads the Arc <N> bw epic + git log, surfaces only meaningful state transitions back to you (epic filed, phase transitions, blockers, hand-back). Routine "no activity" fires don't surface — only the meaningful ones. Session-only (dies when this session exits). Job-id will be returned and you can cancel anytime via `CronDelete <id>`. Expected engagement duration ~<N> hours. Schedule the cron, or stay human-pinged for this engagement?

If the PRINCIPAL responds with a cadence adjustment ("make it every 15 minutes") POLYBIUS adopts the adjusted cadence and re-confirms. If declined entirely, POLYBIUS operates human-pinged for the engagement.

**After the engagement ends** (arc shipped, hand-back complete), POLYBIUS cancels the cron explicitly with `CronDelete <job-id>` rather than letting it run idle for the rest of the session. Surfaces the cancellation back to PRINCIPAL: "cron <id> cancelled; engagement closed."

---

## What requires no prompt

- **Reading existing files.** POLYBIUS reads `pwd`, `ls .claude/`, `git log`, `bw list`, `cat HUMAN_paste-orchestrator-instruction.md` freely. These are recon, not modification.
- **Dry-running `install.sh --dry-run`.** No writes; just shows what would happen.
- **Generating the paste-instruction text in conversation.** Until POLYBIUS writes it to disk (Prompt 6), it's just text in the chat.
- **Choosing a bw prefix that follows convention.** If the project is `agent-character-builder`, the prefix is `acb-` by convention; POLYBIUS picks it without asking. If the project name is ambiguous, surface for direction (not consent).

The rule: if the action is a *write* to a file the PRINCIPAL didn't ask for *and* the file affects the broader system (`CLAUDE.md`, `agents/`, beadwork branch), prompt for consent. If it's recon, dry-run, or a contained scratch artifact, just do it and announce.
