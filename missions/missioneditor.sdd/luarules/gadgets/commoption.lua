--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    game_spawn.lua
--  brief:   spawns start unit and sets storage levels
--           (special version for XTA)
--  author:  Tobi Vollebregt
--
--  Copyright (C) 2010.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
    return {
        name      = "Spawn",
        desc      = "spawns start unit and sets storage levels",
        author    = "Tobi Vollebregt/TheFatController",
        date      = "January, 2010",
        license   = "GNU GPL, v2 or later",
        layer     = 0,
        enabled   = true  --  loaded by default?
    }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- synced only
if (gadgetHandler:IsSyncedCode()) then

local function SpawnStartUnit(teamID)
	-- spawn the specified start unit
	local x,y,z = Spring.GetTeamStartPosition(teamID)
	-- snap to 16x16 grid
	x, z = 16*math.floor((x+8)/16), 16*math.floor((z+8)/16)
	y = Spring.GetGroundHeight(x, z)
	-- facing toward map center
	local facing=math.abs(Game.mapSizeX/2 - x) > math.abs(Game.mapSizeZ/2 - z)
		and ((x>Game.mapSizeX/2) and "west" or "east")
		or ((z>Game.mapSizeZ/2) and "north" or "south")
	local commanderID = Spring.CreateUnit("zzz_mission_wizzard", x, y, z, facing, teamID)
	Spring.GiveOrderToUnit(commanderID, CMD.MOVE_STATE, { 0 }, {})
end

function gadget:GameStart()
	local excludeTeams = {}

    -- spawn start units
    local gaiaTeamID = Spring.GetGaiaTeamID()
    local teams = Spring.GetTeamList()
	for i = 1,#teams do
        local teamID = teams[i]
        -- don't spawn a start unit for the Gaia team
        if (teamID ~= gaiaTeamID) and (not excludeTeams[teamID]) then
            SpawnStartUnit(teamID)
        end
    end
end

function gadget:Initialize()
	local gaiaTeamID = Spring.GetGaiaTeamID()
	local teams = Spring.GetTeamList()
	for i = 1,#teams do
		local teamID = teams[i]
		if (teamID ~= gaiaTeamID) then
			Spring.SetTeamResource(teamID, "ms", 0)
			Spring.SetTeamResource(teamID, "es", 0)
		end
	end
end

end