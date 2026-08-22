# Credential discipline — canonical-pattern detail + Railway-specific notes — instruction module

> Relocated from `operating-disciplines.md` §20 (the CONDITIONAL DETAIL only — §20.1 canonical
> pattern, §20.5 Railway-specific notes, §20.6 skill cross-ref). The always-on credential CORE
> (§20-intro structural rule + §20.2 five rejected anti-patterns + §20.3 refusal-as-signal +
> §20.4 universal rule) STAYS INLINE in the slim core. Read this module when authoring a CI
> workflow for credentialed deploy work and you need the worked WIF/secrets-manager chain or the
> Railway-CLI behavior notes. Provenance: composition-layer spec `bw show stoa--xyb.4`; debloat
> Arc 47 cut `agents/design/arc-47/design-rev2.md` + epic `bw show stoa--xyb` / cut ticket
> `bw show stoa--xyb.8`. The slim-core residue is the §20 structural rule (inline) + the
> `<!-- MODULE-INLINE:credential-discipline-detail -->` marker after §20.4 + relocation-index
> row in `operating-disciplines.md` §0.5.

### 20.1 The canonical pattern

```
[Local agent] → git push → [GitHub] → [CI workflow] → [Cloud APIs]
   (no creds)             (Actions    (WIF mints      (creds used
                           secrets)    short-lived     once, expire)
                                       creds)
```

Concretely:

1. **Long-lived secrets** (API keys, signing secrets, identifiers) live in a **cloud-native secrets manager**. GCP Secret Manager is the substrate's worked example (free tier covers our scale: 6 active versions per secret, 10k access ops/month). AWS Secrets Manager and Azure Key Vault are structurally equivalent substitutes; the property is "encrypted at rest, versioned, audited, accessed by CI via short-lived credential," not the specific vendor.

2. **CI authenticates to the cloud via Workload Identity Federation.** GitHub Actions presents an OIDC token at workflow runtime; the cloud exchanges it for a 1-hour scoped credential that expires when the workflow exits. **No static cloud key exists anywhere — not in GitHub, not on dev machines, not on production hosts.**

3. **Per-service tokens that lack WIF support** (e.g., Railway API tokens, third-party SaaS PATs) live in **GitHub Actions encrypted secrets**, decrypted only inside the workflow's bounded execution. The blast radius is the workflow run, not the agent's process tree.

4. **Routing identifiers** (workload-identity provider resource name, service-account email, project IDs) live in **GitHub Actions variables** (not secrets — these are addressing information, not authorizing values; leaking them costs nothing).

5. **Deployed services** receive runtime secrets as env vars set by the workflow at deploy time. Service code stays simple; no runtime calls to a secrets manager from inside the service.

This is structurally what Anthropic ships in production for Claude Code's git proxy (https://www.anthropic.com/engineering/claude-code-sandboxing) — generalized to non-git credentialed services via the cloud-secrets-manager + WIF chain.

### 20.5 Railway-specific notes (canonization from railway--r9z empirical findings)

Two Railway-specific patterns surfaced during railway--r9z's CI workflow first-run + revise arc that are load-bearing for any future Railway-deploy workflow. They live in the substrate doc because the empirical agent (and multiple peer agents recommending from theory) initially got both wrong.

**Pattern: Railway reference variables resolve ONLY at deploy-time, not at CLI-time.** A Railway service variable defined as a reference (e.g., `DATABASE_URL_PRIVATE = ${{Postgres.DATABASE_URL}}`) resolves to its literal value only inside the deployed service's runtime container. It does NOT resolve when read via `railway variable list --service NAME --json` from an external runner — the CLI returns the KEY with a null VALUE.

The canonical workaround: any CI workflow that needs the resolved value must fetch from the SOURCE service's variable list, where the variable is a literal:

```bash
# WRONG: returns null for reference-typed variables.
railway variable get DATABASE_URL_PRIVATE --service consuming-service

# RIGHT: fetch from the source where the value is a literal.
railway variable get DATABASE_PUBLIC_URL --service Postgres
```

**Anti-pattern: `railway run --service NAME -- cmd`.** This command's name is misleading. It does NOT exec `cmd` inside the service container — it runs `cmd` on the local shell with the service's env vars injected, which means it inherits the same reference-resolution limitation (references still don't resolve, because resolution happens at container start). Multiple agents — including user-tier POLYBIUS and railway_stoa POLYBIUS — initially recommended this pattern from theory based on the misleading command name. ARGUS narrow audit caught it on railway--r9z (DAEDALUS round 2). The discipline lesson: verify Railway CLI behavior against actual docs + empirical runs; don't recommend tool-specific syntax from theoretical mental models.

### 20.6 Cross-reference

The new substrate-tier skill at `substrate/skills/credential-discipline/SKILL.md` carries the worked example: gcloud commands for WIF pool + provider + service account setup, GitHub Actions YAML for `google-github-actions/auth@v3` + `get-secretmanager-secrets@v3` (current-stable majors as of 2026-05-16, verified via `gh api`), Railway-specific patterns for PAT-based services that lack WIF, and the canonical worked-example workflow at `denson/sector-4/.github/workflows/deploy-dev-ariadne.yml` (run 25956772075, dev Ariadne live as of 2026-05-16; note the sector-4 workflow currently pins both actions at `@v2`, lagging upstream by ~8 months — substrate canon is `@v3`).
