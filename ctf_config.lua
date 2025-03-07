ctfConfig = {}

ctfConfig.teams = {
    {
        id = TeamType.TEAM_RED,
        flagColor = {255, 0, 0},
        basePosition = vector3(2555.1860, -333.1058, 92.9928),
        playerModel = 'a_m_y_beachvesp_01',
        playerHeading = 90.0
    },
    {
        id = TeamType.TEAM_BLUE,
        flagColor = {0, 0, 255},
        basePosition = vector3(2574.9807, -342.9044, 92.9928),
        playerModel = 's_m_m_armoured_02',
        playerHeading = 90.0
    },
    {
        id = TeamType.TEAM_SPECTATOR,
        flagColor = {255, 255, 255},
        basePosition = vector3(2574.9807, -342.9044, 92.9928),
        playerModel = 's_m_m_armoured_02',
        playerHeading = 90.0
    },
}

ctfConfig.flags = {
    {
        teamID = TeamType.TEAM_RED,
        model = "w_am_case",
        position = vector3(2555.1860, -333.1058, 92.9928)
    },
    {
        teamID = TeamType.TEAM_BLUE,
        model = "w_am_case",
        position = vector3(2574.9807, -342.9044, 92.9928)
    }
}

ctfConfig.UI = {
    btnCaptions = {
        Spawn = "Spawn",
        NextTeam = "Next Team",
        PreviousTeam = "Previous Team"
    },
    teamTxtProperties = {
        x = 1.0,
        y = 0.9,
        width = 0.4,
        height = 0.070,
        scale = 1.0,
        text = "",
        color = {
            r = 255,
            g = 255,
            b = 255,
            a = 255
        }
    },
    screenCaptions = {
        DefendAndGrabThePackage = "Defend and grab the ~y~package~w~.",
        TeamFlagAction = "The %s team's flag has been %s."
    }
}
