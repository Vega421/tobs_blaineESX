-- tobs_blaine server. Shared by every framework version; framework-specific code is in bridge/server.lua.

-- Door state for every bank, built from the gate and vault settings in TOB.Banks
Doors = {}
for bank, b in pairs(TOB.Banks) do
    Doors[bank] = {
        {loc = b.gate.loc, h = b.gate.h, txtloc = b.gate.txtloc, locked = false},
        {loc = b.vault.loc, txtloc = b.vault.txtloc, locked = false},
    }
end

-- Heist state lives on the server, so a cheater can't trigger payouts,
-- doors or heist events from their own game.
local Owner = {}      -- [bank] = server id of the player who started the heist
local Started = {}    -- [bank] = os.time() the heist started
local Looted = {}     -- [bank] = {Loot1 = true, ...}
local Looting = {}    -- [server id] = {bank, started, last, piles}
local Payouts = {}    -- [bank] = {[server id] = {name, cash, items, piles}}
local VaultReady = {} -- [bank] = true once TOB.VaultItem has been used
local Trolleys = {Loot1 = "trolley1", Loot2 = "trolley2", Loot3 = "trolley3"}
local GRAB_WINDOW = 50000 -- ms a player can collect piles after starting a trolley (the animation is about 40 s)
local MIN_PILE_GAP = 250  -- ms between two piles

local function VaultItemEnabled()
    return TOB.VaultItem ~= nil and TOB.VaultItem ~= ""
end

-- DISCORD LOGS --

local function PlayerLabel(src)
    local name = GetPlayerName(src) or "unknown"
    local license = "unknown"
    local discord

    for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do
        if id:find("^license:") then license = id end
        if id:find("^discord:") then discord = id:sub(9) end
    end
    local label = ("**%s** (id %s, `%s`)"):format(name, src, license)
    if discord then
        label = label .. (" <@%s>"):format(discord)
    end
    return label
end

local function Log(title, description, color)
    print(("[tobs_blaine] %s: %s"):format(title, description:gsub("%*", ""):gsub("`", "")))
    if SV.Webhook == nil or SV.Webhook == "" then return end
    PerformHttpRequest(SV.Webhook, function() end, "POST", json.encode({
        username = "tobs_blaine",
        embeds = {{
            title = title,
            description = description,
            color = color,
            footer = {text = GetCurrentResourceName()},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }},
    }), {["Content-Type"] = "application/json"})
end

-- Anti-cheat flags, at most once a minute per player and reason so a cheater can't flood the webhook
local flagged = {}
local function Flag(src, reason)
    if not SV.LogAntiCheat then return end
    local key = tostring(src) .. reason
    if flagged[key] and os.time() - flagged[key] < 60 then return end
    flagged[key] = os.time()
    Log("Suspicious event blocked", PlayerLabel(src) .. "\n" .. reason, 15158332)
end

-- HELPERS --

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

local function Duration(seconds)
    return ("%dm %02ds"):format(math.floor(seconds / 60), seconds % 60)
end

-- Ends the heist. cooldown = false (admin reset) lets the bank be robbed again straight away.
local function EndHeist(bank, reason, cooldown)
    local lines = {}
    local total = 0

    for _, p in pairs(Payouts[bank] or {}) do
        total = total + p.cash
        local items = (TOB.RewardItem or "") ~= "" and (" (%d × %s)"):format(p.items, TOB.RewardItem) or ""
        lines[#lines + 1] = ("%s: $%d%s from %d piles"):format(p.name, p.cash, items, p.piles)
    end
    if Started[bank] then
        Log("Heist ended: " .. bank, ("Reason: %s\nDuration: %s\nTotal: $%d\n%s"):format(
            reason, Duration(os.time() - Started[bank]), total, #lines > 0 and table.concat(lines, "\n") or "Nobody was paid."), 15105570)
    end

    TOB.Banks[bank].lastrobbed = cooldown == false and 0 or os.time()
    TOB.Banks[bank].onaction = false
    Owner[bank] = nil
    Started[bank] = nil
    Looted[bank] = nil
    Payouts[bank] = nil
    VaultReady[bank] = nil
    for id, l in pairs(Looting) do
        if l.bank == bank then Looting[id] = nil end
    end
end

local function CloseVault(bank)
    Doors[bank][2].locked = true
    TriggerClientEvent("TOB_fh:toggleVault", -1, bank, true)
end

local function CooldownLeft(bank)
    local left = TOB.cooldown - (os.time() - TOB.Banks[bank].lastrobbed)
    return string.format("%d:%02d", math.floor(left / 60), math.floor(math.fmod(left, 60)))
end

local function GiveReward(src, amount)
    if TOB.RewardItem ~= nil and TOB.RewardItem ~= "" then
        local count = TOB.RewardItemCount == "cash" and amount or (tonumber(TOB.RewardItemCount) or 1)
        Bridge.AddItem(src, TOB.RewardItem, count)
        return count
    end
    Bridge.AddMoney(src, amount, TOB.black)
    return 0
end

-- EVENTS --

RegisterServerEvent("TOB_fh:startcheck")
AddEventHandler("TOB_fh:startcheck", function(bank)
    local _source = source

    if TOB.Banks[bank] == nil or Bridge.IsPolice(_source) then return end
    if not IsNear(_source, TOB.Banks[bank].doors.startloc, 5.0) then
        Flag(_source, "Tried to start the heist at " .. tostring(bank) .. " from far away.")
        return
    end

    if Bridge.CountPolice() < TOB.mincops then
        TriggerClientEvent("TOB_fh:outcome", _source, false, L("no_cops"))
    elseif not Bridge.HasItem(_source, "id_card_f", 1) then
        TriggerClientEvent("TOB_fh:outcome", _source, false, L("no_card"))
    elseif TOB.Banks[bank].onaction then
        TriggerClientEvent("TOB_fh:outcome", _source, false, L("busy"))
    elseif (os.time() - TOB.cooldown) <= TOB.Banks[bank].lastrobbed then
        TriggerClientEvent("TOB_fh:outcome", _source, false, L("cooldown", CooldownLeft(bank)))
    else
        TOB.Banks[bank].onaction = true
        Owner[bank] = _source
        Started[bank] = os.time()
        Looted[bank] = {}
        Payouts[bank] = {}
        Bridge.RemoveItem(_source, "id_card_f", 1)
        TriggerClientEvent("TOB_fh:outcome", _source, true, bank)
        TriggerClientEvent("TOB_fh:policenotify", -1, bank)
        Log("Heist started: " .. bank, PlayerLabel(_source) .. " started a heist.", 16740396)
    end
end)

RegisterServerEvent("TOB_fh:useVaultItem")
AddEventHandler("TOB_fh:useVaultItem", function(bank)
    local _source = source

    if not VaultItemEnabled() or not IsHeistOwner(_source, bank) or VaultReady[bank] then return end
    if not IsNear(_source, Doors[bank][2].loc, 5.0) then
        Flag(_source, "Tried to use the vault item at " .. tostring(bank) .. " from far away.")
        return
    end
    if Bridge.HasItem(_source, TOB.VaultItem, 1) then
        Bridge.RemoveItem(_source, TOB.VaultItem, 1)
        VaultReady[bank] = true
        TriggerClientEvent("TOB_fh:vaultItemResult", _source, bank, true)
    else
        TriggerClientEvent("TOB_fh:vaultItemResult", _source, bank, false)
    end
end)

RegisterServerEvent("TOB_fh:lootup")
AddEventHandler("TOB_fh:lootup", function(bank, trolley)
    local _source = source

    if TOB.Banks[bank] == nil or not TOB.Banks[bank].onaction or Trolleys[trolley] == nil then return end
    if Bridge.IsPolice(_source) then return end
    Looted[bank] = Looted[bank] or {}
    if Looted[bank][trolley] then return end
    if not IsNear(_source, TOB.Banks[bank][Trolleys[trolley]], 5.0) then
        Flag(_source, "Tried to loot a trolley at " .. tostring(bank) .. " from far away.")
        return
    end

    Looted[bank][trolley] = true
    Looting[_source] = {bank = bank, started = GetGameTimer(), last = 0, piles = 0}
    TriggerClientEvent("TOB_fh:lootup_c", -1, bank, trolley)
end)

RegisterServerEvent("TOB_fh:toggleDoor")
AddEventHandler("TOB_fh:toggleDoor", function(key, state)
    local _source = source

    if Doors[key] == nil then return end
    if not (Bridge.IsPolice(_source) or IsHeistOwner(_source, key)) then
        Flag(_source, "Tried to use the gate at " .. tostring(key) .. " without being police or the robber.")
        return
    end
    Doors[key][1].locked = state
    TriggerClientEvent("TOB_fh:toggleDoor", -1, key, state)
end)

RegisterServerEvent("TOB_fh:toggleVault")
AddEventHandler("TOB_fh:toggleVault", function(key, state)
    local _source = source

    if Doors[key] == nil then return end
    local police = Bridge.IsPolice(_source)
    if not (police or IsHeistOwner(_source, key)) then
        Flag(_source, "Tried to use the vault at " .. tostring(key) .. " without being police or the robber.")
        return
    end
    -- With TOB.VaultItem set, the robber can only open the vault after using the item
    if not police and state == false and VaultItemEnabled() and not VaultReady[key] then
        Flag(_source, "Tried to open the vault at " .. tostring(key) .. " without using " .. TOB.VaultItem .. ".")
        return
    end
    Doors[key][2].locked = state
    TriggerClientEvent("TOB_fh:toggleVault", -1, key, state)
end)

RegisterServerEvent("TOB_fh:updateVaultState")
AddEventHandler("TOB_fh:updateVaultState", function(key, state)
    if Doors[key] == nil or type(state) ~= "number" then return end
    if not IsNear(source, Doors[key][2].loc, 60.0) then return end
    Doors[key][2].state = state
    -- Share the final vault angle, so players who weren't nearby see it correctly later
    TriggerClientEvent("TOB_fh:vaultState", -1, key, state)
end)

RegisterServerEvent("TOB_fh:startLoot")
AddEventHandler("TOB_fh:startLoot", function(_, name)
    local _source = source

    if not IsHeistOwner(_source, name) then
        Flag(_source, "Tried to start the loot phase at " .. tostring(name) .. " without being the robber.")
        return
    end
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

    if l == nil then
        Flag(_source, "Asked for heist cash without looting a trolley.")
        return
    end
    local now = GetGameTimer()
    if now - l.started > GRAB_WINDOW then return end
    if now - l.last < MIN_PILE_GAP then
        Flag(_source, "Asked for heist cash faster than the grab animation allows.")
        return
    end
    if l.piles >= TOB.MaxPiles then
        Flag(_source, ("Hit TOB.MaxPiles (%d) on one trolley. If this happens to normal players, raise TOB.MaxPiles."):format(TOB.MaxPiles))
        return
    end
    l.piles = l.piles + 1
    l.last = now

    local amount = math.random(TOB.mincash, TOB.maxcash)
    local items = GiveReward(_source, amount)
    local p = Payouts[l.bank] and Payouts[l.bank][_source]
    if Payouts[l.bank] and not p then
        p = {name = GetPlayerName(_source) or tostring(_source), cash = 0, items = 0, piles = 0}
        Payouts[l.bank][_source] = p
    end
    if p then
        p.cash = p.cash + amount
        p.items = p.items + items
        p.piles = p.piles + 1
    end
end)

local EndReasons = {
    hack_failed = "the robber failed the hacking minigame",
    vault_timeout = "the robber didn't open the vault in time",
}

RegisterServerEvent("TOB_fh:setCooldown")
AddEventHandler("TOB_fh:setCooldown", function(name, reason)
    if not IsHeistOwner(source, name) then return end
    EndHeist(name, EndReasons[reason] or "finished")
end)

-- If the player who started the heist leaves, close the vault and end the heist
AddEventHandler("playerDropped", function()
    local _source = source

    Looting[_source] = nil
    for bank, owner in pairs(Owner) do
        if owner == _source then
            TriggerClientEvent("TOB_fh:stopHeist_c", -1, bank)
            CloseVault(bank)
            EndHeist(bank, "the robber disconnected")
        end
    end
end)

Bridge.RegisterCallback("TOB_fh:getBanks", function(source, cb)
    cb(TOB.Banks, Doors)
end)

-- ADMIN RESET --
-- /tobreset [bank]  (no bank = all banks). Needs: add_ace group.admin command.tobreset allow
RegisterCommand(SV.ResetCommand, function(src, args)
    local who = src == 0 and "the server console" or PlayerLabel(src)
    local count = 0

    for bank, _ in pairs(TOB.Banks) do
        if args[1] == nil or args[1] == bank then
            TriggerClientEvent("TOB_fh:stopHeist_c", -1, bank)
            TriggerClientEvent("TOB_fh:forceReset", -1, bank)
            CloseVault(bank)
            Doors[bank][1].locked = false
            TriggerClientEvent("TOB_fh:toggleDoor", -1, bank, false)
            EndHeist(bank, "reset by an admin", false)
            count = count + 1
        end
    end
    local msg = count > 0 and ("Reset %d bank(s)."):format(count) or ("No bank called %s."):format(args[1])
    if src == 0 then
        print("[tobs_blaine] " .. msg)
    else
        TriggerClientEvent("TOB_fh:outcome", src, false, msg)
    end
    if count > 0 then
        Log("Heist reset", who .. " reset " .. (args[1] or "all banks") .. ".", 3447003)
    end
end, true)

-- UPDATE CHECK --

local function IsNewer(latest, current)
    local a, b = {}, {}
    for n in latest:gmatch("%d+") do a[#a + 1] = tonumber(n) end
    for n in current:gmatch("%d+") do b[#b + 1] = tonumber(n) end
    for i = 1, math.max(#a, #b) do
        local x, y = a[i] or 0, b[i] or 0
        if x ~= y then return x > y end
    end
    return false
end

Citizen.CreateThread(function()
    if not SV.CheckForUpdates then return end
    Citizen.Wait(5000)
    local current = GetResourceMetadata(GetCurrentResourceName(), "version", 0) or "0.0.0"

    PerformHttpRequest(("https://api.github.com/repos/%s/releases/latest"):format(Bridge.Repo), function(status, body)
        if status ~= 200 or not body then return end
        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= "table" or type(data.tag_name) ~= "string" then return end
        local latest = data.tag_name:gsub("^v", "")
        if IsNewer(latest, current) then
            print(("^3[tobs_blaine] Version %s is available (you have %s). Download: %s^7"):format(latest, current, data.html_url))
        else
            print(("^2[tobs_blaine] Version %s is up to date.^7"):format(current))
        end
    end, "GET", "", {["User-Agent"] = "tobs_blaine", ["Accept"] = "application/vnd.github+json"})
end)
