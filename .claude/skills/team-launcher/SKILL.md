---
name: team-launcher
description: |
  Stand up a multi-seat Stoa agent team (POLYBIUS + PLINY — the STANDARD composition) in terminal sessions on Windows, ready for activation — in ONE command instead of hand-opening terminals. Consumer-generic: the bundled `launch-team.ps1` derives the project + slug from where it is deployed and defaults to SAY-TRIGGER activation (pre-seeds the bare "polybius"/"pliny" so the workspace CLAUDE.md auto-loads the role). Three layouts: side-by-side PANES (default), TABS, or separate WINDOWS, via Windows Terminal (`wt`) with a windows fallback. Variable composition (`-Composition`: add CHIRON for custom agents / HAMILTON for custom workflows) + a chain-of-command preamble injected on arc/paste launches + gauntlet-by-default (`-GauntletWaiver` to opt out). Carries the VERIFIED `wt` + `claude` CLI mechanics (Microsoft WT docs + smoke test).

  Invoke when asked to "stand up / spin up / launch the team", "open POLYBIUS and PLINY", "start the agent sessions", "launch in panes/tabs/windows", or when a workspace needs its team brought online. Windows + Claude Code Desktop (builder tier).
author: Denson Smith
---

# team-launcher — stand up an agent team in terminals (Windows)

> **Verified mechanics, not theory.** The `wt` and `claude` flags below were confirmed against Microsoft's Windows Terminal command-line docs + a live smoke test (2026-06-04); the consumer-generic launcher was re-smoke-tested 2026-06-06 (parse + DryRun across panes / auto-derive / windows-fallback) under `stoa--h8w`. Sibling of `interactive-html-preview` (both hold verified builder-tier mechanics).

## TERMINALS ARE THE EXCEPTION, NOT THE DEFAULT (PRINCIPAL directive 2026-07-10 — "stop the terminal parade")

Before invoking this launcher AT ALL: for small/medium arcs the lane fork runs the floor IN-SESSION (FM/PLINY-equivalent supervision + the CAPTAIN gauntlet as in-session subagents, full gauntlet discipline + bw receipts, ZERO terminals). Terminal seats are reserved for genuinely long-running parallel floors, and every terminal launch REQUIRES a recorded WHY in a launch note on the arc ticket.

When terminals ARE in play: (a) a stalled seat is remedied nudge-first, then `claude --resume <stalled-sid>` (same lineage — no new window), and a fresh forge is LAST RESORT with the reason recorded; HARD CAP one respawn per seat per arc — a second stall is an arc-level problem, not a seat problem. (b) SUPERSESSION INCLUDES DISPOSAL: whoever flips a seat dead disposes of its window in the same step (agent-side where safely identifiable, else one batched close-list for PRINCIPAL) — dead windows never accumulate; a lingering window is a zombie-seat surface (stale monitors re-fire; observed live 2026-07-10).

## The tool: `launch-team.ps1` (ships in this skill dir)
The script lives **beside this SKILL.md** and deploys with the skill into every workspace's `.claude/skills/team-launcher/`. One command brings up the whole team — each session named, in the project dir, and activated.

```powershell
# it derives the project + slug from its own deployed location:
.claude/skills/team-launcher/launch-team.ps1                 # PANES (default), say-trigger
.claude/skills/team-launcher/launch-team.ps1 -Layout Tabs    # one tab per seat
.claude/skills/team-launcher/launch-team.ps1 -Layout Windows # one OS window per seat (no wt needed)
.claude/skills/team-launcher/launch-team.ps1 -DryRun         # print the command + the record step, run neither
.claude/skills/team-launcher/launch-team.ps1 -RemoteControl  # add --remote-control to each launched session
# explicit project / slug, or a paste-trigger team:
.claude/skills/team-launcher/launch-team.ps1 -ProjectDir C:\path\to\proj -Slug proj
.claude/skills/team-launcher/launch-team.ps1 -Activation paste -Layout Windows -AutoPaste
```

**Project + slug auto-derive:** with no `-ProjectDir`, the script walks up from its own location to the workspace root (the dir containing `.claude/`); the slug defaults to that dir's leaf. So in `origindex` the seats are `POLYBIUS_origindex` / `PLINY_origindex`, floor-manager first. POLYBIUS + PLINY is the *standard* composition, not a fixed default — see "Launcher-correctness" below.

## Launcher-correctness (Arc 68 / stoa--pk4): chain, gauntlet, composition

The launcher structurally lays down the by-the-book forge (canon: `operating-disciplines.md` §37):

- **Chain-of-command at launch.** A fixed chain preamble (PRINCIPAL → POLYBIUS → PLINY → CAPTAINs; PLINY surfaces to POLYBIUS not the PRINCIPAL; seats are not co-equal panes) is injected on the **arc + paste** activation paths (which already force `-Layout Windows`). **Option B — the SAY path stays a bare word** (`polybius`/`pliny`): no preamble, no `-Layout Windows` force, so the **Panes default is preserved** for standard say launches. The bare-word say path establishes the chain via the role-file canon it loads (`MAJOR_POLYBIUS.md` / `MAJOR_PLINY.md` carry it substantively + §37).
- **Gauntlet-by-default.** The full gauntlet is the default; `-GauntletWaiver "<reason>"` opts out (records `gauntlet=waived:<reason>`, a POLYBIUS/PRINCIPAL action — a seat cannot self-grant solo). The Stop self-check hook's clause (E) is the independent detector (detection + recorded-deviation, not prevention).
- **Variable composition.** `-Composition standard|custom-agent|custom-workflow|custom-agent+workflow` — `custom-agent` adds **MAJOR_CHIRON** (team-architect), `custom-workflow` adds **MAJOR_HAMILTON** (workflow-architect); both are launcher-spun design-time terminal seats answering to POLYBIUS, parallel to PLINY. Architect seats carry full prompts → they force `-Layout Windows` (the prompt class only, not the say path). The composition / gauntlet / chain_role are recorded per seat to the ONE registry `stoa--reg`.

**Activation modes:**
- **`say` (default)** — pre-seeds the bare word (`polybius` / `pliny`) as claude's positional prompt; the workspace `CLAUDE.md` say-trigger auto-loads the role. The common case for deployed workspaces. (If a pane doesn't fire, it is still named + ready — type the word.)
- **`paste`** — opens sessions ready for a manual activation paste; with `-Layout Windows -AutoPaste`, feeds each seat's `Paste` file as the first prompt (the-stoa-style paste-trigger).

## The verified `wt` mechanics (the part that trips you up)
- **Side-by-side panes = `split-pane -V` (`--vertical`).** `-H` stacks top/bottom. First seat is `new-tab`; each next seat is `split-pane -V` (panes) or `new-tab` (tabs).
- **`;` delimits `wt` commands** — passed as its own array token so PowerShell does not eat it as a statement separator.
- **`--title <name>` + `--startingDirectory <dir>` per pane/tab.**
- **Launch NON-blocking with `Start-Process wt …`** — a bare `wt` / `& wt` makes PowerShell wait for the window to close (WT is a Store app).
- Use the **full `claude.exe` path** (`(Get-Command claude).Source`) so PATH resolution inside the pane never bites.

## The verified `claude` CLI flags
- `--dangerously-skip-permissions` — the team runs unattended.
- `--model <name>` — `opus` alias works; full id `claude-opus-4-8` if an alias is rejected.
- `-n/--name <name>` — sets the session display name + terminal title (how each pane is labeled by seat).
- `--session-id <uuid>` — pins the seat's session-id at launch (the launcher mints one GUID per seat; see "Session-identity" below).
- `--remote-control` — added to each session when `-RemoteControl` is passed (optional).
- positional `[prompt]` — pre-seeds the interactive session (this is how say-trigger feeds `polybius`/`pliny`). Do **not** use `-p/--print` (non-interactive).
- In-session `/rename "<name>"` renames a live session.

## Session-identity: mint + name + record (stoa--p7c, Arc 67 — the HYBRID DC1 launcher half)
Each terminal seat the launcher brings up gets:
1. **A minted per-seat UUID** (`[guid]::NewGuid()`), pinned via `claude --session-id <uuid>`. The launcher KNOWS the id deterministically before the seat activates (it minted it), so there is no activation-ordering window where a launched seat is un-recorded.
2. **A space-free human-friendly name** (`--name`, e.g. `POLYBIUS_the-stoa`).
3. **A durable registry row.** After the launch loop (non-dry-run only), the launcher calls `record-seat.ps1` serially, once per seat, writing `{seat, name, session_id, project, machine, role, tier, launched_at, status:alive}` to the bw seat registry (`stoa--reg`).

**Desktop self-record fallback (HYBRID DC1).** Desktop-UI sessions are created OUTSIDE this launcher, so it can neither mint nor pin their id. Those seats SELF-RECORD on activation: they read their own session-id from the `$CLAUDE_CODE_SESSION_ID` environment variable (the `whoami` skill returns it) and call this same `record-seat.ps1` with that sid. `$CLAUDE_CODE_SESSION_ID` is a terminal seat's OWN sid (and a sub-agent's CALLER sid); `whoami` FAILS LOUD if it is empty rather than recording a blank identity. This is the env-var-powered path that covers exactly the case the launcher pin cannot reach.

**The registry read recipe** ("which seat owns which project / is it alive"):
```powershell
git show beadwork:attachments/stoa--reg/seat-registry.jsonl   # the JSONL manifest, one row per seat
# filter to alive seats on a project (PowerShell):
git show beadwork:attachments/stoa--reg/seat-registry.jsonl |
  ForEach-Object { $_ | ConvertFrom-Json } |
  Where-Object { $_.project -eq 'the-stoa' -and $_.status -eq 'alive' }
# or with jq:
git show beadwork:attachments/stoa--reg/seat-registry.jsonl | jq -c 'select(.project=="the-stoa" and .status=="alive")'
```
The full registry shape, schema, and the honest-claim boundary live in the `stoa--reg` ticket body; the signing convention these rows feed is `operating-disciplines.md` §28.9.

`record-seat.ps1` (ships beside this SKILL.md) is the standalone read-modify-rewrite-attach helper: it reads the current manifest via `git show`, drops any existing row matching `(seat, machine)` (idempotent refresh), appends the new row, and re-attaches via `bw attach stoa--reg <temp> --name seat-registry.jsonl`. It is callable without spawning a live agent — the launcher calls it (terminal path), a desktop seat calls it (self-record), and verification calls it directly with a synthetic row.

## The workflow (say-trigger — the default)
1. **Launch:** `.claude/skills/team-launcher/launch-team.ps1`. Panes come up named, in the project dir, each pre-seeded its bare word; the workspace `CLAUDE.md` auto-loads each role (floor-manager = left pane / first tab).
2. **Confirm** the floor-manager's bw presence-announce before leaning on the worker.

For paste-trigger workspaces, use `-Activation paste` and paste each seat's file (floor-manager first), or `-Layout Windows -AutoPaste`.

## Gotchas (verified)
- **Don't reuse seat names of a team already running** — the same `--name` twice is a seat-identity collision. For throwaway runs use a distinct `-Slug` + a scratch `-ProjectDir`.
- **`bw comment` text is POSITIONAL, not `-m`** (`bw comment <id> "text"`). The `-m` habit silently records the body as `-m`. (Cross-ref: substrate §12.)
- **`-AutoPaste` is Windows-layout only** (a multi-line paste through a wt pane is brittle); a single bare word (say-trigger) is fine in panes.
- **Paths/names with spaces** are not quoted — keep them space-free.
- **Panes/Tabs need Windows Terminal (`wt`)** — absent → falls back to separate windows.

## Cross-references
- **Recovery (radio-check, op-disc §38):** a seat presumed-dead by an on-demand radio-check is REPLACED, not resurrected — relaunch here mints a fresh seat + an idempotent `(seat,machine)` registry row that overwrites the dead row. (The dead session's `sid` is gone; liveness is the ping, never a stored field.)
- `launch-team.ps1` (this dir) — the tool. `-DryRun` previews the launch + record steps without running either.
- `record-seat.ps1` (this dir) — the standalone registry write helper (mint+name+record / desktop self-record).
- `whoami` skill — returns the seat's session-id from `$CLAUDE_CODE_SESSION_ID` (FAIL-LOUD if empty); the desktop self-record path uses it.
- `operating-disciplines.md` §28.9 — the session-identity sign-everywhere convention these registry rows feed.
- `MAJOR_POLYBIUS.md` / `MAJOR_PLINY.md` — the seat roles; the activation order (floor-manager before worker) is theirs.
- The workspace `CLAUDE.md` — its say-trigger line ("when the user invokes POLYBIUS, read `.claude/MAJOR_POLYBIUS.md`") is what say-mode relies on.
- `interactive-html-preview` skill — sibling verified-mechanics skill.
- `stoa--h8w` — the generalization that made this skill consumer-deployable; `stoa--p7c` — the seat session-identity scheme landed here (mint + name + record to `stoa--reg`); see §28.9 + the `stoa--reg` registry ticket.
