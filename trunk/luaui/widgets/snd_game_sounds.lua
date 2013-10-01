function widget:GetInfo()
	return {
		name = "XTA Unit sounds",
		desc = "Plays various unit sounds (under attack, cloak, decloak, self-d countdown, etc.)",
		author = "DeadnightWarrior, Jools, knorke, very_bad_soldier",
		date = "Sep, 2013",
		license = "GPLv2",
		version = "1.1",
		layer = 1,
		enabled = true
	}
end
----------------------------------------------------------------------------
local alarmInterval				= 60		-- seconds, interval between sound alarms for same unit type
local commanderAlarmInterval	= 10 		-- seconds, interval for sound alarms for other units after commander was attacked
local textNotifyInterval		= 10 		-- seconds, interval for text notifications for same unit type
local commanderSoundInterval	= 3			-- seconds, interval between sound notifications for Commander
local commanderTextInterval		= 3			-- seconds, interval between text notifications for Commander	
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
local spAreTeamsAllied			= Spring.AreTeamsAllied
local random					= math.random
----------------------------------------------------------------------------
local lastAlarmTime				= nil
local localTeamID				= nil
local commanderTable			= {}
local lastCommanderAlarm		= nil
local alarmTimes				= {}
alarmTimes["text"]				= {}
alarmTimes["sound"]				= {}
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
	if (spGetSpectatingState() == true) then
		widgetHandler:RemoveWidget()
		return false
	end
    lastAlarmTime = spGetTimer()
    math.randomseed(os.time())
	
	for id, unitDef in ipairs(UnitDefs) do
		if unitDef.customParams.iscommander and (not unitDef.customParams.isdecoycommander) then
			if unitDef.name then
				commanderTable[id] = true
			end
		end
	end	
	
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

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	
	if ADUnits[unitID] and (not spAreTeamsAllied(unitTeam, newTeam)) then
		ADUnits[unitID] = nil
	end
end

function widget:UnitDamaged (unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if (localTeamID ~= unitTeam or spIsUnitInView(unitID)) then
		return --ignore other teams and units in view
	end
	
	local now = spGetTimer()
	local udef
	
	if commanderTable[unitDefID] then 
		-- return before text notification condition
		if alarmTimes["text"][unitDefID] and (spDiffTimers(now, alarmTimes["text"][unitDefID]) < commanderTextInterval) then return end
		alarmTimes["text"][unitDefID] = now
		
		udef = UnitDefs[unitDefID]
		spEcho("-> " .. udef.humanName  ..": under attack!") --print notification
		
		-- return before sound notification condition
		if alarmTimes["sound"][unitDefID] and (spDiffTimers(now, alarmTimes["sound"][unitDefID]) < commanderSoundInterval) then return end
		lastCommanderAlarm = now
	else
		-- return before text notification condition
		if alarmTimes["text"][unitDefID] and (spDiffTimers(now, alarmTimes["text"][unitDefID]) < textNotifyInterval) then return end
		alarmTimes["text"][unitDefID] = now
		
		udef = UnitDefs[unitDefID]
		spEcho("-> " .. udef.humanName  ..": under attack!") --print notification

		-- return before sound notification condition
		if alarmTimes["sound"][unitDefID] and (spDiffTimers(now, alarmTimes["sound"][unitDefID]) < alarmInterval) then return end
		
		-- return if commander was attacked recently
		if lastCommanderAlarm and (spDiffTimers(now, lastCommanderAlarm) < commanderAlarmInterval) then return end
	end
	
	alarmTimes["sound"][unitDefID] = now
	
	local x,y,z = spGetUnitPosition(unitID)

	local snd 
	if commanderTable[unitDefID] then
		snd = 'sounds/warning2.wav'
	else
		snd = 'sounds/warning1.wav'
	end
	spPlaySoundFile(snd, udef.sounds.underattack[1].volume, nil, "ui")

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