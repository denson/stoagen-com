# Canonical-code-block-fix discipline (extends §6.2) — instruction module

> Relocated from `CAPTAIN_DAEDALUS.md` §6.2.1' (CONDITIONAL — read when a §6.2 self-catch names a
> defect in a CODE design). Fires only when self-catching a defect during the §6.2 weak-points pass
> on a design that contains canonical code blocks. The always-on §6.2 self-assessed-weak-points gate
> STAYS INLINE in the slim core; this module is the fix-location extension read at point of need.
> Provenance: composition-layer spec `bw show stoa--xyb`; debloat Arc 6 (Arc 49) cut
> `agents/design/arc-49/design-rev1.md` / cut ticket `bw show stoa--xyb.11`. The slim-core residue is
> the §6.2.1' stub + the `<!-- MODULE-INLINE:canonical-code-block-fix -->` marker + relocation-index
> row in `CAPTAIN_DAEDALUS.md` §6.0. The 4-anchor empirical block below is in-prose stellation-Pass-10
> narrative (no standalone bw ticket) — moved VERBATIM into this module (the module IS the surviving copy).

### 6.2.1' Canonical-code-block-fix discipline (extends 6.2)

§6.2 names self-assessed weak points as a post-work gate: surface brittle
assumptions before returning. The discipline below extends that to the
location of the fix when §6.2 self-catch names a defect.

When self-catching a defect during §6.2 pass, the fix MUST land at the
§2.X canonical code-block that ADA reads as authoritative — not only at a
§11 step-list reference or a §6 weak-point flag. ADA reads code blocks
first; a fix-narrative in §11 or a flag in §6 is read second, after the
canonical block has already shipped to the build. The empirical record is
that fix-narratives without canonical-block edits ship a buggy canonical
block.

**The discipline (at §6.2 pass time):**

1. **Identify the canonical site.** The canonical site is the code block
   in §2 (or wherever the design names "this is what ADA builds") that
   defines the contract ADA reads first. Not the verification probe
   (that's §4); not the weak-point flag (that's §6).
2. **Edit the canonical site.** Apply the fix in the same draft, at the
   canonical code block, before returning the verdict. A §6 flag without
   a canonical edit is incomplete.
3. **The §6 weak-point flag remains too** — but it documents WHY the fix
   was needed, not as a substitute for the fix.

**Empirical anchor.** Four anchors:
- **Arc 3 r1 (originating)** — sortAxis charCodeAt(0) bias: §6.2 self-catch
  declared "fix applied at design-time" but §2.4 canonical code still
  shipped the buggy form. ARGUS caught by reading §2.4 first per the
  canonical-authority order.
- **Arc 3 rev2 o1** — Effect-B prose at design.md:313 declared "fires when
  sortKey or sortMaps change, but NOT on filter"; code DOES fire on
  filter clicks because sortMaps useMemo deps include tickets. ARGUS-rev2
  self-applied at audit time.
- **Arc 3 VERA Probe L FAIL** — design rev2 pivoted from
  useConstellationLayout.test.ts → computeFinalPositions.test.ts per r3/r7
  but Probe L still enumerated the hook-test file. ADA shipped reality per
  §5.2 ground-check.
- **Arc 4 WP13** — DAEDALUS-rev2 picked attrX/attrY based on motion docs
  SVG-component example; ARGUS-rev2 caught the discrepancy; design pivoted
  at rev3 but original §2 canonical block needed re-edit, not just a §6
  flag.

**Cross-refs:**
<!-- cite: CAPTAIN_DAEDALUS.md §6.2 — parent canon (self-assessed weak points; this section extends to the fix-location when self-catch names a defect) -->
<!-- cite: CAPTAIN_DAEDALUS.md §6.9.3'' — live-RT at canonical-block authoring time (same principle: authority lies at the canonical block, not at the narrative reference) -->
<!-- cite: CAPTAIN_ADA.md §5.2 — stay inside design's scope (the ground-check sibling at build-time) -->
- `CAPTAIN_DAEDALUS.md` §6.2 (parent canon — self-assessed weak points)
- `CAPTAIN_DAEDALUS.md` §6.9.3'' (live-RT at canonical-block authoring time — same principle: authority lies at the canonical block, not at the narrative reference)
- `CAPTAIN_ADA.md` §5.2 (stay inside design's scope — the ground-check sibling at build-time)
