ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

Doors = {
    ["B1"] = {{loc = vector3(-105.15334320068,6472.7075195312,31.626728057861), h = 42.639282226562, txtloc = vector3(-105.34651184082,6472.708984375,31.626726150513), obj = nil, locked = false}, {loc = vector3(-105.84294891357,6475.4428710938,31.62670135498), txtloc = vector3(-105.84294891357,6475.4428710938,31.62670135498), obj = nil, locked = false}},
}

RegisterServerEvent("TOB_fh:startcheck")
AddEventHandler("TOB_fh:startcheck", function(bank)
    local _source = source
    local copcount = 0
    local Players = ESX.GetPlayers()

    for i = 1, #Players, 1 do
        local xPlayer = ESX.GetPlayerFromId(Players[i])

        if xPlayer.job.name == "police" then
            copcount = copcount + 1
        end
    end
    local xPlayer = ESX.GetPlayerFromId(_source)
    local item = xPlayer.getInventoryItem("id_card_f")["count"]

    if copcount >= TOB.mincops then
        if item >= 1 then
            if not TOB.Banks[bank].onaction == true then
                if (os.time() - TOB.cooldown) > TOB.Banks[bank].lastrobbed then
                    TOB.Banks[bank].onaction = true
                    xPlayer.removeInventoryItem("id_card_f", 1)
                    TriggerClientEvent("TOB_fh:outcome", _source, true, bank)
                    TriggerClientEvent("TOB_fh:policenotify", -1, bank)
                else
                    TriggerClientEvent("TOB_fh:outcome", _source, false, "This bank recently robbed. You need to wait "..math.floor((TOB.cooldown - (os.time() - TOB.Banks[bank].lastrobbed)) / 60)..":"..math.fmod((TOB.cooldown - (os.time() - TOB.Banks[bank].lastrobbed)), 60))
                end
            else
                TriggerClientEvent("TOB_fh:outcome", _source, false, "This bank is currently being robbed.")
            end
        else
            TriggerClientEvent("TOB_fh:outcome", _source, false, "You don't have a malicious access card.")
        end
    else
        TriggerClientEvent("TOB_fh:outcome", _source, false, "There is not enough police in the city.")
    end
end)

RegisterServerEvent("TOB_fh:lootup")
AddEventHandler("TOB_fh:lootup", function(var, var2)
    TriggerClientEvent("TOB_fh:lootup_c", -1, var, var2)
end)

RegisterServerEvent("TOB_fh:openDoor")
AddEventHandler("TOB_fh:openDoor", function(coords, method)
    TriggerClientEvent("TOB_fh:openDoor_c", -1, coords, method)
end)

RegisterServerEvent("TOB_fh:toggleDoor")
AddEventHandler("TOB_fh:toggleDoor", function(key, state)
    Doors[key][1].locked = state
    TriggerClientEvent("TOB_fh:toggleDoor", -1, key, state)
end)

RegisterServerEvent("TOB_fh:toggleVault")
AddEventHandler("TOB_fh:toggleVault", function(key, state)
    Doors[key][2].locked = state
    TriggerClientEvent("TOB_fh:toggleVault", -1, key, state)
end)

RegisterServerEvent("TOB_fh:updateVaultState")
AddEventHandler("TOB_fh:updateVaultState", function(key, state)
    Doors[key][2].state = state
end)

RegisterServerEvent("TOB_fh:startLoot")
AddEventHandler("TOB_fh:startLoot", function(data, name, players)
    local _source = source

    for i = 1, #players, 1 do
        TriggerClientEvent("TOB_fh:startLoot_c", players[i], data, name)
    end
    TriggerClientEvent("TOB_fh:startLoot_c", _source, data, name)
end)

RegisterServerEvent("TOB_fh:stopHeist")
AddEventHandler("TOB_fh:stopHeist", function(name)
    TriggerClientEvent("TOB_fh:stopHeist_c", -1, name)
end)

RegisterServerEvent("TOB_fh:rewardCash")
AddEventHandler("TOB_fh:rewardCash", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local reward = math.random(TOB.mincash, TOB.maxcash)

    if TOB.black then
        xPlayer.addAccountMoney("black_money", reward)
    else
        xPlayer.addMoney(reward)
    end
end)

RegisterServerEvent("TOB_fh:setCooldown")
AddEventHandler("TOB_fh:setCooldown", function(name)
    TOB.Banks[name].lastrobbed = os.time()
    TOB.Banks[name].onaction = false
    TriggerClientEvent("TOB_fh:resetDoorState", -1, name)
end)

ESX.RegisterServerCallback("TOB_fh:getBanks", function(source, cb)
    cb(TOB.Banks, Doors)
end)