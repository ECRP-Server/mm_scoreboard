local QBCore = exports['qb-core']:GetCoreObject()

local connectedPlayers = {}
local recentPlayers = {}
local verified = true

-- Functions
local function HexIdToSteamId(hexId)
    if hexId == 'N/A' then
        return 'N/A'
    end
    local cid = math.floor(tonumber(string.sub(hexId, 7), 16))
	local steam64 = math.floor(tonumber(string.sub( cid, 2)))
	local a = steam64 % 2 == 0 and 0 or 1
	local b = math.floor(math.abs(6561197960265728 - steam64 - a) / 2)
	local sid = "STEAM_0:"..a..":"..(a == 1 and b -1 or b)
    return sid
end

local function GetIdentifier(source, idtype)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, idtype) then
            return identifier
        end
    end
    return nil
end

-- Events
AddEventHandler("playerDropped", function(reason)
    if not verified then return end
    local plyid = source
    if not connectedPlayers[plyid] then return end

    recentPlayers[plyid] = {
        id = plyid or 0,
        name = connectedPlayers[plyid].name or 'N/A',
        steam2 = connectedPlayers[plyid].steam2 or 'N/A',
        steam3 = connectedPlayers[plyid].steam3 or 'N/A',
        license = connectedPlayers[plyid].license or 'N/A',
        discord = connectedPlayers[plyid].discord or 'N/A',
        color = connectedPlayers[plyid].color or {255, 255, 255}
    }
    connectedPlayers[plyid] = nil

    TriggerClientEvent("mm_scoreboard:client:UpdateConnect", -1, connectedPlayers)
	TriggerClientEvent("mm_scoreboard:client:combat", -1, source, GetEntityCoords(GetPlayerPed(source)), recentPlayers[plyid].license, reason)
    TriggerClientEvent("mm_scoreboard:client:UpdateRecent", -1, recentPlayers)
    Wait(600000)
    recentPlayers[plyid] = nil
    TriggerClientEvent("mm_scoreboard:client:UpdateRecent", -1, recentPlayers)
end)

RegisterNetEvent('mm_scoreboard:server:AddPlayer', function()
    if not verified then return end
    local src = source
    local steamIdentifier = GetIdentifier(src, 'steam') or 'N/A'
    local licenseIdentifier = GetIdentifier(src, 'license') or 'N/A'
    local disocrdIdentifier = GetIdentifier(src, 'discord') or 'N/A'
    local color = {255, 255, 255}
    local icon = nil

    local steam2 = HexIdToSteamId(steamIdentifier)
    local ply = GetPlayerName(src)
    local steam3 = steamIdentifier:gsub("steam:", "")
    local license = 'N/A'
    local discord = disocrdIdentifier:gsub("discord:", "")
    if string.find(licenseIdentifier, "license:") then
        license = licenseIdentifier:gsub("license:", "")
    elseif string.find(licenseIdentifier, "license2:") then
        license = licenseIdentifier:gsub("license2:", "")
    end

    if Config.EnablePriorityColor then
        for k, v in pairs(Config.PriorityColor) do
            local hasRole = exports[GetCurrentResourceName()]:GetDiscordRoles(src, k)
            if hasRole  then
                color = v
                break
            end
        end
    end

    if Config.EnableIcon then
        for k, v in pairs(Config.Icons) do
            local hasRole = exports[GetCurrentResourceName()]:GetDiscordRoles(src, k)
            if hasRole  then
                icon = v
                break
            end
        end
    end

    local plyid = src
    connectedPlayers[plyid] = {
        id = plyid or 0,
        name = ply or 'N/A',
        steam2 = steam2,
        steam3 = steam3 or 'N/A',
        license = license,
        discord = discord or 'N/A',
        color = color,
        icon = icon
    }

    TriggerClientEvent("mm_scoreboard:client:UpdateConnect", -1, connectedPlayers)
end)

RegisterNetEvent('mm_robbery:server:sync', function(time)
    TriggerClientEvent('mm_robbery:client:sync', -1, Config.Robberies, time)
end)

RegisterNetEvent('mm_robbery:server:getservicedata', function()
    for k, v in pairs(Config.Services) do
        local amount = 0
        local players = QBCore.Functions.GetQBPlayers()
        for _, ply in pairs(players) do
            if ply and ply.PlayerData.job.name == v.job and ply.PlayerData.job.onduty then
                amount += 1
            end
        end
        v.amount = amount
        for _, rob in pairs(Config.Robberies) do
            if rob.job == v.job and rob.jobamount > v.amount then
                rob.status = true
            end
        end
    end
    TriggerClientEvent("mm_robbery:client:sync1", source, Config.Services, Config.Robberies)
end)