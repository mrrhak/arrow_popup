#!/usr/bin/env bash
# Compresses the PNGs in ../../screenshots, in place, to keep the published
# package small. Run it after regenerating them:
#
#   flutter test tool/screenshots_test.dart
#   sh tool/compress_screenshots.sh
#
# Needs pngquant and oxipng: brew install pngquant oxipng
#
# Meant for freshly generated images. Running it again is safe, but quantizes
# the colors once more, so don't repeat it more than needed.
set -euo pipefail

dir="$(cd "$(dirname "$0")/../../screenshots" && pwd)"

for tool in pngquant oxipng; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool is not installed. Run: brew install pngquant oxipng" >&2
    exit 1
  fi
done

before=$(du -sk "$dir" | cut -f1)

for file in "$dir"/*.png; do
  # Dark images have large soft gradients that band at lower quality.
  case "$file" in
    *_dark.png) quality='95-100' ;;
    *) quality='80-95' ;;
  esac
  # Exit 98 (result not smaller) and 99 (quality too low) leave the file
  # untouched, which is fine.
  status=0
  pngquant --quality="$quality" --speed 1 --strip --skip-if-larger \
    --ext .png --force "$file" || status=$?
  if [ "$status" -ne 0 ] && [ "$status" -ne 98 ] && [ "$status" -ne 99 ]; then
    exit "$status"
  fi
  oxipng -o 4 --strip safe -q "$file"
  echo "$(basename "$file")  $(du -k "$file" | cut -f1) KB"
done

echo "screenshots/: ${before} KB -> $(du -sk "$dir" | cut -f1) KB"
