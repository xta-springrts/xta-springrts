
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
	local smokeCEG							= "torpedosmoke"
	local subsurfaceCEG						= "torpedoold" 
	local lavaCEG1							= "napalam"
	local lavaCEG2							= "SMOKESHELL_Small"
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
	local isLava 							= false
	
	
	function gadget:Explosion(weaponID, px, py, pz, ownerID)
		if py <= 0 then
			local groundHeight = GetGroundHeight(px,pz)
			if groundHeight < 0 and not nonexplosiveWeapons[WeaponDefs[weaponID].type] then
				local aoe = WeaponDefs[weaponID]["damageAreaOfEffect"] * 0.5
				if isLava then
					SpawnCEG(lavaCEG1, px+random(-aoe,aoe), py, pz+random(-aoe,aoe),0,1,0,aoe,0)
				else
					local isShallow = groundHeight > shallowLimit
					if py > shallowHitLimit then -- hits close to water surface
						SpawnCEG(splashCEG, px+random(-aoe,aoe), py, pz+random(-aoe,aoe),0,1,0,aoe,0)
						if isShallow then SpawnCEG(splashCEGshallow, px, 0, pz) end
					else -- subsurface hit
					-- in spring 95, there seems to be a new ceg tag for underwater effects, but nevertheless it looks better if spawned close to surface
						local spawnY = -aoe*0.25
						SpawnCEG(subsurfaceCEG, px+random(-aoe,aoe), spawnY, pz+random(-aoe,aoe),0,1,0,aoe,0)
					end
					
					if isShallow then
						local rnd = random()
						if rnd > 0.999 then
							PlaySoundFile(duckSND, volume, px, 100, pz,0,0,0,Channel)
							--SpawnCEG(duckCEG, px, py, pz,0,0,0,aoe,0)
							--Echo("Some ducks were hit")
						end
					end
				end
			end
		end
		return false
	end
	
	function gadget:Initialize()
		local waterColour = Game.waterBaseColor
		if waterColour and waterColour[1] > waterColour[3] then
			isLava = true
		end
		--Echo("Lava:", isLava)
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