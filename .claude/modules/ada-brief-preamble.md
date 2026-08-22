# ADA brief preamble — grounding-check enumeration + credential-discipline cite

> Relocated from `MAJOR_PLINY.md` §5.2 + §5.2.1 (CONDITIONAL — read at ADA dispatch, when PLINY
> authors the executor brief). Provenance: debloat Arc 48 cut `agents/design/arc-48/design-rev1.md`
> + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.10`. The slim-core residue is the §5.2
> stub (which names §5.2.1 in prose) + routing-map row (ADA dispatch) + relocation-index row in §4.2.

The ADA dispatch brief includes a generic "ground against shipped code" instruction. Empirical signal (m5e arc, `ariadne--hhb`) showed ADA absorbing a design-internal defect anyway because the grounding instruction was too generic — the design was internally consistent, the shipped code disagreed with it, and ADA reproduced the design verbatim. Sharper version: enumerate explicit ground-check categories.

**The ADA brief preamble (which PLINY authors per dispatch) MUST include this literal:**

> Ground-check every concrete example in the design against the shipped code, specifically:
> - JSON example shapes (response bodies, request bodies)
> - Function/method signatures (parameter names, types, return types)
> - Error message text (exact string match)
> - Line ranges in path:line citations
> - HTTP response codes
> - Wire-protocol constants (header names, status codes, envelope keys)
>
> If a design example contradicts the shipped code, the shipped code is canon — flag the design drift but build to ship reality.

The enumeration is what makes the difference. "Ground against shipped code" is too easy to satisfy in a fast-read pass; the explicit list forces ADA to check each category and either confirm or surface drift.

Cross-ref to gauntlet shape: ARGUS catches design-internal consistency; CATO catches design-vs-shipped drift on review; this discipline pushes part of the catch upstream into the executor's ground-check, cheaper than waiting for CATO. ARGUS's responsibility (design-internal consistency + load-bearing risk) is unchanged; CATO's responsibility (cold-read review of the diff vs. intent) is unchanged.

## Credential-discipline cite for credentialed-operations dispatches (§5.2.1)

When the dispatch brief involves credentialed operations against any third-party API or cloud service (Railway, gcloud, gh, op, aws, azure, kubectl, vercel, fly — any CLI or HTTP API gated by an API token, OAuth scope, or service account), the brief MUST point the CAPTAIN at `operating-disciplines.md` §20 (Credential discipline) so the CI-mediated canon is structurally surfaced at the dispatch moment rather than left for the CAPTAIN to rediscover. The cite is one line in the brief's preamble:

> See `operating-disciplines.md` §20 (Credential discipline) for the CI-mediated canonical pattern (§20.1), the five rejected anti-patterns (§20.2), and the universal rule (§20.4). Agents author CI workflows; agents do NOT hold credentials.

The brief's credential-flow section MUST specify a CI-mediated path (workflow YAML the agent authors; CI runs the workflow). Any per-call credentialed-CLI dispatch in the brief is a §20.2 anti-pattern — refuse back to POLYBIUS for re-scope rather than dispatch.

(Cross-ref: `operating-disciplines.md` §20 — full credential discipline canon. §20.3 refusal-as-signal is the responsive sibling — when an external refusal has already happened mid-dispatch, halt immediately per `MAJOR_POLYBIUS.md` §13.1 universal escalation triggers + §20.3.)

Anchor: `stoa--bxx` Item 1 (ADA brief grounding-check sharpening; the m5e `error: true` SPEC-vs-shipped lesson — `ariadne--m5e` arc PR 1.SPEC / `ariadne--hhb`, 2026-05-08; design-rev3.md §2.6 defect, shipped server strips `error` before emit at `routes.py:316`, CATO caught on review, shipped clean as PR #30 / cb613b3). Recover via `bw show stoa--bxx`.
