# HANDOFF — Polybius the Stoagen — 2026-08-22 (pre-compaction)

Author: Denson Smith. Seat: Polybius the Stoagen (the seat working stoagen-com
and, by u--xal, the Ethiopia build-story site), on the laptop
(DESKTOP-3B02H5L). This handoff indexes tickets and state; it does not
duplicate them. Resume with `bw prime` in each repo and `bw show` on the
tickets below.

## Machine and toolchain (this laptop, NOT the reference desktop)

- Projects root: `C:\claude_projects` (the Grand's kit paths say
  `C:\Users\denso\claude_projects`; that is the other machine).
- bw 0.13.2 at `C:\Users\denso\.local\bin\bw.exe` (installed this session via
  the-stoa `substrate/bootstrap-bw.sh`; on a new shell `bw` is on PATH; in
  this session call it by full path).
- the-stoa cloned at `C:\claude_projects\the-stoa` (9e612d2a). Substrate
  installed into `stoagen-com/.claude` as CAPABILITY NOT DEFAULT (PRINCIPAL
  ruling): say-trigger activation only, hooks inert. Committed 116edbf.
- Standing rules from today: never touch Cloudflare without PRINCIPAL's
  per-instance authorization (the harness also blocks browser control on
  dash.cloudflare.com); report times in UTC, labeled; there is NO zero-JS
  law (the rule is readable-with-JS-off, one script per page); the
  two-filter agent law (mechanical reachability AND trust) governs every
  agent affordance; playbook at `docs/building-agent-friendly-sites.md`.

## Repos and sites (all live, HTTPS enforced)

| Repo | Local | Site | bw prefix / START HERE |
|---|---|---|---|
| denson/stoagen-com | C:\claude_projects\stoagen-com | https://stoagen.com/ | sg- / sg-re7 |
| denson/pueblo-srda-questions | C:\claude_projects\stoagen-site (dir predates rename) | https://pueblo-srda-questions.stoagen.com/ | psq- / psq-zue |
| denson/aroma-atlas | C:\claude_projects\aroma-atlas | https://denson.github.io/aroma-atlas/ | aa- / aa-x5a |
| denson/cannabis-review-project | C:\claude_projects\cannabis-review-project | https://colorado-medical-cannabis.org/ | GH issues 195, 196, 198, 199 |
| denson/user-beadwork | C:\claude_projects\user-beadwork | (user tier) | u-- / u--xal, u--0dx |
| denson/ethiopia-build | C:\claude_projects\ethiopia-build | https://ethiopia-build.stoagen.com/ (DNS pending) | eb- / eb-hx4 |

All three Stoagen sites: licensed CC BY 4.0 (content) + MIT (code); copy
box "Tell me about this site: <domain>/full_site.txt"; descriptive ask-AI
strip; llms.txt; start.md; validators enforce all of it. Google Search
Console: stoagen.com and colorado-medical-cannabis.org verified and
submitted; the pueblo subdomain property NOT yet added (token already
served; one Verify click).

## Active tickets and their state

- **sg-re7** (stoagen-com, in_progress): steps 1, 2, 3, 5 done and recorded.
  OPEN: step 4, one child ticket per thing stoagen.com needs. PRINCIPAL has
  not yet supplied the list. Close when child tickets exist.
- **u--xal** (user-beadwork, open, P1): the Ethiopia build-story site.
  Done: package unpacked from PRINCIPAL's thumb drive into
  `C:\claude_projects\ethiopia-archive\unpacked\` (ethiopia-program 3.9 GB
  95,019 files; oo-ld-corpus; coffee_and_el_nino_article; user-beadwork
  subset; transcripts in `transcripts-PRIVATE`); GitHub clones with beadwork
  branches in `C:\claude_projects\ethiopia-archive\`; report and the five
  key documents read end to end; step 3 decided by PRINCIPAL: own repo
  `denson/ethiopia-build` (not yet created), subdomain
  `ethiopia-build.stoagen.com`, bw prefix eb. Step 4: 27-page outline
  proposed (home; sources; speech datasets; ingestion; three graph
  generations; convergence; evidence model; fifteen-problems hub plus one
  page per problem; seats; timeline; open items; evidence map; agent access;
  plus a proposed delivery-tiers page) - AWAITING PRINCIPAL'S GO. Design:
  PRINCIPAL is running Claude Design on an existing design system with two
  materials files in Downloads (`ethiopia-build-site-content.md`, the
  report); the export zip path will arrive in chat; encode it into the new
  site's stylesheet. This site will exceed the ~100 KB single-fetch ceiling:
  front door is `site_guide.txt` (map), per the playbook.
  RULINGS: humans by role only (the Amharic reviewer is "a native Amharic
  speaker who is also a data scientist"); redaction rule HARD (u--6bh, Grand
  Ethiopian charter, MEMO_alazar-*/ALAZAR_*, step0/seed/chain/feasibility/
  reverse-trade memos, private transcript passages; also exclude the YouTube
  channel handle named in PROJECT-RECORD and the family-gate passage in the
  tiers brief). OPEN QUESTION to PRINCIPAL: did the Amharic review reading
  come back since the report?
  Next: on "go", create the repo on the stoagen-com pipeline (copy build,
  validator, CSS; add site_guide.txt generation + validator), file one
  eb- ticket per page under u--xal's direction, draft pages from the report
  citing evidence paths in each appendix, re-verify against the package.
- **psq-zue**, **aa-x5a**: START HERE tickets, nothing pending.
- **u--0dx**: the kit; read. Replies to the Grand only via
  `[for: Polybius the Grand]` on sg- tickets.

## Update 2026-08-22 ~15:20 UTC

The Claude Design export arrived and the Ethiopia site was built and deployed
(28 pages, repo denson/ethiopia-build, eb-hx4 START HERE, 28 page tickets,
progress posted on u--xal). Design export unpacked at
`C:\claude_projects\ethiopia-build-design\`. Pages is on, custom domain set;
the site resolves once the PRINCIPAL adds the Cloudflare CNAME
`ethiopia-build -> denson.github.io` (DNS only). Then: enforce HTTPS on the
repo, Search Console property, and decide whether stoagen.com/demos/ lists it.

## Pending from PRINCIPAL

1. Edits to the Ethiopia site pages (via eb- tickets).
2. The Cloudflare CNAME for ethiopia-build (then HTTPS + GSC).
3. The list of things stoagen.com needs (sg-re7 step 4).
4. Whether the Amharic review reading came back.
5. Search Console property for pueblo-srda-questions.stoagen.com (one click).
