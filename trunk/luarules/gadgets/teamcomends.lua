function gadget:GetInfo()
	return {
		name = "Team Com Ends",
		desc = "Implements com ends for allyteams",
		author = "KDR_11k (David Becker)",
		date = "2008-02-04",
		license = "Public domain",
		layer = -5,
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
	local teamCommanders 		= {}	-- table of commander's count per team (allyteam)
	local playerCommanders 		= {}	-- table of commanders per player (team)
	local commanderTable 		= {} 	-- table of commander unitdefid:s
	local isAlive 				= {}

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
	local gameHasEnded			= false
	local contesters			= {}
	local gameoverframe			= nil
	local gamewinners			= nil
	local gameoverdelay			= 120 -- check that this is less than the value in game_end gadget to make combomb forfeit work
	
	local dgunWeapons = {		-- better to hardcode these, as many weapons are listed as dgun, for example bogus dgun
	arm_disintegrator = true,
	core_disintegrator = true,
	core_udisintegrator = true,
	uber_disintegrator = true,
	}
	
	local dgunTable = {} -- Populated from dgunWeapons; a little better to store weapons in table by id instead of name
	
	function gadget:Initialize()
		if not endmodes[modOptions.mode] then
			gadgetHandler:RemoveGadget(self)
			Echo("Team Comends gadget: game is set to continue when commander dies, I am not needed.")
			return
		end
		
		local gaiaAllyID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))
		
		for i,allyTeam in ipairs(Spring.GetAllyTeamList()) do
			teamCommanders[allyTeam] = 0
			if allyTeam ~= gaiaAllyID then
				contesters[i] = allyTeam
			end
		end
		
		for _,team in ipairs(GetTeamList()) do
			playerCommanders[team] = 0
		end
		
		for id,weaponDef in pairs(WeaponDefs) do
			local wName = weaponDef.name
			--Echo("Weapon: ", wName)
			if dgunWeapons[wName] then
				dgunTable[weaponDef.id] = true
			end
		end
		
		if modOptions and modOptions.commander == DECOYSTART then
			for id, unitDef in ipairs(UnitDefs) do
				if unitDef.customParams.iscommander then
					if unitDef.name then
						commanderTable[id] = true
					end
				end
			end	
		else
			for id, unitDef in ipairs(UnitDefs) do	
				if unitDef.customParams.iscommander and (not unitDef.customParams.isdecoycommander) then
					if unitDef.name then
						commanderTable[id] = true
					end				
				end
			end
		end
	end
	
	local function removeContester(allyID)
		for i, aID in ipairs (contesters) do
			if aID == allyID then
				table.remove(contesters, i)
			end
		end
	end
	
	local function checkWinners()
		local winners 
		if #contesters == 1 then
			winners = (contesters)
		elseif #contesters < 1 then
			winners = {}
		end
		if winners then
			local frame = Spring.GetGameFrame()
			gameoverframe = frame + gameoverdelay
			gamewinners = winners
			Spring.PlaySoundFile("sounds/victory1.wav",8.0,0,0,0,0,0,0,'userinterface')
			return true
		end
		return false
	end
			
	local function DestroySingleTeam(team)
		if killX and destroyStepwise then
			-- code to kill team in steps
			if not frame then frame = GetGameFrame() end
			local radius = (GetGameFrame() - frame)*step
			if radius > 0 then
				for _, unitID in ipairs(GetUnitsInSphere(killX,0,killZ,radius,team)) do
					DestroyUnit(unitID, true)
				end
			end
		else	
			for _,u in ipairs(GetTeamUnits(team)) do
				DestroyUnit(u, true)
			end
			
		end
	end
	
	local function DestroyAllyTeam(allyTeam)
		local allyteamCount = 0
		for _,team in ipairs(GetTeamList(allyTeam)) do
			local count = GetTeamUnitCount(team)
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
		
		if gameoverframe and t >= gameoverframe then
			Spring.GameOver(gamewinners)
		end
		
		if t % frequency == 0 then
			for ateam,_ in pairs(destroyQueue) do
				if not commanderEnds then				
					if teamCommanders[ateam] <= 0 then --safety check, triggers on transferring the last com otherwise
						DestroyAllyTeam(ateam)
					end
				end
			end
			
			for team,_ in pairs(destroySingleQueue) do
				if commanderEnds then				
					if playerCommanders[team] <= 0 then --safety check, triggers on transferring the last com otherwise
						DestroySingleTeam(team)
					end
				end
			end
		end
	end
	
	function gadget:UnitCreated(unitID, unitDefID, team)
		isAlive[unitID] = true
		if commanderTable[unitDefID] then
			local allyTeam = GetUnitAllyTeam(unitID)
			teamCommanders[allyTeam] = teamCommanders[allyTeam] + 1
			playerCommanders[team] = playerCommanders[team] + 1
		end
		return false
	end

	function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
		if commanderTable[unitDefID] then
			local allyTeam = GetUnitAllyTeam(unitID)
			teamCommanders[allyTeam] = teamCommanders[allyTeam] + 1
			playerCommanders[unitTeam] = playerCommanders[unitTeam] + 1
		end
		return false
	end

	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
		
		-- End game and declare winners if a Commander was D-Gunned
		if commanderTable[unitDefID] then
			if dgunTable[weaponDefID] and attackerTeam then
				local health = Spring.GetUnitHealth(unitID)
				local enemyAllyID = select(6,Spring.GetTeamInfo(attackerTeam))
				if teamCommanders[enemyAllyID] <= 1 and health <= 0 and (not AreTeamsAllied(unitTeam, attackerTeam)) then
					if not gameHasEnded then
						removeContester(enemyAllyID)
						if checkWinners() then
							Echo("Game ends: last team commander d-gunned enemy commander")
							gameHasEnded = true
						end
					end
				end
			end
		end
		return false
	end

	function gadget:UnitDestroyed(unitID, unitDefID, team)
		isAlive[unitID] = nil
		
		if commanderTable[unitDefID] then
			local allyTeam = GetUnitAllyTeam(unitID)
			teamCommanders[allyTeam] = teamCommanders[allyTeam] - 1
			playerCommanders[team] = playerCommanders[team] - 1
		
			-- End game and declare winners if last commander dies
			if commanderEnds then -- implement classic commander ends option
				if playerCommanders[team] <= 0 then
					killX, _, killZ = GetUnitPosition(unitID)
					destroySingleQueue[team] = true
					if teamCommanders[allyTeam] <= 0 then
						if not gameHasEnded then
							removeContester(allyTeam)
							if checkWinners() then
								Echo("Game ends: last commander is killed")
								gameHasEnded = true
							end
						end
					end
				end
				
			else -- team comends option
				if teamCommanders[allyTeam] <= 0 then
					killX, _, killZ = GetUnitPosition(unitID)
					destroyQueue[allyTeam] = true
					if not gameHasEnded then
						removeContester(allyTeam)
						if checkWinners() then
							Echo("Game ends: last team commander is killed")
							gameHasEnded = true
						end
					end
				end
			end
		end
		return false
	end

	function gadget:UnitTaken(unitID, unitDefID, team)
		if isAlive[unitID] and commanderTable[unitDefID] then
			local allyTeam = GetUnitAllyTeam(unitID)
			teamCommanders[allyTeam] = teamCommanders[allyTeam] - 1
			playerCommanders[team] = playerCommanders[team] - 1 
			if teamCommanders[allyTeam] <= 0 then
				destroyQueue[allyTeam] = true
			end
			if modOptions.mode == COMMANDER then
				if playerCommanders[team] <= 0 then
					destroySingleQueue[team] = true
				end
			end
		end
		return false
	end
else
	--UNSYNCED
	return false
end
