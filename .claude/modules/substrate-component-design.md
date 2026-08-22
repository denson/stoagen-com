# Substrate-component design principles for agent-installable distribution — instruction module

> Relocated from `operating-disciplines.md` §31 (CONDITIONAL — read when authoring substrate-component
> distribution/onboarding materials and weighing the agent-installable distribution model +
> composability framing). Provenance: composition-layer spec `bw show stoa--xyb.4`; debloat Arc 47
> cut `agents/design/arc-47/design-rev2.md` + epic `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.8`.
> The slim-core residue is the §31 stub + relocation-index row in `operating-disciplines.md` §0.5.
> The §31.3 N=2 provenance compresses to `Anchor: stoa--gq1` (recover via `bw show`).

<!-- cite: HUMAN_relay_user_polybius_ariadne_distribution_and_mcp_2026-05-13 (ariadne-core-workspace) Findings 2 + 3; stoa--gq1 ticket body; SPECIFICATION.md §13.5 Pass 4 / Arc 38 enumeration -->

A substrate component is any artifact a peer workspace consumes from a producer workspace via `install.sh`-style or skill-copy-style deploy. The Stoa substrate itself (deployed from `the-stoa` via `install.sh`) is the canonical instance; Ariadne Core (the semantic-search infrastructure originated by ariadne-core-workspace) is the second. Future substrate components — Railway-deploy skills produced by `railway_stoa`; the inspection-agent pattern per §27; component-author skills per future arcs — follow the same shape.

This section names two design principles that apply to any agent-installable substrate component: the agent-installable distribution model (Principle 1) + the composability framing (Principle 2). Both surfaced empirically — Principle 1 from PRINCIPAL's 2026-05-13 Ariadne distribution-shaping conversation (HUMAN_relay_user_polybius_ariadne_distribution_and_mcp_2026-05-13 Findings 2 + 3); Principle 2 from the same conversation's "many wirings of one substrate" framing. Stoa-substrate-as-shipped-via-install.sh is a parallel empirical instance (N=2 per §31.3); the principles abstract across both.

### 31.1 Principle 1 — Agent-installable distribution model

<!-- cite: HUMAN_relay file (verbatim 7-step formulation) -->

The user-experience flow for any agent-installable substrate component:

1. **User encounters component** (URL via word-of-mouth, a published demo, a shared link).
2. **User pastes URL to their AI** (Claude Code, ChatGPT, etc.).
3. **User asks the AI: "do I need this?"** (the diagnostic question — fit-to-domain, not feature-tour).
4. **AI fetches the repo's README + AGENTS.md + skills/ materials** (the agent-facing landing surface).
5. **AI evaluates against the user's domain** (cross-checking the user's accumulated memories — see §30 four-layer identity — against the component's stated fit criteria).
6. **AI returns yes / no / try-the-demo recommendation** (with rationale citing fit-vs-domain or domain-mismatch).
7. **If yes + user consent: AI installs + runs demo** (the consent moment is a §25 PRINCIPAL-gate; the install + demo are bounded mechanical operations the agent runs once authorized).

The AI is the primary reader at the component's repo; the human is the decision-authority who acts on the AI's recommendation. Repo-shape implications follow from this primary-reader inversion: README stays human-readable but adds a top-of-page pointer routing agents to AGENTS.md (or equivalent agent-facing landing file); AGENTS.md is the canonical agent-facing decision-support landing (fit criteria, install cost, skill inventory, recommendation templates, hard rules); an invitation-style skill handles the "do I need this?" diagnostic conversation; a walkthrough skill handles post-install hands-on demo.

**Worked instance — Stoa substrate-as-component.** The Stoa substrate (this very deployable) follows the same flow: a user encounters the-stoa via the canonical URL; pastes it to their AI; asks "do I need this?"; the AI fetches `SKILL.md` + `CLAUDE.md` + the case-study materials; evaluates against the user's domain (substrate-team-coordination work? AI-agent-as-collaborator pattern in active use?); returns yes / no / try-the-visual-tour; on yes + consent, runs `install.sh --target user` or `--target project`. The repo-shape implication: `SKILL.md` at repo root routes agents to `skills/stoa-intro/SKILL.md` (visual tour) or `skills/install-stoa/SKILL.md` (guided install) or the case study — exactly the 7-step shape.

**Worked instance — Ariadne Core distribution.** Ariadne Core's distribution flow at the ariadne-core-workspace produces the same shape: user-encounters; paste-URL; ask-fit; AI-fetches AGENTS.md + the skills/ materials; AI-evaluates against domain (factory-manager? healthcare? SRE? legal?); AI-returns recommendation; consent + install + demo. The HUMAN_relay_user_polybius_ariadne_distribution_and_mcp_2026-05-13 thread is the load-bearing source.

### 31.2 Principle 2 — Composability framing

<!-- cite: HUMAN_relay file (verbatim composability framing) -->

Breadth of a substrate component is composability, not demo-inventory.

The claim "this substrate supports many projects" is a COMPOSABILITY claim — one substrate, many wirings — NOT a BREADTH-OF-DEMOS claim — "look, here are five demos showing five separate use cases." The first claim is what makes a substrate component valuable to a new user (their use case can be a NEW wiring, not a copy of a demonstrated one); the second claim ages out the moment the user's use case differs from any demo.

Concretely: **Ariadne Core** supports the factory-manager demo but ALSO supports healthcare / SRE / legal / journalism / audit / cyber by the same substrate WIRED DIFFERENTLY. **One install, many shapes.** The right way to surface breadth is to demonstrate the wiring surface (e.g., the per-domain skills + the per-domain memory accumulation patterns); the wrong way is to ship five demos and let the reader infer composability from coverage.

**Concretely for the Stoa substrate** (the parallel instance): one install of the substrate supports many project shapes — the-stoa's own substrate-meta work, ariadne-core's semantic-search domain, railway_stoa's deploy-tooling domain, sector-4's future domain. The substrate composes across project shapes via the base-vs-custom convention (§23 + `MAJOR_POLYBIUS.md` §17) plus the two-team forge/shop architecture (`MAJOR_POLYBIUS.md` §19). The breadth claim for the Stoa substrate is "one substrate, deploys via install.sh, wires to your domain through customization conventions" — NOT "see, we have N demo projects."

**Architectural implication for substrate-component authoring:** when authoring substrate-component marketing/onboarding materials (READMEs, AGENTS.md, skills/, demo links), frame breadth as composability (one substrate, many wirings) not as demo inventory (here are five demos). The composability framing both ages slower (a new domain composes without new demos) and signals correctly (the substrate IS the breadth, not the demos).

### 31.3 Empirical anchors — N=2 honest scope

<!-- cite: §6.7.1 N=1 canon-promotion gate; sibling §29.6 + §30.5 N=1/N=2 framing precedent -->

Anchor: `stoa--gq1` — N=2 honest scope. Per §6.7.1 honest-scope: this section enters substrate canon off-gate on PRINCIPAL's project-direction authority (2026-05-13 Ariadne distribution-shaping conversation, captured at HUMAN_relay_user_polybius_ariadne_distribution_and_mcp_2026-05-13 Findings 2 + 3). The discipline enters canon off-gate on PRINCIPAL's authority, with future-evidence-accretion against the §6.7.1 gate still required for promotion to "structural lesson" status.

Supporting evidence at the time of this writing:

- **N=1 — Ariadne Core distribution (originating empirical anchor).** PRINCIPAL's 2026-05-13 conversation surfaced both principles in the context of authoring Ariadne Core's distribution materials. The 7-step agent-installable flow + composability-over-demo-multiplication framing are PRINCIPAL's verbatim formulations (per the HUMAN_relay file).
- **N=2 — Stoa substrate distribution (parallel empirical anchor).** The Stoa substrate itself follows the same shape, observable at the the-stoa repo: `SKILL.md` at repo root routes agents to invitation skills + install skill; `install.sh` provides the bounded mechanical install per Principle 1 step 7; the substrate composes across projects via base-vs-custom + two-team architecture per Principle 2. The Stoa-substrate instance PRE-DATES the Ariadne instance (the-stoa shipped install.sh in earlier arcs; Ariadne adopted the agent-installable shape after observing the-stoa's pattern), making it an INDEPENDENT instance rather than a derivative of the Ariadne anchor.

N=2 is the honest count. Both instances are observable in the current ecosystem; the principles abstract across both. Promotion to "structural lesson" status with multi-instance + controlled-comparison + substrate-level-pattern evidence remains future-arc work; future substrate components (Railway-deploy skills + future component-author skills) accrete additional N as they ship. Recover via `bw show stoa--gq1`.

### 31.4 Cross-references

- **§29 (Multi-team interoperation)** — substrate components ARE the artifacts that flow between teams per §29.2. §31 names the design principles; §29 names the runtime topology those principles operate within.
- **§23 (Base vs custom agents — universal-team framing)** + **`MAJOR_POLYBIUS.md` §17 (POLYBIUS-tier statement of the same canon)** — co-equal canon for the base-vs-custom architectural model, both anchored at their respective §X.1 source-of-truth subsections to PRINCIPAL's 2026-05-17 declaration captured at `stoa--ads`. The two are paired cuts of one canon (universal-team cut + POLYBIUS-tier cut), not a base + derivative; cite both together per the established install.sh cite-comment precedent (install.sh lines 836-837 / 865-866 / 893-894). Substrate components ship a BASE that consumers can CUSTOMIZE per the per-class path convention. The composability framing (§31.2) leans on the base-vs-custom split: substrate component = the base; per-project wiring = the custom.
- **§27 (Mechanical-script / agent-inspection split)** — the script-then-agent pattern IS a substrate-component pattern; the inspection-agent layer (per §27.5) is itself a deliverable that ships in `substrate/skills/inspect-script-output/`. Principle 2 composability framing applies: the pattern composes across script-based workflows (substrate-update flow today; future flows as the pattern proves out).
- **§28 (Co-Authored-By trailer — substrate-component attribution)** — substrate-component authorship attribution at the commit-trailer layer follows §28; file-frontmatter attribution per §28.4 stays Denson Smith (or per-project PRINCIPAL).
- **§30 (Four-layer identity model)** — substrate components ship the **role file** layer (the universal substrate identity layer); the **memories** layer is PRINCIPAL-accumulated per-deployment; the **handoff** layer is per-engagement; the **bw substrate** layer is per-project. Principle 1's 7-step flow operates against all four layers (the AI evaluating "do I need this?" at step 5 reads against the user's accumulated memories per §30.2).
- **HUMAN_relay_user_polybius_ariadne_distribution_and_mcp_2026-05-13** (the load-bearing source; ariadne-core-workspace) — Findings 2 + 3 carry PRINCIPAL's verbatim formulations of both principles.
- **`stoa--gq1`** (this section's originating ticket).
- **`stoa--vmc`** (Arc 23, closed) — sibling substrate-canon principle (bw-fit matrix); related shape (which substrate for which use-case).
- **`SPECIFICATION.md` §13.5** (the Pass 4 / Arc 38 enumeration) — this section's place in the workplan.
