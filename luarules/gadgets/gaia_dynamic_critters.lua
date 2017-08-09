function gadget:GetInfo()
  return {
    name      	= "gaia dynamic critter units",
    desc      	= "predator prey behavior of cons and adv cons around the map",
    author    	= "knorke (original) changes by res",
    date      	= "6-8-2017",
    license 	= "GNU GPL, v3 or later",
    layer     	= -99, --negative, otherwise critters spawned by gadget do not disappear on death (spawned with /give they always die)
    enabled   	= true,
	}
end

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

-- settings
local addingAfterExtinction = 2		-- respam after area extinction species
local evolveTimePace		= 151 	-- time between predation procreation moment (before 257)(higher is better for prey)
local procreatChangePrey	= 0.2	-- 
local procreatChangePred	= 0.5 	-- (only when predation was succes so 0.5 * 0.2 = 0.1)
local predationChange		= 0.4	-- change of succesful predation
local lifeSpanPrey			= 5000	-- begin lifespan prey
local lifeSpanPred			= 5000	-- begin lifespan pred
local procreateLifespan		= 5000	-- Lifspan prey start having babies (procreate safety)
local predLife				= 4000  -- Lifespan whenpredation kicks in (hunger)
local maximumCritters		= 500	-- collusion makes cpu work

-- locals
local total					= 0
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
local critterConfig 		= include("LuaRules/Configs/gaia_dynamic_critters_config.lua")
local critterUnits 			= {}	-- critter units that are currently alive
local critterPrey 			= {} 	-- prey alive
local critterPred 			= {} 	-- preditor alive
local numberOfAreas 		= 0
local critterDied 			= {}
local areaNotEmptyPrey      = {}
local areaNotEmptyPred      = {}
local spGetGroundHeight 	= Spring.GetGroundHeight
local random 				= math.random
local sin, cos 				= math.sin, math.cos
local rad 					= math.rad

local function randomPatrolInBox(unitID, box)
	for i=1,5 do
		local x = random(box.x1, box.x2)
		local z = random(box.z1, box.z2)
		GiveOrderToUnit(unitID, CMD.PATROL , {x, spGetGroundHeight(x, z), z}, {"shift"})
	end
end

local function randomPatrolInCircle(unitID, circle)
	for i=1,5 do
		local a = rad(random(0, 360))
		local r = random(0, circle.r)
		local x = circle.x + r*sin(a)
		local z = circle.z + r*cos(a)
		GiveOrderToUnit(unitID, CMD.PATROL , {x, spGetGroundHeight(x, z), z}, {"shift"})
	end
end


local function makeUnitCritter(unitID, role, loc, unitName, ss)
	SetUnitNeutral(unitID, true)
	SetUnitNoSelect(unitID, true)
	SetUnitStealth(unitID, true)
	critterUnits[unitID] = true
	Spring.SetUnitAlwaysVisible(unitID, true)
	if (role == "prey") then
		critterPrey[unitID] = {lifespan = lifeSpanPrey, area = loc, role = "prey", name = unitName, shape = ss}
	else
		critterPred[unitID] = {lifespan = lifeSpanPred, area = loc, role = "pred", name = unitName, shape = ss}
	end
end


function nearest_friend_from_unit(uID, unitType)
  local nearest_friendID = nil
  local nearest_friend_distance = 9999999999
  local x,y,z = GetUnitPosition(uID)
  local radiusPredation = critterConfig[Game.mapName][critterPred[uID].area]["pred"].predRadius
  friend = GetUnitsInCylinder(x,z, radiusPredation)
  if (friend == nil) then return nil end
	  for i in pairs(friend) do
		if (friend[i] ~= uID and units_allied(friend[i], uID)) then 
			local unitDefID = GetUnitDefID(friend[i])
			if (UnitDefs[unitDefID].name == unitType) then
				local d = GetUnitSeparation(uID, friend[i])
				if (d < nearest_friend_distance) then
					nearest_friend_distance = d
					nearest_friendID = friend[i]
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
  return GetUnitAllyTeam(unitID1) == GetUnitAllyTeam (unitID2)
end


function makeBabyCritter(uID, role, name, shape)
	local x,y,z = GetUnitPosition(uID)
	unitID = CreateUnit(name, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
	if unitID then
		if role == "prey" then
			if shape == "box" then
				randomPatrolInBox(unitID, critterConfig[Game.mapName][critterPrey[uID].area][role].spawnBox)
			else
				randomPatrolInCircle(unitID, critterConfig[Game.mapName][critterPrey[uID].area][role].spawnCircle)
			end
			makeUnitCritter(unitID, role, critterPrey[uID].area, name, shape)
		else
			if shape == "box" then
				randomPatrolInBox(unitID, critterConfig[Game.mapName][critterPred[uID].area][role].spawnBox)
			else
				randomPatrolInCircle(unitID, critterConfig[Game.mapName][critterPred[uID].area][role].spawnCircle)
			end
			makeUnitCritter(unitID, role, critterPred[uID].area, name, shape)
		end
	else
		Echo("Failed to create " .. name)
	end
end


function addNewCritters(addingAfterExtinction)

	local critterUnits = GetTeamUnits(GaiaTeamID)
	total = 0
	for index, unitID in pairs(critterUnits) do
		total = total + 1
		if critterPrey[unitID] ~= nil then
			if critterPrey[unitID].area and critterPrey[unitID].role then
				areaNotEmptyPrey[critterPrey[unitID].area] = critterPrey[unitID].role
			end
		elseif critterPred[unitID] ~= nil then
			if critterPred[unitID].area and critterPred[unitID].role  then
				areaNotEmptyPred[critterPred[unitID].area] = critterPred[unitID].role
			end
		else 
			--Spring.Echo("There is an unit that is not pred nor prey :S") 
			--DestroyUnit(unitID)
			--local unitDefID = GetUnitDefID(unitID)
			--Echo(UnitDefs[unitDefID].name)
		end
	end
	
	local preyPred = nil
	for area, pP in pairs(critterConfig[Game.mapName]) do
		for role, cC in pairs(pP) do
			if role == "prey" then
				preyPred = areaNotEmptyPrey
			else
				preyPred = areaNotEmptyPred
			end
			if ((preyPred[area] == nil) or (preyPred[area] ~= role)) and total < maximumCritters then
				if cC.spawnBox then
					for unitName, unitAmount in pairs(cC.unitNames) do
						for i=1, addingAfterExtinction do
							local unitID = nil
							local x = random(cC.spawnBox.x1, cC.spawnBox.x2)
							local z = random(cC.spawnBox.z1, cC.spawnBox.z2)
							unitID = CreateUnit(unitName, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
							if unitID then
								randomPatrolInBox(unitID, cC.spawnBox)
								makeUnitCritter(unitID, role, area, unitName, "box")
							else
								Echo("Failed to create " .. unitName)
							end
						end
					end
				elseif cC.spawnCircle then	
					for unitName, unitAmount in pairs(cC.unitNames) do
						for i=1, addingAfterExtinction do
							local a = rad(random(0, 360))
							local r = random(0, cC.spawnCircle.r)
							local x = cC.spawnCircle.x + r*sin(a)
							local z = cC.spawnCircle.z + r*cos(a)
							unitID = CreateUnit(unitName, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
							if unitID then
								randomPatrolInCircle(unitID, cC.spawnCircle)
								makeUnitCritter(unitID, role, area, unitName, "circle")
							else
								Echo("Failed to create " .. unitName)
							end
						end
					end
				end
			end
		end
	end
	
	areaNotEmptyPrey = {}
	areaNotEmptyPred = {}
end


function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.dynamic_critters)== 0 then
		Echo("gaia_dynamic_critters.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	end
	
	Echo("gaia_dynamic_critters.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
	if not critterConfig[Game.mapName] then
		Echo("no dynamic critter config for this map")
		gadgetHandler:RemoveGadget(self)
	end	
end


-- spawning critters in game start prevents them from being spawned every time you do /luarules reload
function gadget:GameStart()
	for area, pP in pairs(critterConfig[Game.mapName]) do
		numberOfAreas = numberOfAreas + 1
		for role, cC in pairs(pP) do
			if cC.spawnBox then	
				for unitName, unitAmount in pairs(cC.unitNames) do
					for i=1, unitAmount do
						local x = random(cC.spawnBox.x1, cC.spawnBox.x2)
						local z = random(cC.spawnBox.z1, cC.spawnBox.z2)
						unitID = CreateUnit(unitName, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
						if unitID then
							randomPatrolInBox(unitID, cC.spawnBox)
							makeUnitCritter(unitID, role, area, unitName, "box")
						else
							Echo("Failed to create " .. unitName)
						end
					end
				end
			elseif cC.spawnCircle then
				for unitName, unitAmount in pairs(cC.unitNames) do
					for i=1, unitAmount do
						local a = rad(random(0, 360))
						local r = random(0, cC.spawnCircle.r)
						local x = cC.spawnCircle.x + r*sin(a)
						local z = cC.spawnCircle.z + r*cos(a)
						unitID = CreateUnit(unitName, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
						if unitID then
							randomPatrolInCircle(unitID, cC.spawnCircle)
							makeUnitCritter(unitID, role, area, unitName, "circle")
						else
							Echo("Failed to create " .. unitName)
						end
					end
				end
			end
		end
	end
end


function gadget:GameFrame(f)
	if (f%evolveTimePace) == 0 then 
		if (f%2 == 0) then
			for prey, pred in pairs(critterDied) do
				DestroyUnit(prey)
				if math.random() < procreatChangePred and (total < maximumCritters) then
					makeBabyCritter(pred, "pred", critterPred[pred].name, critterPred[pred].shape)
				end
				if critterPred[pred].shape == "circle" then
					randomPatrolInCircle(pred, critterConfig[Game.mapName][critterPred[pred].area]["pred"].spawnCircle)
				else
					randomPatrolInBox(pred, critterConfig[Game.mapName][critterPred[pred].area]["pred"].spawnBox)
				end
			end
			critterDied = {}
			for unitID, data in pairs(critterPrey) do
				if (data.lifespan > 0) then	
					if (data.lifespan < procreateLifespan) then
						if math.random() < procreatChangePrey and (total < maximumCritters) then
							makeBabyCritter(unitID, "prey", data.name, data.shape)
						end				
					end
					critterPrey[unitID].lifespan = critterPrey[unitID].lifespan - 1 * evolveTimePace - random(1, evolveTimePace)
				else	
					local unitDefID = GetUnitDefID(unitID)
					DestroyUnit(unitID)
					critterPrey[unitID] = nil
					critterUnits[unitID] = nil
				end
			end
			if (f%(4 * evolveTimePace) == 0) then
				addNewCritters(addingAfterExtinction)
			end
		else
			for unitID, data in pairs(critterPred) do
				if data.lifespan > 0 then
					if data.lifespan < predLife then
						if math.random() < predationChange then
							for name,number in pairs(critterConfig[Game.mapName][data.area]["prey"].unitNames) do 
								local nearest = nearest_friend_from_unit(unitID, name)	
								if nearest then
									if critterPrey[nearest] ~= nil then
										critterPrey[nearest] = nil
										critterUnits[nearest] = nil
										critterDied[nearest] = unitID
										x,y,z = GetUnitPosition(nearest)
										GiveOrderToUnit(unitID, CMD.MOVE, {x, spGetGroundHeight(x, z), z}, {})
										GiveOrderToUnit(nearest, CMD.MOVE, {x, spGetGroundHeight(x, z), z}, {})
										critterPred[unitID].lifespan = critterPred[unitID].lifespan + 1 * evolveTimePace + random(1, evolveTimePace)
									end
								else
									critterPred[unitID].lifespan = critterPred[unitID].lifespan - 3 * evolveTimePace - random(1, evolveTimePace)
								end
							end
						else
							critterPred[unitID].lifespan = critterPred[unitID].lifespan - 3 * evolveTimePace - random(1, evolveTimePace)
						end
					else
						critterPred[unitID].lifespan = critterPred[unitID].lifespan - 3 * evolveTimePace - random(1, evolveTimePace)
					end
				else	
					DestroyUnit(unitID)
					critterPred[unitID] = nil
				end
			end
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	if critterUnits[unitID] then 
		critterUnits[unitID] = nil
		if critterPrey[unitID] ~= nil then
			critterPrey[unitID] = nil
		elseif critterPred[unitID] ~= nil then
			critterPred[unitID] = nil
		else
			--Spring.Echo("error????")
		end
	end
end

--http://springrts.com/phpbb/viewtopic.php?f=23&t=30109
function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)	
	--Spring.Echo (CMD[cmdID] or "nil")
	if cmdID and cmdID == CMD.ATTACK then 		
		if cmdParams and #cmdParams == 1 then			
			--Spring.Echo ("target is unit" .. cmdParams[1] .. " #cmdParams=" .. #cmdParams)
			if critterUnits[cmdParams[1]] then 
			--	Spring.Echo ("target is a critter and ignored!") 
				return false 
			end
		end
	end		
	return true
end
