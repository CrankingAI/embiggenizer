// Embiggenizer: show the user's text at the largest font size that fits the
// viewport, wrapping only between words.
"use strict";

const IDLE_MS = 2000;

const editor = document.getElementById("editor");
const form = document.getElementById("form");
const textInput = document.getElementById("text");
const hint = document.getElementById("hint");
const stage = document.getElementById("stage");
const big = document.getElementById("big");
const backButton = document.getElementById("back");
const fullscreenButton = document.getElementById("fullscreen");
const videoChoices = document.querySelectorAll(".video-choice");
const player = document.getElementById("player");
const playerFrame = document.getElementById("player-frame");
const closeVideoButton = document.getElementById("close-video");

let idleTimer = 0;
let fitFrame = 0;

function fitsAt(size, availableHeight) {
  big.style.fontSize = `${size}px`;
  return big.scrollWidth <= big.clientWidth && big.scrollHeight <= availableHeight;
}

// Binary-search the largest whole-pixel font size at which the text fits
// inside the stage's content box without overflowing either axis. A word that
// is too wide for the screen shrinks the whole text rather than breaking.
function fit() {
  stage.classList.remove("overflowing");
  const style = getComputedStyle(stage);
  const availableHeight =
    stage.clientHeight - parseFloat(style.paddingTop) - parseFloat(style.paddingBottom);

  let low = 1;
  let high = Math.max(1, Math.floor(availableHeight));
  while (low < high) {
    const mid = Math.ceil((low + high) / 2);
    if (fitsAt(mid, availableHeight)) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  // Text too long to fit even at 1px scrolls rather than being clipped.
  stage.classList.toggle("overflowing", !fitsAt(low, availableHeight));
}

function scheduleFit() {
  cancelAnimationFrame(fitFrame);
  fitFrame = requestAnimationFrame(fit);
}

function wake() {
  stage.classList.remove("idle");
  clearTimeout(idleTimer);
  idleTimer = setTimeout(() => stage.classList.add("idle"), IDLE_MS);
}

function isShowing() {
  return !stage.hidden;
}

// A video left playing would go on behind the text with its controls hidden,
// so it stops.
function enter() {
  stopVideo();
  editor.hidden = true;
  stage.hidden = false;
  fit();
  wake();
  stage.focus();
}

function show(text) {
  big.textContent = text;
  enter();
  history.pushState({ embiggenized: true }, "");
}

function hide() {
  if (!isShowing()) return;
  clearTimeout(idleTimer);
  if (document.fullscreenElement) {
    document.exitFullscreen().catch(() => {});
  }
  stage.hidden = true;
  editor.hidden = false;
  textInput.focus();
}

// Leaving the stage goes through history, so the browser's Back button and
// gesture behave the same as the on-screen Back button and Esc. A page opened
// from a ?msg= link has no editor entry behind it, so the on-screen Back
// turns the link's entry into the editor, dropping ?msg= from the address.
function goBack() {
  const state = history.state || {};
  if (state.linked) {
    history.replaceState(null, "", location.pathname);
    hide();
  } else if (state.embiggenized) {
    history.back();
  } else {
    hide();
  }
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  const text = textInput.value.trim();
  if (!text) {
    hint.textContent = "Type something to embiggenize.";
    textInput.focus();
    return;
  }
  hint.textContent = "";
  show(text);
});

textInput.addEventListener("keydown", (event) => {
  if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
    event.preventDefault();
    form.requestSubmit();
  }
});

textInput.addEventListener("input", () => {
  if (hint.textContent && textInput.value.trim()) hint.textContent = "";
});

backButton.addEventListener("click", goBack);

stage.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    event.preventDefault();
    goBack();
  } else {
    wake();
  }
});

stage.addEventListener("pointermove", wake);
stage.addEventListener("pointerdown", wake);

// Back leaves the stage; Forward returns to it. An entry left over from
// before a reload has no text to show, so it is cleared rather than kept.
window.addEventListener("popstate", (event) => {
  const embiggenized = Boolean(event.state && event.state.embiggenized);
  if (embiggenized && big.textContent) {
    enter();
  } else {
    if (embiggenized) history.replaceState(null, "");
    hide();
  }
});

// Nothing loads from YouTube until the visitor picks a video. The page sends
// no referrer, but YouTube's player refuses to start without one (error
// 153), so this frame alone sends the site's origin, never the path.
function playVideo(choice) {
  const frame = document.createElement("iframe");
  frame.src =
    `https://www.youtube-nocookie.com/embed/${choice.dataset.video}` +
    "?autoplay=1&playsinline=1&rel=0";
  frame.title = choice.querySelector(".video-title").textContent;
  frame.allow = "autoplay; encrypted-media; fullscreen; picture-in-picture";
  frame.referrerPolicy = "strict-origin-when-cross-origin";
  playerFrame.replaceChildren(frame);
  player.hidden = false;
  for (const other of videoChoices) {
    other.setAttribute("aria-pressed", String(other === choice));
  }
}

// Removing the frame stops the video.
function stopVideo() {
  playerFrame.replaceChildren();
  player.hidden = true;
  for (const choice of videoChoices) {
    choice.setAttribute("aria-pressed", "false");
  }
}

function closeVideo() {
  const playing = document.querySelector('.video-choice[aria-pressed="true"]');
  stopVideo();
  if (playing) playing.focus();
}

for (const choice of videoChoices) {
  choice.addEventListener("click", () => {
    if (choice.getAttribute("aria-pressed") === "true") {
      closeVideo();
    } else {
      playVideo(choice);
    }
  });
}

closeVideoButton.addEventListener("click", closeVideo);

new ResizeObserver(() => {
  if (isShowing()) scheduleFit();
}).observe(stage);

if (document.fullscreenEnabled) {
  fullscreenButton.hidden = false;
  fullscreenButton.addEventListener("click", () => {
    if (document.fullscreenElement) {
      document.exitFullscreen().catch(() => {});
    } else {
      document.documentElement.requestFullscreen().catch(() => {});
    }
  });
  document.addEventListener("fullscreenchange", () => {
    fullscreenButton.textContent = document.fullscreenElement ? "Exit full screen" : "Full screen";
  });
}

// A link such as /?msg=Hello opens straight to the big text, which is also
// put in the editor. As in any query string, + is a space, and &, # and +
// themselves must be written %26, %23 and %2B. The link's own history entry
// shows the text, so the browser's Back returns to wherever the link was
// opened from. Adding an entry here instead would not work: Chrome's Back
// button skips past a page that adds history entries before the visitor has
// clicked or typed anything.
const linkedText = (new URLSearchParams(location.search).get("msg") || "").trim();

if (linkedText) {
  textInput.value = linkedText;
  big.textContent = linkedText;
  history.replaceState({ embiggenized: true, linked: true }, "");
  enter();
} else {
  // A reload while the text was showing starts in the editor, so drop the
  // stale history entry rather than leaving Back pointed at nothing.
  if (history.state && history.state.embiggenized) {
    history.replaceState(null, "");
  }
  textInput.focus();
}
