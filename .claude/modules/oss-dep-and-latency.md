# AI-team OSS-dep calculus + agent-time latency budget — instruction module

> Relocated from `operating-disciplines.md` §17 (CONDITIONAL — read when a Stoa-deployed project
> depends on third-party OSS or designs for an agent-driven traffic profile). Provenance:
> composition-layer spec `bw show stoa--xyb.4`; debloat Arc 47 cut
> `agents/design/arc-47/design-rev2.md` + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.8`.
> The slim-core residue is the §17 stub + relocation-index row in `operating-disciplines.md` §0.5.

Two adjacent disciplines that surface together for any Stoa-deployed project depending on third-party open-source or designing for an agent-driven traffic profile. Replicated from workspace-tier memory files to substrate per `stoa--rno`.

### 17.1 Fork-over-upstream default for AI-team OSS dependencies

The AI-team OSS calculus is inverted from human-dev convention.

- **For a human dev team:** fork-and-tailor is expensive (maintenance burden, drift from upstream, ongoing sync cost). Upstream-issue-filing is cheap (open ticket, wait, maybe land). Default: file the issue; minimize the fork.
- **For an AI agent team:** fork-and-tailor is cheap (the agent can carry the diff trivially; sync is also automatable). Upstream-issue-filing is expensive coordination overhead (write the issue with discipline; wait days or weeks; possibly never resolved; blocks the project's roadmap). Default: fork-and-tailor when the dep doesn't fit the specific use case. Upstream-contribute-back is optional and post-hoc.

**The discipline:** when a Stoa-deployed project hits an upstream limitation that a small patch would resolve, the default decision is **fork the dep into the project's own workspace and apply the patch**. Upstream-PR is a downstream optional step, not a precondition. The 2026-05-12 bw arc validated this empirically: a 150 LOC `TreeFS`-incremental-tree-update patch is a small fork-and-tailor surface for the AI team but a substantial upstream coordination job (RFC, maintainer review, possibly multiple rounds, possibly rejected for design-fit reasons). The project-tier choice (pivot the use case rather than fork) was viable in that specific arc because the use-case pivot was cheap; the architectural option to fork was always available and cheap.

Two adjacent considerations:

- **The fork is not a fork in the destructive sense.** It's a local patch applied at install / build time, with the upstream remained as the canonical source. The diff is small; sync from upstream remains automatable.
- **Upstream contribution stays optional.** If the patch's design happens to be a clean general improvement and the maintainer is responsive, contribute it back. If not, the patch lives in the project's substrate; the project is unblocked.

### 17.2 Agent-time latency budget for agent-driven traffic

When a system's traffic is 100% agent-to-system (no human keystrokes in the request loop), the latency budget is **per-LLM-turn** (5-20s acceptable per round-trip), not **per-human-keystroke** (<1s expected). Optimizing for human-perceived-instant response is over-optimization for a system that won't be touched by human keystrokes.

Engineering decisions shift on several axes:

| Decision | Human-facing | Agent-facing |
|---|---|---|
| 1-2s synchronous ingest API call | unacceptable | acceptable |
| Bulk operations spread over minutes | unacceptable | acceptable |
| Async-queue-for-bulk plumbing | required | not needed unless wall-clock is a real bottleneck |
| UI polish / streaming responses | high priority | lower priority than correctness / coverage |
| Cold-start latency (process spin-up) | unacceptable | acceptable when the agent's own turn-budget absorbs it |

The implication: for any Stoa-deployed project that has an agent-vs-human-consumer split, the substrate-canonical engineering trade-offs match the consumer profile. A project serving agents only does NOT inherit the human-facing latency budget; it inherits the agent-facing one, and the engineering choices follow.

**Discipline:** when designing a new Stoa-deployed project, ask explicitly: who is the consumer of this traffic — humans, agents, or both? The answer drives the latency budget, the engineering choices, and where polish-effort lands. Same project-tier rule across the team.

Empirical anchor: `Anchor: stoa--rno` — 2026-05-12, the bw → Ariadne integration arc's Phase 4 OPERATOR ACTION analysis. Workspace-tier memory files at `ariadne-core-workspace/memory/feedback_fork_over_upstream_issue.md` + `project_agent_time_latency_budget.md`. Recover via `bw show stoa--rno`.
