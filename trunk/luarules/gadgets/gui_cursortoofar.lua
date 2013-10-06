function gadget:GetInfo()
	return {
		name      = "Cursor too far",
		desc      = "Implements cursor out of range mode on attack command",
		author    = "Jools, Deadnight Warrior",
		date      = "May 2013",
		version   = "1.1",
		license   = "GNU GPL v2",
		layer     = 1,
		enabled   = true  --  loaded by default?
  }
end

-- Changelog: 1.1 gets range from engine and drops attack if out of range. 

-- function localisations
local spGetUnitWeaponState 	= Spring.GetUnitWeaponState
local CMD_ATTACK 			= CMD.ATTACK
local Echo 					= Spring.Echo

-- Constants
local CMD_ATTACKBAD 		= 35577
local FIRSTWEAPON			= 1
if gadgetHandler:IsSyncedCode() then	--	SYNCED

local spAssignMouseCursor 	= Spring.AssignMouseCursor

--	CallIns
	function gadget:Initialize()
		gadgetHandler:RegisterCMDID(CMD_ATTACKBAD)
		spAssignMouseCursor("AttackBad", "cursorattackbad", true, false)
		if Game.version <= "94.1" then 
			FIRSTWEAPON	= 0
		end
	end	
	
	function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
		if cmdID == CMD_ATTACK and UnitDefs[unitDefID].isBuilding and #UnitDefs[unitDefID].weapons > 0 then
			local range = spGetUnitWeaponState(unitID,FIRSTWEAPON,"range")		
			if cmdParams and cmdParams[3] ~= nil and range ~= nil then
				local x, y, z = cmdParams[1], cmdParams[2], cmdParams[3]
				-- Only check if position is within range
				local testRange = Spring.GetUnitWeaponTestRange(unitID, FIRSTWEAPON, x, y, z)
				if not testRange then return false end
			end
		end
		return true
	end

else	--	UNSYNCED

if Game.version > "91.0" then return end	-- not needed in Spring > 91.0

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
			local canFire = false
			if s == "ground" and sU then	-- we're pointing at ground, so there are valid coordiantes
				local x, y, z = t[1], t[2], t[3]
				for i=1, #sU do
					local unitID = sU[i]
					local unitDef = UnitDefs[spGetUnitDefID(unitID)]
					if unitDef.isBuilding then
						if #unitDef.weapons > 0 then	-- we assume that first weapon is the one with longest range
							
							local tryTarget = Spring.GetUnitWeaponTryTarget(unitID, 0, x, y, z)
							
							--local testTarget = Spring.GetUnitWeaponTestTarget(unitID, 0, x, y, z)
							--local testRange = Spring.GetUnitWeaponTestRange(unitID, 0, x, y, z)
							--local freeline = Spring.GetUnitWeaponHaveFreeLineOfFire(unitID, 0, x, y, z)
							--Spring.Echo("Fire test: ", i, tryTarget, testTarget, testRange, freeline)
							
							if tryTarget then 
								canFire = true
								break
							end
							
							-- for w=1, #unitDef.weapons do	--otherwise uncomment this block
								-- local wr = spGetUnitWeaponState(unitID,0,"range")
								-- if wr > range then range = wr end
							-- end
							
						else
							-- No weapons, but building still can attack. Return in range. Applies for example to labs, can set attack point
							canFire = true
							break	-- once we determine that there is a unit that can attack the target, skip testing other units
						end
					else -- mobile unit
						if #unitDef.weapons > 0 or unitDef.canKamikaze then
							canFire = true -- mobile units can always walk closer until they can attack.
							break
						end
					end
				end
				if not canFire then
					spSetMouseCursor("AttackBad")
				end
			end
		end
	end
end