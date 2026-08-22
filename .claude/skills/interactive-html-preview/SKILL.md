---
name: interactive-html-preview
description: |
  Build a self-contained interactive HTML "surface" (decision dashboard, categorized inventory, visual tradeoff) and render + verify + interact with it live via the Claude Preview MCP, on Claude Code Desktop (Mac/Windows). This is the rendering layer for the decision-surface skill and any task that needs a rich visual artifact the human can read and manipulate — plus a shareable HTML documentation artifact at the end. It carries the VERIFIED mechanics (confirmed 2026-06-04 building the debloat decision-surface): how Preview actually works (a dev server from launch.json, NOT a direct static-file open), the build→serve→render→verify→interact loop, and the gotchas. Builder-tier (Preview ships with Claude Code Desktop); for consumers the self-contained HTML file is the graceful fallback — it opens in any browser.

  Invoke when building an HTML presentation/dashboard to help a human understand or decide something, when asked to "render this in Preview", "make an interactive HTML surface", "show me a dashboard", or as the Part-2 rendering of decision-surface. Triggers: "build the html presentation", "preview this html", "interactive decision dashboard", "render and verify the html".
author: Denson Smith
---

# interactive-html-preview — build + render an interactive HTML surface via Preview

> **Verified mechanics, not theory.** Every step below was confirmed by building + rendering the debloat decision-surface (`docs/debloat-decision-surface.html`) on 2026-06-04. The Preview tools carry their own descriptions; this skill adds the WORKING LOOP and the gotchas those descriptions don't make obvious.

## The one fact that trips you up
`preview_start` runs a **dev server defined in `.claude/launch.json`** — it does **not** open a static HTML file directly. To preview a self-contained HTML file you first need a server that serves it. The cheapest is Python's stdlib:

```jsonc
// .claude/launch.json — READ it first, then ADD a config (never clobber existing ones)
{ "name": "stoa-docs", "runtimeExecutable": "python",
  "runtimeArgs": ["-m", "http.server", "8765", "--directory", "docs"], "port": 8765 }
```

`--directory docs` serves `docs/` at the server root, so `docs/x.html` lives at `http://localhost:8765/x.html`. The case-study `architecture-kg.html` uses this exact pattern (the `stoa-kg` config) — established Stoa precedent.

## The loop: build → serve → render → verify → interact
1. **Build a SELF-CONTAINED HTML** — CSS + JS inline, zero external deps. Two payoffs: it renders identically in Preview *and* opens directly in any browser (the consumer-tier fallback when there's no Preview), and it's one shareable artifact.
2. **Ensure a launch.json server** for the file's directory (Read launch.json first; add a config, don't clobber).
3. **`preview_start({ name })`** → returns a `serverId` (reuses the server if already running).
4. **Navigate** to the file: `preview_eval(serverId, "window.location.href='http://localhost:<port>/<file>.html'")`. The server root is a directory listing — navigate to the specific file.
5. **Verify the render — do NOT assume it worked:**
   - `preview_screenshot` → the visual (layout/appearance). **Do NOT trust screenshots for colors / fonts / spacing** — use `preview_inspect` for those.
   - `preview_console_logs(level:"error")` → catch JS errors.
   - `preview_eval(serverId, "document.querySelectorAll('.card').length")` → confirm the JS rendered the data (all N rows present).
   - `preview_snapshot` → a11y tree; the **best** tool for verifying text content + element presence.
   - `preview_inspect(selector, ['color','padding',…])` → exact computed styles.
6. **Interact** (drive the live surface): `preview_click(selector)`, `preview_fill(selector, value)` (selects match by value or text), `preview_resize({preset|width,height, colorScheme})` for responsive + dark-mode.

## Patterns that work
- **Markdown = truth, HTML = view.** For a durable surface, keep the decision DATA in markdown (agent-readable, diffable, version-controlled) and generate/embed it into the HTML view. Agents read the markdown; humans get the rich HTML. (A v1 may embed data straight in the HTML; extract to a markdown source when it needs to be canonical.)
- **Persist human input client-side** with `localStorage`, so the surface is a *working tool* across reloads (e.g. a "your call" selector on each row that survives refresh).
- **Scale richness to stakes.** A simple call needs plain markdown; reserve the interactive dashboard for high-stakes / multi-dimensional decisions. Don't pay the build complexity on every surface.

## Gotchas (verified)
- **Preview is a Claude Code Desktop MCP.** Guaranteed for *builders* (Desktop, Mac/Windows); *consumers* may not have it → which is exactly why the HTML must be a self-contained file that also opens in a plain browser.
- **`preview_eval` is for debugging / inspection / navigation ONLY.** Its DOM edits are temporary and lost on reload. To change the UI, edit the **source file** and reload — never patch via eval.
- **No direct static-file open** — you always need the dev server.
- **`preview_start` reuses a running server** — pass the same `name` (or check `preview_list`); `preview_stop(serverId)` to tear down.

## Cross-references
- `docs/capability-registry.md` — Preview's verified entry + the verify-don't-assume methodology that produced it.
- `docs/case-study/architecture-kg.html` + `.claude/launch.json` (`stoa-kg`) — the precedent this generalizes.
- `decision-surface` skill (forthcoming) — this is its Part-2 rendering layer: that skill holds the dilemma-vs-problem decision *logic*; this one holds how to *render* it.
- **Worked example: `../decision-surface/worked-example-debloat.md`** — the canonical end-to-end run (the 2026-06-04 substrate-debloat surface) showing both skills together: frame problem-vs-dilemma → ground every call in the real source via a fan-out workflow → surface honest proposed→grounded revisions → render + verify in Preview. The headline lesson (don't propose from memory; grounding revised 11 of 34 calls) is decision-surface canon; the build→serve→render→verify mechanics are this skill's.
