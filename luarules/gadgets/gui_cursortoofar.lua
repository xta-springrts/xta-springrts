function gadget:GetInfo()
	return {
		name      = "Cursor too far",
		desc      = "Implements cursor out of range mode on attack command",
		author    = "Jools, Deadnight Warrior",
		date      = "Jan 2013",
		version   = "1.0",
		license   = "GNU GPL v2",
		layer     = 1,
		enabled   = true  --  loaded by default?
  }
end

-- function localisations
local spGetUnitWeaponState 	= Spring.GetUnitWeaponState
local spGetUnitPosition  	= Spring.GetUnitPosition 
local CMD_ATTACK 			= CMD.ATTACK
local Echo 					= Spring.Echo
local errorCount 			= 0

-- Constants
local CMD_ATTACKBAD = 35577

if gadgetHandler:IsSyncedCode() then	--	SYNCED

local spAssignMouseCursor 	= Spring.AssignMouseCursor

--	CallIns
	function gadget:Initialize()
		gadgetHandler:RegisterCMDID(CMD_ATTACKBAD)
		spAssignMouseCursor("AttackBad", "cursorattackbad", true, false)
	end	

	function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
		if cmdID == CMD_ATTACK and UnitDefs[unitDefID].isBuilding and #UnitDefs[unitDefID].weapons > 0 then
			local range = spGetUnitWeaponState(unitID,0,"range")		
			if cmdParams and cmdParams[3] ~= nil and range ~= nil then
				local ux, _, uz = spGetUnitPosition(unitID)
				local x, z = cmdParams[1], cmdParams[3]
				local dx, dz = x-ux, z-uz
				local dist = dx*dx + dz*dz
				if dist > range*range then 
					--Spring.SetActiveCommand ("Attack") -- causes confusion in UI when multiple units are selected are some can attack
					return false	
				end
			end
		end
		return true
	end


else	--	UNSYNCED

--if Game.version > "91.0" then return end	-- not needed in Spring > 91.0

local spGetUnitDefID 		= Spring.GetUnitDefID
local spSetMouseCursor 		= Spring.SetMouseCursor
local spGetActiveCommand 	= Spring.GetActiveCommand
local spGetSelectedUnits 	= Spring.GetSelectedUnits
local spTraceScreenRay 		= Spring.TraceScreenRay
local spGetMouseState 		= Spring.GetMouseState

	function gadget:Update()
		local _, activeCmdID = spGetActiveCommand()
		if activeCmdID == CMD_ATTACK then
			local mx, my = spGetMouseState()
			local sU = spGetSelectedUnits()
			local s, t = spTraceScreenRay(mx,my)
			if s == "ground" and sU then	-- we're pointing at ground, so there are valid coordiantes
				local x, z = t[1], t[3]
				local inRange = false
				for i=1, #sU do
					local unitID = sU[i]
					local unitDef = UnitDefs[spGetUnitDefID(unitID)]
					if unitDef.isBuilding then
						if #unitDef.weapons > 0 then	-- we assume that first weapon is the one with longest range
							local range = spGetUnitWeaponState(unitID,0,"range")
							-- for w=1, #unitDef.weapons do	--otherwise uncomment this block
								-- local wr = spGetUnitWeaponState(unitID,0,"range")
								-- if wr > range then range = wr end
							-- end
							if range and range > 0 then
								local ux, _, uz = spGetUnitPosition(unitID)
								local dx, dz = x-ux, z-uz
								local dist = dx*dx + dz*dz
								if dist < range*range then
									inRange = true
									break
								end
							else
								errorCount = errorCount + 1
								if errorCount < 5 then 
									Echo("Cursortoofar: Range = nil for ",unitDef.name)
								else
									Echo("Cursortoofar: Removing gadget due to errors")
									gadgetHandler:RemoveGadget(self)
								end
							end
						else
							-- No weapons, but building still can attack. Return in range. Applies for example to labs, can set attack point
							inRange = true
							break	-- once we determine that there is a unit that can attack the target, skip testing other units
						end
					else -- mobile unit
						if #unitDef.weapons > 0 or unitDef.canKamikaze then
							inRange = true -- mobile units can always walk closer until they can attack.
							break
						end
					end
				end
				if inRange then
					spSetMouseCursor("Attack")
				else
					spSetMouseCursor("AttackBad")
				end
			end
		end
	end
end