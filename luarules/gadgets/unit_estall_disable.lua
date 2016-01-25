--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_estall_disable.lua
--  brief:   disables units during energy stall
--  author:  
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "UnitEStallDisable",
    desc      = "Deactivates units during energy stall",
    author    = "Licho",
    date      = "23.7.2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------

--Speed-ups

local insert            = table.insert
local GiveOrderToUnit	= Spring.GiveOrderToUnit
local GetUnitStates	= Spring.GetUnitStates
local GetUnitTeam	= Spring.GetUnitTeam
local GetUnitResources	= Spring.GetUnitResources
local GetGameSeconds    = Spring.GetGameSeconds

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local units = {}
local disabledUnits = {}
local changeStateDelay = 3 -- delay in seconds before state of unit can be changed. Do not set it below 2 seconds, because it takes 2 seconds before enabled unit reaches full energy use
local estallDefs = {
  -- [ UnitDefNames['arm_advanced_radar_tower'].id ] = true,
  -- [ UnitDefNames['arm_advanced_sonar_station'].id ] = true,
  -- [ UnitDefNames['arm_marky'].id ] = true,
  -- [ UnitDefNames['arm_radar_tower'].id ] = true,
  -- [ UnitDefNames['arm_seer'].id ] = true,
  -- [ UnitDefNames['arm_sonar_station'].id ] = true,
  -- [ UnitDefNames['core_advanced_radar_tower'].id ] = true,
  -- [ UnitDefNames['core_advanced_sonar_station'].id ] = true,
  -- [ UnitDefNames['core_informer'].id ] = true,
  -- [ UnitDefNames['core_radar_tower'].id ] = true,
  -- [ UnitDefNames['core_sonar_station'].id ] = true,
  -- [ UnitDefNames['core_voyeur'].id ] = true,
  [ UnitDefNames['arm_adv_aircraft_plant'].id ] = true,
  [ UnitDefNames['arm_aircraft_plant'].id ] = true,
  [ UnitDefNames['arm_colossus'].id ] = true,
  [ UnitDefNames['arm_moho_mine'].id ] = true,
  [ UnitDefNames['arm_targeting_facility'].id ] = true,
  [ UnitDefNames['core_adv_aircraft_plant'].id ] = true,
  [ UnitDefNames['core_aircraft_plant'].id ] = true,
  [ UnitDefNames['core_hive'].id ] = true,
  [ UnitDefNames['core_moho_mine'].id ] = true,
  [ UnitDefNames['core_targeting_facility'].id ] = true,
  [ UnitDefNames['lost_adv_aircraft_plant'].id ] = true,
  [ UnitDefNames['lost_aircraft_plant'].id ] = true,
  [ UnitDefNames['lost_giant'].id ] = true,
  [ UnitDefNames['lost_moho_mine'].id ] = true,
  [ UnitDefNames['lost_targeting_facility'].id ] = true,
  [ UnitDefNames['guardian_moho_mine'].id ] = true,
  [ UnitDefNames['guardian_targeting_facility'].id ] = true,
  [ UnitDefNames['guardian_areo_platform'].id ] = true,
  
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  for _,unitID in ipairs(Spring.GetAllUnits()) do
	local unitDefID = Spring.GetUnitDefID(unitID)
	AddUnit(unitID, unitDefID)
  end
end


function AddUnit(unitID, unitDefID) 
  if (estallDefs[unitDefID]) then
	units[unitID] = { defID = unitDefID, changeStateTime = GetGameSeconds() } 
  end
end

function RemoveUnit(unitID) 
  units[unitID] = nil
  disabledUnits[unitID] = nil
end


function gadget:UnitCreated(unitID, unitDefID)
	AddUnit(unitID, unitDefID)
end

function gadget:UnitTaken(unitID, unitDefID)
	AddUnit(unitID, unitDefID)
end

function gadget:UnitGiven(unitID, unitDefID, newTeamID)
  if (newTeamID==nil) then RemoveUnit(unitID) end
end


function gadget:UnitDestroyed(unitID,_,_, _, _, _, preEvent)
  if (preEvent) then return end
  RemoveUnit(unitID)
end



function gadget:GameFrame(n)
  if (((n+8) % 64) < 0.1) then
	local teamEnergy = {}
	local gameSeconds = GetGameSeconds()
	local temp = Spring.GetTeamList() 
	for _,teamID in ipairs(temp) do 
		local eCur, eMax, ePull, eInc, _, _, _, eRec = Spring.GetTeamResources(teamID, "energy")
		teamEnergy[teamID] = eCur - ePull + eInc
	end 
		

    for unitID,data in pairs(units) do
      if (gameSeconds - data.changeStateTime > changeStateDelay) then
        local disabledUnitEnergyUse = disabledUnits[unitID] 
        if (disabledUnitEnergyUse~=nil) then -- we have disabled unit
          local unitTeamID = GetUnitTeam(unitID)
          if (disabledUnitEnergyUse < teamEnergy[unitTeamID]) then  -- we still have enough energy to reenable unit
            disabledUnits[unitID]=nil
            GiveOrderToUnit(unitID, CMD.ONOFF, { 1 }, { })
            data.changeStateTime = gameSeconds
            teamEnergy[unitTeamID] = teamEnergy[unitTeamID] - disabledUnitEnergyUse
          end
        else -- we have non-disabled unit
          local _, _, _, energyUse =	GetUnitResources(unitID)
          local energyUpkeep = UnitDefs[data.defID].energyUpkeep
          if (energyUse == nil or energyUpkeep == nil) then -- unit probably doesnt exists, get rid of it
            RemoveUnit(unitID)
          elseif (energyUse < energyUpkeep) then -- there is not enough energy to keep unit running (its energy use auto dropped to 0), we will disable it 
            if (GetUnitStates(unitID).active) then  -- only disable "active" unit
              GiveOrderToUnit(unitID, CMD.ONOFF, { 0 }, { })
              data.changeStateTime = gameSeconds
              disabledUnits[unitID] = energyUpkeep
            end				
          end
        end
      end
    end
  end
end


function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  if (cmdID == CMD.ONOFF and disabledUnits[unitID]~=nil) then
    return false
  else 
    return true
  end
end
 
  
--------------------------------------------------------------------------------
--  END SYNCED
--------------------------------------------------------------------------------
end
