# bw-fit matrix + layered-architecture framing — instruction module

> Relocated from `operating-disciplines.md` §16 (CONDITIONAL — read when a POLYBIUS seat is
> choosing a substrate for a project's ticket-shape / knowledge-shape state and weighing bw fit).
> Provenance: composition-layer spec `bw show stoa--xyb.4`; debloat Arc 47 cut
> `agents/design/arc-47/design-rev2.md` + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.8`.
> The slim-core residue is the §16 stub + relocation-index row in `operating-disciplines.md` §0.5.

When choosing a project's substrate for ticket-shape state, knowledge-shape data, or hybrid use cases, consult this matrix before committing to bw. The matrix codifies the empirical bw scaling characteristics observed across the 2026-05 stoa + ariadne integration arcs.

### 16.1 The bw-fit matrix

| Use case shape | Fit |
|---|---|
| Project-management substrate, incremental over months/years, < ~5k lifetime tickets | bw is the right choice |
| Agent-team work-tracking with rich metadata + dependencies | bw is the right choice (Stoa's own use) |
| Investigative workflow with structured evidence + hypotheses | bw is the right choice |
| Audit trail for a workflow with versioned commits | bw is the right choice |
| Catalog / reference corpus / knowledge-graph at 10k+ entries | NOT bw — use direct Postgres, beads-on-Dolt, or another DB engine |
| High-write-rate bulk ingest workloads | NOT bw — even if total corpus is small |
| Use cases requiring concurrent multi-agent cell-level merge | NOT bw (consider beads-on-Dolt if this is a real requirement) |

The wall: bw's `TreeFS.Commit` rewrites the entire tree on every commit (no incremental tree update). At ~5k tickets and beyond, this becomes superlinear (~21s/ticket observed at 11,446 tickets; ~50-80h projected for full bulk-seed of that corpus). The matrix's "right choice" rows are use cases where the commit-rate stays well below the scaling wall; the "NOT bw" rows are where the scaling wall is structurally load-bearing.

### 16.2 The layered-architecture framing

**bw is the write-side substrate; an optional read-side projection add-on (hybrid search + KG) serves the read side; hypergraph extends the projection to relational reads.** Each layer addresses a different read shape; do not force bw to be fast at reads — that is not its job in the stack.

Concretely:

- **bw (write-side).** Authoritative ticket-shape state. Audit-trail-grade durability. Incremental-author-friendly. Best when reads are spot-lookups against known IDs or small-set list operations. Native bw `list` / `show` / `history` are the right APIs at this layer.
- **Read-side projection add-on (hybrid search + KG).** An optional sidecar projection layer that mirrors bw's state into a queryable shape (typically SQLite + FTS5 + structured indices). Built for relational reads, full-text search, cross-ticket aggregation, and analytics queries that bw cannot serve fast at scale. The projection is eventually-consistent with bw; bw is the source of truth, the projection is the cached query layer.
- **Hypergraph extension.** When the project's read shape includes many-to-many relationships across tickets / artifacts / concepts (knowledge-graph queries; multi-hop traversal; relational joins on derived attributes), the hypergraph layer sits on top of the read-side projection. Same eventually-consistent pattern; richer query surface.

The mental model substantive value: for any future Stoa-deployed project that needs both ticket-shape and knowledge-shape data, the projection layer is load-bearing — bw alone won't carry the knowledge-graph use case. The bw → read-side-projection integration arc was proving exactly this: the bulk-seed wall was the empirical evidence that bw is for writes, the projection add-on is for reads, and the two layers compose.

### 16.3 Decision rule

When a future POLYBIUS session is considering bw for a project, walk the matrix at §16.1 first:

1. If the use case falls in a "right choice" row → bw is the right substrate. Standard stoa-deploy applies.
2. If the use case falls in a "NOT bw" row → use the alternative named in the matrix row. Document the choice; bw is not the universal answer.
3. If the use case spans both (ticket-shape + knowledge-shape, or write-intensive small + read-intensive large), apply the layered architecture from §16.2: bw for the write side, a projection layer for the read side. Don't force one tool to do both jobs.

Empirical anchor: `Anchor: stoa--vmc` — 2026-05-12, the bw → Ariadne integration arcs in ariadne-core-workspace. Project-tier relay at `HUMAN_relay_substrate_bw_scaling_findings_2026-05-12.md`. Research artifacts in `agents/research/bw-scaling-vs-mature-systems/` and `agents/research/bw-create-on-source-read/`. `ariadne--8fd.10` in the project-tier bw store documents the scaling-wall confirmation. Recover via `bw show stoa--vmc`.
