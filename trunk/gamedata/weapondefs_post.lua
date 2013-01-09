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

local function hs2rgb(h, s)
	--// FIXME? ignores saturation completely
	s = 1

	local invSat = 1 - s

	if (h > 0.5) then h = h + 0.1 end
	if (h > 1.0) then h = h - 1.0 end

	local r = invSat / 2.0
	local g = invSat / 2.0
	local b = invSat / 2.0

	if (h < (1.0 / 6.0)) then
		r = r + s
		g = g + s * (h * 6.0)
	elseif (h < (1.0 / 3.0)) then
		g = g + s
		r = r + s * ((1.0 / 3.0 - h) * 6.0)
	elseif (h < (1.0 / 2.0)) then
		g = g + s
		b = b + s * ((h - (1.0 / 3.0)) * 6.0)
	elseif (h < (2.0 / 3.0)) then
		b = b + s
		g = g + s * ((2.0 / 3.0 - h) * 6.0)
	elseif (h < (5.0 / 6.0)) then
		b = b + s
		r = r + s * ((h - (2.0 / 3.0)) * 6.0)
	else
		r = r + s
		b = b + s * ((3.0 / 3.0 - h) * 6.0)
	end

	return ("%0.3f %0.3f %0.3f"):format(r,g,b)
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
  
  if (not wd.rgbcolor) then
    if (wd.weapontype == "Cannon") then
      wd.rgbcolor = "1.0 0.5 0.0"
    elseif (wd.weapontype == "EmgCannon") then
      wd.rgbcolor = "0.9 0.9 0.2"
    else
      local hue = (wd.color or 0) / 255
      local sat = (wd.color2 or 0) / 255
      wd.rgbcolor = hs2rgb(hue, sat)
    end
  end
  
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
	DGun = true,
}

local modOptions = Spring.GetModOptions()

-- Adjustment of terrain damage, area of effect, kinetic force of weapons and cannon trajectory height
local customGravity = 0.45
local maxRangeAngle = 38  --in degrees >0 and <=45
if modOptions and modOptions.gravity then customGravity=modOptions.gravity end
local velGravFactor = customGravity * 900 / math.sin(math.rad(2 * maxRangeAngle))
local interceptorStyle = 2
if modOptions and modOptions.nuke then interceptorStyle = modOptions.nuke end

for id in pairs(WeaponDefs) do
	WeaponDefs[id].soundhitwet = ""
	if WeaponDefs[id].range and tonumber(WeaponDefs[id].range) < 550 or explosiveWeapons[WeaponDefs[id].weapontype] then
		WeaponDefs[id].avoidfeature = false
	end
	if explosiveWeapons[WeaponDefs[id].weapontype] then
		if WeaponDefs[id].edgeeffectiveness and tonumber(WeaponDefs[id].edgeeffectiveness)>0 and tonumber(WeaponDefs[id].areaofeffect)<145 then
			WeaponDefs[id].areaofeffect = math.min(WeaponDefs[id].areaofeffect / (1 - WeaponDefs[id].edgeeffectiveness), 160)
			WeaponDefs[id].edgeeffectiveness = 0
			WeaponDefs[id].avoidfeature = false
		end
		if WeaponDefs[id].weapontype == "Cannon" and WeaponDefs[id].range and not WeaponDefs[id].mygravity and not WeaponDefs[id].cylindertargeting then
			WeaponDefs[id].mygravity = customGravity
			WeaponDefs[id].weaponvelocity = math.sqrt(WeaponDefs[id].range * velGravFactor)
			WeaponDefs[id].gravityaffected = true
			WeaponDefs[id].heightboostfactor = 0.04
		elseif WeaponDefs[id].interceptor then
			WeaponDefs[id].interceptor = interceptorStyle
		end
		if WeaponDefs[id].weapontype == "TorpedoLauncher" then
			WeaponDefs[id].soundhitwet = WeaponDefs[id].soundhitdry
		else
			local AoE = tonumber(WeaponDefs[id].areaofeffect) or 0
			if AoE<50 then
				WeaponDefs[id].soundhitwet = "splshbig"
			elseif AoE<88 then
				WeaponDefs[id].soundhitwet = "splssml"
			elseif AoE<145 then
				WeaponDefs[id].soundhitwet = "splsmed"
			elseif AoE>450 then
				WeaponDefs[id].soundhitwet = WeaponDefs[id].soundhitdry
			else
				WeaponDefs[id].soundhitwet = "splslrg"
			end
		end
	elseif inertialessWeapons[WeaponDefs[id].weapontype] then
		WeaponDefs[id].impulseboost = 0
		WeaponDefs[id].impulsefactor = 0
		WeaponDefs[id].soundhitwet = "sizzle"		
		if WeaponDefs[id].weapontype == "LaserCannon" then
			WeaponDefs[id].cegtag = ""	-- we use the projectile lights widget now
		elseif WeaponDefs[id].weapontype == "BeamLaser" then
			WeaponDefs[id].soundhitdry = ""
			WeaponDefs[id].soundtrigger = 1
		end
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

--- Localised sounds, put sounds in customparams and access them from snd_local gadget.
--- NOTE:
---    dguns are excluded from this since the gadget breaks Spring's ability to
---    limit playback concurrency which we want for the dgun's explosion sounds
if modOptions and modOptions.globalsounds ~= '1' then
	Spring.Echo("Weapons_post: Local sound option detected")

	for id, weaponDef in pairs(WeaponDefs) do
		if (weaponDef.name == nil or weaponDef.name:find("Disintegrator") == nil) then
			--Spring.Echo("Old weaponsdef:",id,WeaponDefs[id].soundhitwet)
			if weaponDef.soundhitwet then
				if not weaponDef.customparams then
					weaponDef.customparams = {}
				end
				weaponDef.customparams.soundhitwet = weaponDef.soundhitwet -- for sound localisation gadget
			end
		
			if weaponDef.soundhitdry then
				if not weaponDef.customparams then
					weaponDef.customparams = {}
				end
				weaponDef.customparams.soundhitdry = weaponDef.soundhitdry -- for sound localisation gadget
			end
		
			if weaponDef.soundstart then
				if not weaponDef.customparams then
					weaponDef.customparams = {}
				end
				weaponDef.customparams.soundstart = weaponDef.soundstart -- for sound localisation gadget
			end
			weaponDef.soundhitwet = nil
			weaponDef.soundhitdry = nil
			weaponDef.soundstart = nil
			--Spring.Echo("New weaponsdef:",id,WeaponDefs[id].soundhitwet)
		end
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
