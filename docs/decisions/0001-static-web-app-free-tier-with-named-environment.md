---
status: accepted
date: 2026-10-22
decision-makers:
---

# Host on a Free-tier Azure Static Web App, with a named environment for a readable URL

## Context and Problem Statement

The Embiggenizer is one page of HTML, CSS and JavaScript. It has no backend
and stores nothing. It needs a public URL now, and a custom domain may not
come for a while. An Azure Static Web App's production hostname is generated
(`kind-flower-026e62e0f.6.azurestaticapps.net`) and can't be chosen. How
should the site be hosted, and how does it get a URL that says
"embiggenizer" before it has a domain?

## Considered Options

- Azure Static Web App, Free tier, deployed to production and to a named
  environment called `embiggenizer`
- Azure Static Web App, production environment only
- Azure Storage static website, whose account name sets the hostname

## Decision Outcome

Chosen option: "Azure Static Web App, Free tier, deployed to production and
to a named environment called `embiggenizer`", because Static Web Apps was
the requested host, and a named environment's hostname contains its name:
`kind-flower-026e62e0f-embiggenizer.eastus2.6.azurestaticapps.net`.

- Subscription EffAz-Run, region `eastus2`, resource group
  `rg-embiggenizer`, app `swa-embiggenizer`.
- No build step and no dependencies: `src/` is uploaded as it is.
- `scripts/deploy-site.sh` uploads the same files to both environments on
  every deploy, so they never differ.

### Consequences

- Good, because it costs nothing on the Free tier and needs no server.
- Good, because the URL to share contains "embiggenizer" today.
- Bad, because that URL still carries the generated prefix, and the Free
  tier allows only three named environments, one of which this uses.
- Neutral, because a custom domain attaches to the production environment,
  after which the named environment can be deleted.

### Confirmation

`./scripts/deploy-site.sh` ends by fetching both URLs and fails unless each
one serves the page.

## More Information

- Revisit when a domain is bought: see
  [../decision-backlog/custom-domain.md](../decision-backlog/custom-domain.md).
- Named environments:
  <https://learn.microsoft.com/azure/static-web-apps/named-environments>
- 2026-10-22: moved from EffAz-Prod to EffAz-Run at the owner's request,
  by an Azure resource move, which kept both hostnames.
