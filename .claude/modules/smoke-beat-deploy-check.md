# Smoke-beat discipline (install.sh deploy-plan check) — instruction module

> Relocated from `MAJOR_PLINY.md` §5.7 (CONDITIONAL — read at Phase C smoke-beat time for a
> substrate-touching arc). Provenance: debloat Arc 48 cut `agents/design/arc-48/design-rev1.md` +
> epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.10`. The slim-core residue is the §5.7
> stub + routing-map row (smoke-beat for substrate arc) + relocation-index row in §4.2.

When you run Phase C smoke beats for an arc that touched substrate, your beat list MUST include the install.sh deploy-plan check from `operating-disciplines.md` §8.4 for each new substrate file the arc added. The discipline applies to:

- Files added under `substrate/templates/` — covered by `TEMPLATE_NAMES` in install.sh.
- Files added under `substrate/skills/` — covered by `SKILL_NAMES` in install.sh.
- New CAPTAIN role files added under `substrate/` — covered by `CAPTAIN_NAMES` in install.sh.
- Any future install.sh-managed file class.

**The discipline is a Phase C smoke beat, not a Phase 2 build step.** ADA can add the file source in the build; install.sh's deploy-list update is a separate concern that the smoke beat surfaces if missed. If ADA naturally updates install.sh during the build (because the diff is obvious), the smoke beat still runs — it confirms the wiring is correct, even when the wiring was authored intentionally.

Cross-ref: `operating-disciplines.md` §8.4. Anchor: Arc 21 (`stoa--14u`). Recover via `bw show stoa--14u`.
