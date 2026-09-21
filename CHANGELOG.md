# Changelog

All notable changes to tobs_blaine (ESX). Each version is also a [GitHub release](https://github.com/Vega421/tobs_blaineESX/releases) with a ready-to-use zip.

Full documentation: https://vega421.github.io/script-docs/scripts/tobs-blaine/

## 1.3.1 · 2026-09-21

- Files organized into `config/`, `locales/`, `client/` and `server/` folders. `TOB.lua` is now `config/config.lua`. When updating, replace the whole `tobs_blaine` folder and copy your settings into the new config files

## 1.3.0 · 2026-09-21

- Discord logs of heists, payouts, admin resets and blocked cheat attempts
- Admin reset command `/tobreset`
- Update check on server start
- Loot as items with `TOB.RewardItem`
- Optional vault item step with `TOB.VaultItem`
- More banks can be added from the config
- Fixed the police gate lock and the vault angle for late arrivals, which used the wrong (Fleeca) door models
- Loot checks for far-away players now stop when the heist ends
- New `config_server.lua` for server-only settings

## 1.2.2 · 2026-09-21

- Vault door: only players near the bank run the door animation. Before, every player on the server ran it, and far-away players could make the vault look wrong for players who arrived later
- Prompt and loot loops only run every frame when a prompt can be on screen
- Removed unused old code
- `items.sql` no longer adds the unused `secure_card` item

## 1.2.1 · 2026-09-21

- Performance: the heist timer display no longer runs every frame when no heist is active

## 1.2.0 · 2026-09-21

- Hacking minigame with ox_lib's skill check (`TOB.Minigame`). Failing it ends the heist
- ox_target support (`TOB.Target`); press E still works
- Progress bars use ox_lib when it's running (`TOB.Progress`), so `progressBars` is no longer required
- All text moved to `locales.lua`, with English and Danish (`TOB.Locale`)
- Dispatch hook `TOB.DispatchAlert` and `TOB.BuiltInPoliceAlert`
- Default hack time is now 1 minute (was 1 second) so police can respond
- `TOB.VaultCloseDelay` setting; the security timer message now shows the real time
- Performance: the script now does almost nothing when players aren't near the bank
- Fixed a second heist in the same session not being lootable by players who saw the first
- Player data refreshes on character switch

## 1.1.0 · 2026-09-21

- Added `TOB.Notify`: ox_lib, mythic_notify, ESX or GTA notifications, picked automatically by default
- Added `TOB.PoliceJob` so the police job name can be changed
- Security: server-side anti-cheat checks. Mod menus could previously trigger unlimited cash payouts
- The heist now ends cleanly if the player who started it disconnects
- Added GPL-3.0 license and ready-to-use release zips
- Works with the ESX Legacy `getSharedObject` export
- Moved the map file into `stream/` so FiveM loads it
- Fixed wrong descriptions in `TOB.lua`

## 1.0.0 · 2026-08-02

- First ESX release
