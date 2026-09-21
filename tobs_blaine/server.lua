ESX = nil
-- ESX Legacy uses the export; older ESX versions use the event
local ok, esxObj = pcall(function() return exports["es_extended"]:getSharedObject() end)
if ok and esxObj then
    ESX = esxObj
else
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

Doors = {
    ["B1"] = {{loc = vector3(-105.15334320068,6472.7075195312,31.626728057861), h = 42.639282226562, txtloc = vector3(-105.34651184082,6472.708984375,31.626726150513), obj = nil, locked = false}, {loc = vector3(-105.84294891357,6475.4428710938,31.62670135498), txtloc = vector3(-105.84294891357,6475.4428710938,31.62670135498), obj = nil, locked = false}},
}

function IsPolice(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer ~= nil and xPlayer.job.name == TOB.PoliceJob
end

function CountPolice()
    local count = 0
    for _, id in ipairs(ESX.GetPlayers()) do
        if IsPolice(id) then count = count + 1 end
    end
    return count
end

function HasCard(src)
    local item = ESX.GetPlayerFromId(src).getInventoryItem("id_card_f")
    return item ~= nil and item.count >= 1
end

function TakeCard(src)
    ESX.GetPlayerFromId(src).removeInventoryItem("id_card_f", 1)
end

function GiveReward(src, amount)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer == nil then return end
    if TOB.black then
        xPlayer.addAccountMoney("black_money", amount)
    else
        xPlayer.addMoney(amount)
    end
end

-- Heist state lives on the server, so a cheater can't trigger payouts,
-- doors or heist events from their own game.
local Owner = {}    -- [bank] = server id of the player who started the heist
local Looted = {}   -- [bank] = {Loot1 = true, ...}
local Looting = {}  -- [server id] = {bank, started, last, piles}
local Trolleys = {Loot1 = "trolley1", Loot2 = "trolley2", Loot3 = "trolley3"}
local GRAB_WINDOW = 50000 -- ms a player can collect piles after starting a trolley (the animation is about 40 s)
local MIN_PILE_GAP = 250  -- ms between two piles

-- Returns true when the player is within maxDist of pos.
-- Without OneSync the server can't see player positions, so the check is skipped.
local function IsNear(src, pos, maxDist)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return true end
    local coords = GetEntityCoords(ped)
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then return true end
    return #(coords - vector3(pos.x, pos.y, pos.z)) <= maxDist
end

local function IsHeistOwner(src, bank)
    return TOB.Banks[bank] ~= nil and TOB.Banks[bank].onaction and Owner[bank] == src
end

local function EndHeist(bank)
    TOB.Banks[bank].lastrobbed = os.time()
    TOB.Banks[bank].onaction = false
    Owner[bank] = nil
    Looted[bank] = nil
    for id, l in pairs(Looting) do
        if l.bank == bank then Looting[id] = nil end
    end
    TriggerClientEvent("TOB_fh:resetDoorState", -1, bank)
end

local function CooldownLeft(bank)
    local left = TOB.cooldown - (os.time() - TOB.Banks[bank].lastrobbed)
    return string.format("%d:%02d", math.floor(left / 60), math.floor(math.fmod(left, 60)))
end

RegisterServerEvent("TOB_fh:startcheck")
AddEventHandler("TOB_fh:startcheck", function(bank)
    local _source = source

    if TOB.Banks[bank] == nil or IsPolice(_source) then return end
    if not IsNear(_source, TOB.Banks[bank].doors.startloc, 5.0) then return end

    if CountPolice() >= TOB.mincops then
        if HasCard(_source) then
            if not TOB.Banks[bank].onaction == true then
                if (os.time() - TOB.cooldown) > TOB.Banks[bank].lastrobbed then
                    TOB.Banks[bank].onaction = true
                    Owner[bank] = _source
                    Looted[bank] = {}
                    TakeCard(_source)
                    TriggerClientEvent("TOB_fh:outcome", _source, true, bank)
                    TriggerClientEvent("TOB_fh:policenotify", -1, bank)
                else
                    TriggerClientEvent("TOB_fh:outcome", _source, false, L("cooldown", CooldownLeft(bank)))
                end
            else
                TriggerClientEvent("TOB_fh:outcome", _source, false, L("busy"))
            end
        else
            TriggerClientEvent("TOB_fh:outcome", _source, false, L("no_card"))
        end
    else
        TriggerClientEvent("TOB_fh:outcome", _source, false, L("no_cops"))
    end
end)

RegisterServerEvent("TOB_fh:lootup")
AddEventHandler("TOB_fh:lootup", function(bank, trolley)
    local _source = source

    if TOB.Banks[bank] == nil or not TOB.Banks[bank].onaction or Trolleys[trolley] == nil then return end
    if IsPolice(_source) then return end
    Looted[bank] = Looted[bank] or {}
    if Looted[bank][trolley] then return end
    if not IsNear(_source, TOB.Banks[bank][Trolleys[trolley]], 5.0) then return end

    Looted[bank][trolley] = true
    Looting[_source] = {bank = bank, started = GetGameTimer(), last = 0, piles = 0}
    TriggerClientEvent("TOB_fh:lootup_c", -1, bank, trolley)
end)

RegisterServerEvent("TOB_fh:toggleDoor")
AddEventHandler("TOB_fh:toggleDoor", function(key, state)
    local _source = source

    if Doors[key] == nil then return end
    if not (IsPolice(_source) or IsHeistOwner(_source, key)) then return end
    Doors[key][1].locked = state
    TriggerClientEvent("TOB_fh:toggleDoor", -1, key, state)
end)

RegisterServerEvent("TOB_fh:toggleVault")
AddEventHandler("TOB_fh:toggleVault", function(key, state)
    local _source = source

    if Doors[key] == nil then return end
    if not (IsPolice(_source) or IsHeistOwner(_source, key)) then return end
    Doors[key][2].locked = state
    TriggerClientEvent("TOB_fh:toggleVault", -1, key, state)
end)

RegisterServerEvent("TOB_fh:updateVaultState")
AddEventHandler("TOB_fh:updateVaultState", function(key, state)
    if Doors[key] == nil then return end
    Doors[key][2].state = state
end)

RegisterServerEvent("TOB_fh:startLoot")
AddEventHandler("TOB_fh:startLoot", function(_, name)
    local _source = source

    if not IsHeistOwner(_source, name) then return end
    -- Everyone near the bank can loot. Bank data comes from the server, not the client.
    for _, id in ipairs(GetPlayers()) do
        id = tonumber(id)
        if id == _source or IsNear(id, TOB.Banks[name].doors.startloc, 60.0) then
            TriggerClientEvent("TOB_fh:startLoot_c", id, TOB.Banks[name], name)
        end
    end
end)

RegisterServerEvent("TOB_fh:stopHeist")
AddEventHandler("TOB_fh:stopHeist", function(name)
    if not IsHeistOwner(source, name) then return end
    TriggerClientEvent("TOB_fh:stopHeist_c", -1, name)
end)

RegisterServerEvent("TOB_fh:rewardCash")
AddEventHandler("TOB_fh:rewardCash", function()
    local _source = source
    local l = Looting[_source]

    if l == nil then return end
    local now = GetGameTimer()
    if now - l.started > GRAB_WINDOW or now - l.last < MIN_PILE_GAP or l.piles >= TOB.MaxPiles then return end
    l.piles = l.piles + 1
    l.last = now
    GiveReward(_source, math.random(TOB.mincash, TOB.maxcash))
end)

RegisterServerEvent("TOB_fh:setCooldown")
AddEventHandler("TOB_fh:setCooldown", function(name)
    if not IsHeistOwner(source, name) then return end
    EndHeist(name)
end)

-- If the player who started the heist leaves, close the vault and end the heist
AddEventHandler("playerDropped", function()
    local _source = source

    Looting[_source] = nil
    for bank, owner in pairs(Owner) do
        if owner == _source then
            TriggerClientEvent("TOB_fh:stopHeist_c", -1, bank)
            Doors[bank][2].locked = true
            TriggerClientEvent("TOB_fh:toggleVault", -1, bank, true)
            EndHeist(bank)
        end
    end
end)

ESX.RegisterServerCallback("TOB_fh:getBanks", function(source, cb)
    cb(TOB.Banks, Doors)
end)
