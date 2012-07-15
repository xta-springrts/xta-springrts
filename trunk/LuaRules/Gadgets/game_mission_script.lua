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

local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitVectors = Spring.GetUnitVectors
local spGetUnitRadius = Spring.GetUnitRadius
local spSetUnitPosition = Spring.SetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitDefID = Spring.GetUnitDefID
local spCreateUnit = Spring.CreateUnit
local spDestroyUnit = Spring.DestroyUnit
local modOptions = Spring.GetModOptions()
local gaiaTeamID = Spring.GetGaiaTeamID()
local teams = Spring.GetTeamList()
local floor = math.floor
local triggers = {}
local spawnData, missionTriggers, locations = {}, {}, {}

if (gadgetHandler:IsSyncedCode()) then

local function initTriggers()
	for teamID, trig in pairs(missionTriggers) do
		triggers[teamID] = {}
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
		end
	end
end

function gadget:Initialize()
	if modOptions and modOptions.mission then
		local mission = "Missions/" .. modOptions.mission ..".lua"
		if VFS.FileExists(mission) then
			spawnData, missionTriggers, locations = include(mission)
			if spawnData.map ~= Game.mapName then
				Spring.Echo("Mission '" .. modOptions.mission .. "' was started on a wrong map or you don't have " .. spawnData.map)
				Spring.Echo("Swiching to standard skirmish mode")
				gadgetHandler:RemoveGadget()
			else
				initTriggers()
				missionTriggers = nil	--kill table once not needed
			end
		else
			gadgetHandler:RemoveGadget()
		end
	else
		gadgetHandler:RemoveGadget()
	end
end

function gadget:GameStart()
	for i = 1,#teams do
        local teamID = teams[i]
        -- don't spawn a start unit for the Gaia team
        if (teamID ~= gaiaTeamID) then
			-- set start resources, either from mod options or custom team keys
			Spring.SetTeamResource(teamID, "ms", 0)
			Spring.SetTeamResource(teamID, "es", 0)	
			
			for unitname, pos in pairs(spawnData.teams[teamID]) do
				local x, z = 16*floor((pos[1]+8)/16), 16*floor((pos[2]+8)/16)	-- snap to 16x16 grid
				local y = spGetGroundHeight(x, z)
				spCreateUnit(unitname, x, y, z, pos[3], teamID)
			end

			local teamOptions = select(7, Spring.GetTeamInfo(teamID))
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
    end
	spawnData = nil		--kill table once not needed
end

local function testCondition(cond, teamID)
	local comm, type = cond[1], cond[3]
	local qty, idx
	if cond[2] then qty=tonumber(cond[2]) end
	if cond[4] then idx=tonumber(cond[4]) end
	if comm=="Always" then
		return true
	elseif comm=="Ctrl" then
		local loc = locations[idx]
		local unitsInArea = {}
		if loc==nil then
			unitsInArea = Spring.GetTeamUnitsByDefs(teamID, UnitDefNames[type].id)
		elseif loc.shape == "C" then
			unitsInArea = Spring.GetUnitsInCylinder(loc.X,loc.Z,loc.r,teamID)
		elseif loc.shape == "R" then
			unitsInArea = Spring.GetUnitsInRectangle(loc.X1,loc.Z1,loc.X2,loc.Z2,teamID)
		end
		if type=="ANY" then
			if qty >= 0 then
				return #unitsInArea >= qty
			else
				return #unitsInArea < qty
			end
		else
			local count=0			
			if loc==nil then
				count = #unitsInArea
			else
				for _, unitID in pairs(unitsInArea) do
					if spGetUnitDefID(unitID) == UnitDefNames[type].id then
						count = count + 1
					end
				end
			end
			if qty >= 0 then
				return count >= qty
			else
				return count < qty
			end
		end	
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
		end
	elseif comm=="Kill" then
		--TO DO
		return false
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

local function DoActions(actions, teamID)
	for i=1, #actions do
		local actn = actions[i]
		if actn[1]=="Defeat" then
			Spring.KillTeam(teamID)
		elseif actn[1]=="Echo" then
			Spring.Echo(actn[2])
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
		elseif actn[1]=="Give" then
			--TO DO
		elseif actn[1]=="Kill" then
			local team = tonumber(actn[3])	
			if actn[4] then
				local loc = locations[tonumber(actn[4])]
				if loc.shape == "C" then
					if actn[2]=="ANY" then
						for _, unitID in pairs(Spring.GetUnitsInCylinder(loc.X,loc.Z,loc.r,team)) do
							spDestroyUnit(unitID, false, false, teamID)
						end
					else
						for _, unitID in pairs(Spring.GetUnitsInCylinder(loc.X,loc.Z,loc.r,team)) do
							if spGetUnitDefID(unitID) == UnitDefNames[actn[2]].id then
								spDestroyUnit(unitID, false, false, teamID)
							end
						end
					end
				elseif loc.shape == "R" then
					if actn[2]=="ANY" then
						for _, unitID in pairs(Spring.GetUnitsInRectangle(loc.X1,loc.Z1,loc.X2,loc.Z2,team)) do
							spDestroyUnit(unitID, false, false, teamID)
						end
					else
						for _, unitID in pairs(Spring.GetUnitsInRectangle(loc.X1,loc.Z1,loc.X2,loc.Z2,team)) do
							if spGetUnitDefID(unitID) == UnitDefNames[actn[2]].id then
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
					for unitDefID, unitIDs in pairs(Spring.GetTeamUnitsSorted(team)) do
						if unitDefID == UnitDefNames[actn[2]].id then
							for _, unitID in pairs(unitIDs) do
								spDestroyUnit(unitID, false, false, teamID)
							end
							break
						end
					end
				end
			end
		elseif actn[1]=="Victory" then
			local allyTeam = select(6,Spring.GetTeamInfo(teamID))
			Spring.GameOver({allyTeam})
		end
	end
end

function gadget:GameFrame(n)
	--check triggers once per second, but spread teams accross gameframes, less lag
	--we assume one player per team and multiple teams per allied AI controlled side
	--only one human player, this is for campaign after all
	local teamID = n % 30
	if teams[teamID+1] and teamID ~= gaiaTeamID and n>30 then		--skip first second of game and all dead/gaia teams
		local _, active = Spring.GetPlayerInfo(teamID)
		if active==true then
			local trigger = triggers[teamID]
			for i=1, #trigger do	--process triggers
				if trigger[i].once==nil or trigger[i].once==true then	
					if testConditions(trigger[i].conditions, teamID)==true then
						DoActions(trigger[i].actions, teamID)
						if trigger[i].once and trigger[i].once==true then
							trigger[i].once = false	--disable one shot trigger
						end
					end
				end
			end
		end
	end
end

end
