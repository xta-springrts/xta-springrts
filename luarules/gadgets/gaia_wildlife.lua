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

-- TODO do seasons

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

-- settings
local evolveTimePace		= 337 					-- time between predation procreation moment (191,151, 257, 337)
local maximumTreesInArea	= 9
local procreatSuccesFood	= 0.7   				-- succesrate procreation food
local procreatSuccesPrey	= 0.4   				-- succesrate procreation prey
local predationSucces		= 0.7					--
local procreatSuccesPred	= 0.3					--
local maxWildlife			= 500  					-- maximal amount of critters be spawned
local addingAfterExtinction = 2						-- respam after area extinction species
local ExtraLifeLost			= 0.5

-- might be changed on own risk
local maxLifeSpanFood		= 25 * evolveTimePace 	-- begin lifespan food
local maxLifeSpanPrey		= 20 * evolveTimePace	-- begin lifespan prey
local maxLifeSpanPred		= 15 * evolveTimePace	-- begin lifespan pred
local procreateLifespanFood	= 20 * evolveTimePace
local makeUnitWildlifeTime	= 20 * evolveTimePace

-- locals
local numberOfAreas 		= 0
local totalWildlife			= 0
local wildlifeUnits 		= {}					-- critter units that are currently alive
local preyEatsFood			= {}
local predEatsPrey			= {}
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
local pairs					= pairs
local ipairs				= ipairs
local wildlifeCon			= wildlifeConfig[Game.mapName]


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


function makeUnitWildlife(unitID, unitRole, unitArea, unitName, spawnshape, unitRadius, spawnDim, maxLifeSpan)
	SetUnitNeutral(unitID, true)
	--SetUnitNoSelect(unitID, true)
	SetUnitStealth(unitID, true)
	Spring.SetUnitAlwaysVisible(unitID, true)
	wildlifeUnits[unitID] = {
		lifespan = maxLifeSpan,
		area = unitArea,
		name = unitName,
		shape = spawnshape,
		radius = unitRadius,
		role = unitRole,
		dim = spawnDim
	}
end


function nearest_friend_from_unit(unitID, unitName, radius)
	local nearest_friendID = nil
	local nearest_friend_distance = 9999999999
	local x,y,z = GetUnitPosition(unitID)
	friend = GetUnitsInCylinder(x,z, radius)
	if (friend == nil) then return nil end
		for i in pairs(friend) do
			if (friend[i] ~= unitID and units_allied(friend[i], unitID)) then 
				local unitDefID = GetUnitDefID(friend[i])
				if (UnitDefs[unitDefID].name == unitName) and wildlifeUnits[friend[i]]~= nil then
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


function addNewWildlife(addingAfterExtinction)

	-- first erasing some stuff maybe
	local critters = GetTeamUnits(GaiaTeamID)
	for index, unitID in pairs(critters) do
		if wildlifeUnits[unitID] == nil then
			DestroyUnit(unitID)
			Echo(unitID, "erased manually")
		end
	end

	totalWildlife = 0
	local areaNotEmpty = {}
	for unitID, data in pairs(wildlifeUnits) do
		if data == nil or data.area == nil or data.role == nil then
			Echo("nil")
		else
			totalWildlife = totalWildlife + 1
			areaNotEmpty[data.area] = data.role
		end
	end

	for area, all in pairs(wildlifeCon) do
		for role, data in pairs(all) do
			if ((areaNotEmpty[area] == nil) or (areaNotEmpty[area] ~= role)) and totalWildlife < maxWildlife then
				for unitName, unitAmount in pairs(data.unitNames) do
					for i=1, addingAfterExtinction do
						unitID = spawnUnit(data.spawn.dim, data.spawn.shape, unitName, role, "true")
						if role == "food" then
							makeUnitWildlife(unitID, role, area, unitName, data.spawn.shape, data.radius, data.spawn.dim, maxLifeSpanFood/2)
						elseif role == "prey" then
							makeUnitWildlife(unitID, role, area, unitName, data.spawn.shape, data.radius, data.spawn.dim, maxLifeSpanPrey)
							randomPatrol(unitID, data.spawn.dim, data.spawn.shape)
						else
							makeUnitWildlife(unitID, role, area, unitName, data.spawn.shape, data.radius, data.spawn.dim, maxLifeSpanPred)
							randomPatrol(unitID, data.spawn.dim, data.spawn.shape)
						end
					end
				end
			end
		end
	end
	
end


function spawnUnit(dim, shape, unitName, unitRole, begin)
	if shape == "box" then
		local x = random(dim.x1, dim.x2)
		local z = random(dim.z1, dim.z2)
		unitID = CreateUnit(unitName, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
	else
		local a = rad(random(0, 360))
		local r = random(0, dim.r)
		local x = dim.x + r*sin(a)
		local z = dim.z + r*cos(a)
		unitID = CreateUnit(unitName, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
	end
	if unitRole == "food" then							-- maybe also check for original location
		Enable(unitID)
	end
	if unitRole == "food" and begin ~= "true" then
		local height = 23                             	-- This needs to be something obtained of unit property.
		local x, y , z = GetUnitPosition(unitID)
		SetPosition(unitID, x, y - height, z)
	end 
	return unitID
end


-- This function can be way more efficient by keep track of the number of neigbours (keep track what happend to neigbour trees)
function procreateFood(unitID, data)
	if (data.lifespan < procreateLifespanFood) then
		local totalWildlifeNeighbours = 0
		local x,y,z = GetUnitPosition(unitID)
		if random() < procreatSuccesFood and (totalWildlife < maxWildlife) then
			neighbours = GetUnitsInCylinder(x,z, data.radius)
			if (neighbours ~= nil) then 
				for i in pairs(neighbours) do
					local unitDefID = GetUnitDefID(neighbours[i])
					if neighbours[i] ~= unitID and units_allied(neighbours[i], unitID) and UnitDefs[unitDefID].name == data.name then 
						totalWildlifeNeighbours = totalWildlifeNeighbours + 1
					end
				end
			end
			if (totalWildlifeNeighbours < maximumTreesInArea) then
				uID = spawnUnit({r = data.radius, x = x, z = z}, "circle", data.name, data.role, "false")
				makeUnitWildlife(uID, data.role, data.area, data.name, data.shape, data.radius, data.dim, maxLifeSpanFood)
			end
		end
	end
end


function foragingAndProcreation(unitID, data)
	local nearest = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["food"].name, data.radius)
	if nearest ~= nil then
		wildlifeUnits[nearest] = nil
		local x, y, z = GetUnitPosition(nearest)
		GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
		preyEatsFood[unitID] = nearest
		procreatePrey(unitID, data)
	else
		wildlifeUnits[unitID].lifespan = data.lifespan - ExtraLifeLost * random(1, evolveTimePace)
	end
end


function procreatePrey(unitID, data)
	if random() < procreatSuccesPrey then
		local x, y, z = GetUnitPosition(unitID)
		local begin = false
		local shape = "circle"
		local dim = {x=x, z=z, r=30}
		uID = spawnUnit(dim, shape, data.name, data.role, begin)
		randomPatrol(uID, data.dim, wildlifeUnits[unitID].shape)
		if wildlifeUnits[unitID].shape == "circle" then
			local newDim = {x=x, z=z, r = wildlifeCon[data.area]["prey"].spawn.dim.r}
			--makeUnitWildlife(uID, data.role, data.area, data.name, shape, data.radius, newDim, maxLifeSpanPrey)
			makeUnitWildlife(uID, data.role, data.area, data.name, data.shape, data.radius, data.dim, maxLifeSpanPrey)
		else
			-- TODO now it uses old radius improvement adds other radius
			--local newDim = {x=x, y=y, r = wildlifeCon[data.area]["prey"].spawn.dim.radius}
			makeUnitWildlife(uID, data.role, data.area, data.name, data.shape, data.radius, data.dim, maxLifeSpanPrey)
		end	
	end
end


function procreatePred(unitID, data)
	if random() < procreatSuccesPred then
		local x, y, z = GetUnitPosition(unitID)
		local begin = false
		local shape = "circle"
		local dim = {x=x, z=z, r=30}
		uID = spawnUnit(dim, shape, data.name, data.role, begin)
		randomPatrol(uID, data.dim, wildlifeUnits[unitID].shape)
		if wildlifeUnits[unitID].shape == "circle" then
			local newDim = {x=x, z=z, r = wildlifeCon[data.area]["pred"].spawn.dim.r}
			--makeUnitWildlife(uID, data.role, data.area, data.name, shape, data.radius, newDim, maxLifeSpanPred)
			makeUnitWildlife(uID, data.role, data.area, data.name, data.shape, data.radius, data.dim, maxLifeSpanPred)
		else
			-- TODO now it uses old radius improvement adds other radius
			--local newDim = {x=x, y=y, r = wildlifeCon[data.area]["prey"].spawn.dim.radius}
			makeUnitWildlife(uID, data.role, data.area, data.name, data.shape, data.radius, data.dim, maxLifeSpanPred)
		end	
	end
end


function predationAndProcreation(unitID, data)
	if random() < predationSucces then
		local prey = nearest_friend_from_unit(unitID, wildlifeCon[data.area]["prey"].name, data.radius)
		if prey ~= nil then
			procreatePred(unitID, data)
			wildlifeUnits[prey] = nil
			local x, y, z = GetUnitPosition(prey)
			GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
			GiveOrderToUnit(prey, CMD.MOVE, {x, y, z}, {})
			predEatsPrey[unitID] = prey
		else
			wildlifeUnits[unitID].lifespan = data.lifespan - ExtraLifeLost * random(1, evolveTimePace)
		end
	end
end


function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.wildlife)== 0 then
		Echo("gaia_wildlife.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	end
	
	Echo("gaia_wildlife.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
	if not wildlifeCon then
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
					unitID = spawnUnit(data.spawn.dim, data.spawn.shape, unitName, role, "true")
					if role == "food" then
						makeUnitWildlife(unitID, role, area, unitName, data.spawn.shape, data.radius, data.spawn.dim, maxLifeSpanFood/2)
					elseif role == "prey" then
						makeUnitWildlife(unitID, role, area, unitName, data.spawn.shape, data.radius, data.spawn.dim, maxLifeSpanPrey)
						randomPatrol(unitID, data.spawn.dim, data.spawn.shape)
					else
						makeUnitWildlife(unitID, role, area, unitName, data.spawn.shape, data.radius, data.spawn.dim, maxLifeSpanPred)
						randomPatrol(unitID, data.spawn.dim, data.spawn.shape)
					end
				end
			end
		end
	end
end

 
function gadget:GameFrame(f)
	
	-- replace the extinction populations
	if f%(makeUnitWildlifeTime) == 0 then
		addNewWildlife(addingAfterExtinction)
	end
	
	if (f%evolveTimePace) == 0 then 
		if (f%2 == 0) then
			
			-- first erasing some stuff maybe
			--local critters = GetTeamUnits(GaiaTeamID)
			--for index, unitID in pairs(critters) do
				--if wildlifeUnits[unitID] == nil then
					--DestroyUnit(unitID)
					--Echo(unitID, "erased manually")
				--end
			--end
			
			
			for unitID, data in pairs(wildlifeUnits) do
				
				-- aging for all critters
				wildlifeUnits[unitID].lifespan = data.lifespan - 0.5 * evolveTimePace - ExtraLifeLost * random(1, evolveTimePace)	
				
				-- food
				if data.role == "food" then
					if (data.lifespan > 0) then	
						
						if (data.lifespan < 20 * evolveTimePace) then
							procreateFood(unitID, data)
						end
						
						if data.lifespan < 15 * evolveTimePace then
							local x, y , z = GetUnitPosition(unitID)
							local groundHeight = spGetGroundHeight(x, z)
							if y <  (groundHeight + 1) then
								local growth = abs(spGetGroundHeight(x, z) - y) * 0.5
								SetPosition(unitID, x, y + growth, z)
							end
						end
					else
						DestroyUnit(unitID)
						wildlifeUnits[unitID] = nil
					end
				end
				
				
				-- prey
				if data.role == "prey" then					
					if data.lifespan > 0 then
						foragingAndProcreation(unitID, data)
					else
						DestroyUnit(unitID)
						wildlifeUnits[unitID] = nil
					end
					
				end
			
			
				-- pred
				if data.role == "pred" then
					if data.lifespan > 0 then
						if (data.lifespan < 20 * evolveTimePace) then
							predationAndProcreation(unitID, data)
						end
					else
						DestroyUnit(unitID)
						wildlifeUnits[unitID] = nil
					end
				end

				
			end
		
		else
			
			-- update eating food
			for prey, eatenfood in pairs(preyEatsFood) do
				if wildlifeUnits[prey] ~= nil then
					randomPatrol(prey, wildlifeUnits[prey].dim, wildlifeUnits[prey].shape)
				end
				DestroyUnit(eatenfood)
			end
			preyEatsFood = {}
			
			-- update eating prey
			for pred, eatenprey in pairs(predEatsPrey) do
				if wildlifeUnits[pred] ~= nil then
					randomPatrol(pred, wildlifeUnits[pred].dim, wildlifeUnits[pred].shape)
				end
				DestroyUnit(eatenprey)
			end
			preyEatsFood = {}
		
			for unitID, data in pairs(wildlifeUnits) do
			
				-- aging for all critters
				wildlifeUnits[unitID].lifespan = data.lifespan - 0.5 * evolveTimePace - ExtraLifeLost * random(1, evolveTimePace)
				
				-- food
				if data.role == "food" then
					if data.lifespan > 0 then
						

					else
						DestroyUnit(unitID)
						wildlifeUnits[unitID] = nil
					end
				end
				
				-- prey
				if data.role == "prey" then
					if data.lifespan > 0 then
						

					else
						DestroyUnit(unitID)
						wildlifeUnits[unitID] = nil
					end
				end
				

				-- pred
				if data.role == "pred" then
					if data.lifespan > 0 then
						

					else
						DestroyUnit(unitID)
						wildlifeUnits[unitID] = nil
					end
				end
			
			end
			
			--erasing stuff (WHY???)
			local critters = GetTeamUnits(GaiaTeamID)
			for index, unitID in pairs(critters) do
				if wildlifeUnits[unitID] == nil then
					DestroyUnit(unitID)
				end
			end
		end
	end
end
 

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	if wildlifeUnits[unitID] ~= nil then 
		wildlifeUnits[unitID] = nil
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
