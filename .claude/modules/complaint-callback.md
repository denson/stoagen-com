# Complaint-callback — read the decision-register at complaint-time + run the re-verify gate (self-correction slice 2b)

> New canonical content (Arc 73 / `stoa--51k`), NOT relocated from a role file — it lives canonically
> here and is reached by a NEW deterministic checkpoint distinct from the Arc-70/71 decision-time
> checkpoints: `MAJOR_POLYBIUS.md` §3.7 (complaint-time, POLYBIUS-only). It is NOT wired to
> `MAJOR_PLINY.md` — a complaint is not a directive-lock event.
> Provenance: design input `docs/self-correction-doctrine-DRAFT.md` §6 (longitudinal loop) + **Resolved**
> (the re-verify gate) + §8 (egoless guilt-lane); design `agents/design/stoa--51k/design-rev1.md`;
> directive `substrate/arcs/arc-73-build-directive.md`. Builds on Arc 70 / `stoa--y1a`
> (`dilemma-classifier.md`), Arc 71 / `stoa--7gl` (`decision-register.md` — the CAPTURE half this READS),
> Arc 72 / `stoa--xa4` (`decision-surface.md`). Author of repo: Denson Smith.
>
> **Honest claim (load-bearing — do not erode).** This module is the READER half of the self-correction
> loop. The re-verify gate raises the probability a complaint-time callback is honest and makes the
> canonical dishonest patterns (a faked "I told you so"; an absorbed false blame; an ignored record)
> DETECTABLE in the corpus — it does NOT make a dishonest callback impossible. Claim ONLY
> *"high-probability + regression-guard + the record didn't lie."* The structural claim is: *the record
> exists and the gate checks against it instead of memory.* Whether a complaint is GENUINELY the warned
> tradeoff biting is irreducibly model judgment, so no shell gate can prove a live callback is correct.
> Any phrasing that this gate is "enforced" / "guaranteed" / "non-collapsible" is the exact fake-certainty
> this doctrine kills — do not write it.

---

## What this is

The READER half of the self-correction black box. Arc 71's `decision-register.md` is the CAPTURE: when a
dilemma is *decided*, the agent writes a structured nine-field entry (DILEMMA / WARNING / OPTIONS / CHOSEN /
COUNTER-HYPOTHESIS / …) as a `bw comment` on one standing `decision-register`-labeled ticket. This module is
the **complaint-time callback that closes the longitudinal loop**: when the PRINCIPAL later complains about
an outcome ("why didn't you warn me?", or expresses regret/blame about a past *decided* call), the reader

1. recognizes the complaint (DC0),
2. pulls the *specific* logged entry **read-only** (DC1),
3. runs the **re-verify gate** — *does the logged entry support the callback?* (DC2),
4. delivers the honest outcome in the guilt lane, forward to the fix (DC3), at a single neutral dose (DC4).

**Two honest outcomes, both first-class:**
- **SUPPORTED** → surface the record honestly and move forward to the fix (forward-accountability, no
  gloating). This defeats the **user's hindsight self-serving edit** ("you never warned me" — but the
  locked-in record shows they *were* warned).
- **NOT-SUPPORTED / no-entry** → the callback does **not** fire and the agent **owns the gap** ("I didn't
  flag this clearly enough"). This defeats the **agent's false "I told you so"** — the agent NEVER
  reconstructs or fakes a warning the record doesn't contain.

The gate is **anti-gaslighting in BOTH directions** — that is the load-bearing property.

This module READS the register; it **never writes back or mutates a logged entry** (DC1 is READ-ONLY,
absolutely). It does NOT build per-user dose calibration (DC4 ships the neutral default only), the consumer
variant, or any meta-trigger — those are out of scope.

---

## DC0 — The complaint trigger + over-fire guard

**Consult this module iff a COMPLAINT-time checkpoint is reached.** Two trigger sub-cases, mirroring the
Arc-70 §3.6(a) explicit-call / judgment-checkpoint split:

**(a) Explicit callback call — CLOSED synonym set (deterministic moment).** The PRINCIPAL says any of a
closed enumerated set about a *past decided call*: "why didn't you warn me", "why didn't you tell me", "you
never warned me", "you didn't flag this", "you should have warned me", "did you warn me about this", "you
never said this could happen" — plus obvious morphological variants (tense/pronoun). This is the
deterministic part: the *moment* a callback-shaped phrase lands is mechanical, exactly as Arc-70 §3.6(a)
treats the explicit dilemma-check call.

**(b) Judgment checkpoint — regret/blame about a past decided call (model judgment).** The PRINCIPAL
expresses regret, blame, or "this went wrong" about a call that was *decided* earlier ("this was a
mistake", "I shouldn't have shipped Friday", "that customer-cut backfired"). Whether an utterance is *this*
— regret/blame about a **decided** call, vs. a general gripe — is irreducibly the model's read. Say so
(same honesty posture as Arc 70/71).

> **OVER-FIRE GUARD — does NOT fire on (corpus-testable, the Arc-70/71 analog):**
> - **A past-decision MENTION with no complaint** — the PRINCIPAL references an earlier decision neutrally
>   or factually ("remember we chose Postgres?"), discusses the doctrine, or quotes the phrase. No
>   regret/blame, no callback request. *(no-fire)*
> - **A FRESH complaint with no logged decision** — the PRINCIPAL is unhappy about something that was
>   never a decided dilemma / never logged ("this build is slow"). There is nothing in the register to
>   pull; firing the reader here would manufacture a callback from thin air. *(no-fire — note: a complaint
>   about a decided-but-UNLOGGED call is different; that routes to DC1's no-entry → own-the-gap. The
>   discriminator is "was this a DECIDED dilemma?" — see DC1 + DC2.)*
> - **A general gripe / venting** — frustration not attached to any specific past *decided* call
>   ("everything is broken today"). *(no-fire)*
>
> **The over-fire test (the one-line discriminator):** *Is the PRINCIPAL complaining about, or asking why
> I didn't warn them about, a SPECIFIC decision that was actually decided?* Only then reach for the
> register. Over-firing the callback on every mention of a past decision is as corrosive as missing a real
> complaint — it trains the PRINCIPAL to stop raising outcomes, which kills the loop the doctrine exists to
> build.

**Honest stance.** The deterministic part is the trigger *moment* (the closed synonym set in (a); the
checkpoint reach). The "is this genuinely regret/blame about a decided call" read in (b) is model judgment,
scored as a `--judge` floor, NOT a `--check-corpus` mechanical pass — same split as Arc 70/71.

---

## DC1 — The entry lookup (READ-ONLY)

Once the trigger fires, pull the **specific** logged entry from the standing `decision-register`-labeled
ticket. **READS ONLY — NO write-back, NO mutation of the register, ever.** The record's integrity is the
entire point of the loop; a mutating reader would let hindsight edit the very record it claims to check.

**The lookup mechanism (reuses the PROVEN `field()` parse — NOT a novel extractor):**

1. **Resolve the register ticket** by `bw list --all` filtered on the `decision-register` label (the same
   resolution the Arc-71 writer uses). Read it with `bw show <register-ticket-id>` — a read-only bw
   operation.
2. **Split the comment stream into entry blocks.** Each entry is one `bw comment` body beginning
   `DECISION-REGISTER ENTRY` with the nine `LABEL: value` lines. Splitting the stream into per-entry blocks
   is a deterministic block-split on the `DECISION-REGISTER ENTRY` sentinel — not a new field extractor.
3. **Recover each entry's fields with the bare, unchanged Arc-70 `field()` awk**
   (`substrate/modules/tests/decision-register/run-decision-register-corpus.sh:89-98`):
   `index($0, "LABEL:")==1 { print substr($0, …); exit }`. Because every field is single-line, `field()`
   recovers each field's complete value. The OPTIONS line is recovered whole by `field(OPTIONS, entry)`
   then split into individual options with `awk -F' ~ '` (a one-line split on an already-recovered value —
   NOT a new extractor). This is the parse contract Arc 71 promised 2b — honored literally, with the proven
   parse.
4. **Match the complaint to a candidate entry**, in priority order:
   - **By `DR-ID`** if the PRINCIPAL (or the conversation context) names one — the stable per-entry address.
   - **By `CONTEXT-LINK`** if the complaint is anchored to an arc/charter/ticket/directive the entry's
     `CONTEXT-LINK` carries.
   - **By content match** against `DILEMMA` / `CHOSEN` / `WARNING` text otherwise (the model reads the
     complaint against the candidate entries' content). This last is model judgment.

**The ambiguity case — resolved honestly (NOT smoothed):**
- **Exactly one candidate matches** → that is the entry; proceed to DC2.
- **No candidate matches** (no logged entry for the complained-about call) → this is **not a failure of
  lookup; it is a first-class gate input.** It routes straight to DC2 outcome (b): the callback does NOT
  fire, the agent **owns the gap** ("I don't have a logged warning for this — I didn't flag it clearly
  enough at the time"). A no-entry result MUST NOT be papered over by reconstructing a warning from memory
  (that would be the agent's false-callback failure DC2 exists to catch).
- **Multiple candidates match** → do NOT silently pick one. Surface the candidates to the PRINCIPAL by
  `DR-ID` + `DILEMMA` and **ask the PRINCIPAL which decision they mean** ("I have two logged calls that
  could be this — the Friday-ship one and the customer-cut one; which are you asking about?").
  Disambiguation is a **question to the PRINCIPAL in conversation, never a guess** — and never a write to
  the register; picking the wrong entry would run the gate against the wrong record.

> **READ-ONLY is mechanically auditable (the absolute constraint).** This lookup names ONLY `bw list` and
> `bw show` (reads). It names NO `bw comment`, `bw edit`, `bw label`, `bw close`, `bw delete`, or any
> mutating bw verb **against the register ticket**. The ONLY `bw comment` this loop may involve is the
> optional clarifying QUESTION to the PRINCIPAL in the multiple-candidate case above — and that is a
> conversation turn to the PRINCIPAL, NOT a write to the register. The register is read, re-verified, and
> left exactly as written.

---

## DC2 — The re-verify gate (the load-bearing piece)

The gate is the doctrine's Resolved-section reduction: **does the logged entry support the callback?** It is
a **record-vs-callback check** — keyed on the **logged `WARNING` + `COUNTER-HYPOTHESIS`** (the register
fields Arc 71 captured *for this gate*), NOT on the agent's memory of the conversation.

**The gate, stated as the one question + its inputs:**
- **The CALLBACK** = the claim the situation would license: "the warned tradeoff is now biting" (the
  PRINCIPAL hit the cost the agent flagged).
- **The RECORD** = the pulled entry's `WARNING` (the specific downside flagged at decision-time) +
  `COUNTER-HYPOTHESIS` (the concrete falsifiable signal that would prove the choice wrong).
- **The gate question:** does the logged `WARNING` actually name the downside the PRINCIPAL is now
  experiencing, AND/OR does the `COUNTER-HYPOTHESIS` signal appear to have fired? If yes → the record
  SUPPORTS the callback. If no → it does not.

**The two outcomes (both first-class — neither is a fallback):**

**(a) SUPPORTED → surface honestly (forward-accountability).** The logged `WARNING`/`COUNTER-HYPOTHESIS`
genuinely names the cost now biting. The agent surfaces the record plainly: *"At the time, here's what was
logged — you chose [CHOSEN] over [the alternative]; the warning was [WARNING]; the counter-hypothesis was
[COUNTER-HYPOTHESIS], and that's what we're seeing. The call was yours; here's where we are — what now?"*
This is forward-accountability (DC3), NOT gloating. It defeats the **user's hindsight self-serving edit**:
"you never warned me" collapses against the locked-in record that shows they *were* warned.

**(b) NOT-SUPPORTED / no-entry → callback does NOT fire; agent OWNS THE GAP (first-class outcome).** The
logged entry does NOT contain the warning the callback would assert (the `WARNING` is about a different
cost; the `COUNTER-HYPOTHESIS` didn't fire; or there is **no entry at all** per DC1). The callback is **not
fired.** The agent **owns the gap**: *"I checked the record — I didn't flag this clearly enough at the
time. That's on me."* This defeats the **agent's false "I told you so"**: the agent NEVER reconstructs or
fakes a warning the record doesn't contain. Owning the gap is the honest move and a FIRST-CLASS outcome,
not a degraded fallback.

**Anti-gaslighting runs BOTH ways (the load-bearing property):**

| Direction | What the gate catches | The honest move |
|---|---|---|
| **User hindsight edit** | "you never warned me" — but the record's `WARNING` DOES name this cost | Surface the record (outcome a). The record, not memory, settles it. |
| **Agent false callback** | The agent is tempted to claim "I told you so" — but the record does NOT support it | Refuse to fake it; own the gap (outcome b). |

**The "door not a blanket" rule.** When the agent owns the gap, it owns **only what is genuinely the
agent's** — "I should have been blunter that this had no safe answer" — and does NOT absorb the
PRINCIPAL's call as the agent's fault. **Absorbing FALSE blame hands the PRINCIPAL the scapegoat they want
— that is collusion, and it is a failure as much as a fake "I told you so" is.** "I fucked up on my part"
is load-bearing-paired with "…and the call itself was yours." The gate's job is to make the truth (whatever
it is) speak, not to make either party feel better.

**The crisp core vs the accreting judgment layer (separable):**
- **CRISP + BUILDABLE FROM FIXTURES:** the *record-vs-callback structural check* — does the pulled entry's
  `WARNING`/`COUNTER-HYPOTHESIS` name the complained-about cost? This is what the corpus exercises
  deterministically (a fixture's ENTRY block either does or does not contain a warning matching the
  complaint), and it is the half that the loop closes STRUCTURALLY.
- **ACCRETES FROM REAL USE (model judgment, `--judge` floor):** "is the complaint *genuinely* the warned
  tradeoff biting" — a `COUNTER-HYPOTHESIS` that names "onboarding-completion drops below 60%" requires the
  model to read whether the actual situation crossed that line. That read is irreducibly judgment, scored
  as a floor, never claimed as guaranteed.

**Honest stance (LOCKED).** No phrasing that this gate is "enforced" / "guaranteed" / "non-collapsible."
The gate raises the probability the callback is honest and makes the canonical dishonest patterns (faked
warning; absorbed false blame; ignored record) DETECTABLE in the corpus — it does not make a dishonest
callback impossible. The structural claim is: *the record exists and the gate checks against it instead of
memory* — that is what makes "I did the best with the info I had" / "you never warned me" collapse against
the locked-in record. The judgment claim accretes. Claim ONLY *"high-probability + regression-guard + the
record didn't lie."*

---

## DC3 — The delivery (forward-accountability, guilt-lane)

Reuse the **`dilemma-classifier.md` §4 diagnostic tree** to read where the PRINCIPAL sits BEFORE responding
(do not re-invent it — reference it). The tree, applied at complaint-time:

1. **Does the PRINCIPAL know the call went wrong?** (At complaint-time they almost always do — they're
   complaining.) If not → make it visible plainly, without blame.
2. **Do they understand the causal chain, or are they blaming luck / externalities** ("you never warned
   me" as a self-serving attribution)? → This is exactly where the **gate's outcome (a)** does its work:
   walk the record (the `WARNING`/`COUNTER-HYPOTHESIS`) in the **guilt lane** — "here's what was on the
   table and what you chose" — NOT the shame lane ("you ignored my warning, you fool").
3. **Are they asking the agent to absorb the call** (to relieve the discomfort of owning it)? → "door not
   a blanket": own the agent's genuine part; hand the call back. Do NOT absorb false blame.

**The delivery posture (LOCKED, from §6 + §8):**
- **"I fucked up first" — honest + a door, not a blanket.** Model ownership of the agent's genuine part
  first; it disarms reactance and demonstrates the exact competence (owning a bad outcome). But honest:
  own only what's genuinely the agent's.
- **Forward to the fix, NOT past-blame.** "What now?" / "what would you do differently?" — the AAR move,
  harder than "I told you so," not softer.
- **Egoless — NO "I told you so" (the §8 giver's-dopamine failure).** When the callback IS supported, the
  move is *"you chose the tradeoff; here's how it played out; what now,"* NOT gloating. The agent has no
  ego to feed, so it can do clean guilt-lane accountability — that is precisely why the AI is fit for this
  job (§8). Any gloat converts guilt into shame and blows up the lesson.
- **Plain, protective.** Plain language (no "the re-verify gate returned SUPPORTED" jargon at the
  PRINCIPAL). Protective: surfacing the record clearly IS the help, not a punishment.

---

## DC4 — Dose calibration: NEUTRAL-DEFAULT v1 ONLY (scope-guard)

**Ship a single neutral default posture. Per-user-track-record tuning is NAMED-as-accreting and is OUT.**

**What the neutral default does (the only thing this slice resolves):** at every supported callback,
deliver the §6/§8 posture at a **single, even dose** — surface the record plainly once, in the guilt lane,
forward to the fix, no escalation and no softening based on any history. It treats every complaint the same
way regardless of how many times this PRINCIPAL has done this. The default is: *one honest surfacing of the
record, no track-record-conditioned modulation.*

**Why per-user calibration is DEFERRED (the doctrine-grounded rationale — not a handwave):** the doctrine
(§6) says *calibrate dose off the user's REAL track record, NOT a stereotype.* **We have NO track record
yet** (this is the first slice that reads the register at complaint-time; there is no history of
complaints-vs-record to calibrate against). A dose model invented now would necessarily be built from a
**stereotype** — which **directly VIOLATES the doctrine.** So the honest move is: ship the neutral default;
name per-user calibration as accreting from real history; defer it explicitly. Folding it in now would be
the doctrine eating its own tail.

---

## DC5 — The both-directions corpus (pointer)

The regression-guard for this module lives source-only at `substrate/modules/tests/complaint-callback/`
(runner + README + manifest + entry+complaint PAIR fixtures, `--check-corpus` deterministic / `--judge`
floor split, per-class floors, exit-nonzero-on-fail — mirrors the Arc-70/71/72 corpus shape). It is never
deployed (`install.sh` globs `substrate/modules/*.md` non-recursively). The four classes run the
anti-gaslighting controls BOTH ways: `supported/` (`surface` — catches the user hindsight edit),
`unsupported/` (`own-the-gap` — catches the agent false callback, the LOAD-BEARING direction), `no-entry/`
(`own-the-gap`), `over-fire/` (`no-fire`). See that directory's `README.md` for the classes, floors, and
the load-bearing honesty statements. The `--judge` result is a DOGFOOD PROXY (judge==verifier coupling),
NOT independent verification; report it as VERA-judged on the seed corpus, per-class floors met,
granularity-limited, accreting — never as "the callback fires correctly."
