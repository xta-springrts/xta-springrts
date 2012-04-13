
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
		local random  = math.random
		local isWater = Spring.GetGroundHeight(px,pz) < 0
		local aoe = WeaponDefs[weaponID]["damageAreaOfEffect"]
		if isWater and py < 10 then
			Spring.SpawnCEG(splashCEG1, px+random(-aoe/2,aoe/2), py, pz+random(-aoe/2,aoe/2))
			if aoe > 40 then Spring.SpawnCEG(splashCEG2, px, 0, pz) end
			Spring.PlaySoundFile(sndWater,15.0,px,0,pz)
			--Spring.Echo("Explosion!", weaponID, ownerID, Spring.GetGroundInfo(px,pz),aoe)
			return true
		else
			return false
		end
	end
	
	function gadget:Initialize()
		Spring.SendCommands ("cheat") 
		Spring.SendCommands ("globallos")
		Spring.SendCommands ("nocost")
	
		for id,Def in pairs(WeaponDefs) do
			local weaponID
			-- for i,v in Def:pairs() do
				-- Spring.Echo(id,i,v)
			-- end
			if Def["damageAreaOfEffect"] ~= nil and Def["damageAreaOfEffect"] > 15 and Def["myGravity"] > 0 then
				weaponID = Def["id"]
				Script.SetWatchWeapon(weaponID, true)
				--Spring.Echo(Def["name"] .. " added: AOE = " .. Def["damageAreaOfEffect"] .. " Gravity =" .. Def["myGravity"] )
			end
		end


		--local bombDefID = WeaponDefNames["TheNameOfMyAwesomeBombWeapon"].id -- change to suit :P
		--Script.SetWatchWeapon(bombDefID, true)
		--en
	end
end