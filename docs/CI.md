# CI — Workflows canoniques

## Workflows
- **sanity-main.yml** — `push` & `workflow_dispatch`  
  Génère `.ci-out/diag.json` + `.ci-out/diag.ts`, pack `.tgz`, upload artifact **sanity-diag**.
- **sanity-echo.yml** — `workflow_dispatch` simple (sanity ping).
- **ci-yaml-check.yml** — vérification simple de structure YAML des workflows.

## Déclenchement manuel
```bash
# via GitHub CLI (REST)
gh api repos/:owner/:repo/actions/workflows/sanity-main.yml/dispatches \
  --method POST -f ref=main

# fallback (push vide)
git commit --allow-empty -m "ci(sanity-main): retrigger $(date +%Y%m%dT%H%M%S)" --no-verify && git push

