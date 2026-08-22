---
name: gauntlet-setup
description: |
  Stand up a Stoa-substrate multi-tier gauntlet arc by DRIVING the launch script (team-launcher/launch-team.ps1) — user-tier POLYBIUS authors two engagement briefs (floor-manager POLYBIUS_<project> + PLINY_<project>), attaches them to the arc ticket on the beadwork branch, then LAUNCHES the two sessions with the script (floor-manager first, confirm, then PLINY). Use when PRINCIPAL requests "set up a gauntlet" / "spawn the gauntlet" / "dispatch the arc" / "we need a gauntlet for <arc>" / any phrasing that maps to "stand up the substrate seats for a gauntlet-orchestrated arc." Enforces a mandatory checklist that prevents the recurring failure modes: shipping one brief instead of two, forgetting role-assumption, omitting a polling discipline, wrong chain-of-command — AND the failure of hand-rolling the launch instead of using the script.
---

# Gauntlet setup — multi-tier substrate arc activation (via the launch script)

## Purpose

When PRINCIPAL requests a gauntlet-orchestrated arc on a Stoa-substrate project, **user-tier POLYBIUS authors TWO engagement briefs** (one for the project-tier floor-manager POLYBIUS_<project>, one for PLINY_<project>), attaches them to the arc ticket on the `beadwork` branch, and **LAUNCHES the two sessions by driving `team-launcher/launch-team.ps1`** — then restarts its own bw Monitor for the close-gate watch.

This is NOT a one-brief pattern, and user-tier POLYBIUS does NOT activate the gauntlet directly. The substrate-canonical chain is:

```
PRINCIPAL
    ↓
USER-TIER POLYBIUS (chief-of-staff — multi-project; close-gate + merge authority)
    ↓
POLYBIUS_<project> (floor-manager — project-tier; independent verification + relay)
    ↓
PLINY_<project> (gauntlet orchestrator; dispatches CAPTAINs sequentially)
    ↓
CAPTAINs (DAEDALUS → ARGUS → ADA → VERA → CATO → ZENO/NOMOS)
```

The floor-manager exists to (a) preserve user-tier context (user-tier doesn't get pulled into every tactical interaction — it loses the big picture if it supervises the build directly) and (b) provide an independent verification layer (someone other than PLINY checks PLINY's CAPTAIN outputs before they reach user-tier).

## The launch method IS the script — NEVER hand-paste (HARD RULE)

**The seats are spawned by `team-launcher/launch-team.ps1`. That is the only method.** There is no "open a fresh session and paste this line" step — user-tier POLYBIUS DRIVES the script (it pre-seeds each session with its spawn-instruction, in the project dir, named by seat). Hand-opening sessions and pasting by hand is the anti-pattern this skill exists to kill.

**If ANYTHING about the launch goes wrong** — a PowerShell quoting quirk, a `wt` arg that won't pass, a path that resolves wrong, a flag claude rejects, a brief that won't fetch — **do NOT work around it in the moment.** Fix the SKILL and/or `team-launcher/launch-team.ps1` so the failure cannot recur, then re-launch from a clean state. The bar is **"it just works from the script"** — not "I got it running by hand this once."

**Report every workaround/deviation AS IT HAPPENS, no matter how minor** (even a one-character quoting fix, even choosing one layout over another because the other is broken) — surface it to PRINCIPAL immediately AND fold the fix back into the skill/script in the same breath. A silent "I just tweaked it and moved on" is exactly the failure this rule kills: the next agent inherits the same break. If PowerShell / `wt` / the claude CLI did not behave the way the script assumed, that is a **SCRIPT BUG** — capture the cause + corrected form in `launch-team.ps1`'s gotchas section.

*(Manual hand-paste was removed 2026-06-17 per PRINCIPAL — "the manual method removed, the script method in all tiers." It had survived as the surface-message template and kept luring agents into hand-rolling. Prior anchor: 2026-06-15, a hand-rolled `wt` launch silently mangled the activation prompt and produced no running agent.)*

## Mandatory pre-write checklist

Before authoring either brief, user-tier POLYBIUS confirms:

- [ ] **Arc identifier + coordination ticket exist** (e.g., the arc epic `stoa--p41.1`); the in-scope work is clear from a directive or bw ticket.
- [ ] **Project name is known** (e.g., `the-stoa`) so seat names form correctly (`POLYBIUS_<project>`, `PLINY_<project>`).
- [ ] **Project uses the Stoa substrate** — `.claude/MAJOR_POLYBIUS.md` and `.claude/MAJOR_PLINY.md` exist in the project (the script-launched sessions Read these). If not, this skill doesn't apply; surface to PRINCIPAL.
- [ ] **PRINCIPAL has explicitly asked for the gauntlet** (vs pair-programming).
- [ ] **The scope warrants the substrate overhead** (canon/tooling/auth/security/public surface/novel architecture). Tiny refactors don't need a gauntlet.
- [ ] **`launch-team.ps1` is present** at `.claude/skills/team-launcher/launch-team.ps1` (or the substrate source) and **a `-DryRun` of the intended launch is clean** before any real spawn.

## Mandatory content checklist for each brief

> **Belt-and-suspenders note (Arc 68 / stoa--pk4).** The chain-of-command + gauntlet-by-default are now **launcher-injected** (the L1 chain preamble on the arc/paste paths) **+ canon** (`operating-disciplines.md` §37, carried substantively in `MAJOR_POLYBIUS.md` / `MAJOR_PLINY.md` — the carrier for the bare-word say path under Option B). So the brief items below that restate the chain are a **belt-and-suspenders confirm** of what the launcher already lays down — author them anyway (defense in depth), but they are no longer the SOLE carrier. For a **variable composition** (an arc designing custom agents/workflows), pass `launch-team.ps1 -Composition custom-agent|custom-workflow|custom-agent+workflow` to add MAJOR_CHIRON / MAJOR_HAMILTON (design-time seats answering to POLYBIUS); to opt out of the gauntlet default, pass `-GauntletWaiver "<reason>"`.

The briefs are attached to the arc ticket on beadwork; the script's spawn-instruction fetches them (`git show beadwork:attachments/<arc-id>/<file>`).

### Floor-manager brief (`HUMAN_paste-polybius_<project>-<arc-id>-instruction.md`)

- [ ] Opens with: `Read .claude/MAJOR_POLYBIUS.md and assume the project-tier role for <project> (the "floor-manager" instance, distinct from the user-tier POLYBIUS chief-of-staff). You are POLYBIUS_<project> for the duration of this engagement.`
- [ ] States the engagement: which arc, what gauntlet shape (full DAEDALUS → ARGUS → ADA → VERA → CATO → ZENO/NOMOS), the spec pointer (the arc directive).
- [ ] Documents the three-tier chain explicitly so the seat understands its position.
- [ ] Floor-manager responsibilities: independent verification at each CAPTAIN hand-back; bw coordination (own persistent Monitor); relay between PLINY and user-tier POLYBIUS (with own verification attached); hand-up at arc close.
- [ ] Polling discipline: persistent Monitor on `git rev-parse beadwork` SHA changes, armed at engagement start, torn down at close.
- [ ] Mutual-polling language: "All three substrate seats — you, user-tier POLYBIUS, PLINY — poll each other through bw. Your Monitor is YOUR half of that mutual loop."
- [ ] What it does NOT do: dispatch CAPTAINs, merge, push, apply to deployed instances, modify the arc-build worktree.
- [ ] Close-signal: `CLOSE ME — POLYBIUS_<project> floor-manager engagement complete; arc <arc-id> handed up to user-tier POLYBIUS`.
- [ ] Compaction-recovery footer: re-fetch via `git show beadwork:attachments/<arc-id>/<this-file>`.

### PLINY brief (`HUMAN_paste-pliny-<arc-id>-instruction.md`)

- [ ] Opens with: `Read .claude/MAJOR_PLINY.md and assume the orchestrator role for <project>.`
- [ ] Documents the three-tier chain so PLINY knows it **surfaces to the floor-manager, not user-tier direct**.
- [ ] States arc scope (point at the directive as authoritative; summarize what's in/out + locked design decisions for DAEDALUS). Forward work on an `<arc-id>/build` feature branch.
- [ ] All three polling disciplines: **D-A** (every CAPTAIN echoes significant output to bw on the coordination ticket); **D-B** (read bw between every CAPTAIN dispatch — floor-manager + user-tier + PRINCIPAL); **D-C** (Monitor/sleep at ~2-3 min during surface-and-wait).
- [ ] Hand-back protocol: at CATO/ZENO/NOMOS PASS, post on the coordination ticket addressed to **POLYBIUS_<project> (floor-manager)** — NOT direct to user-tier.
- [ ] What PLINY does NOT do: merge, push, apply to deployed instances, relay direct to user-tier (except scope disputes), surface to PRINCIPAL except emergencies.
- [ ] Close-signal: `CLOSE ME — <arc-id> gauntlet complete; awaiting user-tier POLYBIUS close-gate + merge`.
- [ ] Compaction-recovery footer: re-fetch via `git show beadwork:attachments/<arc-id>/<this-file>`.

### User-tier POLYBIUS (self) commitment

- [ ] Restart own bw Monitor at the moment the sessions are spawned (NOT before — empty channel is wasted polling). Tune it to a **close-gate watch** (fires on a *new* hand-up to user-tier), not fire-on-every-change.
- [ ] Stay at the close-gate / big-picture altitude; let the floor-manager run PLINY's tactical supervision.

## Output + launch procedure

User-tier POLYBIUS does, in order:

1. **Coordination ticket + scope.** The arc coordination ticket must exist; put the full SCOPE on it (or point at the committed arc directive — long dispositions live in bw/the directive, not paste-relay).
2. **Author the two briefs + attach to beadwork** (their tracked home — NOT main):
   ```
   bw attach <arc-id> HUMAN_paste-polybius_<project>-<arc-id>-instruction.md
   bw attach <arc-id> HUMAN_paste-pliny-<arc-id>-instruction.md
   git push origin beadwork
   rm HUMAN_paste-polybius_<project>-<arc-id>-instruction.md HUMAN_paste-pliny-<arc-id>-instruction.md   # loose copies; they now live on beadwork
   ```
   They land at `attachments/<arc-id>/<file>` and read back via `git show beadwork:attachments/<arc-id>/<file>`. (`HANDOFF_*`/`HUMAN_paste-*`/`PLAN_*` are gitignored on main by design — their tracked home is the beadwork branch.)
3. **DryRun the launch**, then **launch via the script — floor-manager FIRST, confirm, then PLINY**:
   ```powershell
   # Each seat is pre-seeded with a spawn-instruction (role file + git show beadwork:<brief> + follow).
   $fm = "Read .claude/MAJOR_POLYBIUS.md. Then get your engagement brief from the beadwork branch: git show beadwork:attachments/<arc-id>/HUMAN_paste-polybius_<project>-<arc-id>-instruction.md and follow it as the project-tier floor-manager for <project> on arc <arc-id>."
   $pl = "Read .claude/MAJOR_PLINY.md. Then get your engagement brief from the beadwork branch: git show beadwork:attachments/<arc-id>/HUMAN_paste-pliny-<arc-id>-instruction.md and follow it as the orchestrator for <project> on arc <arc-id>."

   # DryRun first (verify the command, spawn nothing):
   & .claude/skills/team-launcher/launch-team.ps1 -ProjectDir <proj-dir> -Slug <project> -Layout Windows -Seats @(@{Name="POLYBIUS_<project>"; Say=$fm}) -DryRun

   # STEP 1 — launch the floor-manager ONLY:
   & .claude/skills/team-launcher/launch-team.ps1 -ProjectDir <proj-dir> -Slug <project> -Layout Windows -Seats @(@{Name="POLYBIUS_<project>"; Say=$fm})

   # WAIT for the floor-manager to post its activation + Monitor-armed comment to bw (poll via your Monitor).

   # STEP 2 — only after the floor-manager confirms, launch PLINY:
   & .claude/skills/team-launcher/launch-team.ps1 -ProjectDir <proj-dir> -Slug <project> -Layout Windows -Seats @(@{Name="PLINY_<project>"; Say=$pl})
   ```
   - **Floor-manager FIRST, then confirm, then PLINY** — separate launch calls, not a stagger; the floor-manager must be online + polling before PLINY begins. This ordering is load-bearing.
   - **Layout:** use `-Layout Windows` for now — `launch-team.ps1` panes/tabs append a multi-word prompt unquoted and break (tracked: `stoa--waa`). When that's fixed, prefer panes (side-by-side). Choosing Windows-over-panes IS a reportable deviation until the fix lands.
4. **Restart your own bw Monitor** (close-gate watch) the moment you spawn the sessions.

There is **no manual surface message telling PRINCIPAL to open sessions and paste.** PRINCIPAL doesn't spawn the seats — user-tier POLYBIUS does, via the script. (PRINCIPAL is told only what they need: that the gauntlet is dispatched, and any parallel work they own.)

## The spawn-instruction MUST name the role file AND the beadwork brief

The script pre-seeds each session with a spawn-instruction. It MUST name BOTH — the role file AND the arc-specific brief from the beadwork branch — or the session may fall back to a stale/default activation.

✅ CORRECT (pre-seeded by the script):
```
Read .claude/MAJOR_PLINY.md. Then get your brief: git show beadwork:attachments/<arc-id>/HUMAN_paste-pliny-<arc-id>-instruction.md and follow it as the orchestrator for <project> on arc <arc-id>.
```
❌ WRONG (generic — may load a stale/default brief): `Read .claude/MAJOR_PLINY.md and assume the orchestrator role.`
❌ WRONG (a main-tree path — the brief is gitignored on main; it lives only on beadwork): `... and HUMAN_paste-pliny-<arc-id>-instruction.md ...`

## Failure modes this skill prevents

1. **Hand-pasting instead of driving the script.** The biggest one — and the reason manual-paste was removed. If the script can't launch, FIX the script; never hand-roll.
2. **Ship only one brief and forget the floor-manager** → PLINY surfaces direct to user-tier, dragging it into every tactical call and skipping independent verification.
3. **Forget the role-assumption line** → a session starts cold without `Read .claude/MAJOR_<NAME>.md` and improvises.
4. **Omit a polling discipline** (most often D-C) → a session goes silent during waits.
5. **Wrong launch order** (PLINY before the floor-manager confirms) → PLINY begins before its verifier/relay is online.
6. **Forget the CLOSE ME signal** → PRINCIPAL doesn't know which windows can close.
7. **Forget to restart own Monitor** → user-tier sits silent while the gauntlet runs.
8. **Chain-of-command set up wrong** → PLINY thinks it surfaces direct to user-tier; floor-manager thinks it has CAPTAIN-dispatch authority. **(Arc 68 / stoa--pk4: the launcher now establishes the chain structurally — the L1 chain-of-command preamble is injected on the arc/paste activation paths, and `operating-disciplines.md` §37 + the substantive `MAJOR_POLYBIUS.md` / `MAJOR_PLINY.md` chain paragraphs carry it on the bare-word say path. The brief checklist below is now a BELT-AND-SUSPENDERS confirm of what the launcher already lays down, not the sole carrier.)**
9. **Solo run with one checker (the AR-7 shape)** → a seat runs as its own orchestrator, spawns CAPTAINs with no PLINY, self-certifies with one checker. **(Arc 68: the full gauntlet is now the launcher default; opt-out requires `launch-team.ps1 -GauntletWaiver "<reason>"` — a POLYBIUS/PRINCIPAL action recorded to `stoa--reg`, never a seat's silent solo opt-in. The Stop self-check hook's clause (E) is the independent detector.)**

## When NOT to use this skill

- Pair-programming arcs (user-tier writes code directly with PRINCIPAL watching) — no gauntlet.
- Tiny refactors / doc edits / one-line fixes — substrate overhead exceeds value.
- Projects that don't deploy the Stoa substrate — different coordination model.
- Investigative / research work with no defined scope yet — the gauntlet needs an arc to run against.

## Cross-references

- `team-launcher/launch-team.ps1` — the launch tool this skill drives; `-DryRun` previews without spawning.
- `MAJOR_POLYBIUS.md` / `MAJOR_PLINY.md` (project-deployed) — the roles the launched sessions assume.
- `feedback_long_dispositions_via_bw_not_paste_relay.md` — long dispositions via bw, not paste-relay.
- `feedback_radio_check_pattern_for_polybius_coordination.md` — silent-peer detection (when monitors die).

## Author

Denson Smith. Created 2026-05-26 (after recurring user-tier POLYBIUS gauntlet-setup failures). Rewritten 2026-06-17 to remove the manual hand-paste method entirely and make `launch-team.ps1` the prescribed (only) launch method. Pending: port this skill into the substrate (`substrate/skills/` + `SKILL_NAMES`) so the discipline deploys to all tiers — sequenced after the in-flight Arc 61 (which is concurrently editing `install.sh`), to avoid a collision.
