-- tobs_blaine client. Shared by every framework version; framework-specific code is in client/bridge.lua.

Check = {}          -- [bank] = true while this player has started a heist there
LootCheck = {}      -- [bank] = {Stop, Loot1, Loot2, Loot3}
LootActive = {}     -- [bank] = true while the loot phase is running
AwaitingVault = {}  -- [bank] = true while the robber still has to use TOB.VaultItem
Doors = {}
local ready = false
local disableinput = false
local initiator = false
local startdstcheck = false
local currentname = nil
local currentcoords = nil
local dooruse = false
local timerLeft = 0

-- Notifications. Pick a system with TOB.Notify in config/config.lua.
function Notify(ntype, msg, duration)
    duration = duration or 5000
    local mode = TOB.Notify

    if mode == "auto" then
        if GetResourceState("ox_lib") == "started" then
            mode = "ox_lib"
        elseif GetResourceState("mythic_notify") == "started" then
            mode = "mythic_notify"
        else
            mode = Bridge.NotifyFallback
        end
    end

    if mode == "ox_lib" then
        TriggerEvent("ox_lib:notify", {title = TOB.NotifyTitle, description = msg, type = ntype, duration = duration})
    elseif mode == "mythic_notify" then
        exports["mythic_notify"]:SendAlert(ntype == "warning" and "error" or ntype, msg, duration)
    elseif mode == "esx" or mode == "framework" then
        Bridge.Notify(msg)
    else
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

-- Progress bars. Pick a system with TOB.Progress in config/config.lua. Waits until the bar is done.
function Progress(ms, label)
    local mode = TOB.Progress

    if mode == "auto" then
        mode = GetResourceState("ox_lib") == "started" and "ox_lib" or "progressBars"
    end
    if mode == "ox_lib" then
        exports.ox_lib:progressBar({duration = ms, label = label, canCancel = false})
    else
        exports["progressBars"]:startUI(ms, label)
        Citizen.Wait(ms)
    end
end

-- The hacking minigame. Returns true when passed, or when the minigame is off or ox_lib isn't running.
function Minigame()
    if not TOB.Minigame or GetResourceState("ox_lib") ~= "started" then
        return true
    end
    return exports.ox_lib:skillCheck(TOB.MinigameDifficulty, TOB.MinigameKeys)
end

-- True when ox_target should be used instead of "press E" prompts
function UseTarget()
    if TOB.Target == "ox_target" then
        return true
    end
    return TOB.Target == "auto" and GetResourceState("ox_target") == "started"
end

function IsPoliceJob()
    return Bridge.IsPolice()
end

function DrawText3D(x, y, z, text, scale) local onScreen, _x, _y = World3dToScreen2d(x, y, z) SetTextScale(scale, scale) SetTextFont(4) SetTextProportional(1) SetTextEntry("STRING") SetTextCentre(true) SetTextColour(255, 255, 255, 215) AddTextComponentString(text) DrawText(_x, _y) local factor = (string.len(text)) / 700 DrawRect(_x, _y + 0.0150, 0.095 + factor, 0.03, 41, 11, 41, 100) end
function DisableControl() DisableControlAction(0, 73, false) DisableControlAction(0, 24, true) DisableControlAction(0, 257, true) DisableControlAction(0, 25, true) DisableControlAction(0, 263, true) DisableControlAction(0, 32, true) DisableControlAction(0, 34, true) DisableControlAction(0, 31, true) DisableControlAction(0, 30, true) DisableControlAction(0, 45, true) DisableControlAction(0, 22, true) DisableControlAction(0, 44, true) DisableControlAction(0, 37, true) DisableControlAction(0, 23, true) DisableControlAction(0, 288, true) DisableControlAction(0, 289, true) DisableControlAction(0, 170, true) DisableControlAction(0, 167, true) DisableControlAction(0, 73, true) DisableControlAction(2, 199, true) DisableControlAction(0, 47, true) DisableControlAction(0, 264, true) DisableControlAction(0, 257, true) DisableControlAction(0, 140, true) DisableControlAction(0, 141, true) DisableControlAction(0, 142, true) DisableControlAction(0, 143, true) end
function ShowTimer() SetTextFont(0) SetTextProportional(0) SetTextScale(0.42, 0.42) SetTextDropShadow(0, 0, 0, 0,255) SetTextEdge(1, 0, 0, 0, 255) SetTextEntry("STRING") AddTextComponentString("~r~"..timerLeft.."~w~") DrawText(0.682, 0.96) end

local function StartVec(bank)
    local s = TOB.Banks[bank].doors.startloc
    return vector3(s.x, s.y, s.z)
end

local function GateModel(bank)
    return GetHashKey(TOB.Banks[bank].gateModel or TOB.door)
end

local function VaultModel(bank)
    return GetHashKey(TOB.Banks[bank].vaultModel or TOB.vaultdoor)
end

local function GetVaultObject(bank)
    local s = StartVec(bank)
    return GetClosestObjectOfType(s.x, s.y, s.z, 2.0, VaultModel(bank), false, false, false)
end

Citizen.CreateThread(function()
    while true do
        if disableinput then
            DisableControl()
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

RegisterNetEvent("TOB_fh:lootup_c")
AddEventHandler("TOB_fh:lootup_c", function(bank, loot)
    if LootCheck[bank] ~= nil then
        LootCheck[bank][loot] = true
    end
end)

RegisterNetEvent("TOB_fh:outcome")
AddEventHandler("TOB_fh:outcome", function(ok, arg)
    if ok then
        Check[arg] = true
        StartHeist(arg)
    else
        Notify("error", arg)
    end
end)

RegisterNetEvent("TOB_fh:startLoot_c")
AddEventHandler("TOB_fh:startLoot_c", function(data, name)
    -- Fresh loot state for every heist, so a second heist can be looted too
    LootCheck[name] = {Stop = false, Loot1 = false, Loot2 = false, Loot3 = false}
    LootActive[name] = true
    Citizen.CreateThread(function()
        local useTarget = UseTarget()
        local start = vector3(data.doors.startloc.x, data.doors.startloc.y, data.doors.startloc.z)

        while true do
            local pedcoords = GetEntityCoords(PlayerPedId())

            if #(pedcoords - start) < 40 then
                local sleep = 250

                for i = 1, 3 do
                    local loot = "Loot" .. i
                    local t = data["trolley" .. i]

                    if not LootCheck[name][loot] then
                        local dst1 = #(pedcoords - vector3(t.x, t.y, t.z + 1))

                        if dst1 < 5 and not useTarget and not IsPoliceJob() then
                            sleep = 0
                            DrawText3D(t.x, t.y, t.z + 1, "[~r~E~w~] " .. L("loot"), 0.40)
                            if dst1 < 1 and IsControlJustReleased(0, 38) then
                                TriggerServerEvent("TOB_fh:lootup", name, loot)
                                StartGrab(name, vector3(t.x, t.y, t.z))
                            end
                        end
                    end
                end

                local lc = LootCheck[name]
                if lc.Stop or (lc.Loot1 and lc.Loot2 and lc.Loot3) then
                    lc.Stop = false
                    LootActive[name] = false
                    if initiator and currentname == name then
                        TriggerEvent("TOB_fh:reset", name, data)
                    end
                    return
                end
                Citizen.Wait(sleep)
            else
                if LootCheck[name].Stop then
                    LootActive[name] = false
                    return
                end
                Citizen.Wait(1000)
            end
        end
    end)
end)

RegisterNetEvent("TOB_fh:stopHeist_c")
AddEventHandler("TOB_fh:stopHeist_c", function(name)
    if LootCheck[name] ~= nil then
        LootCheck[name].Stop = true
    end
end)

RegisterNetEvent("TOB_fh:policenotify")
AddEventHandler("TOB_fh:policenotify", function(name)
    if TOB.BuiltInPoliceAlert and IsPoliceJob() then
        local s = StartVec(name)

        Notify("warning", L("police_alert"), 10000)
        local blip = AddBlipForCoord(s.x, s.y, s.z)
        SetBlipSprite(blip, 161)
        SetBlipScale(blip, 2.0)
        SetBlipColour(blip, 1)
        PulseBlip(blip)
        Citizen.Wait(240000)
        RemoveBlip(blip)
    end
end)

-- Admin reset (TOB.ResetCommand): stop everything for this bank and remove the props
RegisterNetEvent("TOB_fh:forceReset")
AddEventHandler("TOB_fh:forceReset", function(name)
    if LootCheck[name] ~= nil then
        LootCheck[name].Stop = true
    end
    LootActive[name] = false
    AwaitingVault[name] = nil
    Check[name] = false
    if currentname == name then
        initiator = false
        startdstcheck = false
        disableinput = false
        if IdProp ~= nil and DoesEntityExist(IdProp) then
            DeleteEntity(IdProp)
        end
    end
    local b = TOB.Banks[name]
    for i = 1, 3 do
        local t = b["trolley" .. i]
        for _, model in ipairs({"hei_prop_hei_cash_trolly_01", "hei_prop_hei_cash_trolly_03"}) do
            local obj = GetClosestObjectOfType(t.x, t.y, t.z, 1.5, GetHashKey(model), false, false, false)
            if obj ~= 0 then
                NetworkRequestControlOfEntity(obj)
                SetEntityAsMissionEntity(obj, true, true)
                DeleteEntity(obj)
            end
        end
    end
end)

-- DOORS --

local function DoorThreads()
    -- Keeps the gate frozen (locked) and at the right angle while players are near
    Citizen.CreateThread(function()
        while true do
            local near = false
            local pcoords = GetEntityCoords(PlayerPedId())

            for k, v in pairs(Doors) do
                if #(pcoords - v[1].loc) < 60.0 then
                    near = true
                    if v[1].obj == nil or not DoesEntityExist(v[1].obj) then
                        v[1].obj = GetClosestObjectOfType(v[1].loc, 1.5, GateModel(k), false, false, false)
                    end
                    FreezeEntityPosition(v[1].obj, v[1].locked)
                    if v[1].locked then
                        SetEntityHeading(v[1].obj, v[1].h)
                    end
                end
            end
            Citizen.Wait(near and 200 or 2000)
        end
    end)

    -- "Press E" prompts for police at the gate and the vault
    Citizen.CreateThread(function()
        local useTarget = UseTarget()

        while true do
            local sleep = 1000

            if IsPoliceJob() and not dooruse and not useTarget then
                local pcoords = GetEntityCoords(PlayerPedId())

                for k, v in pairs(Doors) do
                    for i = 1, 2 do
                        local dst = #(pcoords - v[i].loc)

                        if dst <= 5.0 then
                            sleep = 0
                        elseif dst <= 30.0 and sleep > 250 then
                            sleep = 250
                        end
                        if dst <= 4.0 then
                            local label = v[i].locked and L("unlock_door") or L("lock_door")
                            DrawText3D(v[i].txtloc.x, v[i].txtloc.y, v[i].txtloc.z, "[~r~E~w~] " .. label, 0.40)
                            if dst <= 1.5 and IsControlJustReleased(0, 38) then
                                ToggleDoor(k, i)
                            end
                        end
                    end
                end
            end
            Citizen.Wait(sleep)
        end
    end)

    -- Keeps the vault door at its last known angle for players who come near later
    Citizen.CreateThread(function()
        while true do
            local sleep = 1000
            local pcoords = GetEntityCoords(PlayerPedId())

            for k, v in pairs(Doors) do
                if v[2].state ~= nil and not dooruse and #(pcoords - v[2].loc) <= 20.0 then
                    local obj = GetVaultObject(k)
                    if obj ~= 0 then
                        SetEntityHeading(obj, v[2].state)
                    end
                end
            end
            Citizen.Wait(sleep)
        end
    end)
end

function ToggleDoor(k, i)
    dooruse = true
    if i == 2 then
        TriggerServerEvent("TOB_fh:toggleVault", k, not Doors[k][i].locked)
    else
        TriggerServerEvent("TOB_fh:toggleDoor", k, not Doors[k][i].locked)
    end
end

RegisterNetEvent("TOB_fh:toggleDoor")
AddEventHandler("TOB_fh:toggleDoor", function(key, state)
    if Doors[key] ~= nil then
        Doors[key][1].locked = state
    end
    dooruse = false
end)

RegisterNetEvent("TOB_fh:toggleVault")
AddEventHandler("TOB_fh:toggleVault", function(key, state)
    if Doors[key] == nil then return end
    local obj = GetVaultObject(key)

    Doors[key][2].locked = state
    -- Only players near the bank have the vault loaded. Everyone else just keeps the state,
    -- and gets the final door angle from the server (TOB_fh:vaultState).
    if obj == 0 then
        dooruse = false
        return
    end
    dooruse = true
    Doors[key][2].state = nil
    local step = state and 0.10 or -0.10
    for _ = 1, 900 do
        SetEntityHeading(obj, GetEntityHeading(obj) + step)
        Citizen.Wait(10)
    end
    Doors[key][2].state = GetEntityHeading(obj)
    TriggerServerEvent("TOB_fh:updateVaultState", key, Doors[key][2].state)
    dooruse = false
end)

RegisterNetEvent("TOB_fh:vaultState")
AddEventHandler("TOB_fh:vaultState", function(key, heading)
    if Doors[key] ~= nil then
        Doors[key][2].state = heading
    end
end)

-- HEIST --

AddEventHandler("TOB_fh:reset", function(name, data)
    Check[name] = false
    Notify("error", L("vault_closing_soon", TOB.VaultCloseDelay))
    Citizen.Wait(TOB.VaultCloseDelay * 1000)
    Notify("error", L("vault_closing"))
    TriggerServerEvent("TOB_fh:toggleVault", name, true)
    CleanUp(data, name)
end)

local function FailHeist(name, reason)
    Notify("error", L(reason))
    Check[name] = false
    initiator = false
    AwaitingVault[name] = nil
    if IdProp ~= nil and DoesEntityExist(IdProp) then
        DeleteEntity(IdProp)
    end
    TriggerServerEvent("TOB_fh:setCooldown", name, reason)
end

function StartHeist(name)
    local data = TOB.Banks[name]

    TriggerServerEvent("TOB_fh:toggleDoor", name, true) -- make sure the gate is locked for this heist
    disableinput = true
    currentname = name
    currentcoords = StartVec(name)
    initiator = true
    -- Server owners' dispatch integration (config/config.lua). pcall so a broken hook can't stop the heist.
    local ok, err = pcall(TOB.DispatchAlert, currentcoords)
    if not ok then
        print("[tobs_blaine] TOB.DispatchAlert error: " .. tostring(err))
    end
    RequestModel("p_ld_id_card_01")
    while not HasModelLoaded("p_ld_id_card_01") do
        Citizen.Wait(1)
    end
    local ped = PlayerPedId()

    SetEntityCoords(ped, data.doors.startloc.animcoords.x, data.doors.startloc.animcoords.y, data.doors.startloc.animcoords.z)
    SetEntityHeading(ped, data.doors.startloc.animcoords.h)
    IdProp = CreateObject(GetHashKey("p_ld_id_card_01"), GetEntityCoords(ped), 1, 1, 0)
    AttachEntityToEntity(IdProp, ped, GetPedBoneIndex(ped, 28422), 0.20, 0.038, 0.001, 10.0, 175.0, 0.0, true, true, false, true, 1, true)
    TaskStartScenarioInPlace(ped, "PROP_HUMAN_ATM", 0, true)
    Citizen.CreateThread(function() Progress(2000, L("using_card")) end)
    Citizen.Wait(1500)
    DetachEntity(IdProp, false, false)
    SetEntityCoords(IdProp, data.prop.first.coords, 0.0, 0.0, 0.0, false)
    SetEntityRotation(IdProp, data.prop.first.rot, 1, true)
    FreezeEntityPosition(IdProp, true)
    Citizen.Wait(500)
    ClearPedTasksImmediately(ped)
    disableinput = false
    Citizen.Wait(1000)
    if not Minigame() then
        FailHeist(name, "hack_failed")
        return
    end
    Progress(TOB.hacktime, L("hacking"))
    Notify("success", L("hack_done"))
    PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET")

    if TOB.VaultItem ~= nil and TOB.VaultItem ~= "" then
        WaitForVaultItem(name)
    else
        OpenVault(name)
    end
end

function OpenVault(name)
    TriggerServerEvent("TOB_fh:toggleVault", name, false)
    startdstcheck = true
    timerLeft = TOB.timer
    Notify("error", L("security_timer", string.format("%d:%02d", math.floor(TOB.timer / 60), TOB.timer % 60)))
    SpawnTrolleys(TOB.Banks[name], name)
end

-- Extra vault step (TOB.VaultItem): the robber has TOB.timer seconds to use the item on the vault door
function WaitForVaultItem(name)
    AwaitingVault[name] = true
    Notify("inform", L("use_vault_item", TOB.VaultItemLabel), 10000)
    Citizen.CreateThread(function()
        local deadline = GetGameTimer() + TOB.timer * 1000

        while AwaitingVault[name] do
            if GetGameTimer() > deadline or #(GetEntityCoords(PlayerPedId()) - currentcoords) > 30.0 then
                FailHeist(name, "vault_timeout")
                return
            end
            Citizen.Wait(500)
        end
    end)
end

function UseVaultItem(name)
    if not AwaitingVault[name] then return end
    TriggerServerEvent("TOB_fh:useVaultItem", name)
end

RegisterNetEvent("TOB_fh:vaultItemResult")
AddEventHandler("TOB_fh:vaultItemResult", function(name, ok)
    if not ok then
        Notify("error", L("no_vault_item", TOB.VaultItemLabel))
        return
    end
    AwaitingVault[name] = nil
    local ped = PlayerPedId()

    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_WELDING", 0, true)
    Progress(TOB.VaultItemTime, L("using_vault_item"))
    ClearPedTasks(ped)
    OpenVault(name)
end)

function CleanUp(data, name)
    Citizen.Wait(10000)
    for i = 1, 3, 1 do
        for _, model in ipairs({"hei_prop_hei_cash_trolly_01", "hei_prop_hei_cash_trolly_03"}) do
            local obj = GetClosestObjectOfType(data.objects[i].x, data.objects[i].y, data.objects[i].z, 0.75, GetHashKey(model), false, false, false)

            if DoesEntityExist(obj) then
                DeleteEntity(obj)
            end
        end
    end
    if IdProp ~= nil and DoesEntityExist(IdProp) then
        DeleteEntity(IdProp)
    end
    TriggerServerEvent("TOB_fh:setCooldown", name)
    initiator = false
end

function SpawnTrolleys(data, name)
    RequestModel("hei_prop_hei_cash_trolly_01")
    while not HasModelLoaded("hei_prop_hei_cash_trolly_01") do
        Citizen.Wait(1)
    end
    for i = 1, 3 do
        local t = data["trolley" .. i]
        local trolley = CreateObject(GetHashKey("hei_prop_hei_cash_trolly_01"), t.x, t.y, t.z, 1, 1, 0)

        SetEntityHeading(trolley, GetEntityHeading(trolley) + t.h)
    end
    -- The server decides who can loot (everyone near the bank)
    TriggerServerEvent("TOB_fh:startLoot", nil, name)
end

function StartGrab(name, trolleyCoords)
    disableinput = true
    local ped = PlayerPedId()
    local model = "hei_prop_heist_cash_pile"

    Trolley = GetClosestObjectOfType(trolleyCoords or GetEntityCoords(ped), 1.0, GetHashKey("hei_prop_hei_cash_trolly_01"), false, false, false)
    local CashAppear = function()
	    local pedCoords = GetEntityCoords(ped)
        local grabmodel = GetHashKey(model)

        RequestModel(grabmodel)
        while not HasModelLoaded(grabmodel) do
            Citizen.Wait(100)
        end
	    local grabobj = CreateObject(grabmodel, pedCoords, true)

	    FreezeEntityPosition(grabobj, true)
	    SetEntityInvincible(grabobj, true)
	    SetEntityNoCollisionEntity(grabobj, ped)
	    SetEntityVisible(grabobj, false, false)
	    AttachEntityToEntity(grabobj, ped, GetPedBoneIndex(ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
	    local startedGrabbing = GetGameTimer()

	    Citizen.CreateThread(function()
		    while GetGameTimer() - startedGrabbing < 37000 do
			    Citizen.Wait(1)
			    DisableControlAction(0, 73, true)
			    if HasAnimEventFired(ped, GetHashKey("CASH_APPEAR")) then
				    if not IsEntityVisible(grabobj) then
					    SetEntityVisible(grabobj, true, false)
				    end
			    end
			    if HasAnimEventFired(ped, GetHashKey("RELEASE_CASH_DESTROY")) then
				    if IsEntityVisible(grabobj) then
                        SetEntityVisible(grabobj, false, false)
                        TriggerServerEvent("TOB_fh:rewardCash")
				    end
			    end
		    end
		    DeleteObject(grabobj)
	    end)
    end
	local trollyobj = Trolley
    local emptyobj = GetHashKey("hei_prop_hei_cash_trolly_03")

	if IsEntityPlayingAnim(trollyobj, "anim@heists@ornate_bank@grab_cash", "cart_cash_dissapear", 3) then
		return
    end
    local baghash = GetHashKey("hei_p_m_bag_var22_arm_s")

    RequestAnimDict("anim@heists@ornate_bank@grab_cash")
    RequestModel(baghash)
    RequestModel(emptyobj)
    while not HasAnimDictLoaded("anim@heists@ornate_bank@grab_cash") and not HasModelLoaded(emptyobj) and not HasModelLoaded(baghash) do
        Citizen.Wait(100)
    end
	while not NetworkHasControlOfEntity(trollyobj) do
		Citizen.Wait(1)
		NetworkRequestControlOfEntity(trollyobj)
	end
	local bag = CreateObject(GetHashKey("hei_p_m_bag_var22_arm_s"), GetEntityCoords(PlayerPedId()), true, false, false)
    local scene1 = NetworkCreateSynchronisedScene(GetEntityCoords(trollyobj), GetEntityRotation(trollyobj), 2, false, false, 1065353216, 0, 1.3)

	NetworkAddPedToSynchronisedScene(ped, scene1, "anim@heists@ornate_bank@grab_cash", "intro", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, scene1, "anim@heists@ornate_bank@grab_cash", "bag_intro", 4.0, -8.0, 1)
    SetPedComponentVariation(ped, 5, 0, 0, 0)
	NetworkStartSynchronisedScene(scene1)
	Citizen.Wait(1500)
	CashAppear()
	local scene2 = NetworkCreateSynchronisedScene(GetEntityCoords(trollyobj), GetEntityRotation(trollyobj), 2, false, false, 1065353216, 0, 1.3)

	NetworkAddPedToSynchronisedScene(ped, scene2, "anim@heists@ornate_bank@grab_cash", "grab", 1.5, -4.0, 1, 16, 1148846080, 0)
	NetworkAddEntityToSynchronisedScene(bag, scene2, "anim@heists@ornate_bank@grab_cash", "bag_grab", 4.0, -8.0, 1)
	NetworkAddEntityToSynchronisedScene(trollyobj, scene2, "anim@heists@ornate_bank@grab_cash", "cart_cash_dissapear", 4.0, -8.0, 1)
	NetworkStartSynchronisedScene(scene2)
	Citizen.Wait(37000)
	local scene3 = NetworkCreateSynchronisedScene(GetEntityCoords(trollyobj), GetEntityRotation(trollyobj), 2, false, false, 1065353216, 0, 1.3)

	NetworkAddPedToSynchronisedScene(ped, scene3, "anim@heists@ornate_bank@grab_cash", "exit", 1.5, -4.0, 1, 16, 1148846080, 0)
	NetworkAddEntityToSynchronisedScene(bag, scene3, "anim@heists@ornate_bank@grab_cash", "bag_exit", 4.0, -8.0, 1)
	NetworkStartSynchronisedScene(scene3)
    NewTrolley = CreateObject(emptyobj, GetEntityCoords(trollyobj) + vector3(0.0, 0.0, - 0.985), true)
    SetEntityRotation(NewTrolley, GetEntityRotation(trollyobj))
	while not NetworkHasControlOfEntity(trollyobj) do
		Citizen.Wait(1)
		NetworkRequestControlOfEntity(trollyobj)
	end
	DeleteObject(trollyobj)
    PlaceObjectOnGroundProperly(NewTrolley)
	Citizen.Wait(1800)
	DeleteObject(bag)
    SetPedComponentVariation(ped, 5, 45, 0, 0)
	RemoveAnimDict("anim@heists@ornate_bank@grab_cash")
	SetModelAsNoLongerNeeded(emptyobj)
    SetModelAsNoLongerNeeded(GetHashKey("hei_p_m_bag_var22_arm_s"))
    disableinput = false
end

-- Ends the heist if the robber leaves the bank
Citizen.CreateThread(function()
    while true do
        if startdstcheck and initiator then
            if #(GetEntityCoords(PlayerPedId()) - currentcoords) > 20 then
                LootCheck[currentname].Stop = true
                startdstcheck = false
                TriggerServerEvent("TOB_fh:stopHeist", currentname)
            end
        end
        Citizen.Wait(500)
    end
end)

-- Security timer: ends the heist when it runs out
Citizen.CreateThread(function()
    while true do
        if startdstcheck and initiator then
            if timerLeft > 0 then
                timerLeft = timerLeft - 1
            else
                startdstcheck = false
                TriggerServerEvent("TOB_fh:stopHeist", currentname)
            end
        end
        Citizen.Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        if startdstcheck and initiator then
            ShowTimer()
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

-- STARTUP --

Bridge.Init(function()
    Bridge.TriggerCallback("TOB_fh:getBanks", function(banks, doors)
        TOB.Banks = banks
        Doors = doors
        for k, _ in pairs(TOB.Banks) do
            Check[k] = false
            LootCheck[k] = {Stop = false, Loot1 = false, Loot2 = false, Loot3 = false}
        end
        if UseTarget() then
            RegisterTargets()
        end
        DoorThreads()
        ready = true
    end)
end)

-- "Press E" prompts for robbers: start the heist and use the vault item
Citizen.CreateThread(function()
    while not ready do
        Citizen.Wait(500)
    end
    local useTarget = UseTarget()

    while true do
        local sleep = 1000

        if not IsPoliceJob() and not useTarget then
            local coords = GetEntityCoords(PlayerPedId())

            for k, v in pairs(TOB.Banks) do
                local s = v.doors.startloc
                local dst = #(coords - vector3(s.x, s.y, s.z))

                if dst <= 6 then
                    sleep = 0
                elseif dst <= 30 and sleep > 250 then
                    sleep = 250
                end
                if not v.onaction and dst <= 5 and not Check[k] then
                    DrawText3D(s.x, s.y, s.z, "[~r~E~w~] " .. L("start_heist"), 0.40)
                    if dst <= 1 and IsControlJustReleased(0, 38) then
                        TriggerServerEvent("TOB_fh:startcheck", k)
                    end
                end
                if AwaitingVault[k] then
                    local vt = Doors[k][2].txtloc
                    local vdst = #(coords - vt)

                    if vdst <= 5 then
                        sleep = 0
                        DrawText3D(vt.x, vt.y, vt.z, "[~r~E~w~] " .. L("use_item", TOB.VaultItemLabel), 0.40)
                        if vdst <= 1.5 and IsControlJustReleased(0, 38) then
                            UseVaultItem(k)
                        end
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

-- ox_target zones, used instead of "press E" prompts when TOB.Target allows it
function RegisterTargets()
    for k, v in pairs(TOB.Banks) do
        local start = v.doors.startloc

        exports.ox_target:addSphereZone({
            coords = vector3(start.x, start.y, start.z),
            radius = 1.0,
            options = {{
                name = "tob_start_" .. k,
                icon = "fa-solid fa-id-card",
                label = L("start_heist"),
                distance = 1.5,
                canInteract = function()
                    return not IsPoliceJob() and not TOB.Banks[k].onaction and not Check[k]
                end,
                onSelect = function()
                    TriggerServerEvent("TOB_fh:startcheck", k)
                end
            }}
        })

        for i = 1, 3 do
            local t = v["trolley" .. i]
            local loot = "Loot" .. i

            exports.ox_target:addSphereZone({
                coords = vector3(t.x, t.y, t.z + 1.0),
                radius = 0.8,
                options = {{
                    name = "tob_loot_" .. k .. "_" .. i,
                    icon = "fa-solid fa-sack-dollar",
                    label = L("loot"),
                    distance = 1.5,
                    canInteract = function()
                        return LootActive[k] and not LootCheck[k][loot] and not IsPoliceJob()
                    end,
                    onSelect = function()
                        TriggerServerEvent("TOB_fh:lootup", k, loot)
                        StartGrab(k, vector3(t.x, t.y, t.z))
                    end
                }}
            })
        end
    end

    for k, v in pairs(Doors) do
        for i = 1, 2 do
            local options = {
                {
                    name = "tob_unlock_" .. k .. "_" .. i,
                    icon = "fa-solid fa-lock-open",
                    label = L("unlock_door"),
                    distance = 2.0,
                    canInteract = function()
                        return IsPoliceJob() and not dooruse and Doors[k][i].locked
                    end,
                    onSelect = function() ToggleDoor(k, i) end
                },
                {
                    name = "tob_lock_" .. k .. "_" .. i,
                    icon = "fa-solid fa-lock",
                    label = L("lock_door"),
                    distance = 2.0,
                    canInteract = function()
                        return IsPoliceJob() and not dooruse and not Doors[k][i].locked
                    end,
                    onSelect = function() ToggleDoor(k, i) end
                }
            }
            if i == 2 then
                options[#options + 1] = {
                    name = "tob_vaultitem_" .. k,
                    icon = "fa-solid fa-fire",
                    label = L("use_item", TOB.VaultItemLabel),
                    distance = 2.0,
                    canInteract = function()
                        return AwaitingVault[k] == true
                    end,
                    onSelect = function() UseVaultItem(k) end
                }
            end
            exports.ox_target:addSphereZone({coords = v[i].txtloc, radius = 1.0, options = options})
        end
    end
end
