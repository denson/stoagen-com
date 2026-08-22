# API-docs-examples-don't-generalize-to-differently-shaped-elements — instruction module

> Relocated from `CAPTAIN_DAEDALUS.md` §6.11 (CONDITIONAL — read when a design rests on a third-party
> API whose docs supply an example using ONE element type but the design wires against a DIFFERENT
> element type). Provenance: composition-layer spec `bw show stoa--xyb`; debloat Arc 6 (Arc 49) cut
> `agents/design/arc-49/design-rev1.md` / cut ticket `bw show stoa--xyb.11`. The two Pass-10 anchors
> (attrX/attrY pick; motion layoutId not on SVG) are in-prose stellation narrative (no standalone bw
> ticket) — moved VERBATIM into this module (it IS the surviving copy). The slim-core residue is the
> §6.11 REAL-HEADING-LINE stub (substrate-cited ×2 from ADA §183/§186) + the
> `<!-- MODULE-INLINE:api-docs-dont-generalize -->` marker + relocation-index row in
> `CAPTAIN_DAEDALUS.md` §6.0.

### 6.11 API-docs-examples-don't-generalize-to-differently-shaped-elements

When a design rests on a third-party API and the API docs supply an
example using ONE element type, the docs do not guarantee the API
generalizes to a DIFFERENT element type. Element-type attribute surfaces
vary by spec; an API that animates `attrX` / `attrY` on an SVG `<rect>`
may not animate the same attributes on `<g>` because `<g>` lacks
native `x` / `y` per the SVG2 spec.

**The discipline (at design-time):**

1. **Identify the element-type the design targets.** Not the element-type
   the API docs' example uses; the element-type the design actually wires
   against.
2. **Ground-check the chosen API against the target element-type's
   attribute surface.** Cite the element-spec (MDN, WHATWG, SVG2, …) and
   the API doc together; confirm the API's verbs are valid against the
   target element's nouns. A generic doc example is not a generalization
   guarantee.
3. **When the API verb does NOT apply at the target element, narrow the
   API choice OR re-shape the design.** Do not ship a probe that asserts
   behavior the underlying surface cannot supply.

**Empirical anchor.** Two anchors at Pass 10:
- **Arc 4 rev2 — attrX / attrY pick.** DAEDALUS-rev2 picked attrX / attrY
  based on motion docs SVG-component generic example; ARGUS-rev2 caught
  that SVG `<g>` has no native `x` / `y` per MDN + SVG2 spec; the API
  verb (motion's attr-animate) cannot animate what doesn't exist at the
  target element type. DAEDALUS-rev3 grounded against three sources
  (motion docs + MDN g + MDN/SVG2 transform) and pivoted to transform-
  based animation.
- **Arc 5 §6.4 — motion layoutId not supported on SVG.** Same defect-
  class at a different API verb (`layoutId` for FLIP-style transitions);
  motion's docs example used HTML elements; the API does not support
  SVG element layout transitions. Design narrowed scope rather than
  assert behavior the surface can't supply.

**Cross-refs:**
<!-- cite: CAPTAIN_DAEDALUS.md §6.9 — probe-grounding parent canon (clause 4 names ground-check against shipped tool surface; this section extends the principle to third-party API surfaces) -->
<!-- cite: CAPTAIN_DAEDALUS.md §6.4 — WebSearch / WebFetch for live constraints (operational mechanism for the ground-check this discipline names) -->
<!-- cite: CAPTAIN_ADA.md §5.3 — web-search before guessing on third-party APIs (build-time sibling) -->
<!-- cite: CAPTAIN_ADA.md §5.9 — scope-reduce motion APIs that overlap SVG-attribute-driven props (build-time sibling discipline that this design-time discipline catches before the build) -->
- `CAPTAIN_DAEDALUS.md` §6.9 (probe-grounding parent canon — clause 4 names "ground-check against shipped tool surface"; this section extends the principle to third-party API surfaces)
- `CAPTAIN_DAEDALUS.md` §6.4 (WebSearch / WebFetch for live constraints — the operational mechanism for the ground-check this discipline names)
- `CAPTAIN_ADA.md` §5.3 (web-search before guessing on third-party APIs — the build-time sibling)
- `CAPTAIN_ADA.md` §5.9 (scope-reduce motion APIs that overlap SVG-attribute-driven props — build-time sibling discipline that this design-time discipline catches *before* the build)
