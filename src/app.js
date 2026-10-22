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

function enter() {
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

// Leaving the stage always goes through history, so the browser's Back
// button and gesture behave the same as the on-screen Back button and Esc.
function goBack() {
  if (history.state && history.state.embiggenized) {
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

// A reload while the text was showing starts in the editor, so drop the
// stale history entry rather than leaving Back pointed at nothing.
if (history.state && history.state.embiggenized) {
  history.replaceState(null, "");
}

textInput.focus();
