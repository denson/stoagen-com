# Four-layer identity model — role file / memories / handoff / bw substrate — instruction module

> Relocated from `operating-disciplines.md` §30 (CONDITIONAL — read when a seat needs the
> identity-layer model: memory-introspection, memory-authoring, generational handoff, or
> cross-layer composition). Provenance: composition-layer spec `bw show stoa--xyb.4`; debloat
> Arc 47 cut `agents/design/arc-47/design-rev2.md` + epic `bw show stoa--xyb` / cut ticket
> `bw show stoa--xyb.8`. The slim-core residue is the §30 stub + relocation-index row in
> `operating-disciplines.md` §0.5. The §30.5 N=1 provenance compresses to `Anchor: stoa--wad`
> (recover via `bw show`).

A Stoa-deployed agent's identity has FOUR layers, each with distinct content and distinct variance across users and projects. Identity is not a single property; it is the composition of the four layers. Different PRINCIPALs interacting with the same deployed substrate produce different agent behaviors because the four layers compose differently — and that is the alignment mechanism working correctly, not noise to normalize away.

### 30.1 The four layers

| Layer | Content | Variance | Persistence |
|---|---|---|---|
| **Role file** | What KIND of agent the seat is (POLYBIUS / PLINY / CAPTAIN_<MNEMONIC>); seat responsibilities, disciplines specific to the seat, voice notes | Universal across users and projects | Permanent on disk; loaded every session |
| **Memories** | Standing PRINCIPAL preferences, accumulated lessons, project-specific knowledge | UNIQUE per PRINCIPAL / per project | Permanent on disk at `~/.claude/CLAUDE.md` (user-tier) + project `.claude/CLAUDE.md` / `MEMORY.md` (project-tier); accumulated by interaction |
| **Handoff** | Current work-state for session continuity — what's in flight, what's just-closed, what immediate decision the next session faces | Unique per engagement | Periodic, manually authored at `HANDOFF_<role>_<date>.md` per the `handoff-author` skill (`substrate/skills/handoff-author/SKILL.md`) |
| **bw substrate** | Durable detail (tickets, history, comments, verdict trails) | Unique per project | Durable across sessions on the `beadwork` orphan branch (per §12 + §9) |

The role file is the same for every deployment of a given seat — every POLYBIUS reads the same `MAJOR_POLYBIUS.md` at load. The memories are what make THIS POLYBIUS serve THIS PRINCIPAL effectively. The handoff is the continuity-of-identity layer across compactions and session boundaries. The bw substrate carries the durable detail no in-context layer could afford to inline.

### 30.2 Memories are the user-alignment layer

Different PRINCIPALs → different memory accumulations → different agent behaviors. This is the alignment mechanism working correctly. The substrate supports memory accumulation as a first-class feature, not as noise to normalize away.

Concretely:

- **Memory introspection is supported.** When PRINCIPAL asks "what do you remember about me?" or "what do you know about this project?", the agent returns a curated answer FROM accumulated memories rather than confabulating from the in-context window or pattern-matching against generic knowledge. The agent reads the memory files, summarizes the load-bearing entries, and surfaces what it actually knows.
- **Memory authoring is collaborative.** PRINCIPAL correction + expansion of memories is a normal action, not exceptional. When PRINCIPAL says "remember that I prefer X" or "you should know that Y about this project," the agent updates the appropriate memory file (user-tier or project-tier per scope). When the agent observes a pattern worth canonizing as a standing preference, the agent surfaces a candidate memory edit for PRINCIPAL ratification before landing it.
- **Memories travel with agent identity.** Memories persist across compactions, project-team modifications, and session boundaries. A new POLYBIUS spinning up (per `MAJOR_POLYBIUS.md` §16 Mode 2) inherits the same memory accumulation as the prior session — what changes is the role-file content the new session loaded fresh, not the alignment layer.

The memory layer is what distinguishes a Stoa-deployed agent serving Denson Smith from a Stoa-deployed agent serving any other PRINCIPAL: the role files are identical, the bw substrate is project-specific but not PRINCIPAL-specific in shape, the handoff is engagement-specific; the MEMORIES are where PRINCIPAL-alignment lives.

### 30.3 Cross-layer interactions

The four layers interact in ways future seats need to understand:

- **Base team designing project team (per `MAJOR_POLYBIUS.md` §19).** When the base team authors project-specific customizations, the project team inherits memory-access conventions from the base team. The project team's POLYBIUS reads the same user-tier memories at `~/.claude/CLAUDE.md` (because all Stoa-deployed agents have user-tier memory access), plus the project team accumulates its own project-tier memories.
- **Handoff captures within-session state; memories capture cross-session standing knowledge.** A handoff doc (per the `handoff-author` skill at `substrate/skills/handoff-author/SKILL.md`) references memories without restating them — "see `feedback_radio_check_pattern_for_polybius_coordination.md` for the discipline applied here." Citing-not-duplicating is the discipline that keeps the four layers compositional; if a handoff inlined every memory, the handoff would become a transcript and the value-per-token property the handoff-author skill names would be lost.
- **bw substrate carries durable detail neither memories nor handoff can hold.** Memories carry standing preferences ("PRINCIPAL prefers fix-now over defer-later"); bw carries the per-engagement detail (ticket bodies, comment trails, arc histories, verdict records). When the agent needs to recall a specific past arc, the agent reads bw; when the agent needs to know how to act, the agent reads memories.
- **Role file is the universal substrate identity.** Every POLYBIUS reads the same `MAJOR_POLYBIUS.md`; every CAPTAIN_DAEDALUS reads the same `CAPTAIN_DAEDALUS.md`. The role file is what makes a seat a seat; the other three layers are what make THIS instance of the seat effective for THIS PRINCIPAL in THIS project.

### 30.4 Generational lineage — memories persist across generations

When a POLYBIUS or PLINY session ends and a successor session spins up (Mode 2 per `MAJOR_POLYBIUS.md` §16 — fresh session with new role-file load), the successor inherits memories automatically (they live on disk; the new session loads them via `~/.claude/CLAUDE.md` auto-load + project `.claude/CLAUDE.md`). The role file is reloaded fresh. The handoff is the bridge — the successor reads `HANDOFF_<role>_<date>.md` to orient on work-state per the `handoff-author` skill (per `substrate/skills/handoff-author/SKILL.md`, including the lineage-recording section that captures the prior generation's session id for `/resume` capability).

The four-layer model is what makes generational continuity work: the role file gives the successor universal identity; the memories give the successor PRINCIPAL-alignment; the handoff gives the successor work-state continuity; the bw substrate gives the successor full project history on-demand. None of the four layers alone is sufficient; together they make the agent semi-persistent (per the `handoff-author` skill's framing).

### 30.5 N=1 provenance + accretion path

Anchor: `stoa--wad` — N=1 provenance + accretion path. Per `MAJOR_POLYBIUS.md` §15 honest-scope and §6.7.1: PRINCIPAL declared this discipline 2026-05-13 (project-direction authority, captured at `stoa--wad` ticket body — the 2026-05-13 substrate-architecture discussion, verbatim PRINCIPAL framing on memories-as-alignment-feature). The discipline enters substrate canon off-gate on PRINCIPAL's project-direction authority, with future-evidence-accretion against the §6.7.1 gate still required for promotion to "structural lesson" status. Supporting evidence: N=0 bit-by-it of failure (no specific empirical anchor of memory-not-as-alignment failure mode); N=multi de-facto four-layer pattern in practice across every deployed agent; N=0 worked-when-applied with formal four-layer canon. Recover via `bw show stoa--wad`.

### 30.6 Cross-references

- `MAJOR_POLYBIUS.md` §16 (POLYBIUS session lifecycle) — the §16 lifecycle disciplines (Mode 1 / Mode 2 / Mode 3 as named in §16.2 — the relay-channel lifecycle taxonomy, distinct from §10's HITL/Autonomous engagement axis) operate over the four-layer model; §16 names HOW sessions cross boundaries; §30 names WHAT crosses them.
- `MAJOR_POLYBIUS.md` §19 (NEW Arc 37 — Two-team architecture forge/shop) — the two-team architecture composes with the four-layer identity model: each team's deployed agents have their own four-layer identity; the base team accumulates substrate-shaped memories, the project team accumulates project-shaped memories.
- `operating-disciplines.md` §29 (NEW Arc 37 — Multi-team interoperation) — at the across-workspace layer, each workspace's deployed agents have their own four-layer identity; the four layers are workspace-scoped (except user-tier memories at `~/.claude/CLAUDE.md`, which are PRINCIPAL-scoped across all workspaces).
- `~/.claude/CLAUDE.md` (global, on PRINCIPAL's machine) — the user-tier memory layer; auto-loaded into every Claude Code session per Claude Code docs.
- `substrate/skills/handoff-author/SKILL.md` (NEW Arc 37 — C6) — the handoff-author skill is the operational shape of §30.3's handoff layer; its "cite, don't duplicate" principle is what keeps handoffs from collapsing into memory-restatements.
- `operating-disciplines.md` §10 NEW Arc 37 additions (operating-mode progression — bolded-paragraph extensions inside §10's body; see C4) — the lifecycle disciplines operate across all four layers; the §10 transition-triggers paragraph fires on signals readable from any layer.
- Empirical anchors: `stoa--wad` (2026-05-13 PRINCIPAL substrate-architecture discussion); `~/.claude/CLAUDE.md` itself (the accumulated user-tier memory at the-stoa is the canonical in-practice anchor for what memory-accumulation looks like).
