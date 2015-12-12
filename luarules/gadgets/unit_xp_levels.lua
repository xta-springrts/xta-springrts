--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "XP levels",
    desc      = "XP upgrade.",
    author    = "Jools",
    date      = "Nov, 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  -- quietly kill this gadget
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local Echo              = Spring.Echo
local GetAllUnits       = Spring.GetAllUnits
local GetUnitDefID      = Spring.GetUnitDefID
local GetUnitExperience = Spring.GetUnitExperience
local GetUnitHealth     = Spring.GetUnitHealth
local GetUnitIsStunned  = Spring.GetUnitIsStunned
local GetUnitTeam       = Spring.GetUnitTeam
local IsCheatingEnabled = Spring.IsCheatingEnabled
local SetUnitHealth     = Spring.SetUnitHealth
local SetUnitMaxHealth  = Spring.SetUnitMaxHealth


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Configuration
--

local healthDefs = {  --  unitName, healthBonus
  ['arm_targeting_facility'] = 0.5,
  ['core_targeting_facility'] = 0.5,
  ['lost_targeting_facility'] = 0.5,
}

local commDefs = {
  'arm_advanced_radar_tower',
  'arm_advanced_sonar_station',
  'arm_colossus',
  'arm_infiltrator',
  'arm_radar_tower',
  'arm_targeting_facility',
  'arm_seer',
  'arm_sonar_station',
  'arm_marky',
  'core_advanced_radar_tower',
  'core_advanced_sonar_station',
  'core_hive',
  'core_parasite',
  'core_radar_tower',
  'core_targeting_facility',
  'core_informer',
  'core_sonar_station',
  'core_voyeur',
  'lost_advanced_radar_tower',
  'lost_advanced_sonar_station',
  'lost_giant',
  'lost_assassin',
  'lost_radar_tower',
  'lost_targeting_facility',
  'lost_observer',
  'lost_sonar_station',
  'lost_divine',
}



--------------------------------------------------------------------------------
--
--  Parse the configuration
--

local healthDefIDs = {}
do
  for udName, bonus in pairs(healthDefs) do
    local ud = UnitDefNames[udName]
    if (ud and ud.id) then
      healthDefIDs[ud.id] = bonus
    end
  end
end
healthDefs = nil

local commDefIDs = {}
do
  for _, udName in ipairs(commDefs) do
    local ud = UnitDefNames[udName]
    if (ud and ud.id) then
      commDefIDs[ud.id] = ud.health
    end
  end
end
commDefs = nil


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Local Vars
--

local teamData = {}
do
  for t = 0, Game.maxTeams do
    teamData[t] = {
      comms = {},
      scale = 1.0,
    }
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  for _, unitID in ipairs(spGetAllUnits()) do
    local unitTeam = GetUnitTeam(unitID)
    local unitDefID = GetUnitDefID(unitID)
    if (unitTeam and unitDefID) then
      local td = teamData[unitTeam]
      if (commDefIDs[unitDefID]) then
        td.comms[unitID] = unitDefID
      end
      local healthBonus = healthDefIDs[unitDefID]
      if (healthBonus) then
        local _, _, beingBuilt = GetUnitIsStunned(unitID)
        if (not beingBuilt) then
          td.scale = td.scale + healthBonus
        end 
      end
    end
  end

  for t = 0, Game.maxTeams do
    AdjustTeam(t)
  end

  gadgetHandler:AddChatAction('healthbonus', function()
    if (not IsCheatingEnabled()) then
      Echo('Enable cheating to see the health bonus list')
    else
      Echo('Commander Health Bonuses:')
      for t = 0, Game.maxTeams do
        Echo('  team ' .. t .. ': ' .. teamData[t].scale)
      end
    end
  end)
end


function gadget:Shutdown()
  for _, unitID in ipairs(spGetAllUnits()) do
    local health, maxHealth = GetUnitHealth(unitID)
    SetUnitMaxHealth(unitID, maxHealth)
  end

  gadgetHandler:RemoveChatAction('healthbonus')
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
  if (commDefIDs[unitDefID]) then
    local td = teamData[unitTeam]
    td.comms[unitID] = unitDefID
    AdjustUnit(unitID, unitDefID, unitTeam)
  end
end


function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  local healthBonus = healthDefIDs[unitDefID]
  if (healthBonus) then
    local td = teamData[unitTeam]
    td.scale = td.scale + healthBonus
    AdjustTeam(unitTeam)
  end
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  local td = teamData[unitTeam]
  local healthBonus = healthDefIDs[unitDefID]
  if (healthBonus) then
    td.scale = td.scale - healthBonus
    AdjustTeam(unitTeam)
  end
  td.comms[unitID] = nil
end


function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  local td = teamData[unitTeam]
  local healthBonus = healthDefIDs[unitDefID]
  if (healthBonus) then
    td.scale = td.scale - healthBonus
    AdjustTeam(unitTeam)
  end
  td.comms[unitID] = nil
end


function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  local td = teamData[unitTeam]
  local healthBonus = healthDefIDs[unitDefID]
  if (healthBonus) then
    td.scale = td.scale + healthBonus
    AdjustTeam(unitTeam)
  elseif (commDefIDs[unitDefID]) then
    td.comms[unitID] = unitDefID
    AdjustUnit(unitID, unitDefID, unitTeam)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

