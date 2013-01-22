function gadget:GetInfo()
	return {
		name      = "Cursor too far",
		desc      = "Implements cursor out of range mode on attack command",
		author    = "Jools",
		date      = "Jan 2013",
		version   = "1.0",
		license   = "GNU GPL v2",
		layer     = 1,
		enabled   = true  --  loaded by default?
  }
end

-- function localisations
-- Synced Read
local GetUnitDefID			= Spring.GetUnitDefID
local GetUnitPosition		= Spring.GetUnitPosition
local GetUnitsInCylinder	= Spring.GetUnitsInCylinder
local ValidUnitID			= Spring.ValidUnitID
-- Synced Ctrl
local CallCOBScript			= Spring.CallCOBScript
local DestroyUnit			= Spring.DestroyUnit
local RemoveBuildingDecal	= Spring.RemoveBuildingDecal
local SetUnitMoveGoal		= Spring.SetUnitMoveGoal
local SpawnCEG				= Spring.SpawnCEG
local AssignMouseCursor 	= Spring.AssignMouseCursor
-- Constants
local CMD_ATTACKBAD = 35522

if gadgetHandler:IsSyncedCode() then
--	SYNCED

--	CallIns

	function gadget:Initialize()
		gadgetHandler:RegisterCMDID(CMD_ATTACKBAD)
		AssignMouseCursor("AttackBad", "cursorattackbad", true, false)
	end

else
--	UNSYNCED
	
	-- function localisations
	local Spring_GetMouseState = Spring.GetMouseState
	local Spring_GetActiveCommand = Spring.GetActiveCommand
	local Spring_GetSelectedUnits = Spring.GetSelectedUnits
	local Spring_TraceScreenRay = Spring.TraceScreenRay
	local Spring_GetUnitDefID = Spring.GetUnitDefID
	local Spring_GetUnitWeaponState = Spring.GetUnitWeaponState
	local Spring_GetUnitPosition  = Spring.GetUnitPosition 
	local Spring_SetMouseCursor = Spring.SetMouseCursor
	local CMD_ATTACK = CMD.ATTACK
	function gadget:Update()
		
		local _, activeCmdID = Spring_GetActiveCommand()
		
		if activeCmdID == CMD_ATTACK then
			local mx,my=Spring_GetMouseState()
			local sU = Spring_GetSelectedUnits()
			local s,t =Spring_TraceScreenRay(mx,my)
			if s == "ground" then
				local x,z
				x = t[1]
				--y = t[2]
				z = t[3]
				
				if sU then
					local inRange = false
					for _,unit in ipairs(sU) do
						local unitDef = Spring_GetUnitDefID(unit)
						local isTurret = UnitDefs[unitDef].isBuilding and #UnitDefs[unitDef].weapons > 0
						if isTurret then
							local range = Spring_GetUnitWeaponState(unit,0,"range")
							if range and range > 0 then
								local ux, uy, uz = Spring_GetUnitPosition(unit)
								local dist = ((x-ux)^2+(z-uz)^2)^0.5
								if dist < range then inRange = true end
							else
								--inRange = true
							end
						else -- moving unit
							if #UnitDefs[unitDef].weapons > 0 then
								inRange = true
							end
						end
					end
					if inRange then
						Spring_SetMouseCursor("Attack")
					else
						Spring_SetMouseCursor("AttackBad")
					end
				end
			end
		end
	end
end