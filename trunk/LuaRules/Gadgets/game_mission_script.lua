function gadget:GetInfo()
  return {
    name      = "Mission Script Engine",
    desc      = "Runs mission triggers and event scripts",
    author    = "Deadnight Warrior",
    date      = "14 Jul 2012",
    license   = "GNU LGPL, v2 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

local spGetTeamInfo = Spring.GetTeamInfo
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitVectors = Spring.GetUnitVectors
local spGetUnitRadius = Spring.GetUnitRadius
local spSetUnitPosition = Spring.SetUnitPosition

local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitDefID = Spring.GetUnitDefID
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit
local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGetTeamUnitsByDefs = Spring.GetTeamUnitsByDefs
local spEcho = Spring.Echo
local spCreateFeature = Spring.CreateFeature

local modOptions = Spring.GetModOptions()
local gaiaTeamID = Spring.GetGaiaTeamID()
local teams = Spring.GetTeamList()
for i=1, #teams do
	if teams[i] == gaiaTeamID then
		table.remove(teams, i)
		break
	end
end

local floor = math.floor

local triggers, switches = {}, {}
local killCounter, deathCounter = {}, {}
local killCounterType = {}
local gameData, spawnData, missionTriggers, locations = {}, {}, {}, {}

if (gadgetHandler:IsSyncedCode()) then

local function initTriggers()
	for teamID, trig in pairs(missionTriggers) do
		triggers[teamID] = {}
		killCounter[teamID] = {}
		killCounter[teamID]["total"] = 0
		for _, enemyTeam in pairs(teams) do
			killCounter[teamID][enemyTeam] = {}
			killCounter[teamID][enemyTeam]["total"] = 0
		end
		killCounterType[teamID] = {}
		for no, val in pairs(trig) do
			triggers[teamID][no] = {}
			triggers[teamID][no].conditions = {}
			for cond, text in pairs(val.conditions) do
				triggers[teamID][no].conditions[cond] = {}
				local idx = 1
				for w in text:gmatch("[_%w]+") do
					triggers[teamID][no].conditions[cond][idx] = w
					idx = idx + 1
				end
			end
			triggers[teamID][no].actions = {}
			for actn, text in pairs(val.actions) do
				triggers[teamID][no].actions[actn] = {}
				local idx = 1
				for w in text:gmatch("[_%w]+") do
					if w=="Echo" and idx==1 then 
						triggers[teamID][no].actions[actn][1] = w
						triggers[teamID][no].actions[actn][2] = text:sub(6,-1)
						break
					end
					triggers[teamID][no].actions[actn][idx] = w
					idx = idx + 1
				end
			end
			if val.once and val.once == true then
				triggers[teamID][no].once = true
			end
			triggers[teamID][no].wait = 0
		end
	end
	for i, teamID in pairs(teams) do
		deathCounter[teamID] = {}
		deathCounter[teamID]["total"] = 0
	end
	for i=1, 32 do
		switches[i]=false
	end
end

function gadget:Initialize()
	if modOptions and modOptions.mission then
		local mission = "Missions/" .. modOptions.mission ..".lua"
		if VFS.FileExists(mission) then
			gameData, spawnData, missionTriggers, locations = include(mission)
			if gameData.game == Game.modShortName and gameData.minVersion <= Game.modVersion then
				if gameData.map ~= Game.mapName then
					spEcho('Mission "' .. modOptions.mission .. "\" was started on a wrong map or you don't have " .. spawnData.map)
					spEcho("Swiching to standard skirmish mode")
					gadgetHandler:RemoveGadget()
				else
					initTriggers()			-- pre-parse trigger strings
					missionTriggers = nil	-- kill table once not needed
				end
			else
				spEcho('This mission is intended for "' .. gameData.game .. " " .. gameData.minVersion .. '" or newer')
				gadgetHandler:RemoveGadget()				
			end
		else
			spEcho("Mission parameter incorrect or wrong mission file")
			gadgetHandler:RemoveGadget()
		end
	else
		gadgetHandler:RemoveGadget()
	end
end

function gadget:GameStart()
	for _, teamID in pairs(teams) do
		-- set start resources, either from mod options or custom team keys
		Spring.SetTeamResource(teamID, "ms", 0)
		Spring.SetTeamResource(teamID, "es", 0)	

		for _, unitData in pairs(spawnData.teams[teamID]) do
			--local x, z = 16*floor((unitData[2]+8)/16), 16*floor((unitData[3]+8)/16)	-- snap to 16x16 grid, fails for odd footprint sizes
			--local x, z = 8*floor((unitData[2]+4)/8), 8*floor((unitData[3]+4)/8)	-- snap to 8x8 grid
			local x, z = unitData[2], unitData[3]	-- don't snap to grid, not needed if mission dumper was used
			local y = spGetGroundHeight(x, z)
			spCreateUnit(unitData[1], x, y, z, unitData[4], teamID)
		end

		local teamOptions = select(7, spGetTeamInfo(teamID))
		local m = teamOptions.startmetal  or modOptions.startmetal  or 1000
		local e = teamOptions.startenergy or modOptions.startenergy or 1000
		if (m and tonumber(m) ~= 0) then
			--Spring.SetUnitResourcing(commanderID, "m", 0)
			Spring.SetTeamResource(teamID, "m", 0)
			Spring.AddTeamResource(teamID, "m", tonumber(m))
		end
		if (e and tonumber(e) ~= 0) then
			--Spring.SetUnitResourcing(commanderID, "e", 0)
			Spring.SetTeamResource(teamID, "e", 0)
			Spring.AddTeamResource(teamID, "e", tonumber(e))
		end
	end
	for _, featureData in pairs(spawnData.features) do
		local y = spGetGroundHeight(featureData[2], featureData[3])
		spCreateFeature(featureData[1], featureData[2], y, featureData[3], featureData[4], featureData[5])
	end
	local i=1
	while i <= #teams do	-- remove from team list all teams that have no triggers
		if triggers[teams[i]] then
			i=i+1
		else
			table.remove(teams, i)
		end
	end
	if #teams == 0 then
		gadgetHandler:RemoveGadget()	-- this mission has no triggers, we're done
	end
	spawnData = nil		-- kill table once not needed
end

local function testCondition(cond, teamID)
	local comm, type = cond[1], cond[3]
	local qty, idx
	if cond[2] then qty=tonumber(cond[2]) end
	if cond[4] then idx=tonumber(cond[4]) end

	-- Always   - Unconditional trigger
	if comm=="Always" then
		return true

	-- Ctrl quantity (unitname|ANY) [index]
	elseif comm=="Ctrl" then
		local loc = locations[idx]
		local unitsInArea = {}
		if loc==nil then
			if type=="ANY" then
				if qty >= 0 then
					return Spring.GetTeamUnitCount(teamID) >= qty
				else
					return Spring.GetTeamUnitCount(teamID) < qty
				end
			else
				if qty >= 0 then
					return Spring.GetTeamUnitDefCount(teamID, UnitDefNames[type].id) >= qty
				else
					return Spring.GetTeamUnitDefCount(teamID, UnitDefNames[type].id) < qty
				end
			end
		elseif loc.shape == "C" then
			unitsInArea = spGetUnitsInCylinder(loc.X,loc.Z,loc.r,teamID)
		elseif loc.shape == "R" then
			unitsInArea = spGetUnitsInRectangle(loc.X1,loc.Z1,loc.X2,loc.Z2,teamID)
		end
		if type=="ANY" then
			if qty >= 0 then
				return #unitsInArea >= qty
			else
				return #unitsInArea < qty
			end
		else
			local count, uDefID = 0, UnitDefNames[type].id
			for _, unitID in pairs(unitsInArea) do
				if spGetUnitDefID(unitID) == uDefID then
					count = count + 1
				end
			end
			if qty >= 0 then
				return count >= qty
			else
				return count < qty
			end
		end
		
	-- Death quantity (unitname|ANY) [ownerID]
	elseif comm=="Death" then
		local team = idx or teamID
		if type == "ANY" then
			if qty >= 0 then	--total deaths
				return deathCounter[team]["total"] >= qty
			else
				return deathCounter[team]["total"] < qty
			end
		else
			if qty >= 0 then	--deaths by unitname
				return (deathCounter[team][UnitDefNames[type].id] or 0)>= qty
			else
				return (deathCounter[team][UnitDefNames[type].id] or 0) < qty
			end
		end			

	-- Kill quantity (unitname|ANY) [ownerID]
	elseif comm=="Kill" then
		if cond[4] then
			if type == "ANY" then
				if qty >= 0 then	-- total kills by enemy team
					return killCounter[teamID][idx]["total"] >= qty
				else
					return killCounter[teamID][idx]["total"] < qty
				end
			else
				if qty >= 0 then	-- kills by enemy team by unitname
					return (killCounter[teamID][idx][UnitDefNames[type].id] or 0) >= qty
				else
					return (killCounter[teamID][idx][UnitDefNames[type].id] or 0) < qty
				end
			end			
		else
			if type == "ANY" then
				if qty >= 0 then	-- total number of kills
					return killCounter[teamID]["total"] >= qty
				else
					return killCounter[teamID]["total"] < qty
				end
			else
				if qty >= 0 then	-- total number of unitname kills
					return (killCounterType[teamID][UnitDefNames[type].id] or 0) >= qty
				else
					return (killCounterType[teamID][UnitDefNames[type].id] or 0) < qty
				end
			end
		end

	-- Res quantity (M|E|ME)
	elseif comm=="Res" then
		local currentM = Spring.GetTeamResources(teamID, "metal")
		local currentE = Spring.GetTeamResources(teamID, "energy")
		if type=="M" then
			if qty>= 0 then
				return currentM >= qty
			else
				return currentM < qty
			end
		elseif type=="E" then
			if qty>= 0 then
				return currentE >= qty
			else
				return currentE < qty
			end
		elseif type=="ME" then
			if qty>= 0 then
				return currentM >= qty and currentE >= qty
			else
				return currentM < qty and currentE < qty
			end
		else
			return false
		end

	-- Switch number (true|false)
	elseif comm=="Switch" then
		if type=="true" then
			return switches[qty]==true
		elseif type=="false" then
			return switches[qty]==false
		else
			return false
		end

	--Unknown condition
	else
		return false
	end
end

local function testConditions(conditions, teamID)
	for i=1, #conditions do
		if testCondition(conditions[i], teamID)==false then
			return false
		end
	end
	return true
end

local function DoActions(actions, teamID, trigNo)
	for i=1, #actions do
		local actn = actions[i]

		-- Defeat [teamID]
		if actn[1]=="Defeat" then
			Spring.KillTeam(tonumber(actn[2] or teamID))

		-- Echo Any kind of message.
		elseif actn[1]=="Echo" then
			spEcho(actn[2])

		-- Eco quantity (M|E|ME) [teamID]
		elseif actn[1]=="Eco" then
			local team = tonumber(actn[4] or teamID)
			local qty = tonumber(actn[2])
			if actn[3]=="M" then
				if qty>=0 then
					Spring.AddTeamResource(team, "metal", qty)
				else
					Spring.UseTeamResource(team, "metal", 0-qty)
				end
			elseif actn[3]=="E" then
				if qty>=0 then
					Spring.AddTeamResource(team, "energy", qty)
				else
					Spring.UseTeamResource(team, "energy", 0-qty)
				end			
			elseif actn[3]=="ME" then
				if qty>=0 then
					Spring.AddTeamResource(team, "metal", qty)
					Spring.AddTeamResource(team, "energy", qty)
				else
					Spring.UseTeamResource(team, {metal=0-qty, energy=0-qty})
				end			
			end

		-- Give quantity unitname index [teamID]
		elseif actn[1]=="Give" then
			-- TO DO

		-- Kill (unitname|ANY) teamID [index]
		elseif actn[1]=="Kill" then
			local team = tonumber(actn[3])	
			if actn[4] then
				local loc = locations[tonumber(actn[4])]
				if loc.shape == "C" then
					if actn[2]=="ANY" then
						for _, unitID in pairs(spGetUnitsInCylinder(loc.X,loc.Z,loc.r,team)) do
							spDestroyUnit(unitID, false, false, teamID)
						end
					else
						local uDefID = UnitDefNames[actn[2]].id
						for _, unitID in pairs(spGetUnitsInCylinder(loc.X,loc.Z,loc.r,team)) do
							if spGetUnitDefID(unitID) == uDefID then
								spDestroyUnit(unitID, false, false, teamID)
							end
						end
					end
				elseif loc.shape == "R" then
					if actn[2]=="ANY" then
						for _, unitID in pairs(spGetUnitsInRectangle(loc.X1,loc.Z1,loc.X2,loc.Z2,team)) do
							spDestroyUnit(unitID, false, false, teamID)
						end
					else
						local uDefID = UnitDefNames[actn[2]].id
						for _, unitID in pairs(spGetUnitsInRectangle(loc.X1,loc.Z1,loc.X2,loc.Z2,team)) do
							if spGetUnitDefID(unitID) == uDefID then
								spDestroyUnit(unitID, false, false, teamID)
							end
						end
					end
				end
			else
				if actn[2]=="ANY" then
					for _, unitID in pairs(Spring.GetTeamUnits(team)) do
						spDestroyUnit(unitID, false, false, teamID)
					end
				else
					local uDefID = UnitDefNames[actn[2]].id
					for unitDefID, unitIDs in pairs(Spring.GetTeamUnitsSorted(team)) do
						if unitDefID == uDefID then
							for _, unitID in pairs(unitIDs) do
								spDestroyUnit(unitID, false, false, teamID)
							end
							break
						end
					end
				end
			end

		-- Move (unitname|ANY) src dest [teamID]
		elseif actn[1]=="Move" then
			-- TO DO

		-- Switch number (true|false|flip)
		elseif actn[1]=="Switch" then
			local num = tonumber(actn[2])
			if actn[3]=="true" then
				switches[num]=true
			elseif actn[3]=="false" then
				switches[num]=false
			elseif actn[3]=="flip" then
				switches[num] = not (switches[num]==true)
			end

		-- Victory
		elseif actn[1]=="Victory" then
			local allyTeam = select(6,Spring.GetTeamInfo(teamID))
			Spring.GameOver({allyTeam})

		-- Wait time
		elseif actn[1]=="Wait" then
			triggers[teamID][trigNo].wait = tonumber(actn[2])
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	-- don't track gaia team's kills, but if a gaia unit is killed, it counts under per unit type kill
	if attackerID and attackerTeamID and killCounter[attackerTeamID] and attackerTeamID ~= gaiaTeamID and teamID ~= attackerTeamID then
		if teamID ~= gaiaTeamID then	-- don't track per team kills for gaia units
			if killCounter[attackerTeamID][teamID][unitDefID] then -- player's per team per unit type kills
				killCounter[attackerTeamID][teamID][unitDefID] = killCounter[attackerTeamID][teamID][unitDefID] + 1
			else
				killCounter[attackerTeamID][teamID][unitDefID] = 1
			end
			killCounter[attackerTeamID][teamID]["total"] = killCounter[attackerTeamID][teamID]["total"] + 1 -- player's per team kills
		end
		if killCounterType[attackerTeamID][unitDefID] then -- players' per unit type kills
			killCounterType[attackerTeamID][unitDefID] = killCounterType[attackerTeamID][unitDefID] + 1
		else
			killCounterType[attackerTeamID][unitDefID] = 1		
		end
		killCounter[attackerTeamID]["total"] = killCounter[attackerTeamID]["total"] + 1	-- player's total kills
	end
	if teamID ~= gaiaTeamID then	-- don't track deaths of gaia team
		if deathCounter[teamID][unitDefID] then
			deathCounter[teamID][unitDefID] = deathCounter[teamID][unitDefID] + 1	-- per unit type deaths
		else
			deathCounter[teamID][unitDefID] = 1
		end
		deathCounter[teamID]["total"] = deathCounter[teamID]["total"] + 1 -- total deaths
	end
end

function gadget:GameFrame(n)
	-- check triggers once per second, but spread teams accross gameframes, less lag
	-- we assume one player per team and multiple teams per allied AI controlled side
	-- we also assume < 31 teams in total
	-- only one human player, usualy team 0, this is for campaign after all
	local teamID = teams[n%30 + 1]
	if teamID and n>29 then		-- skip first second of game and look for teams with triggers
		local _, _, teamDead = spGetTeamInfo(teamID)
		if teamDead==false then
			local trigger = triggers[teamID]
			local i = 1
			while i <= #trigger do	-- process triggers, can't use for loop due to one-shot triggers
				trigger[i].wait = trigger[i].wait - 1
				if trigger[i].wait <= 0 then	
					if testConditions(trigger[i].conditions, teamID)==true then
						DoActions(trigger[i].actions, teamID, i)
						if trigger[i].once and trigger[i].once==true then
							table.remove(triggers[teamID], i) -- disable one-shot trigger
							i = i - 1	-- prevent skiping a trigger after table removal
						end
					end
				end
				i = i + 1
			end
		else
			table.remove(teams, n%30 + 1)	-- remove dead team from teams list
		end
	end
end

end