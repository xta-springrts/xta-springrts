function gadget:GetInfo()
  return {
    name      = "gaia dynamic critter units",
    desc      = "predator prey behavior of cons and adv cons around the map",
    author    = "knorke (original) changes by res",
    date      = "2017",
    license = "GNU GPL, v3 or later",
    layer     = -99, --negative, otherwise critters spawned by gadget do not disappear on death (spawned with /give they always die)
    enabled   = true,
	}
end

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

-- settings
local AddingAfterExtintion 	= 3


-- locals
local GaiaTeamID  			= Spring.GetGaiaTeamID()
local critterConfig 		= include("LuaRules/Configs/gaia_dynamic_critters_config.lua")
local critterUnits 			= {}	--critter units that are currently alive
local critterPrey 			= {} --prey species
local critterPred 			= {} --preditor species
local numberOfAreas 		= 0
local critterDied 			= {}
local areaNotEmpty 			= {}
local spGetGroundHeight 	= Spring.GetGroundHeight
local random 				= math.random
local sin, cos 				= math.sin, math.cos
local rad 					= math.rad

local function randomPatrolInBox(unitID, box)
	for i=1,5 do
		local x = random(box.x1, box.x2)
		local z = random(box.z1, box.z2)
		Spring.GiveOrderToUnit(unitID, CMD.PATROL , {x, spGetGroundHeight(x, z), z}, {"shift"})
	end
end

local function randomPatrolInCircle(unitID, circle)
	for i=1,5 do
		local a = rad(random(0, 360))
		local r = random(0, circle.r)
		local x = circle.x + r*sin(a)
		local z = circle.z + r*cos(a)
		Spring.GiveOrderToUnit(unitID, CMD.PATROL , {x, spGetGroundHeight(x, z), z}, {"shift"})
	end
end

local function randomPatrolInCircle2(unitID, circle)
	for i=1,5 do
		local a = rad(random(0, 360))
		local r = random(0, circle.r)
		local x = circle.x + r*sin(a)
		local z = circle.z + r*cos(a)
		Spring.GiveOrderToUnit(unitID, CMD.PATROL , {x, spGetGroundHeight(x, z), z}, {})
	end
end

local function makeUnitCritter(unitID, role, loc, unitName, ss)
	Spring.SetUnitNeutral(unitID, true)
	Spring.SetUnitNoSelect(unitID, true)
	Spring.SetUnitStealth(unitID, true)
	critterUnits[unitID] = true
	if (role == "prey") then
		critterPrey[unitID] = {lifespan = 5000, area = loc, role = "prey", name = unitName, shape = ss}
	else
		critterPred[unitID] = {lifespan = 5000, area = loc, role = "pred", name = unitName, shape = ss}
	end
end


function nearest_friend_from_unit(uID, unitType)
  local nearest_friendID = nil
  local nearest_friend_distance = 9999999999
  local x,y,z = Spring.GetUnitPosition(uID)
  local ually = Spring.GetUnitAllyTeam(uID)
  friend = Spring.GetUnitsInCylinder(x,z, 900)
  if (friend == nil) then return nil end
	  for i in pairs(friend) do
		if (friend[i] ~= uID and units_allied(friend[i], uID)) then 
			local unitDefID =Spring.GetUnitDefID(friend[i])
			if (UnitDefs[unitDefID].name == unitType) then
				local d = Spring.GetUnitSeparation(uID, friend[i])
				if (d < nearest_friend_distance) then
					nearest_friend_distance = d
					nearest_friendID = friend[i]
				 end
			end
		end
	  end
  if (nearest_friendID~=nil) then
    local rx,ry,rz=Spring.GetUnitPosition(nearest_friendID)
    return nearest_friendID, rx,ry,rz, nearest_friend_distance
  else return nil
  end
end


function units_allied(unitID1, unitID2)
  return Spring.GetUnitAllyTeam (unitID1) == Spring.GetUnitAllyTeam (unitID2)
end


function makeBabyCritter(uID, role, name, shape)
	local x,y,z = Spring.GetUnitPosition(uID)
	unitID = Spring.CreateUnit(name, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
	if unitID then
		if role == "prey" then
			if shape == "box" then
				randomPatrolInCircle(unitID, critterConfig[Game.mapName][critterPrey[uID].area][role].spawnBox)
			else
				randomPatrolInCircle(unitID, critterConfig[Game.mapName][critterPrey[uID].area][role].spawnCircle)
			end
			makeUnitCritter(unitID, role, critterPrey[uID].area, name, shape)
		else
			if shape == "box" then
				randomPatrolInCircle(unitID, critterConfig[Game.mapName][critterPred[uID].area][role].spawnBox)
			else
				randomPatrolInCircle(unitID, critterConfig[Game.mapName][critterPred[uID].area][role].spawnCircle)
			end
			makeUnitCritter(unitID, role, critterPred[uID].area, name, shape)
		end
	else
		Spring.Echo("Failed to create " .. name)
	end
end


function addNewCritters(AddingAfterExtintion)

	local unitsCritters = Spring.GetTeamUnits(GaiaTeamID)
	for index, unitID in pairs(unitsCritters) do
		if critterPrey[unitID] ~= nil then
			if critterPrey[unitID].area and critterPrey[unitID].role then
				areaNotEmpty[critterPrey[unitID].area] = critterPrey[unitID].role
			else
				Spring.Echo("why is this nil.. please add the properties to this unit.")
			end
		elseif critterPred[unitID] ~= nil then
			if critterPred[unitID].area and critterPred[unitID].role  then
				areaNotEmpty[critterPred[unitID].area] = critterPred[unitID].role
			else
				Spring.Echo("why is this nil.. please add the properties to this unit.")
			end
		else 
			--Spring.Echo("There is an unit that is not pred nor prey :S") TODO PLEASE FIX THIS STUFFFFFFFFFFF
		end
	end
	
	for area, pP in ipairs(critterConfig[Game.mapName]) do
		for role, cC in pairs(pP) do
			if (areaNotEmpty[area] == nil) or (areaNotEmpty[area] ~= role) then
				if cC.spawnBox then	
					for unitName, unitAmount in ipairs(cC.unitNames) do
						for i=1, AddingAfterExtintion do
							local unitID = nil
							local x = random(cC.spawnBox.x1, cC.spawnBox.x2)
							local z = random(cC.spawnBox.z1, cC.spawnBox.z2)
							unitID = Spring.CreateUnit(unitName, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
							if unitID then
								randomPatrolInBox(unitID, cC.spawnBox)
								makeUnitCritter(unitID, role, area, unitName, "box")
							else
								Spring.Echo("Failed to create " .. unitName)
							end
						end
					end
				elseif cC.spawnCircle then	
					for unitName, unitAmount in pairs(cC.unitNames) do
						for i=1, AddingAfterExtintion do
							local a = rad(random(0, 360))
							local r = random(0, cC.spawnCircle.r)
							local x = cC.spawnCircle.x + r*sin(a)
							local z = cC.spawnCircle.z + r*cos(a)
							unitID = Spring.CreateUnit(unitName, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
							if unitID then
								randomPatrolInCircle(unitID, cC.spawnCircle)
								makeUnitCritter(unitID, role, area, unitName, "circle")
							else
								Spring.Echo("Failed to create " .. unitName)
							end
						end
					end
				end
			end
		end
	end
	
	areaNotEmpty = {}
end


function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.dynamic_critters)== 0 then
		Spring.Echo("gaia_dynamic_critters.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	end
	
	Spring.Echo("gaia_dynamic_critters.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
	if not critterConfig[Game.mapName] then
		Spring.Echo("no dynamic critter config for this map")
		gadgetHandler:RemoveGadget(self)
	end	
end


-- spawning critters in game start prevents them from being spawned every time you do /luarules reload
function gadget:GameStart()
	for area, pP in ipairs(critterConfig[Game.mapName]) do
		numberOfAreas = numberOfAreas + 1
		for role, cC in pairs(pP) do
			if cC.spawnBox then	
				for unitName, unitAmount in ipairs(cC.unitNames) do
					for i=1, unitAmount do
						local unitID = nil
						local x = random(cC.spawnBox.x1, cC.spawnBox.x2)
						local z = random(cC.spawnBox.z1, cC.spawnBox.z2)
						unitID = Spring.CreateUnit(unitName, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
						if unitID then
							randomPatrolInBox(unitID, cC.spawnBox)
							makeUnitCritter(unitID, role, area, unitName, "box")
						else
							Spring.Echo("Failed to create " .. unitName)
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
						unitID = Spring.CreateUnit(unitName, x, spGetGroundHeight(x, z), z, 0, GaiaTeamID)
						if unitID then
							randomPatrolInCircle(unitID, cC.spawnCircle)
							makeUnitCritter(unitID, role, area, unitName, "circle")
						else
							Spring.Echo("Failed to create " .. unitName)
						end
					end
				end
			end
		end
	end
end


function gadget:GameFrame(f)
	if (f%257) == 0 then 
		if (f%2 == 0) then
			for prey, pred in pairs(critterDied) do
				Spring.DestroyUnit(prey)
				if math.random() < .5 then
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
					if (data.lifespan < 4000) then
						if math.random() < .2 then
							makeBabyCritter(unitID, "prey", data.name, data.shape)
						end				
					end
					critterPrey[unitID].lifespan = critterPrey[unitID].lifespan - 2*257
				else	
					local unitDefID = Spring.GetUnitDefID(unitID)
					Spring.DestroyUnit(unitID)
					if unitDefID then
						critterPrey[unitID] = nil
					end
				end
			end
			if (f%(4 * 257) == 0) then
				addNewCritters(AddingAfterExtintion)
			end
		else
			for unitID, data in pairs(critterPred) do
				if data.lifespan > 0 then
					if data.lifespan < 4000 then
						if math.random() < .4 then
							for name,number in pairs(critterConfig[Game.mapName][data.area]["prey"].unitNames) do 
								local nearest = nearest_friend_from_unit(unitID, name)	
								if nearest then
									if critterPrey[nearest] ~= nil then
										critterPrey[nearest] = nil
										critterDied[nearest] = unitID
										x,y,z = Spring.GetUnitPosition(nearest)
										Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, spGetGroundHeight(x, z), z}, {})
										Spring.GiveOrderToUnit(nearest, CMD.MOVE, {x, spGetGroundHeight(x, z), z}, {})
										critterPred[unitID].lifespan = critterPred[unitID].lifespan + 4 * 257
									end
								else
									critterPred[unitID].lifespan = critterPred[unitID].lifespan - 2*257
								end
							end
						else
							critterPred[unitID].lifespan = critterPred[unitID].lifespan - 2*257
						end
					else
						critterPred[unitID].lifespan = critterPred[unitID].lifespan - 2*257
					end
				else	
					Spring.DestroyUnit(unitID)
					critterPred[unitID] = nil
				end
			end
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	if critterUnits[unitID] then 
		critterUnits[unitID] = nil
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
