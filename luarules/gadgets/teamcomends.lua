function gadget:GetInfo()
	return {
		name = "Team Com Ends",
		desc = "Implements com ends for allyteams",
		author = "KDR_11k (David Becker)",
		date = "2008-02-04",
		license = "Public domain",
		layer = 1,
		enabled = true
	}
end

-- this acts just like Com Ends except instead of killing a player's units when
-- his com dies it acts on an allyteam level, if all coms in an allyteam are dead
-- the allyteam is out

-- the deathmode modoption (called now just "mode") must be set to one of the following to enable this
local endmodes= {
	comcontrol=true,
	commander=true,
	comends=true,
}

if (gadgetHandler:IsSyncedCode()) then
	--SYNCED
	
	local destroyQueue 			= {}
	local destroySingleQueue	= {}
	local aliveCount 			= {}
	local localCommanders 		= {}
	local commanderTable 		= {}
	local isAlive 				= {}

	local GetTeamList			= Spring.GetTeamList
	local GetTeamUnits 			= Spring.GetTeamUnits
	local GetUnitAllyTeam 		= Spring.GetUnitAllyTeam
	local DestroyUnit			= Spring.DestroyUnit
	local Echo 					= Spring.Echo
	local GetTeamUnitDefCount	= Spring.GetTeamUnitDefCount
	local GetTeamUnitCount 		= Spring.GetTeamUnitCount
	local GetUnitsInSphere 		= Spring.GetUnitsInSphere
	local GetGameFrame			= Spring.GetGameFrame
	local COMMANDER				= "commander" --key name in modoptions.mode
	local DECOYSTART			= "decoystart" -- value name in modoptions.commander
	local commanderEnds			= Spring.GetModOptions().mode == COMMANDER
	local killX, killZ
	local frame
	local step					= 28 -- how much to expand killradius every 10 frames
	local frequency				= 6
	local destroyStepwise		= true
	
	function gadget:Initialize()
		gadgetHandler:RemoveGadget()
		if not endmodes[Spring.GetModOptions().mode] then
			Spring.Echo("Teamcomends: not commander ends, removing gadget")
			gadgetHandler:RemoveGadget()
		end
		
		for _,allyTeam in ipairs(Spring.GetAllyTeamList()) do
			aliveCount[allyTeam] = 0
		end
		
		for _,team in ipairs(GetTeamList()) do
			localCommanders[team] = 0
		end
		
		for id,unitDef in ipairs(UnitDefs) do
			if Spring.GetModOptions() and Spring.GetModOptions().commander == DECOYSTART then
				if unitDef.customParams.iscommander then
					commanderTable[unitDef.name] = true
				end
			else
				if unitDef.customParams.iscommander and (not unitDef.customParams.isdecoycommander) then
					commanderTable[unitDef.name] = true
				end
			end
		end
	end
	
	function DestroySingleTeam(team)
		--Echo("Destroying team:",team)
		if killX and destroyStepwise then
			-- code to kill team in steps
			if not frame then frame = GetGameFrame() end
			local radius = (GetGameFrame() - frame)*step
			if radius > 0 then
				for _, unitID in ipairs(GetUnitsInSphere(killX,0,killZ,radius,team)) do
					DestroyUnit(unitID, true)
				end
			end
			--Echo("Radius:",team, radius)
		else	
			for _,u in ipairs(GetTeamUnits(team)) do
				DestroyUnit(u, true)
			end
			
		end
	end
	
	function DestroyAllyTeam(allyTeam)
		--Echo("Destroying allyteam:",allyTeam)
		local allyteamCount = 0
		for _,team in ipairs(GetTeamList(allyTeam)) do
			local count = GetTeamUnitCount(team)
			--Echo("Count:",team,count)
			allyteamCount = allyteamCount + count
			if count > 0 then
				DestroySingleTeam(team)
			else
				destroySingleQueue[team] = nil
			end
		end

		if allyteamCount <= 0 then 
			destroyQueue[allyTeam] = nil
			frame = nil
		end
	end
	
	function gadget:GameFrame(t)
		if t % frequency == 0 then
			for ateam,_ in pairs(destroyQueue) do
				if not commanderEnds then				
					if aliveCount[ateam] <= 0 then --safety check, triggers on transferring the last com otherwise
						DestroyAllyTeam(ateam)
					end
				end
			end
			
			for team,_ in pairs(destroySingleQueue) do
				if commanderEnds then				
					if localCommanders[team] <= 0 then --safety check, triggers on transferring the last com otherwise
						DestroySingleTeam(team)
					end
				end
			end
		end
	end

	function gadget:UnitCreated(unitID, unitDefID, team)
		isAlive[unitID] = true
		if commanderTable[UnitDefs[unitDefID].name] then
			local allyTeam = GetUnitAllyTeam(unitID)
			aliveCount[allyTeam] = aliveCount[allyTeam] + 1
			localCommanders[team] = localCommanders[team] + 1
		end
	end

	function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
		if commanderTable[UnitDefs[unitDefID].name] then
			local allyTeam = GetUnitAllyTeam(unitID)
			aliveCount[allyTeam] = aliveCount[allyTeam] + 1
			localCommanders[unitTeam] = localCommanders[unitTeam] + 1
		end
	end

	function gadget:UnitDestroyed(unitID, unitDefID, team)
		isAlive[unitID] = nil
		
		if commanderTable[UnitDefs[unitDefID].name] then
			local allyTeam = GetUnitAllyTeam(unitID)
			aliveCount[allyTeam] = aliveCount[allyTeam] - 1
			localCommanders[team] = localCommanders[team] - 1
			
			--Echo("Local commanders",localCommanders[team])
			--Echo("Team commanders",aliveCount[allyTeam])
			
			if commanderEnds then -- implement classic commander ends option
				if localCommanders[team] <= 0 then
					killX, _, killZ = Spring.GetUnitPosition(unitID)
					destroySingleQueue[team] = true
				end
			else -- team comends option
				if aliveCount[allyTeam] <= 0 then
					killX, _, killZ = Spring.GetUnitPosition(unitID)
					destroyQueue[allyTeam] = true
				end
			end
		end
	end

	function gadget:UnitTaken(u, ud, team)
		if isAlive[u] and commanderTable[UnitDefs[ud].name] then
			local allyTeam = GetUnitAllyTeam(u)
			aliveCount[allyTeam] = aliveCount[allyTeam] - 1
			localCommanders[team] = localCommanders[team] - 1 
			if aliveCount[allyTeam] <= 0 then
				destroyQueue[allyTeam] = true
			end
			if Spring.GetModOptions().mode == COMMANDER then
				if localCommanders[team] <= 0 then
					destroySingleQueue[team] = true
				end
			end
		end
	end
else
	--UNSYNCED
	return false
end
