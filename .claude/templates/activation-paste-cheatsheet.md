---
author: Denson Smith
---

# Activation paste cheatsheet

Single-page reference for authoring the activation paste that brings up MAJOR_POLYBIUS in a fresh Claude Code session. Consult this BEFORE writing any activation paste — the asymmetry between MAJOR and CAPTAIN suffixing and between auto-load and paste-trigger modes is a real source of silent activation failures.

## When to use this

When `install.sh` finishes and you (the dispatching POLYBIUS or the human operating from the command line) need to activate the deployed POLYBIUS in a fresh terminal. Match the row in the table below to the `--target` and `--modify-claude-md` flags `install.sh` ran with; use the activation pattern from that row exactly.

`install.sh`'s next-steps output prints the right pattern automatically (per `MAJOR_POLYBIUS.md` §5.5), but this cheatsheet is the canonical reference if you need to recover an activation paste later — after a `/compact`, on a re-run, or when handing the activation off to PRINCIPAL.

## The four mode-pattern pairs

| `--target` | `--modify-claude-md`? | MAJOR filename | CLAUDE.md auto-load? | Activation pattern |
|---|---|---|---|---|
| `user` | yes (default) | `MAJOR_POLYBIUS.md` at `~/.claude/` | yes (global CLAUDE.md ref) | **Say-trigger:** open Claude in any project dir; say `POLYBIUS` or `chief of staff` to activate |
| `project` | yes | `MAJOR_POLYBIUS.md` at `.claude/` | yes (project CLAUDE.md ref) | **Say-trigger:** open Claude in project dir; say `POLYBIUS` or `chief of staff` to activate |
| `project` | no | `MAJOR_POLYBIUS.md` at `.claude/` | no | **Paste:** open Claude in project dir; paste `Read .claude/MAJOR_POLYBIUS.md and assume the role for this project.` |
| `subproject` | n/a (never modifies parent CLAUDE.md) | `MAJOR_POLYBIUS_<slug>.md` at `<parent>/<slug>/.claude/` | no | **Paste:** open Claude in `<parent>/<slug>/`; paste `Read .claude/MAJOR_POLYBIUS_<slug>.md and assume the role for this sub-project.` |

Two patterns total: rows 1-2 are **say-trigger** (CLAUDE.md auto-load is wired; saying `POLYBIUS` or `chief of staff` brings up the role); rows 3-4 are **paste-trigger** (no CLAUDE.md ref; activation IS the literal paste reading the role file by path).

**Do NOT paste the literal word `POLYBIUS` as a multi-line activation.** That conflates the say-trigger with the paste-trigger pattern. The say-trigger is a one-word prompt the human types into the chat after Claude is up; the paste-trigger is a literal `Read <path> and assume the role...` instruction. Mixing them produces an activation that does not load the role file — symptoms in the "Verifying" section below.

## CAPTAIN naming asymmetry

CAPTAINs are ALWAYS suffixed when there is a slug (project or subproject), regardless of how MAJORs are named in the same install. Concrete:

- `--target user` → `CAPTAIN_DAEDALUS.md` (no slug → no suffix).
- `--target project --project-dir <path>` → `CAPTAIN_DAEDALUS_<sanitized-project>.md` (slug → suffix; MAJOR is unsuffixed).
- `--target subproject --subproject <slug>` → `CAPTAIN_DAEDALUS_<slug>.md` (slug → suffix; MAJOR is also suffixed — the only mode where both MAJOR and CAPTAIN carry the slug).

The asymmetry exists because Claude Code's sub-agent registry (`.claude/agents/`) shares a namespace; CAPTAINs always need disambiguation when they live in a project's tree. MAJORs only need disambiguation when they coexist with parent-project MAJORs, which only happens at sub-project tier.

## Verifying activation worked

After pasting (or saying the trigger), a healthy activation looks like:

- The activated session's first response references the right tier explicitly: "I'm MAJOR_POLYBIUS, the CHIEF-OF-STAFF for this `<tier>`" (per `MAJOR_POLYBIUS.md` §9 step 1).
- The session can run `bw prime` from the right directory and get a non-error response naming the project's bw prefix (per §9 step 2).
- The session does NOT attempt to read `~/.claude/MAJOR_POLYBIUS.md` from a project-tier or sub-project-tier paste. Wrong-tier symptom: the activation reads the user-tier role file by path (visible if you watch what files it opens), and `bw prime` errors or hits user-beadwork instead of the project's bw.

If the activation does NOT identify the right tier, or `bw prime` errors with "no bw repo here," the activation paste was wrong — re-check the row in the table above and re-paste with the correct path and wording.

## Recovering an activation paste later

After `install.sh` runs, the next-steps output prints the activation pattern; you may want to record it in a known location for re-use after `/compact` or `/clear`. POLYBIUS keeps the last activation paste at:

- For say-trigger modes (rows 1-2): `<ACTIVATE_DIR>/HUMAN_paste-orchestrator-instruction.md` is for activating MAJOR_PLINY (orchestrator), NOT for activating POLYBIUS itself — POLYBIUS auto-loads via CLAUDE.md, so no on-disk activation paste is needed. If you need to recover the say-trigger, just say `POLYBIUS` or `chief of staff` again in any new session.
- For paste-trigger modes (rows 3-4): re-paste from this cheatsheet — the activation paste is short enough to re-derive from the table above. There is no on-disk POLYBIUS activation paste at project or sub-project tier; it is the literal one-line paste in the row.

For activating MAJOR_PLINY (orchestrator) at any tier, see `substrate/templates/paste-instruction-template.md` — that is a separate template, with its own slot-filling procedure.

## Empirical anchor

The structural failure this cheatsheet addresses surfaced 2026-05-04: a project-mode install (no `--modify-claude-md`) used the suffixed filename in its activation paste. The session activated as the wrong tier, hit the wrong bw store, and PRINCIPAL caught it. The cheatsheet flows the activation through the four-row table so the asymmetry (MAJOR suffixed only at sub-project; auto-load only when CLAUDE.md is modified) is impossible to forget under pressure.
