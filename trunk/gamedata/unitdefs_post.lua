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

local tabremove = table.remove

--------------------------------------------------------------------------------
-- General postprocessing
local lowcpu = modOptions.lowcpu and tobool(modOptions.lowcpu)
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
	-- Do aircraft collide with each other or they don't?  (Default, no collision)
	if ud.canfly and tobool(ud.canfly) then
		if modOptions and modOptions.airnocollide and not tobool(modOptions.airnocollide) then
			ud.collide = 1
		else
			ud.collide = 0
		end
	end
	-- convert from the pre-0.83 representation (pieceTrailCEGTag, pieceTrailCEGRange)
	if (ud.piecetrailcegtag ~= nil and not lowcpu) then
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
	ud.collisionvolumetest = 1  --Prevent projectiles from flying through units
	
	--enable restore ability
	if ud.terraformSpeed and  ud.terraformSpeed > 0 then
		ud.canRestore = 1
	end
	
	-- scale brakerates for air
	 if (ud.brakerate) then  
		if ud.canfly then 
			if not ud.hoverattack then 
				ud.brakerate = ud.brakerate * 0.1 
			end
		end
	end
end 

-------------------------------------------------------------------------------
-- Disable units based on map atmosphere and mod options

--[[   Not possible due to Game. not being available at _post stage
local disableWind = Game.windMax < 9.1
local disableAir, disableHovers
if not modOptions.space_mode or (modOptions.space_mode and modOptions.space_mode=="0") then
	local map = Game.mapHumanName:lower()
	if Game.windMin <= 1 and Game.windMax <= 4 then
		disableAir = true
		disableHovers = true
	elseif map:find("comet") or map:find("moon") then
		disableAir = true
		disableHovers = true
	end
	if Game.windMin >= 30 or Game.windMax >= 35 then
		disableAir = true
	end
end
if (disableWind) then
	UnitDefs["arm_wind_generator"].unitRestricted = 0
	UnitDefs["core_wind_generator"].unitRestricted = 0
end
if (disableHovers) then
	UnitDefs["arm_hovercraft_platform"].unitRestricted = 0
	UnitDefs["core_hovercraft_platform"].unitRestricted = 0
end
if (disableAir) then
	UnitDefs["arm_aircraft_plant"].unitRestricted = 0
	UnitDefs["arm_adv_aircraft_plant"].unitRestricted = 0
	UnitDefs["arm_seaplane_platform"].unitRestricted = 0
	UnitDefs["core_aircraft_plant"].unitRestricted = 0
	UnitDefs["core_adv_aircraft_plant"].unitRestricted = 0
	UnitDefs["core_seaplane_platform"].unitRestricted = 0
end
--]]

local commanderList = {
	arm_commander = 50,
	arm_decoy_commander = 0,
	arm_decoy_ucommander = 0,
	arm_decoy_ucommander_core = 0,
	arm_u0commander = 50,
	arm_ucommander = 1000,
	arm_u2commander = 1500,
	arm_u3commander = 4000,
	arm_u4commander = 9000,
	arm_scommander = 50,
	armcom = 200,
	arm_base = 0,
	arm_nincommander = 50,
	core_commander = 50,
	core_decoy_commander = 0,
	core_decoy_ucommander = 0,
	core_decoy_ucommander_arm = 0,
	core_u0commander = 50,
	core_ucommander = 1000,
	core_u2commander = 1500,
	core_u3commander = 4000,
	core_u4commander = 9000,
	core_scommander = 50,
	corcom = 200,
	core_base = 0,
	core_nincommander = 50,
	
}
-------------------------------------------------------------------------------
-- Starting resource storage adjustment

if (modOptions) then
	local stEn = modOptions.startenergy or 1000
	local stMe = modOptions.startmetal or 1000
	for name, store in pairs(commanderList) do  
		UnitDefs[name].energystorage = stEn + store
		UnitDefs[name].metalstorage = stMe + store
	end
	UnitDefs["arm_nincommander"].metalstorage = stMe + 9000
	UnitDefs["core_nincommander"].metalstorage = stMe + 9000
end

--------------------------------------------------------------------------------
-- Decoy commander setup
if (modOptions and modOptions.commander) then
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
	UnitDefs["arm_decoy_commander"].decoyfor = arm_start_unit[modOptions.commander]
	UnitDefs["core_decoy_commander"].decoyfor = core_start_unit[modOptions.commander]
end

--------------------------------------------------------------------------------
-- Unit napping settings
if (modOptions and modOptions.mo_transportenemy) then
  if (modOptions.mo_transportenemy == "com") then
    for name,ud in pairs(commanderList) do  
      UnitDefs[name].transportbyenemy = false
    end
  elseif (modOptions.mo_transportenemy == "all") then
    for name, ud in pairs(UnitDefs) do  
      ud.transportbyenemy = false
    end
  end
end

--------------------------------------------------------------------------------
-- Metal Extraction Bonus

if (modOptions and modOptions.metalmult and tonumber(modOptions.metalmult) ~= 1.0) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].extractsmetal
    if (em) then
      UnitDefs[name].extractsmetal = em * modOptions.metalmult
    end
  end
end
--------------------------------------------------------------------------------
-- Hitpoint Bonus

if (modOptions and modOptions.hitmult and tonumber(modOptions.hitmult) ~= 1.0) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].maxdamage
    if (em) then
      UnitDefs[name].maxdamage = em * modOptions.hitmult 
    end
  end
end
--------------------------------------------------------------------------------
-- Velocity Bonus

if (modOptions and modOptions.velocitymult and tonumber(modOptions.velocitymult) ~= 1.0) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].maxvelocity
    if (em) then
      UnitDefs[name].maxvelocity = em * modOptions.velocitymult
    end
  end
end
--------------------------------------------------------------------------------
-- Build Bonus

if (modOptions and modOptions.workermult and tonumber(modOptions.workermult) ~= 1.0) then
  for name in pairs(UnitDefs) do
    local em = UnitDefs[name].workertime
    if (em) then
      UnitDefs[name].workertime = em * modOptions.workermult 
    end
  end
end
--------------------------------------------------------------------------------
-- Energy Production Bonus

if (modOptions and modOptions.energymult and tonumber(modOptions.energymult) ~= 1.0) then
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
	em = UnitDefs[name].totalEnergyOut
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
				UnitDefs[name].cruisealt = 1.5 * UnitDefs[name].cruisealt
				UnitDefs[name].acceleration = 2 * UnitDefs[name].acceleration
				UnitDefs[name].maxacc = 0.52
				UnitDefs[name].brakerate = 3 * UnitDefs[name].brakerate
			else
				UnitDefs[name].maxvelocity = 9 * UnitDefs[name].maxvelocity
				UnitDefs[name].cruisealt = 3 * UnitDefs[name].cruisealt
				UnitDefs[name].acceleration = 3 * UnitDefs[name].acceleration
				UnitDefs[name].maxacc = 0.78
				UnitDefs[name].brakerate = 2 * UnitDefs[name].brakerate
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
            tabremove(ud.buildoptions, index)
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
	"yeomen", "armona", "arm_evaperator", "paci", "armsparkle", "armjanus",
	"walker", "neutral_eyes", "armpur", "armbfortew", "armarch", "armbugger",
	"boa", "armfff", "mercury", "tadg07", "armraz", "armhyren", "demolish",
	"armrebel", "arm_tor", "tadg05", "arm_infinite", "arm_mech_lab",

	"corbyp", "justice", "corpur", "astank", "corjar", "core_egg_shell",
	"corscrew", "corcrw", "corfff", "screamer", "corebfortns", "corhback",
	"commando", "corevashp", "core_emperor", "cor_jumbo", "scorp3g",
	"nsaclash", "tadg06"
  })
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Disable Spider and Tortoise unitpack?
--

if (modOptions and not tobool(modOptions.spidertortoise)) then
  disableunits({
	"arm_spidernest",

	"core_tortoise_plant" 
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

