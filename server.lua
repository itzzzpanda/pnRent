local Core = nil
local Config = require 'config'

if Config.Core.Name == 'vRP' then
    Tunnel = module("vrp", "lib/Tunnel")
    Proxy = module("vrp", "lib/Proxy")
    vRP = Proxy.getInterface("vRP")
    vRPClient = Tunnel.getInterface("vRP", GetCurrentResourceName())
elseif Config.Core.Name == 'QBCore' then
    Core = exports[Config.Core.ResourceName]:GetCoreObject()
elseif Config.Core.Name == 'ESX' then 
    Core = exports[Config.Core.ResourceName]:getSharedObject()
else
    print("The framework " .. Config.Core.Name .. " is not supported. Check the README.MD to see the supported scripts")
end

local ped = nil

RegisterNetEvent('pnRental:createCar')
AddEventHandler('pnRental:createCar', function(model, plate, day)
    local currentDate = os.date('%Y-%m-%d')  
    local daysToAdd = day 
    local rentFinishDate = os.date('%Y-%m-%d', os.time() + daysToAdd * 24 * 60 * 60) 

    if Config.Core.Name == 'vRP' then
        local Player = vRP.getUserId({source})

        MySQL.insert.await('INSERT INTO vrp_user_vehicles ( user_id, vehicle, vehicle_plate, upgrades, vId, stage, rentfinish ) VALUES ( ?, ?, ?, ?, ?, ?, ? )', {
            Player,
            model,
            plate,
            json.encode(prop),
            1,
            0,
            rentFinishDate
        })
    elseif Config.Core.Name == 'ESX' then
        local xPlayer = Core.GetPlayerFromId(source) 

        MySQL.insert.await('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored, rentfinish) VALUES (?, ?, ?, ?, ?, ?)', {
            xPlayer.identifier,  
            plate,
            json.encode({model = model}),  
            'car',
            1, 
            rentFinishDate
        })
    elseif Config.Core.Name == 'QBCore' then
        local Player = Core.Functions.GetPlayer(source) 

        MySQL.insert.await('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, rentfinish) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.license,
            Player.PlayerData.citizenid,
            model, 
            GetHashKey(model),
            json.encode(prop),
            plate,
            0,
            rentFinishDate
        }) 
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then 
        if ped ~= nil then
            DeletePed(ped)
        end
            TriggerEvent('pnRental:createPed')
            if Config.Core.Name == 'vRP' then
                MySQL.Async.execute("DELETE FROM vrp_user_vehicles WHERE rentfinish < NOW()", {})
            elseif Config.Core.Name == 'ESX' then
                MySQL.Async.execute("DELETE FROM owned_vehicles WHERE rentfinish < NOW()", {})
            elseif Config.Core.Name == 'QBCore' then
                MySQL.Async.execute("DELETE FROM player_vehicles WHERE rentfinish < NOW()", {})
            end
            return
        end
end)

lib.callback.register('pnRental:rent', function(source, data)
    if Config.Core.Name == 'vRP' then
        local Player = vRP.getUserId({source})
        if data.payType == 'cash' then
            if vRP.getMoney({source}) >= data.carPrice then
                vRP.tryPayment({source, data.carPrice})
                return true
            else 
                return false
            end
        else
            if vRP.getBankMoney({source}) >= data.carPrice then
                vRP.tryBankPayment({source, data.carPrice})
                return true
            else
                return false
            end
        end
    elseif Config.Core.Name == 'ESX' then
        local Player = Core.GetPlayerFromId(source)

        if data.payType == 'cash' then 
            if Player.getAccount('money').money >= data.carPrice then
                Player.removeMoney(data.carPrice, 'Rented vehicle')
                return true
            else 
                return false
            end
        else
            if Player.getAccount('bank').money >= data.carPrice then           

                Player.removeAccountMoney('bank', data.carPrice)
                return true
            else
                return false
            end
        end
    elseif Config.Core.Name == 'QBCore' then 
        local Player = Core.Functions.GetPlayer(source)
        if data.payType == "cash" then
            if Player.Functions.GetMoney(data.payType) >= data.carPrice then
                Player.Functions.RemoveMoney('cash', data.carPrice)
                return true
            end
            return false
        else        
            if Player.PlayerData.money.bank >= data.carPrice then
                Player.Functions.RemoveMoney(data.payType, data.carPrice)
                return true
            end
            return false
        end
    end
end)

if Config.VersionCheck then 
    lib.versionCheck('PandaRomania/pnRent')
end
