# PRINCIPAL-gate design discipline — instruction module

> Relocated from `CAPTAIN_DAEDALUS.md` §6.7 (CONDITIONAL — read when designing a directive or spec
> that contains a PRINCIPAL-gating clause). Fires only on directive/spec designs with gating clauses;
> a typical feature/refactor/debloat design reads neither this nor the credential module. Provenance:
> composition-layer spec `bw show stoa--xyb`; debloat Arc 6 (Arc 49) cut
> `agents/design/arc-49/design-rev1.md` / cut ticket `bw show stoa--xyb.11`. The Arc 26 empirical
> (`stoa--dxw`, `stoa--501`) travels INSIDE this module (the section IS the surviving copy). The
> slim-core residue is the §6.7 REAL-HEADING-LINE stub (substrate-cited ×5 from ADA/VERA/op-disc) +
> the `<!-- MODULE-INLINE:principal-gate-design -->` marker + relocation-index row in
> `CAPTAIN_DAEDALUS.md` §6.0. Anchor: stoa--dxw, stoa--501.

### 6.7 PRINCIPAL-gate discipline (surface gating at design ratification time)

When designing a directive or spec that contains a PRINCIPAL-gating clause (per `operating-disciplines.md` §25.3: any clause where PRINCIPAL input is structurally required for the workflow to proceed correctly — examples: `PRINCIPAL-discretion per design §X`, `PRINCIPAL ratifies before Phase 2`, `blocked-on-PRINCIPAL`), the discipline is:

1. **Recognize gating clauses at design time** — not at post-build cleanup. Read the brief for clauses that match §25.3's gate-shape; flag them in the design's §1 restatement.
2. **Surface the gating to PRINCIPAL at design ratification time** — explicitly, in the design artifact, in a section ARGUS can audit and the operator can see before ADA dispatches. The design's §4 self-assessed weak points or §5 out-of-scope are natural homes; the format is "this design contains PRINCIPAL-gating clause X at Y; PRINCIPAL-ratification-time evidence: <evidence>." If PRINCIPAL has not yet ratified at design time, the design surfaces as `status: refused` with `gap_or_blocker: PRINCIPAL-gate clause X requires ratification before this design can progress to ARGUS.`
3. **Do NOT use post-hoc-disposition framing.** A clause like "PRINCIPAL-discretion per design §X" without PRINCIPAL-ratification-time evidence is a defect against §25 — surface back as substance-disagreement, not as a design that ARGUS can audit cleanly.

If the design contains a probe spec that would mutate a real (operator-owned) workspace, the probe-design sub-case at `operating-disciplines.md` §25.5 applies: name the throwaway-clone pattern (`git clone --no-local`) in the probe spec rather than relying on a design-time blanket "PRINCIPAL-discretion" clause. The catch-point for this sub-case is DAEDALUS at design time — that is the explicit framing in retro §9.

The Arc 26 empirical anchor (`stoa--dxw`): VERA Probe 8's design carried `PRINCIPAL-discretion per design §6` with no ratification evidence; the quality chain read it as a post-hoc-disposition marker; the probe shipped, mutated sector-4 unauthorized, and the post-hoc cleanup was `stoa--501`. Per §25.4, the catch-point was DAEDALUS at design time; this discipline closes the gap.

**Cross-refs:** `operating-disciplines.md` §25 (universal canon) + §25.5 (probe-design sub-case — relevant when DAEDALUS designs a probe spec for VERA) + Arc 26 anchor (`stoa--dxw`).
