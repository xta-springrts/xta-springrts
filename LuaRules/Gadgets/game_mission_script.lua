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

local spEcho = Spring.Echo
local spGetGameSeconds = Spring.GetGameSeconds
local spGetGameFrame = Spring.GetGameFrame

local spGetTeamInfo = Spring.GetTeamInfo
local spSetTeamResource = Spring.SetTeamResource
local spAddTeamResource = Spring.AddTeamResource
local spGetTeamResources = Spring.GetTeamResources
local spUseTeamResource = Spring.UseTeamResource

local spGetGroundHeight = Spring.GetGroundHeight

local spGetUnitDefID = Spring.GetUnitDefID
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit
local spTransferUnit = Spring.TransferUnit
local spSetUnitPosition = Spring.SetUnitPosition

local spGetUnitsInCylinder = Spring.GetUnitsInCylinder
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGetTeamUnits = Spring.GetTeamUnits
local spGetTeamUnitsSorted = Spring.GetTeamUnitsSorted
local spGetTeamUnitCount = Spring.GetTeamUnitCount
local spGetTeamUnitDefCount = Spring.GetTeamUnitDefCount

local spCreateFeature = Spring.CreateFeature

local spPlaySoundFile = Spring.PlaySoundFile

local modOptions = Spring.GetModOptions()
local gaiaTeamID = Spring.GetGaiaTeamID()
local teams = Spring.GetTeamList()
for i=1, #teams do
	if teams[i] == gaiaTeamID then
		table.remove(teams, i)
		break
	end
end

local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local pairs = pairs

local triggers, switches, timers = {}, {}, {}
local killCounter, deathCounter = {}, {}
local killCounterType = {}
local gameData, spawnData, missionTriggers, locations = {}, {}, {}, {}

if (gadgetHandler:IsSyncedCode()) then

local function initTriggers()	-- pre-parse triggers
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
				for w in text:gmatch("[%-_%w]+") do
					triggers[teamID][no].conditions[cond][idx] = w
					idx = idx + 1
				end
			end
			triggers[teamID][no].actions = {}
			for actn, text in pairs(val.actions) do
				triggers[teamID][no].actions[actn] = {}
				local idx = 1
				for w in text:gmatch("[%-_%w]+") do
					if idx==1 and w=="Echo" or w=="Play" then 
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
		spSetTeamResource(teamID, "ms", 0)
		spSetTeamResource(teamID, "es", 0)	

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
			spSetTeamResource(teamID, "m", 0)
			spAddTeamResource(teamID, "m", tonumber(m))
		end
		if (e and tonumber(e) ~= 0) then
			spSetTeamResource(teamID, "e", 0)
			spAddTeamResource(teamID, "e", tonumber(e))
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

	-- Ctrl quantity (unitname|ANY) [locIdx]
	elseif comm=="Ctrl" then
		local loc = locations[idx]
		local unitsInArea = {}
		if loc==nil then
			if type=="ANY" then
				if qty >= 0 then
					return spGetTeamUnitCount(teamID) >= qty
				else
					return spGetTeamUnitCount(teamID) < qty
				end
			else
				if qty >= 0 then
					return spGetTeamUnitDefCount(teamID, UnitDefNames[type].id) >= qty
				else
					return spGetTeamUnitDefCount(teamID, UnitDefNames[type].id) < qty
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

	-- Res quantity (M|E|ME) [teamID]
	elseif comm=="Res" then
		local team = tonumber(cond[4] or teamID)
		local currentM = spGetTeamResources(team, "metal")
		local currentE = spGetTeamResources(team, "energy")
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

	-- Time quantity
	elseif comm=="Time" then
		if qty>= 0 then
			return spGetGameSeconds >= qty
		else
			return spGetGameSeconds < qty
		end	
		
	-- Timer number
	elseif comm=="Timer" then
		if timers[qty] then
			return timers[qty]==0
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
					spAddTeamResource(team, "metal", qty)
				else
					spUseTeamResource(team, "metal", 0-qty)
				end
			elseif actn[3]=="E" then
				if qty>=0 then
					spAddTeamResource(team, "energy", qty)
				else
					spUseTeamResource(team, "energy", 0-qty)
				end			
			elseif actn[3]=="ME" then
				if qty>=0 then
					spAddTeamResource(team, "metal", qty)
					spAddTeamResource(team, "energy", qty)
				else
					spUseTeamResource(team, {metal=0-qty, energy=0-qty})
				end			
			end

		-- Give quantity unitname locIdx [teamID]
		elseif actn[1]=="Give" then
			local loc = locations[tonumber(actn[4])]
			local qty = tonumber(actn[2])
			local team = tonumber(actn[5] or teamID)
			local unitname = actn[3]
			local x, z, xr, zr
			if loc.shape == "C" then
				x, z = loc.X, loc.Z
			elseif loc.shape == "R" then
				x, z = (loc.X1 + loc.X2)/2, (loc.Z1 + loc.Z2)/2
			else
				return
			end
			local xs, zs = UnitDefs[UnitDefNames[unitname].id].xsize*8, UnitDefs[UnitDefNames[unitname].id].zsize*8
			xr = ceil(math.sqrt(qty))
			zr = ceil(qty/xr)-1
			local dz, dx = zr/2*zs, (xr-1)/2*xs
			for zp=z-dz, z+dz-zs, zs do
				for xp=x-dx, x+dx, xs do
					local y = spGetGroundHeight(xp,zp)
					spCreateUnit(unitname, xp, y, zp, 0,team)
				end
			end
			local zp = z+dz
			for i=0, qty-xr*zr-1 do
				local xp = x-dx+i*xs
				local y = spGetGroundHeight(xp, zp)
				spCreateUnit(unitname, xp, y, zp, 0, team)
			end

		-- Kill (unitname|ANY) teamID [locIdx]
		elseif actn[1]=="Kill" then
			local team = tonumber(actn[3])	
			if actn[4] then
				local loc = locations[tonumber(actn[4])]
				local unitsInArea = {}
				if loc.shape == "C" then
					unitsInArea = spGetUnitsInCylinder(loc.X,loc.Z,loc.r,team)
				elseif loc.shape == "R" then
					unitsInArea = spGetUnitsInRectangle(loc.X1,loc.Z1,loc.X2,loc.Z2,team)
				end
				if actn[2]=="ANY" then
					for _, unitID in pairs(unitsInArea) do
						spDestroyUnit(unitID, false, false, teamID)
					end
				else
					local uDefID = UnitDefNames[actn[2]].id
					for _, unitID in pairs(unitsInArea) do
						if spGetUnitDefID(unitID) == uDefID then
							spDestroyUnit(unitID, false, false, teamID)
						end
					end
				end
			else
				if actn[2]=="ANY" then
					for _, unitID in pairs(spGetTeamUnits(team)) do
						spDestroyUnit(unitID, false, false, teamID)
					end
				else
					local uDefID = UnitDefNames[actn[2]].id
					for unitDefID, unitIDs in pairs(spGetTeamUnitsSorted(team)) do
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
			local src = locations[tonumber(actn[3])]
			local dest = locations[tonumber(actn[4])]
			local team = tonumber(actn[5] or teamID)
			local allUnitsInArea = {}
			local unitsInArea = {}
			if src.shape == "C" then
				allUnitsInArea = spGetUnitsInCylinder(src.X,src.Z,src.r,team)
			elseif src.shape == "R" then
				allUnitsInArea = spGetUnitsInRectangle(src.X1,src.Z1,src.X2,src.Z2,team)
			end
			if actn[2]=="ANY" then
				unitsInArea = allUnitsInArea
			else
				local uDefID = UnitDefNames[actn[2]].id
				local i = 1
				for _, unitID in pairs(allUnitsInArea) do
					if spGetUnitDefID(unitID) == uDefID then
						unitsInArea[i] = unitID
						i = i + 1
					end
				end
			end
			local xs, zs = 1, 1
			for _, unitID in pairs(unitsInArea) do
				local def = UnitDefs[spGetUnitDefID(unitID)]
				if def.xsize > xs then xs = def.xsize end
				if def.zsize > zs then zs = def.zsize end				
			end
			xs, zs = xs*8, zs*8
			local x, z, xr, zr
			if dest.shape == "C" then
				x, z = dest.X, dest.Z
			elseif dest.shape == "R" then
				x, z = (dest.X1 + dest.X2)/2, (dest.Z1 + dest.Z2)/2
			else
				return
			end
			local qty, i = #unitsInArea, 1
			xr = ceil(math.sqrt(qty))
			zr = ceil(qty/xr)-1
			local dz, dx = zr/2*zs, (xr-1)/2*xs
			for zp=z-dz, z+dz-zs, zs do
				for xp=x-dx, x+dx, xs do
					spSetUnitPosition(unitsInArea[i], xp, zp)
					i = i + 1
				end
			end
			local zp = z+dz
			for j=0, qty-xr*zr-1 do
				local xp = x-dx+j*xs
				spSetUnitPosition(unitsInArea[i], xp, zp)
				i = i + 1
			end

		-- Play soundfile
		elseif actn[1]=="Play" then
			spPlaySoundFile(actn[2])

		-- Share (unitname|ANY) teamID [locIdx]
		elseif actn[1]=="Share" then
			local team = tonumber(actn[3])	
			if actn[4] then
				local loc = locations[tonumber(actn[4])]
				local unitsInArea = {}
				if loc.shape == "C" then
					unitsInArea = spGetUnitsInCylinder(loc.X,loc.Z,loc.r,teamID)
				elseif loc.shape == "R" then
					unitsInArea = spGetUnitsInRectangle(loc.X1,loc.Z1,loc.X2,loc.Z2,teamID)
				end
				if actn[2]=="ANY" then
					for _, unitID in pairs(unitsInArea) do
						spTransferUnit(unitID, team)
					end
				else
					local uDefID = UnitDefNames[actn[2]].id
					for _, unitID in pairs(unitsInArea) do
						if spGetUnitDefID(unitID) == uDefID then
							spTransferUnit(unitID, team)
						end
					end
				end
			else
				if actn[2]=="ANY" then
					for _, unitID in pairs(spGetTeamUnits(teamID)) do
						spTransferUnit(unitID, team)
					end
				else
					local uDefID = UnitDefNames[actn[2]].id
					for unitDefID, unitIDs in pairs(spGetTeamUnitsSorted(teamID)) do
						if unitDefID == uDefID then
							for _, unitID in pairs(unitIDs) do
								spTransferUnit(unitID, team)
							end
							break
						end
					end
				end
			end
			
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

		-- Timer number quantity
		elseif actn[1]=="Timer" then
			timers[tonumber(actn[2])] = tonumber(actn[3])

		-- Victory
		elseif actn[1]=="Victory" then
			local allyTeam = select(6,spGetTeamInfo(teamID))
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
	-- we also assume < 31 teams in total and only one human player, usualy team 0
	-- this is for campaign after all, but should work with more human players in
	-- form of special game modes or LOLmaps
	local index = n%30 + 1
	if index==1 then
		for i in pairs(timers) do	-- timers can have arbitrary indexes, as they are added in-game
			timer[i] = timer[i]-1
		end
	end
	local teamID = teams[index]
	if teamID and n>29 then		-- skip first second of game and look for teams with triggers
		local _, _, teamDead = spGetTeamInfo(teamID)
		if teamDead==false then
			local trigger = triggers[teamID]
			local i = 1
			while i <= #trigger do	-- process triggers, can't use for loop due to one-shot triggers
				if trigger[i].wait <= 0 then	
					if testConditions(trigger[i].conditions, teamID)==true then
						DoActions(trigger[i].actions, teamID, i)
						if trigger[i].once and trigger[i].once==true then
							table.remove(triggers[teamID], i) -- disable one-shot trigger
							i = i - 1	-- prevent skiping a trigger after table removal
						end
					end
				else
					trigger[i].wait = trigger[i].wait - 1			
				end
				i = i + 1
			end
		else
			table.remove(teams, index)	-- remove dead team from teams list
		end
	end
end

else	--UNSYNCED

function gadget:Initialize()
	if modOptions and modOptions.mission then
		local mission = "Missions/" .. modOptions.mission ..".lua"
		if VFS.FileExists(mission) then
			gameData, _, _, locations = include(mission)
			if gameData.game == Game.modShortName and gameData.minVersion <= Game.modVersion then
				if gameData.map ~= Game.mapName then
					gadgetHandler:RemoveGadget()
				else
					local i=1
					while i <= #locations do	-- remove from location list all locations that aren't drawn on ground
						if not locations[i].visible or locations[i].visible==false then
							table.remove(locations, i)
						else
							i=i+1
						end
					end
					if #locations == 0 then
						gadgetHandler:RemoveGadget()	-- there are no locations that need drawing
					end
				end
			else
				gadgetHandler:RemoveGadget()
			end
		else
			gadgetHandler:RemoveGadget()
		end
	else
		gadgetHandler:RemoveGadget()
	end
end

function gadget:DrawWorldPreUnit()
	local alpha = abs(spGetGameFrame() % 60 - 30)/30
	gl.LineWidth(10)
	for i=1, #locations do
		local loc = locations[i]
		if loc.RGB then gl.Color(loc.RGB[1], loc.RGB[2], loc.RGB[3], alpha) else gl.Color(1.0, 1.0, 1.0, alpha) end
		if loc.shape=="C" then
			gl.DrawGroundCircle(loc.X, spGetGroundHeight(loc.X, loc.Z), loc.Z, loc.r-3, 24)
		elseif loc.shape=="R" then
			gl.DrawGroundQuad(loc.X1, loc.Z1, loc.X2, loc.Z2)
		end
	end
end

end