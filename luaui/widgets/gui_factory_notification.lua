function widget:GetInfo()
	return {
		name = "Factory notification",
		desc = "Notifies when player's factory gets blocked",
		author = "Jools",
		date = "Movember, 2014",
		license = "GPLv2",
		version = "1.0",
		layer = 1,
		enabled = true
	}
end
----------------------------------------------------------------------------

local PlaySoundFile				= Spring.PlaySoundFile
local GetTimer					= Spring.GetTimer
local DiffTimers				= Spring.DiffTimers
local IsUnitInView				= Spring.IsUnitInView
local GetUnitPosition			= Spring.GetUnitPosition
local SetLastMessagePosition	= Spring.SetLastMessagePosition
local GetSpectatingState		= Spring.GetSpectatingState
local GetTeamInfo				= Spring.GetTeamInfo
local GetGameFrame				= Spring.GetGameFrame
local AreTeamsAllied			= Spring.AreTeamsAllied
local GetUnitTeam				= Spring.GetUnitTeam
local GetUnitIsDead				= Spring.GetUnitIsDead
local random					= math.random
local Echo						= Spring.Echo
local SendMessageToTeam			= Spring.SendMessageToTeam
local myTeamID					= Spring.GetMyTeamID()
local GetUnitHealth				= Spring.GetUnitHealth
local maxUnits					= tonumber(Spring.GetModOptions().maxunits or Game.maxUnits) 
----------------------------------------------------------------------------

local alarmTimes				= {}
local factoryUnits				= {}
local blockedFactories			= {}
local Factories					= {}

----------------------------------------------------------------------------

local cancel = "sounds/unit/cancel2.wav"
local movefailed = "sounds/unit/cantdo4.wav"

----------------------------------------------------------------------------
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
   
	if (GetSpectatingState() == true) then
		widgetHandler:RemoveWidget()
		return false
	end
    
	
	for id, unitDef in ipairs(UnitDefs) do			
		if unitDef.isFactory and unitDef.isImmobile then
			factoryUnits[id] = true
			--Echo("Factory added:",unitDef.name)
		end
	end
	VOLUI = 0.015*Spring.GetConfigInt('snd_volui') or 1.0
	
	for _, uID in pairs(Spring.GetTeamUnits(myTeamID) ) do
		local udID = Spring.GetUnitDefID(uID)
		if factoryUnits[udID] and IsUnitComplete(uID) then
			Factories[uID] = true
		end
	end
end

function widget:GameFrame(gameFrame)
	if gameFrame%300 == 0 then
		
		for fID,frame in pairs (blockedFactories) do
			if Spring.GetUnitIsDead(fID) then
				blockedFactories[fID] = nil
			else	
				local isBuilding = Spring.GetUnitIsBuilding(fID)
				if isBuilding then
					blockedFactories[fID] = nil
				else
					local fCounts = Spring.GetFactoryCounts(fID,3)
					local hasQueue = fCounts and fCounts[2]
					if hasQueue then
						if gameFrame - frame > 900 and (gameFrame - frame)%900 == 0 then
							local fdID = Spring.GetUnitDefID(fID)
							SendMessageToTeam(myTeamID, UnitDefs[fdID].humanName .. ": foreign object blocking construction platform!")
							--local x,y,z = Spring.GetUnitPosition(fID) -- markers are annoying
							--Spring.MarkerAddPoint (x,y,z,"Factory stuck",true)
						end
					else
						blockedFactories[fID] = nil
					end
				end
			end
		end
		
		for fID in pairs(Factories) do
			
			local isBuilding = Spring.GetUnitIsBuilding(fID)
			if not isBuilding then
				local nbUnits = Spring.GetTeamUnitCount(myTeamID)
				local fCounts = Spring.GetFactoryCounts(fID,3)
				local hasQueue = fCounts and fCounts[2]
				if hasQueue and nbUnits < maxUnits then
					if not blockedFactories[fID] then
						blockedFactories[fID] = gameFrame
						local fdID = Spring.GetUnitDefID(fID)
					end
				end
			end
		end
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	if factoryUnits[unitDefID] then
		Factories[unitID] = true
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, preEvent)
	if preEvent == false then return end
	
	if Factories[unitID] then
		Factories[unitID] = nil
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if factoryUnits[unitDefID] then
		if newTeam == myTeamID then
			Factories[unitID] = true
		elseif oldTeam == myTeamID then
			Factories[unitID] = nil
		end
	end
end

function widget:GameOver()
	widgetHandler:RemoveWidget()
	return false
end

function widget:PlayerChanged(playerID)
	--changing teams, rejoin, becoming spec etc
    myTeamID = Spring.GetMyTeamID()
	if (GetSpectatingState() == true) then
		widgetHandler:RemoveWidget()
		return false
	end
end
