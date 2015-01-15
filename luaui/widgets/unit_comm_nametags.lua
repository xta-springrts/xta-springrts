local versionNumber = "1.4"

function widget:GetInfo()
  return {
    name      = "Commander Name Tags" .. versionNumber,
    desc      = "Displays a name tag above each commander.",
    author    = "Evil4Zerggin, Jools, DeadnightWarrior",
    date      = "6 Jan 2012",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true  --  loaded by default?
  }
end

-- Changelog: 1.4: Add Lost and Guardian commanders and show for decoys if decoy start
-- Changelog: 1.3: Greatly improved performance.
-- Changelog: 1.2: Modified commander detection due to change in spring 85.0. Decoys also get the tag to avoid detection.

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
local heightOffset = 24
local fontSize = 6
--------------------------------------------------------------------------------
-- speed-ups
--------------------------------------------------------------------------------

local GetUnitTeam         = Spring.GetUnitTeam
local GetTeamInfo         = Spring.GetTeamInfo
local GetPlayerInfo       = Spring.GetPlayerInfo
local GetTeamColor        = Spring.GetTeamColor
local GetUnitViewPosition = Spring.GetUnitViewPosition
local GetVisibleUnits     = Spring.GetVisibleUnits
local IsUnitVisible	      = Spring.IsUnitVisible
local GetUnitDefID        = Spring.GetUnitDefID
local glColor             = gl.Color
local glText              = gl.Text
local glPushMatrix        = gl.PushMatrix
local glTranslate         = gl.Translate
local glBillboard         = gl.Billboard
local glPopMatrix         = gl.PopMatrix
local GetGaiaTeamID		  = Spring.GetGaiaTeamID
local haveZombies 		  = (tonumber((Spring.GetModOptions() or {}).zombies) or 0) == 1
local isDecoyStart		  = false

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
teams = {}
commanderIDs = {}
commanders = {}
--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function widget:Initialize()
	for no, teamID in pairs(Spring.GetTeamList()) do
		teams[teamID] = {}
		local r, g, b, a = GetTeamColor(teamID)
		teams[teamID].colour = {r, g, b, a}
		local player,isAI,side,name
		local isGaia = teamID == GetGaiaTeamID()
		_,player,_,isAI,side,_,_,_ = GetTeamInfo(teamID)
		
		if modOptions and modOptions.commander == "decoystart" then
			isDecoyStart = true
		end
		
		if isAI then
			if side == "arm" then name = "Arm"
				elseif side == "core" then name = "Core"
				elseif side == "lost" then name = "Lost"
				elseif side == "guardian" then name = "Guardian"
				else name = side
			end
		elseif isGaia then
			if haveZombies then
				name = "Zombie"
			else
				name = "Gaia"
			end
		else
			name = GetPlayerInfo(player)
		end
		teams[teamID].name = name
	end
	for i=1, #UnitDefs do
		local cp = UnitDefs[i].customParams
		if cp and cp.iscommander and (not cp.isdecoycommander or isDecoyStart) then
			commanderIDs[i] = true
		end
	end
	local visibleUnits = GetVisibleUnits(ALL_UNITS,16,false)
	for i=1, #visibleUnits do
		local unitID    = visibleUnits[i]
		local unitDefID = GetUnitDefID(unitID)
		if commanderIDs[unitDefID] then
			commanders[unitID] = unitDefID
		end
	end
end

function widget:UnitCreated(unitID,  unitDefID,  unitTeam)
	if not commanders[unitID] then
		if commanderIDs[unitDefID] then
			commanders[unitID] = unitDefID
		end
	end
end

function widget:UnitEnteredLos(unitID, allyTeam)
	if not commanders[unitID] then
		local unitDefID = GetUnitDefID(unitID)
		if commanderIDs[unitDefID] then
			commanders[unitID] = unitDefID
		end
	end
end

function widget:DrawWorld()
	for unitID, unitDefID in pairs(commanders) do
		if GetUnitDefID(unitID) == unitDefID then
			if IsUnitVisible(unitID, 16, false) then --skip if zoomed out or not on screen
				local ux, uy, uz = GetUnitViewPosition(unitID)
				local teamData = teams[GetUnitTeam(unitID)]
				glPushMatrix()
				glTranslate(ux, uy + UnitDefs[unitDefID].height + heightOffset, uz )
				glBillboard()
				glColor(teamData.colour)
				glText(teamData.name, 0, 0, fontSize, "cn")
				glPopMatrix()
			end
		else -- unitID no longer contains a commander
			commanders[unitID] = nil
		end
	end
end
