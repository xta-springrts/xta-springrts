function widget:GetInfo()
	return {
		name = "XTA Unit sounds",
		desc = "Plays various unit sounds (under attack, cloak, decloak, self-d countdown, etc.)",
		author = "DeadnightWarrior, Jools, knorke, very_bad_soldier",
		date = "Jan, 2013",
		license = "GPLv2",
		layer = 1,
		enabled = true
	}
end
----------------------------------------------------------------------------
local alarmInterval				= 5		--seconds
----------------------------------------------------------------------------                
local spGetLocalTeamID			= Spring.GetLocalTeamID
local spPlaySoundFile			= Spring.PlaySoundFile
local spEcho					= Spring.Echo
local spGetTimer				= Spring.GetTimer
local spDiffTimers				= Spring.DiffTimers
local spIsUnitInView			= Spring.IsUnitInView
local spGetUnitPosition			= Spring.GetUnitPosition
local spSetLastMessagePosition	= Spring.SetLastMessagePosition
local spGetSpectatingState		= Spring.GetSpectatingState
local spGetTeamInfo				= Spring.GetTeamInfo
local spGetGameFrame			= Spring.GetGameFrame
local random					= math.random
----------------------------------------------------------------------------
local lastAlarmTime				= nil
local localTeamID				= nil
----------------------------------------------------------------------------
local cloak1 = "sounds/kloak1.wav"
local decloak1 = "sounds/kloak1un.wav"
local cloak2 = "sounds/kloak2.wav"
local decloak2 = "sounds/kloak2un.wav"

local CD1 = "sounds/count1.wav"
local CD2 = "sounds/count2.wav"
local CD3 = "sounds/count3.wav"
local CD4 = "sounds/count4.wav"
local CD5 = "sounds/count5.wav"
local CD6 = "sounds/count6.wav"
local cancel = "sounds/cancel2.wav"

local ADUnits = {}
local CMD_SELFD = CMD.SELFD

local volume = 3.0
local Channel = 'battle'
----------------------------------------------------------------------------
function widget:Initialize()
    localTeamID = spGetLocalTeamID()   
    lastAlarmTime = spGetTimer()
    math.randomseed(os.time())
end

function widget:UnitCloaked(unitID, unitDefID, teamID) 
	local x,y,z = spGetUnitPosition(unitID)
	local _,_,_,_,side = spGetTeamInfo(teamID)
		
	if side == "arm" then
		spPlaySoundFile(cloak1,volume,x,y,z,0,0,0,Channel)
	else
		spPlaySoundFile(cloak2,volume,x,y,z,0,0,0,Channel)
	end
end

function widget:UnitDecloaked(unitID, unitDefID, teamID) 
	local x,y,z = spGetUnitPosition(unitID)
	local _,_,_,_,side = spGetTeamInfo(teamID)
	
	if side == "arm" then
		spPlaySoundFile(decloak1,volume,x,y,z,0,0,0,Channel)
	else
		spPlaySoundFile(decloak2,volume,x,y,z,0,0,0,Channel)
	end
end

function widget:GameFrame(gameFrame)
	for _, startFrame in pairs(ADUnits) do
		if (gameFrame - startFrame) == 30 then
			spPlaySoundFile(CD2)
		elseif (gameFrame - startFrame) == 60 then
			spPlaySoundFile(CD3)
		elseif (gameFrame - startFrame) == 90 then
			spPlaySoundFile(CD4)
		elseif (gameFrame - startFrame) == 120 then
			spPlaySoundFile(CD5)
		elseif (gameFrame - startFrame) == 150 then
			spPlaySoundFile(CD6)
		end			
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
	if cmdID == CMD_SELFD then
		if not ADUnits[unitID] then
		local frame = spGetGameFrame()
			ADUnits[unitID] = frame
			spPlaySoundFile(CD1)
		else
			ADUnits[unitID] = nil
			spPlaySoundFile(cancel)
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

function widget:UnitDamaged (unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if (localTeamID ~= unitTeam or spIsUnitInView(unitID)) then
		return --ignore other teams and units in view
	end

	local now = spGetTimer()
	if (spDiffTimers(now, lastAlarmTime) < alarmInterval) then
		return
	end

	lastAlarmTime = now

	local udef = UnitDefs[unitDefID]
	local x,y,z = spGetUnitPosition(unitID)

	spEcho("-> " .. udef.humanName  .." is being attacked!") --print notification

	if (udef.sounds.underattack and (#udef.sounds.underattack > 0)) then
		id = random(1, #udef.sounds.underattack) --pick a sound from the table by random --(id 138, name warning2, volume 1)

		soundFile = udef.sounds.underattack[id].name
		if (string.find(soundFile, "%.") == nil) then
			soundFile = soundFile .. ".wav" --append .wav if no extension is found
		end
			
		spPlaySoundFile("sounds/" .. soundFile, udef.sounds.underattack[id].volume, nil, "ui")
	end

	if (x and y and z) then spSetLastMessagePosition(x,y,z) end
end

function widget:UnitMoveFailed(unitID, unitDefID, unitTeam)
	spEcho(UnitDefs[unitDefID].humanName .. ": Can't reach destination!")
end 

--changing teams, rejoin, becoming spec etc
function widget:PlayerChanged(playerID)
    localTeamID = spGetLocalTeamID()  
	if (spGetSpectatingState() == true) then
		widgetHandler:RemoveWidget()
		return false
	end
end