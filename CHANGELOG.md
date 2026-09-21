# Changelog

All notable changes to tobs_blaine (ESX). Each version is also a [GitHub release](https://github.com/Vega421/tobs_blaineESX/releases) with a ready-to-use zip.

Full documentation: https://vega421.github.io/script-docs/scripts/tobs-blaine/

## 1.5.0 · 2026-09-21

- **Deposit boxes:** drill the safe deposit boxes in every vault (8 per bank) with the heist drilling animation and an ox_lib skill check. Rewards come from `TOB.DrillRewards` (cash, items or nothing). Needs a `drill` item by default. Box positions from qbcore-framework/qb-bankrobbery (GPL-3.0)
- **Laptop hack:** the Pacific Standard laptop hacking animation during the hack (`TOB.LaptopHack`)
- **Thermite:** the vault item now plants a thermal charge with burning sparks everyone nearby can see (`TOB.VaultItemAnim`)
- **Bank alarm:** the real Paleto Bay bank alarm plays during the heist. Fleeca banks use a silent alarm (`TOB.Alarm`)
- **Gold and diamond trolleys:** sometimes one trolley holds gold (2× pay) or diamonds (3× pay) (`TOB.SpecialTrolleys`, `TOB.SpecialTrolleyChance`)
- **Stop grabbing early:** press X to stop and keep what's in the bag (`TOB.StopGrabKey`)
- **Loot counter:** see the cash you're grabbing on screen, and everyone's total when the heist ends (`TOB.LootCounter`)
- Fixed grabbing getting stuck if the trolley was already gone, and a model loading check that didn't wait for all models

## 1.4.1 · 2026-09-21

Security and reliability fixes from a full audit:

- **Security:** heist cash is only paid while the player is at the trolley they're looting
- **Security:** only the real vault open/close can set the vault door angle, so players can't swing the vault open
- Heists that get stuck end automatically after the longest possible heist time
- Fleeca inner gates stay locked outside heists and are relocked afterwards
- Crew members who arrive after the trolleys spawn can loot too
- The hack fails if the robber is killed during it
- Banks with missing settings are skipped with a console warning instead of breaking the script, and `mincash`/`maxcash` in the wrong order are fixed automatically
- Automated tests run on every push, and a release is only published when they pass

## 1.4.0 · 2026-09-21

- **All 6 Fleeca banks** included, with an inner gate the robber hacks to reach the last trolley (positions from utkuali/Fleeca-Bank-Heists). Turn them off with `TOB.FleecaBanks = false`
- `TOB.GateItem`: optional item for the inner gate, such as `secure_card`
- `TOB.MinCrew`: minimum number of robbers at the panel to start
- `TOB.OneAtATime` and `TOB.GlobalCooldown`: stop players chaining banks
- `SV.BlockBeforeRestart`: no new heists shortly before a txAdmin scheduled restart
- Every bank has a `label` (shown in Discord logs) and an `enabled` switch

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
