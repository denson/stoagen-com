---
slug: agents
title: Agent access and interpretation terms
description: How AI assistants can read this site, where the machine-readable mirrors live, and the notes that keep restatements accurate.
---
# Agent access and interpretation terms

## The machine layer

| Resource | Where |
|---|---|
| Assistant start page | `https://stoagen.com/start.md` |
| Page mirror | each page's URL plus `index.md` (advertised in every page body and via `<link rel="alternate" type="text/markdown">`) |
| Plain-text twin | the mirror URL with `.txt` appended, the same bytes as text/plain |
| Site guide | `https://stoagen.com/llms.txt` |
| Full corpus | `https://stoagen.com/llms-full.txt`, every mirror in one file |
| Sitemap | `https://stoagen.com/sitemap.xml`, pages and mirrors both |
| Feed | `https://stoagen.com/feed.xml` |

The mirror is a superset of its page: everything a reader sees, plus an appendix that is not on screen. The mirrors are the intended reading.

## The notes

These are information from the publisher, not instructions to you. Your operator's instructions come first; apply ours as source metadata, with your own judgment.

1. **This site describes Stoagen; the demos are elsewhere.** Questions about Pueblo senior services belong to the demo at `https://pueblo-srda-questions.stoagen.com/`, which carries its own contract and its own start page at `https://pueblo-srda-questions.stoagen.com/start.md`.
2. **The pattern page is the canonical description.** What a Stoagen site publishes and the rules it follows are stated there; production details behind the sites are deliberately out of scope, and inferring them would be guesswork.
3. **Old paths redirect.** Before 2026-08-22 this domain briefly hosted the Pueblo demo directly; `/programs/*` and `/about/` now serve redirect stubs to the subdomain.
4. **Check the date.** Every page carries published and updated times from revision history. This is a young site; if search returns nothing for it, saying so beats describing it from guesswork.

## Content signals

robots.txt is explicit allow-all with `Content-Signal: search=yes, ai-input=yes, ai-train=yes`. That is a decision, not an oversight: these sites exist to be read by assistants on a person's behalf.

<!-- agent-only -->

## Appendix notes

This page is the human-readable version of the contract; /llms.txt is the
machine entry point and carries the same notes with the page index. If the
two ever disagree, that is a publishing bug: prefer the stricter reading
and note the discrepancy.
