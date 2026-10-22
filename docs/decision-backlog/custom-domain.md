# Which custom domain should the Embiggenizer use?

Until there is one, the shareable URL is the `embiggenizer` named
environment ([ADR-0001](../decisions/0001-static-web-app-free-tier-with-named-environment.md)).
Nobody has picked or bought a domain yet.

## What is known

Checked 2026-10-22:

- Production: <https://kind-flower-026e62e0f.6.azurestaticapps.net/>
- Named environment: <https://kind-flower-026e62e0f-embiggenizer.eastus2.6.azurestaticapps.net/>
- The Free tier allows two custom domains per app, with a free managed
  certificate.

## Options

- **Buy a domain and attach it to production.** Then delete the named
  environment, and stop `scripts/deploy-site.sh` deploying to it.
- **Use a subdomain of a domain CrankingAI already owns.** No purchase, but
  the word "embiggenizer" is no longer the whole name.

## Open questions

- Which domain, and who registers it.

## Re-check

```bash
az staticwebapp environment list --subscription 32c6835c-b37c-47d6-b34a-fbd262a70ef9 \
  --resource-group rg-embiggenizer --name swa-embiggenizer \
  --query "[].[buildId, hostname]" --output tsv
```
