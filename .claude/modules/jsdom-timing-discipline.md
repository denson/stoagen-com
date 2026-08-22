# Test-environment timing discipline — jsdom + animation libraries — instruction module

> Relocated from `operating-disciplines.md` §32 (CONDITIONAL — read when authoring or verifying
> tests against animation surfaces in a jsdom test environment). Provenance: composition-layer spec
> `bw show stoa--xyb.4`; debloat Arc 47 cut `agents/design/arc-47/design-rev2.md` + epic
> `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.8`. The slim-core residue is the §32 stub +
> relocation-index row in `operating-disciplines.md` §0.5.

jsdom (the headless DOM environment most projects use for React tests) does
not implement `requestAnimationFrame` in a way that drives animation
libraries' internal timing loops. `motion` / `framer-motion`'s
`AnimatePresence` exit animation with `mode="popLayout"` waits for
rAF-driven completion that jsdom does not deliver; the element stays in
the DOM with `opacity: 0` and the testid still attached, indefinitely.

**The discipline (at test-authoring time):**

1. **Identify animation-library code paths that depend on rAF-driven
   timing.** Exit animations, layout transitions, springs that decay over
   multiple frames.
2. **Assert against the OBSERVABLE END-STATE under jsdom, not the
   library's exit-completion semantics.** "Element absent from DOM" is
   not the right assertion for an `AnimatePresence` exit under jsdom;
   "element has `opacity: 0` OR is absent from DOM" is the correct
   disjunctive assertion that round-trips both real-browser and jsdom
   semantics.
3. **When testing an animation that targets the DOM-presence boundary,
   write a helper that accepts EITHER observable.** Example helper
   contract: `expectXHidden()` returns truthy when either the X-testid
   element is absent OR the element's outer wrapper has computed `opacity`
   zero. The helper documents the disjunction; individual tests don't
   re-derive it.

**Empirical anchor.** Pass 10 Arc 4 build: `AnimatePresence mode="popLayout"`
star exit animation under jsdom; the rAF-driven exit didn't complete; the
star element stayed in the DOM with `opacity: 0`; the test's
`expect(queryByTestId('star')).toBeNull()` assertion failed against the
intended exit behavior. The `expectStarHidden()` helper (accepting EITHER
testid-absent OR outer-wrapper-opacity-0) resolved the test failure
without weakening the qualitative-acceptance audit (real browser fires the
exit correctly; jsdom rests at the early-frame state; both are
"star hidden" for the test's purposes).

**Cross-refs:**
<!-- cite: CAPTAIN_ADA.md §5.9 — build-time sibling (motion-API scope reduction; both are properties of motion + jsdom interaction) -->
<!-- cite: CAPTAIN_VERA.md §5.1 — verification-side test-discipline (VERA reads this module when designing probes against animation surfaces) -->
<!-- cite: CAPTAIN_CATO.md — honesty-audit consumer (when a test asserts disjunctively against the environment, CATO verifies the disjunction is the empirical reality, not a smoothed-over defect) -->
- `CAPTAIN_ADA.md` §5.9 (build-time sibling — motion-API scope reduction; both are properties of motion + jsdom interaction)
- `CAPTAIN_VERA.md` §5.1 (verification-side test-discipline — VERA reads this module when designing probes against animation surfaces)
- `CAPTAIN_CATO.md` (honesty-audit consumer — when a test asserts disjunctively against the environment, CATO verifies the disjunction is the empirical reality, not a smoothed-over defect)
