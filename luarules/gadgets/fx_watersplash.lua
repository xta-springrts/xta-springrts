
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


if gadgetHandler:IsSyncedCode() then
	
	----------------------
	-- ONLY SYNCED PART --
	----------------------
	
	local splashCEG							= "verticalbomb"
	local splashCEGshallow					= "torpedoold"
	local smokeCEG							= "torpedosmoke"
	local subsurfaceCEG						= "torpedoold"
	local torpedoCEG						= "torpedosmokesmall"
	local lavaCEG1							= "napalam"
	local lavaCEG2							= "SMOKESHELL_Small"
	--local duckCEG							= "blplasmaballbloom"
	local duckSND							= 'sounds/battle/ducks.ogg'
		
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
	local AirProjectiles					= {}
	
	local nonexplosiveWeapons = {
		LaserCannon = true,
		BeamLaser = true,
		EmgCannon = true,
		Flame = true,
		LightningCannon = true,
	}
	
	local aerialTorpedoes = {
		[WeaponDefNames["armair_torpedo"].id] = true, -- Arm Lancet, lost_osprey
		[WeaponDefNames["armseap_weapon1"].id] = true, -- Arm Albatross, Core Typhoon, lost_fisher, 
		[WeaponDefNames["corair_torpedo"].id] = true, -- Core Titan
	}
	
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
		if (waterColour and waterColour[1] > waterColour[3]) or Game.waterDamage > 0 then
			isLava = true
		end
		Spring.Log("Gadget", LOG.INFO,"fx_watersplash: lava detected:",isLava)
		for id,Def in pairs(WeaponDefs) do
			if aerialTorpedoes[id] or (Def.damageAreaOfEffect ~= nil and Def.damageAreaOfEffect > 16 and not nonexplosiveWeapons[Def.type]) then
				SetWatchWeapon(Def.id, true)
				--Echo("Watching weapon:",Def.name,Def.type,Def.damageAreaOfEffect)
			end
		end
	end
	
	function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)	
		if aerialTorpedoes[weaponDefID] then
			local _,y,_ = Spring.GetProjectilePosition(proID)
			if y and y > 0 then
				AirProjectiles[proID] = true
			end
		end
	end
	
	function gadget:ProjectileDestroyed(proID)
		AirProjectiles[proID] = nil
	end
	
	function gadget:GameFrame(frame)
		if frame%8 == 0 then
			for proID in pairs (AirProjectiles) do
				local x,y,z = Spring.GetProjectilePosition(proID)		
				if y <= 0 then
					AirProjectiles[proID] = nil
					SpawnCEG(torpedoCEG, x, y, z ,0,1,0,10,0)
				end
			end
		end
	end
	
	function gadget:Shutdown()
		for id,Def in pairs(WeaponDefs) do
			if aerialTorpedoes[id] or (Def and Def.damageAreaOfEffect ~= nil and Def.damageAreaOfEffect > 16 and not nonexplosiveWeapons[Def.type]) then
				SetWatchWeapon(Def.id, false)
			end
		end
	end
end