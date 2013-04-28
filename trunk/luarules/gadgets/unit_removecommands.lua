function gadget:GetInfo()
   return {
   version   = "1",
   name      = "Remove commands",
   desc      = "Removes some commands, and adds one",
   author    = "Jools",
   date      = "Apr, 2013", 
   license   = "Public Domain",
   layer     = 0,
   enabled   = true, --enabled by default
   handler   = true, --access to handler
   }
end

local RemoveWait = {
	[UnitDefNames.arm_advanced_radar_tower.id] = true,
	[UnitDefNames.arm_advanced_sonar_station.id] = true,
	[UnitDefNames.arm_air_repair_pad.id] = true,
	[UnitDefNames.arm_cloakable_fusion_reactor.id] = true,
	[UnitDefNames.arm_energy_storage.id] = true,
	[UnitDefNames.arm_floating_metal_maker.id] = true,
	[UnitDefNames.arm_floating_radar.id] = true,
	[UnitDefNames.arm_fusion_reactor.id] = true,
	[UnitDefNames.arm_geothermal_powerplant.id] = true,
	[UnitDefNames.arm_metal_extractor.id] = true,
	[UnitDefNames.arm_metal_maker.id] = true,
	[UnitDefNames.arm_metal_storage.id] = true,
	[UnitDefNames.arm_moho_metal_maker.id] = true,
	[UnitDefNames.arm_moho_mine.id] = true,
	[UnitDefNames.arm_radar_jamming_tower.id] = true,
	[UnitDefNames.arm_radar_tower.id] = true,
	[UnitDefNames.arm_solar_collector.id] = true,
	[UnitDefNames.arm_sonar_station.id] = true,
	[UnitDefNames.arm_targeting_facility.id] = true,
	[UnitDefNames.arm_tidal_generator.id] = true,
	[UnitDefNames.arm_underwater_energy_storage.id] = true,
	[UnitDefNames.arm_underwater_fusion_reactor.id] = true,
	[UnitDefNames.arm_underwater_metal_storage.id] = true,
	[UnitDefNames.arm_underwater_moho_mine.id] = true,
	[UnitDefNames.arm_underwater_tidal_generator.id] = true,
	[UnitDefNames.arm_wind_generator.id] = true,
	[UnitDefNames.core_advanced_radar_tower.id] = true,
	[UnitDefNames.core_advanced_sonar_station.id] = true,
	[UnitDefNames.core_air_repair_pad.id] = true,
	[UnitDefNames.core_cloakable_fusion_power_plant.id] = true,
	[UnitDefNames.core_energy_storage.id] = true,
	[UnitDefNames.core_floating_metal_maker.id] = true,
	[UnitDefNames.core_floating_radar.id] = true,
	[UnitDefNames.core_fusion_power_plant.id] = true,
	[UnitDefNames.core_geothermal_powerplant.id] = true,
	[UnitDefNames.core_light_fusion_power_plant.id] = true,
	[UnitDefNames.core_metal_extractor.id] = true,
	[UnitDefNames.core_metal_maker.id] = true,
	[UnitDefNames.core_metal_storage.id] = true,
	[UnitDefNames.core_moho_metal_maker.id] = true,
	[UnitDefNames.core_moho_mine.id] = true,
	[UnitDefNames.core_radar_jamming_tower.id] = true,
	[UnitDefNames.core_radar_tower.id] = true,
	[UnitDefNames.core_solar_collector.id] = true,
	[UnitDefNames.core_sonar_station.id] = true,
	[UnitDefNames.core_targeting_facility.id] = true,
	[UnitDefNames.core_tidal_generator.id] = true,
	[UnitDefNames.core_underwater_energy_storage.id] = true,
	[UnitDefNames.core_underwater_fusion_power_plant.id] = true,
	[UnitDefNames.core_underwater_metal_storage.id] = true,
	[UnitDefNames.core_underwater_moho_mine.id] = true,
	[UnitDefNames.core_underwater_tidal_generator.id] = true,
	[UnitDefNames.core_wind_generator.id] = true,
	[UnitDefNames.arm_protector.id] = true,
	[UnitDefNames.core_fortitude_missile_defense.id] = true,
	[UnitDefNames.core_resistor.id] = true,
	[UnitDefNames.arm_repulsor.id] = true,
}

local RemoveStop = {
	[UnitDefNames.arm_advanced_radar_tower.id] = true,
	[UnitDefNames.arm_advanced_sonar_station.id] = true,
	[UnitDefNames.arm_air_repair_pad.id] = true,
	[UnitDefNames.arm_cloakable_fusion_reactor.id] = true,
	[UnitDefNames.arm_energy_storage.id] = true,
	[UnitDefNames.arm_floating_metal_maker.id] = true,
	[UnitDefNames.arm_floating_radar.id] = true,
	[UnitDefNames.arm_fusion_reactor.id] = true,
	[UnitDefNames.arm_geothermal_powerplant.id] = true,
	[UnitDefNames.arm_metal_extractor.id] = true,
	[UnitDefNames.arm_metal_maker.id] = true,
	[UnitDefNames.arm_metal_storage.id] = true,
	[UnitDefNames.arm_moho_metal_maker.id] = true,
	[UnitDefNames.arm_moho_mine.id] = true,
	[UnitDefNames.arm_radar_jamming_tower.id] = true,
	[UnitDefNames.arm_radar_tower.id] = true,
	[UnitDefNames.arm_solar_collector.id] = true,
	[UnitDefNames.arm_sonar_station.id] = true,
	[UnitDefNames.arm_targeting_facility.id] = true,
	[UnitDefNames.arm_tidal_generator.id] = true,
	[UnitDefNames.arm_underwater_energy_storage.id] = true,
	[UnitDefNames.arm_underwater_fusion_reactor.id] = true,
	[UnitDefNames.arm_underwater_metal_storage.id] = true,
	[UnitDefNames.arm_underwater_moho_mine.id] = true,
	[UnitDefNames.arm_underwater_tidal_generator.id] = true,
	[UnitDefNames.arm_wind_generator.id] = true,
	[UnitDefNames.core_advanced_radar_tower.id] = true,
	[UnitDefNames.core_advanced_sonar_station.id] = true,
	[UnitDefNames.core_air_repair_pad.id] = true,
	[UnitDefNames.core_cloakable_fusion_power_plant.id] = true,
	[UnitDefNames.core_energy_storage.id] = true,
	[UnitDefNames.core_floating_metal_maker.id] = true,
	[UnitDefNames.core_floating_radar.id] = true,
	[UnitDefNames.core_fusion_power_plant.id] = true,
	[UnitDefNames.core_geothermal_powerplant.id] = true,
	[UnitDefNames.core_light_fusion_power_plant.id] = true,
	[UnitDefNames.core_metal_extractor.id] = true,
	[UnitDefNames.core_metal_maker.id] = true,
	[UnitDefNames.core_metal_storage.id] = true,
	[UnitDefNames.core_moho_metal_maker.id] = true,
	[UnitDefNames.core_moho_mine.id] = true,
	[UnitDefNames.core_radar_jamming_tower.id] = true,
	[UnitDefNames.core_radar_tower.id] = true,
	[UnitDefNames.core_solar_collector.id] = true,
	[UnitDefNames.core_sonar_station.id] = true,
	[UnitDefNames.core_targeting_facility.id] = true,
	[UnitDefNames.core_tidal_generator.id] = true,
	[UnitDefNames.core_underwater_energy_storage.id] = true,
	[UnitDefNames.core_underwater_fusion_power_plant.id] = true,
	[UnitDefNames.core_underwater_metal_storage.id] = true,
	[UnitDefNames.core_underwater_moho_mine.id] = true,
	[UnitDefNames.core_underwater_tidal_generator.id] = true,
	[UnitDefNames.core_wind_generator.id] = true,
	[UnitDefNames.arm_protector.id] = true,
	[UnitDefNames.core_fortitude_missile_defense.id] = true,
	[UnitDefNames.core_resistor.id] = true,
	[UnitDefNames.arm_repulsor.id] = true,
}

local RemoveMove = {
	-- it wont work to set canMove to false in unitdef for some reason
	[UnitDefNames.arm_air_repair_pad.id] = true,
	[UnitDefNames.core_air_repair_pad.id] = true,
}

local RemoveMoveState = {
	[UnitDefNames.arm_air_repair_pad.id] = true,
	[UnitDefNames.core_air_repair_pad.id] = true,
}

local RemoveFireState = {
	[UnitDefNames.arm_air_repair_pad.id] = true,
	[UnitDefNames.core_air_repair_pad.id] = true,
}

local RemoveAreaAttack = {
	[UnitDefNames.arm_eagle.id] = true,
	[UnitDefNames.arm_seahawk.id] = true,
	[UnitDefNames.arm_peeper.id] = true,
	[UnitDefNames.core_vulture.id] = true,
	[UnitDefNames.core_hunter.id] = true,
	[UnitDefNames.core_fink.id] = true,
}

local DestructDesc= {
	name = "Destruct",
	action="SelfD",
	id=CMD_SELFD,
	type=CMDTYPE.ICON,
	tooltip="Order the unit to selfdestruct",
	cursor="cursorattack",
}

local RemoveUnitCmdDesc 			= Spring.RemoveUnitCmdDesc
local FindUnitCmdDesc				= Spring.FindUnitCmdDesc
local EditUnitCmdDesc				= Spring.EditUnitCmdDesc
local cmdWait 						= 5 -- "Wait" ID = "5"
local cmdStop						= 0 -- "Stop" ID = "0"
local cmdMove						= 10 -- "Move" ID = "10"
local cmdMoveState					= 50 -- "Move state" ID = "50"
local cmdFireState					= 45 -- "Fire state" ID = "45"
local cmdAreaAttack_air				= 21 -- "Area Attack" ID = "39954", this is the one for aircraft, provided bt engine, xta has a gadget for area attack too
local cmdSelfD						= 65 -- "SelfD" ID = "65"

--local cmdFight						= 16 -- "Fight" ID = "16"
-- (Fight should be removed by putting canFight tag to false in unitDef)
local Echo							= Spring.Echo

function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = Spring.GetUnitTeam(unitID)
		local unitDefID = GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	--remove wait command
	if RemoveWait[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, cmdWait)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
	
	--remove stop command
	if RemoveStop[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, cmdStop)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end	
	
	--remove other commands
	if RemoveMove[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, cmdMove)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end	
	
	if RemoveMoveState[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, cmdMoveState)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end	
	
	if RemoveFireState[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, cmdFireState)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
	
	if RemoveAreaAttack[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, cmdAreaAttack_air)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
	
	-- add self-d button
	local cmdDescID = FindUnitCmdDesc(unitID, cmdSelfD)
	EditUnitCmdDesc(unitID, cmdDescID, {hidden = false,name = "Destruct"})
	--Spring.InsertUnitCmdDesc(unitID, cmd
end

--[[
"Stop" ID = "0"
"Wait" ID = "5"
"TimeWait" ID = "6"
"DeathWait" ID = "7"
"SquadWait" ID = "8"
"GatherWait" ID = "9"
"SelfD" ID = "65"
"Fire state" ID = "45"
"Repeat" ID = "115"
"Cloak state" ID = "95"
"Move state" ID = "50"
"Load units" ID = "76"
"Move" ID = "10"
"Patrol" ID = "15"
"Fight" ID = "16"
"Guard" ID = "25"
"Repair level" ID = "135"
"Land mode" ID = "145"
"Area attack" ID = "21" -- engine provided area attack
"Attack" ID = "20"
"Repair" ID = "40"
"Reclaim" ID = "90"
"Restore" ID = "110"
"Load units" ID = "75"
"Unload units" ID = "80"
"Active state" ID = "85"
"apLandAt" ID = "34569"
"apAirRepair" ID = "34570"
"Automatic Mex Upgrade" ID = "31243"
"Upgrade Mex" ID = "31244"
"Area Attack" ID = "39954" -- gadget called areaattack.lua
"Trajectory" ID = "120"
"Resurrect" ID = "125"
"0/0" ID = "100"
"Stagger" ID = "34566"
"DGun" ID = "105"
"ntPassiveMode" ID = "34571"
"Capture" ID = "130"
]]--
