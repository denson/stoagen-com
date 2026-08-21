# stoagen-com

Source for **stoagen.com** — the home of the Stoagen system: websites that
people and their AI assistants can both read faithfully. This apex site
describes the pattern and links the working demonstrations; the flagship
demo lives at https://pueblo-srda-questions.stoagen.com/ (repo:
denson/pueblo-srda-questions).

## Build

```
python site-src/build_site.py
python site-src/validate_site.py
```

Output lands in `public/` (gitignored). CI runs both on every pull request;
only `main` deploys to GitHub Pages. The build also emits redirect stubs
for the paths that belonged to the Pueblo demo before it moved to its
subdomain.

Author: Denson Smith.
