# Site source — rules that hold regardless of the task

This directory builds `stoagen.com`, the home of the Stoagen system.
`public/` is generated output; never edit it. Edit `site-src/` and run the build.

Voice: plain, confident, concrete. No emoji, no exclamation points, no
em-dashes in reader-facing prose, no marketing superlatives. The published
pattern is the subject; production details behind the sites are out of
scope on this site, deliberately.

## Pages are Markdown; the page is a subset of them

Write the whole document — prose, sources, cautions — in one file under
`content/`. Everything after `<!-- agent-only -->` goes to the Markdown
mirror and never to the page. The HTML page is the part above the marker,
rewritten for human readability.

The mirror is a **superset**: it may carry more than the page, it may never
carry less, and the two may never contradict each other.

## Dates are derived, never typed

Published and last-updated come from the file's commit history, UTC to the
minute. There is no date field in front matter. A file with no `main`
history renders as a draft, which is correct. CI needs `fetch-depth: 0`.

## Hard constraints

- **One script per page**, the deferred copy-box enhancer. Content must
  stay readable with JavaScript off; the validator enforces both.
  Everything must work read-only, with large type, and print cleanly.
- **robots.txt is allow-all with `Content-Signal: search=yes, ai-input=yes,
  ai-train=yes`.** That is a decision, not an oversight. Do not narrow it.
- Front matter keys: `slug`, `title`, `description`, optional `eyebrow`.

## Always run both

```
python site-src/build_site.py
python site-src/validate_site.py
```

CI runs both on every pull request and only `main` deploys.
