--------------------------------------------------------------------------------
-- Unit Definitions Post-processing
--------------------------------------------------------------------------------

local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()

local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end

--------------------------------------------------------------------------------
-- General postprocessing
for name, ud in pairs(UnitDefs) do
	-- Tanks and hovers don't slow down when turning
	if ud.maxvelocity and ud.category and ((ud.category:find("TANK",1,true) or ud.category:find("HOVER",1,true))) then
		if not ud.turninplace then
			ud.turninplace = 0
			ud.turninplacespeedlimit = ud.maxvelocity * 0.4
			ud.turnrate = ud.turnrate * 1.2
		elseif not tobool(ud.turninplace) then
			ud.turninplacespeedlimit = ud.maxvelocity * 0.75
		end
	end
	-- Do aircraft collide with each other or they don't?
	if ud.canfly and tonumber(ud.canfly) == 1 then
		if modOptions and modOptions.airnocollide and not tobool(modOptions.airnocollide) then
			ud.collide = 1
		else
			ud.collide = 0
		end
	end
	-- convert from the pre-0.83 representation (pieceTrailCEGTag, pieceTrailCEGRange)
	if (ud.piecetrailcegtag ~= nil) then
		if (ud.sfxtypes == nil) then
			ud.sfxtypes = {}
		end
		if (ud.piecetrailcegrange == nil) then
			ud.piecetrailcegrange = 1
		end
		ud.sfxtypes["pieceExplosionGenerators"] = {}
		for n = 1, ud.piecetrailcegrange do
			ud.sfxtypes["pieceExplosionGenerators"][n] = ud.piecetrailcegtag .. (n - 1)
		end
	end
end 


-------------------------------------------------------------------------------
-- Starting resource storage adjustment

if (modOptions) then
   local stEn = modOptions.startenergy or 1000
   local stMe = modOptions.startmetal or 1000
   for name, ud in pairs(UnitDefs) do  
	if (ud.unitname == "arm_commander" or ud.unitname == "core_commander") then
		ud.energystorage = stEn + 50
		ud.metalstorage = stMe + 50
	elseif (ud.unitname == "arm_u0commander" or ud.unitname == "core_u0commander") then
		ud.energystorage = stEn + 50
		ud.metalstorage = stMe + 50
	elseif (ud.unitname == "arm_scommander" or ud.unitname == "core_scommander") then
		ud.energystorage = stEn + 50
		ud.metalstorage = stMe + 50
	elseif (ud.unitname == "arm_ucommander" or ud.unitname == "core_ucommander") then
		ud.energystorage = stEn + 1000
		ud.metalstorage = stMe + 1000
	elseif (ud.unitname == "arm_u2commander" or ud.unitname == "core_u2commander") then
		ud.energystorage = stEn + 1500
		ud.metalstorage = stMe + 1500
	elseif (ud.unitname == "arm_u3commander" or ud.unitname == "core_u3commander") then
		ud.energystorage = stEn + 4000
		ud.metalstorage = stMe + 4000
	elseif (ud.unitname == "arm_u4commander" or ud.unitname == "core_u4commander") then
		ud.energystorage = stEn + 9000
		ud.metalstorage = stMe + 9000
	elseif (ud.unitname == "armcom" or ud.unitname == "corcom") then
		ud.energystorage = stEn + 200
		ud.metalstorage = stMe
	elseif (ud.unitname == "arm_decoy_commander" or ud.unitname == "core_decoy_commander") then
		ud.energystorage = stEn
		ud.metalstorage = stMe
	elseif (ud.unitname == "arm_base" or ud.unitname == "core_base") then
		ud.energystorage = stEn
		ud.metalstorage = stMe
	elseif (ud.unitname == "arm_nincommander" or ud.unitname == "core_nincommander") then
		ud.energystorage = stEn + 50
		ud.metalstorage = stMe + 9000
	end
   end
end

--------------------------------------------------------------------------------
-- Decoy commander setup
if (modOptions and modOptions.comm) then
	-- Maps 'comm' mod option to ARM start unit.
	local arm_start_unit = {
		choose		= "arm_commander",
		zeroupgrade = "arm_commander",
		halfupgrade = "arm_u2commander",
		fullupgrade = "arm_u4commander",
		noupgrade = "arm_u0commander",
		plain = "arm_scommander",
		comshooter = "armcom",
		decoystart = "arm_decoy_commander",
		capturethebase = "arm_base",
		nincom = "arm_nincommander",
	}
	-- Maps 'comm' mod option to CORE start unit.
	local core_start_unit = {
		choose		= "core_commander",	
		zeroupgrade = "core_commander",
		halfupgrade = "core_u2commander",
		fullupgrade = "core_u4commander",
		noupgrade = "core_u0commander",
		plain = "core_scommander",
		comshooter = "corcom",
		decoystart = "core_decoy_commander",
		capturethebase = "core_base",
		nincom = "core_nincommander",
	}
	for name, ud in pairs(UnitDefs) do  
		if (ud.unitname == "arm_decoy_commander") then
			ud.decoyfor = arm_start_unit[modOptions.comm]
		elseif (ud.unitname == "core_decoy_commander") then
			ud.decoyfor = core_start_unit[modOptions.comm]		
		end
	end
end

--------------------------------------------------------------------------------
-- Unit napping settings
if (modOptions and modOptions.mo_transportenemy) then

local commanderList = {
	arm_commander = true,
	arm_decoy_commander = true,
	arm_u0commander = true,
	arm_ucommander = true,
	arm_u2commander = true,
	arm_u3commander = true,
	arm_u4commander = true,
	arm_scommander = true,
	armcom = true,
	arm_base = true,
	arm_nincommander = true,
	core_commander = true,
	core_decoy_commander = true,
	core_u0commander = true,
	core_ucommander = true,
	core_u2commander = true,
	core_u3commander = true,
	core_u4commander = true,
	core_scommander = true,
	corcom = true,
	core_base = true,
	core_nincommander = true,
}

  if (modOptions.mo_transportenemy == "com") then
    for name,ud in pairs(UnitDefs) do  
      if (commanderList[name]) then
        ud.transportbyenemy = false
      end
    end
  elseif (modOptions.mo_transportenemy == "all") then
    for name, ud in pairs(UnitDefs) do  
      ud.transportbyenemy = false
    end
  end
end

--------------------------------------------------------------------------------
-- Metal Extraction Bonus

if (modOptions and modOptions.metalmult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].extractsmetal
    if (em) then
      UnitDefs[name].extractsmetal = em * modOptions.metalmult
    end
  end
end
--------------------------------------------------------------------------------
-- Hitpoint Bonus

if (modOptions and modOptions.hitmult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].maxdamage
    if (em) then
      UnitDefs[name].maxdamage = em * modOptions.hitmult 
    end
  end
end
--------------------------------------------------------------------------------
-- Velocity Bonus

if (modOptions and modOptions.velocitymult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].maxvelocity
    if (em) then
      UnitDefs[name].maxvelocity = em * modOptions.velocitymult
    end
  end
end
--------------------------------------------------------------------------------
-- Build Bonus

if (modOptions and modOptions.workermult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].workertime
    if (em) then
      UnitDefs[name].workertime = em * modOptions.workermult 
    end
  end
end
--------------------------------------------------------------------------------
-- Energy Production Bonus

if (modOptions and modOptions.energymult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].energymake
    if (em) then
      UnitDefs[name].energymake = em * modOptions.energymult
    end
    em = UnitDefs[name].windgenerator
    if (em) then
      UnitDefs[name].windgenerator = em * modOptions.energymult
    end
    em = UnitDefs[name].energyuse
    if (em and (em+0)<0) then
      UnitDefs[name].energyuse = em * modOptions.energymult
    end
  end
end

if (modOptions and modOptions.energymult) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].totalEnergyOut
    if (em) then
      UnitDefs[name].totalEnergyOut = em * modOptions.energymult
    end
  end
end
--------------------------------------------------------------------------------
-- Realistical scaling

if (modOptions and modOptions.realscale and tobool(modOptions.realscale)) then
  for name in pairs(UnitDefs) do
		if (UnitDefs[name].airsightdistance) then
			UnitDefs[name].airsightdistance = 10 * UnitDefs[name].airsightdistance
		end
		if (UnitDefs[name].sightdistance) then
			UnitDefs[name].sightdistance = 10 * UnitDefs[name].sightdistance
		end
		if (UnitDefs[name].radardistance) then
			UnitDefs[name].radardistance = 10 * UnitDefs[name].radardistance
		end
		if (UnitDefs[name].sonardistance) then
			UnitDefs[name].sonardistance = 10 * UnitDefs[name].sonardistance
		end
		if (UnitDefs[name].radardistancejam) then
			UnitDefs[name].radardistancejam = 10 * UnitDefs[name].radardistancejam
		end
		if (UnitDefs[name].sonardistancejam) then
			UnitDefs[name].sonardistancejam = 10 * UnitDefs[name].sonardistancejam
		end
		if (UnitDefs[name].floater and UnitDefs[name].canmove) then
			UnitDefs[name].maxvelocity = 1.5 * UnitDefs[name].maxvelocity
		elseif (UnitDefs[name].canfly and UnitDefs[name].canmove) then
			if (UnitDefs[name].hoverattack or UnitDefs[name].canbuild or UnitDefs[name].transportsize) then
				UnitDefs[name].maxvelocity = 4 * UnitDefs[name].maxvelocity
				UnitDefs[name].cruisealt = 1.5 *UnitDefs[name].cruisealt
				UnitDefs[name].acceleration = 2 *UnitDefs[name].acceleration
				UnitDefs[name].brakerate = 3 *UnitDefs[name].brakerate
			else
				UnitDefs[name].maxvelocity = 9 * UnitDefs[name].maxvelocity
				UnitDefs[name].cruisealt = 3 *UnitDefs[name].cruisealt
				UnitDefs[name].acceleration = 3 *UnitDefs[name].acceleration
				UnitDefs[name].brakerate = 2 *UnitDefs[name].brakerate
			end
		elseif (UnitDefs[name].canmove and UnitDefs[name].movementclass) then
			UnitDefs[name].maxvelocity = 1.75 * UnitDefs[name].maxvelocity
		end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function disableunits(unitlist)
  for name, ud in pairs(UnitDefs) do
    if (ud.buildoptions) then
      for _, toremovename in ipairs(unitlist) do
        for index, unitname in pairs(ud.buildoptions) do
          if (unitname == toremovename) then
            table.remove(ud.buildoptions, index)
          end
        end
      end
    end
  end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Disable all XTA units since 8.1?
-- 

if (modOptions and tobool(modOptions.newunits)) then
  disableunits({
	"arm_floating_radar", "arm_vanguard", "arm_daybreak",
	"arm_nano_tower", "arm_repulsor", "arm_spidey",
	"arm_sub_pen", "arm_floating_light_laser_tower",
	"arm_ornith", "arm_underwater_moho_mine",

	"core_floating_radar", "core_viking", "core_nightfall",
	"core_nano_tower", "core_resistor", "core_tic",
	"core_sub_pen", "core_floating_light_laser_tower",
	"core_underwater_moho_mine", "core_zeppelin"
  })
end
--------------------------------------------------------------------------------
-- Disable XTAIDS unitpack?
--

if (modOptions and not tobool(modOptions.xtaidunits)) then
  disableunits({
	"yeomen", "armona", "arm_evaperator", "paci", "armsparkle", "walker",
	"neutral_eyes", "armpur", "armbfortew", "armarch", "armbugger", "boa",
	"armfff", "mercury", "tadg07", "armraz", "armhyren", "demolish",
	"armrebel", "arm_tor","tadg05", "arm_infinite", "arm_mech_lab",

	"corbyp", "justice", "corpur", "astank", "corjar", "core_egg_shell",
	"corscrew", "corcrw", "corfff", "screamer", "corebfortns", "corhback",
	"commando", "corevashp", "core_emperor", "cor_jumbo", "scorp3g",
	"nsaclash", "tadg06"
  })
end
--------------------------------------------------------------------------------
-- Can missile/rocket units toggle rocket type?
--

if (modOptions and tobool(modOptions.rockettoggle)) then
  disableunits({
	"arm_raven", "arm_wombat", "arm_jethro", "arm_rocko", "arm_samson",
	"arm_swatter", "arm_merl", "arm_ranger", 

	"core_dominator", "core_nixer", "core_crasher", "core_storm",
	"core_slasher", "core_slinger", "core_diplomat", "core_missile_frigate"
  })
else
  disableunits({
	"arm_raven_rt", "arm_wombat_rt", "arm_jethro_rt", "arm_rocko_rt",
	"arm_samson_rt", "arm_swatter_rt", "arm_merl_rt", "arm_ranger_rt",

	"core_dominator_rt", "core_nixer_rt", "core_crasher_rt",
	"core_storm_rt", "core_slasher_rt", "core_slinger_rt",
	"core_diplomat_rt", "core_missile_frigate_rt"
  })
end
end

