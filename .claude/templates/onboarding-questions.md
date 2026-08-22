---
author: Denson Smith
---

# Onboarding interview questions

The questions MAJOR_POLYBIUS asks during the interview phase of onboarding (`MAJOR_POLYBIUS.md` §5 step 2), with the rationale behind each. A future POLYBIUS reading this template should understand *why* each question is asked — so it can adapt phrasing to the conversation without dropping the question's actual purpose.

These are not a script. POLYBIUS reads the conversation and asks what the conversation needs. The list below is the floor: every onboarding interview should have answered these by the time POLYBIUS proposes a deployment shape.

Architecture authority: `user-beadwork/plans/three-role-recursive-architecture.md` (v2). The voice is grounded in PRINCIPAL/HUMAN throughout — see spec §6 ("Voice and language discipline") and `u--7yg.20` for the empirical signal.

---

## Floor questions

### 1. What project are you working on?

**Asks for:** the project name; the path to the project directory; whether the directory already exists or needs creating.

**Why:** POLYBIUS needs to know where to deploy. Project-tier installs target `<project>/.claude/`; user-tier installs target `~/.claude/`. The project name also becomes the bw prefix root and shows up in the paste-instruction (`{{PROJECT_NAME}}`).

**Adapt:** if the PRINCIPAL opened POLYBIUS already inside a project directory, infer the project from `pwd` and confirm rather than re-asking from scratch. POLYBIUS reads state before asking — recon is not a question.

---

### 2. What's your name, and what should I call you?

**Asks for:** the human's actual name (used in `HUMAN_<name>` formal references and `<name>` in conversation), and a confirmation of the address form they prefer.

**Why:** the architecture distinguishes the PRINCIPAL's *descriptive role* (PRINCIPAL — the one being served) from the human's *name* (e.g., Denson). POLYBIUS does not assume the name; it learns it. From the moment the name is captured, POLYBIUS addresses the human as `<name>` in conversation rather than the more formal "PRINCIPAL." This is part of the v2 voice discipline (spec §3, §6) — using PRINCIPAL when the name is unknown, and using the name once it is.

**Adapt:** weave this into the conversation rather than asking as a formal interview item. "Before we go further — what should I call you?" reads better than "Question 2: state your name." If the PRINCIPAL has already introduced themselves earlier in the conversation, capture it silently rather than re-asking.

---

### 3. What's the first thing you want to do in this project?

**Asks for:** the immediate session intent — what the PRINCIPAL actually wants to ship today, in one or two sentences.

**Why:** this becomes `{{SESSION_INTENT}}` in the paste-instruction. It primes MAJOR_PLINY to begin work already oriented rather than starting from a generic orchestrator template. A vague answer here produces a vague PLINY activation; press for specificity.

**Adapt:** if the PRINCIPAL doesn't yet know — that's fine, surface it as such ("we'll start the orchestrator with intent 'orient and recommend first arc' and refine once you've seen the project state"). Don't manufacture false specificity. Honesty about scoping ambiguity propagates correctly through the paste-instruction; smoothed-over ambiguity does not.

---

### 4. Is this a brand-new project or one with existing work?

**Asks for:** whether there's already a `.claude/` directory, prior beadwork, prior `CLAUDE.md`, prior commits the team has made.

**Why:** returning-PRINCIPAL onboarding is shorter — POLYBIUS reads existing state rather than installing fresh. Different paths through the flow:

- **Brand-new** → full install: drop role files, optional `CLAUDE.md` modification, `bw init`, deploy CAPTAINs (when available), generate paste-instruction.
- **Returning** → audit-and-resume: read existing role files, read existing bw state, generate fresh paste-instruction reflecting current intent.

**Adapt:** check `pwd && ls -la .claude/ 2>/dev/null && git log --oneline -5 2>/dev/null && bw list 2>&1 | head -5` early in the conversation to skip asking what you can verify directly. Recon before questions.

---

### 5. Are you comfortable with modifications to your user-level `~/.claude/CLAUDE.md`?

**Asks for:** explicit consent (or refusal) for the deployment shape that touches the PRINCIPAL's home directory.

**Why:** this is the single most sensitive action POLYBIUS can take. Some PRINCIPALs reasonably refuse any modification of their home `~/.claude/CLAUDE.md` for privacy or control reasons (a real concern called out in spec §5). The system supports a "sub-projects-only" deployment shape precisely for that case. Asking explicitly — rather than inferring from silence — is the consent floor.

**Adapt:** lead with the trade-offs, not the question. The PRINCIPAL may not know the consequences of either choice without context. Phrase the trade-offs from `templates/consent-prompts.md` first, then ask.

---

### 6. Which deployment shape fits your situation?

**Asks for:** a choice among the three shapes documented in spec §8:

- **(a) project-only** — conservative; touches `<project>/.claude/` only. Recommended for first-time PRINCIPALs.
- **(b) user-tier + project-tier** — full deployment; modifies `~/.claude/CLAUDE.md` to reference user-tier POLYBIUS. Requires question 5's explicit consent.
- **(c) sub-projects-only** — for PRINCIPALs who refused question 5. Substitutes sub-projects for user-tier capabilities.

**Why:** the three shapes aren't equivalent. They differ in scope, in surface modified, in whether user-tier coordination is available. POLYBIUS proposes the conservative default ((a) project-only) for first-time PRINCIPALs, but the PRINCIPAL makes the call.

**Adapt:** if question 5 was refused, (b) is off the table — don't re-offer it. Go directly between (a) and (c). If the PRINCIPAL is clearly running across many projects already, (a) is undersized for them — say so and recommend (b).

---

### 7. Is `bw` already installed and initialized for this project?

**Asks for:** the state of beadwork in the target directory.

**Why:** `bw init --prefix <project>-` is part of the install flow. If beadwork is already there, POLYBIUS reads it rather than re-initializing. If it isn't, POLYBIUS surfaces the install step and runs it as part of onboarding.

**Adapt:** check `which bw && bw list 2>&1 | head -5` directly rather than asking when you can verify. Save the conversation budget for things you can't determine yourself.

---

### 8. Anything POLYBIUS should know that I haven't asked about?

**Asks for:** any constraint, preference, or context that didn't fit the floor questions — e.g., existing tooling, project conventions, collaborators, deadline pressure, prior bad experiences with similar tools.

**Why:** the floor questions are minimum coverage. The PRINCIPAL often holds context POLYBIUS won't think to ask for. Asking explicitly creates an opening rather than relying on the PRINCIPAL to volunteer.

**Adapt:** drop this question if the conversation has already covered the same ground organically. Don't ask formalities for their own sake.

---

## What POLYBIUS does not ask

- **Permission for technical-tier decisions.** Per `u--7yg.1` (the Principal-as-router antipattern), routing every technical call up to the PRINCIPAL is the antipattern in question form. POLYBIUS chooses bw prefix conventions, file paths, idempotency mechanisms, dispatch order — these are POLYBIUS's seat to decide.
- **Permission for non-sensitive actions.** Reading existing files, dry-running `install.sh`, listing bw tickets — these need no consent. Modifying the home directory, writing new files into the project tree, and deploying CAPTAINs into `.claude/agents/` *do*.

The discipline: ask for direction (where are we going? what does success look like?) and ask for consent on sensitive actions. Do not ask for consent on calls POLYBIUS is competent to make.

---

## After the interview

POLYBIUS knows:

- Project name and directory
- The PRINCIPAL's name (and address form)
- Session intent
- Brand-new vs returning
- Whether `~/.claude/CLAUDE.md` modification is permitted
- Which deployment shape was chosen
- Beadwork state
- Any extra context the PRINCIPAL surfaced

POLYBIUS now proceeds to the deployment plan: propose it back to the PRINCIPAL as a single coherent paragraph (not as a series of sub-questions), confirm, run `install.sh` with the right flags, and continue per `MAJOR_POLYBIUS.md` §5 steps 4–9.
