
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
local Echo = Spring.Echo

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

	
if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------
	
	local GetProjectilePosition = Spring.GetProjectilePosition
	local IsPosInRadar = Spring.IsPosInRadar
	local GetUnitTeam = Spring.GetUnitTeam
	local nukeList = {}
				
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
				local x,_,z = GetProjectilePosition(projectileID)
				local teamID = GetUnitTeam(projectileOwnerID)
				nukeList[projectileID] = {x,z,teamID}
				-- if only minimap is used, there is no need for y component. However, y-coord is needed if radar check is to be enabled.
			end
		end
	end

	function gadget:ProjectileDestroyed(projectileID)
		nukeList[projectileID] = nil
		SendToUnsynced('MMX_ProjectileDestroyed', projectileID)
	end
	
	function gadget:GameFrame(frame)
		if frame%6 == 0 then
			for i,nuke in pairs(nukeList) do
				local x,_,z = GetProjectilePosition(i)
				nuke[1] = x
				nuke[2] = z
			end
			
			for id, nuke in pairs (nukeList) do
				SendToUnsynced('MMX_ShowProjectile', id, nuke[1], nuke[2],nuke[3]) -- eventID, nukeID, x, z, teamID
			end
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
	
	local mapX = Game.mapX * 512
	local mapY = Game.mapY * 512
	local GetTeamColor = Spring.GetTeamColor
	local clientIsSpec, clientAllyID
	local drawList = {}
	
	local function MMX_ShowProjectile(_,projectileID, x, z, teamID)
		drawList[projectileID] = {x,z,teamID}
	end
	
	local function MMX_ProjectileDestroyed(_,projectileID)
		drawList[projectileID] = nil
	end
	
	
	function gadget:Initialize()
		local clientID = Spring.GetLocalPlayerID()
		_,_,clientIsSpec,_,clientAllyID = Spring.GetPlayerInfo(clientID)
		
		gadgetHandler:AddSyncAction('MMX_ShowProjectile', MMX_ShowProjectile)
		gadgetHandler:AddSyncAction('MMX_ProjectileDestroyed', MMX_ProjectileDestroyed)	
	end
	
	function gadget:DrawInMiniMap(sx, sy)
		
		if drawList then
			local ratioX = sx / mapX
			local ratioY = sy / mapY
			glPushMatrix()
			for _, nuke in pairs(drawList) do
				local x = nuke[1] -- x in world map
				local y = nuke[2] -- z in world map
				local teamID = nuke[3]
				local inRadar = true -- IsPosInRadar(x, y, z, clientAllyID) -- needs y-coord to be sent from synced as well.
				local red, green, blue = GetTeamColor(teamID)
				glColor(red, green, blue, 1)
				if inRadar or clientIsSpec then
					glText("X", x*ratioX, sy-y*ratioY, 10, 'cv')
				end
			end
			glPopMatrix()
			glColor(1, 1, 1, 1)
		end
	end
end