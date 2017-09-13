function gadget:GetInfo()
  return {
    name      	= "gaia wildlife",
    desc      	= "Green, grazers and graze eaters ",
    author    	= "res (based on original critters from knorke)",
    date      	= "10-8-2017",
    license 	= "GNU GPL, v3 or later",
    layer     	= -99, --negative, otherwise wildlife do not disappear on death 
    enabled   	= true,
	}
end

--[[

Description:

	The map gets populated with species (roles) that grow, procreate, forage, predate and die (of age and by eaten)
	All species can be present (max 6 per area) or a selection. All species can be used as mobile or as immobile
	units theoretically. Only the roles food1 and food2 are set default immobile and growing with time. The roles
	prey1 and prey2 roles do foraging on maximal two food names (unitnames) and likewise the pred1 and pred2 roles
	do predation on maximal 2. This means that when two areas with defined species carry for different roles the 
	same names it can be possible that preys in one area predate the predators in another area. (in this case the 
	predators would be set as food in area 1 and preys would be able to reach area 2) By default wildlife is 
	selectable which makes it possible to capture them if the unitDef table of the wildlife allows this. From
	this example it shows that untDefs are important when setting up wildlife. To not overcomplicate the matter to
	much there are default settings for instance for land maps "spawn only trees" or "spawn trees and foragers"
	but for manny others too. These setups can be found in the gaia_wildlife_config file. 
	
	When wildlife exstinct (by either ageing, foraging or predation) after a couple of life cycles a few new individuals
	will be respawned on the original set location. The behavior of wildlife is charactarised by a random patrol in the
	given area. Foraging can only be succesfull if food exist in within the given forage radius. (likewise for predation)
	When predators and preys do succesful predation and foraging respectively then there is a change of procreation and
	else in case of the former a lifespan penalty is given. Food will procreate in a given radius and is limited to a
	number of units by this radius which are also set by default. The forageSucces, procreteSucces and predationSucces
	changes contribute to the overall forage, procreate and predate behavior. These parameters are set default so no
	need to specify them. There are more of these parameters of which the possibilities of this gadget reach near infinity.
	This is a downsite since messing to adjust one behavior with one parameter might have great concequences for
	other behaviors. There are some behaviors between the above evolution as hunting, socialising etc... . These 
	behaviors can be easy made from the functions given in the gadget. (see there for an example)(use candy function)

	TODO
	- setting new circle/box for wildlife babies. 
	- above implementation set through to ofspring if succesfull
]]--

	
-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end 

-- settings
local evolveTimePace			= 337 						-- time between predation procreation moment (191,151, 257, 337)
local maxWildlife				= 500  						-- maximal amount of critters be spawned
local addingAfterExtinction 	= 2							-- respam after area extinction species
local ExtraLifeLost				= 0.5						-- 0.5 default
local makeUnitWildlifeTime		= 20 * evolveTimePace
local actionSpan 				= evolveTimePace * 9/10		-- max time that happenings are delayed to look more natural
local randomTable 				= 0 			
local canCapture				= true 						-- if false units get destroyed when tried to capture
local showBehaviors				= true

-- Global stuff
mapX = Game.mapX
mapY = Game.mapY


-- locals
local numberOfAreas 			= 0
local totalWildlife				= 0
local wildlifeUnits 			= {}						-- wildlife that are currently alive
local prey1EatsFood				= {}
local prey2EatsFood				= {}
local pred1EatsPrey				= {}
local pred2EatsPrey				= {}
local defaultMaxLifespan = {
	food1 = 25 * evolveTimePace, 							-- begin lifespan food1
	prey1 = 20 * evolveTimePace,		
	pred1 = 15 * evolveTimePace,		
	food2 = 25 * evolveTimePace, 		
	prey2 = 20 * evolveTimePace,		
	pred2 = 15 * evolveTimePace			
}
local defaultProcreateLifespan = {
	food1 = 20 * evolveTimePace, 							-- only used and tested	
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
local min					= math.min
local max					= math.max
local wildlifeCon 			= wildlifeConfig[wildlifeConfig[Game.mapName]] or wildlifeConfig[Game.mapName]
local delayedHappenings		= {}


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
	if dataNew["noGrowing"] ~= nil then
		if dataNew.role == "food1" or dataNew.role == "food2" then
			dataNew.noGrowing = true
		else
			dataNew.noGrowing = false
		end		
	end
	if dataNew["immobile"] ~= nil then 
		if dataNew.role == "food1" or dataNew.role == "food2" then
			dataNew.immobile = false
		else
			dataNew.immobile = true
		end	
	end
	if dataNew["NoSelectable"] ~= nil then
		SetUnitNoSelect(unitID, true)
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


function nearest_friend_from_unit(unitID, unitName, radius, unitName2, radius2)
	local radius = radius2 or radius
	local unitname2 = unitname2 or unitname
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
	else 
		return nil
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
	local critters = GetTeamUnits(GaiaTeamID)
	for index, unitID in pairs(critters) do
		if wildlifeUnits[unitID] == nil then
			DestroyUnit(unitID)
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
	for area, all in pairs(wildlifeCon) do
		for role, data in pairs(all) do
			if ((areaNotEmpty[area] == nil) or (areaNotEmpty[area] ~= role)) then 
				for unitName, unitAmount in pairs(data.unitNames) do
					if wildlifeCon[area][role].unitNames[data.name] ~= 0 then
						for i=1, addingAfterExtinction do
							unitID = spawnUnit(data.spawn.dim, unitName, data.spawn.shape, role, data.noGrowing)
							if unitID ~= nil then	
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


function isOnMap(x,z)
	if (0 < x and x < mapX*512) and (0 < z and z < mapY*512) then
		return true
	else
		return false
	end
end


function spawnUnit(dim, unitName, shape, role, noGrowing)
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
	if isOnMap(x,z) then							-- this can be elegant							
		local height = spGetGroundHeight(x, z)
		local unitDef = UnitDefNames[unitName]
		local maxWaterDepth = unitDef["maxWaterDepth"]
		local minWaterDepth = unitDef["minWaterDepth"]
		if (role ~= "food1" and role ~= "food2") and noGrowing == nil then
			if (height < 0 and (minWaterDepth + height < 0 and (-maxWaterDepth < height and maxWaterDepth~=0))) or (height > 0 and (minWaterDepth == 0)) then
				unitID = CreateUnit(unitName, x, height, z, 0, GaiaTeamID)
			else
				return nil
			end
		elseif ((role == "food1" or role == "food2") and noGrowing == nil) or ((role ~= "food1" and role ~= "food2") and noGrowing ~= nil) then
			if (height < 0 and (minWaterDepth + height < 0 and (-maxWaterDepth < height and maxWaterDepth~=0))) or (height > 0 and (minWaterDepth == 0)) then
				unitID = CreateUnit(unitName, x, height, z, 0, GaiaTeamID)
				Enable(unitID)
				local radius = GetUnitRadius(unitID)  
				SetPosition(unitID, x, height - radius, z)
			else
				return nil
			end
		else
			if (height < 0 and (minWaterDepth + height < 0 and (-maxWaterDepth < height and maxWaterDepth~=0))) or (height > 0 and (minWaterDepth == 0)) then
				unitID = CreateUnit(unitName, x, height, z, 0, GaiaTeamID)
			else
				return nil
			end
		end
		return unitID
	else
		return nil
	end
end


function eating(tableEaten)
	for individual, dinner in pairs(tableEaten) do
		if wildlifeUnits[individual] ~= nil then
			randomPatrol(individual, wildlifeUnits[individual].spawn.dim, wildlifeUnits[individual].spawn.shape)
		else
			DestroyUnit(individual)
		end
		DestroyUnit(dinner)
		wildlifeUnits[dinner] = nil
	end
end


function onMap(coor, method, shape) -- only box
	shape = shape or "box"
	local coordinates = {} 
	if method == "point" then
		coordinates.x = min(max(0, coor.x1), mapX*512)
		coordinates.z = min(max(0, coor.z1), mapX*512)
		coordinates.y = spGetGroundHeight(x, z)
	else
		if shape == "box" then
			coordinates.x1 = min(max(0, coor.x1), mapX*512) 
			coordinates.x2 = min(max(0, coor.x2), mapX*512) 
			coordinates.z1 = min(max(0, coor.z1), mapY*512)
			coordinates.z2 = min(max(0, coor.z2), mapY*512)
		else 
			local newCoor = onMap({x1 = coor.x - coor.r, z1 = coor.z - coor.r, x2 = coor.x + coor.r , z2 =  coor.z + coor.r})
			local xWidth = newCoor.x2-newCoor.x1
			local zWidth = newCoor.z2-newCoor.z1
			local newRadius = min(xWidth, zWidth)/2
			coordinates.r = newRadius
			coordinates.x = newCoor.x1 + newRadius
			coordinates.z = newCoor.z1 + newRadius
		end
	end
	return coordinates
end
	
	
function agingAndBehavior(unitID, data)
	if data.lifespan > 0 then
		delayedHappenings[#delayedHappenings+1] = {delay = random(1,floor(actionSpan/4)), unitID = unitID, action = behave}
	else
		DestroyUnit(unitID)
		wildlifeUnits[unitID] = nil
	end
end


-- behaviors set further down 
function behave(unitID, data)
	if showBehaviors == true then
		local behaviors = {}
		if data.role == "food1" or data.role == "food2" then
			behaviors[1] = socialise
			behaviors[2] = hunt
			behaviors[3] = fight
			behaviors[4] = wanderAroundDinner
		elseif data.role == "prey1" or data.role == "prey2" then
			behaviors[1] = socialise
			behaviors[2] = hunt
			behaviors[3] = fight
			behaviors[4] = wanderAroundDinner		
		elseif data.role == "pred1" or data.role == "pred2" then
			behaviors[1] = socialise
			behaviors[2] = hunt
			behaviors[3] = fight
			behaviors[4] = wanderAroundDinner		
		end
		local index = random(1,#behaviors)
		behaviors[index](unitID, data)
	end
end


function oneDelayRecur() 
	eating(prey1EatsFood)
	prey1EatsFood = {}
	eating(pred1EatsPrey)
	pred1EatsPrey = {}
	eating(prey2EatsFood)
	prey2EatsFood = {}
	eating(pred2EatsPrey)
	pred2EatsPrey = {}
	for unitID, data in pairs(wildlifeUnits) do
		wildlifeUnits[unitID].lifespan = data.lifespan - (0.5 * evolveTimePace + ExtraLifeLost * random(1, evolveTimePace))
		agingAndBehavior(unitID, data)
	end
	local critters = GetTeamUnits(GaiaTeamID)
	for index, unitID in pairs(critters) do
		if wildlifeUnits[unitID] == nil then
			DestroyUnit(unitID)
		end
	end
end
 

function firstTwoDelayrecur()
	for unitID, data in pairs(wildlifeUnits) do
		wildlifeUnits[unitID].lifespan = data.lifespan - (0.5 * evolveTimePace + ExtraLifeLost * random(1, evolveTimePace))
		local rdm = random(1,actionSpan)
		if data.role == "food1" then
			if (data.lifespan > 0) then	
				if (data.lifespan < 20 * evolveTimePace) then
					delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = procreateFood}
				end
				if data.lifespan < 20 * evolveTimePace and data.noGrowing == nil then
					delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = growingFood}
				end
			else
				delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = DestroyUnit}
			end
		end
		if data.role == "prey1" then					
			if data.lifespan > 0 then
				delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = foragingAndProcreation}
			else
				delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = DestroyUnit}
			end
		end
		if data.role == "pred1" then
			if data.lifespan > 0 then
				if (data.lifespan < 20 * evolveTimePace) then
					delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = predationAndProcreation}
				end
			else
				delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = DestroyUnit}
			end
		end
	end
end


function secondTwoDelayRecur()
	for unitID, data in pairs(wildlifeUnits) do
		wildlifeUnits[unitID].lifespan = data.lifespan - (0.5 * evolveTimePace + ExtraLifeLost * random(1, evolveTimePace))
		local rdm = random(1,actionSpan)
		if data.role == "food2" then
			if (data.lifespan > 0) then	
				if (data.lifespan < 20 * evolveTimePace) then
					delayedHappenings[#delayedHappenings+1] = {delay = rdm, action = procreateFood}
				end
				if data.lifespan < 20 * evolveTimePace and data.noGrowing == nil then 
					delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = growingFood}
				end
			else
				delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = DestroyUnit}
			end
		end
		if data.role == "prey2" then					
			if data.lifespan > 0 then
				delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = foragingAndProcreation}
			else
				delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = DestroyUnit}
			end
		end
		if data.role == "pred2" then
			if data.lifespan > 0 then
				if (data.lifespan < 20 * evolveTimePace) then
					delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = predationAndProcreation}
				end
			else
				delayedHappenings[#delayedHappenings+1] = {delay = rdm, unitID = unitID, action = DestroyUnit}
			end
		end
	end
end


function updateDelayedHappenings(delayedHappenings) 
	for i, happening in ipairs(delayedHappenings) do 
		if wildlifeUnits[happening.unitID] ~= nil then
			if happening.delay > 0 then
				delayedHappenings[i].delay = happening.delay - 1
			else
				local unitID = happening.unitID
				if happening.action == DestroyUnit then
					happening.action(unitID)
					wildlifeUnits[unitID] = nil
				elseif happening.action == randomPatrol then
					randomPatrol(unitID, wildlifeUnits[unitID].spawn.dim, wildlifeUnits[unitID].spawn.shape)
				else
					happening.action(unitID, wildlifeUnits[unitID])
				end
				table.remove(delayedHappenings, i)
			end
		end
	end
end

--[[
		
	Below the functions that make up behaviors (if added more care for not let them greate delete new units)
]]

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
				local newCoor = onMap({r = data.radius, z = z, x = x}, "area", "circle")
				uID = spawnUnit({r = newCoor.r, x = newCoor.x, z = newCoor.z}, data.name, "circle", data.role, data.noGrowing)
				babyData = copyTable(data)
				-- might wanna adjust babydata 
				if uID ~= nil then
					randomPatrol(uID, data.spawn.dim, data.spawn.shape)
					makeUnitWildlife(uID, babyData)
				end
			end
		end
	end
end


function foragingAndProcreation(unitID, data)
	nearest = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["food1"].name, data.radius, wildlifeCon[data.area]["food2"].name, nil)
	if nearest ~= nil then
		wildlifeUnits[nearest] = nil
		local x, y, z = GetUnitPosition(nearest)
		GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
		GiveOrderToUnit(nearest, CMD.MOVE, {x, y, z}, {})
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
		local newCoor = onMap({r = data.maxInRadius, z = z, x = x}, "area", "circle")
		local dim = {r = newCoor.r, x = newCoor.x, z = newCoor.z}
		uID = spawnUnit(dim, data.name, shape, data.role, data.noGrowing)
		if uID ~= nil then
			babyData = copyTable(data)
			-- might wanna adjust babydata
			if data.spawn.shape == "circle" then
				randomPatrol(uID, data.spawn.dim, data.spawn.shape)
				makeUnitWildlife(uID, babyData)
			else
				randomPatrol(uID, data.spawn.dim, data.spawn.shape)
				makeUnitWildlife(uID, babyData)
			end	
		end
	end
end


function procreatePred(unitID, data)
	if random() < data.procreatSucces then
		local x, y, z = GetUnitPosition(unitID)
		local shape = "circle"
		local newCoor = onMap({r = data.maxInRadius, z = z, x = x}, "area", "circle")
		local dim = {r = newCoor.r, x = newCoor.x, z = newCoor.z}
		uID = spawnUnit(dim, data.name, shape, data.role, data.noGrowing)
		if uID ~= nil then
			babyData = copyTable(data)
			-- might wanna adjust babydata
			if wildlifeUnits[unitID].shape == "circle" then
				randomPatrol(uID, data.spawn.dim, data.spawn.shape)
				makeUnitWildlife(uID, babyData)
			else
				randomPatrol(uID, data.spawn.dim, data.spawn.shape) 
				makeUnitWildlife(uID, babyData)
			end
		end
	end
end


function predationAndProcreation(unitID, data)
	if random() < data.predationSucces then
		prey = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["prey1"].name, data.radius, wildlifeCon[data.area]["prey2"].name, nil)
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


function patrolAroundSame(unitID, data)
	toPatrolAround = nearest_friend_from_unit(unitID, wildlifeCon[data.area][data.role].name, data.radius, nil, 1000)
	if toPatrolAround ~= nil then
		local x, y, z = GetUnitPosition(toPatrolAround)
		if x~=nil then
			local coor =  onMap({x1 = x - 200, z1 = z - 200, x2 = x + 200 , z2 = z + 200}, "area")
			randomPatrol(unitID, coor, "box")
		end
	end
end


function patrolAroundDinner(unitID, data)
	if data.role == "prey1" or data.role == "prey2" then
		toPatrolAround = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["food1"].name, data.radius, wildlifeCon[data.area]["food2"].name, 1000)
	elseif data.role == "pred1" or data.role == "pred2" then
		toPatrolAround = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["prey1"].name, data.radius, wildlifeCon[data.area]["prey2"].name, 1000)
	end
	if toPatrolAround ~= nil then
		local x, y, z = GetUnitPosition(toPatrolAround)
		if x ~= nil then
			local coor =  onMap({x1 = x - 200, z1 = z - 200, x2 = x + 200 , z2 = z + 200}, "area")
			randomPatrol(unitID, coor, "box")
		end
	end
end


function guardSameRole(unitID, data)
	toGuard = nearest_friend_from_unit(unitID, wildlifeCon[data.area][data.role].name, data.radius, nil, 1000)
	if toGuard ~= nil then
		GiveOrderToUnit(unitID, CMD.GUARD, {toGuard}, {})
	end
end


function moveToSame(unitID, data)
	toMoveTo = nearest_friend_from_unit(unitID, wildlifeCon[data.area][data.role].name, data.radius, nil, 1000)
	if toMoveTo ~= nil then
		local x, y, z = GetUnitPosition(toMoveTo)
		GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
	end
end


function moveToDinner(unitID, data)
	if data.role == "prey1" or data.role == "prey2" then
		toMoveTo = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["food1"].name, data.radius, wildlifeCon[data.area]["food2"].name, 1000)
	elseif data.role == "pred1" or data.role == "pred2" then
		toMoveTo = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["prey1"].name, data.radius, wildlifeCon[data.area]["prey2"].name, 1000)
	end
	if toMoveTo ~= nil then
		local x, y, z = GetUnitPosition(toMoveTo)
		GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
	end
end


function guardDinner(unitID, data)
	if data.role == "prey1" or data.role == "prey2" then
		toGuard = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["food1"].name, data.radius, wildlifeCon[data.area]["food2"].name, 1000)
	elseif data.role == "pred1" or data.role == "pred2" then
		toGuard = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["prey1"].name, data.radius, wildlifeCon[data.area]["prey2"].name, 1000)
	end
	if toGuard ~= nil then
		GiveOrderToUnit(unitID, CMD.GUARD, {toGuard}, {})
	end
end


function attackDinner(unitID, data)
	if data.role == "prey1" or data.role == "prey2" then
		toattack = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["food1"].name, data.radius, wildlifeCon[data.area]["food2"].name, 1000)
	elseif data.role == "pred1" or data.role == "pred2" then
		toattack = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["prey1"].name, data.radius, wildlifeCon[data.area]["prey2"].name, 1000)
	end
	if toattack ~= nil then
		GiveOrderToUnit(unitID, CMD.ATTACK, {toattack}, {})
	end
end


function attackSame(unitID, data)
	toattack = nearest_friend_from_unit(unitID, wildlifeCon[data.area][data.role].name, data.radius, wildlifeCon[data.area][data.role].name, 1000)
	if toattack ~= nil then
		GiveOrderToUnit(unitID, CMD.ATTACK , {toattack}, {})
	end
end

function destroyUnit()

end

--[[
	This section contains all the behaviors that last one evolvetime (on average) that can be called during
	update time. The allowed used functions (which can be extended) which make up behaviors are:
	
	for all (food, prey, pred)
	-- guardSameRole				looks for a similar unit in range and guard it
	-- patrolAroundSame				looks ... and patrols around the found location (repeat this to keep track of unit)
	-- attackSame					looks ... and attacks it (if unit cant attack this might resolve in guarding behavior)
	-- patrol						patrol original coordinates
	-- moveToSame					move to same in radius
	
	for only prey and pred
	-- moveToDinner					move to dinner in range 
	-- patrolAroundDinner			patrol to dinner in range (keep repeating to follow the unit)
	-- attackDinner					attack dinner in range
	-- guardDinner					guard dinner in range
	
	range is set to 1000 for all these functions. Note that it is important that the behaviors dont span over
	the actionspan time because otherwise the other functions in other time span (procreate.. etc) might behave
	wrongly. Here the time span is around 10 seconds to perform the behaviors. (set to evolvetime)
]]--

function timeSequence(totalActions)
	local totalActions = totalActions
	local timespan = actionSpan
	local timeSpanLeft = actionSpan
	local startTimes = {}
	local beginTime = 1
	for i = 1,totalActions, 1 do
		startTimes[i] = random(beginTime, floor(beginTime + timeSpanLeft/totalActions) )
		beginTime = floor(startTimes[i])
		timeSpanLeft = timespan - beginTime
		totalActions = totalActions - 1
	end
	return startTimes
end

-- all species
function socialise(unitID, data)
	beginTimes = timeSequence(6)
	delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[1], unitID = unitID, action = guardSameRole} 
	if random() < 0.5 then
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[2], unitID = unitID, action = patrolAroundSame} 
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[3], unitID = unitID, action = patrolAroundSame} 	-- repeating to follow the unit
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[4], unitID = unitID, action = guardSameRole}
	else
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[2], unitID = unitID, action = patrolAroundSame} 
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[3], unitID = unitID, action = patrolAroundSame} 	-- repeating to follow the unit
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[4], unitID = unitID, action = moveToSame}
	end
	delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[5], unitID = unitID, action = patrolAroundSame}
	delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[6],unitID = unitID, action = randomPatrol}			-- make them not stay at same spot to much
end

-- all species
function fight(unitID, data)
	beginTimes = timeSequence(10)
	delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[1], unitID = unitID, action = guardSameRole}
	if random() < 0.5 then
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[2], unitID = unitID, action = moveToSame}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[3], unitID = unitID, action = patrolAroundSame}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[4], unitID = unitID, action = moveToSame}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[5], unitID = unitID, action = moveToSame}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[6], unitID = unitID, action = patrolAroundSame}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[7], unitID = unitID, action = moveToSame}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[8], unitID = unitID, action = patrolAroundSame}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[9], unitID = unitID, action = moveToSame}
	else
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[2], unitID = unitID, action = patrolAroundSame}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[3], unitID = unitID, action = attackDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[4], unitID = unitID, action = patrolAroundSame}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[5], unitID = unitID, action = attackDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[6], unitID = unitID, action = patrolAroundSame}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[7], unitID = unitID, action = attackDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[8], unitID = unitID, action = patrolAroundDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[9], unitID = unitID, action = patrolAroundSame}
	end
	delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[10], unitID = unitID, action = randomPatrol} 			-- make them not stay at same spot to much
end

-- prey and predator only
function hunt(unitID, data)
	beginTimes = timeSequence(10)
	delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[1], unitID = unitID, action = attackDinner}
	if random() < 0.5 then
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[2], unitID = unitID, action = moveToDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[3], unitID = unitID, action = patrolAroundDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[4], unitID = unitID, action = moveToDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[5], unitID = unitID, action = moveToDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[6], unitID = unitID, action = patrolAroundDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[7], unitID = unitID, action = moveToDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[8], unitID = unitID, action = patrolAroundDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[9], unitID = unitID, action = moveToDinner}
	else
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[2], unitID = unitID, action = patrolAroundDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[3], unitID = unitID, action = attackDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[4], unitID = unitID, action = patrolAroundDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[5], unitID = unitID, action = attackDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[6], unitID = unitID, action = patrolAroundDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[7], unitID = unitID, action = attackDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[8], unitID = unitID, action = patrolAroundDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[9], unitID = unitID, action = attackDinner}
	end
	delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[10], unitID = unitID, action = randomPatrol} 			-- make them not stay at same spot to much
end


-- pred and prey
function wanderAroundDinner(unitID, data)
	beginTimes = timeSequence(5)
	delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[1], unitID = unitID, action = patrolAroundDinner}
	if random() < 0.5 then
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[2], unitID = unitID, action = moveToDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[3], unitID = unitID, action = randomPatrol}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[4], unitID = unitID, action = moveToDinner}
	else
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[2], unitID = unitID, action = patrolAroundDinner}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[3], unitID = unitID, action = randomPatrol}
		delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[4], unitID = unitID, action = patrolAroundDinner}
	end
	delayedHappenings[#delayedHappenings+1] = {delay = beginTimes[5], unitID = unitID, action = randomPatrol} 			-- make them not stay at same spot to much
end




-------------------------


function gadget:GameFrame(f) 
	updateDelayedHappenings(delayedHappenings)
	if f%(makeUnitWildlifeTime) == 0 then
		addNewWildlife(addingAfterExtinction)
	end
	if f%(floor(makeUnitWildlifeTime/4)) == 0 then
		totalWildlifeCount()
	end 
	if (f%evolveTimePace) == 0 then 
		if (f%2 ~= 0) or (f < evolveTimePace) then
			oneDelayRecur()	
		elseif (f%4 ~= 0) then
			firstTwoDelayrecur()
		else
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
	if (wildlifeConfig[wildlifeConfig[Game.mapName]]==nil) and (wildlifeConfig[Game.mapName] == nil) then
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
					unitID = spawnUnit(data.spawn.dim, data.name, data.spawn.shape, data.role, data.NoGrowing)
					if unitID ~= nil then
						makeUnitWildlife(unitID, data) -- this works also on immobile units
						randomPatrol(unitID, data.spawn.dim, data.spawn.shape)
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
