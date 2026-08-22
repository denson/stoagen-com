# Multi-team interoperation — how Stoa-deployed workspaces coexist — instruction module

> Relocated from `operating-disciplines.md` §29 (CONDITIONAL — read when a seat needs the
> across-workspace interoperation topology: prefix-namespaces, cross-team request routing,
> consumed-artifact channels, team discovery). Provenance: composition-layer spec
> `bw show stoa--xyb.4`; debloat Arc 47 cut `agents/design/arc-47/design-rev2.md` + epic
> `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.8`. The slim-core residue is the §29 stub +
> relocation-index row in `operating-disciplines.md` §0.5. The §29.6 N=1 provenance compresses to
> `Anchor: stoa--kt6, stoa--gq1` (recover via `bw show`).

The Stoa ecosystem is multi-workspace. Each workspace is a Stoa-substrate-deployed project with its own base team (forge) + project team (shop) per `MAJOR_POLYBIUS.md` §19. Workspaces in the current ecosystem include: **the-stoa** (the canonical forge; ships the substrate templates), **ariadne-core-workspace** (the first specialized derivative; semantic-search infrastructure), **railway_stoa** (in setup; Railway-deploy tooling + skills), plus future workspaces (Conan, factory-demo, additional sector-N deployments). Each workspace has its own bw store, its own deployed CAPTAINs, its own accumulated memories, and its own ongoing engagement with PRINCIPAL.

This section is the universal-team layer for inter-workspace concerns. `MAJOR_POLYBIUS.md` §19 is the intra-workspace layer (two teams within one workspace); §7 is the within-team coordination layer. The three nest: §7 (within team) → §19 (within workspace, two teams) → §29 (across workspaces).

### 29.1 Each workspace is its own project

The structural property: every Stoa-deployed workspace operates as an independent project with its own bw store, its own deployed agents, its own memory accumulation, its own engagement lifecycle. There is no shared runtime state across workspaces; there is no shared bw across workspaces (each carries its own `beadwork` orphan branch per §12 + §9); there is no shared memory store (memories live at `~/.claude/CLAUDE.md` for user-tier and at the project's `.claude/CLAUDE.md` + `MEMORY.md` for project-tier).

The the-stoa workspace is the **canonical forge**: it produces the substrate templates every other workspace consumes via `install.sh`. The relationship is one-way at the substrate-source layer: the-stoa publishes; everyone else consumes. At every other layer — operational state, current work, accumulated memory — workspaces are peers, not children.

### 29.2 Cross-team interoperation happens via consumed artifacts

Workspaces interoperate through artifacts they produce that other workspaces consume:

- **Skills.** A workspace that produces a skill (e.g., railway_stoa producing a Railway-deploy skill; the-stoa producing the universal credential-discipline skill) lands the skill at the producer's `substrate/skills/<name>/` (or `.claude/skills/<name>/` for non-substrate-tier workspaces); consumers either install it via `install.sh` (if it's substrate-tier) or copy it directly into their own `.claude/skills/custom-<name>/` per §23 / `MAJOR_POLYBIUS.md` §17.3 (if it's workspace-tier customization).
- **Tooling source.** A workspace producing tooling (e.g., the bw tool itself, the-stoa's `install.sh`) publishes via its own release mechanism; consumers `git clone` + `npm install` / `pip install` / `cp` per the tool's deploy convention.
- **Deployed services.** A workspace producing a runtime service (e.g., a railway_stoa deploy that serves an API ariadne-core-workspace consumes) ships via the service's deploy mechanism (Railway, GCP Cloud Run, etc.); consumers integrate via the service's documented API.

The interoperation is artifact-mediated, not direct-runtime. No workspace agent ever dispatches an Agent tool call into a peer workspace's runtime; no workspace bw is read or written from a peer workspace's session. The bounded-context property §7.5 enforces within-tier is mirrored at the workspace boundary: each workspace operates against its own state and inherits from siblings only via consumed-artifact channels.

### 29.3 Cross-team bw coordination — prefix-namespace convention

Each workspace's bw uses a distinct prefix to disambiguate ticket IDs across workspaces:

| Workspace | bw prefix |
|---|---|
| the-stoa | `stoa--` |
| ariadne-core-workspace | `ariadne--` |
| railway_stoa | `railway--` |
| sector-4 (future workspace; prefix not yet deployed) | `s4--` (planned) |
| user-tier (cross-project context, discipline-accretion) | `u--` |

The prefix is set in the project's `bw` configuration at `bw init` time. When a substrate-tier ticket needs to reference a peer-workspace ticket (e.g., the-stoa's `stoa--p5g` credential-discipline arc references its empirical anchor at `railway--r9z`), the reference uses the full prefixed ID — there is no ambiguity because prefixes are workspace-distinct.

Note on the sector-4 row: the `s4--` prefix is reserved for the planned sector-4 workspace; no `s4--` bw store is deployed at this writing (verified 2026-05-17: `bw list --grep s4--` returns zero matches across all initialized workspaces). The row is aspirational and documented here for future-workspace setup convention; it is NOT a claim of current deployment.

Cross-workspace bw operations are SCOPED to the operating workspace. A session at the-stoa cannot `bw show ariadne--<id>` from inside the the-stoa workspace; that would require `cd`-ing into ariadne-core-workspace's directory first (where the ariadne-core bw store is bound). The downward-only visibility rule from §7.5 applies recursively at the workspace boundary: user-tier POLYBIUS can read down into every workspace's bw via its unified poll per §7.3; project-tier seats see only their own workspace's bw.

### 29.4 Cross-team requests flow through user-tier POLYBIUS or PRINCIPAL

When a project-tier seat at workspace A needs cross-workspace context (a result from workspace B, an empirical anchor from workspace C, a coordination signal across workspaces), the request flows through one of two paths:

1. **Through user-tier POLYBIUS** — the only seat with cross-workspace visibility (per §7.3 unified poll). Project-tier seat A posts a `[for: user-tier-polybius]` comment on its own workspace's coordination ticket per §7.4; user-tier POLYBIUS polls down, reads the request, responds on the same ticket within poll cadence (~5 min default). Cross-workspace coordination meets at the lower tier (workspace A's bw); user-tier POLYBIUS responds back into workspace A's bw, never writing upward into workspace A's parent-of-anything.
2. **Through PRINCIPAL** — for cross-workspace requests that exceed user-tier POLYBIUS's discretion (project-direction questions about cross-workspace sequencing; strategic-priority calls; cross-workspace ship/no-ship). PRINCIPAL is the cross-project broker per `MAJOR_POLYBIUS.md` §5.1.1.1 (cross-project sequencing context is user-tier-only — never leaked to project-tier seats).

**Project-tier seats do NOT directly dispatch into peer-workspace teams.** That would violate §7.5 write boundaries (no upward writes; no cross-workspace writes by extension). When a project-tier seat believes its work needs a peer workspace's capability (e.g., ariadne-core-workspace wants a Railway-deploy skill from railway_stoa), the correct path is: surface to user-tier POLYBIUS, request the artifact be made available via consume-artifact channels (§29.2), then consume it locally. The substrate's bounded-context property is what keeps each workspace's state-space manageable; cross-workspace direct-dispatch would defeat it.

### 29.5 Team discovery — convention-based, not registered

The current ecosystem is small enough that team discovery happens via convention + user-tier POLYBIUS's awareness:

- **Convention:** peer workspaces live as siblings in PRINCIPAL's `claude_projects/` directory (e.g., `claude_projects/the-stoa/`, `claude_projects/ariadne-core-workspace/`, `claude_projects/railway_stoa/`). A directory listing answers "what workspaces exist."
- **User-tier POLYBIUS awareness:** user-tier POLYBIUS, by virtue of its cross-project visibility per §7.3, maintains the cross-workspace mental map. When a project-tier seat asks "is there a peer workspace that has solved X?", user-tier POLYBIUS answers from accumulated knowledge.

No substrate-tier registry ships. The convention is sufficient for the current ecosystem size (5-10 workspaces); a future arc may add a registry if the convention proves insufficient at scale. Per A17, multi-team registry is HARD-LOCKED OUT of Arc 37; this section establishes the convention-based discovery as canon, not the registry.

### 29.6 N=1 provenance + accretion path

Anchor: `stoa--kt6, stoa--gq1` — N=1 provenance + accretion path. Per `MAJOR_POLYBIUS.md` §15 honest-scope and §6.7.1: PRINCIPAL declared this discipline 2026-05-13 (project-direction authority, captured at `stoa--kt6` ticket body — the 2026-05-13 substrate-architecture discussion). The discipline enters substrate canon off-gate on PRINCIPAL's project-direction authority, with future-evidence-accretion against the §6.7.1 gate still required for promotion to "structural lesson" status. Supporting evidence: N=multi de-facto cross-workspace coordination already in practice (prefix-namespaces; user-tier POLYBIUS as cross-project broker; peer-workspace artifact consumption); N=0 worked-when-applied with formal unified canon. `stoa--gq1` is the sibling many-projects-from-one-substrate composability finding. Recover via `bw show stoa--kt6` / `bw show stoa--gq1`.

### 29.7 Cross-references

- `operating-disciplines.md` §7.4 (Cross-tier coordination routing) — the within-team / cross-tier coordination convention. §29 extends the convention to the across-workspace layer.
- `operating-disciplines.md` §7.5 (Cross-tier write boundaries) — the no-upward-writes rule applies recursively at the workspace boundary; cross-workspace direct-dispatch is forbidden for the same structural reason.
- `operating-disciplines.md` §7.3 (Unified polling pattern) — user-tier POLYBIUS's cross-workspace visibility comes from the unified poll; §29.4's cross-team request channel is the operational consequence.
- `MAJOR_POLYBIUS.md` §5.1.1.1 (Cross-project sequencing context is user-tier-only) — the bounded-context property §29.4 preserves at the workspace boundary; cross-project sequencing leaks are the most-empirically-observed failure mode in this area.
- `MAJOR_POLYBIUS.md` §19 (NEW Arc 37 — Two-team architecture forge/shop) — the intra-workspace two-team layer §29 extends to multi-workspace.
- `operating-disciplines.md` §30 (NEW Arc 37 — Four-layer identity model) — sibling section; the identity-layer canon that travels with each workspace's deployed agents.
- `substrate/skills/check-substrate-updates/` — the artifact-consumption mechanism for substrate-tier updates from the-stoa to peer workspaces.
- Empirical anchors: `stoa--kt6` (2026-05-13 PRINCIPAL substrate-architecture discussion); `stoa--gq1` (many-projects-from-one-substrate composability finding — sibling pattern); the live ecosystem of the-stoa + ariadne-core-workspace + railway_stoa (in-practice anchor).
