# embiggenizer

You give some text and it displays it as large as possible within available
screen real estate. The word "embiggen" comes from the 1996 Simpsons episode
["Lisa the Iconoclast"](https://www.imdb.com/title/tt0701155/).

**Live:** <https://kind-flower-026e62e0f-embiggenizer.eastus2.6.azurestaticapps.net/>
(also at the production hostname,
<https://kind-flower-026e62e0f.6.azurestaticapps.net/>, until there is a
custom domain)

## How it works

Type text, press **Embiggenize** (or `Ctrl+Enter`, `⌘+Enter` on a Mac),
and the text fills the window. A binary search finds the largest font size
at which the text fits both ways, wrapping only between words. It refits
whenever the window changes size. **Full screen** uses the whole display;
**Back**, `Esc` or the browser's Back button returns to the editor.

Below the editor, three short videos explain where "embiggen" comes from.
Nothing loads from YouTube until a visitor picks one, and then it plays in
the page from `youtube-nocookie.com`
([ADR-0002](docs/decisions/0002-play-youtube-videos-only-when-picked.md)).

It is one static page in [`src/`](src/): HTML, CSS and JavaScript with no
build step, no dependencies and no backend. Nothing you type leaves the
browser.

## Run it locally

```bash
python3 -m http.server --directory src 8765   # then open http://localhost:8765/
```

## Deploy

Hosted on an Azure Static Web App (Free tier) in the EffAz-Run subscription.
Why, and why there are two URLs:
[ADR-0001](docs/decisions/0001-static-web-app-free-tier-with-named-environment.md).

```bash
az login
./scripts/provision-swa.sh     # once; idempotent
./scripts/deploy-site.sh       # every release; --dry-run to preview
```

`deploy-site.sh` uploads `src/` to both environments and fails unless each
URL then serves the page.
