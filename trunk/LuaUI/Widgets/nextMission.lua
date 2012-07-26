
function widget:GetInfo()
	return {
		name      = 'Next Mission Loader',
		desc      = 'Restart Spring to next mission after victory',
		author    = 'Deadnight Warrior',
		date      = '26 Jul 2012',
		license   = 'GNU LGPL v2',
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local noFile = true
local file
local modOptions = Spring.GetModOptions()
local gameData = {}

function widget:Initialize()
	if modOptions and modOptions.mission then
		local mission = "Missions/" .. modOptions.mission ..".lua"
		if VFS.FileExists(mission) then
			gameData = VFS.Include(mission)
			if gameData.game == Game.modShortName and gameData.minVersion <= Game.modVersion then
				if gameData.map ~= Game.mapName then
					widgetHandler:RemoveWidget()
				end
			else
				widgetHandler:RemoveWidget()				
			end
		else
			widgetHandler:RemoveWidget()
		end
	else
		widgetHandler:RemoveWidget()
	end
end

function widget:GameOver()
	local amIDead = select(3, Spring.GetTeamInfo(Spring.GetMyTeamID()))
	if amIDead==false and gameData.nextMission then
		local nextMission = "Missions/" .. gameData.nextMission ..".txt"
		if VFS.FileExists(nextMission) then
			local startScript = VFS.LoadFile(nextMission)
			Spring.Restart("-s", startScript)
		end
	end
end