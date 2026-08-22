# Post-STRABO VERA dispatch (substrate-tier / upstream-bound propagation) — instruction module

> Relocated from `MAJOR_PLINY.md` §5.5 (CONDITIONAL — read on a propagation-bound STRABO dispatch).
> Provenance: debloat Arc 48 cut `agents/design/arc-48/design-rev1.md` + epic `bw show stoa--xyb` /
> cut ticket `bw show stoa--xyb.10`. The slim-core residue is the §5.5 stub + routing-map row
> (propagation-STRABO dispatch) + relocation-index row in §4.2.

When a STRABO dispatch produces an artifact intended for substrate-tier or upstream-project propagation (substrate-canon update, GitHub issue against an upstream repo, documented bug claim against an actively-maintained dep), the dispatch loop is **not closed** until a follow-on VERA dispatch verifies the artifact's citations.

The protocol:

1. **Read STRABO's artifact for the propagation flag.** STRABO self-marks `verification_status: needs-vera` per `CAPTAIN_STRABO.md` §6.6 when the brief flagged the research as propagation-intended. If the flag is absent but the brief's destination indicates substrate-tier / upstream-bound, treat as if flagged.
2. **Pick sampling policy.** Per `CAPTAIN_VERA.md` §5.8. The brief's `sampling:` field is YAML-valued: the keyword `full` (string) or a positive integer.
   - **`sampling: full`** for substrate-tier-bound or upstream-project-bound artifacts. Every citation gets verified. Default for substrate-canon and upstream-PR destinations.
   - **`sampling: 3`** (bare integer) for routine in-project propagation where a sample is sufficient. Default `N=3` for in-project research feeding a downstream design; PLINY may set any positive integer per dispatch.
3. **Dispatch VERA on the artifact** with a citation-verification brief naming the artifact path, the sampling policy, the ticket ID, and any quadrant tags STRABO self-applied. VERA returns a verdict per `CAPTAIN_VERA.md` §6 with one probe per (sampled) claim and `quadrant_classification` recorded per probe.
4. **Route per VERA's verdict.**
   - VERA returns `pass` → STRABO's artifact is canonical; propagation proceeds.
   - VERA returns `fail` (any citation falsified) → STRABO's artifact is NOT canonical; surface the falsifying evidence to POLYBIUS for routing; do not propagate.
   - VERA returns `INCOMPLETE` or `UNVERIFIABLE` → operator disposition (per the INCOMPLETE/UNVERIFIABLE routing module — `MAJOR_PLINY.md` §5.6) before propagation. Both verdict shapes surface to POLYBIUS; neither gates merge autonomously.

The discipline is the same redundant-checker property the gauntlet's other pairs enforce: STRABO surfaces; VERA falsifies; PLINY routes. STRABO claims are not load-bearing until VERA verifies them.

Anchor: `stoa--fea` (2026-05-12) — the chain that almost-but-didn't fail propagated a STRABO fabrication through to a draft GitHub issue against jallum/beadwork; only the "stop guessing, look at the code" reflex at the drafting boundary caught it. This protocol replaces the reflex with structural routing. Recover via `bw show stoa--fea`.
