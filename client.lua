local Core = nil
local Config = require 'config'
if Config.Core.Name == 'vRP' then
    Tunnel = module("vrp", "lib/Tunnel")
    Proxy = module("vrp", "lib/Proxy")
    vRP = Proxy.getInterface("vRP")
elseif Config.Core.Name == 'QBCore' then
    Core = exports[Config.Core.ResourceName]:GetCoreObject()
elseif Config.Core.Name == 'ESX' then 
    Core = exports[Config.Core.ResourceName]:getSharedObject()
else
    print("The frmework " .. Config.Core.Name .. " is not supported. Check the README.MD to see the supported scripts")
end
lib.locale()
local pedSpawned = false
local ShopPed = {}

local spawncarcoords

local function openRentMenu(data)
    SendNUIMessage({
        action = "OPEN",
        data = data
    })
    SetNuiFocus(true, true)
end

RegisterNUICallback('pnRental:rent', function(data)
    lib.callback('pnRental:rent', function(status)
        if status then
            if Config.Core.Name == 'vRP' then
                vRP.Notify(locale("success.paid", data.carPrice))
            elseif Config.Core.Name == 'QBCore' then
                Core.Functions.Notify(locale("success.paid", data.carPrice), 'success')
            elseif Config.Core.Name == 'ESX' then 
                Core.ShowNotification(locale("success.paid", data.carPrice), "success", 5000)
            end
            createCar(data)
        else
            if Config.Core.Name == 'vRP' then
                vRP.Notify(locale("error.not_enough"))
            elseif Config.Core.Name == 'QBCore' then
                Core.Functions.Notify(locale("error.not_enough"), 'error')
            elseif Config.Core.Name == 'ESX' then 
                Core.ShowNotification(locale("error.not_enough"), "error", 5000)
            end
        end
    end, data)
end)

function createCar(data)
    local playerPed = PlayerPedId()
    local coords    = spawncarcoordsnui
    local vehicle   = GetHashKey(data.carName)
    RequestModel(vehicle)

    while not HasModelLoaded(vehicle) do
        Citizen.Wait(0)
    end

    local vehicle = CreateVehicle(vehicle, spawncarcoords, 90.0, true, false)
    SetVehicleColours(vehicle, 12, 12)
    SetVehicleWindowTint(vehicle, 1)
    SetPedIntoVehicle(playerPed, vehicle, -1)
    SetVehicleNumberPlateText(vehicle, 'LS' .. math.random(10, 99) .. string.char(math.random(65, 90)) .. string.char(math.random(65, 90)) .. string.char(math.random(65, 90))) 
    exports[Config.FuelResource]:SetFuel(vehicle, 100)
    TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(vehicle))
    TriggerServerEvent('pnRental:createCar', data.carName, GetVehicleNumberPlateText(vehicle) , data.carDay)
end


local function createBlips()
    if pedSpawned then return end

    for store in pairs(Config.Locations) do
        if Config.Locations[store]["showblip"] then
            local StoreBlip = AddBlipForCoord(Config.Locations[store]["coords"]["x"], Config.Locations[store]["coords"]["y"], Config.Locations[store]["coords"]["z"])
            SetBlipSprite(StoreBlip, Config.Locations[store]["blipsprite"])
            SetBlipScale(StoreBlip, Config.Locations[store]["blipscale"])
            SetBlipDisplay(StoreBlip, 4)
            SetBlipColour(StoreBlip, Config.Locations[store]["blipcolor"])
            SetBlipAsShortRange(StoreBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Config.Locations[store]["label"])
            EndTextCommandSetBlipName(StoreBlip)
        end
    end
end

local function createPeds()
    if pedSpawned then return end

    for k, v in pairs(Config.Locations) do
        local current = type(v["ped"]) == "number" and v["ped"] or joaat(v["ped"])

        RequestModel(current)
        while not HasModelLoaded(current) do
            Wait(0)
        end

        ShopPed[k] = CreatePed(0, current, v["coords"].x, v["coords"].y, v["coords"].z - 1, v["coords"].w, false, false)
        TaskStartScenarioInPlace(ShopPed[k], v["scenario"], 0, true)
        FreezeEntityPosition(ShopPed[k], true)
        SetEntityInvincible(ShopPed[k], true)
        SetBlockingOfNonTemporaryEvents(ShopPed[k], true)
        
        if Config.Interactions.Target.Enabled and Config.Interactions.Target.ResourceName == 'qb-target' then
            exports['qb-target']:AddTargetEntity(ShopPed[k], {
                options = {
                    {
                        label = locale("target.open"),
                        icon = v["targetIcon"],
                        onSelect = function()
                            spawncarcoords = v.carspawn,
                            openRentMenu(v.categorie)
                        end,
                    }
                },
                distance = 2.0
            })
        elseif Config.Interactions.Target.ResourceName == 'ox_target' then
            exports.ox_target:addModel(ShopPed[k], {
                {
                    label = locale("target.open"),
                    icon = v["targetIcon"],
                    onSelect = function()
                        spawncarcoords = v.carspawn,
                        openRentMenu(v.categorie)
                    end,
                }
            })
        else
            print('The Target system you selected is not supported. Edit pnRent > client.lua > 133th line to add suport to custom one')
        end

        if Config.Interactions.TextUI.Enabled then
            lib.zones.box({
                coords = vec3(v["coords"].x, v["coords"].y, v["coords"].z - 1),
                size = vec3(1.5, 1.5, 1.5),
                onEnter = function()
                    Config.Interactions.TextUI.Open(locale("textui.open"))
                end,
                onExit = function()
                    Config.Interactions.TextUI.Close()
                end
            })
        end
    end

    pedSpawned = true
end


local function deletePeds()
    if not pedSpawned then return end
    for _, v in pairs(ShopPed) do
        DeletePed(v)
    end
    pedSpawned = false
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    createBlips()
    createPeds()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    deletePeds()
end)


RegisterNUICallback('pnRental:close', function()
    SetNuiFocus(false, false)
end)