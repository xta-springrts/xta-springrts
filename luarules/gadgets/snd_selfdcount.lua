function gadget:GetInfo()
	return {
		name      = "Autodestruction countdown sounds",
		desc      = "Implementgs OTA-style countdown sounds on self-d",
		author    = "Jools",
		date      = "Jan 2013",
		version   = "1.0",
		license   = "GNU GPL v2",
		layer     = 1,
		enabled   = true  --  loaded by default?
  }
end

-- function localisations

local GetUnitDefID					= Spring.GetUnitDefID
local GetUnitPosition				= Spring.GetUnitPosition
local GetUnitsInCylinder			= Spring.GetUnitsInCylinder
local ValidUnitID					= Spring.ValidUnitID
local CallCOBScript					= Spring.CallCOBScript
local DestroyUnit					= Spring.DestroyUnit
local RemoveBuildingDecal			= Spring.RemoveBuildingDecal
local SetUnitMoveGoal				= Spring.SetUnitMoveGoal
local SpawnCEG						= Spring.SpawnCEG
local AssignMouseCursor 			= Spring.AssignMouseCursor
local Spring_GetMouseState 			= Spring.GetMouseState
local Spring_GetActiveCommand 		= Spring.GetActiveCommand
local Spring_GetSelectedUnits 		= Spring.GetSelectedUnits
local Spring_TraceScreenRay 		= Spring.TraceScreenRay
local Spring_GetUnitDefID 			= Spring.GetUnitDefID
local Spring_GetUnitWeaponState 	= Spring.GetUnitWeaponState
local Spring_GetUnitPosition  		= Spring.GetUnitPosition 
local Spring_SetMouseCursor 		= Spring.SetMouseCursor
local CMD_ATTACK 					= CMD.ATTACK
local Echo							= Spring.Echo
local PlaySoundFile		 			= Spring.PlaySoundFile
-- sounds

local CD1 = "sounds/count1.wav"
local CD2 = "sounds/count2.wav"
local CD3 = "sounds/count3.wav"
local CD4 = "sounds/count4.wav"
local CD5 = "sounds/count5.wav"
local CD6 = "sounds/count6.wav"

if gadgetHandler:IsSyncedCode() then
--	SYNCED

	local ADUnits = {}
	local CMD_SELFD = CMD.SELFD
--	CallIns

	function gadget:Initialize()
	
	end	
	
	function gadget:GameFrame(gameFrame)
		for _, startFrame in pairs(ADUnits) do
			if (gameFrame - startFrame)/30 == 1 then
				PlaySoundFile(CD1)
			elseif (gameFrame - startFrame)/30 == 2 then
				PlaySoundFile(CD2)
			elseif (gameFrame - startFrame)/30 == 3 then
				PlaySoundFile(CD3)
			elseif (gameFrame - startFrame)/30 == 4 then
				PlaySoundFile(CD4)
			elseif (gameFrame - startFrame)/30 == 5 then
				PlaySoundFile(CD5)
			elseif (gameFrame - startFrame)/30 == 6 then
				PlaySoundFile(CD6)
			end			
		end
	end
	
	function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
		if cmdID == CMD_SELFD then
			if not ADUnits[unitID] then
			local frame = Spring.GetGameFrame()
				ADUnits[unitID] = frame
			else
				ADUnits[unitID] = nil
			end
		end
		return true
	end
	
	function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
		if ADUnits[unitID] then
			ADUnits[unitID] = nil
		end
	end
	
	function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
		if ADUnits[unitID] then
			ADUnits[unitID] = nil
		end
	end
	
else

-- UNSYNCED

end
	

	
	
	
	