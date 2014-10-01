function gadget:GetInfo()
  return {
    name      = "gaia critter units",
    desc      = "units spawn and wander around the map",
    author    = "knorke",
    date      = "2013",
    license   = "horse",
    layer     = -100, --negative, otherwise critters spawned by gadget do not disappear on death (spawned with /give they always die)
    enabled   = true,
	}
end

local mo = Spring.GetModOptions()
--Spring.Echo ("mo.critters:", mo.critters)
if mo and tonumber (mo.critters)==0 then
	Spring.Echo ("gaia_critters.lua: turned off via modoptions")
	gadgetHandler:RemoveGadget(self)
	return
end

local GaiaTeamID  = Spring.GetGaiaTeamID ()

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

local critterConfig = include("LuaRules/Configs/gaia_critters_config.lua")

local critterUnits = {}	--critter units that are currently alive

function gadget:Initialize()
	Spring.Echo ("gaia_critters.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
	if not critterConfig[Game.mapName] then Spring.Echo ("no critter config for this map") return end	
	for key, cC in pairs (critterConfig[Game.mapName]) do
		for unitName, unitAmount in pairs (cC.unitNames) do
			--Spring.Echo ("***"..unitName .. " " .. unitAmount)			
			for i=1, unitAmount do
				local unitID = nil
				if cC.spawnBox then
					local x = math.random (cC.spawnBox.x1, cC.spawnBox.x2)
					local z = math.random (cC.spawnBox.z1, cC.spawnBox.z2)
					unitID = Spring.CreateUnit (unitName,x,100,z, 0, GaiaTeamID)
					if unitID then
						randomPatrolInBox (unitID, cC.spawnBox)
					else
						Spring.Echo("Failed to create " .. unitName)
					end
				end
				if cC.spawnCircle then
					local a = math.rad (math.random (0,360))
					local r = math.random (0, cC.spawnCircle.r)
					local x = cC.spawnCircle.x + (math.sin (a)*r)
					local z = cC.spawnCircle.z + (math.cos (a)*r)
					unitID = Spring.CreateUnit (unitName,x,100,z, 0, GaiaTeamID)
					if unitID then
						randomPatrolInCircle (unitID, cC.spawnCircle)
					else
						Spring.Echo("Failed to create " .. unitName)
					end
				end
				--Spring.Echo ("i:"..i)
				if unitID then
					Spring.SetUnitNeutral(unitID, true)
					Spring.SetUnitNoSelect(unitID, true)
					Spring.SetUnitStealth(unitID, true)
					critterUnits[unitID] = true
				end
			end			
		end		
	end
end


function randomPatrolInBox (unitID, box)
	for i=1,5 do
		local x = math.random (box.x1, box.x2)
		local z = math.random (box.z1, box.z2)
		Spring.GiveOrderToUnit(unitID, CMD.PATROL , {x, 100, z}, {"shift"})
	end
end

function randomPatrolInCircle (unitID, circle)
	for i=1,5 do
		local a = math.rad (math.random (0,360))
		local r = math.random (0, circle.r)
		local x = circle.x + (math.sin (a)*r)
		local z = circle.z + (math.cos (a)*r)	
		Spring.GiveOrderToUnit(unitID, CMD.PATROL , {x, 100, z}, {"shift"})
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	if critterUnits[unitID] then critterUnits[unitID] = nil end
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
