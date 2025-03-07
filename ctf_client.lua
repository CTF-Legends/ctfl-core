-- How can you see this?
-- Are you a developer? If so, you can see this file.
-- Are you a player? If so, you can't see this file.
-- Are you a Crackhead? If so, you can't see this file.

-- If you start this resource, you are dead.
-- If you stop this resource, you are dead.
-- If you restart this resource, you are dead.

local bInTeamSelection = false
local bIsAttemptingToSwitchTeams = false
local bShouldShowTeamScreen = true
local receivedServerTeams = nil
local lastTeamSelKeyPress = -1
local localTeamSelection = 0
local activeCameraHandle = -1
local entityBlipHandles = {}
local spawnPoints = {}

local CONTROL_LMB = 329
local CONTROL_RMB = 330
local CONTROL_LSHIFT = 209

local BLIP_COLOR_BLUE = 4
local BLIP_COLOR_RED = 1

local spawnmanager = exports.spawnmanager

LocalPlayer.state:set('teamID', TeamType.TEAM_SPECTATOR, true)

AddEventHandler('onClientResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    TriggerServerEvent("requestTeamData")
    print('The resource ' .. resourceName .. ' has been started.')
end)

RegisterNetEvent('ctfl:ShowTeamSelection')
AddEventHandler('ctfl:ShowTeamSelection', function()
    if receivedServerTeams then
        print("Showing team selection menu")
        setIntoTeamSelection(LocalPlayer.state.teamID, true)
    else
        print("Error: receivedServerTeams is nil")
    end
end)

RegisterNetEvent("SetObjectiveVisible")
AddEventHandler("SetObjectiveVisible", function(flagEntityNetID, bVisible)
    if NetworkDoesNetworkIdExist(flagEntityNetID) then
        local flagEntity = NetToEnt(flagEntityNetID)

        print("SetObjectiveVisible: " .. GetEntityArchetypeName(flagEntity) .. " to our player, owner is: " .. GetPlayerName(NetworkGetEntityOwner(flagEntity)))

        SetEntityVisible(flagEntity, bVisible)
    else
        print("AttachFlagToPlayer: Something terrible happened, where's our flag?")
    end
end)

RegisterNetEvent("PlaySoundFrontEnd")
AddEventHandler("PlaySoundFrontEnd", function(soundName, soundSetName)
    PlaySoundFrontend(-1, soundName, soundSetName, false)
end)

AddEventHandler('playerSpawned', function()
    if shouldGoIntoTeamSelection() then
        setIntoTeamSelection(TeamType.TEAM_BLUE, true)
    end
end)

RegisterNetEvent("receiveTeamData")
AddEventHandler("receiveTeamData", function(teamsData)
    print("Received team data from server")
    receivedServerTeams = teamsData

    for _, team in ipairs(receivedServerTeams) do
        spawnPoints[team.id] = spawnmanager:addSpawnPoint({
            x = team.basePosition.x,
            y = team.basePosition.y,
            z = team.basePosition.z,
            heading = team.playerHeading,
            model = team.playerModel,
            skipFade = false
        })
    end
end)

RegisterCommand("switchteam", function(source, args, rawCommand)
    TriggerServerEvent("sendTeamDataToClient", GetPlayerServerId(PlayerId()))
    bIsAttemptingToSwitchTeams = true
    LocalPlayer.state:set('teamID', TeamType.TEAM_SPECTATOR, true)
    SetEntityHealth(PlayerPedId(), 0)
end)

RegisterCommand("kill", function(source, args, rawCommand)
    SetEntityHealth(PlayerPedId(), 0)
end, false)

function handleTeamSelectionControl()
    local teamSelDirection = 0
    local bPressedSpawnKey = false

    if IsControlPressed(0, CONTROL_LMB) then 
        teamSelDirection = -1
    elseif IsControlPressed(0, CONTROL_RMB) then
        teamSelDirection = 1
    elseif IsControlPressed(0, CONTROL_LSHIFT) then
        bInTeamSelection = false
        bIsAttemptingToSwitchTeams = false
        bPressedSpawnKey = true

        spawnmanager:spawnPlayer(
            spawnPoints[LocalPlayer.state.teamID], 
            onPlayerSpawnCallback
        )
    end

    if teamSelDirection ~= 0 or bPressedSpawnKey then
        local newTeamID = LocalPlayer.state.teamID + teamSelDirection
        if newTeamID >= 1 and newTeamID <= #receivedServerTeams then
            LocalPlayer.state:set('teamID', newTeamID, true)
            lastTeamSelKeyPress = GetGameTimer() + 500
        end
        setIntoTeamSelection(LocalPlayer.state.teamID, bInTeamSelection)
    end
end

function onPlayerSpawnCallback()
    local ped = PlayerPedId()

    spawnmanager:spawnPlayer(
        spawnPoints[LocalPlayer.state.teamID]
    )

    GiveWeaponToPed(ped, `weapon_assaultrifle`, 300, false, true)

    NetworkSetFriendlyFireOption(false)

    ClearPedBloodDamage(ped)

    SetEntityVisible(ped, true)

    local TEAM_BLUE_REL_GROUP, TEAM_RED_REL_GROUP = nil, nil

    TEAM_BLUE_REL_GROUP = AddRelationshipGroup('TEAM_BLUE')
    TEAM_RED_REL_GROUP = AddRelationshipGroup('TEAM_RED')

    SetRelationshipBetweenGroups(5, `TEAM_BLUE`, `TEAM_RED`)
    SetRelationshipBetweenGroups(5, `TEAM_RED`, `TEAM_BLUE`)

    if LocalPlayer.state.teamID == TeamType.TEAM_BLUE then
        SetPedRelationshipGroupHash(ped, `TEAM_BLUE`)
    else
        SetPedRelationshipGroupHash(ped, `TEAM_RED`)
    end
end

function formatTeamName(receivedServerTeams, teamID)
    if receivedServerTeams and receivedServerTeams[teamID] then
        return receivedServerTeams[teamID].name .. " Team"
    else
        return "Unknown Team"
    end
end

function shouldGoIntoTeamSelection()
    return LocalPlayer.state.teamID == TeamType.TEAM_SPECTATOR and not bInTeamSelection
end

function setIntoTeamSelection(team, bIsInTeamSelection)
    if not receivedServerTeams or not receivedServerTeams[team] then
        print("Error: Invalid team or receivedServerTeams is nil")
        return
    end

    print("Setting into team selection for team ID: " .. team)

    local ped = PlayerPedId()

    LocalPlayer.state:set('teamID', team, true)
    bInTeamSelection = bIsInTeamSelection
    local origCamCoords = receivedServerTeams[team].basePosition
    local camFromCoords = vector3(origCamCoords.x, origCamCoords.y + 2.0, origCamCoords.z + 2.0)
    if activeCameraHandle == -1 then
        activeCameraHandle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    end

    SetEntityCoords(ped, origCamCoords.x, origCamCoords.y, origCamCoords.z, false, false, false, true)

    SetCamCoord(activeCameraHandle, camFromCoords)
    PointCamAtCoord(activeCameraHandle, origCamCoords)

    RenderScriptCams(bInTeamSelection)

    SetEntityVisible(ped, not bIsInTeamSelection)
end

function tryCreateBlipForEntity(teamID, entity, spriteId)
    local blipHandle = entityBlipHandles[teamID]
    if DoesBlipExist(blipHandle) then
        RemoveBlip(blipHandle)
    end
    local newBlipHandle = AddBlipForEntity(entity)
    SetBlipSprite(newBlipHandle, spriteId)
    SetBlipColour(newBlipHandle, teamID == TeamType.TEAM_RED and BLIP_COLOR_RED or BLIP_COLOR_BLUE)
    return newBlipHandle
end

function processFlagLogic(flagEntityNetID)
    if not NetworkDoesNetworkIdExist(flagEntityNetID) then return end

    local ent = NetToEnt(flagEntityNetID)

    if not DoesEntityExist(ent) then return end

    local time = GetGameTimer() / 1000

    local intensity = 3 * (1 + math.sin(time))

    intensity = math.max(0, math.min(6, intensity))

    local bFreezeInPosition = false

    local es = Entity(ent)

    if es.state.flagStatus == EFlagStatuses.DROPPED then
        local coords = GetEntityCoords(ent)
        Draw3DText(coords.x, coords.y, coords.z, 0.5, screenCaptions.DefendAndGrabThePackage)
    
        DrawLightWithRangeAndShadow(
            coords.x, coords.y, coords.z,
            es.state.flagColor[1], 
            es.state.flagColor[2], 
            es.state.flagColor[3], 
            5.0, 
            intensity,
            1.0
        )

        entityBlipHandles[es.state.teamID] = tryCreateBlipForEntity(
            es.state.teamID,
            ent,
            309
        )

    elseif es.state.flagStatus == EFlagStatuses.TAKEN then
        local carrierPed = GetPlayerPed(GetPlayerFromServerId(es.state.carrierId))
        local carrierCoords = GetEntityCoords(carrierPed)
        DrawLightWithRangeAndShadow(
            carrierCoords.x, carrierCoords.y, carrierCoords.z,
            es.state.flagColor[1], 
            es.state.flagColor[2], 
            es.state.flagColor[3], 
            4.0, 
            intensity,
            1.0
        )

        entityBlipHandles[es.state.teamID] = tryCreateBlipForEntity(
            es.state.teamID,
            carrierPed,
            309
        )
    
        if IsEntityDead(carrierPed) then
            es.state:set('flagStatus', EFlagStatuses.CARRIER_DIED, true)
            TriggerServerEvent("requestFlagUpdate")
            return
        end
    end
    
    if es.state.flagStatus ~= EFlagStatuses.TAKEN then
        if not IsEntityAttachedToAnyPed(ent) then
            local playerPed = PlayerPedId()
            if entityHasEntityInRadius(ent, playerPed) and not IsEntityDead(playerPed) then
                TriggerServerEvent("requestFlagUpdate")
                Citizen.Wait(500)
            end
        end
    end  
    
    if es.state.flagStatus == EFlagStatuses.AT_BASE then
        if DoesBlipExist(entityBlipHandles[es.state.teamID]) then
            RemoveBlip(entityBlipHandles[es.state.teamID])
        end

        bFreezeInPosition = true
    end

    FreezeEntityPosition(ent, bFreezeInPosition)
end

function processBasesForTeams()
    for _, team in ipairs(receivedServerTeams) do
        DrawLightWithRangeAndShadow(
            team.basePosition.x, team.basePosition.y, team.basePosition.z,
            team.flagColor[1],
            team.flagColor[2],
            team.flagColor[3],
            10.0,
            2.0,
            1.0
        )

        if NetworkDoesNetworkIdExist(team.baseNetworkId) then
            local ent = NetToEnt(team.baseNetworkId)
            if not IsEntityPositionFrozen(ent) then
                FreezeEntityPosition(ent, true)
            end
        end
    end
end

function getReceivedServerTeams()
    return receivedServerTeams
end

function isInTeamSelection()
    return bInTeamSelection
end

spawnmanager:setAutoSpawnCallback(onPlayerSpawnCallback)
spawnmanager:setAutoSpawn(true)

Citizen.CreateThread(function()
    while true do
        if not bInTeamSelection then
            if receivedServerTeams and #receivedServerTeams > 0 then
                for _, team in ipairs(receivedServerTeams) do
                    if team.id ~= TeamType.TEAM_SPECTATOR then
                        processFlagLogic(team.flagNetworkedID)
                    end
                end
            end
        end
        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do
        if receivedServerTeams and #receivedServerTeams > 0 then
            if shouldGoIntoTeamSelection() and not bIsAttemptingToSwitchTeams then
                setIntoTeamSelection(TeamType.TEAM_BLUE, true)
            end

            if bInTeamSelection then
                if GetGameTimer() > lastTeamSelKeyPress then
                    handleTeamSelectionControl()
                end
            end
            processBasesForTeams()
        end
        ClearPlayerWantedLevel(PlayerId())

        NetworkOverrideClockTime(23, 0, 0)

        ctfRenderingRenderThisFrame()

        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do
        for _, player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                DeleteEntity(vehicle)
            end
        end
        Citizen.Wait(2000)
    end
end)
local gamerTags = {}

Citizen.CreateThread(function()
    while true do
        for _, player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)
            local entityalpha = GetEntityAlpha(ped)

            if IsEntityVisible(ped) and entityalpha > 99 then
                if not gamerTags[player] then
                    gamerTags[player] = CreateMpGamerTag(ped, GetPlayerName(player), false, false, "", 0)
                end
                
                local teamName = formatTeamName(receivedServerTeams, LocalPlayer.state.teamID)
                SetMpGamerTagVisibility(gamerTags[player], 2, true)
                SetMpGamerTagName(gamerTags[player], GetPlayerName(player) .. " [" .. teamName .. "]")

                if LocalPlayer.state.teamID == TeamType.TEAM_BLUE then
                    SetMpGamerTagColour(gamerTags[player], 0, 0, 255, 255)
                else
                    SetMpGamerTagColour(gamerTags[player], 255, 0, 0, 255)
                end
            else
                if gamerTags[player] then
                    RemoveMpGamerTag(gamerTags[player])
                    gamerTags[player] = nil
                end
            end
        end
        Citizen.Wait(500)
    end
end)
