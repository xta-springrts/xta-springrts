function widget:GetInfo()
	return {
		name      = "Sound: Autodestruction countdown",
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

local Spring_GetActiveCommand 		= Spring.GetActiveCommand
local Spring_GetSelectedUnits 		= Spring.GetSelectedUnits
local Spring_TraceScreenRay 		= Spring.TraceScreenRay
local Spring_GetUnitDefID 			= Spring.GetUnitDefID
local Echo							= Spring.Echo
local PlaySoundFile		 			= Spring.PlaySoundFile
-- sounds

local CD1 = "sounds/count1.wav"
local CD2 = "sounds/count2.wav"
local CD3 = "sounds/count3.wav"
local CD4 = "sounds/count4.wav"
local CD5 = "sounds/count5.wav"
local CD6 = "sounds/count6.wav"
local cancel = "sounds/cancel2.wav"

local ADUnits = {}
local CMD_SELFD = CMD.SELFD
--	CallIns

function widget:Initialize()

end	

function widget:GameFrame(gameFrame)
	for _, startFrame in pairs(ADUnits) do
		if (gameFrame - startFrame) == 30 then
			PlaySoundFile(CD2)
		elseif (gameFrame - startFrame) == 60 then
			PlaySoundFile(CD3)
		elseif (gameFrame - startFrame) == 90 then
			PlaySoundFile(CD4)
		elseif (gameFrame - startFrame) == 120 then
			PlaySoundFile(CD5)
		elseif (gameFrame - startFrame) == 150 then
			PlaySoundFile(CD6)
		end			
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if cmdID == CMD_SELFD then
		if not ADUnits[unitID] then
		local frame = Spring.GetGameFrame()
			ADUnits[unitID] = frame
			PlaySoundFile(CD1)
		else
			ADUnits[unitID] = nil
			PlaySoundFile(cancel)
		end
	end
	return true
end

function widget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	if ADUnits[unitID] then
		ADUnits[unitID] = nil
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	if ADUnits[unitID] then
		ADUnits[unitID] = nil
	end
end