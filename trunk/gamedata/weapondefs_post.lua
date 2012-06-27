--------------------------------------------------------------------------------
-- Default Engine Weapon Definitions Post-processing
--------------------------------------------------------------------------------

local function isbool(x)   return (type(x) == 'boolean') end
local function istable(x)  return (type(x) == 'table')   end
local function isnumber(x) return (type(x) == 'number')  end
local function isstring(x) return (type(x) == 'string')  end

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

local function ProcessWeaponDef(wdName,wd)
  -- weapon reloadTime and stockpileTime were seperated in 77b1
  if (tobool(wd.stockpile) and (wd.stockpiletime==nil)) then
    wd.stockpiletime = wd.reloadtime
    wd.reloadtime    = 2             -- 2 seconds
  end

  -- auto detect ota weapontypes
  if (wd.weapontype==nil) then
    local rendertype = tonumber(wd.rendertype) or 0
    if (tobool(wd.dropped)) then
      wd.weapontype = "AircraftBomb";
    elseif (tobool(wd.vlaunch)) then
      wd.weapontype = "StarburstLauncher";
    elseif (tobool(wd.beamlaser)) then
      wd.weapontype = "BeamLaser";
    elseif (tobool(wd.isshield)) then
      wd.weapontype = "Shield";
    elseif (tobool(wd.waterweapon)) then
      wd.weapontype = "TorpedoLauncher";
    elseif (wdName:lower():find("disintegrator",1,true)) then
      wd.weaponType = "DGun"
    elseif (tobool(wd.lineofsight)) then
      if (rendertype==7) then
        wd.weapontype = "LightningCannon";

      -- swta fix (outdated?)
      elseif (wd.model and wd.model:lower():find("laser",1,true)) then
        wd.weapontype = "LaserCannon";

      elseif (tobool(wd.beamweapon)) then
        wd.weapontype = "LaserCannon";
      elseif (tobool(wd.smoketrail)) then
        wd.weapontype = "MissileLauncher";
      elseif (rendertype==4 and tonumber(wd.color)==2) then
        wd.weapontype = "EmgCannon";
      elseif (rendertype==5) then
        wd.weapontype = "Flame";
      --elseif(rendertype==1) then
      --  wd.weapontype = "MissileLauncher";
      else
        wd.weapontype = "Cannon";
      end
    else
      wd.weapontype = "Cannon";
    end

    if (wd.weapontype == "LightingCannon") then
      wd.weapontype = "LightningCannon";
    end
  end

  -- 
  if (tobool(wd.ballistic) or tobool(wd.dropped)) then
    wd.gravityaffected = true
  end
end

for wdName, wd in pairs(WeaponDefs) do
  if (isstring(wdName) and istable(wd)) then
    ProcessWeaponDef(wdName, wd)
  end
end


--------------------------------------------------------------------------------
-- XTA Weapon Definitions Post-processing
--------------------------------------------------------------------------------
local explosiveWeapons = {
	MissileLauncher = true,
	StarburstLauncher = true,
	TorpedoLauncher = true,
	Cannon = true,
	AircraftBomb = true,
}
local inertialessWeapons = {
	LaserCannon = true,
	BeamLaser = true,
	EmgCannon = true,
	Flame = true,
	LightningCannon = true,
}

local modOptions = Spring.GetModOptions()

-- Adjustment of terrain damage, area of effect, kinetic force of weapons and cannon trajectory height
local customGravity = 0.5
local maxRangeAngle = 45  --in degrees >0 and <=45
if modOptions and modOptions.gravity then customGravity=modOptions.gravity end
local velGravFactor = customGravity * 900 / math.sin(math.rad(2 * maxRangeAngle))
for id in pairs(WeaponDefs) do
	if WeaponDefs[id].range then
		if tonumber(WeaponDefs[id].range) < 550 or explosiveWeapons[WeaponDefs[id].weapontype] then
				WeaponDefs[id].avoidfeature = false
		end
		if WeaponDefs[id].edgeeffectiveness and tonumber(WeaponDefs[id].edgeeffectiveness)>0 then
			if explosiveWeapons[WeaponDefs[id].weapontype] and tonumber(WeaponDefs[id].areaofeffect)<145 then
					WeaponDefs[id].areaofeffect = math.min(WeaponDefs[id].areaofeffect / (1 - WeaponDefs[id].edgeeffectiveness), 160)
					WeaponDefs[id].edgeeffectiveness = 0
					WeaponDefs[id].avoidfeature = false
			end
		end
	end
	if WeaponDefs[id].weapontype == "Cannon" and WeaponDefs[id].range and not WeaponDefs[id].mygravity and not WeaponDefs[id].cylindertargetting then
		WeaponDefs[id].mygravity = customGravity
		WeaponDefs[id].weaponvelocity = math.sqrt(WeaponDefs[id].range * velGravFactor)
		WeaponDefs[id].gravityaffected = true
		WeaponDefs[id].heightboostfactor = 0.04
	elseif inertialessWeapons[WeaponDefs[id].weapontype] then
		WeaponDefs[id].impulseboost = 0
		WeaponDefs[id].impulsefactor = 0
	end
	if WeaponDefs[id].cratermult then 
		WeaponDefs[id].cratermult = WeaponDefs[id].cratermult * 0.4
	else
		WeaponDefs[id].cratermult = 0.4
	end
	if WeaponDefs[id].craterboost then
		WeaponDefs[id].craterboost = WeaponDefs[id].craterboost * 0.4
	else
		WeaponDefs[id].craterboost = 0
	end
end



if (modOptions) then

--------------------------------------------------------------------------------
-- Relistical scaling

if (modOptions.realscale and tobool(modOptions.realscale)) then
  local rngMul, velMul, stVelMul, acclMul, fltMul, durMul
  for id in pairs(WeaponDefs) do
	if (WeaponDefs[id].weapontype == "LaserCannon" or WeaponDefs[id].weapontype == "BeamLaser" or WeaponDefs[id].weapontype == "EmgCannon" or WeaponDefs[id].weapontype == "LightningCannon") then
		rngMul, velMul, stVelMul, acclMul, fltMul, durMul = 5, 4, 4, 0.5, 1, 0.5
		if (WeaponDefs[id].cegtag) then
			WeaponDefs[id].cegtag = ""
		end
	elseif (WeaponDefs[id].weapontype == "StarburstLauncher") then
		rngMul, velMul, stVelMul, acclMul, fltMul, durMul = 9, 2, 2, 1.5, 5, 1	
		if (WeaponDefs[id].cegtag) then
			WeaponDefs[id].cegtag = ""
		end
	elseif (WeaponDefs[id].weapontype == "MissileLauncher") then 
		rngMul, velMul, stVelMul, acclMul, fltMul, durMul = 9, 3, 3, 1, 5, 1
		if (WeaponDefs[id].cegtag) then
			WeaponDefs[id].cegtag = ""
		end
	elseif (WeaponDefs[id].weapontype == "TorpedoLauncher") then 
		rngMul, velMul, stVelMul, acclMul, fltMul, durMul = 7, 2, 2, 1.3, 3, 1
	elseif (WeaponDefs[id].weapontype == "Flame" or WeaponDefs[id].weapontype == "DGun" or WeaponDefs[id].weapontype == "AircraftBomb") then 
		rngMul, velMul, stVelMul, acclMul, fltMul, durMul = 2, 2, 2, 0.5, 1, 2
	elseif (WeaponDefs[id].weapontype == "Melee") then 
		rngMul, velMul, stVelMul, acclMul, fltMul, durMul = 1, 1, 1, 1, 1, 1
	else
		rngMul, velMul, stVelMul, acclMul, fltMul, durMul = 9, 3, 3, 0.333, 1, 1
	end
	if (WeaponDefs[id].range) then
		WeaponDefs[id].range = rngMul * WeaponDefs[id].range
	end
	if (WeaponDefs[id].weaponvelocity) then
		WeaponDefs[id].weaponvelocity = velMul * WeaponDefs[id].weaponvelocity
	end
	if (WeaponDefs[id].startvelocity) then
		WeaponDefs[id].startvelocity = stVelMul * WeaponDefs[id].startvelocity
	end
	if (WeaponDefs[id].weaponacceleration) then
		WeaponDefs[id].weaponacceleration = acclMul * WeaponDefs[id].weaponacceleration
	end
	if (WeaponDefs[id].flighttime) then
		WeaponDefs[id].flighttime = fltMul * WeaponDefs[id].flighttime
	end
	if (WeaponDefs[id].duration) then
		WeaponDefs[id].duration = durMul * WeaponDefs[id].duration
	end
	if (WeaponDefs[id].sprayangle) then
		WeaponDefs[id].duration = WeaponDefs[id].sprayangle / rngMul
	end
  end
end

--------------------------------------------------------------------------------
-- Don't Collide with friendlies for all weapons

if (modOptions.nocollide and tobool(modOptions.nocollide)) then
  for id in pairs(WeaponDefs) do
	WeaponDefs[id].collidefriendly = false
  end
end

-- Low performance computer mode
if (modOptions.lowcpu and tobool(modOptions.lowcpu)) then
  for id in pairs(WeaponDefs) do
	WeaponDefs[id].cegtag = "" 
	if WeaponDefs[id].reloadtime and tonumber(WeaponDefs[id].reloadtime)<0.5 then
		WeaponDefs[id].reloadtime = WeaponDefs[id].reloadtime * 2
		if WeaponDefs[id].energypershot then WeaponDefs[id].energypershot = WeaponDefs[id].energypershot * 2 end
		if WeaponDefs[id].metalpershot then WeaponDefs[id].metalpershot = WeaponDefs[id].metalpershot * 2 end
		if WeaponDefs[id].beamtime then WeaponDefs[id].beamtime = WeaponDefs[id].beamtime * 2 end
		for weap, dmg in pairs(WeaponDefs[id].damage) do
			WeaponDefs[id].damage[weap] = dmg * 2
		end
	end
  end
end

end