#!/usr/bin/env bash
#
# Regenerates the macOS app icon set from the SVG sources in this directory.
#
# Renders two variants:
#   - icon-small.svg : bolder, simplified — used for the 16pt/32pt slots where
#                      fine detail is lost.
#   - icon.svg       : detailed — used for the 128pt slots and larger.
#
# Requires rsvg-convert (e.g. `brew install librsvg`).

set -euo pipefail

ICON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSET_DIR="$ICON_DIR/../centerd/Assets.xcassets/AppIcon.appiconset"
SVG_DETAIL="$ICON_DIR/icon.svg"
SVG_SMALL="$ICON_DIR/icon-small.svg"

if ! command -v rsvg-convert >/dev/null 2>&1; then
    echo "error: rsvg-convert not found. Install it with: brew install librsvg" >&2
    exit 1
fi

# render <pixels> <output-filename> <svg-source>
render() {
    rsvg-convert -w "$1" -h "$1" "$3" -o "$ASSET_DIR/$2"
    echo "  $2 (${1}px)"
}

echo "Rendering app icon set into $ASSET_DIR"

# Small variant for the small slots (rendered pixels: 16, 32, 32, 64).
render 16 icon_16x16.png "$SVG_SMALL"
render 32 "icon_16x16@2x.png" "$SVG_SMALL"
render 32 icon_32x32.png "$SVG_SMALL"
render 64 "icon_32x32@2x.png" "$SVG_SMALL"

# Detailed variant for the large slots (rendered pixels: 128, 256, 256, 512, 512, 1024).
render 128 icon_128x128.png "$SVG_DETAIL"
render 256 "icon_128x128@2x.png" "$SVG_DETAIL"
render 256 icon_256x256.png "$SVG_DETAIL"
render 512 "icon_256x256@2x.png" "$SVG_DETAIL"
render 512 icon_512x512.png "$SVG_DETAIL"
render 1024 "icon_512x512@2x.png" "$SVG_DETAIL"

echo "Done."
