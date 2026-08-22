# Qualitative-acceptance-anchor surface (SSoT-with-WHY pattern) — instruction module

> Relocated from `CAPTAIN_DAEDALUS.md` §6.10 (CONDITIONAL — read when a design ships a
> qualitative-acceptance body: motion vocabulary, color palette, error-message tone, fallback-chain
> ordering, operating-mode triggers). Provenance: composition-layer spec `bw show stoa--xyb`; debloat
> Arc 6 (Arc 49) cut `agents/design/arc-49/design-rev1.md` / cut ticket `bw show stoa--xyb.11`. The two
> worked examples (motion-vocab SSoT; three-surface reduced-motion architecture) are in-prose
> stellation-Pass-10 narrative (no standalone bw ticket) — moved VERBATIM into this module (it IS the
> surviving copy). The slim-core residue is the §6.10 stub + the `<!-- MODULE-INLINE:ssot-with-why -->`
> marker + relocation-index row in `CAPTAIN_DAEDALUS.md` §6.0. §6.2 (KEEP) repoints its self-catch
> extension-pointer at this module.

### 6.10 Qualitative-acceptance-anchor surface (SSoT-with-WHY pattern)

When a design ships a body of decisions that need to read clean at a later
qualitative-acceptance audit — CATO read, ARGUS cold-read, PRINCIPAL
review — the design wins by colocating the decision with the *why* in a
single source of truth (SSoT). The SSoT-with-WHY pattern is the structural
shape that enables systematic verification: a reader walking the SSoT can
trace every choice to a named rationale; the §6 anti-pattern audit at
cold-read leverages the SSoT for systematic verification rather than
hunting through scattered prose.

**The discipline (at design-time):**

1. **Identify the qualitative-acceptance surface** — the body of choices
   that will be qualitatively audited at CATO / cold-read time. Motion
   vocabulary, color palette, error-message tone, fallback-chain ordering,
   operating-mode triggers — anything where the choices are not
   individually mechanically checkable but the BODY of choices reads clean
   or doesn't.
2. **Build the SSoT module or section.** A single file (or single
   contiguous section of a file) that names every choice in the body, with
   a one-line WHY immediately adjacent to each choice. The WHY anchors the
   choice in the domain vocabulary; the cold-reader can trace why each
   choice is the choice without consulting external context.
3. **Reference the SSoT at every consumption site.** Code or prose that
   uses a choice from the SSoT names the SSoT module + the specific choice.
   Reading the consumption site tells the reader where to look up the WHY.
4. **Audit at the §6 anti-pattern surface.** When the body's
   qualitative-acceptance audit fires (CATO honesty review, ARGUS cold
   re-read), the audit walks the SSoT systematically — every choice has a
   WHY adjacent; the audit verifies every WHY is non-circular, domain-
   grounded, and not a place-holder.

**Worked example 1 — motion vocabulary SSoT (Pass 10 Arc 4 origin).** At
stellation Arc 4, ADA shipped `motionVocabulary.ts` as a single TypeScript
module containing every motion choice in the project (durations, easings,
spring stiffnesses) with a one-line rationale comment per choice grounded
in the night-sky / star-physics vocabulary the project's qualitative-
acceptance domain rests on (e.g., "starsAppearDuration: 1.2s — slow enough
that the constellation 'emerges' rather than 'flashes', per night-sky
domain vocab"). CATO independently verified the SSoT enabled clean
qualitative-acceptance audit: the reviewer walked the module top-to-bottom
and traced every motion in the running app back to a named rationale.

**Worked example 2 — three-surface reduced-motion architecture (Pass 10
Arc 4 origin).** Same arc shipped reduced-motion mitigation across three
surfaces: `<MotionConfig reducedMotion="user">` at the app root; CSS
`@media (prefers-reduced-motion: reduce)` rules in the global stylesheet;
`useReducedMotion()` hook gating React-side animation. All three are
referenced from the motion-vocabulary SSoT's reduced-motion section,
so a reader walking the SSoT sees the three-surface architecture in one
place; each surface independently exercises under `matchMedia=reduce`
in tests. The three surfaces are not separate SSoTs; they are a single
SSoT section with the cross-references.

**Cross-refs:**
<!-- cite: CAPTAIN_DAEDALUS.md §6.2 — self-assessed weak points (SSoT-with-WHY pattern reduces the surface where weak points hide) -->
<!-- cite: CAPTAIN_DAEDALUS.md §6.2.1' — canonical-code-block-fix (SSoT IS the canonical-code-block for qualitative-acceptance bodies) -->
<!-- cite: CAPTAIN_CATO.md — honesty-audit consumer (CATO reads the SSoT for the §6 anti-pattern audit) -->
- `CAPTAIN_DAEDALUS.md` §6.2 (self-assessed weak points — SSoT-with-WHY pattern reduces the surface where weak points hide)
- §6.2.1' (canonical-code-block-fix — SSoT IS the canonical-code-block for qualitative-acceptance bodies)
- `CAPTAIN_CATO.md` (honesty-audit consumer — CATO reads the SSoT for the §6 anti-pattern audit)
