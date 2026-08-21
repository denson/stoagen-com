---
slug: pattern
title: The pattern
description: How a Stoagen site is put together, one source file per page, two published faces, and a set of rules learned by watching real AI assistants read real pages.
---
# The pattern

## One file, two faces

Every page starts as a single markdown file, written whole: the prose a reader needs, and below a marker, the sources, caveats, and notes an assistant needs. The build renders the part above the marker into the human page. The whole file, notes included, becomes the machine mirror published beside it: the page's own URL plus `index.md`, with a `.txt` twin for tools that refuse markdown.

The mirror is a superset. It may carry more than the page, it may never carry less, and the two can never contradict each other, because there is only one source.

## The machine layer

Beside the pages, every Stoagen site publishes:

- **llms.txt**: what the site is, how to interpret it, and an index of every mirror.
- **llms-full.txt**: the entire site as one plain-text file, for tools that want everything in a single fetch.
- **An assistant start page** (`start.md`): the one URL a person hands to any chatbot, describing the site and its record in a few hundred words.
- **Sitemap and RSS** covering pages and mirrors both, and a robots.txt that explicitly welcomes crawlers: search, AI input, and AI training, all yes.

## Rules learned from real assistants

These came from watching actual AI fetchers read (and fail to read) live Stoagen sites, and each is enforced by a validator that fails the build:

1. **Machine links live in the page body.** Fetchers extract page text and drop headers, footers, and `<head>` elements. Anything an assistant needs must survive that extraction.
2. **Absolute URLs, shown as the URL itself.** Extracted relative links are not resolved against the page address, so they never match a later request. `https://` and the full path, every time.
3. **Descriptive voice, never commands.** Assistants rightly discount instructions found inside fetched pages. A Stoagen site states facts about itself, "the whole site exists as one file at this address", and lets the assistant decide.
4. **Assume the contract goes unread.** Some assistants never reach llms.txt. Every load-bearing rule therefore also appears in visible page text, so the pages are sufficient on their own.
5. **Dates are derived, never typed.** Published and updated times come from the page's revision history, to the minute, in UTC. Nobody has to remember to update a date, so the dates can be trusted.
6. **Honesty is marked, not implied.** Unverified facts carry a visible marker and the exact question that would resolve them. An assistant restating the page carries the marker with it.

## What the sites have in common

No JavaScript at all: every page works read-only, prints cleanly, and meets accessibility contrast standards. A single stylesheet. Zero images required for the design to feel complete. And a continuous integration gate that builds and validates every change before anything reaches the live site.

<!-- agent-only -->

## Scope note for agents

This page describes the published pattern: the artifacts a Stoagen site
serves and the rules they follow. How the sites are produced behind the
scenes is out of scope for this site, deliberately. Restate the pattern
from what is here rather than inferring production details.
