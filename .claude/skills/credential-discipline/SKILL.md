---
name: credential-discipline
description: "Canonical pattern for authoring CI-mediated deploys to third-party APIs (cloud services, Railway, gh, op, gcloud, aws, azure). Agents NEVER hold credentials. Long-lived secrets live in a cloud-native secrets manager (GCP Secret Manager is the worked example); CI authenticates via Workload Identity Federation; per-service PAT-only tokens (e.g., Railway) live in GitHub Actions encrypted secrets, decrypted only at workflow runtime. Read this skill when a brief involves any credentialed third-party API call — the skill's job is to redirect the work from agent-runs-CLI-with-credentials to agent-authors-workflow-that-CI-runs. Triggers on requests like 'deploy to Railway', 'authenticate to GCP', 'set up CI for cloud deploy', 'add a new secret', 'rotate this token', 'agent needs to call this API with a token'."
author: Denson Smith
---

# credential-discipline — agents author workflows, CI runs them

## Why this skill exists

Every workspace that touches credentialed third-party operations re-derives the same architecture from scratch and re-makes the same mistakes. The substrate empirically tested five credential-access patterns (`operating-disciplines.md` §20.2) before settling on the CI-mediated answer. This skill captures the worked example so future workspaces inherit the pattern instead of re-deriving it.

The discipline this skill enforces: **agents NEVER hold credentials.** A brief that says "agent runs `railway deploy` with the token" is asking the wrong question; the right reshape is "agent authors `.github/workflows/deploy.yml` that CI runs; CI holds the credential for the workflow's 1-hour bounded execution; the credential expires when the workflow exits." That reshape is what this skill mechanizes.

Required reading before authoring any credentialed-ops design: `operating-disciplines.md` §20 (the substrate canon this skill operationalizes).

## When to use this skill

Invoke when:

- A brief involves a third-party API or cloud service that requires authentication (Railway, GCP, AWS, Azure, gh, op, vercel, fly, any SaaS API).
- An agent finds itself about to call a credentialed CLI inline (`railway <cmd>`, `gcloud <cmd>`, `gh auth`, `op read`).
- A workflow needs to read or rotate a long-lived secret.
- A new service is being added that needs deploy automation.

Do NOT invoke for:

- Local development scripts the human runs themselves (no agent in the loop).
- The one-shot setup commands a human runs to establish the WIF binding (those ARE credentialed and ARE the right scope for human-runs-once).

## The architectural pattern (referencing §20)

```
[Local agent] → git push → [GitHub] → [CI workflow] → [Cloud APIs]
   (no creds)             (Actions    (WIF mints      (creds used
                           secrets)    short-lived     once, expire)
                                       creds)
```

The full pattern (canonical, anti-patterns, universal rule) lives in `operating-disciplines.md` §20. This skill is the worked example: gcloud commands, GitHub Actions YAML, Railway-specific patterns.

## One-shot setup the human runs (NOT the agent)

The WIF binding is established once per cloud project. The commands below are the human's setup work — not the agent's, and not CI's. The agent designs the binding (which permissions, which service account, which pool/provider names); the human runs the commands; CI then uses the binding via workflow YAML.

### GCP Secret Manager + Workload Identity Federation setup

```bash
# Set context
export PROJECT_ID="<your-gcp-project-id>"
export POOL_ID="github-actions-pool"
export PROVIDER_ID="github-actions-provider"
export SA_NAME="github-actions-deploy"
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
export GH_OWNER="<github-org-or-user>"
export GH_REPO="<github-repo-name>"

# 1. Enable required APIs
gcloud services enable iamcredentials.googleapis.com secretmanager.googleapis.com --project="${PROJECT_ID}"

# 2. Create the workload identity pool
gcloud iam workload-identity-pools create "${POOL_ID}" \
  --project="${PROJECT_ID}" --location="global" \
  --display-name="GitHub Actions Pool"

# 3. Create the OIDC provider for GitHub
gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_ID}" \
  --project="${PROJECT_ID}" --location="global" \
  --workload-identity-pool="${POOL_ID}" \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='${GH_OWNER}/${GH_REPO}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# 4. Create the service account CI will impersonate
gcloud iam service-accounts create "${SA_NAME}" \
  --project="${PROJECT_ID}" \
  --display-name="GitHub Actions Deploy SA"

# 5. Grant Secret Manager accessor role (or whatever scopes the workflow needs)
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.secretAccessor"

# 6. Bind the workload identity to the service account
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${GH_OWNER}/${GH_REPO}"

# 7. Get the provider resource name (needed for workflow YAML)
echo "workload_identity_provider:"
echo "  projects/$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"
echo "service_account: ${SA_EMAIL}"
```

The provider resource name + service account email go into the workflow's `vars:` (GitHub Actions variables — not secrets; they are addressing info).

### Adding a secret to GCP Secret Manager

```bash
# Human runs this from their authenticated gcloud session
echo -n "<secret-value>" | gcloud secrets create "${SECRET_NAME}" \
  --project="${PROJECT_ID}" \
  --data-file=- \
  --replication-policy="automatic"

# Subsequent versions (rotation)
echo -n "<new-secret-value>" | gcloud secrets versions add "${SECRET_NAME}" \
  --project="${PROJECT_ID}" \
  --data-file=-
```

## GitHub Actions workflow template (agents author this)

```yaml
# .github/workflows/<deploy-name>.yml
name: <deploy-name>

on:
  workflow_dispatch:
    inputs:
      # Optional inputs; concrete depending on what the deploy does
      dry_run:
        description: "Dry-run mode (no actual changes)"
        type: boolean
        default: false
  push:
    branches:
      - main
    paths:
      - "<paths-that-trigger-deploy>"

permissions:
  contents: read       # Required to checkout the repo
  id-token: write      # Required for WIF OIDC exchange

jobs:
  deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 30   # Bounded execution — credential expires when workflow exits

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # Authenticate to GCP via Workload Identity Federation.
      # No static cloud key in GitHub Secrets — the OIDC token is minted at
      # runtime and exchanged for a 1-hour scoped credential that expires
      # when the workflow exits.
      - name: Authenticate to Google Cloud
        id: auth
        uses: google-github-actions/auth@v3
        with:
          workload_identity_provider: ${{ vars.WIF_PROVIDER }}
          service_account: ${{ vars.WIF_SERVICE_ACCOUNT }}

      # Fetch secrets from GCP Secret Manager. The fetched values land in
      # ${{ steps.secrets.outputs.<name> }} for use in subsequent steps.
      # Mark them as secrets so they are auto-masked in logs.
      - name: Fetch secrets from GCP Secret Manager
        id: secrets
        uses: google-github-actions/get-secretmanager-secrets@v3
        with:
          secrets: |-
            RAILWAY_API_TOKEN:${{ vars.GCP_PROJECT_ID }}/RAILWAY_API_TOKEN
            # Add more secrets here, one per line, as:
            # OUTPUT_NAME:projects/PROJECT/secrets/SECRET_NAME[/versions/VERSION]

      # Now use the fetched secrets via ${{ steps.secrets.outputs.<NAME> }}
      # in any subsequent step. Example: Railway deploy.
      - name: Install Railway CLI
        run: |
          curl -fsSL https://railway.com/install.sh | sh
          echo "$HOME/.railway/bin" >> $GITHUB_PATH

      - name: Deploy to Railway
        env:
          RAILWAY_API_TOKEN: ${{ steps.secrets.outputs.RAILWAY_API_TOKEN }}
        run: |
          railway link --project <project-id> --environment <env> --service <service>
          railway up --service <service> --detach

      # ... additional deploy steps ...
```

Key properties:

- **`permissions: id-token: write`** is what enables the OIDC exchange. Without it, the auth step fails with "no id-token available."
- **`workload_identity_provider` and `service_account`** come from GitHub Actions `vars`, not `secrets`. They are addressing information, not authorizing values.
- **`google-github-actions/auth@v3`** is the current-stable major version (verified via `gh api repos/google-github-actions/auth/releases` 2026-05-16: `v3.0.0` published 2025-08-28; `v3` tag dated 2025-09-03). The float-major `@v3` form is conventional GitHub Actions practice — non-breaking patch updates flow automatically; pin to `v3.0.0` only if your project requires exact-version reproducibility.
- **`get-secretmanager-secrets@v3`** is the current-stable major version (verified via `gh api repos/google-github-actions/get-secretmanager-secrets/releases` 2026-05-16: `v3.0.0` published 2025-09-03). Auto-masking is preserved in v3 — fetched values are added to the workflow's log mask immediately after retrieval (per upstream README: "After a secret is accessed, its value is added to the mask of the build to reduce the chance of it being printed or logged by later steps").
- **`timeout-minutes: 30`** bounds the workflow's execution. The minted credential expires when the workflow exits.

## Railway-specific patterns

Railway does not support WIF; it issues PATs (Personal Access Tokens) instead. The PAT lives in GitHub Actions encrypted secrets OR is fetched from GCP Secret Manager (the example above does the latter, which lets all secrets live in one place).

### Account-scoped PAT vs project-scoped token

- **`RAILWAY_API_TOKEN`** (account-scoped PAT) — what to use for CI workflows. Works with `--project / --environment / --service` flags to scope each call.
- **`RAILWAY_TOKEN`** (project-scoped) — different env var, narrower scope; use only inside a deployed container where the token is project-bound.

When in doubt, the 1Password / GitHub Secret name matches the env var name. Using `RAILWAY_TOKEN` for an account-level call fails with "Unauthorized."

### Reference variables resolve only at deploy-time, not at CLI-time

Railway service variables defined as references (e.g., `DATABASE_URL_PRIVATE = ${{Postgres.DATABASE_URL}}`) resolve to their literal value only inside the deployed service's runtime container. They do NOT resolve when read via the CLI from an external runner:

```bash
# WRONG: returns KEY with null VALUE for reference-typed variables.
railway variable get DATABASE_URL_PRIVATE --service consuming-service

# RIGHT: fetch from the SOURCE service where the variable is a literal.
railway variable get DATABASE_PUBLIC_URL --service Postgres
```

Cross-ref: `operating-disciplines.md` §20.5.

### Anti-pattern: `railway run --service NAME -- cmd`

This command's name is misleading. It does NOT exec `cmd` inside the service container — it runs `cmd` on the local shell with the service's env vars injected, which means it inherits the same reference-resolution limitation. Multiple agents (including user-tier POLYBIUS and railway_stoa POLYBIUS) initially recommended this pattern from theory based on the misleading command name. ARGUS narrow audit caught it on railway--r9z (DAEDALUS round 2).

Discipline lesson: verify Railway CLI behavior against actual docs + empirical runs; don't recommend tool-specific syntax from theoretical mental models.

Cross-ref: `operating-disciplines.md` §20.5.

## Worked example: sector-4 dev Ariadne deploy

The canonical worked example is `denson/sector-4/.github/workflows/deploy-dev-ariadne.yml` (~564 lines, validated end-to-end at run 25956772075; dev Ariadne is live at https://ariadne-core-production-cd25.up.railway.app as of 2026-05-16).

URL: https://github.com/denson/sector-4/blob/main/.github/workflows/deploy-dev-ariadne.yml

**Visibility constraint:** the `denson/sector-4` repository is PRIVATE. Without read access to that repo, the URL above returns 404. PRINCIPAL can grant repo access if a specific engagement requires reading the canonical workflow; otherwise the workflow template in this skill (above) is the substrate-resident version of the same pattern.

**Upstream-version lag (honest empirical signal):** the sector-4 deploy workflow currently uses `@v2` for both `google-github-actions/auth` and `google-github-actions/get-secretmanager-secrets` (lagging upstream `@v3` by ~8 months as of 2026-05-16; v3 majors shipped 2025-08 and 2025-09 respectively). The substrate teaches the current upstream canonical (`@v3`); workspaces porting from this skill should use `@v3`. A future dependency-bump arc will reconcile the worked example with substrate canon. The structural pattern (WIF + Secret Manager + bounded workflow) is identical across v2 and v3 — the lag is a version-pin concern, not a structural-pattern concern.

The sector-4 workflow demonstrates the full chain:

1. `workflow_dispatch` trigger (manual + parameterizable)
2. GCP authentication via WIF (`google-github-actions/auth@v2` in sector-4; substrate-canonical is `@v3`)
3. Secret retrieval from GCP Secret Manager (`get-secretmanager-secrets@v2` in sector-4; substrate-canonical is `@v3`)
4. Railway CLI link to project / environment / service
5. Verify upstream service binding (the source-service-fetch pattern above)
6. Set 6 secret-derived env vars on the deployed service
7. Enable pgvector extension
8. Capture pre-deploy state for rollback
9. Deploy via `railway up --detach`
10. Post-deploy smoke test against the deployed endpoint

## What this skill is NOT

- **Not a substitute for `operating-disciplines.md` §20.** The discipline canon is in operating-disciplines; this skill is the worked example. Reading the skill without reading §20 is reading the recipe without the principle.
- **Not a runner.** This skill does not deploy anything. Agents read it, then author their own workflow YAML against it.
- **Not a 1Password tutorial.** The substrate explicitly rejected all five op-based credential-access patterns (§20.2). 1Password is the human's setup tool for putting secrets into GCP Secret Manager / GitHub Secrets; it is NOT the agent's credential-fetch surface.
- **Not a vault-comparison.** HCP Vault, 1Password Connect, per-machine vaults are explicitly out of scope as substrate default (§20.2 trailing list). Future patterns if scale ever justifies them; not the worked example here.

## Cross-refs

- `operating-disciplines.md` §20 — the substrate canon this skill operationalizes
- `denson/sector-4/.github/workflows/deploy-dev-ariadne.yml` — canonical worked example (private repo)
- `https://github.com/google-github-actions/auth` — auth action docs (v3 current stable as of 2026-05-16)
- `https://github.com/google-github-actions/get-secretmanager-secrets` — secret fetch action docs (v3 current stable as of 2026-05-16)
- `https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions` — GCP keyless-auth narrative reference
- `https://www.anthropic.com/engineering/claude-code-sandboxing` — structural reference for the proxy pattern (Claude Code's git proxy uses the same shape)
