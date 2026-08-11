# Mangosbot UI (WoW client addon)

Unified addon for cmangos/playerbots on Classic (1.12), TBC (2.4.3), and WotLK (3.3.5a).

## Installation

**From source (dev /reload loop):** copy or symlink this repo into `Interface/AddOns/Mangosbot`. Keep `## Interface:` in `Mangosbot.toc` matching your client (or enable Load out of date addons).

**Release zips:**
```bash
./scripts/build.sh
```
Produces:
- `dist/Mangosbot-classic-1.12.zip` — Interface 11000
- `dist/Mangosbot-tbc-2.4.3.zip` — Interface 20400
- `dist/Mangosbot-wotlk-3.3.5a.zip` — Interface 30300

Extract the zip so you get `Interface/AddOns/Mangosbot/`.

## Bot Roster

Run `/bot` in WoW to open the Bot Roster. Use Login on a bot row to bring it online.

## Bot Controls

Select a bot (or click its class icon in the roster) for the control panel: formations, stances, RTI, strategies, class specs (including Death Knight on WotLK).

## Tests

```bash
cd src && lua test.lua
```
