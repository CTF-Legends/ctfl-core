-- How can you see this?
-- Are you a developer? If so, you can see this file.
-- Are you a player? If so, you can't see this file.
-- Are you a Crackhead? If so, you can't see this file.
-- Are you a Skid? If so, you cant't see this file.

-- If you start this resource, you are dead.
-- If you stop this resource, you are dead.
-- If you restart this resource, you are dead.

local UIConfig = ctfConfig.UI
local screenCaptions = UIConfig.screenCaptions

Team = {}
Team.__index = Team

function Team.new(id, flagColor, basePosition, playerModel, playerHeading)
    local self = setmetatable({}, Team)
    self.id = id
    self.flagColor = flagColor
    self.basePosition = basePosition
    self.entity = nil
    self.score = 0
    self.playerModel = playerModel
    self.playerHeading = playerHeading
    return self
end

function Team:createBaseObject()
    local baseEntity = CreateObjectNoOffset(
        `xs_propint2_stand_thin_02_ring`,
        self.basePosition.x, self.basePosition.y, self.basePosition.z - 0.85
    )
    while not DoesEntityExist(baseEntity) do
        Citizen.Wait(1)
    end
    FreezeEntityPosition(baseEntity, true)
    self.entity = Entity(baseEntity)
    self.networkedID = NetworkGetNetworkIdFromEntity(self.entity)
end

function Team:goalBaseHasEntityInRadius(targetEntity, radius)
    radius = radius or 2.5
    local targetEntityPos = GetEntityCoords(targetEntity)
    local distance = #(self.basePosition - targetEntityPos)
    return distance < radius
end

function Team:getName()
    if self.id == TeamType.TEAM_BLUE then
        return "Blue"
    end
    if self.id == TeamType.TEAM_RED then
        return "Red"
    end
    return "Spectator"
end

function Team:updateScore(score)
    self.score = self.score + score
end

function Team:destroy()
    DeleteEntity(self.entity)
    self.id = -1
    self.flagColor = {0, 0, 0}
    self.basePosition = nil
    self.entity = nil
    setmetatable(self, nil)
end

Flag = {}
Flag.__index = Flag

function Flag.new(id, modelHash, team, spawnPosition)
    local self = setmetatable({}, Flag)
    self.id = id
    self.modelHash = modelHash
    self.entity = nil
    self.team = team
    self.spawnPosition = spawnPosition
    self.hasBeenCaptured = false
    self.networkedID = -1
    return self
end

function Flag:spawn()
    print('Spawning flag at: ' .. self.spawnPosition)
    local flagEntity = CreateObjectNoOffset(self.modelHash, self.spawnPosition)
    while not DoesEntityExist(flagEntity) do
        Citizen.Wait(1)
    end
    SetEntityVelocity(flagEntity, 0, 0, -1.0)
    self.entity = Entity(flagEntity)
    self.networkedID = NetworkGetNetworkIdFromEntity(self.entity)
    self.entity.state.networkedID = self.networkedID
    self.entity.state.teamID = self.team.id
    self.entity.state.position = self.spawnPosition
    self.entity.state.flagColor = self.team.flagColor
    self.entity.state.flagStatus = EFlagStatuses.AT_BASE
    self.entity.state.carrierId = -1
    self.entity.state.lastCooldown = GetGameTimer()
    self.entity.state.autoReturnTime = GetGameTimer()
end

function Flag:getFlagStatus()
    if self.entity then
        return self.entity.state.flagStatus
    end
    return nil
end

function Flag:getFlagNetworkedID()
    return self.networkedID
end

function Flag:carrierDied()
    return self:getFlagStatus() == EFlagStatuses.CARRIER_DIED
end

function Flag:isBeingCarried()
    return self.entity.state.carrierId ~= -1
end

function Flag:isFlagCarrier(playerId)
    return self.entity.state.carrierId == playerId
end

function Flag:isTaken()
    return self:getFlagStatus() == EFlagStatuses.TAKEN
end

function Flag:isCaptured()
    return self:getFlagStatus() == EFlagStatuses.CAPTURED
end

function Flag:isDropped()
    return self:getFlagStatus() == EFlagStatuses.DROPPED
end

function Flag:isAtBase()
    local distance = #(GetEntityCoords(self.entity) - self.spawnPosition)
    return distance < 5.0
end

function Flag:setNextCooldown(timeMs)
    self.entity.state.lastCooldown = GetGameTimer() + timeMs
end

function Flag:setAutoReturnTime(timeMs)
    self.entity.state.autoReturnTime = GetGameTimer() + timeMs
end

function Flag:isPastCooldown()
    return GetGameTimer() > self.entity.state.lastCooldown
end

function Flag:isPastAutoReturnTime()
    return GetGameTimer() > self.entity.state.autoReturnTime
end

function Flag:setStatus(status)
    self.entity.state.flagStatus = status
end

function Flag:getStatus()
    return self.entity.state.flagStatus
end

function Flag:hasEntityInRadius(targetEntity, radius)
    return entityHasEntityInRadius(self.entity, targetEntity, radius)
end

function Flag:setPosition(position)
    print("setPosition: " .. position .. " entity: " .. tostring(self.entity))
    SetEntityCoords(self.entity, position.x, position.y, position.z, true, true, true, true)
end

function Flag:sendBackToBase()
    self:setNextCooldown(500)
    self:setPosition(self.spawnPosition)
    self:setStatus(EFlagStatuses.AT_BASE)
    SetEntityVelocity(self.entity, 0, 0, -1.0)
    self.entity.state.carrierId = -1
    TriggerClientEvent("SetObjectiveVisible", -1, self:getFlagNetworkedID(), true)
    print(string.format("Sent %s flag back to %f, %f, %f\n", self.team:getName(), self.spawnPosition.x, self.spawnPosition.y, self.spawnPosition.z))
end

function Flag:setAsDropped()
    local carrierId = self.entity.state.carrierId
    self:setStatus(EFlagStatuses.DROPPED)
    self:setPosition(GetEntityCoords(GetPlayerPed(carrierId)))
    self.entity.state.carrierId = -1
    self:setNextCooldown(5000)
    self:setAutoReturnTime(30000)
    TriggerClientEvent("SetObjectiveVisible", -1, self:getFlagNetworkedID(), true)
end

function Flag:destroy()
    print("Flag:destroy\n")
    DeleteEntity(self.entity)
    self.id = -1
    self.modelHash = modelHash
    self.entity = nil
    self.team = team
    self.spawnPosition = spawnPosition
    self.hasBeenCaptured = false
    self.networkedID = -1
    setmetatable(self, nil)
end

CTFGame = {}
CTFGame.__index = CTFGame

local WINNING_SCORE = 1

function CTFGame.new()
    local self = setmetatable({}, CTFGame)
    self.teams = {}
    for _, teamConfig in ipairs(ctfConfig.teams) do
        self.teams[teamConfig.id] = Team.new(
            teamConfig.id,
            teamConfig.flagColor,
            teamConfig.basePosition,
            teamConfig.playerModel,
            teamConfig.playerHeading
        )
    end
    self.flags = {}
    for _, flagConfig in ipairs(ctfConfig.flags) do
        self.flags[flagConfig.teamID] = Flag.new(
            flagConfig.teamID,
            flagConfig.model,
            self.teams[flagConfig.teamID],
            flagConfig.position
        )
    end
    self.leadingTeam = nil
    return self
end

function CTFGame:start()
    for _, team in ipairs(self.teams) do
        team:createBaseObject()
    end
    for _, flag in ipairs(self.flags) do
        print('Spawning flag owned by team: ' .. flag.team.id)
        flag:spawn()
    end
end

function GetCTFGame()
    if not ctfGame then
        ctfGame = CTFGame.new()
    end
    return ctfGame
end

function CTFGame:getPlayerTeam(source)
    local playerState = Player(source).state
    local teamID = playerState.teamID
    local playerTeam = self.teams[teamID] or self.teams[TeamType.TEAM_SPECTATOR]
    return playerTeam 
end

function CTFGame:getFlag(source, bGetEnemyFlag)
    local playerTeam = self:getPlayerTeam(source)
    if bGetEnemyFlag then
        local enemyTeamIndex = (playerTeam.id == TeamType.TEAM_BLUE) and TeamType.TEAM_RED or TeamType.TEAM_BLUE
        return self.flags[enemyTeamIndex] or nil
    else
        return self.flags[playerTeam.id] or nil
    end
    return nil
end

function CTFGame:getFlagByTeamID(teamID)
    return self.flags[teamID] or nil
end

function CTFGame:captureFlag(flagToCapture, ourFlag, playerId)
    local playerTeam = self:getPlayerTeam(playerId)
    playerTeam:updateScore(1)
    SendClientHudNotification(
        -1, 
        string.format(
            "The %s team's flag has been captured.~n~Scores are %d-%d",
            flagToCapture.team:getName(),
            flagToCapture.team.score, 
            ourFlag.team.score
        )
    )
    PlaySoundForEveryone("BASE_JUMP_PASSED", "HUD_AWARDS")
    flagToCapture:sendBackToBase()
    TriggerEvent("sendTeamDataToClient", -1)
    self:checkForWin()
end

function CTFGame:attemptToTakeFlag(flagToCapture, playerPed, playerId)
    flagToCapture:setStatus(EFlagStatuses.TAKEN)
    TriggerClientEvent("SetObjectiveVisible", NetworkGetEntityOwner(flagToCapture.entity), flagToCapture:getFlagNetworkedID(), false)
    flagToCapture.entity.state.carrierId = playerId
    flagToCapture:setNextCooldown(2000)
    PlaySoundForEveryone("CHALLENGE_UNLOCKED", "HUD_AWARDS")
    SendClientHudNotification(
        -1,
        string.format(
            screenCaptions.TeamFlagAction,
            flagToCapture.team:getName(),
            "taken"
        )
    )
end

function CTFGame:returnFlag(ourFlag)
    ourFlag:sendBackToBase()
    TriggerEvent("sendTeamDataToClient", -1)
    SendClientHudNotification(
        -1,
        string.format(
            screenCaptions.TeamFlagAction,
            ourFlag.team:getName(),
            "returned"
        )
    )
end

function CTFGame:checkForWin()
    for _, team in ipairs(self.teams) do
        if team.score >= WINNING_SCORE then
            self:endGame(team)
            break
        end
    end
end

function CTFGame:endGame(winningTeam)
    SendClientHudNotification(-1, string.format("The %s team has won the game!", winningTeam:getName()))
    PlaySoundForEveryone("MP_WAVE_COMPLETE", "HUD_FRONTEND_DEFAULT_SOUNDSET")
    self:shutDown()
    Citizen.SetTimeout(1000, function()
        ctfGame = CTFGame.new()
        ctfGame:respawnAllPlayers()
        ctfGame:start()
    end)
end

function CTFGame:respawnAllPlayers()
    for _, player in ipairs(GetPlayers()) do
        local playerTeam = self:getPlayerTeam(player)
        local spawnPosition = playerTeam.basePosition
        local playerPed = GetPlayerPed(player)
        SetEntityCoords(playerPed, spawnPosition.x, spawnPosition.y, spawnPosition.z, false, false, false, true)
        SetEntityHeading(playerPed, playerTeam.playerHeading)
    end
end

function CTFGame:update()
    for _, flagInstance in ipairs(ctfGame.flags) do
        if Flag:carrierDied() then
            flagInstance:setAsDropped()
            SendClientHudNotification(
                -1,
                string.format(
                    screenCaptions.TeamFlagAction,
                    flagInstance.team:getName(),
                    "dropped"
                )
            )
        elseif Flag:isDropped() then 
            if flagInstance:isPastAutoReturnTime() then
                self:returnFlag(flagInstance)
            end
        end
    end
end

function SendClientHudNotification(source, message)
    TriggerClientEvent("SendClientHudNotification", source, message)
    TriggerEvent("sendTeamDataToClient", source)
end

function CTFGame:shutDown()
    for _, flag in ipairs(self.flags) do
        flag:destroy()
    end
    for _, team in ipairs(self.teams) do
        team:destroy()
    end
end

ctfGame = CTFGame.new()
ctfGame:start()

function PlaySoundForEveryone(soundName, soundSetName)
    TriggerClientEvent("PlaySoundFrontEnd", -1, soundName, soundSetName)
end

RegisterServerEvent('requestFlagUpdate')
AddEventHandler('requestFlagUpdate', function()
    print("requestFlagUpdate from: " .. source .. "\n")
    local playerPed = GetPlayerPed(source)
    local playerTeam = ctfGame:getPlayerTeam(source)
    if playerTeam.id ~= TeamType.TEAM_SPECTATOR then
        if GetEntityHealth(playerPed) < 1 then return end
        local ourFlag = ctfGame:getFlag(source, false)
        local flagToCapture = ctfGame:getFlag(source, true)
        if flagToCapture:isPastCooldown() and ourFlag:isPastCooldown() then
            if (flagToCapture:isDropped() or flagToCapture:isAtBase()) and flagToCapture:hasEntityInRadius(playerPed) then
                ctfGame:attemptToTakeFlag(flagToCapture, playerPed, source)
            elseif flagToCapture:isFlagCarrier(source) and ourFlag:isAtBase() then
                if playerTeam:goalBaseHasEntityInRadius(playerPed) then
                    ctfGame:captureFlag(flagToCapture, ourFlag, source)
                end
            elseif ourFlag:hasEntityInRadius(playerPed) and ourFlag:isDropped() then
                ctfGame:returnFlag(ourFlag)
            end
        end
    end
end)

RegisterServerEvent('playerJoining')
AddEventHandler('playerJoining', function(source, oldID)
    Player(source).state.teamID = TeamType.TEAM_RED
    TriggerEvent("sendTeamDataToClient", source)
end)

RegisterServerEvent('requestTeamData')
AddEventHandler('requestTeamData', function()
    TriggerEvent("sendTeamDataToClient", source)
end)

RegisterServerEvent("sendTeamDataToClient")
AddEventHandler("sendTeamDataToClient", function(source)
    local teamsDataArray = {}
    for _, team in ipairs(ctfGame.teams) do
        if team.id ~= TeamType.TEAM_SPECTATOR then
            print("flag status is " .. ctfGame:getFlagByTeamID(team.id):getFlagStatus())
            local teamData = {
                id = team.id,
                name = team:getName(),
                basePosition = team.basePosition,
                flagColor = team.flagColor,
                flagNetworkedID = ctfGame:getFlagByTeamID(team.id):getFlagNetworkedID(),
                flagStatus = ctfGame:getFlagByTeamID(team.id):getFlagStatus(),
                playerModel = team.playerModel,
                playerHeading = team.playerHeading,
                baseNetworkId = team.networkedID,
                score = team.score
            }
            teamsDataArray[#teamsDataArray+1] = teamData
        end
    end
    TriggerClientEvent("receiveTeamData", source, teamsDataArray)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    ctfGame:shutDown()
    print('The resource ' .. resourceName .. ' was stopped.')
end)

AddEventHandler('playerDropped', function (reason)
    local flagToCapture = ctfGame:getFlag(source, true)
    if flagToCapture:isFlagCarrier(source) then
        flagToCapture:setAsDropped()
    end
end)

Citizen.CreateThread(function()
    while true do
        ctfGame:update()
        Citizen.Wait(500)
    end
end)