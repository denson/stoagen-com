# Substrate-update check (daily cadence) — instruction module

> Relocated from `MAJOR_POLYBIUS.md` §14 (CONDITIONAL — loaded at dispatch when a substrate-drift
> check is relevant). Provenance: composition-layer spec `bw show stoa--xyb.4`; debloat Arc 2 cut
> `agents/design/arc-45/design-rev2.md` + epic `bw show stoa--xyb`. The slim-core residue is the
> §14 stub + routing-map row in `MAJOR_POLYBIUS.md` §3.5.

The substrate (this role file, MAJOR_PLINY.md, operating-disciplines.md, the 10 CAPTAIN envelopes, templates, skills) is canonical at the-stoa repo and deployed via `install.sh` into consumer workspaces. After deploy, a workspace silently drifts as the-stoa evolves — there is no built-in notification.

On activation, read `<workspace>/.claude/.substrate-last-check`. If `last_check_timestamp` is more than 24h old AND `last_check_against_sha` does not match the current the-stoa HEAD, surface a non-modal "want me to check substrate for drift?" prompt. The PRINCIPAL can answer at any time — there's no nag and no blocking. Drift output is informational; the working team keeps running unchanged regardless.

The tool that performs the check is `skills/check-substrate-updates/check.sh`; run it directly (`substrate/skills/check-substrate-updates/check.sh --workspace <path>`) — as of Arc 63 it is a substrate-shipped operator tool, not a Skill-tool skill (its SKILL.md was removed), and the SessionStart substrate-check hook fires it at session start. When drift is found and the PRINCIPAL wants to apply it, `apply.sh --workspace <path> --all-differing` walks per-file consent + diff display, with git pre-commit safety net and a running-agent warning when role files are touched. `revert.sh` undoes the most recent apply.

If `.substrate-last-check` is missing, treat as never-checked: when an opportunity surfaces (low-cost moment, PRINCIPAL not deep in another concern), offer to run the check. Don't gate the activation on it; the file gets populated on the first run. v0 scope is project-tier and subproject-tier only — user-tier check is documented as future work in `agents/design/stoa--lyh/design.md` §10.2.

Cross-reference: the universal-team framing of substrate freshness lives in `operating-disciplines.md` (durable-substrate / cross-session continuity section).
