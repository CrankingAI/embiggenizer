---
status: accepted
date: 2026-10-22
decision-makers:
---

# Play YouTube videos inline, loading YouTube only when a visitor picks one

## Context and Problem Statement

The owner asked the main screen to offer three YouTube videos about the word
"embiggen", played inline. Until now the page loaded nothing from another
origin, its CSP allowed no frames, and it sent no referrer. YouTube's player
won't start without a referrer (it shows error 153). How should the page
play the videos while giving up as little of that as it can?

## Considered Options

- A button per video; the YouTube frame is created only after a visitor
  clicks one, from `www.youtube-nocookie.com`
- Embed all three players when the page loads
- Link to the videos on YouTube instead of playing them in the page

## Decision Outcome

Chosen option: "A button per video; the YouTube frame is created only after
a visitor clicks one, from `www.youtube-nocookie.com`", because it plays
inline as asked, and a visitor who doesn't pick a video sends nothing to
YouTube. The buttons are plain text, with no thumbnails, which would also
load from YouTube.

- `staticwebapp.config.json`: the CSP gains
  `frame-src https://www.youtube-nocookie.com`, and Permissions-Policy lets
  that origin use full screen. No other origin is allowed.
- The page keeps `Referrer-Policy: no-referrer`. Only the video frame sets
  `referrerpolicy="strict-origin-when-cross-origin"`, so YouTube gets the
  site's origin and never the path.
- The frame is removed, which stops the video, when the visitor closes it
  or embiggenizes text, since the video's controls are hidden behind the
  text.

### Consequences

- Good, because a visitor can watch without leaving the page, and the page
  load contacts no third party.
- Bad, because the CSP now allows one third-party frame, and a visitor who
  picks a video is subject to YouTube's own privacy terms.
- Bad, because two of the three are fan uploads of *The Simpsons*, which
  YouTube may take down. The player then says the video is unavailable, and
  the button should be removed or pointed at another upload.

### Confirmation

`curl -sI` on either URL shows the `frame-src` and `fullscreen` entries. On
the page, picking each video plays it, and the browser console shows no
CSP or Permissions-Policy errors.

## More Information

- The videos, by YouTube ID: `jno3nXowcyQ` (CLIPS TV), `DMEvFgp6vlY` (The
  Max Power Way) and `WTzGnRQ9cfA` (The A.V. Club, Pop Lexicon).
- YouTube's privacy-enhanced mode:
  <https://support.google.com/youtube/answer/171780>
- Error 153 and the referrer:
  <https://simonwillison.net/2025/Dec/1/youtube-embed-153-error/>
