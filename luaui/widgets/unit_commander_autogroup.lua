
function widget:GetInfo()
  return {
    name      = "Commander autogroup",
    desc      = "Sets Commander as member of group 1 at game start",
    author    = "Jools",
    date      = "Apr, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

local GetLocalTeamID 		= 	Spring.GetLocalTeamID
local GetTeamUnits 			= 	Spring.GetTeamUnits
local GetUnitDefID 			= 	Spring.GetUnitDefID
local SetUnitGroup 			= 	Spring.SetUnitGroup


function widget:GameStart()
	local teamID = GetLocalTeamID()
	local units = GetTeamUnits(teamID)
	local commanderID = units[1] or nil
	
	if commanderID then
		local cdID = GetUnitDefID(commanderID)
		if cdID and UnitDefs[cdID] then	
			local cp = UnitDefs[cdID].customParams
			if cp and cp.iscommander then
				SetUnitGroup(commanderID, 1)
			end
		end
	end
	widgetHandler.RemoveWidget()
end