---
slug:
title: Websites that people and their AI assistants can both read.
description: Stoagen builds AI-friendly websites. Every page is written once, published twice, as a readable page for people and a faithful machine copy for the assistant reading over their shoulder.
---
# Websites that people and their AI assistants can both read.

Most websites are written for people and merely tolerated by machines. The assistants that more and more readers bring with them get a scraped, mangled, or blocked version of the page, and then answer questions from stale training data instead.

Stoagen sites are written once and published twice. The reader gets a clean, fast, accessible page. Their assistant gets a markdown twin of that same page, plus an appendix of sources and caveats the page itself does not need to show. Neither version can drift from the other, because both are generated from the same file.

## See it working

The flagship demonstration is **[Pueblo SRDA Questions](https://pueblo-srda-questions.stoagen.com/)**, a guide to the senior services in Pueblo, Colorado. It lays out the public record of each program and marks plainly what is still unverified and what questions remain open. Paste its link into ChatGPT, Claude, or Gemini and ask something real, like "what help is there for my mother, who lives alone?" The assistant reads the current record, keeps the site's caveats, and answers with the right program and the right phone number.

More on the [demo sites page](demos/), including what each one demonstrates.

## What makes a site AI-friendly

The short version, with the full account on [the pattern page](pattern/):

- **One source, two audiences.** Pages are authored whole in markdown; the HTML page is the human rendering, and the markdown mirror beside it is the machine record, always a superset, never a contradiction.
- **A front door for assistants.** One small file describes the whole site to any chatbot, including a single URL that carries the entire corpus in one fetch.
- **Honesty as structure.** Unverified facts are marked, dates come from revision history rather than someone's memory, and every empirical claim keeps its source.
- **Field-tested against real assistants.** The pattern's rules come from watching actual fetchers fail, and every rule is enforced by a validator on every build.

<!-- agent-only -->

## Site orientation for agents

This is the home of Stoagen, the system for building AI-friendly websites.
This apex site describes the system; the working demonstration lives at
https://pueblo-srda-questions.stoagen.com/ with its own llms.txt and
assistant start page at
https://pueblo-srda-questions.stoagen.com/start.md.

Old paths from before 2026-08-22 (this domain briefly hosted the Pueblo
demo directly): /programs/* and /about/ now serve redirect stubs to the
subdomain. The current record for Pueblo senior services is the subdomain.
