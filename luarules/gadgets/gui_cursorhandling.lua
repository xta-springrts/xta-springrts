function gadget:GetInfo()
	return {
		name      = "Cursor handling",
		desc      = "Handles cursor for out of range and submerged targets",
		author    = "Jools, Deadnight Warrior",
		date      = "Oct 2013",
		version   = "1.2",
		license   = "GNU GPL v2",
		layer     = 1,
		enabled   = true  --  loaded by default?
  }
end

-- Changelog: 	1.1 gets range from engine and drops attack if out of range. 
--				1.2 add code for handling submerged targets

-- function localisations
local GetUnitWeaponState 		= Spring.GetUnitWeaponState
local GetUnitWeaponTestRange	= Spring.GetUnitWeaponTestRange
local GetUnitDefID 				= Spring.GetUnitDefID
local GetUnitDefDimensions		= Spring.GetUnitDefDimensions
local GetUnitRadius				= Spring.GetUnitRadius
local GetUnitPosition			= Spring.GetUnitPosition
local GetUnitTeam				= Spring.GetUnitTeam
local CallAsTeam				= CallAsTeam
local Echo 						= Spring.Echo

-- Constants
local CMD_ATTACKBAD 			= 35577
local CMD_ATTACK 				= CMD.ATTACK
local FIRSTWEAPON				= 1

local waterWeapons 				= {}
local unitDefRadius				= {}

if gadgetHandler:IsSyncedCode() then	
	-----------------
	-- SYNCED PART --
	-----------------
	
local spAssignMouseCursor 	= Spring.AssignMouseCursor

--	CallIns
	function gadget:Initialize()
		gadgetHandler:RegisterCMDID(CMD_ATTACKBAD)
		spAssignMouseCursor("AttackBad", "cursorattackbad", true, false)
		if Game.version <= "94.1" then 
			FIRSTWEAPON	= 0
		end
		
		for id,unitDef in pairs(UnitDefs) do
			local weapons = unitDef.weapons
			local canKamikaze = unitDef.canKamikaze and unitDef.speed > 0
			
			if weapons and #weapons > 0 then
				local weaponDefID = weapons[FIRSTWEAPON].weaponDef
				local waterWeapon = WeaponDefs[weaponDefID].waterWeapon
				
				if waterWeapon then waterWeapons[id] = true end
				
			elseif canKamikaze then
				waterWeapons[id] = true 
			end
		end
	end	
	
	function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
		if cmdID == CMD_ATTACK then
			if UnitDefs[unitDefID].isBuilding and #UnitDefs[unitDefID].weapons > 0 then
				local range = GetUnitWeaponState(unitID,FIRSTWEAPON,"range")		
				if cmdParams and cmdParams[3] ~= nil and range ~= nil then
					local x, y, z = cmdParams[1], cmdParams[2], cmdParams[3]
					-- Only check if position is within range
					return GetUnitWeaponTestRange(unitID, FIRSTWEAPON, x, y, z)
				end
			elseif cmdParams and #cmdParams == 1 then
				local tID = cmdParams[1]
				local _,_,_,_,midY = GetUnitPosition(tID,true)
				if midY and midY < 0 then
					local targetdefID = GetUnitDefID(tID)
					local tDef = UnitDefs[targetdefID ]
					if not tDef then return true end
					
					local radius = unitDefRadius[targetdefID]
					
					if not radius then
						unitDefRadius[targetdefID] = GetUnitRadius(tID)
						radius = unitDefRadius[targetdefID]
					end
					local speed = tDef.speed
				
					if radius and speed and midY and midY + radius < 0 and speed == 0 then
						if not waterWeapons[unitDefID] then
							SendToUnsynced("failsound", unitTeam, tID)
							return false
						end
					end
				end
			end
		end
		return true
	end

else

	-----------------
	-- UNSYNCED PART --
	-----------------
	
	local PlaySoundFile				= Spring.PlaySoundFile
	local failed					= "sounds/cantdo4.wav"
	local myTeamID
	local GetUnitDefID				= Spring.GetUnitDefID
	
	function gadget:Initialize()
		gadgetHandler:AddSyncAction("failsound", FailSound)
		myTeamID = Spring.GetMyTeamID()
	end

	function FailSound(_,teamID, targetID)
		local udef = CallAsTeam(myTeamID,GetUnitDefID, targetID)
		
		if teamID == myTeamID and udef then
			PlaySoundFile (failed, 1.0, nil, 'ui')
		end
	end	

end