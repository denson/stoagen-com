# Sub-agent diagnostic transcript discipline — instruction module

> Relocated from `operating-disciplines.md` §14 (CONDITIONAL — read when a dispatching seat
> kills a sub-agent mid-dispatch and needs the post-mortem evidence discipline). Provenance:
> composition-layer spec `bw show stoa--xyb.4`; debloat Arc 47 cut
> `agents/design/arc-47/design-rev2.md` + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.8`.
> The slim-core residue is the §14 stub + relocation-index row in `operating-disciplines.md` §0.5.

When a sub-agent (CAPTAIN, Explore, general-purpose, etc.) is killed mid-dispatch — by watchdog (per `MAJOR_PLINY.md` §5.3) or manually by the dispatching seat — capture the JSONL transcript of the dispatch BEFORE the process exits. The transcript is the only direct evidence of what the agent was doing at stall time; reconstruction-from-memory or reconstruction-from-screenshots is fallback only.

**Save target:** `.claude/diagnostics/<agent-mnemonic>-<dispatch-id>-<timestamp>.jsonl` (or analogous; substrate names the convention, project may localize). The directory is part of the project's working tree; gitignore as appropriate (transcripts are diagnostic context, not durable substrate).

**Read-side discipline:** when authoring a post-mortem after a stall or kill, the JSONL transcript is first-line evidence. Reconstruction from screenshots or working memory is fallback when the transcript is unavailable. A post-mortem authored without consulting the transcript when one exists is a discipline failure — the evidence is there; use it.

**Open question (carried forward, not resolved):** how the parent session captures the JSONL transcript depends on whether Claude Code exposes it natively. If it does, the discipline is "save it on every kill." If it does not, the discipline reduces to "name the convention; await platform support" and the implementation surface stays open at `stoa--dyb` Item 2. This section names the discipline shape; the implementation question is downstream of platform capability.

Empirical anchor: `agents/design/ariadne--m5e/post-mortem-daedalus-rev3-stall.md` (in ariadne-core-workspace; 2026-05-07; 12.7 KB) — 6+ DAEDALUS rev3 stalls left no diagnostic trace; the post-mortem had to reconstruct from intermittent screenshots and status snapshots. Substrate fix: capture the JSONL transcript on every kill, by default. Substrate ticket: `stoa--dyb` Item 2.

Universality: every seat that dispatches sub-agents (currently MAJOR_PLINY; future tiers may add).
