
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
	
	local splashCEG1					= "verticalbomb"
	local splashCEG2					= "torpbomb"
	local sndWater 						= "Sounds/SPLSHBIG.WAV"
	
	function gadget:Explosion(weaponID, px, py, pz, ownerID)
		local isWater = Spring.GetGroundHeight(px,pz) < 0
		local isShallow = Spring.GetGroundHeight(px,pz) > -50
		local aoe = WeaponDefs[weaponID]["damageAreaOfEffect"] / 2
		local wType = WeaponDefs[weaponID].type
		
		--Spring.Echo("Water depth = ", Spring.GetGroundHeight(px,pz), isWater, isShallow)
		if not nonexplosiveWeapons[wType] and isWater and abs(py) <= aoe then		
			Spring.SpawnCEG(splashCEG1, px+random(-aoe,aoe), py, pz+random(-aoe,aoe),0,1,0,aoe,aoe)
			if isShallow then
				Spring.SpawnCEG(splashCEG2, px, 0, pz)
				--Spring.Echo("Shallow water explosion:", weaponID)
				--Spring.PlaySoundFile(sndWater,15.0,px,0,pz) -- now indluded in mod
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