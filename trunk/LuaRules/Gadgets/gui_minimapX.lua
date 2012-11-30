
function gadget:GetInfo()
  return {
    name      = "gui_minimapX",
    desc      = "Draws an X for nukes in minimap (when in radar)",
	version   = "1.0",
    author    = "Jools",
    date      = "Movember,2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

-- shared synced/unsynced globals
LUAUI_DIRNAME							= 'LuaUI/'
local random  = math.random
local abs = math.abs
local Echo = Spring.Echo
local LUAMESSAGE = 	"20121130"


local nukeWeapons = {
	fmd_rocket = true,
	crblmssl = true,
	armscab_weapon = true,
	nuclear_missile = true,
	amd_rocket = true,
	armemp_weapon = true,
	}

local nukeList = {}
	
if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------
	local clientID, clientAllyID, clientIsSpec
	local GetProjectilePosition = Spring.GetProjectilePosition
	local IsPosInRadar = Spring.IsPosInRadar
				
	function gadget:Initialize()	
		for id,weaponDef in pairs(WeaponDefs) do
			local wName = weaponDef.name
			if nukeWeapons[wName] then 
				Script.SetWatchWeapon(weaponDef.id, true) 
				--Echo("Watching weapon: ",wName,weaponDef.id)
			end
		end
	end

	
	function gadget:ProjectileCreated(projectileID, projectileOwnerID, projectileWeaponDefID)
		local x,y,z = Spring.GetProjectilePosition(projectileID)
		local inRadar = Spring.IsPosInRadar(x, y, z, clientAllyID)
		
		local wName
		if WeaponDefs[projectileWeaponDefID] then wName = WeaponDefs[projectileWeaponDefID].name end
		if wName and nukeWeapons[wName] then
			local teamID = Spring.GetUnitTeam(projectileOwnerID)
			table.insert(nukeList,{projectileID, x,y,z, inRadar,teamID})
			--Echo("Nuke added:",#nukeList, inRadar, projectileOwnerID,teamID)
		end
	end

	function gadget:ProjectileDestroyed(projectileID)
		for i,array in ipairs(nukeList) do
			if array[1] == projectileID then table.remove(nukeList,i) return end	
		end
	end
	
	function gadget:GameFrame(frame)
		if frame%3 == 0 then
			for i,array in ipairs(nukeList) do
				local x,y,z = GetProjectilePosition(array[1])
				local inRadar = IsPosInRadar(x, y, z, clientAllyID)
				array[2] = x
				array[3] = y
				array[4] = z
				array[5] = inRadar
			end
			_G.nukeList = nukeList
		end
	end
	
	function gadget:RecvLuaMsg(msg, playerID)
		--Spring.Echo("Got a message from " .. playerID .. " :",msg,string.len(msg))
		if msg and string.len(msg) >= 9 then	
			local sms = string.sub(msg, string.len(LUAMESSAGE)+1) 
			clientID = tonumber(string.sub(sms,1,1))
			--Echo("Local client = ", clientID)
			_,_,clientIsSpec,_,clientAllyID = Spring.GetPlayerInfo(clientID)
		end
	end
	
	function gadget:Shutdown()
		for id,weaponDef in pairs(WeaponDefs) do
			local wName = weaponDef.name
			if weaponDef ~= nil and nukeWeapons[wName] then 
				Script.SetWatchWeapon(weaponDef.id, false)
			end
		end
	end
else
	-------------------
	-- UNSYNCED PART --
	-------------------

	local mapX = Game.mapX * 512
	local mapY = Game.mapY * 512
	local GetTeamColor = Spring.GetTeamColor
	function gadget:Initialize()
		local pID = Spring.GetLocalPlayerID()
		Spring.SendLuaRulesMsg(LUAMESSAGE .. pID)
	end

	function gadget:DrawInMiniMap(sx, sy)
		local ratioX = sx / mapX
		local ratioY = sy / mapY
		
		local drawList = SYNCED.nukeList
		
		gl.PushMatrix()
		gl.Color(1, 1, 1, 1)
		if drawList then
			for i, nuke in sipairs(drawList) do
				local id = nuke[1]
				local x = nuke[2]
				local y = nuke[4]
				local inRadar = nuke[5]
				local teamID = nuke[6]
				local red
				local green
				local blue
				red, green, blue = GetTeamColor(teamID)
				gl.Color(red, green, blue, 1)
				--Echo("Nuke ",i, x,y, inRadar)
				if inRadar then
					gl.Text("X", x*ratioX, sy-y*ratioY, 10, 'cv')
				end
			end
		end
	end
end