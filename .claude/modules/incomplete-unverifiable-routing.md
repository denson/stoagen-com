# Dispatch protocol for INCOMPLETE and UNVERIFIABLE verdicts — instruction module

> Relocated from `MAJOR_PLINY.md` §5.6 (CONDITIONAL — read when a verifier returns INCOMPLETE or
> UNVERIFIABLE). Provenance: debloat Arc 48 cut `agents/design/arc-48/design-rev1.md` + epic
> `bw show stoa--xyb` / cut ticket `bw show stoa--xyb.10`. The slim-core residue is the §5.6 stub +
> routing-map row (verifier returns INCOMPLETE/UNVERIFIABLE) + relocation-index row in §4.2.

When a verifying CAPTAIN (VERA, CATO, ARGUS, ZENO) returns a verdict of **INCOMPLETE** or **UNVERIFIABLE** per the verification-complexity framework (`operating-disciplines.md` §15), PLINY routes by verdict shape — not by collapsing the new shapes back into PASS / FAIL.

**INCOMPLETE verdict received.**

- PLINY does NOT auto-close the ticket. INCOMPLETE is an operator-disposition state, not a ship verdict.
- PLINY surfaces the verdict's `coverage_description:` (what was checked, what was not, bound used, confidence interval) to POLYBIUS via beadwork comment on the dispatch ticket.
- POLYBIUS routes to PRINCIPAL for an operator-judgment-required decision, OR accepts the bound and authorizes proceed, OR requests deeper verification with an explicit higher budget (e.g., "re-run VERA with 100× probe budget; document in the verdict").
- The verdict does NOT gate merge on its own (per `operating-disciplines.md` §15.4 A6 LOCK). Both PASS and INCOMPLETE leave the ticket open until operator disposition.

**UNVERIFIABLE verdict received.**

- PLINY does NOT auto-close the ticket. UNVERIFIABLE is also an operator-disposition state.
- PLINY surfaces the verdict's `quadrant_classification:`, `sanity_check_performed:`, and `recommended_next_step:` to POLYBIUS.
- POLYBIUS routes to PRINCIPAL for operator judgment, OR accepts the risk with documented mitigation (e.g., "ship with the synthesis-claim wording narrowed; track UNVERIFIABLE assertion as deferred follow-up").
- UNVERIFIABLE also does not gate merge on its own.

**Why neither gates merge.** The discipline is that the verifier reports honestly rather than fail closed or run indefinitely. An INCOMPLETE verdict against a routine concurrency check is not a defect; an UNVERIFIABLE verdict against a load-bearing synthesis claim is not a defect either. Both surface decisions that belong with operator judgment. Routing them through PRINCIPAL via POLYBIUS is the gauntlet doing its job.

---

**DIVERGENT verdict received (from CAPTAIN_NOMOS).**

When CAPTAIN_NOMOS (the ground-truth auditor) returns **DIVERGENT** on an orchestrator output — an activation paste, arc-close, commit, or directive whose claims contradict the bw/git ground truth — PLINY does NOT propagate the output. It remediates by **re-decomposing the failed unit into smaller pieces and re-dispatching** (an orchestrator job — CAPTAINs can't nest). Compaction-derailment correlates with task size; small-enough tasks never compact, so splitting both fixes this instance AND tunes granularity for next time (the reaction teaches the prevention — `bw show stoa--xyb.5`). bw-as-memory makes fine decomposition cheap: unit state is read from bw, not carried in-head, so splits do not fragment context.

PLINY reads the `classification` of each divergence in the NOMOS verdict (§4.6 / §6.4 of `CAPTAIN_NOMOS.md` — the classification is produced AT the checker, with the checker's evidence) and routes per the three load-bearing guardrails:

- **SIZE-DERAIL** divergences → re-decompose the failed unit (**guardrail 1: only a size-derail is split** — the unit was too large, not wrong). BEFORE splitting:
  - **Guardrail 2 (attempt cap, re-derived not remembered):** COUNT the existing `[re-decompose attempt: k/2 — lineage <root-ticket-id>]` comments for this unit's lineage on its bw ticket — a bw READ, not a remembered integer, so a mis-incremented or skipped write self-corrects on the next read rather than compounding (robustness against the orchestrator's OWN compaction). If the count is already ≥ the cap (default **N=2**) → ESCALATE to PRINCIPAL via POLYBIUS, do NOT split. If the count read itself is UNVERIFIABLE (ticket unreadable) → ESCALATE, do NOT split (**fail-toward-escalation** — escalation surfaces to a human; over-splitting does not).
  - **Guardrail 3 (granularity floor):** if the unit is already at the floor — the point where its own dispatch brief + verdict would be longer than the work it describes — ESCALATE instead of splitting.
  - Otherwise: split, re-dispatch, and post a fresh `[re-decompose attempt: k/2 — lineage <root>]` comment on the ticket.
- **WRONG-SPEC / BLOCKED / IMPOSSIBLE** divergences → do NOT split (splitting a wrong-spec unit infinitely subdivides a task that can never pass). Surface to POLYBIUS → PRINCIPAL — the same operator-disposition path as INCOMPLETE / UNVERIFIABLE.
- DIVERGENT does NOT gate merge autonomously (consistent with the A6 LOCK above for INCOMPLETE / UNVERIFIABLE); it routes through operator judgment.

This keeps the new remediation INSIDE the existing verdict-routing protocol rather than bolting on a parallel path. Why the classification must come from a judgment agent and not a mechanical rule: the SAME surface divergence (a unit failed to complete) routes to *split* if it is a size-derail and to *escalate* if it is wrong-spec — only judgment distinguishes them, which is why NOMOS is a CAPTAIN (`CAPTAIN_NOMOS.md` §6.4) and not a skill.

---

Cross-refs: `operating-disciplines.md` §15 (the framework); `CAPTAIN_VERA.md` §5.7 (VERA's quadrant discipline); `CAPTAIN_CATO.md` §6.7; `CAPTAIN_ARGUS.md` §6.6; `CAPTAIN_ZENO.md` §6.6; `CAPTAIN_NOMOS.md` §4/§7 (the DIVERGENT verdict shape + the per-divergence `classification` field this branch routes on).
