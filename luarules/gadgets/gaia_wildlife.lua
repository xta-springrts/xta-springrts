function gadget:GetInfo()
  return {
    name      	= "gaia wildlife",
    desc      	= "Green, grazers and graze eaters ",
    author    	= "res (many stuf borrowed from knorke",
    date      	= "10-8-2017",
    license 	= "GNU GPL, v3 or later",
    layer     	= -99, --negative, otherwise critters spawned by gadget do not disappear on death (spawned with /give they always die)
    enabled   	= true,
	}
end

--[[

See for full configuration documentation the config file.

Description:

The map gets populated with species that grow, procreate, forage, predate and die (of age and by eaten)
TODO a proper story that include the follow
- wildlife canbe used (captured, reclaimed, etc (be creative))
- many settings iin unitdef determine wildlife behavior (attacking wildlife?)
- wildlife could leave dead structures after being killed on the map as a resource etc...
- 
-
-

]]--

-- TODO do seasons (adjust grow rate trees by seasons)
-- setting new circle/box for wildlife babies. 
-- make predators compete, by age?? succes?
-- option to exlude alternative foodsource (prey1 only eats food1 for instance)

-- TODO experimental
-- Improve predators when offspring of a good predetor (by changing unitdef speed,...)(optional)
-- implement fast growing trees easy foraged and hard foraged trees grow slower
-- above implementation set through to ofspring if succesfull
-- 
	
-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end 

-- settings
local evolveTimePace		= 337 					-- time between predation procreation moment (191,151, 257, 337)
local maxWildlife			= 500  					-- maximal amount of critters be spawned
local addingAfterExtinction = 2						-- respam after area extinction species
local ExtraLifeLost			= 0.5					-- 0.5 default
local makeUnitWildlifeTime	= 20 * evolveTimePace
local actionSpan 			= evolveTimePace * 9/10	-- max time that happenings are delayed to look more natural

-- more settings
local canCapture			= true 					-- if false units get destroyed when tried to capture

-- Global stuff
mapX = Game.mapX
mapY = Game.mapY

-- might be changed on own risk (some values might need to be in certain range because of dependencies)
-- also possible to change by config file (see config)
local defaultMaxLifespan = {
	food1 = 25 * evolveTimePace, 		-- begin lifespan food1
	prey1 = 20 * evolveTimePace,		
	pred1 = 15 * evolveTimePace,		
	food2 = 25 * evolveTimePace, 		
	prey2 = 20 * evolveTimePace,		
	pred2 = 15 * evolveTimePace			
}
local defaultProcreateLifespan = {
	food1 = 20 * evolveTimePace, 		-- only used and tested	
	prey1 = 20 * evolveTimePace,	
	pred1 = 20 * evolveTimePace,	
	food2 = 20 * evolveTimePace, 	
	prey2 = 20 * evolveTimePace,	
	pred2 = 20 * evolveTimePace	
}
local defaultMaxInRadius = {
	food1 = 9, 		
	prey1 = 9, 
	pred1 = 30,
	food2 = 30,
	prey2 = 30,
	pred2 = 30
}
local defaultProcreatSucces = {
	food1 = 0.7, 		
	prey1 = 0.4, 
	pred1 = 0.3,
	food2 = 0.7,
	prey2 = 0.4,
	pred2 = 0.3
}
local defaultPredationSucces = {
	pred1 = 0.7,
	pred2 = 0.7
}	
local defaultRadius = {
	food1 = 100, 		
	prey1 = 100, 
	pred1 = 200,
	food2 = 200,
	prey2 = 200,
	pred2 = 200
}

-- locals
local numberOfAreas 		= 0
local totalWildlife			= 0
local wildlifeUnits 		= {}					-- wildlife that are currently alive
local prey1EatsFood			= {}
local prey2EatsFood			= {}
local pred1EatsPrey			= {}
local pred2EatsPrey			= {}
local actions 				= {"growing", "procreate", "destroy","forage","predate"}
local delayedHappenings		= {
growing 	= {},
procreate 	= {},
destroy 	= {},
forage 		= {},
predate 	= {},
}
local GetUnitRadius			= Spring.GetUnitRadius
local GetUnitDefDimensions	= Spring.GetUnitDefDimensions
local Enable				= Spring.MoveCtrl.Enable
local SetPosition  			= Spring.MoveCtrl.SetPosition
local GaiaTeamID  			= Spring.GetGaiaTeamID()
local GiveOrderToUnit		= Spring.GiveOrderToUnit
local SetUnitNeutral		= Spring.SetUnitNeutral
local SetUnitNoSelect		= Spring.SetUnitNoSelect
local SetUnitStealth		= Spring.SetUnitStealth
local GetUnitPosition		= Spring.GetUnitPosition
local GetUnitsInCylinder	= Spring.GetUnitsInCylinder
local GetUnitDefID			= Spring.GetUnitDefID
local GetUnitSeparation		= Spring.GetUnitSeparation
local GetUnitAllyTeam		= Spring.GetUnitAllyTeam
local CreateUnit			= Spring.CreateUnit
local GetTeamUnits			= Spring.GetTeamUnits
local Echo					= Spring.Echo
local DestroyUnit			= Spring.DestroyUnit
local wildlifeConfig 		= include("LuaRules/Configs/gaia_wildlife_config.lua")
local spGetGroundHeight 	= Spring.GetGroundHeight
local random 				= math.random
local sin, cos 				= math.sin, math.cos
local rad 					= math.rad
local abs					= math.abs
local floor					= math.floor
local pairs					= pairs
local ipairs				= ipairs

local wildlifeCon			= {}
if wildlifeConfig[wildlifeConfig[Game.mapName]] == nil then
	wildlifeCon		= wildlifeConfig[Game.mapName]
else
	wildlifeCon		= wildlifeConfig[wildlifeConfig[Game.mapName]]
end	


function randomPatrol(unitID, dim, shape)
	if shape == "box" then	
		for i=1,5 do
			local x = random(dim.x1, dim.x2)
			local z = random(dim.z1, dim.z2)
			GiveOrderToUnit(unitID, CMD.PATROL , {x, spGetGroundHeight(x, z), z}, {"shift"})
		end
	else
		for i=1,5 do
			local a = rad(random(0, 360))
			local r = random(0, dim.r)
			local x = dim.x + r*sin(a)
			local z = dim.z + r*cos(a)
			GiveOrderToUnit(unitID, CMD.PATROL , {x, spGetGroundHeight(x, z), z}, {"shift"})
		end
	end
end


function copyTable(t)
  local t2 = {};
  for k,v in pairs(t) do
    if type(v) == "table" then
        t2[k] = copyTable(v);
    else
        t2[k] = v;
    end
  end
  return t2;
end


function makeUnitWildlife(unitID, data)
	SetUnitNeutral(unitID, true)
	--SetUnitNoSelect(unitID, true)
	SetUnitStealth(unitID, true)
	Spring.SetUnitAlwaysVisible(unitID, true)
	local dataNew = nil
	dataNew = copyTable(data)
	if dataNew["maxLifespan"] == nil then
		dataNew.lifespan = defaultMaxLifespan[dataNew.role]
	else
		dataNew.lifespan = dataNew["maxLifespan"]
	end
	if dataNew["procreateLifespan"] == nil then
		dataNew.procreateLifespan = defaultProcreateLifespan[dataNew.role]
	end
	if dataNew["maxInRadius"] == nil then
		dataNew.maxInRadius = defaultMaxInRadius[dataNew.role]
	end
	if dataNew["procreatSucces"] == nil then
		dataNew.procreatSucces = defaultProcreatSucces[dataNew.role]
	end	
	if dataNew["radius"] == nil then
		dataNew.radius = defaultRadius[dataNew.role]
	end	
	if (dataNew.role == "pred1" or dataNew.role == "pred2") and (dataNew["predationSucces"] == nil) then
		dataNew.predationSucces = defaultPredationSucces[dataNew.role]
	end
	wildlifeUnits[unitID] = dataNew
end


function nearest_friend_from_unit(unitID, unitName, radius, unitName2)
	unitname2 = unitname2 or unitname
	local nearest_friendID = nil
	local nearest_friend_distance = 9999999999
	local x,y,z = GetUnitPosition(unitID)
	friend = GetUnitsInCylinder(x,z, radius)
	if (friend == nil) then return nil end
		for i in pairs(friend) do
			if (friend[i] ~= unitID and units_allied(friend[i], unitID)) then 
				local unitDefID = GetUnitDefID(friend[i])
				if ((UnitDefs[unitDefID].name == unitName) or (UnitDefs[unitDefID].name == unitName2)) and wildlifeUnits[friend[i]]~= nil then
					if wildlifeUnits[friend[i]].lifespan > 15 * evolveTimePace then
						local d = GetUnitSeparation(unitID, friend[i])
						if (d < nearest_friend_distance) then
							nearest_friend_distance = d
							nearest_friendID = friend[i]
						end
					end
				end
			end
		end
	if (nearest_friendID~=nil) then
		local rx,ry,rz = GetUnitPosition(nearest_friendID)
		return nearest_friendID, rx,ry,rz, nearest_friend_distance
	else return nil
	end
end


function units_allied(unitID1, unitID2)
  return GetUnitAllyTeam(unitID1) == GetUnitAllyTeam(unitID2)
end


function totalWildlifeCount()
	totalWildlife = 0
	for unitID, data in pairs(wildlifeUnits) do
		if data == nil or data.area == nil or data.role == nil then
		else
			totalWildlife = totalWildlife + 1
		end
	end
end
	

function addNewWildlife(addingAfterExtinction)

	-- first erasing some stuff maybe
	local critters = GetTeamUnits(GaiaTeamID)
	for index, unitID in pairs(critters) do
		if wildlifeUnits[unitID] == nil then
			DestroyUnit(unitID)
			--Echo(unitID, "erased manually")
		end
	end

	totalWildlife = 0
	local areaNotEmpty = {}
	for unitID, data in pairs(wildlifeUnits) do
		if data == nil or data.area == nil or data.role == nil then
		else
			totalWildlife = totalWildlife + 1
			areaNotEmpty[data.area] = data.role
		end
	end

	-- MAYBE THIS GOES WRONG IF ONE ROLE IS NOT SPECIFIED
	for area, all in pairs(wildlifeCon) do
		for role, data in pairs(all) do
			if ((areaNotEmpty[area] == nil) or (areaNotEmpty[area] ~= role)) then -- and totalWildlife < maxWildlife then YHIS IS ONLY LITTLE CONTRIBUTION
				for unitName, unitAmount in pairs(data.unitNames) do
					-- All roles need to bespecified otherwise some where is an ERROR
					if wildlifeCon[area][role].unitNames[data.name] ~= 0 then
						for i=1, addingAfterExtinction do
							unitID = spawnUnit(data.spawn.dim, unitName, data.spawn.shape, role)
							if unitID ~= nil then	
								if role == "food1" and unitID ~= nil then
									makeUnitWildlife(unitID, data) 
								else
									makeUnitWildlife(unitID, data)
									randomPatrol(unitID, data.spawn.dim, data.spawn.shape)
								end
							end
						end
					end
				end
			end
		end
	end
	
end

function isOnMap(x,z)
	if (0 < x and x < mapX*512) and (0 < z and z < mapY*512) then
		return true
	else
		return false
	end
end

function spawnUnit(dim, unitName, shape, role)
	local x
	local z
	if shape == "box" then
		x = random(dim.x1, dim.x2)
		z = random(dim.z1, dim.z2)
	else
		local a = rad(random(0, 360))
		local r = random(0, dim.r)
		x = dim.x + r*sin(a)
		z = dim.z + r*cos(a)
	end
	if isOnMap(x,z) then							-- This might be harse and give procreation near map edge hard with high radius.
		local height = spGetGroundHeight(x, z)
		local unitDef = UnitDefNames[unitName]
		local maxWaterDepth = unitDef["maxWaterDepth"]
		local minWaterDepth = unitDef["minWaterDepth"]
		if role ~= "food1" then
			if (height < 0 and (minWaterDepth + height < 0 and (-maxWaterDepth < height and maxWaterDepth~=0))) or (height > 0 and (minWaterDepth == 0)) then
				unitID = CreateUnit(unitName, x, height, z, 0, GaiaTeamID)
			else
				return nil
			end
		else
			if (height < 0 and (minWaterDepth + height < 0 and (-maxWaterDepth < height and maxWaterDepth~=0))) or (height > 0 and (minWaterDepth == 0)) then
				unitID = CreateUnit(unitName, x, height, z, 0, GaiaTeamID)
				Enable(unitID)
				local radius = GetUnitRadius(unitID) + 15  -- why 15??(works so far)
				SetPosition(unitID, x, height - radius, z)
			else
				return nil
			end
		end
		return unitID
	else
		return nil
	end
end


-- This function can be way more efficient by keep track of the number of neigbours (keep track what happend to neigbour trees)
function procreateFood(unitID, data)
	if (data.lifespan < data.procreateLifespan) then
		local totalWildlifeNeighbours = 0
		local x,y,z = GetUnitPosition(unitID)
		if random() < data.procreatSucces and (totalWildlife < maxWildlife-(maxWildlife/4)) then 
			neighbours = GetUnitsInCylinder(x,z, data.radius)
			if (neighbours ~= nil) then 
				for i in pairs(neighbours) do
					local unitDefID = GetUnitDefID(neighbours[i])
					if neighbours[i] ~= unitID and units_allied(neighbours[i], unitID) and UnitDefs[unitDefID].name == data.name and wildlifeUnits[neighbours[i]]~= nil then 
						totalWildlifeNeighbours = totalWildlifeNeighbours + 1
					end
				end
			end
			if (totalWildlifeNeighbours < data.maxInRadius) then
				uID = spawnUnit({r = data.radius, x = x, z = z}, data.name, "circle", data.role)
				babyData = copyTable(data)
				--babyData[] =          TODO add some new properties to new trees (evolution)(random)
				if uID ~= nil then
					makeUnitWildlife(uID, babyData)
				end
			end
		end
	end
end


function foragingAndProcreation(unitID, data)
	nearest = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["food1"].name, data.radius, wildlifeCon[data.area]["food2"].name)
	if nearest ~= nil then
		wildlifeUnits[nearest] = nil
		local x, y, z = GetUnitPosition(nearest)
		GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
		if data.role == "prey1" then
			prey1EatsFood[unitID] = nearest
		else 
			prey2EatsFood[unitID] = nearest
		end
		procreatePrey(unitID, data)
	else
		wildlifeUnits[unitID].lifespan = data.lifespan - ExtraLifeLost * random(1, evolveTimePace)
	end
end


function procreatePrey(unitID, data)
	if random() < data.procreatSucces and (totalWildlife < maxWildlife) then
		local x, y, z = GetUnitPosition(unitID)
		local shape = "circle"
		local dim = {x=x, z=z, r = data.maxInRadius}
		uID = spawnUnit(dim, data.name, shape, data.role)
		
		-- for now no evolution 
		if uID ~= nil then
			babyData = copyTable(data)
			if data.spawn.shape == "circle" then
				-- local newDim = {x=x, z=z, r = wildlifeCon[data.area]["prey"].spawn.dim.r}
				-- TODO now it uses old radius -->> improvement adds other radius (only to data of babies or also to behavior of babies?)
				-- make this optional? (todo)		
				randomPatrol(uID, data.spawn.dim, data.spawn.shape)
				--makeUnitWildlife(uID, data.role, data.area, data.name, shape, data.radius, newDim, maxLifeSpanPrey)
				--babyData[] =          TODO 
				makeUnitWildlife(uID, babyData)
				
			else
				randomPatrol(uID, data.spawn.dim, data.spawn.shape)
				-- TODO now it uses old radius improvement adds other radius
				--local newDim = {x=x, y=y, r = wildlifeCon[data.area]["prey"].spawn.dim.radius}
				makeUnitWildlife(uID, babyData)
			end	
		end
	end
end


function procreatePred(unitID, data)
	if random() < data.procreatSucces then
		local x, y, z = GetUnitPosition(unitID)
		local shape = "circle"
		local dim = {x=x, z=z, r=data.maxInRadius}
		uID = spawnUnit(dim, data.name, shape, data.role)
		-- again same here, introduce evolution by adjusting predatorSucces, radius, etc (dangerous if randomly applied)
		-- make it depended on neigboring predator (mating)???
		if uID ~= nil then
			babyData = copyTable(data)
			if wildlifeUnits[unitID].shape == "circle" then
				--local newDim = {x=x, z=z, r = wildlifeCon[data.area]["pred"].spawn.dim.r}
				--makeUnitWildlife(uID, data.role, data.area, data.name, shape, data.radius, newDim, maxLifeSpanPred)
				--babyData[] =          TODO 
				randomPatrol(uID, data.spawn.dim, data.spawn.shape)
				makeUnitWildlife(uID, babyData)
			else
				-- TODO now it uses old radius improvement adds other radius
				--local newDim = {x=x, y=y, r = wildlifeCon[data.area]["prey"].spawn.dim.radius}
				--babyData[] =          TODO 
				randomPatrol(uID, data.spawn.dim, data.spawn.shape) -- patrol with new dimentions (evolution)??
				makeUnitWildlife(uID, babyData)
			end
		end
	end
end


function predationAndProcreation(unitID, data)
	if random() < data.predationSucces then
		prey = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["prey1"].name, data.radius, wildlifeCon[data.area]["prey2"].name)
		if prey ~= nil then
			procreatePred(unitID, data)
			wildlifeUnits[prey] = nil
			local x, y, z = GetUnitPosition(prey)
			GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
			GiveOrderToUnit(prey, CMD.MOVE, {x, y, z}, {})		
			if data.role == "pred1" then
				pred1EatsPrey[unitID] = prey
			else 
				pred2EatsPrey[unitID] = prey
			end
		else
			wildlifeUnits[unitID].lifespan = data.lifespan - (ExtraLifeLost * random(1, evolveTimePace))
		end
	end
end


function growingFood(unitID)
	local x, y , z = GetUnitPosition(unitID)
	local groundHeight = spGetGroundHeight(x, z)
	if y <  (groundHeight + 1) then
		local growth = abs(spGetGroundHeight(x, z) - y) * 0.5
		SetPosition(unitID, x, y + growth, z)
	end
end


function eating(tableEaten)
	for individual, dinner in pairs(tableEaten) do
		if wildlifeUnits[individual] ~= nil then
			randomPatrol(individual, wildlifeUnits[individual].spawn.dim, wildlifeUnits[individual].spawn.shape)
		else
			--Echo("eating individual missing and deleted (also dinner) deleted")
			DestroyUnit(individual)
		end
		DestroyUnit(dinner)
		wildlifeUnits[dinner] = nil
	end
end

function checkAgeAndNothing(unitID, data)
	if data.lifespan > 0 then
		-- do nothing
	else
		DestroyUnit(unitID)
		wildlifeUnits[unitID] = nil
		--Echo(unitID, "WHY THE DESTROYUNIT FUNCTION DOESNT WORK HERE?????")
		-- Maybe has to do with spring needs 3 frames to clear the unitID!!!!
		--
		--
		--????????????????????????????????????
		
	end
end


function oneDelayRecur() 
	
	-- update eating 
	eating(prey1EatsFood)
	prey1EatsFood = {}
	
	eating(pred1EatsPrey)
	pred1EatsPrey = {}

	eating(prey2EatsFood)
	prey2EatsFood = {}
	
	eating(pred2EatsPrey)
	pred2EatsPrey = {}
	
	for unitID, data in pairs(wildlifeUnits) do
	
		-- aging for all wildlife
		wildlifeUnits[unitID].lifespan = data.lifespan - (0.5 * evolveTimePace + ExtraLifeLost * random(1, evolveTimePace))

		-- removing age died wildlife
		
		-- food
		if data.role == "food1" then
			checkAgeAndNothing(unitID, data)
		elseif data.role == "food2" then
			checkAgeAndNothing(unitID, data)
		-- prey
		elseif data.role == "prey1" then
			checkAgeAndNothing(unitID, data)
		elseif data.role == "prey2" then
			checkAgeAndNothing(unitID, data)
		
		-- pred
		elseif data.role == "pred1" then
			checkAgeAndNothing(unitID, data)
		elseif data.role == "pred2" then
			checkAgeAndNothing(unitID, data)
		else
			Echo("roleless wildlife?")
		end
	end
	
	--erasing stuff (I NEED THIS BECAUSE THE ABOVE ERASE DOES NOT WORK)
	local critters = GetTeamUnits(GaiaTeamID)
	for index, unitID in pairs(critters) do
		if wildlifeUnits[unitID] == nil then
			DestroyUnit(unitID)
			--Echo("removed", unitID)
		end
	end

end


 

function firstTwoDelayrecur()
	
	for unitID, data in pairs(wildlifeUnits) do
				
		-- aging for all wildlife
		wildlifeUnits[unitID].lifespan = data.lifespan - (0.5 * evolveTimePace + ExtraLifeLost * random(1, evolveTimePace))
		-- food (steady)
		if data.role == "food1" then
			if (data.lifespan > 0) then	
				
				if (data.lifespan < 20 * evolveTimePace) then
					--procreateFood(unitID, data)
					delayedHappenings.procreate[unitID] = {delay = random(1,actionSpan), action = procreateFood}
				end
				
				if data.lifespan < 20 * evolveTimePace then
					--growingFood(unitID)
					delayedHappenings.growing[unitID] = {delay = random(1,actionSpan), action = growingFood}
				end
			else
				--DestroyUnit(unitID)
				--wildlifeUnits[unitID] = nil
				delayedHappenings.destroy[unitID] = {delay = random(1,actionSpan), action = DestroyUnit}
			end
		end
		
		-- prey
		if data.role == "prey1" then					
			if data.lifespan > 0 then
				--foragingAndProcreation(unitID, data)
				delayedHappenings.forage[unitID] = {delay = random(1,actionSpan), action = foragingAndProcreation}
			else
				delayedHappenings.destroy[unitID] = {delay = random(1,actionSpan), action = DestroyUnit}
				--DestroyUnit(unitID)
				--wildlifeUnits[unitID] = nil
			end
			
		end

		-- pred
		if data.role == "pred1" then
			if data.lifespan > 0 then
				if (data.lifespan < 20 * evolveTimePace) then
					--predationAndProcreation(unitID, data)
					delayedHappenings.predate[unitID] = {delay = random(1,actionSpan), action = predationAndProcreation}
				end
			else
				--DestroyUnit(unitID)
				--wildlifeUnits[unitID] = nil
				delayedHappenings.destroy[unitID] = {delay = random(1,actionSpan), action = DestroyUnit}
			end
		end
		
	end
	
end


function secondTwoDelayRecur()
	
	
	for unitID, data in pairs(wildlifeUnits) do
	
	-- aging for all critters
		wildlifeUnits[unitID].lifespan = data.lifespan - (0.5 * evolveTimePace + ExtraLifeLost * random(1, evolveTimePace))
		
		
	-- food (possibly non steady)
		if data.role == "food2" then
			if (data.lifespan > 0) then	
		
				if (data.lifespan < 20 * evolveTimePace) then
					delayedHappenings.procreate[unitID] = {delay = random(1,actionSpan), action = procreateFood}
				end
				
				if data.lifespan < 20 * evolveTimePace then
					--growingFood(unitID)
					--delayedHappenings.growing[unitID] = {delay = random(1,actionSpan), action = growingFood}
				end
			else
				delayedHappenings.destroy[unitID] = {delay = random(1,actionSpan), action = DestroyUnit}
				--DestroyUnit(unitID)
				--wildlifeUnits[unitID] = nil
			end
		end
		
		
		-- prey
		if data.role == "prey2" then					
			if data.lifespan > 0 then
				--foragingAndProcreation(unitID, data)
				delayedHappenings.forage[unitID] = {delay = random(1,actionSpan), action = foragingAndProcreation}
			else
				delayedHappenings.destroy[unitID] = {delay = random(1,actionSpan), action = DestroyUnit}
				--DestroyUnit(unitID)
				--wildlifeUnits[unitID] = nil
			end
			
		end


		-- pred
		if data.role == "pred2" then
			if data.lifespan > 0 then
				if (data.lifespan < 20 * evolveTimePace) then
					--predationAndProcreation(unitID, data)
					delayedHappenings.predate[unitID] = {delay = random(1,actionSpan), action = predationAndProcreation}
				end
			else
				--DestroyUnit(unitID)
				--wildlifeUnits[unitID] = nil
				delayedHappenings.destroy[unitID] = {delay = random(1,actionSpan), action = DestroyUnit}
			end
		end
	
	end
end


function updateDelayedHappenings(delayedHappenings) 
	for i, DelayedAction in ipairs(actions) do 
		for unitID, happening in pairs(delayedHappenings[DelayedAction]) do
			if wildlifeUnits[unitID] ~= nil then
				if happening.delay > 0 then
					delayedHappenings[DelayedAction][unitID].delay = happening.delay - 1
				else
					if DelayedAction == "destroy" then
						happening.action(unitID)
						wildlifeUnits[unitID] = nil
					else
						happening.action(unitID, wildlifeUnits[unitID])
					end
					delayedHappenings[DelayedAction][unitID] = nil
				end
			end
		end	
	end
end


function gadget:GameFrame(f)
	
	-- slowly let happenings execute
	updateDelayedHappenings(delayedHappenings)
	
	-- replace the extinction populations
	if f%(makeUnitWildlifeTime) == 0 then
		addNewWildlife(addingAfterExtinction)
	end
	
	-- keep track of total wildlife
	if f%(floor(makeUnitWildlifeTime/4)) == 0 then
		totalWildlifeCount()
	end 
	
	
	if (f%evolveTimePace) == 0 then 
		
		if (f%2 ~= 0) or (f < evolveTimePace) then

		-- do all the actions which were preformed in the other time spend
			oneDelayRecur()	
			
		elseif (f%4 ~= 0) then
			
			-- do everything involving the first set of food, prey and preds
			firstTwoDelayrecur()
		else
			
			-- do everything for the second set
			secondTwoDelayRecur()
		end
	end

end
 

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	if wildlifeUnits[unitID] ~= nil then 
		wildlifeUnits[unitID] = nil
	end
end


function gadget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	if canCapture == false then
		DestroyUnit(unitID)
	end
	if wildlifeUnits[unitID] ~= nil then 
		wildlifeUnits[unitID] = nil
	end
end


function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if canCapture == false then
		DestroyUnit(unitID)
	end
	if wildlifeUnits[unitID] ~= nil then 
		wildlifeUnits[unitID] = nil
	end
end	


function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.wildlife)== 0 then
		Echo("gaia_wildlife.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	end
	
	Echo("gaia_wildlife.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
	if (wildlifeConfig[wildlifeConfig[Game.mapName]]==nil) or (wildlifeConfig[Game.mapName] == nil) then
		Echo("no wildlife config for this map")
		gadgetHandler:RemoveGadget(self)
	end	
end


function gadget:GameStart()

	for area, all in pairs(wildlifeCon) do
		numberOfAreas = numberOfAreas + 1
		for role, data in pairs(all) do
			for unitName, unitAmount in pairs(data.unitNames) do
				for i=1, unitAmount do
					totalWildlife = totalWildlife + 1
					unitID = spawnUnit(data.spawn.dim, data.name, data.spawn.shape, data.role)
					if unitID ~= nil then
						if role == "food1" then 						-- immobile growing food unit 
							makeUnitWildlife(unitID, data)
						else
							makeUnitWildlife(unitID, data)				-- possibly mobile non growing
							randomPatrol(unitID, data.spawn.dim, data.spawn.shape)
						end
					end
				end
			end
		end
	end
		
end


--http://springrts.com/phpbb/viewtopic.php?f=23&t=30109
function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)	
	--Spring.Echo (CMD[cmdID] or "nil")
	if cmdID and cmdID == CMD.ATTACK then 		
		if cmdParams and #cmdParams == 1 then			
			--Spring.Echo ("target is unit" .. cmdParams[1] .. " #cmdParams=" .. #cmdParams)
			if wildlifeUnits[cmdParams[1]] then 
			--	Spring.Echo ("target is a critter and ignored!") 
				return false 
			end
		end
	end		
	return true
end
