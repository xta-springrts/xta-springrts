
function widget:GetInfo()
	return {
		name      = "DGun Stall Assist",
		desc      = "Waits cons/facs when trying to dgun and stalling",
		author    = "Niobium",
		date      = "2 April 2010",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

-- Updates. 2014.09: Also stop mohos and metal makers, and don't stop builders that are not consuming energy
----------------------------------------------------------------
-- Config
----------------------------------------------------------------
local targetEnergy = 600
local watchForTime = 5
local hoverSetting = 100
local alterLevelFormat = string.char(137) .. '%i'
----------------------------------------------------------------
-- Globals
----------------------------------------------------------------
local watchTime = 0
local waitedUnits = nil -- nil / waitedUnits[1..n] = uID
local shouldWait = {} -- shouldWait[uDefID] = true / nil
local isFactory = {} -- isFactory[uDefID] = true / nil
local stoppedMohos = nil
local stoppedMMakers = nil

----------------------------------------------------------------
-- Speedups
----------------------------------------------------------------
local spGetActiveCommand = Spring.GetActiveCommand
local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray
local spGetUnitCommands = Spring.GetUnitCommands
local spGetFactoryCommands = Spring.GetFactoryCommands
local spGetMyTeamID = Spring.GetMyTeamID
local spGetTeamResources = Spring.GetTeamResources
local spGetTeamUnits = Spring.GetTeamUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGetSpectatingState = Spring.GetSpectatingState
local Echo	= Spring.Echo

local CMD_DGUN = CMD.MANUALFIRE
local CMD_WAIT = CMD.WAIT

----------------------------------------------------------------
-- Callins
----------------------------------------------------------------

local mohos	= {
[UnitDefNames["arm_moho_mine"].id] 					= true,
[UnitDefNames["arm_underwater_moho_mine"].id] 		= true,
[UnitDefNames["core_moho_mine"].id] 				= true,
[UnitDefNames["core_underwater_moho_mine"].id] 		= true,
[UnitDefNames["lost_moho_mine"].id] 				= true,
[UnitDefNames["lost_underwater_moho_mine"].id] 		= true,
[UnitDefNames["talon_moho_mine"].id] 				= true,
}

local mmakers = {
[UnitDefNames["arm_moho_metal_maker"].id] 			= true,
[UnitDefNames["arm_metal_maker"].id] 				= true,
[UnitDefNames["arm_floating_metal_maker"].id]		= true,
[UnitDefNames["core_moho_metal_maker"].id] 			= true,
[UnitDefNames["core_metal_maker"].id] 				= true,
[UnitDefNames["core_floating_metal_maker"].id]		= true,
[UnitDefNames["lost_moho_metal_maker"].id] 			= true,
[UnitDefNames["lost_metal_maker"].id] 				= true,
[UnitDefNames["lost_floating_metal_maker"].id]		= true,
[UnitDefNames["talon_moho_metal_maker"].id] 			= true,
[UnitDefNames["talon_metal_maker"].id] 				= true,
[UnitDefNames["talon_underwater_metal_maker"].id]		= true,
}

local function IsUnitComplete(unitID)
	if unitID then
		local _,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)
		if buildProgress and buildProgress>=1 then
			return true
		else
			return false
		end
	else 
		return false
	end
end
	
function widget:Initialize()
	
	if spGetSpectatingState() then
		widgetHandler:RemoveWidget()
		return
	end
	
	for uDefID, uDef in pairs(UnitDefs) do
		if (uDef.buildSpeed > 0) and uDef.canAssist and (not uDef.canManualFire) then
			shouldWait[uDefID] = true
			if uDef.isFactory then
				isFactory[uDefID] = true
			end
		end
	end
end

function widget:Update(dt)
	
	local _, activeCmdID = spGetActiveCommand()
	if activeCmdID == CMD_DGUN then
		watchTime = watchForTime
	else
		watchTime = watchTime - dt
		
		if waitedUnits and (watchTime < 0) then
			
			local toUnwait = {}
			for i = 1, #waitedUnits do
				local uID = waitedUnits[i]
				local uDefID = spGetUnitDefID(uID)
				local uCmds = isFactory[uDefID] and spGetFactoryCommands(uID, 1) or spGetUnitCommands(uID, 1)
				if uCmds and (#uCmds > 0) and (uCmds[1].id == CMD_WAIT) then
					toUnwait[#toUnwait + 1] = uID
				end
			end
			spGiveOrderToUnitArray(toUnwait, CMD_WAIT, {}, {})
			Spring.SendLuaRulesMsg(string.format(alterLevelFormat,100*hoverSetting))
			waitedUnits = nil
			
		end
		
		if stoppedMohos and (watchTime < 0) then
			spGiveOrderToUnitArray(stoppedMohos, CMD.ONOFF, { 1 }, {})
			stoppedMohos = nil
		end
		
		if stoppedMMakers and (watchTime < 0) then
			spGiveOrderToUnitArray(stoppedMMakers, CMD.ONOFF, { 1 }, {})
			stoppedMMakers = nil
		end
		
	end
	
	if (watchTime > 0) and (not waitedUnits) then
		
		if spGetSpectatingState() then
			widgetHandler:RemoveWidget()
			return
		end
		
		local myTeamID = spGetMyTeamID()
		local currentEnergy, energyStorage = spGetTeamResources(myTeamID, "energy")
		if (currentEnergy < targetEnergy) and (energyStorage >= targetEnergy) then
			
			waitedUnits = {}
			local myUnits = spGetTeamUnits(myTeamID)
			for i = 1, #myUnits do
				local uID = myUnits[i]
				local uDefID = spGetUnitDefID(uID)
				
				if shouldWait[uDefID] then
					local uCmds = isFactory[uDefID] and spGetFactoryCommands(uID, 1) or spGetUnitCommands(uID, 1)
					local buildPower = Spring.GetUnitCurrentBuildPower(uID)
					local projectID = Spring.GetUnitIsBuilding(uID)
					local projectCost = projectID and UnitDefs[Spring.GetUnitDefID(projectID)].energyCost or 0
				
					if ((#uCmds == 0) or (uCmds[1].id ~= CMD_WAIT)) and buildPower and buildPower > 0 and projectCost > 0 and not(IsUnitComplete(projectID)) then
						waitedUnits[#waitedUnits + 1] = uID
					end
				elseif mohos[uDefID] then
					if not stoppedMohos then stoppedMohos = {} end
										
					local state = Spring.GetUnitStates(uID)
					if state and state.active then
						stoppedMohos[#stoppedMohos+1] = uID
					end
					
				elseif mmakers[uDefID] then
					if not stoppedMMakers then stoppedMMakers = {} end
					
					local state = Spring.GetUnitStates(uID)
					if state and state.active then
						stoppedMMakers[#stoppedMMakers+1] = uID
					end
					
				end
				
				spGiveOrderToUnitArray(stoppedMohos or {}, CMD.ONOFF, { 0 }, {} )
				spGiveOrderToUnitArray(stoppedMMakers or {}, CMD.ONOFF, { 0 }, {} )
				spGiveOrderToUnitArray(waitedUnits, CMD_WAIT, {}, {})
				hoverSetting = Spring.GetTeamRulesParam(myTeamID, 'mmLevel') or 0
				Spring.SendLuaRulesMsg(string.format(alterLevelFormat, 100))
			end
		end
	end
end
