
function gadget:GetInfo()
  return {
    name      = "Watereffects",
    desc      = "Make splash sound in water",
	version   = "1.0",
    author    = "Jools",
    date      = "April,2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

LUAUI_DIRNAME							= 'LuaUI/'
local random  = math.random
local abs = math.abs
local nonexplosiveWeapons = {
	LaserCannon = true,
	BeamLaser = true,
	EmgCannon = true,
	Flame = true,
	LightningCannon = true,
}

if not gadgetHandler:IsSyncedCode() then
	-------------------
	-- UNSYNCED PART --
	-------------------
	
else
	-----------------
	-- SYNCED PART --
	-----------------
	
	local splashCEG							= "verticalbomb"
	local splashCEGshallow					= "torpbomb"
	local shockCEG							= "Torpedoold"
	--local duckCEG							= "blplasmaballbloom"
	local duckSND							= 'sounds/ducks.ogg'
	
	function gadget:Explosion(weaponID, px, py, pz, ownerID)
		local groundHeight = Spring.GetGroundHeight(px,pz)
		local isWater = groundHeight < 0
		local isShallow = groundHeight > -50
		local aoe = WeaponDefs[weaponID]["damageAreaOfEffect"] / 2
		local wType = WeaponDefs[weaponID].type
		
		--Spring.Echo("Water depth = ", groundHeight, isWater, isShallow, py)
		if not nonexplosiveWeapons[wType] and isWater and abs(py) <= aoe and py <= 0 then
			if py > -2 then -- hits close to water surface
				Spring.SpawnCEG(splashCEG, px+random(-aoe,aoe), py, pz+random(-aoe,aoe),0,1,0,aoe,aoe)
				if isShallow then Spring.SpawnCEG(splashCEGshallow, px, 0, pz) end
			else -- deep water explosion
				Spring.SpawnCEG(shockCEG, px+random(-aoe,aoe), py, pz+random(-aoe,aoe),0,1,0,aoe,aoe)
				--Spring.Echo("Deep water explosiion")
			end
			
			if isShallow then
				local rnd = random()
				Spring.Echo(rnd)
				if rnd > 0.96 then
					Spring.PlaySoundFile(duckSND, 1.0, px, 250, pz,0,10,0,'sfx')
					--Spring.SpawnCEG(duckCEG, px, py, pz,0,0,0,aoe,0)
					--Spring.Echo("Some ducks were hit")
				end
			end
			
			
			
		end
		return false
	end
	
	function gadget:Initialize()
		--Spring.SendCommands ("cheat") 
		--Spring.SendCommands ("globallos")
		--Spring.SendCommands ("nocost")
	
		for id,Def in pairs(WeaponDefs) do
			local weaponID
			if Def.damageAreaOfEffect ~= nil and Def.damageAreaOfEffect > 16 and not nonexplosiveWeapons[Def.type] then
				Script.SetWatchWeapon(Def.id, true)
			end
		end
	end
end