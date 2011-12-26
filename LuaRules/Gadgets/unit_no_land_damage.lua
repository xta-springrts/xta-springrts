--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "No Land Damage",
    desc      = "Stops torpedos and stuff from damaging units when they're on land.",
    author    = "TheFatController",
    date      = "Aug 31, 2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local GetUnitBasePosition = Spring.GetUnitBasePosition

local NO_LAND_DAMAGE = {
  [WeaponDefNames['armair_torpedo'].id] = true,
  [WeaponDefNames['armatl_torpedo'].id] = true,
  [WeaponDefNames['armdepthcharge'].id] = true,
  [WeaponDefNames['armseap_weapon1'].id] = true,
  [WeaponDefNames['armseap_weapon2'].id] = true,
  [WeaponDefNames['armsmart_torpedo'].id] = true,
  [WeaponDefNames['arm_torpedo'].id] = true,
  [WeaponDefNames['coax_torpedo'].id] = true,
  [WeaponDefNames['corair_torpedo'].id] = true,
  [WeaponDefNames['coratl_torpedo'].id] = true,
  [WeaponDefNames['coredepthcharge'].id] = true,
  [WeaponDefNames['core_torpedo'].id] = true,
  --[WeaponDefNames['corseap_weapon1'].id] = true,
  --[WeaponDefNames['corseap_weapon2'].id] = true,
  [WeaponDefNames['corsmart_torpedo'].id] = true,
  [WeaponDefNames['corssub_weapon'].id] = true,
  [WeaponDefNames['levi_torpedo'].id] = true,
  [WeaponDefNames['boat_torpedo'].id] = true,
  [WeaponDefNames['tank_torpedo'].id] = true,
  [WeaponDefNames['fibby_torpedo'].id] = true,
  [WeaponDefNames['stupidsubs'].id] = true,
  --[WeaponDefNames['tawf009_weapon'].id] = true,
  --[WeaponDefNames['coramph_weapon1'].id] = true
}

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, 
                            weaponID, attackerID, attackerDefID, attackerTeam)
  if NO_LAND_DAMAGE[weaponID] then
    if select(2,GetUnitBasePosition(unitID)) > 0 then 
      return (damage * 0.2),1
    else 
      return damage,1
    end
  else
    return damage,1
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------