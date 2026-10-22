# AGENTS.md

The Embiggenizer: a one-page static site that shows the user's text at the
largest size that fits the screen. See [README.md](README.md).

## Layout

```text
src/                 the whole site, uploaded as-is (no build step)
  staticwebapp.config.json   security headers, including a strict CSP
scripts/             provision-swa.sh (once), deploy-site.sh (each release)
  lib/target.sh      subscription, resource group and app names
docs/decisions/      decision records; read before changing what they cover
docs/decision-backlog/  questions nobody has decided yet
```

## Rules

- **No backend, no build, no dependencies.** Plain HTML, CSS and JavaScript.
  Adding any of them is a decision: record it in `docs/decisions/`.
- **Keep the CSP strict.** No inline scripts or styles, no third-party
  origins. A change that needs one updates `staticwebapp.config.json` and
  says why.
- **Accessible:** keyboard-operable, visible focus, labelled controls,
  `prefers-reduced-motion` respected (WCAG 2.2 AA).
- **Scripts** follow DevPartners agent-kit's `devp-scripts-convention`:
  verb-first names from its lifecycle vocabulary, `-h/--help`,
  `set -euo pipefail`, `--subscription` passed on every `az` call and
  never `az account set`, macOS Bash 3.2 compatible. Check with
  `bash -n` and `shellcheck scripts/*.sh scripts/lib/*.sh`.
- **Decisions** follow agent-kit's `devp-decision-records` (MADR 4.0 Bare
  Minimal). Check with `<agent-kit>/scripts/validate-decisions.sh .`.

## Verify a change

1. `python3 -m http.server --directory src 8765` and try it at
   <http://localhost:8765/>: short text, a long word, line breaks, Esc and
   Back, a narrow window.
2. `./scripts/deploy-site.sh --dry-run`, then `./scripts/deploy-site.sh`,
   which smoke-tests both URLs.
