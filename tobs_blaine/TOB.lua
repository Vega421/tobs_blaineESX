TOB = {}

-- Language: "en" (English) or "da" (Danish). Texts are in locales.lua.
TOB.Locale = "en"

-- Heist
TOB.mincops = 4 -- police needed online to start the heist
TOB.PoliceJob = "police" -- ESX job that counts as police
TOB.hacktime = 60000 -- hack duration in milliseconds (60000 = 1 min). Gives police time to arrive
TOB.timer = 300 -- seconds after the hack before the doors lock again
TOB.VaultCloseDelay = 30 -- seconds between the last trolley being looted and the vault closing
TOB.cooldown = 600 -- seconds before the bank can be robbed again (600 = 10 min)

-- Hacking minigame (ox_lib skill check). Failing it ends the heist; police are already alerted.
TOB.Minigame = true -- needs ox_lib; skipped automatically if ox_lib isn't running
TOB.MinigameDifficulty = {"easy", "easy", "medium", "medium"} -- one entry per round: "easy", "medium" or "hard"
TOB.MinigameKeys = {"w", "a", "s", "d"} -- keys the skill check can ask for

-- Rewards
TOB.mincash = 3000 -- minimum cash per cash pile (a trolley has many piles)
TOB.maxcash = 6500 -- maximum cash per cash pile
TOB.black = false -- true pays into the black_money account instead of cash
TOB.MaxPiles = 60 -- anti-cheat: most cash piles one player can be paid for per trolley

-- Interaction and UI
TOB.Target = "auto" -- "auto" (ox_target if running, otherwise press E), "ox_target" or "none" (always press E)
TOB.Progress = "auto" -- "auto" (ox_lib if running, otherwise progressBars), "ox_lib" or "progressBars"
TOB.Notify = "auto" -- "auto", "ox_lib", "mythic_notify", "esx" or "native". "auto" uses ox_lib, then mythic_notify, then ESX notifications
TOB.NotifyTitle = "Paleto Bank" -- title shown on ox_lib notifications

-- Police alerts
TOB.BuiltInPoliceAlert = true -- notification + map blip for on-duty police. Set false if your dispatch script handles it

-- Runs on the robber's game when the heist starts. Paste your dispatch script's alert here,
-- using its own documentation. coords is the bank's position (vector3).
TOB.DispatchAlert = function(coords)
    -- Example (replace with your dispatch script's call):
    -- exports["my_dispatch"]:SendAlert({code = "10-90", message = "Paleto Bank robbery", coords = coords})
end

-- Map objects (normally no need to change)
TOB.vaultdoor = "v_ilev_cbankvauldoor01"
TOB.door = "v_ilev_cbankvaulgate01"
TOB.office = "v_ilev_gb_teldr"
TOB.Banks = {
    B1 = {
        doors = {    
            startloc = {x = -105.44020080566, y = 6472.8505859375, z = 31.62672996521, h = 10.240501403809, animcoords = {x = -105.46078491211, y = 6471.5737304688, z = 30.626703262329, h = 43.363094329834}}
        },
        prop = {  
            first = {coords = vector3(-105.875, 6472.126, 31.87645), rot = vector3(-103.4942855835,6471.9970703125,31.626707077026)}
        },
        trolley1 = {x = -107.82345581055, y = 6475.4278320312, z = 30.62670135498, h = 221.48431396484},
        trolley2 = {x = -102.43961334229, y = 6477.1049804688, z = 30.626722335815, h = 97.833953857422}, 
        trolley3 = {x = -104.86431884766, y = 6479.0537109375, z = 30.62672996521, h = 168.07682800293},
        objects = {
            vector3(-107.38459777832,6474.9672851562,31.62670135498),
            vector3(-102.97591400146,6477.0712890625,31.62670135498),
            vector3(-105.05332183838,6478.5517578125,31.626705169678)
        },
        loot1 = false,
        loot2 = false,
        loot3 = false,
        onaction = false,
        lastrobbed = 0
    }
}