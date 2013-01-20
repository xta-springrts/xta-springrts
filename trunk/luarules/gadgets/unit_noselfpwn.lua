--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "No Self Pwn",
    desc      = "Prevents units from damaging themselves.",
    author    = "quantum",
    date      = "Feb 1, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Spring = Spring


local exceptionList = {
  "arm_big_bertha",
  "arm_conqueror",
  "arm_defender",
  "arm_jethro",
  "arm_guardian",
  "arm_luger",
  "arm_ambusher",
  "arm_millenium",
  "arm_merl",
  "arm_ranger",
  "arm_raven",
  "arm_spider",
  "arm_rocko",
  "arm_retaliator",
  "arm_samson",
  "arm_stunner",
  "arm_vulcan",
  "arm_wombat",
  "core_buzzsaw",
  "core_crasher",
  "core_diplomat",
  "core_dominator",
  "core_executioner",
  "core_goliath",
  "core_immolator",
  "core_intimidator",
  "core_krogoth",
  "core_mobile_artilleryold",
  "core_missile_frigate",
  "core_morty",
  "core_punisher",
  "core_pulverizer",
  "core_silencer",
  "core_slasher",
  "core_storm",
  "core_neutron",
  "core_nixer",
  "core_toaster",
  "core_warlord",
  "core_spoiler",
  "arm_podger",
}
  
  
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

  
local exceptionMap  = {}
for _, unitName in pairs(exceptionList) do
	if exceptionMap[UnitDefNames[unitName]] then
		exceptionMap[UnitDefNames[unitName].id] = true
	else
		Spring.Echo("No Self Pwn: Cannot find the following unit:", unitName)
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
  if (unitID == attackerID and not exceptionMap[unitDefID]) then
    local health, _, paralyzeDamage = Spring.GetUnitHealth(unitID)
    if (paralyzer) then
      Spring.SetUnitHealth(unitID, {paralyze = paralyzeDamage + damage})
    else
      Spring.SetUnitHealth(unitID, health + damage)
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------