TOB = {}
TOB.timer = 300 -- countdown to secure lock in seconds (time needed to pass to door to be closed back)
TOB.hacktime = 1000 -- first door open delay to make time for police to arrive and roleplay in miliseconds (I highly recommend to leave it be (2.5 min default))
TOB.maxcash = 6500 -- maximum amount of cash a pile can hold
TOB.mincash = 3000 -- minimum amount of cash a pile holds
TOB.black = false -- enable this if you want blackmoney as a reward
TOB.cooldown = 600 -- amount of time to do the heist again in seconds (15min)
TOB.mincops = 4 -- minimum required cops to start mission
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