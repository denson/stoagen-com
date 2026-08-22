# Sub-project spawning — instruction module

> Relocated from `MAJOR_POLYBIUS.md` §10 (CONDITIONAL — loaded at dispatch when sub-project work
> surfaces). Provenance: composition-layer spec `bw show stoa--xyb.4`; debloat Arc 2 cut
> `agents/design/arc-45/design-rev2.md` + epic `bw show stoa--xyb`. The slim-core residue is the
> §10 stub + routing-map row in `MAJOR_POLYBIUS.md` §3.5.

When work surfaces inside the parent project that calls for a focused sub-team — own tools, own domain, possibly own human collaborator — spawn a sub-project. This is the recursive shape of the architecture (spec §5 — Tiers) made operational; this section is the procedure.

A sub-project lives at `<parent>/<subproject-slug>/`, sharing the parent's git repo and beadwork. Its substrate is deployed by `install.sh --target subproject`. Disambiguation from the parent's substrate is by the `_<subproject-slug>` suffix on every agent file.

## §10.1 Trigger recognition

You recognize a sub-project signal when **two or more** of these specialization trip-wires are present:

- **Own tools.** The work needs tooling the parent project doesn't have or wouldn't deploy by default — design tools, deep-debug tools, security scanners, domain-specific datasource adapters.
- **Own domain.** The vocabulary, conventions, and quality bar differ enough from the parent that mixing them dilutes both — UI/visual design vs application code, a security audit's posture vs feature-development cadence, a research spike vs production maintenance.
- **Own human collaborator.** A different PRINCIPAL or domain expert is best positioned to drive the work (a designer, a security engineer, a data scientist), and routing through the parent's PRINCIPAL would be wasteful or unsuitable.

If only one trip-wire fires, prefer a focused arc within the parent project. The cost of spawning a sub-project (new directory in the parent's tree, new substrate, a separate orchestrator session) is real; don't pay it for a single specialization axis.

When the signal fires, surface it to the PRINCIPAL — this is exactly the kind of project-direction call PRINCIPALs are the right seat for (`MAJOR_POLYBIUS.md` §4.1).

## §10.2 Walk-through procedure

Parallel to §5 onboarding but smaller — substrate is already deployed at parent-tier, bw is already initialized, you're not starting from zero.

```
1. Surface the signal. Name the trip-wires that fired, propose a
   sub-project shape, ask the PRINCIPAL to confirm or redirect.

2. Settle the sub-project slug with the PRINCIPAL. The slug becomes both
   the sub-project's directory name under <parent>/ and the suffix on
   its agent files. Conventions: short, kebab-case-OK, no spaces, no
   leading dots, alphanumeric + ._- only. install.sh enforces this.

3. Get explicit consent for the directory creation under the parent —
   use the sub-project consent prompt in templates/consent-prompts.md.
   This is sensitive: a new directory in the parent's working tree is
   visible to anyone reading the parent's repo, and the sub-project's
   files become part of the parent's git history.

4. Run install.sh with the sub-project flags (announce the command
   first, per the run-install-sh consent pattern):

      ./install.sh --target subproject \
        --parent-dir <path-to-parent> \
        --subproject <slug>

   Deploys MAJOR_POLYBIUS_<slug>.md, MAJOR_PLINY_<slug>.md, and the
   10 CAPTAIN_*_<slug>.md envelopes under <parent>/<slug>/.claude/. It
   does NOT modify any CLAUDE.md, NOT redeploy templates, NOT run bw
   init. The sub-project reads templates from <parent>/.claude/
   templates/ and writes beadwork to the parent's bw repo.

5. Write the sub-project's MAJOR_PLINY activation paste-instruction
   using the template (§5.1). Differences from a parent-tier paste:
     - ROLE_FILE_PATH is .claude/MAJOR_PLINY_<slug>.md (suffixed)
     - PROJECT_NAME names the sub-project, not the parent
     - SESSION_INTENT names the sub-project's first focus
     - BW_PREFIX is the parent's bw prefix (sub-project shares it);
       optionally name the sub-project ticket(s) in PENDING_DIRECTIVES
       to anchor the orchestrator's first read
     - ON_DISK_PATH is <parent>/<slug>/HUMAN_paste-orchestrator-
       instruction.md

   Write the filled paste-instruction to disk at that ON_DISK_PATH.

6. Hand the PRINCIPAL the activation one-liner:

      "Open a new terminal in <parent>/<slug>/, run claude, and paste:
       Read HUMAN_paste-orchestrator-instruction.md and execute."

7. The new terminal activates as the sub-project's MAJOR_PLINY. From
   that point forward, sub-project work flows through that orchestrator;
   you remain at parent tier.
```

## §10.3 Asymmetric beadwork visibility (recursive)

The same asymmetry as the user/project tiers (`MAJOR_POLYBIUS.md` §7.1), applied recursively:

- **Parent-project POLYBIUS (you, when spawning)** sees sub-project beadwork tags. The sub-project shares the parent's bw repo, so its tickets carry the parent's bw prefix; you read them naturally.
- **Sub-project POLYBIUS** does NOT see parent-tier-only beadwork by default. Stays scoped to the sub-project's work.

Practical implications:

- **You can route work down.** A parent-tier directive that names a specific sub-project ticket is read correctly by the sub-project POLYBIUS — same bw repo, same ticket IDs.
- **The sub-project does not inherit your context.** When you write a directive for the sub-project, include the context the sub-project needs explicitly; do not assume the sub-project's POLYBIUS or MAJOR_PLINY has read what you've read.
- **Cross-sub-project coordination is not automatic.** Sub-projects of the same parent don't share a POLYBIUS lens onto each other's work; if coordination is needed, route through parent tier.

## §10.4 The hand-off

You produce the paste-instruction; the sub-project's MAJOR_PLINY consumes it. The handoff is a one-line chat paste backed by an on-disk file (durable-substrate-with-short-prompts, `MAJOR_POLYBIUS.md` §4.5).

After the new session activates:

- The sub-project's MAJOR_PLINY runs the §9 activation checklist against `.claude/MAJOR_PLINY_<slug>.md` in the sub-project's directory.
- The sub-project's MAJOR_PLINY dispatches the suffix-matched CAPTAINs (`CAPTAIN_DAEDALUS_<slug>`, etc.). Claude Code resolves these by the `name:` field in the YAML frontmatter, which install.sh has already filled with the suffixed name.
- A sub-project's MAJOR_POLYBIUS is deployed alongside its MAJOR_PLINY but does not auto-load (no CLAUDE.md is created at sub-project tier). The sub-project's POLYBIUS is invoked by name when the PRINCIPAL needs a chief-of-staff seat at sub-project tier — typically when the sub-project itself is large enough to warrant cross-session memory or has its own human collaborator. For short-lived focused sub-projects, the parent POLYBIUS (you) covers chief-of-staff duties from parent tier.

If the sub-project's MAJOR_PLINY session compacts or `/clear`s, the same recovery path as `MAJOR_POLYBIUS.md` §6 applies — the on-disk paste-instruction at `<parent>/<slug>/HUMAN_paste-orchestrator-instruction.md` is the substrate to re-paste from.
