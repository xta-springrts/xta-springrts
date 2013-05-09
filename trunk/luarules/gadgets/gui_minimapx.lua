
function gadget:GetInfo()
  return {
    name      = "gui_minimapX",
    desc      = "Draws an X for nukes in minimap (when in radar)",
	version   = "1.0",
    author    = "Jools",
    date      = "November,2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

-- shared synced/unsynced globals
LUAUI_DIRNAME							= 'LuaUI/'
local ipairs = ipairs

local random  = math.random
local tainsert = table.insert
local taremove = table.remove
local abs = math.abs
local Echo = Spring.Echo
local LUAMESSAGE = 	"20121130"


local nukeWeapons = {
	fmd_rocket = true, -- Core_Resistor, core_fortitude_missile_defense
	crblmssl = true, -- core_silencer
	armscab_weapon = true, -- arm_scarab
	nuclear_missile = true, -- arm_retaliator
	amd_rocket = true, -- arm_protector, arm_repulsor
	armemp_weapon = true, --arm_stunner
	cortron_weapon = true, -- core_neutron 
	corabm_weapon = true, -- core_hedgehog
	}

	
	
local nukeList = {}
	
if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------
	local clientID, clientAllyID, clientIsSpec
	local GetProjectilePosition = Spring.GetProjectilePosition
	local IsPosInRadar = Spring.IsPosInRadar
	local GetUnitTeam = Spring.GetUnitTeam
				
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
		if WeaponDefs[projectileWeaponDefID] then
			local wName = WeaponDefs[projectileWeaponDefID].name
			--Echo("Weapon:",wName)
			if nukeWeapons[wName] then
				local x,y,z = GetProjectilePosition(projectileID)
				local inRadar = IsPosInRadar(x, y, z, clientAllyID)
				local teamID = GetUnitTeam(projectileOwnerID)
				nukeList[projectileID] = {x,y,z, inRadar,teamID}
				--Echo("Nuke added:",#nukeList, inRadar, projectileOwnerID,teamID)
			end
		end
	end

	function gadget:ProjectileDestroyed(projectileID)
		nukeList[projectileID] = nil
	end
	
	function gadget:GameFrame(frame)
		if frame%4 == 0 then
			for i,array in pairs(nukeList) do
				local x,y,z = GetProjectilePosition(i)
				--local inRadar = IsPosInRadar(x, y, z, clientAllyID)
				array[1] = x
				array[2] = y
				array[3] = z
				array[4] = true
			end
			_G.nukeList = nukeList
		end
	end
	
	function gadget:RecvLuaMsg(msg, playerID)
		--Spring.Echo("Got a message from " .. playerID .. " :",msg,string.len(msg))
		local minimapX_msg = (msg:find(LUAMESSAGE,1,true))
		if msg and string.len(msg) >= 9 and minimapX_msg then	
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
	local glPushMatrix = gl.PushMatrix
	local glColor = gl.Color
	local glText = gl.Text
	local glPopMatrix = gl.PopMatrix
	local spairs = spairs
	
	local mapX = Game.mapX * 512
	local mapY = Game.mapY * 512
	local GetTeamColor = Spring.GetTeamColor
	
	function gadget:Initialize()
		local pID = Spring.GetLocalPlayerID()
		Spring.SendLuaRulesMsg(LUAMESSAGE .. pID)
	end

	function gadget:DrawInMiniMap(sx, sy)
		local drawList = SYNCED.nukeList
		
		if drawList then
			local ratioX = sx / mapX
			local ratioY = sy / mapY
			glPushMatrix()
			for _, nuke in spairs(drawList) do
				--local id = nuke[1]
				local x = nuke[1]
				local y = nuke[3]
				local inRadar = nuke[4]
				local teamID = nuke[5]
				local red, green, blue = GetTeamColor(teamID)
				glColor(red, green, blue, 1)
				--Echo("Nuke ", x,y, inRadar)
				if inRadar then
					glText("X", x*ratioX, sy-y*ratioY, 10, 'cv')
				end
			end
			glPopMatrix()
			glColor(1, 1, 1, 1)
		end
	end
end