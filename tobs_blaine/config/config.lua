TOB = {}

-- Language: "en" (English) or "da" (Danish). Texts are in locales/locales.lua.
TOB.Locale = "en"

-- Heist
TOB.mincops = 4 -- police needed online to start the heist
TOB.PoliceJob = "police" -- ESX job that counts as police
TOB.hacktime = 60000 -- hack duration in milliseconds (60000 = 1 min). Gives police time to arrive
TOB.timer = 300 -- seconds after the hack before the doors lock again (also the time limit for TOB.VaultItem)
TOB.VaultCloseDelay = 30 -- seconds between the last trolley being looted and the vault closing
TOB.cooldown = 600 -- seconds before a bank can be robbed again (600 = 10 min)
TOB.MinCrew = 1 -- robbers (not police) that must be near the panel to start. 1 = solo is fine
TOB.CrewRadius = 15.0 -- meters around the start panel that count as "near"
TOB.OneAtATime = false -- true = only one heist on the whole server at a time
TOB.GlobalCooldown = 0 -- seconds after any heist before any bank can be robbed (0 = off, each bank only has its own cooldown)

-- Hacking minigame (ox_lib skill check). Failing it ends the heist; police are already alerted.
TOB.Minigame = true -- needs ox_lib; skipped automatically if ox_lib isn't running
TOB.MinigameDifficulty = {"easy", "easy", "medium", "medium"} -- one entry per round: "easy", "medium" or "hard"
TOB.MinigameKeys = {"w", "a", "s", "d"} -- keys the skill check can ask for

-- Extra vault step: after the hack the robber must use this item on the vault door.
TOB.VaultItem = "" -- item name, e.g. "thermite" or "drill". "" = the vault opens right after the hack
TOB.VaultItemLabel = "thermite" -- name shown to players
TOB.VaultItemTime = 15000 -- milliseconds the robber works on the vault door

-- Inner gate (Fleeca banks): after the vault opens, the robber hacks a second panel to reach the last trolley.
TOB.GateItem = "" -- item needed for the second panel, e.g. "secure_card". "" = no item needed
TOB.GateItemLabel = "Secure ID Card" -- name shown to players
TOB.GateHackTime = 10000 -- milliseconds the gate hack takes

-- Rewards
TOB.mincash = 3000 -- minimum cash per cash pile (a trolley has many piles)
TOB.maxcash = 6500 -- maximum cash per cash pile
TOB.black = false -- true pays into the black_money account instead of cash
TOB.RewardItem = "" -- give this item instead of money, e.g. "markedbills". "" = pay money
TOB.RewardItemCount = "cash" -- "cash" = item count equals the cash amount (money-like items), or a number of items per pile (e.g. 1 for bags)
TOB.MaxPiles = 60 -- anti-cheat: most cash piles one player can be paid for per trolley

-- Interaction and UI
TOB.Target = "auto" -- "auto" (ox_target if running, otherwise press E), "ox_target" or "none" (always press E)
TOB.Progress = "auto" -- "auto" (ox_lib if running, otherwise progressBars), "ox_lib" or "progressBars"
TOB.Notify = "auto" -- "auto", "ox_lib", "mythic_notify", "esx" or "native". "auto" uses ox_lib, then mythic_notify, then ESX notifications
TOB.NotifyTitle = "Paleto Bank" -- title shown on ox_lib notifications

-- Police alerts
TOB.BuiltInPoliceAlert = true -- notification + map blip for police. Set false if your dispatch script handles it

-- Runs on the robber's game when the heist starts. Paste your dispatch script's alert here,
-- using its own documentation. coords is the bank's position (vector3).
TOB.DispatchAlert = function(coords)
    -- Example (replace with your dispatch script's call):
    -- exports["my_dispatch"]:SendAlert({code = "10-90", message = "Paleto Bank robbery", coords = coords})
end

-- Banks
TOB.FleecaBanks = true -- include the 6 Fleeca banks. Set false if you run another Fleeca heist script

-- Default door models. A bank can override them with gateModel / vaultModel (a name or a hash number).
TOB.vaultdoor = "v_ilev_cbankvauldoor01"
TOB.door = "v_ilev_cbankvaulgate01"

-- To add a bank, copy a block, give it a new name (for example B2) and fill in its positions.
-- enabled = false hides a bank. doors.secondloc adds an inner gate the robber has to hack (like Fleeca).
-- Fleeca positions are from utkuali/Fleeca-Bank-Heists (GPL-3.0).
TOB.Banks = {
    B1 = {
        label = "Paleto Bay (Blaine County Savings)",
        enabled = true,
        doors = {
            startloc = {x = -105.44020080566, y = 6472.8505859375, z = 31.62672996521, h = 10.240501403809, animcoords = {x = -105.46078491211, y = 6471.5737304688, z = 30.626703262329, h = 43.363094329834}}
        },
        gate = {loc = vector3(-105.15334320068, 6472.7075195312, 31.626728057861), h = 42.639282226562, txtloc = vector3(-105.34651184082, 6472.708984375, 31.626726150513)},
        vault = {loc = vector3(-105.84294891357, 6475.4428710938, 31.62670135498), txtloc = vector3(-105.84294891357, 6475.4428710938, 31.62670135498)},
        prop = {
            first = {coords = vector3(-105.875, 6472.126, 31.87645), rot = vector3(-103.4942855835, 6471.9970703125, 31.626707077026)}
        },
        trolley1 = {x = -107.82345581055, y = 6475.4278320312, z = 30.62670135498, h = 221.48431396484},
        trolley2 = {x = -102.43961334229, y = 6477.1049804688, z = 30.626722335815, h = 97.833953857422},
        trolley3 = {x = -104.86431884766, y = 6479.0537109375, z = 30.62672996521, h = 168.07682800293},
        objects = {
            vector3(-107.38459777832, 6474.9672851562, 31.62670135498),
            vector3(-102.97591400146, 6477.0712890625, 31.62670135498),
            vector3(-105.05332183838, 6478.5517578125, 31.626705169678)
        },
        onaction = false,
        lastrobbed = 0
    },
    F1 = {
        label = "Fleeca Alta (Hawick Ave)",
        enabled = TOB.FleecaBanks,
        gateModel = "v_ilev_gb_vaubar",
        vaultModel = "v_ilev_gb_vauldr",
        doors = {
            startloc = {x = 310.93, y = -284.44, z = 54.16, h = -90, animcoords = {x = 311.05, y = -284, z = 53.16, h = 248.6}},
            secondloc = {x = 312.93, y = -284.45, z = 54.16, h = 160.91, animcoords = {x = 313.41, y = -284.42, z = 53.16, h = 160.91}}
        },
        gate = {loc = vector3(312.93, -284.45, 54.16), h = 160.91, txtloc = vector3(312.93, -284.45, 54.16)},
        vault = {loc = vector3(310.93, -284.44, 54.16), txtloc = vector3(310.93, -284.44, 54.16)},
        prop = {
            first = {coords = vector3(311.5481, -284.5114, 54.285), rot = vector3(90, 180, 21)}
        },
        trolley1 = {x = 313.45, y = -289.24, z = 53.14, h = -15},
        trolley2 = {x = 311.51, y = -288.54, z = 53.14, h = -15},
        trolley3 = {x = 314.49, y = -283.65, z = 53.14, h = 160},
        objects = {vector3(313.45, -289.24, 53.14), vector3(311.51, -288.54, 53.14), vector3(314.49, -283.65, 53.14)},
        onaction = false,
        lastrobbed = 0
    },
    F2 = {
        label = "Fleeca Legion Square",
        enabled = TOB.FleecaBanks,
        gateModel = "v_ilev_gb_vaubar",
        vaultModel = "v_ilev_gb_vauldr",
        doors = {
            startloc = {x = 146.61, y = -1046.02, z = 29.37, h = 244.2, animcoords = {x = 146.75, y = -1045.6, z = 28.37, h = 244.2}},
            secondloc = {x = 148.76, y = -1045.89, z = 29.37, h = 158.54, animcoords = {x = 149.1, y = -1046.08, z = 28.37, h = 158.54}}
        },
        gate = {loc = vector3(148.76, -1045.89, 29.37), h = 158.54, txtloc = vector3(148.76, -1045.89, 29.37)},
        vault = {loc = vector3(146.61, -1046.02, 29.37), txtloc = vector3(146.61, -1046.02, 29.37)},
        prop = {
            first = {coords = vector3(147.22, -1046.148, 29.487), rot = vector3(90, 180, 20)}
        },
        trolley1 = {x = 147.25, y = -1050.38, z = 28.35, h = -15},
        trolley2 = {x = 149.21, y = -1051.07, z = 28.35, h = -15},
        trolley3 = {x = 150.23, y = -1045.4, z = 28.35, h = 160},
        objects = {vector3(147.25, -1050.38, 28.35), vector3(149.21, -1051.07, 28.35), vector3(150.23, -1045.4, 28.35)},
        onaction = false,
        lastrobbed = 0
    },
    F3 = {
        label = "Fleeca Rockford Hills",
        enabled = TOB.FleecaBanks,
        gateModel = "v_ilev_gb_vaubar",
        vaultModel = "v_ilev_gb_vauldr",
        doors = {
            startloc = {x = -1211.07, y = -336.68, z = 37.78, h = 296.76, animcoords = {x = -1211.25, y = -336.37, z = 36.78, h = 296.76}},
            secondloc = {x = -1209.66, y = -335.15, z = 37.78, h = 213.67, animcoords = {x = -1209.4, y = -335.05, z = 36.78, h = 213.67}}
        },
        gate = {loc = vector3(-1209.66, -335.15, 37.78), h = 213.67, txtloc = vector3(-1209.66, -335.15, 37.78)},
        vault = {loc = vector3(-1211.07, -336.68, 37.78), txtloc = vector3(-1211.07, -336.68, 37.78)},
        prop = {
            first = {coords = vector3(-1210.5, -336.37, 37.901), rot = vector3(-90, 0, 25)}
        },
        trolley1 = {x = -1207.5, y = -339.2, z = 36.76, h = 30},
        trolley2 = {x = -1205.61, y = -338.24, z = 36.76, h = 30},
        trolley3 = {x = -1209.1, y = -333.59, z = 36.76, h = 210},
        objects = {vector3(-1207.5, -339.2, 36.76), vector3(-1205.61, -338.24, 36.76), vector3(-1209.1, -333.59, 36.76)},
        onaction = false,
        lastrobbed = 0
    },
    F4 = {
        label = "Fleeca Great Ocean Highway",
        enabled = TOB.FleecaBanks,
        gateModel = "v_ilev_gb_vaubar",
        vaultModel = 4231427725, -- this branch has a different vault door
        doors = {
            startloc = {x = -2956.68, y = 481.34, z = 15.7, h = 353.97, animcoords = {x = -2956.68, y = 481.34, z = 14.7, h = 353.97}},
            secondloc = {x = -2957.26, y = 483.53, z = 15.7, h = 267.73, animcoords = {x = -2957.26, y = 483.53, z = 14.7, h = 267.73}}
        },
        gate = {loc = vector3(-2957.26, 483.53, 15.7), h = 267.73, txtloc = vector3(-2957.26, 483.53, 15.7)},
        vault = {loc = vector3(-2956.68, 481.34, 15.7), txtloc = vector3(-2956.68, 481.34, 15.7)},
        prop = {
            first = {coords = vector3(-2956.59, 482.05, 15.815), rot = vector3(90, 180, -88)}
        },
        trolley1 = {x = -2952.69, y = 483.34, z = 14.68, h = 85},
        trolley2 = {x = -2952.57, y = 485.18, z = 14.68, h = 85},
        trolley3 = {x = -2958.35, y = 484.69, z = 14.68, h = 270},
        objects = {vector3(-2952.69, 483.34, 14.68), vector3(-2952.57, 485.18, 14.68), vector3(-2958.35, 484.69, 14.68)},
        onaction = false,
        lastrobbed = 0
    },
    F5 = {
        label = "Fleeca Burton",
        enabled = TOB.FleecaBanks,
        gateModel = "v_ilev_gb_vaubar",
        vaultModel = "v_ilev_gb_vauldr",
        doors = {
            startloc = {x = -354.15, y = -55.11, z = 49.04, h = 251.05, animcoords = {x = -354.15, y = -55.11, z = 48.04, h = 251.05}},
            secondloc = {x = -351.97, y = -55.18, z = 49.04, h = 159.79, animcoords = {x = -351.97, y = -55.18, z = 48.04, h = 159.79}}
        },
        gate = {loc = vector3(-351.97, -55.18, 49.04), h = 159.79, txtloc = vector3(-351.97, -55.18, 49.04)},
        vault = {loc = vector3(-354.15, -55.11, 49.04), txtloc = vector3(-354.15, -55.11, 49.04)},
        prop = {
            first = {coords = vector3(-353.5, -55.37, 49.157), rot = vector3(90, 180, 20)}
        },
        trolley1 = {x = -353.34, y = -59.48, z = 48.01, h = -15},
        trolley2 = {x = -351.57, y = -60.09, z = 48.01, h = -15},
        trolley3 = {x = -350.57, y = -54.45, z = 48.01, h = 160},
        objects = {vector3(-353.34, -59.48, 48.01), vector3(-351.57, -60.09, 48.01), vector3(-350.57, -54.45, 48.01)},
        onaction = false,
        lastrobbed = 0
    },
    F6 = {
        label = "Fleeca Harmony (Route 68)",
        enabled = TOB.FleecaBanks,
        gateModel = "v_ilev_gb_vaubar",
        vaultModel = "v_ilev_gb_vauldr",
        doors = {
            startloc = {x = 1176.4, y = 2712.75, z = 38.09, h = 84.83, animcoords = {x = 1176.4, y = 2712.75, z = 37.09, h = 84.83}},
            secondloc = {x = 1174.24, y = 2712.47, z = 38.09, h = 359.05, animcoords = {x = 1174.33, y = 2712.09, z = 37.09, h = 359.05}}
        },
        gate = {loc = vector3(1174.24, 2712.47, 38.09), h = 160.91, txtloc = vector3(1174.24, 2712.47, 38.09)},
        vault = {loc = vector3(1176.4, 2712.75, 38.09), txtloc = vector3(1176.4, 2712.75, 38.09)},
        prop = {
            first = {coords = vector3(1175.7, 2712.82, 38.207), rot = vector3(90, 180, 180)}
        },
        trolley1 = {x = 1174.24, y = 2716.69, z = 37.07, h = -180},
        trolley2 = {x = 1172.27, y = 2716.67, z = 37.07, h = -180},
        trolley3 = {x = 1173.23, y = 2711.02, z = 37.07, h = 0},
        objects = {vector3(1174.24, 2716.69, 37.07), vector3(1172.27, 2716.67, 37.07), vector3(1173.23, 2711.02, 37.07)},
        onaction = false,
        lastrobbed = 0
    }
}
