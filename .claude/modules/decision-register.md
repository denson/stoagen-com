# Decision-register — capture a decided dilemma to the bw black box (self-correction slice 2a)

> New canonical content (Arc 71 / `stoa--7gl`), NOT relocated from a role file — it lives canonically
> here and is reached by the same deterministic checkpoints that host the Arc-70 `dilemma-classifier`:
> `MAJOR_POLYBIUS.md` §3.6 and `MAJOR_PLINY.md` §5.18.
> Provenance: design input `docs/self-correction-doctrine-DRAFT.md` (§5 black-box countermeasure, §6
> longitudinal loop); design `agents/design/stoa--7gl/design-rev1.md` + `…-rev2.md` (DC0 + P7) +
> `…-rev3.md` (DC3 + P11); directive `substrate/arcs/arc-71-build-directive.md`. Builds on Arc 70 /
> `stoa--y1a` (`dilemma-classifier.md` + its checkpoint wiring + corpus). Author of repo: Denson Smith.
>
> **Honest claim (load-bearing — do not erode).** This module is a *high-probability writing-discipline
> + a corpus regression-guard*. It is NOT a non-collapsible enforcement: whether a path was actually
> chosen, and whether a counter-hypothesis is genuinely falsifiable, are irreducibly model judgment, so
> no shell gate can prove the entry is real or the writing happened. The structural devices below raise
> the probability the writing is real and make the canonical hollow patterns *detectable* in the corpus;
> they do not make a hollow or skipped entry impossible. Any phrasing that this is "enforced" /
> "guaranteed" / "non-collapsible" is the exact fake-certainty this module exists to kill — do not write
> it. (Non-collapsibility lives in the deferred re-verify structure — slice 2b — not here.)

---

## What this is

The CAPTURE half of the self-correction black box. The Arc-70 `dilemma-classifier` is the READ: at a
fixed checkpoint it decides whether the decision in front of you is a solvable PROBLEM or a value-TRADEOFF
(DILEMMA), illuminates a dilemma, and hands the call back. This module is the appended WRITE step: **once
the classifier has returned DILEMMA *and a path has actually been chosen*, write one structured,
transparent, user-readable decision-register entry to bw** — recording the dilemma, the warning (the cost
being accepted), the options, the chosen option, and a concrete counter-hypothesis (what would later prove
the choice wrong), with a timestamp and a context link.

The register records **DECISIONS, not detected tradeoffs.** Illumination without a choice is NOT a
register event. The two load-bearing reasons to write at all:

1. **"The act of writing it is half the value."** Naming the tradeoff and a *falsifiable*
   counter-hypothesis at decision-time — before hindsight can edit them — is the discipline. The value
   lives in the act of filling the fields, not in any checker.
2. **A structured ex-ante entry, transparent + user-readable by default.** The schema is re-readable by
   the deferred 2b callback (NOT built here) — that is DC0's forward-constraint.

This module SPECIFIES the schema and the write; it does NOT build the 2b reader, the complaint-time
callback, the re-verify gate, or any dose-calibration. Those are slice 2b (out of scope).

---

## §1. WRITE-trigger predicate + over-write guard (DC1)

> **WRITE** an entry **iff** all three hold:
> 1. **You are at an Arc-70 checkpoint** — explicit-call / prioritization / team-spin-up (POLYBIUS
>    §3.6) or directive-lock (PLINY §5.18). *Deterministic: the checkpoint moment is mechanical, exactly
>    as Arc 70 established.*
> 2. **The classifier returned DILEMMA** (or CAMOUFLAGED-DILEMMA, which resolves to dilemma) on the live
>    decision. *The Arc-70 read; model judgment.*
> 3. **A path was actually chosen** — the PRINCIPAL (or the agent on the PRINCIPAL's behalf within a
>    locked directive) committed to one of the illuminated options. *Model judgment.*

Condition (3) is the heart of the over-write guard: a journal of *choices*, not of detected tradeoffs.

**The over-write guard — does NOT fire on:**

- **A problem solved** — classifier returned PROBLEM (condition 2 fails). A grounded answer is not a
  logged tradeoff. *(no-write)*
- **A dilemma illuminated but NOT decided** — classifier returned DILEMMA, the tradeoff was laid out, but
  the PRINCIPAL deferred / asked for more / committed to no option (condition 3 fails). **This is the most
  important guard case:** logging an undecided tradeoff would pollute the journal the 2b callback reads AND
  let a non-decision masquerade later as a warned decision. *(no-write)*
- **An incidental mention** — the words "dilemma" / "tradeoff" appear in conversation but no checkpoint
  fired and no live decision is being classified (condition 1 fails) — discussing the doctrine, naming a
  past classification, quoting the phrase. Same shape as the Arc-70 §3.6(a) over-fire guard. *(no-write)*

**Honest stance.** Condition (3) — "a path was actually chosen" — is model judgment, not a shell check.
The deterministic part is the trigger moment + the DILEMMA precondition; the *was-it-decided* read is
yours, exactly as "is this a dilemma" is in Arc 70. The corpus tests this read as a `--judge` floor, not
a `--check-corpus` mechanical pass. No heuristic auto-detection is introduced.

---

## §2. The entry schema (DC0 — the load-bearing forward-constraint)

**Home: ONE standing per-deployment decision-register ticket; entries are its COMMENT STREAM.** A single
bw ticket titled `Decision register (self-correction black box)`, labeled `decision-register`. Each decided
dilemma is one `bw comment` on that ticket — append-only, chronological, a decision JOURNAL with free
timestamps, inherently transparent (a normal readable ticket). The writer resolves the register ticket id
by `bw list --all` filtered on the `decision-register` label (and creates it on first use — see §3).

**Each entry is a single `bw comment` body: a fixed labeled block (NOT free prose). Every field is one
`LABEL: value` line at line start — including OPTIONS:**

```
DECISION-REGISTER ENTRY
DR-ID: <YYYY-MM-DDTHH-MM-SSZ>-<short-slug>
WHEN: <UTC timestamp, ISO-8601>
CHECKPOINT: <explicit-call | prioritization | team-spin-up | directive-lock>
DILEMMA: <the value-tradeoff in one or two plain sentences — what is being traded against what>
WARNING: <the specific downside the agent flagged about the chosen path — the cost the PRINCIPAL is accepting>
OPTIONS: <option-1 with its cost> ~ <option-2 with its cost> ~ <option-3 with its cost> ~ <…>
CHOSEN: <the chosen option — restate the chosen option text, matching one of the OPTIONS entries>
COUNTER-HYPOTHESIS: <concrete, falsifiable: the specific later observation that would prove this choice wrong>
CONTEXT-LINK: <the arc/charter/ticket id or directive path this decision sits in>
```

### The parse contract (what 2b is promised — by a PROVEN parse, without building 2b)

Nine fields, **all single-line**, each recoverable by the **bare, unchanged Arc-70 `field()` awk**
(`substrate/modules/tests/dilemma-classifier/run-dilemma-corpus.sh:71-80`):
`index($0, "LABEL:")==1 { print substr($0, …); exit }`. Because every field is one line, `field()`'s
same-line / first-match / exit behavior recovers each field's *complete* value. The capture module
SPECIFIES this contract; it does not build the reader.

- **OPTIONS is one line; options are separated by a fixed ` ~ ` (space-tilde-space) delimiter.** A 2b
  reader recovers the whole OPTIONS line by `field(OPTIONS, entry)` (the proven parse), then splits into
  the N individual options with `awk -F' ~ '` (a one-line deterministic split on an already-fully-recovered
  value — NOT a new field extractor). This keeps DC0's promise literally true: the schema is re-readable by
  the *proven* parse, not a novel one.
- **Field-value hygiene (keeps the entry parseable):**
  1. **No field value may BEGIN with one of the nine reserved `LABEL:` tokens** (`DR-ID:`, `WHEN:`,
     `CHECKPOINT:`, `DILEMMA:`, `WARNING:`, `OPTIONS:`, `CHOSEN:`, `COUNTER-HYPOTHESIS:`, `CONTEXT-LINK:`).
     Since every field is one line, this is the only way a value could shadow a field anchor.
  2. **The ` ~ ` sequence is reserved as the OPTIONS delimiter** — option text must not contain ` ~ ` (use
     a dash, "or", or rephrase). ` ~ ` is chosen because it is rare in natural decision prose, is not a
     bw/shell footgun, and is visually unambiguous in a human-read entry.

  This is forward parse-robustness, not a security fix.

- **`DR-ID` is the stable per-entry address** the 2b callback pulls a specific entry by: filename-safe UTC
  timestamp + short slug (same convention as `save-verdict.md`'s `<ts>`: `YYYY-MM-DDTHH-MM-SSZ`,
  colons → hyphens). Recoverable by bare `field(DR-ID, entry)`.
- **`COUNTER-HYPOTHESIS` is the 2b re-verify-gate's future input** — captured now in falsifiable form; the
  gate that *reads* it is 2b. Naming the field + its shape is the forward-constraint; reading it is out of
  scope.
- **Minimal-but-sufficient:** nine fields, all single-line, all load-bearing, none speculative. No
  status/severity/category taxonomy — reader-side concerns that accrete from real entries.

---

## §3. The bw-write mechanics + transparency (DC3)

**An inline deterministic template, NOT a helper script.** The write is a single `bw comment`; the agent
fills the fields in context, which IS the DC4 "writing is half the value" device. A helper would abstract
the field-writing away. The inline body also resolves at every tier including subproject (the module body
recomposes inline; no path-resolution dependency).

### The write contract (footguns honored — the robust single-quote form)

`bw comment` takes the comment body as a **POSITIONAL argument only** — there is no `--stdin`,
`--body-file`, or `-` stdin convention that would let the body bypass shell quoting. So the quoting must be
solved at the positional arg. The entry body is written with **ONE** `bw comment` call using the **robust
single-quote form**:

- **POSITIONAL — never `-m`.** `bw comment` has no `-m` flag; `-m` would record the literal string "-m" and
  drop the message.
- **Single-quote the ENTIRE body; escape each embedded apostrophe as `'\''`** (close-quote,
  escaped-apostrophe, reopen-quote — the proven `save-verdict.md` "Quoting caveat" form applied to the
  positional `bw comment` arg). The module's template instructs the writer to emit:

  ```bash
  bw comment <register-ticket-id> '<entry body, single-quoted; every embedded apostrophe written as '\''>'
  ```

  - **Single quotes make `$` AND backticks AND `$()` all literal at once** — so a bare dollar amount (a
    cost figure like fifty-thousand written `$50k`), a backtick, or a `$()` span in the body is written
    verbatim, NOT shell-expanded. This is what closes the bare-`$` (dollar-mangle) footgun — a bare `$50k`
    inside a double-quoted body would otherwise expand to `0k` (bash reads `$5`/`$50` as a positional
    param → empty). The single-quote form subsumes the backtick/`$()` lock into one mechanism.
  - **`'\''` handles the embedded apostrophe** — "the team's call" is written `the team'\''s call`. Without
    this, a bare apostrophe would terminate the single-quoted string. This is the one place the body author
    must transform the text: each `'` in the prose becomes `'\''`.
  - **Forbidden:** a `cat <<'EOF' … EOF` heredoc (breaks on apostrophes on Windows git-bash). The body goes
    directly in the single-quoted positional arg.

- **No content restriction.** The body MAY contain apostrophes and dollar amounts freely — that is the
  point of the robust quoting. Forbidding dollars/contractions is not an acceptable resolution: cost
  counter-hypotheses need dollar figures and prose needs contractions; the quoting absorbs them. The only
  reserved sequences remain the §2 parse-hygiene rules (no value begins with a reserved `LABEL:` token;
  ` ~ ` is the OPTIONS delimiter) — orthogonal to shell quoting.

- **Verify-then-assert:** after the write, re-read the register ticket (`bw show <register-ticket-id>`) to
  confirm the entry landed intact. This re-read catches the dollar-mangle class (a mangled `$50k → 0k`
  shows on re-read) and the backtick-mangle class. The post-write re-read is a required step.

- **First-use ticket creation:** if no `decision-register`-labeled ticket exists, create it once
  (`bw create "Decision register (self-correction black box)"`, then `bw label <id> +decision-register`),
  then comment. The lookup-or-create sequence is deterministic.

### Shell-path note (honest scope of the quoting contract)

The robust single-quote form above is **bash** single-quote semantics. The seats invoke `bw` through the
**Bash tool** (bash / git-bash) — that is the actual invocation path, and the path this contract is written
for. A future deployment that drives `bw` from **PowerShell** would instead double a literal apostrophe
(`''`) and would not hit the bare-`$` footgun at all (`$` is not special inside PowerShell single quotes) —
a one-line forward note, not a slice-2a build. Apply the bash form on the bash path.

### Transparency (the decision-journal-not-hidden-dossier property)

- The register is a **normal bw ticket** — the same store the team already reads; nothing hidden, encrypted,
  or in a separate dossier. Writing to bw IS the transparency guarantee.
- **Single-user deployment:** the register is **user-readable by default** — a decision journal on the
  PRINCIPAL's side; the PRINCIPAL can `bw show <register-ticket>` at any time; nothing is gated from them.
  This is the primary target.
- **Team deployment:** bw is already team-visible, so the register is transparent to the team by
  construction. The honest caveat (named, not smoothed): team-visibility means a register entry is readable
  by every seat with bw access — the *intended* transparency, but a deployment wanting PRINCIPAL-only
  visibility would need a bw-visibility scoping this slice does NOT build (per-user track-record reading is
  2b dose-calibration — out of scope). For slice 2a the property is "transparent by default."

---

## §4. The "writing is half the value" device (DC4 — LOAD-BEARING)

The structural device: a `COUNTER-HYPOTHESIS` field that must be **concrete + falsifiable**, with a hollow
entry made OBVIOUSLY hollow — the Arc-70 `WHY:`-field analog, same honesty posture (template +
prose-enforced + corpus regression-guard, NOT a hard gate). Two levels:

1. **In the live entry (the prose-enforced discipline).** The `COUNTER-HYPOTHESIS` field carries this
   in-template instruction — the load-bearing words:

   > State the SPECIFIC, OBSERVABLE thing that would later prove this choice was wrong. "We'll see" /
   > "it might not work out" / "time will tell" is a HOLLOW counter-hypothesis and defeats the entry —
   > name the concrete signal: a metric crossing a threshold, a customer doing X, the cost landing above Y.

   Same for `WARNING`: name the specific downside being accepted, not "there are risks." The agent writing
   the fields IS confronting the tradeoff — that is the half-the-value mechanism, and it lives in the act of
   filling the field, not in a checker.

2. **In the corpus (the regression-guard that makes hollowness DETECTABLE).** The DC5 `--check-corpus`
   deterministic pass FLAGS a should-write fixture whose `COUNTER-HYPOTHESIS` or `WARNING` is empty OR
   matches a **vacuity denylist** (case-insensitive substring match against a small seed list: "we'll see",
   "time will tell", "might not work", "who knows", "hard to say", "could go either way" — plus
   empty/whitespace-only). This is the Arc-70 "no empty WHY" check extended to "no vacuous
   counter-hypothesis." It makes a hollow entry obviously hollow mechanically in the test corpus.

**Honest stance (LOCKED).** This is template + prose-enforced + a corpus regression-guard, NOT a hard
non-collapsible gate. A live agent CAN still write a technically-non-empty but weak counter-hypothesis that
slips the denylist; no shell check on a live `bw comment` body proves the counter-hypothesis is genuinely
falsifiable (that read is irreducibly judgment, same as "is this a dilemma"). The device RAISES the
probability the writing is real and makes the canonical hollow patterns DETECTABLE in the corpus — it does
not make a hollow entry impossible. The module text, the README, and any verdict claim ONLY
*"high-probability writing-discipline + a corpus regression-guard against the canonical hollow patterns."*
The vacuity denylist is explicitly a *seed* list that accretes from real hollow entries, not a closed proof
of vacuity.

---

## §5. The both-directions corpus (DC5 — pointer)

The regression-guard for this module lives source-only at
`substrate/modules/tests/decision-register/` (manifest-driven, `--check-corpus` deterministic /
`--judge` judgment split, per-class floors, exit-nonzero-on-fail — mirrors the Arc-70 corpus shape). It is
never deployed (`install.sh` globs `substrate/modules/*.md` non-recursively). See that directory's
`README.md` for the classes, floors, and the load-bearing honesty statements.
