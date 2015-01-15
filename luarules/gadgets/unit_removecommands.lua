function gadget:GetInfo()
   return {
   version   = "1",
   name      = "Remove commands",
   desc      = "Removes some commands, and adds one",
   author    = "Jools",
   date      = "Apr, 2013", 
   license   = "Public Domain",
   layer     = 1,
   enabled   = true, --enabled by default
   handler   = true, --access to handler
   }
end

--adding this was first try at making it not fail with critters. but it just completly disables i think.
if (gadgetHandler:IsSyncedCode()) then

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
	[UnitDefNames.arm_protector.id] = true,
	[UnitDefNames.arm_radar_jamming_tower.id] = true,
	[UnitDefNames.arm_radar_tower.id] = true,
	[UnitDefNames.arm_repulsor.id] = true,
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
	[UnitDefNames.core_fortitude_missile_defense.id] = true,
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
	[UnitDefNames.core_resistor.id] = true,
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
	
	[UnitDefNames.lost_advanced_radar_tower.id] = true,
	[UnitDefNames.lost_advanced_sonar_station.id] = true,
	[UnitDefNames.lost_air_repair_pad.id] = true,
	[UnitDefNames.lost_energy_storage.id] = true,
	[UnitDefNames.lost_floating_metal_maker.id] = true,
	[UnitDefNames.lost_floating_radar.id] = true,
	[UnitDefNames.lost_peacemaker.id] = true,
	[UnitDefNames.lost_fusion_reactor.id] = true,
	[UnitDefNames.lost_cold_fusion_reactor.id] = true,
	[UnitDefNames.lost_geothermal_powerplant.id] = true,
	[UnitDefNames.lost_metal_extractor.id] = true,
	[UnitDefNames.lost_metal_maker.id] = true,
	[UnitDefNames.lost_metal_storage.id] = true,
	[UnitDefNames.lost_moho_metal_maker.id] = true,
	[UnitDefNames.lost_moho_mine.id] = true,
	[UnitDefNames.lost_radar_jamming_tower.id] = true,
	[UnitDefNames.lost_radar_tower.id] = true,
	[UnitDefNames.lost_solar_collector.id] = true,
	[UnitDefNames.lost_sonar_station.id] = true,
	[UnitDefNames.lost_targeting_facility.id] = true,
	[UnitDefNames.lost_tidal_generator.id] = true,
	[UnitDefNames.lost_underwater_energy_storage.id] = true,
	[UnitDefNames.lost_underwater_fusion_power_plant.id] = true,
	[UnitDefNames.lost_underwater_metal_storage.id] = true,
	[UnitDefNames.lost_underwater_moho_mine.id] = true,
	[UnitDefNames.lost_underwater_tidal_generator.id] = true,
	[UnitDefNames.lost_wind_generator.id] = true,
}

local RemoveStop = {
	[UnitDefNames.arm_advanced_radar_tower.id] = true,
	[UnitDefNames.arm_advanced_sonar_station.id] = true,
	[UnitDefNames.arm_air_repair_pad.id] = true,
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
	[UnitDefNames.arm_protector.id] = true,
	[UnitDefNames.arm_radar_jamming_tower.id] = true,
	[UnitDefNames.arm_radar_tower.id] = true,
	[UnitDefNames.arm_repulsor.id] = true,
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
	[UnitDefNames.core_fortitude_missile_defense.id] = true,
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
	[UnitDefNames.core_resistor.id] = true,
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
	
	[UnitDefNames.lost_advanced_radar_tower.id] = true,
	[UnitDefNames.lost_advanced_sonar_station.id] = true,
	[UnitDefNames.lost_air_repair_pad.id] = true,
	[UnitDefNames.lost_energy_storage.id] = true,
	[UnitDefNames.lost_floating_metal_maker.id] = true,
	[UnitDefNames.lost_floating_radar.id] = true,
	[UnitDefNames.lost_peacemaker.id] = true,
	[UnitDefNames.lost_geothermal_powerplant.id] = true,
	[UnitDefNames.lost_fusion_reactor.id] = true,
	[UnitDefNames.lost_cold_fusion_reactor.id] = true,
	[UnitDefNames.lost_metal_extractor.id] = true,
	[UnitDefNames.lost_metal_maker.id] = true,
	[UnitDefNames.lost_metal_storage.id] = true,
	[UnitDefNames.lost_moho_metal_maker.id] = true,
	[UnitDefNames.lost_moho_mine.id] = true,
	[UnitDefNames.lost_radar_jamming_tower.id] = true,
	[UnitDefNames.lost_radar_tower.id] = true,
	[UnitDefNames.lost_solar_collector.id] = true,
	[UnitDefNames.lost_sonar_station.id] = true,
	[UnitDefNames.lost_targeting_facility.id] = true,
	[UnitDefNames.lost_tidal_generator.id] = true,
	[UnitDefNames.lost_underwater_energy_storage.id] = true,
	[UnitDefNames.lost_underwater_fusion_power_plant.id] = true,
	[UnitDefNames.lost_underwater_metal_storage.id] = true,
	[UnitDefNames.lost_underwater_moho_mine.id] = true,
	[UnitDefNames.lost_underwater_tidal_generator.id] = true,
	[UnitDefNames.lost_wind_generator.id] = true,
}

local RemoveMove = {
	-- it wont work to set canMove to false in unitdef for some reason
	[UnitDefNames.arm_air_repair_pad.id] = true,
	[UnitDefNames.core_air_repair_pad.id] = true,
	[UnitDefNames.lost_air_repair_pad.id] = true,
}

local RemoveMoveState = {
	[UnitDefNames.arm_air_repair_pad.id] = true,
	[UnitDefNames.core_air_repair_pad.id] = true,
	[UnitDefNames.lost_air_repair_pad.id] = true,
}

local RemoveFireState = {
	[UnitDefNames.arm_air_repair_pad.id] = true,
	[UnitDefNames.core_air_repair_pad.id] = true,
	[UnitDefNames.lost_air_repair_pad.id] = true,
}

local RemoveAreaAttack = {
	[UnitDefNames.arm_eagle.id] = true,
	[UnitDefNames.arm_seahawk.id] = true,
	[UnitDefNames.arm_peeper.id] = true,
	[UnitDefNames.core_vulture.id] = true,
	[UnitDefNames.core_hunter.id] = true,
	[UnitDefNames.core_fink.id] = true,
	[UnitDefNames.lost_swallow.id] = true,
	[UnitDefNames.lost_condor.id] = true,
	[UnitDefNames.lost_probe.id] = true,
}

local RemoveUnitCmdDesc 			= Spring.RemoveUnitCmdDesc
local FindUnitCmdDesc				= Spring.FindUnitCmdDesc
local EditUnitCmdDesc				= Spring.EditUnitCmdDesc
local GetUnitDefID					= Spring.GetUnitDefID
local CMD_WAIT						= CMD.WAIT -- "Wait" ID = "5"
local CMD_STOP						= CMD.STOP -- "Stop" ID = "0"
local CMD_MOVE						= CMD.MOVE -- "Move" ID = "10"
local CMD_MOVESTATE					= CMD.MOVE_STATE -- "Move state" ID = "50"
local CMD_FIRESTATE					= CMD.FIRE_STATE -- "Fire state" ID = "45"
local CMD_AREA_ATTACK_AIR			= 21 -- "Area Attack" ID = "39954", this is the one for aircraft, provided by engine, xta has a gadget for area attack too
local CMD_SELFD						= CMD.SELFD -- "SelfD" ID = "65"
local GaiaTeamID  					= Spring.GetGaiaTeamID ()
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
	--somehow this gadget does not like the critters. so just do not try to edit their buttons.
	if teamID == GaiaTeamID then return end
	
	--remove wait command
	if RemoveWait[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, CMD_WAIT)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
	
	--remove stop command
	if RemoveStop[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, CMD_STOP)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end	
	
	--remove other commands
	if RemoveMove[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, CMD_MOVE)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end	
	
	if RemoveMoveState[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, CMD_MOVESTATE)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end	
	
	if RemoveFireState[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, CMD_FIRESTATE)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
	
	if RemoveAreaAttack[unitDefID] then
		local cmdDescID = FindUnitCmdDesc(unitID, CMD_AREA_ATTACK_AIR)
		if (cmdDescID) then
			RemoveUnitCmdDesc(unitID, cmdDescID)
		end
	end
	
	-- add self-d button
	local cmdDescID = FindUnitCmdDesc(unitID, CMD_SELFD)
	if (cmdDescID) then --just to be sure
		EditUnitCmdDesc(unitID, cmdDescID, {hidden = false,name = "Destruct"})		
	end
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

else
-- UNSYNCED CODE
end