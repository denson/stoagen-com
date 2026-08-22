# Credential-flow design discipline — instruction module

> Relocated from `CAPTAIN_DAEDALUS.md` §6.6 (CONDITIONAL — read when a design brief involves
> credentialed operations against any third-party API or cloud service). The "load-bearing" heading
> describes the SEVERITY when the task-type fires, not the FREQUENCY — a typical feature/refactor/
> debloat design touches no credentials and never reads this module. The always-on universal credential
> canon lives at `operating-disciplines.md` §20 (a different file, unaffected by relocating this
> design-time application). Provenance: composition-layer spec `bw show stoa--xyb`; debloat Arc 6
> (Arc 49) cut `agents/design/arc-49/design-rev1.md` / cut ticket `bw show stoa--xyb.11`. The slim-core
> residue is the §6.6 stub + the `<!-- MODULE-INLINE:credential-flow-design -->` marker + relocation-
> index row in `CAPTAIN_DAEDALUS.md` §6.0.

### 6.6 Credential discipline (load-bearing for designs that touch credentialed ops)

When a brief involves credentialed operations against any third-party API or cloud service (Railway, gcloud, gh, op, aws, azure, kubectl, vercel, fly — any CLI or HTTP API gated by an API token, OAuth scope, or service account), the design MUST specify a CI-mediated path. Never "agent runs CLI X with credentials"; always "agent authors workflow that does X; CI runs the workflow." The substrate canon is `operating-disciplines.md` §20; the worked example skill is `substrate/skills/credential-discipline/SKILL.md` — read both before drafting the design's credential-flow section.

A design that proposes any of the five rejected anti-patterns (per-call `op`, file-on-disk credential, parent-shell env injection, `op run` wrapper at Claude Code launch, local MCP-server-as-credential-broker — full list at §20.2) fails the pre-gate; if the brief implicitly requires one, refuse back to MAJOR_PLINY with the gap named. The discipline is structural, not stylistic: the five anti-patterns have all been empirically tested and rejected on PRINCIPAL's load-bearing rule that any credential in agent-reachable scope eventually surfaces.

The design's verification probes section (per §3) MUST include at least one probe that confirms the design's CI-mediated structure (e.g., "workflow YAML contains `permissions: id-token: write`" or "no credentialed CLI calls appear in any ADA-built script"). This makes the structural property checkable by VERA rather than implicit in prose.
