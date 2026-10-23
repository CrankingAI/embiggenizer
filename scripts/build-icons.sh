#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# build-icons.sh — Remake the PNG and ICO icons from src/favicon.svg
#
# Usage:
#   ./scripts/build-icons.sh
#
# Browsers that take SVG icons use src/favicon.svg itself. This renders it
# with headless Chrome into copies for the rest: favicon.ico (16 and 32 px)
# and apple-touch-icon.png (180 px, for iPhone and iPad home screens). The
# copies are committed, so deploying still has no build step.
#
# Lifecycle: routine — safe to re-run; overwrites only those two files.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/lib/clock.sh"    # format_duration

APP_DIR="$REPO_ROOT/src"
DEFAULT_CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CHROME="${CHROME:-$DEFAULT_CHROME}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Remake src/favicon.ico and src/apple-touch-icon.png from src/favicon.svg.
Lifecycle: routine — safe to re-run; overwrites only those two files.

Options:
  -h, --help  Show this help

Environment variables:
  CHROME      Chrome binary to render with (default: $DEFAULT_CHROME)

Examples:
  $(basename "$0")
  CHROME=/usr/bin/google-chrome $(basename "$0")
EOF
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help|help) usage ;;
    *)              echo "Error: unknown option '$1'" >&2; usage 1 ;;
  esac
done

need() {
  command -v "$1" &>/dev/null && return 0
  echo "Error: '$1' is not installed."
  echo "  $2"
  exit 1
}
need magick "brew install imagemagick"

[[ -x "$CHROME" ]] || { echo "Error: Chrome not found at '$CHROME'."; echo "  Set CHROME to its path."; exit 1; }
[[ -f "$APP_DIR/favicon.svg" ]] || { echo "Error: $APP_DIR/favicon.svg not found."; exit 1; }

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
cp "$APP_DIR/favicon.svg" "$WORK_DIR/"

# render <size> <css background> <out.png>
# Chrome draws the SVG as a browser tab does; ImageMagick's own SVG renderer
# gets its gradients and <use> copies wrong.
render() {
  local size="$1" background="$2" out="$3"
  cat > "$WORK_DIR/icon.html" <<EOF
<!doctype html>
<style>html, body { margin: 0; background: $background; } img { display: block; }</style>
<img src="favicon.svg" width="$size" height="$size" alt="">
EOF
  rm -f "$out"
  "$CHROME" --headless --disable-gpu --hide-scrollbars \
    --user-data-dir="$WORK_DIR/profile" \
    --force-device-scale-factor=1 --default-background-color=00000000 \
    --window-size="$size,$size" --screenshot="$out" \
    "file://$WORK_DIR/icon.html" >/dev/null 2>&1 || true
  [[ -s "$out" ]] || { echo "Error: Chrome did not render $size px."; exit 1; }
}

START_TIME=$(date +%s)
echo "🚀 clock started ($(date '+%H:%M:%S'))"

echo "==> Rendering $APP_DIR/favicon.svg"
render 16 transparent "$WORK_DIR/16.png"
render 32 transparent "$WORK_DIR/32.png"
# iOS shows transparent corners as black and rounds the icon itself, so the
# corners take the sunburst's edge colour.
render 180 "#ff7a00" "$WORK_DIR/180.png"

echo "==> Writing icons"
magick "$WORK_DIR/16.png" "$WORK_DIR/32.png" "$APP_DIR/favicon.ico"
cp "$WORK_DIR/180.png" "$APP_DIR/apple-touch-icon.png"
echo "    $APP_DIR/favicon.ico"
echo "    $APP_DIR/apple-touch-icon.png"

DURATION=$(( $(date +%s) - START_TIME ))
echo "🏁 clock stopped (took $(format_duration "$DURATION"), ended $(date '+%H:%M:%S'))"
