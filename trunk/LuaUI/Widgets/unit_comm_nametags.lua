local versionNumber = "1.2"

function widget:GetInfo()
  return {
    name      = "Commander Name Tags" .. versionNumber,
    desc      = "Displays a name tag above each commander.",
    author    = "Evil4Zerggin, Jools",
    date      = "6 Jan 2012",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true  --  loaded by default?
  }
end

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
local GetUnitDefID        = Spring.GetUnitDefID
local glColor             = gl.Color
local glText              = gl.Text
local glPushMatrix        = gl.PushMatrix
local glTranslate         = gl.Translate
local glBillboard         = gl.Billboard
local glPopMatrix         = gl.PopMatrix

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

local function GetUnitPlayerName(unitID)
  local team = GetUnitTeam(unitID)
  local player,isAI,side,name
  _,player,_,isAI,side,_,_,_ = GetTeamInfo(team)
  if isAI then
	if side == "arm" then name = "Arm"
		elseif side == "core" then name = "Core"
		else name = side
	end
  else
	name = GetPlayerInfo(player)
  end
  local r, g, b, a = GetTeamColor(team)
  if name == nil or #name < 1 then name = ("Team " .. team) end
  return name, {r, g, b, a,}
end

local function DrawUnitPlayerName(unitID, height)
  local ux, uy, uz = GetUnitViewPosition(unitID)
  local name, color = GetUnitPlayerName(unitID)
  glPushMatrix()
  glTranslate(ux, uy + height, uz )
  glBillboard()
  
  glColor(color)
  glText(name, 0, 0, fontSize, "cn")
  
  glPopMatrix()
end

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function widget:DrawWorld()
  local visibleUnits = GetVisibleUnits(ALL_UNITS,nil,true)
  for i=1,#visibleUnits do
    local unitID    = visibleUnits[i]
    local unitDefID = GetUnitDefID(unitID)
    local unitDef   = UnitDefs[unitDefID or -1]
	local cp 		= unitDef.customParams or nil
    local height    = unitDef.height+heightOffset
	 
	if unitDef and cp and cp.iscommander then
      DrawUnitPlayerName(unitID, height)
    end
  end
end
