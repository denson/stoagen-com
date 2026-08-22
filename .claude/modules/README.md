# Instruction modules — composition-layer reference

This directory holds **instruction modules**: composable, on-demand reference content an
orchestrator (POLYBIUS / PLINY) delivers to a sub-agent **at dispatch time**. It is the
detailed reference for the composition layer; the always-loaded one-paragraph rule lives at
`operating-disciplines.md` §33. Read this file when you are authoring a module, relocating
role-file content into the composition layer, or populating an orchestrator's routing map /
relocation index.

This file is itself a deployed module (it lands at `.claude/modules/README.md` after
`install.sh` runs) — the canon's detail is loaded the same on-demand way every other module's
detail is. That dogfood is deliberate: it keeps the always-loaded §33 rule thin.

> Provenance: composition-layer spec `bw show stoa--xyb.4`; 3-bucket debloat method + 3-tier
> content model `bw show stoa--xyb.3`; CLI-not-MCP delivery channels `bw show stoa--xyb.1`;
> skill-grant / agent-caching findings `bw show stoa--xyb.2`. Shipped Arc 44 (debloat Arc 1).

---

## 1. What a module is (and is not)

Instructions are a **composable library, not an all-memorized monolith**. An orchestrator
selects what a task needs and delivers exactly that, fresh, at spawn. A module is a stable,
reusable instruction body worth keeping on disk and naming from a dispatch.

A module is NOT:
- a one-off instruction the orchestrator composes fresh for a single dispatch (that is CHANNEL 1, inline);
- a dynamic / bespoke / must-persist artifact (that is CHANNEL 3, bw);
- the routing map or relocation index themselves (those stay inline in orchestrator core — §4, NEVER a module).

**Compaction-proofness — the reason the layer exists.** Module *selection* rides the dispatch
payload, delivered fresh at spawn, so a sub-agent always receives its modules even though its
own context may later compact. Known weak spot: a sub-agent that compacts *mid-task* has no
orchestrator re-telling it. Mitigation: keep sub-agent tasks bounded (ties to the future
enforcement layer, `bw show stoa--xyb.5`).

---

## 2. The three delivery channels + selection guidance

All three use tools every agent already has — **Bash / Read / bw**. No Skill grant, no MCP
(settled in `stoa--xyb.1`). The orchestrator picks a channel per the table:

| Channel | Mechanism | Use when | Persists? |
|---|---|---|---|
| **1. inline** | text in the dispatch prompt | small, task-specific, one-off instruction the orchestrator composes fresh | only in that dispatch payload |
| **2. disk module** | `.claude/modules/<X>.md` via `Read <path>` | stable instruction reused across tasks / projects; orchestrator names the path in the dispatch | yes — versioned in substrate |
| **3. bw ticket** | `bw show <id>` / `bw attach <id> <file>` | dynamic / bespoke / single-use, OR anything that must persist or be shared across seats; ALSO the PROVENANCE archive home (§5) | yes — in bw, sharing-topology we control |

**bw FEEDS the library; it is not the library.** The bw custom-instruction stream (CHANNEL 3)
is the routine, constantly-generated record of every custom instruction an orchestrator emits,
retained for record-keeping — NOT a curated module store. Do not misread "bw" as "the module
store." Recurrence in that stream is the SIGNAL to promote an instruction to a CHANNEL-2 disk
module (§3).

**CHANNEL 3 has a dual role:** it is BOTH the live custom-instruction stream AND the PROVENANCE
archive destination (§5). These are two uses of the same bw substrate, not a contradiction.

---

## 3. Module-authoring discipline (recurrence → author a module)

The accretion path that grows the library over time. Under glob deploy (install.sh discovers
`substrate/modules/*.md`), authoring a module needs **no install.sh edit**:

1. Notice the SAME instruction recurring across multiple dispatches in the bw custom-instruction record.
2. Author `substrate/modules/<name>.md` (the reusable form).
3. Redeploy via `install.sh` — the glob auto-discovers the new file. **No install.sh edit.**
4. Add a routing-map row (`task-type → <name>.md → disk`) and, if the module relocates inline
   content, a relocation-index row, to the relevant orchestrator's core (§4).

Glob deploy (not an explicit manifest array) is chosen precisely so step 3 costs zero
install.sh edits on the file class the epic is designed to grow continuously — eliminating the
silent failure mode of an array (author a module, forget the array line, it never deploys, no
error). Convention: only real modules live in `substrate/modules/*.md` (the same single-dir
discipline that governs `templates/` and `skills/`).

---

## 4. Routing map + relocation index (orchestrator core — always loaded — NEVER a module)

Two small structured markdown tables the orchestrator carries **inline in its slim core**, both
always-loaded. They serve different questions and are kept as **two distinct tables** (do not
merge — see the rationale below). An index that must itself be loaded-on-demand never fires,
which is why both stay in always-loaded core.

### 4.1 Routing map (dispatch-time)

Answers *at dispatch time, what does this task need?* Columns: **task-type → module(s) to load → channel**.

```markdown
### Routing map (orchestrator core — always loaded — dispatch-time)

| Task type | Module(s) to load | Channel |
|---|---|---|
| <onboard a new project>      | `onboarding.md`                | disk (Read) |
| <spawn a sub-project>        | `sub-project-spawning.md`      | disk (Read) |
| <author a pair-programmer>   | `pair-programmer-authoring.md` | disk (Read) |
| <one-off bespoke task>       | (compose inline)               | inline |
| <must-persist shared spec>   | `bw show <ticket-id>`          | bw |
```

### 4.2 Relocation index (audit-time)

Answers *where did the content that used to be here go?* Columns: **relocated content → new home → class**.
The `Class` column makes all three relocation classes (§5) first-class index entries a reader
or orchestrator can follow to recover any moved content.

```markdown
### Relocation index (orchestrator core — always loaded — audit-time)

| Relocated content (was here) | New home | Class |
|---|---|---|
| §5 Onboarding flow            | `onboarding.md` (disk module)            | CONDITIONAL |
| §16.6 N=1 provenance          | `bw show stoa--dxw` (Anchor cite)        | PROVENANCE  |
| §7.3 bw cookbook (dupe)       | op-disc §12 (consolidated; pointer kept) | DUPLICATE   |
```

### 4.3 Why two tables, not one

- The routing map is consulted at **dispatch time** to compose a payload; the relocation index
  at **audit / recovery time** to find moved content.
- The cardinalities differ: one task may load several modules; one relocated section may serve
  several task-types; **PROVENANCE and DUPLICATE relocations have no dispatch-time task-type at
  all**. Forcing them into the dispatch-time routing map (a single merged table) is exactly what
  makes PROVENANCE/DUPLICATE inexpressible — a merged class-column table carries empty cells per
  row. Two tables is why all three classes get a home.
- Both column shapes are deliberately **regular** (routing: task-type/module/channel; index:
  content/home/class) so a future enforcement-layer hook (`stoa--xyb.5`) is parseable. Arc 1
  does NOT build the hook — it designs the formats so the hook is possible.

**Keep index rows terse (one line each)** so the index does not re-bloat what a cut removes.
The whole point is that a few dozen always-loaded index rows enable removing hundreds of
always-loaded content lines — a strongly net-negative line count.

---

## 5. The three relocation classes (lossless home per debloat bucket)

The `.3` debloat method (`bw show stoa--xyb.3`) names three kinds of bloat, each with a
different lossless home. This is the composition layer's contract with the role-file cut:

| Class | Bucket (what it is) | Lossless home | Cite-back in slim core |
|---|---|---|---|
| **CONDITIONAL** | needed only sometimes | disk module `.claude/modules/<X>.md` (CHANNEL 2) | routing-map row (task-type → module → disk) |
| **PROVENANCE** | why a rule exists / the N=1 story / cross-refs | bw ticket (CHANNEL 3) | one-line `Anchor: <bw-id>` + relocation-index row |
| **DUPLICATE** | same content in 2–3 homes | the EXISTING single keep-target — NO module | one-line pointer at each deleted site + relocation-index row |

### 5.1 CONDITIONAL → disk module

Content needed only for certain task types relocates to a disk module the orchestrator names at
dispatch. The slim-core cite-back is a routing-map row. Worked template: see §4.1.

### 5.2 PROVENANCE → bw, cited not inlined

Provenance — *why a rule exists*, the empirical N=1 story, the accretion path — is read rarely
(only when someone asks *why does this rule exist*), is inherently historical (tied to a ticket
+ a date), and bw is already the substrate's durable cross-session record. So provenance
relocates to bw and is **cited, not inlined**. A disk module would be the wrong home: modules
are for CONDITIONAL operational content dispatched at spawn; provenance is not dispatched, it is
recovered.

Two sub-cases by where the prose currently lives:

- **(C-1) Already-in-bw provenance (the common case).** Most provenance prose ALREADY names its
  bw ticket (the disciplines cite `u--7yg.X` / `stoa--X` inline). The bw ticket already IS the
  durable home. The cut is: **delete the verbose inline prose, keep a one-line cite-back**.
  Nothing is archived — it is already in bw.
- **(C-2) Not-yet-in-bw provenance.** Where verbose prose has NO bw home, **archive it to bw
  FIRST**, then delete the inline copy and keep the cite-back. This guarantees losslessness: the
  bytes live in bw before the inline copy is removed. Archive via:
  - `bw attach <ticket-id> <file-path> [--name <stored-path>]` for a file (stores bytes at
    `attachments/<ticket-id>/<stored-path>` on the beadwork ref; commits a one-line intent), or
  - `bw comment <ticket-id> "<prose>"` for short prose rather than a file.

**REQUIRED losslessness gate for the C-1 common case (probe-requirement carried into the cut):**
before deleting any "already-in-bw" (C-1) inline provenance prose, run `bw show <cited-id>` and
**content-check that the cited ticket actually contains the full story** the inline prose
carries. A C-1 classification that is wrong — the ticket does NOT actually carry the deleted
detail — silently drops content. This `bw show` content-check turns the C-1 judgment call into a
checkable gate; it MUST run per-deletion before any inline prose is removed.

**Cite-back format (slim-core, what survives the cut):** a one-line `Anchor:` cite at the point
the provenance used to be inline:

```
Anchor: <bw-id>[, <bw-id>...]  — N=1 provenance + accretion path. Recover via `bw show <id>`.
```

Recovery:
- For provenance kept inline-in-a-ticket via `bw comment` (or already-in-bw, C-1): `bw show <id>`
  shows the comment stream.
- For a file archived via `bw attach` (C-2): the bytes live at `attachments/<ticket-id>/<stored-path>`
  on the beadwork git ref. `bw` 0.13.0 has no attachment-read subcommand and `bw show` has no
  `--attachments` flag, so first discover the stored path via `git log beadwork` — the `attach` intent
  is recorded only as a commit message on the beadwork ref (form: `attach <ticket-id> <stored-path>`),
  not surfaced by `bw show <id>` — then recover the bytes via git on that ref (e.g. `git show
  beadwork:attachments/<ticket-id>/<stored-path>`).

For cross-references that point at OTHER substrate sections (e.g. `§X` / `operating-disciplines.md
§Y`), keep the existing in-file pointer convention — those are live cross-refs, not provenance to
archive. Only the verbose *story* moves to bw.

### 5.3 DUPLICATE → consolidate to one existing home + pointer

When the same content lives in 2–3 places, consolidate to the ONE existing keep-target and leave
a one-line pointer at each deleted site. **The DUPLICATE class is explicitly NOT a module** — the
home is an EXISTING section; no new file is authored, no `substrate/modules/` entry is created.
The relocation is purely: delete the dupe + leave a one-line pointer at each deleted site + add a
relocation-index row.

Worked example (the canonical case): the bw cookbook is triplicated. Keep-home is
**`operating-disciplines.md` §12** (the fullest copy); the two copies at `MAJOR_POLYBIUS.md §7.3`
and `MAJOR_PLINY.md §6.1` are deleted and replaced with a one-line pointer to op-disc §12.

---

## 6. Planned Arc-2 CONDITIONAL module taxonomy (NAMED only — no content here yet)

Arc 1 NAMES the CONDITIONAL module files Arc 2 will populate (so Arc 2 is a clean fill-in) but
creates NO content file for any of them. The only real content file Arc 1 ships under
`substrate/modules/` is this README. The named homes, grounded against the shipped
`MAJOR_POLYBIUS.md` section headers:

| Planned module file | Relocates MAJOR_POLYBIUS § (shipped header) | Status |
|---|---|---|
| `onboarding.md` | §5 Onboarding flow | NAMED only |
| `sub-project-spawning.md` | §10 Sub-project spawning | NAMED only |
| `pair-programmer-authoring.md` | §11 Pair-programmer Major authoring | NAMED only |
| `pair-programming-prototyping.md` | §12 Pair-programming-for-prototyping methodology (Mode 2) | NAMED only |
| `substrate-update-check.md` | §14 Substrate-update check (daily cadence) | NAMED only |

§11 and §12 are kept as **two distinct module homes** because the shipped file has them as two
distinct sections (§11 authoring; §12 prototyping methodology). If Arc 2 finds them tightly
coupled it may merge to one — two homes is a superset of one. No content files for any of these
are created in Arc 1.

---

## 7. Subproject-tier deploy — TRACKED Arc-2-gating open question

Arc 1 deploys + verifies modules at **user + project tiers** only. Subproject-tier module deploy
is deferred: Claude Code's Read-tool relative-path resolution for a sub-agent in a subproject is
web-confirmed contested as of early 2026 (claude-code #24987 / never-fixed #2571 lineage /
#4754 / #15627 / #18200 / #11374), and the skills-subproject precedent is about Skill-TOOL
discovery, not Read-TOOL explicit-path resolution — so it does not transfer. `install.sh` sets
`DEST_MODULES_DIR=""` in subproject mode (deploy skipped), mirroring the templates pattern.

Before any Arc-2+ subproject orchestrator relies on a disk-module path, a LIVE probe must
confirm `Read .claude/modules/<X>.md` resolves to the SUBPROJECT's `.claude/modules/`. Until
then, Arc-2 subproject orchestrators MUST use CHANNEL 1 (inline) or CHANNEL 3 (bw) for
module-equivalent content, NOT CHANNEL 2.

---

## 8. Cross-references

- `operating-disciplines.md` §33 — the always-loaded thin rule this file is the on-demand detail for.
- `operating-disciplines.md` §12 — the bw cookbook (the DUPLICATE keep-home; §5.3).
- `MAJOR_POLYBIUS.md` §16.8 — the `bw attach` primitive (the PROVENANCE C-2 archive mechanism; §5.2).
- `MAJOR_PLINY.md` §5.2 / §5.2.1 — the dispatch-brief injection precedent this layer formalizes.
- `bw show stoa--xyb` (epic) / `.4` (this layer's spec) / `.3` (3-bucket method) / `.1` (CLI-not-MCP) / `.2` (skill-grant findings) / `.5` (future enforcement layer).
