#!/usr/bin/env bash
# Build per-client Mangosbot zips. Differs only by ## Interface in the TOC.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
STAGE="$DIST/.stage"

CLIENTS=(
  "classic-1.12:11000"
  "tbc-2.4.3:20400"
  "wotlk-3.3.5a:30300"
)

PAYLOAD=(
  Mangosbot.lua
  Mangosbot.xml
  Mangosbot.toc
  Mangosbot_Core.lua
  Mangosbot_Protocol.lua
  Mangosbot_Commands.lua
  Mangosbot_UI.lua
  Mangosbot_Localization.en.lua
  Bindings.xml
  Images
)

rm -rf "$DIST"
mkdir -p "$DIST"

for entry in "${CLIENTS[@]}"; do
  name="${entry%%:*}"
  interface="${entry##*:}"
  work="$STAGE/Mangosbot"
  rm -rf "$STAGE"
  mkdir -p "$work"

  for item in "${PAYLOAD[@]}"; do
    cp -a "$ROOT/$item" "$work/"
  done

  # Stamp Interface; keep all other TOC lines
  sed -i "s/^## Interface:.*/## Interface: ${interface}/" "$work/Mangosbot.toc"

  (
    cd "$STAGE"
    zip -qr "$DIST/Mangosbot-${name}.zip" Mangosbot
  )
  echo "built dist/Mangosbot-${name}.zip (Interface ${interface})"
done

rm -rf "$STAGE"
ls -la "$DIST"
