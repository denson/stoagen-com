# Probe-grounding discipline (the §6.9 cluster) — instruction module

> Relocated from `CAPTAIN_DAEDALUS.md` §6.9 + §6.9.3' + §6.9.3'' (CONDITIONAL — read when a design
> authors verification probes containing regex/grep/algorithm against substrate prose or tool output).
> The three subsections are ONE coherent probe-grounding discipline (§6.9.3'/§6.9.3'' explicitly extend
> §6.9 clause 3), co-located in this single module. The §3-probes-section RULE itself is in always-on §3
> of the slim core; the GROUNDING DETAIL below is read only when probes are regex/tool-shaped.
> Provenance: composition-layer spec `bw show stoa--xyb`; debloat Arc 6 (Arc 49) cut
> `agents/design/arc-49/design-rev1.md` / cut ticket `bw show stoa--xyb.11`. The §6.9 5-anchor empirical
> compresses to the Anchor below; the §6.9.3'/§6.9.3'' in-prose stellation-Pass-10 narrative anchors
> (no standalone bw ticket) move VERBATIM into this module (it IS the surviving copy). The slim-core
> residue is the §6.9 (REAL-HEADING-LINE — substrate-cited 8× by the validate-spec skill) + §6.9.3' +
> §6.9.3'' (REAL-HEADING-LINE — VERA-cited ×2) stub heading lines + ONE
> `<!-- MODULE-INLINE:probe-grounding -->` marker + relocation-index row in `CAPTAIN_DAEDALUS.md` §6.0.
> Anchor (§6.9): stoa--mn3, stoa--1lm.

### 6.9 Probe-grounding discipline for design.md probes (extends §5.11 to the authoring seat)

When you author a verification probe in design.md, the probe is a load-bearing
instruction to ADA-at-build-time and VERA-at-verify-time. A probe with a regex
that doesn't match its target — or matches more than the intended target —
produces a misleading PASS that the gauntlet then ratifies. The §5.11
discipline at `CAPTAIN_VERA.md` catches this at verify-time when the verifier
notices the under-anchoring; the discipline below catches it at authoring-time
before the brittle probe ships into the design.

**The discipline (at probe-authoring time).** Before submitting any design.md
probe whose body contains a regex or grep pattern against substrate prose, the
canon file structure, or shipped tool output:

1. **Anchor the regex.** Use `^` (line-start), `$` (line-end), word-boundaries
   `\b`, OR a unique surrounding-context substring that disambiguates the
   intended single-or-bounded match from incidental documentation prose.
   Bare-substring patterns that match anywhere in the file are the empirical
   defect-source (mn3 m_4.12.2 anchor: `\bthe user\b` matching
   `the user-tier-POLYBIUS`).

2. **Character-class completeness.** When matching tool-flag or command-name
   patterns, account for case-flag combinations and shell-metacharacter context
   explicitly. `[a-z]*` does NOT match uppercase letters (mn3 m_4.5.2 anchor:
   `grep -[a-z]*i[a-z]*` cannot match `grep -ciE`); use `[a-zA-Z]*` or apply
   `grep -i` at the outer scope.

3. **Live round-trip at authoring time.** Run every probe command literally
   against the current substrate state during design draft. A probe that emits
   zero matches against the very state it's being authored for is structurally
   broken, not under-specified — fix at design-time, don't ship to ADA.
   Adjacent prose (parentheticals, "or equivalently" clauses, algorithmic
   justifications) is covered by §6.9.3'. See §6.9.3'' for the
   operationalized live-RT step + COMPLETENESS CLAUSE / SIBLING-DEFECT-CLASS
   EXTENSION (canon-promoted Arc 43).
   <!-- cite: CAPTAIN_DAEDALUS.md §6.9.3' — round-trip-adjacent-prose discipline (extends clause 3 to prose surrounding the probe) -->
   <!-- cite: CAPTAIN_DAEDALUS.md §6.9.3'' — live-RT at authoring time + COMPLETENESS CLAUSE / SIBLING-DEFECT-CLASS EXTENSION (operationalized clause 3) -->

4. **Ground-check against shipped tool surface.** Do not assume tool flags or
   output shapes from memory. Verify against the shipped script source OR live
   tool output (mn3 m1 anchor: `install.sh --no-bw-init` / `--dest` cited flags
   that don't exist; mn3 m2 anchor: `bw show <id> | grep '^Status:.*closed'`
   cited a status-line shape bw doesn't emit). The §5.2 `MAJOR_PLINY.md`
   grounding-check preamble names this for ADA-build-time; this clause names
   it for DAEDALUS-authoring-time. See §6.11 for the API-docs-examples
   sibling discipline (ground-check the API verb against the target
   element's attribute surface, not just the docs example).
   <!-- cite: CAPTAIN_DAEDALUS.md §6.11 — API-docs-examples-don't-generalize-to-differently-shaped-elements (sibling discipline extending clause 4 to third-party API surfaces) -->


5. **Enumeration vs invocation context.** When a probe greps for risky shell
   tokens (credentials, dangerous commands), scope the grep to the relevant
   context (bash-code-block, git-diff +-line, or rejection-context exclusion)
   rather than whole-file. Whole-file greps false-positive on the substrate's
   own canon documenting the anti-pattern (mn3 m_4.12.3 anchor:
   credential-discipline probe over-matched on enumeration-context lines vs
   actual invocations).

If you cannot apply one of (1)-(5) for structural reasons, surface the gap in
your verdict's `self_assessed_weak_points:` field per §6.2 — that surfaces the
probe-spec brittleness to ARGUS during plan critique, before ADA inherits it.

**Empirical anchor.** Arcs 40-41 accumulated 5 design.md probe-spec defects
(filed at `stoa--mn3`; canon-promotion proposal at this section per
`stoa--1lm`): Arc 40 m1 (install.sh non-existent flag) + m2 (bw output shape
drift); Arc 41 m_4.5.2 (case-class character drift) + m_4.12.2 (word-boundary
FP on hyphenated compound) + m_4.12.3 (whole-file grep over-match on
enumeration context). All 5 substantively PASSed (VERA / ADA caught the drift
and reverified with corrected patterns); the recurrent failure mode is
hand-typed probes that don't live-round-trip at authoring time.
Discipline-shipped arc: Arc 42 (`stoa--1lm`).

**Cross-refs:** `CAPTAIN_VERA.md` §5.11 (verification-side sibling — when a
probe ships with under-anchoring despite this discipline, §5.11 catches it at
verify-time); `CAPTAIN_DAEDALUS.md` §6.2 (self-assessed-weak-points
pre-ratification — probe-spec brittleness you cannot eliminate at authoring
belongs in this field); `MAJOR_PLINY.md` §5.2 (the grounding-check preamble
for ADA-build-time; the §5.2 preamble is the build-seat sibling to this
authoring-seat discipline).

### 6.9.3' Round-trip prose adjacent to probe-specs (extends 6.9 clause 3)

§6.9 clause 3 names live-round-trip as the discipline for the probe body itself.
The discipline below extends that to prose adjacent to the probe: a parenthetical
next to the regex, an "or equivalently" clause, an algorithmic justification in
the paragraph above the bash block. ADA reads adjacent prose as authoritative
at build time. A parenthetical that contradicts the regex it surrounds is a
live defect waiting to fire — ADA may build the regex faithfully and the
parenthetical wrong, or the other way around, but the gauntlet cannot
downstream-catch a contradiction the design's own author smoothed past.

The discipline (at probe-authoring time):

1. **Identify the adjacent prose surface.** Parentheticals immediately
   following a regex; "or equivalently" clauses pointing to a different
   mechanism; algorithmic justifications in the prose paragraph that
   precedes the bash code-block. These are CONTRACT CLAIMS, not commentary.
2. **Round-trip the prose through the probe's actual semantics.** Mentally
   or literally execute the probe against the example the prose names; verify
   the prose's claim is what the probe actually emits.
3. **When the prose generalizes ("this also catches X-shaped sibling defects"),
   audit X explicitly.** A claim of generalization is a sibling-defect-class
   audit promise; if you cannot live-round-trip X, narrow the claim or surface
   in `self_assessed_weak_points:` per §6.2.

**Empirical anchor.** Three anchors across Arcs 2-3 of stellation Pass 10:
Arc 2 r4 (originating) — §2.3 parenthetical "or equivalently the mirror via
`blocked_by`" contradicted Probe O's directed-graph semantics; ARGUS caught
by running Probe O literal Node logic against the parenthetical reading.
Arc 3 r4 — Probe G2 shell-quoting bug: mixed-quote regex unexecutable in
bash; the surrounding prose described what the regex was *meant* to match,
but the regex itself was syntactically broken. Arc 3 ADA Phase 4.5 — design
§1 assumption 10 inlined literal `getByTestId(skeleton-stars)` strings in
canonical App.test.tsx comments that tripped Probe M-A's negation greps;
design's own §3 live-RT block tested the stripped version, masking the
contradiction. ADA caught at build-time.

**Cross-refs:**
<!-- cite: CAPTAIN_DAEDALUS.md §6.9 — probe-grounding parent canon (clause 3 names live-round-trip; this section extends to the probe's surrounding prose) -->
<!-- cite: CAPTAIN_DAEDALUS.md §6.9.3'' — live-RT-at-authoring (the operational mechanism that catches both probe-body and adjacent-prose drift) -->
<!-- cite: CAPTAIN_DAEDALUS.md §6.2 — self-assessed weak points (where ungeneralizable claims surface to ARGUS) -->
- `CAPTAIN_DAEDALUS.md` §6.9 (probe-grounding parent canon — clause 3 names live-round-trip; this section extends to the probe's surrounding prose)
- `CAPTAIN_DAEDALUS.md` §6.9.3'' (live-RT-at-authoring; the operational mechanism that catches both probe-body and adjacent-prose drift)
- `CAPTAIN_DAEDALUS.md` §6.2 (self-assessed weak points — where ungeneralizable claims surface to ARGUS)

### 6.9.3'' Live-round-trip probes at authoring time + COMPLETENESS CLAUSE (extends 6.9 clause 3)

§6.9 clause 3 names "live round-trip at authoring time" as the discipline
for probes whose body contains a regex / grep / algorithm. The discipline
below operationalizes that into a step you actually run, and extends it
with two additional clauses that close empirical gaps Arc 4-5 surfaced.

**The operational discipline (at probe-authoring time):**

1. **Before submitting any probe whose body is a literal command, run the
   command against the current state the probe targets.** If the probe is
   a grep against substrate prose, run the grep against the live file. If
   the probe is an algorithmic check (e.g., "regex X matches input Y"), run
   a one-line Python REPL against Y. Prose-auditing the shell or algorithm
   is insufficient; the discipline is to LIVE-RUN.
2. **A probe that emits zero matches against its target state is structurally
   broken, not under-specified.** Do not ship it expecting ADA or VERA to
   figure out the correct anchor. Fix at design-time, or surface as a
   `self_assessed_weak_point:` per §6.2 with the structural reason.

**COMPLETENESS CLAUSE (the canon-promotion clause).** When you fix one
probe-defect during design draft, do not stop at the named instance. The
empirical record is that defect-classes recur at sibling sites within the
same design draft. The discipline is to audit for the **defect-class**, not
just the exact-pattern-instance:

- If you fixed a hex-escape (`\x27` mismatching a literal apostrophe) at one
  probe, audit every other probe in the design for hex-escapes against
  literal characters — at least 2 sibling instances are typical.
- If you fixed a POSIX/Windows portability defect (e.g., `bash`-only syntax
  in a cross-platform probe), audit every other probe for POSIX-only
  constructs that won't round-trip in the build environment ADA actually
  uses.
- If you fixed an under-anchored regex (matching incidental prose vs the
  intended target), audit every other regex probe for anchor-completeness
  — `^` / `$` / `\b` / unique surrounding context.
- If you fixed a grep-anchored probe, audit every Vitest assertion (or
  equivalent test stub) for sibling under-specification — the defect-class
  spans tool boundaries.

**SIBLING-DEFECT-CLASS EXTENSION (the extension that distinguishes
"defect-class" from "exact-instance").** Sibling-class audit means: when a
defect-class has surfaced, identify the structural property the defect
rests on (under-anchoring, character-class incompleteness, platform
assumption, …), then audit every probe in the design that COULD rest on
that property, not just probes that share the exact symptom.

**Cost-multiplier math (the 60× anchor).** The empirical cost of skipping
sibling-class audit and shipping the design is ~60× the cost of running the
audit at design time. Mechanism: when ARGUS catches the sibling defect on
re-audit, the cost is at minimum a rev-cycle round-trip (~10 minutes of
orchestrator + ARGUS + DAEDALUS wall-clock) plus the cognitive cost of
reconstructing the original audit context. When VERA catches it
downstream, the cost is a build-rev cycle (~30-60 minutes of orchestrator
+ ADA + VERA wall-clock) plus the design-rev to update the probe spec.
The audit-at-design-time cost is ~60 seconds (a `grep -n` scan of the
design's own probe blocks + a mental check against the named defect-class).
~60 seconds vs ~60 minutes = 60× multiplier. The math holds when ARGUS
catches at design-rev; it grows when VERA catches at build-rev.

**Empirical anchor (the 6-anchor canon-promotion block).** Pass 10
stellation Arcs 4-5 surfaced 6 anchors across orthogonal defect-classes,
each showing the same shape: one defect named + fixed; the fix did not
generalize; a sibling-class instance surfaced at the next rev. The 6:

1. **Arc 4 rev1 r3 — `\x27` hex-escape recurrence at Probe K** after the
   same hex-escape was fixed at Probes I / F / L. The fix at I / F / L
   treated the defect as an exact-pattern problem; the defect was
   actually a class (hex-escape against literal apostrophe in any regex
   referencing prose).
2. **Arc 4 rev2 r2 — POSIX/Windows portability recurrence at Probes S + P**
   after the same portability concern was fixed via a caveat at Probe D.
   The caveat-at-one-probe didn't audit the rest of the design.
3. **Arc 4 VERA-final — under-anchored regex recurrence at Probes F / K2 /
   L2** across 3 different probe sites. VERA caught all 3; each was a
   class instance.
4. **Arc 5 ARGUS-rev1 r2 — stub-Vitest assertion under-specification**
   (cross-tool sibling of the grep-anchored defect-class; same structural
   property, different tool).
5. **Arc 5 ARGUS-rev2 — SIBLING-class catalog explicit:** ARGUS-rev2
   surfaced the canonical wording "DEFECT-CLASS, not just exact-pattern-
   instance" + named 3 sibling instances at once. This is the wording
   promoted to canon here.
6. **Cross-arc — same defect-class keeps surfacing at sibling sites after
   named-instance fix.** The 5 specific anchors above all share this
   cross-cutting property; it is the structural reason the COMPLETENESS
   CLAUSE matters.

**Recursive self-application surveillance.** When this canon ships in
design.md probes (including the one shipping THIS canon), expect the canon
to apply to its own probes. An ARGUS catch of a §6.9.3'' violation in a
design that proposes §6.9.3'' is a POSITIVE empirical anchor for the canon,
not a defect to hide. The discipline at probe-authoring time is to surface
suspected violations in `self_assessed_weak_points:` per §6.2 and let
ARGUS catch what was missed.

**Cross-refs:**
<!-- cite: CAPTAIN_DAEDALUS.md §6.9 — parent canon (clause 3 names live-round-trip in principle) -->
<!-- cite: CAPTAIN_DAEDALUS.md §6.9.3' — round-trip-adjacent-prose (sibling extension covering prose around the probe) -->
<!-- cite: CAPTAIN_DAEDALUS.md §6.2 — self-assessed weak points (where suspected violations surface to ARGUS) -->
<!-- cite: CAPTAIN_VERA.md §5.11 — verification-side sibling (when authoring discipline fails, §5.11 catches at verify-time) -->
- `CAPTAIN_DAEDALUS.md` §6.9 (parent canon — clause 3 names live-round-trip in principle)
- `CAPTAIN_DAEDALUS.md` §6.9.3' (round-trip-adjacent-prose — the sibling extension covering prose around the probe)
- `CAPTAIN_DAEDALUS.md` §6.2 (self-assessed weak points — where suspected violations surface to ARGUS)
- `CAPTAIN_VERA.md` §5.11 (verification-side sibling — when authoring discipline fails, §5.11 catches at verify-time)
