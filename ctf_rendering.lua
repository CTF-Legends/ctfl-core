-- How can you see this?
-- Are you a developer? If so, you can see this file.
-- Are you a player? If so, you can't see this file.
-- Are you a Crackhead? If so, you can't see this file.

-- If you start this resource, you are dead.
-- If you stop this resource, you are dead.
-- If you restart this resource, you are dead.

local UIConfig = ctfConfig.UI

local UITeamTxtProps = UIConfig.teamTxtProperties

local btnCaptions = UIConfig.btnCaptions

screenCaptions = UIConfig.screenCaptions

local buttonsHandle = nil

AddEventHandler('onClientResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    AddTextEntry("textRenderingEntry", "~a~")
    RequestStreamedTextureDict("commonmenutu", false)
    buttonsHandle = RequestScaleformMovie('INSTRUCTIONAL_BUTTONS')
end)

RegisterNetEvent("SendClientHudNotification")
AddEventHandler("SendClientHudNotification", function(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(true, true)
end)

function ctfRenderingRenderThisFrame()
    drawScaleFormUI(buttonsHandle)

    local teams = nil

    if not teams then
        teams = getReceivedServerTeams()
    end

    if teams and #teams > 0 then
        if HasStreamedTextureDictLoaded("commonmenutu") then
            renderFlagScores(teams)
        end

        if isInTeamSelection() then
            DisableRadarThisFrame()
            HideHudAndRadarThisFrame()
            DrawScaleformMovieFullscreen(buttonsHandle, 255, 255, 255, 255, 1)
            
            if LocalPlayer.state.teamID and LocalPlayer.state.teamID <= #teams then
                drawTxt(
                    UITeamTxtProps.x,
                    UITeamTxtProps.y,
                    UITeamTxtProps.width,
                    UITeamTxtProps.height,
                    UITeamTxtProps.scale,
                    formatTeamName(teams, LocalPlayer.state.teamID),
                    UITeamTxtProps.color.r,
                    UITeamTxtProps.color.g,
                    UITeamTxtProps.color.b,
                    UITeamTxtProps.color.a
                )
            end
        end
    end
end

function renderFlagScore(flagData, screenPos, colorRgba)
    local statusID = flagData.flagStatus

    DrawSprite(
        "commonmenutu",
        "race",
        screenPos.x,
        screenPos.y,
        0.06,
        0.1,
        0.0,
        table.unpack(colorRgba)
    )

    drawTxt(screenPos.x, screenPos.y, -0.08, 0.08, 1.0, tostring(flagData.score), table.unpack(colorRgba))
    drawTxt(screenPos.x, screenPos.y, 0.03, -0.04, 0.5, getDescriptionForFlagStatus(statusID), table.unpack(colorRgba))
end

function renderFlagScores(teams)
    if teams ~= nil then
        renderFlagScore(teams[TeamType.TEAM_RED], {x = 0.025, y = 0.5}, {255, 0, 0, 180})
        renderFlagScore(teams[TeamType.TEAM_BLUE], {x = 0.025, y = 0.6}, {0, 0, 255, 180})
    end
end

function buttonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function drawScaleFormUI(buttonsHandle)
    while not HasScaleformMovieLoaded(buttonsHandle) do
        Wait(0)
    end

    CallScaleformMovieMethod(buttonsHandle, 'CLEAR_ALL')

    PushScaleformMovieFunction(buttonsHandle, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(2)
    ScaleformMovieMethodAddParamPlayerNameString("~INPUT_SPRINT~")
    buttonMessage(btnCaptions.Spawn)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(buttonsHandle, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(1)
    ScaleformMovieMethodAddParamPlayerNameString("~INPUT_ATTACK~")
    buttonMessage(btnCaptions.PreviousTeam)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(buttonsHandle, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(0)
    ScaleformMovieMethodAddParamPlayerNameString("~INPUT_AIM~")
    buttonMessage(btnCaptions.NextTeam)
    PopScaleformMovieFunctionVoid()
    
    CallScaleformMovieMethod(buttonsHandle, 'DRAW_INSTRUCTIONAL_BUTTONS')
end

function drawTxt(x,y,width,height,scale, text, r,g,b,a)
    SetTextFont(2)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("textRenderingEntry")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end

function Draw3DText(x, y, z, scl_factor, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov * scl_factor
    if onScreen then
        SetTextScale(0.0, scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("textRenderingEntry")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end
