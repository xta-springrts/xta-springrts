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

local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitHealth = Spring.SetUnitHealth

local exceptionList = {
  "arm_ambusher",
  "arm_big_bertha",
  "arm_conqueror",
  "arm_defender",
  "arm_guardian",
  "arm_jethro",
  "arm_luger",
  "arm_merl",
  "arm_millenium",
  "arm_podger",
  "arm_ranger",
  "arm_raven",
  "arm_retaliator",
  "arm_rocko",
  "arm_samson",
  "arm_spider",
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
  "core_mobile_artilleryold",	-- 9.725
  "core_pillager",				-- SVN
  "core_missile_frigate",
  "core_morty",
  "core_punisher",
  "core_pulverizer",
  "core_silencer",
  "core_slasher",
  "core_spoiler",
  "core_storm",
  "core_neutron",
  "core_nixer",
  "core_toaster",
  "core_warlord",
}
  
  
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local exceptionMap  = {}
for _, unitName in pairs(exceptionList) do
	local uID = UnitDefNames[unitName]
	if uID then
		if exceptionMap[uID.id] then
			Spring.Echo("No Self Pwn:  Duplicate table entry: " .. unitName)
		else
			exceptionMap[uID.id] = true
		end
	else
		Spring.Echo("No Self Pwn:  Nonexisting unit: " .. unitName)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
  if (unitID == attackerID and not exceptionMap[unitDefID]) then
    local health, _, paralyzeDamage = spGetUnitHealth(unitID)
    if (paralyzer) then
      spSetUnitHealth(unitID, {paralyze = paralyzeDamage + damage})
    else
      spSetUnitHealth(unitID, health + damage)
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------