# Canonical-template wording-alignment discipline — instruction module

> Relocated from `CAPTAIN_DAEDALUS.md` §6.8 (CONDITIONAL — read when a design carries two-or-more
> inline copies of a canonical template). Fires only on designs with 2+ inline canonical-template
> copies. Provenance: composition-layer spec `bw show stoa--xyb`; debloat Arc 6 (Arc 49) cut
> `agents/design/arc-49/design-rev1.md` / cut ticket `bw show stoa--xyb.11`. The slim-core residue is
> the §6.8 REAL-HEADING-LINE stub (substrate-cited from VERA §208 + SPEC L553 prose, which quotes the
> heading title preserved here verbatim) + the `<!-- MODULE-INLINE:canonical-template-alignment -->`
> marker + relocation-index row in `CAPTAIN_DAEDALUS.md` §6.0.
> Anchor: `stoa--5sr` (the Arc-24 wording-alignment empirical home). NOTE: the discipline SHIPPED in
> Arc 40 alongside `stoa--utn`, but `stoa--utn` is "Promote save-verdict skill" — a different topic,
> a shipped-in-arc cite, NOT the empirical home. The wording-alignment story lives in `stoa--5sr` +
> `agents/design/arc-24/design.md`.

### 6.8 Canonical-template wording-alignment discipline

When your design contains TWO OR MORE inline copies of a canonical template
(a bash block, a poll-loop, a verdict-format YAML schema, a code stub
referenced from multiple §-locations within the design), the copies MUST be
byte-for-byte aligned modulo named-slot substitutions. The discipline is to
verify alignment mechanically before completing the design — the canonical
verification is `diff <(sed -n '<start1>,<end1>p' <design.md>) <(sed -n
'<start2>,<end2>p' <design.md>)` returning empty output. If the diff is
non-empty, either the copies disagree (a defect class ARGUS will catch on
re-audit) or one copy is a deliberate variant (in which case the variant must
be named and defended in the surrounding prose — silent variance fails this
gate).

The discipline applies inside a single design.md file specifically — the
failure mode is two near-identical canonical templates authored within one
design where the byte-level alignment was assumed-rather-than-verified.
Cross-file canonical templates (a design.md referencing a template that lives
canonically in a different substrate file) are a separate concern handled by
the substrate's existing single-source-of-truth discipline + cite-at-read-site
convention; this §6.8 covers the within-design case.

**Cross-FILE byte-aligned template *regions* (out of §6.8's scope — manual
enforcement).** A distinct case is a byte-aligned template region replicated
VERBATIM across multiple substrate files — the canonical example is the
save-verdict `printf → sha256 → bw attach` region shared byte-identically
across `modules/save-verdict.md` + `CAPTAIN_VERA.md` / `CAPTAIN_ARGUS.md` /
`CAPTAIN_CATO.md` §7 (between the `SAVE-VERDICT-BYTE-ALIGNED-REGION` sentinels).
That cross-file byte-identity is NOT covered by §6.8's within-design `diff`, and
there is NO automated/CI gate for it (no "P8" check exists). It is enforced by a
**manual four-home `diff`** of the region across all four homes, run explicitly
at the build, verify, and close-gate steps; a change inside the region MUST
re-align all homes and be re-confirmed by that hand-run `diff`. (Surfaced by
Arc 75 / `stoa--ai5`; the Arc 74 close-gate ran this four-home `diff` by hand.)

**Empirical anchor.** Arc 24 design.md (Phase 1 + Phase 2; surfaced on
ARGUS re-audit per `agents/design/arc-24/design.md` §14.2 r5 line 1147): two
inline copies of the canonical bw-poll-loop template at §3.1 Step 3 and §6.1
§5.8.3. The §3.1 copy placed `SINCE="$last"` after the closing `python -c
"..."` quote (argv position, silently ignored in `-c` mode, runtime
`KeyError: 'SINCE'`); the §6.1 copy placed it before `python -c` (env-var
prefix idiom, works correctly). ARGUS caught the drift on re-audit; the
post-fix recovery aligned both copies byte-for-byte. The empirically-cheap
defense at authoring time is the `diff` mechanical check named above. Source
ticket: `stoa--5sr`. Discipline-shipped arc: Arc 40 (`stoa--utn`).

**Cross-refs:** `agents/design/arc-24/design.md` §14.2 r5 (empirical anchor);
`agents/design/arc-24/design.md` §13.4 (parallel weak point on cross-file
cross-ref drift — separate concern, separate discipline); `CAPTAIN_DAEDALUS.md`
§6.2 (Self-assessed weak points — author may flag suspected within-design
drift as a weak point if `diff` was not run); `CAPTAIN_VERA.md` §5.11
(verification-side sibling — probe-spec anchoring discipline that prevents
under-anchored probes from masking drift §6.8 prevents at the authoring
side); `operating-disciplines.md` §28 (cite-at-read-site discipline —
orthogonal mechanism for cross-file SSoT).
