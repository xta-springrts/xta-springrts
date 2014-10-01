function gadget:GetInfo()
	return {
		name = "Team-comends",
		desc = "Implements comends for allyteams",
		author = "KDR_11k (David Becker), Jools",
		date = "Sep, 2013",
		license = "Public domain",
		layer = -5,
		enabled = true
	}
end

-- this acts just like Comends except instead of killing a player's units when
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
	local allyCommanders 		= {}	-- table of commander's count per teamID (allyteam)
	local teamCommanders 		= {}	-- table of commanders per player (teamID)
	local commanderTable 		= {} 	-- table by commander unitdefid:s = true
	local commanderDefs			= {}	-- table of commander unitdefid:s
	local isAlive 				= {}
	local deadTeams				= {}    -- needed because select(3,Spring.GetTeamInfo(teamID)) returns true 1 frame too late

	local GetTeamList			= Spring.GetTeamList
	local GetTeamUnits 			= Spring.GetTeamUnits
	local GetUnitAllyTeam 		= Spring.GetUnitAllyTeam
	local DestroyUnit			= Spring.DestroyUnit
	local Echo 					= Spring.Echo
	local GetTeamUnitDefCount	= Spring.GetTeamUnitDefCount
	local GetTeamUnitCount 		= Spring.GetTeamUnitCount
	local GetUnitsInSphere 		= Spring.GetUnitsInSphere
	local GetUnitPosition		= Spring.GetUnitPosition
	local GetGameFrame			= Spring.GetGameFrame
	local AreTeamsAllied		= Spring.AreTeamsAllied
	local COMMANDER				= "commander" --key name in modoptions.mode
	local DECOYSTART			= "decoystart" -- value name in modoptions.commander
	local commanderEnds			= Spring.GetModOptions().mode == COMMANDER
	local killX, killZ
	local frame
	local step					= 28 -- how much to expand killradius every <frequency> frames
	local frequency				= 6
	local destroyStepwise		= true
	local modOptions			= Spring.GetModOptions()
	local contesters			= {}
	local TIMEOUTDELAY			= 960 -- force end after this delay
	local isGameWinner			= false
	local gameOverFrame			= nil
	local gaiaTeamID			= Spring.GetGaiaTeamID()
	local gaiaAllyID 			= select(6, Spring.GetTeamInfo(gaiaTeamID))
	
	local dgunWeapons = {		-- better to hardcode these, as many weapons are listed as dgun, for example bogus dgun
	arm_disintegrator = true,
	core_disintegrator = true,
	core_udisintegrator = true,
	uber_disintegrator = true,
	}
	
	local dgunTable = {} -- Populated from dgunWeapons; a little better to store weapons in table by id instead of name
	
	function gadget:Initialize()
		if not endmodes[modOptions.mode] then
			Spring.SetGameRulesParam("WaitForComends",0)
			gadgetHandler:RemoveGadget(self)
			return
		end
		
		for _,allyTeam in ipairs(Spring.GetAllyTeamList()) do
			allyCommanders[allyTeam] = 0
			if allyTeam ~= gaiaAllyID and (#Spring.GetTeamList(allyTeam) > 0) then
				contesters[#contesters+1] = allyTeam
			end
		end
		
		for _,teamID in ipairs(GetTeamList()) do
			teamCommanders[teamID] = 0
		end
		
		for id,weaponDef in pairs(WeaponDefs) do
			local wName = weaponDef.name
			if dgunWeapons[wName] then
				dgunTable[weaponDef.id] = true
			end
		end
		
		if modOptions and modOptions.commander == DECOYSTART then
			for id, unitDef in ipairs(UnitDefs) do
				if unitDef.customParams.iscommander then
					if unitDef.name then
						commanderTable[id] = true
						commanderDefs[#commanderDefs+1]=id
					end
				end
			end	
		else
			for id, unitDef in ipairs(UnitDefs) do	
				if unitDef.customParams.iscommander and (not unitDef.customParams.isdecoycommander) then
					if unitDef.name then
						commanderTable[id] = true
						commanderDefs[#commanderDefs+1]=id
					end				
				end
			end
		end
	end
	
	function gadget:Shutdown()
		Spring.SetGameRulesParam("WaitForComends",0)
		if Spring.IsGameOver() then
			Spring.SetGameRulesParam("ShowEnd",1)
		end
	end
	
	local function removeContester(allyID)
		for i, aID in ipairs (contesters) do
			if aID == allyID then
				table.remove(contesters, i)
			end
		end
	end
	
	local function GetQueue()
		
		local totalcount = 0
		for _,allyID in ipairs(Spring.GetAllyTeamList()) do
			
			if allyID ~= gaiaAllyID and GG.gamewinners then 
				local winnerTeam
				for _, winner in pairs(GG.gamewinners) do
					if winner and winner == allyID then
						winnerTeam = true
						break;
					end
				end
				
				if not winnerTeam then
				
					local allycount = 0
					for _,teamID in ipairs(GetTeamList(allyID)) do
						local count = GetTeamUnitCount(teamID)
						allycount = allycount + count
					end
					totalcount = totalcount + allycount
				end
				
			end
		end
		return totalcount
	end
	
	local function checkWinners()
		local winners 
		if #contesters == 1 then
			winners = (contesters)
		elseif #contesters < 1 then
			winners = {}
		end
				
		if winners or Spring.IsGameOver() then -- add extra check for game over in case the first check failed somehow
			if not GG.gamewinners then -- other gadgets may declare winners
				GG.gamewinners = winners
			end
			isGameWinner = true
			gameOverFrame = Spring.GetGameFrame()
			return true
		end
		return false
	end
	
	local function KillAllyTeamsZeroUnits()
	-- kill all the allyteams that have zero units	
		for _, aID in ipairs(Spring.GetAllyTeamList()) do
			local teamList = Spring.GetTeamList(aID)
			local allyUnitCount = 0
			for _,teamID in ipairs(teamList) do
				local unitCount = Spring.GetTeamUnitCount(teamID)
				allyUnitCount = allyUnitCount + unitCount
			end
			
			if allyUnitCount == 0 then
				for _,teamID in ipairs(teamList) do
					Spring.KillTeam(teamID)
				end
			end
		end
	end
		
	function gadget:GameStart()
		if endmodes[modOptions.mode] then
			Spring.SetGameRulesParam("WaitForComends",1)	
		end
	end
	
	function gadget:GameOver()
		checkWinners()
	end
			
	local function DestroySingleTeam(teamID)
		if killX and destroyStepwise then
			-- code to kill team in steps
			if not frame then frame = GetGameFrame() end
			local radius = (GetGameFrame() - frame)*step
			if radius > 0 then
				for _, unitID in ipairs(GetUnitsInSphere(killX,0,killZ,radius,teamID)) do
					DestroyUnit(unitID, true)
				end
			end
		else	
			for _,u in ipairs(GetTeamUnits(teamID)) do
				DestroyUnit(u, true)
			end
			
		end
	end
	
	local function DestroyAllyTeam(allyTeam)
		local allyteamCount = 0
		for _,teamID in ipairs(GetTeamList(allyTeam)) do
			local count = GetTeamUnitCount(teamID)
			allyteamCount = allyteamCount + count
			if count > 0 then
				DestroySingleTeam(teamID)
			else
				destroySingleQueue[teamID] = nil
			end
		end

		if allyteamCount <= 0 then 
			destroyQueue[allyTeam] = nil
			frame = nil
		end
	end
	
	local function GetTeamCommanders(teamID)
		local teamComms = 0	
		
		for _,cID in pairs(commanderDefs) do
			local count = GetTeamUnitDefCount(teamID,cID)
			teamComms = teamComms+count
		end
		return teamComms
	end
	
	function gadget:GameFrame(t)
		if t % frequency == 0 then
			for ateam,_ in pairs(destroyQueue) do
				if not commanderEnds then
					if allyCommanders[ateam] <= 0 then --safety check, triggers on transferring the last com otherwise
						DestroyAllyTeam(ateam)
					end
				end
			end
			
			for teamID,_ in pairs(destroySingleQueue) do
				if commanderEnds then				
					if teamCommanders[teamID] <= 0 then --safety check, triggers on transferring the last com otherwise
						DestroySingleTeam(teamID)
					end
				end
			end	
		end
		
		if GG.gamewinners and t % frequency == 0 then
			if gameOverFrame and t > gameOverFrame + frequency*2 + 16 and GetQueue() == 0 then
				KillAllyTeamsZeroUnits()
				Spring.SetGameRulesParam("WaitForComends",0)
			end	
		end			
		
		if gameOverFrame and t > gameOverFrame + TIMEOUTDELAY and Spring.GetGameRulesParam("WaitForComends") == 1 then
			Spring.SetGameRulesParam("WaitForComends",0)
			Echo("Team commander ends timeouted, skipping it...")
			if GG.gamewinners then
				Spring.GameOver(GG.gamewinners)
			end		
		end	
	end
	
	function gadget:TeamDied(teamID)
				
		local teamComms = GetTeamCommanders(teamID)
		local allyTeam = select(6,Spring.GetTeamInfo(teamID))
		local isDead = select(3,Spring.GetTeamInfo(teamID))
		
		-- only proceed if teamID that died had a commander
		if teamComms > 0 then
			allyCommanders[allyTeam] = allyCommanders[allyTeam] - 1
			
			local allyComms = allyCommanders[allyTeam]
			if allyComms <= 0 then
				if deadTeams[teamID] then -- means that team's commander has already died, so team didn't die by resigning
					killX, _, killZ = Spring.GetTeamStartPosition(teamID)
					destroyQueue[allyTeam] = true
				end
				deadTeams[teamID] = true
				if not isGameWinner then
					removeContester(allyTeam)
					if checkWinners() then
						Echo("Game ends: teamID's last commander resigned")
					end
				end
			end	
		end
	end
	
	function gadget:UnitCreated(unitID, unitDefID, teamID)
		isAlive[unitID] = true
		if commanderTable[unitDefID] then
			local allyTeam = GetUnitAllyTeam(unitID)
			allyCommanders[allyTeam] = allyCommanders[allyTeam] + 1
			teamCommanders[teamID] = teamCommanders[teamID] + 1
		end
		return false
	end

	function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
		if commanderTable[unitDefID] then
			local allyTeam = GetUnitAllyTeam(unitID)
			local oldAllyTeam = select(6,Spring.GetTeamInfo(oldTeam))
			allyCommanders[allyTeam] = allyCommanders[allyTeam] + 1
			teamCommanders[unitTeam] = teamCommanders[unitTeam] + 1
			
			if allyCommanders[oldAllyTeam] <= 0 then
				killX, _, killZ = GetUnitPosition(unitID)
				if not isGameWinner then
					removeContester(oldAllyTeam)
					if checkWinners() then
						Echo("Game ends: last commander was given away")
					end
				end
			end
		end
		return false
	end

	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
		
		-- End game and declare winners if a Commander was D-Gunned
		if commanderTable[unitDefID] then
			if dgunTable[weaponDefID] and attackerTeam then
				local health = Spring.GetUnitHealth(unitID)
				local enemyAllyID = select(6,Spring.GetTeamInfo(attackerTeam))
				if allyCommanders[enemyAllyID] <= 1 and health <= 0 and (not AreTeamsAllied(unitTeam, attackerTeam)) then
					if not isGameWinner then
						removeContester(enemyAllyID)
						if checkWinners() then
							Echo("Game ends: teamID's last commander d-gunned enemy commander")
						end
					end
				end
			end
		end
		return false
	end

	function gadget:UnitDestroyed(unitID, unitDefID, teamID)
		isAlive[unitID] = nil
		
		if commanderTable[unitDefID] then
						
			local allyTeam = GetUnitAllyTeam(unitID)
			allyCommanders[allyTeam] = allyCommanders[allyTeam] - 1
			teamCommanders[teamID] = teamCommanders[teamID] - 1
			-- End game and declare winners if last commander dies
			if commanderEnds then -- implement classic commander ends option
				if teamCommanders[teamID] <= 0 then
					deadTeams[teamID] = true
					killX, _, killZ = GetUnitPosition(unitID)
					destroySingleQueue[teamID] = true
					if allyCommanders[allyTeam] <= 0 then
						if not isGameWinner then
							removeContester(allyTeam)
							if checkWinners() then
								Echo("Game ends: last commander is killed")
							end
						end
					end
				end
				
			else -- team comends option
				if allyCommanders[allyTeam] <= 0 and allyTeam ~= gaiaAllyID then
					killX, _, killZ = GetUnitPosition(unitID)
					destroyQueue[allyTeam] = true
					
					-- mark teams as dead
					for _, tID in pairs(GetTeamList(allyTeam)) do
						deadTeams[tID] = true
					end
					
					if not isGameWinner then
						removeContester(allyTeam)
						if checkWinners() then
							Echo("Game ends: team's last commander is killed")
						end
					end
				end
			end
		end
		return false
	end

	function gadget:UnitTaken(unitID, unitDefID, teamID)
		if isAlive[unitID] and commanderTable[unitDefID] then
			local allyTeam = GetUnitAllyTeam(unitID)
			allyCommanders[allyTeam] = allyCommanders[allyTeam] - 1
			teamCommanders[teamID] = teamCommanders[teamID] - 1 
			if allyCommanders[allyTeam] <= 0 then
				destroyQueue[allyTeam] = true
			end
			if modOptions.mode == COMMANDER then
				if teamCommanders[teamID] <= 0 then
					destroySingleQueue[teamID] = true
				end
			end
		end
		return false
	end
else
	--UNSYNCED
	return false
end
