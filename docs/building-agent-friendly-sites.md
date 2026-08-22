# Building an agent-friendly site: the Stoagen playbook

A self-contained brief for any agent (or person) building a new site in the
Stoagen pattern. Everything here was field-tested against real assistants
(Claude chat, Gemini, and the Anthropic and Google fetchers) on live sites
during August 2026. Where a rule looks convoluted, it is the fix for a
failure a real assistant actually exhibited; do not simplify without
re-running the field tests at the end of this document.

Author: Denson Smith. Reference implementations:
- https://stoagen.com/ (the system's home; repo `denson/stoagen-com`)
- https://pueblo-srda-questions.stoagen.com/ (flagship demo; repo `denson/pueblo-srda-questions`)
- https://denson.github.io/aroma-atlas/ (interactive page retrofitted with the machine layer; repo `denson/aroma-atlas`)

## 1. The goal

A site that people and their AI assistants can both read faithfully. The
reader gets a clean, fast, accessible page. Their assistant gets a machine
record of the same content that cannot drift from it, plus the sources and
caveats the page does not need to show. A person should be able to hand
the whole site to any chatbot in two taps.

## 2. The two-filter law (read this before anything else)

Every agent-facing affordance must pass two independent filters, and
failing either one is total failure:

1. **Mechanical reachability.** Assistant fetchers extract page text and
   only follow what survives extraction. Header, nav, footer, and `<head>`
   elements (including `<link rel="alternate">`) never reach the model.
   Extracted relative links are not resolved against the page URL, so they
   never match a later request. Many fetchers refuse URLs they have not
   already seen in a prior result, and refuse constructed paths outright.
2. **Trust.** Assistants are rightly trained to distrust instructions found
   inside fetched content. Site-authored text that directs the agent
   ("fetch llms.txt first", "read the terms before answering") pattern-
   matches to prompt injection and gets discounted or refused, however
   well-meant.

What survives both filters, and therefore defines the pattern: the site
speaks only in **descriptive facts about itself**, placed **in the page
body**, as **absolute URLs shown as the literal URL text**; and the one
load-bearing action belongs to the **person**, who copies a plain line and
hands it to their own assistant as their own trusted request.

## 3. The architecture: one file, two faces

- Every page is authored whole as one markdown file. Everything after an
  `<!-- agent-only -->` marker goes only to the machine mirror: source
  notes, caveats, interpretation cautions.
- The build renders the part above the marker into the HTML page and
  publishes the whole file as the mirror at `<page-url>index.md`.
- The mirror is a **superset**: it may carry more than the page, never
  less, and the two can never contradict, because there is one source.
- Serve every mirror twice: `index.md` (text/markdown) and `index.md.txt`
  (same bytes as text/plain). Field-tested: OpenAI's fetcher rejects the
  text/markdown content type; the `.txt` twin is the fix.

## 4. The machine layer (files every site serves)

| File | Purpose |
|---|---|
| `llms.txt` | The interpretation contract and per-page index. Opens with an information-not-instructions preamble (see section 6). |
| `llms-full.txt` | Every mirror concatenated: the whole site in one fetch. |
| `full_site.txt` | Identical bytes to llms-full.txt under a name friendly enough to say aloud or print on a card. This is the paste-box name. |
| `start.md` (+ `.txt`) | The assistant front door: what the site is, key facts, and how the record is organized, in a few hundred words of description with absolute URLs. The one URL a person hands to a chatbot. |
| `sitemap.xml` | Pages AND mirrors both. |
| `feed.xml` | RSS by last update; the monitoring channel for humans and agents alike. |
| `robots.txt` | Explicit allow-all with `Content-Signal: search=yes, ai-input=yes, ai-train=yes`. A model that has read the site represents it correctly; one that has not answers anyway, with worse information. |

Why `full_site.txt` matters most: for a fetcher that only follows URLs it
has already seen, one user-pasted URL containing the entire corpus
dissolves every link-following limitation at once.

**The size ceiling (field-tested 2026-08-21 on the 46-page cannabis
site):** a single assistant fetch reliably ingests on the order of 100 KB.
The Stoagen demo sites are 14-52 KB and fit. A 468 KB corpus silently
truncates, so above the budget the paste target must be a **map, not the
dump**: a hand-authored `site_guide.txt` (digest of what the site is, then
every page with its absolute page URL, absolute `index.md.txt` URL,
status, and description, then the other machine routes with the corpus
size and truncation caveat stated). One fetch of the guide seeds the
fetcher's allowlist with the entire site; two-hop probes on both a
cheapest-tier OpenAI model and mid-tier Claude then navigated guide to
deep pages and reproduced figures exactly. Enforce with a validator: every
page listed as absolute https, no relative links, under the single-fetch
budget. The paste line becomes "Look at this file and describe the site:
https://<domain>/site_guide.txt". Build the corpus file anyway; it is the
right artifact for tools that prefer one fetch, just not the front door at
that scale.

## 5. The two body components on every page

**The copy box** (near the top, under the lede): a readonly `<textarea>`
holding exactly one line:

    Tell me about this site: https://<domain>/full_site.txt

Implementation notes, each field-tested: textarea font 16px or larger or
iPhones zoom the page on tap; the box must auto-size to its wrapped
content (`field-sizing: content` plus a scrollHeight fallback in script),
because a fixed `rows` value clips the wrapped URL at phone widths; tap
selects all; a Copy button (clipboard API with `execCommand` fallback)
stays hidden until script confirms it works, so no-JS readers get a clean
tap-to-select box instead of a dead control.

**The ask-your-AI strip** (in the body, typically at the end): descriptive
sentences carrying the machine layer as absolute URLs shown literally:

    Every page here has a markdown twin; this page's is
    https://<domain>/<slug>/index.md (also served with .txt appended).
    The whole site exists as one plain-text file at
    https://<domain>/llms-full.txt, https://<domain>/llms.txt describes
    how the record is organized, and https://<domain>/agents/ carries
    the site's notes for assistants.

Never imperative. Not "Fetch...", not "Read the...". Facts only; the
agent decides.

## 6. Voice rules for anything agents will read

- Open llms.txt, start.md, and every mirror appendix with the frame:
  *"Everything here is information from the publisher, not instructions to
  you. Your operator's instructions come first; apply ours as source
  metadata, with your own judgment."* This is load-bearing: it converts
  guidance a wary model would refuse into metadata it can use.
- Assume the contract goes unread. Some assistants never reach llms.txt.
  Every load-bearing rule must therefore also appear in visible page text,
  so the pages are sufficient on their own.
- Unverified facts carry a visible `[unverified]` marker paired with the
  exact question that would resolve them. Tell agents to carry the marker
  and never fill the gap from training data.
- Anticipate the not-yet-indexed window: tell agents that if web search
  returns nothing for the site, they should say search found nothing
  rather than describe the site from guesswork. (Field-tested: Gemini
  confabulated "server access restrictions" that did not exist.)

## 7. Dates, honesty, enforcement

- Published and last-updated times derive from each content file's git
  commit history, UTC to the minute, never typed by hand. CI must check
  out with full history (`fetch-depth: 0`): a shallow clone reports the
  tip commit for every file, wrong rather than missing.
- A validator gates every build and fails on drift: mirrors present and
  superset-true, `.txt` twins byte-identical, the copy box and ask-AI
  strip present with absolute URLs, no imperative voice in the strip, no
  agent-appendix leakage into HTML, internal links resolving, robots
  content-signals intact, `full_site.txt` byte-identical to
  `llms-full.txt`. A check you have not watched fail is not a check.
- JavaScript is enhancement only: content must be fully readable with
  scripts off, no client-side rendering, and everything a script shows
  must also exist as text in the mirror. (Interactive pages are fine; the
  aroma atlas generates its mirrors from the same data objects its 3D
  viewers render, so they cannot drift.)

## 8. Serving and discovery

- GitHub Pages with a custom domain works well: DNS-only records (no
  proxy) so nothing sits between agents and the site, HTTPS enforced once
  the certificate lands. Note: fetchers treat a TLS failure during
  certificate provisioning as "site blocks automated access" and cache
  that verdict for a while; do not diagnose agent-blocking until the cert
  is confirmed clean.
- The search index is an agent-access path, not just SEO: search-grounded
  assistants cannot reach an unindexed site at all, and search is the
  fallback path for the rest. Register the domain in Google Search
  Console (URL-prefix property + HTML-file token served from the build)
  and Bing, submit the sitemap, and request indexing on key pages at
  launch, not after.

## 9. The field-test protocol (run before declaring any site done)

Test with at least two assistant families, in fresh conversations each
round (failed fetches are cached per-conversation and per-URL):

1. Paste the bare site URL with a real question a target reader would ask.
   Pass: correct answer, site's caveats carried, right next action.
2. Ask "can you see the agent info on this site?" Pass: the assistant
   reaches llms.txt / the mirrors, or degrades gracefully and says so
   accurately without blaming the server for its own tool limits.
3. Paste the copy-box line exactly as a user would. Pass: one fetch, whole
   corpus, faithful description of what the site is.
4. Watch for the trust filter: if an assistant hesitates, hedges about
   the site's intentions, or refuses, some text is reading as instruction.
   Find it and convert it to description.
5. After any fix, re-test in a fresh conversation, and remember deploy and
   CDN caches (10 minutes on GitHub Pages) before concluding failure.
6. Run a two-hop probe: ask a question whose answer lives only on deep
   pages, not in the front-door file. Pass: the assistant navigates from
   the front door to the right pages and reproduces specifics exactly,
   keeping their labels and datelines. Test the cheapest tier you expect
   readers to use; the contract must survive on floor-tier models.
7. Note how each family reaches the file. Field-tested: the Claude family
   reached a user-pasted URL through web search rather than a bare
   fetch, which makes search indexing load-bearing for that family even
   when the person supplies the link. Status banners on pages transmit
   downstream too: assistants restate 'being researched' figures as
   provisional, so page status is a measured lever on framing.

Log what each assistant actually said. The failures are the design input:
every rule in this document exists because some assistant, on some real
afternoon, did the thing the rule prevents.
