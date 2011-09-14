--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Health Upgrade",
    desc      = "Commander health upgrade.",
    author    = "quantum",
    date      = "Nov 8, 2007",
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

local spEcho              = Spring.Echo
local spGetAllUnits       = Spring.GetAllUnits
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitExperience = Spring.GetUnitExperience
local spGetUnitHealth     = Spring.GetUnitHealth
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetUnitTeam       = Spring.GetUnitTeam
local spIsCheatingEnabled = Spring.IsCheatingEnabled
local spSetUnitHealth     = Spring.SetUnitHealth
local spSetUnitMaxHealth  = Spring.SetUnitMaxHealth


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Configuration
--

local healthDefs = {  --  unitName, healthBonus
  ['arm_targeting_facility'] = 0.5,
  ['core_targeting_facility'] = 0.5,
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

local function AdjustUnit(unitID, unitDefID, unitTeam)
  local scale = teamData[unitTeam].scale
  local health, maxHealth = spGetUnitHealth(unitID)
  local defHealth = UnitDefs[unitDefID].health
-- FIXME?
--  local exp = spGetUnitExperience
--  local limExp = exp / (exp + 1)
--  defHealth = defHealth * (1 + (limExp * 0.7)) -- see CUnit::ExperienceChange()
  

  local newMaxHealth = scale * defHealth
  spSetUnitMaxHealth(unitID, newMaxHealth)

  local currFrac = health / maxHealth
  spSetUnitHealth(unitID, newMaxHealth * currFrac)
end


local function AdjustTeam(teamID)
  local td = teamData[teamID]
  for unitID, unitDefID in pairs(td.comms) do
    AdjustUnit(unitID, unitDefID, teamID)
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
  for _, unitID in ipairs(spGetAllUnits()) do
    local unitTeam = spGetUnitTeam(unitID)
    local unitDefID = spGetUnitDefID(unitID)
    if (unitTeam and unitDefID) then
      local td = teamData[unitTeam]
      if (commDefIDs[unitDefID]) then
        td.comms[unitID] = unitDefID
      end
      local healthBonus = healthDefIDs[unitDefID]
      if (healthBonus) then
        local _, _, beingBuilt = spGetUnitIsStunned(unitID)
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
    if (not spIsCheatingEnabled()) then
      spEcho('Enable cheating to see the health bonus list')
    else
      spEcho('Commander Health Bonuses:')
      for t = 0, Game.maxTeams do
        spEcho('  team ' .. t .. ': ' .. teamData[t].scale)
      end
    end
  end)
end


function gadget:Shutdown()
  for _, unitID in ipairs(spGetAllUnits()) do
    local health, maxHealth = spGetUnitHealth(unitID)
    spSetUnitMaxHealth(unitID, maxHealth)
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

