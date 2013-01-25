function widget:GetInfo()
	return {
		name      = "Sound: Cloak and decloak",
		desc      = "Plays cloak and decloak sounds",
		author    = "Jools",
		date      = "Jan 2013",
		version   = "1.0",
		license   = "GNU GPL v2",
		layer     = 1,
		enabled   = true  --  loaded by default?
  }
end

-- function localisations
local Echo							= Spring.Echo
local PlaySoundFile		 			= Spring.PlaySoundFile

-- sounds
local cloak1 = "sounds/kloak1.wav"
local decloak1 = "sounds/kloak1un.wav"
local cloak2 = "sounds/kloak2.wav"
local decloak2 = "sounds/kloak2un.wav"

-- settings

local volume = 3.0
local Channel = 'battle'

--	CallIns

function widget:Initialize()
end

function widget:UnitCloaked(unitID, unitDefID, teamID) 
	local x,y,z = Spring.GetUnitPosition(unitID)
	local foo1,foo2,foo3,foo4,side = Spring.GetTeamInfo(teamID)
		
	if side == "arm" then
		PlaySoundFile(cloak1,volume,x,y,z,0,0,0,Channel)
	else
		PlaySoundFile(cloak2,volume,x,y,z,0,0,0,Channel)
	end
end

function widget:UnitDecloaked(unitID, unitDefID, teamID) 
	local x,y,z = Spring.GetUnitPosition(unitID)
	local _,_,_,_,side = Spring.GetTeamInfo(teamID)
	
	if side == "arm" then
		PlaySoundFile(decloak1,volume,x,y,z,0,0,0,Channel)
	else
		PlaySoundFile(decloak2,volume,x,y,z,0,0,0,Channel)
	end
end