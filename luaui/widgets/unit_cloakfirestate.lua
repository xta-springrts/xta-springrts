--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Cloak Fire State",
    desc      = "Sets units to Hold Fire when cloaked, reverts to original state when decloaked",
    author    = "KingRaptor (L.J. Lim)",
    date      = "Feb 14, 2010",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local team = Spring.GetMyTeamID()

local commanderList = {} -- populate in initialize instead
	
-- Speedups
local GiveOrderToUnit  = Spring.GiveOrderToUnit
local GetUnitStates    = Spring.GetUnitStates
local GetUnitDefID     = Spring.GetUnitDefID
local GetGameFrame     = Spring.GetGameFrame
local GetMyTeamID      = Spring.GetMyTeamID
local GetSelectedUnits = Spring.GetSelectedUnits
local GetUnitIsCloaked = Spring.GetUnitIsCloaked
local GetPlayerInfo    = Spring.GetPlayerInfo
local Echo				= Spring.Echo
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local cloakUnit = {}	--stores the desired fire state when decloaked of each unitID

function widget:UnitCloaked(unitID, unitDefID, teamID)
	if (teamID ~= team) or not UnitDefs[unitDefID].canMove or (not UnitDefs[unitDefID].decloakOnFire) then return end
	local states = GetUnitStates(unitID)
	cloakUnit[unitID] = states.firestate	--store last state
	if states.firestate ~= 0 then
		GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {})
	end
end

function widget:UnitDecloaked(unitID, unitDefID, teamID)
	if (teamID ~= team) or not UnitDefs[unitDefID].canMove or (not UnitDefs[unitDefID].decloakOnFire) then return end
	local states = GetUnitStates(unitID)
	if states.firestate == 0 then
		local targetState = cloakUnit[unitID] or 2
		GiveOrderToUnit(unitID, CMD.FIRE_STATE, {targetState}, {})	--revert to last state
	end
end

function widget:CommandNotify(commandID, params, options)
  if (commandID == CMD.CLOAK) then
    local selUnits = GetSelectedUnits()
    for i,unitID in pairs(selUnits) do
      local unitDef = GetUnitDefID(unitID)
      if (unitDef ~= nil) and commanderList[unitDef] then
        local states = GetUnitStates(unitID)
        if (not states) then
          return
        end
        if states.cloak then
          GiveOrderToUnit(unitID, CMD.FIRE_STATE, {2}, {})
        else
          GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {}) 
        end
      end
    end
  end   
end

local function CheckSpecState()
  if Spring.GetSpectatingState() then
	Spring.Log("widget", LOG.INFO, "<Cloak Fire State> Spectator mode. Widget removed.")
	widgetHandler:RemoveWidget()
	return
  end
end

function widget:GameFrame(n)
	if (n%16 < 1) then
		CheckSpecState()
	end
end

function widget:Initialize()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget()
		return
	end

	for i=1, #UnitDefs do
		local cp = UnitDefs[i].customParams
		if cp and cp.iscommander then
			commanderList[i] = true
		end
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  if (unitTeam == team) then
	local states = GetUnitStates(unitID)
	cloakUnit[unitID] = states.firestate
  elseif (cloakUnit[unitID]) then
    cloakUnit[unitID] = nil
  end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
  widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
		
    cloakUnit[unitID] = nil
end