
function gadget:GetInfo()
  return {
    name      = "Watereffects",
    desc      = "Make splash sound in water",
	version   = "1.1",
    author    = "Jools",
    date      = "Jan, 2013",
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
	local splashCEGshallow					= "torpedoold"
	local shockCEG							= "torpedo"
	--local duckCEG							= "blplasmaballbloom"
	local duckSND							= 'sounds/ducks.ogg'
	
	local PlaySoundFile						= Spring.PlaySoundFile
	local shallowLimit						= -25
	local shallowHitLimit					= -5
	local GetGroundHeight					= Spring.GetGroundHeight
	local Echo 								= Spring.Echo
	local SpawnCEG							= Spring.SpawnCEG
	local SetWatchWeapon					= Script.SetWatchWeapon
	local volume 							= 3.0
	local Channel	 						= 'battle'
	
	
	function gadget:Explosion(weaponID, px, py, pz, ownerID)
		local groundHeight = GetGroundHeight(px,pz)
		local isWater = groundHeight < 0
		local isShallow = groundHeight > shallowLimit
		local aoe = WeaponDefs[weaponID]["damageAreaOfEffect"] / 2
		local wType = WeaponDefs[weaponID].type
		
		-- Echo("Water depth = ", groundHeight, isWater, isShallow, py)
		if not nonexplosiveWeapons[wType] and isWater and abs(py) <= aoe and py <= 0 then
			if py > shallowHitLimit then -- hits close to water surface
				SpawnCEG(splashCEG, px+random(-aoe,aoe), py, pz+random(-aoe,aoe),0,1,0,aoe,aoe)
				if isShallow then SpawnCEG(splashCEGshallow, px, 0, pz) end
			else -- subsurface hit
				SpawnCEG(shockCEG, px+random(-aoe,aoe), py, pz+random(-aoe,aoe),0,1,0,aoe,aoe)
				--Echo("Deep water explosion")
			end
			
			if isShallow then
				local rnd = random()
				--Echo(rnd)
				if rnd > 0.99 then
					PlaySoundFile(duckSND, volume, px, 100, pz,0,0,0,Channel)
					--SpawnCEG(duckCEG, px, py, pz,0,0,0,aoe,0)
					--Echo("Some ducks were hit")
				end
			end
			
			
			
		end
		return false
	end
	
	function gadget:Initialize()
		
		for id,Def in pairs(WeaponDefs) do
			if Def.damageAreaOfEffect ~= nil and Def.damageAreaOfEffect > 16 and not nonexplosiveWeapons[Def.type] then
				SetWatchWeapon(Def.id, true)
			end
		end
	end
	
	function gadget:Shutdown()
		for id,Def in pairs(WeaponDefs) do
			if Def and Def.damageAreaOfEffect ~= nil and Def.damageAreaOfEffect > 16 and not nonexplosiveWeapons[Def.type] then
				SetWatchWeapon(Def.id, false)
			end
		end
	end
end