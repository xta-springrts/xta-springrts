
function gadget:GetInfo()
  return {
    name      = "gui_minimapX",
    desc      = "Draws an X for nukes in minimap (when in radar)",
	version   = "1.1",
    author    = "Jools, DeadnightWarrior",
    date      = "23 Oct 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------

	local spGetProjectileDefID = Spring.GetProjectileDefID
	local spGetUnitTeam = Spring.GetUnitTeam

	local nukeWeapons = {
		[WeaponDefNames["fmd_rocket"].id] = true,		-- Core_Resistor, core_fortitude_missile_defense
		[WeaponDefNames["crblmssl"].id] = true,			-- core_silencer
		[WeaponDefNames["armscab_weapon"].id] = true,	-- arm_scarab
		[WeaponDefNames["nuclear_missile"].id] = true,	-- arm_retaliator
		[WeaponDefNames["amd_rocket"].id] = true,		-- arm_protector, arm_repulsor
		[WeaponDefNames["armemp_weapon"].id] = true,	-- arm_stunner
		[WeaponDefNames["cortron_weapon"].id] = true,	-- core_neutron 
		[WeaponDefNames["cormabm_weapon"].id] = true,	-- core_hedgehog
		[WeaponDefNames["freezermp"].id] = true,		-- lost_freezer: Tracking Emp Energy Cannon
		[WeaponDefNames["lostcruisenuclear"].id] = true,-- lost_revenger: Powerful Cruise Nuke
		[WeaponDefNames["peacemaker_rocket"].id] = true,-- lost_peacemaker and lost_turtle: anti and mobile anti
	}

	function gadget:Initialize()	
		for id in pairs(nukeWeapons) do
			Script.SetWatchWeapon(id, true) 
		end
	end

	function gadget:ProjectileCreated(projectileID, projectileOwnerID, projectileWeaponDefID)
		if nukeWeapons[projectileWeaponDefID] then
			SendToUnsynced('MMX_ShowProjectile', projectileID, spGetUnitTeam(projectileOwnerID))
		end
	end

	function gadget:ProjectileDestroyed(projectileID)
		if nukeWeapons[spGetProjectileDefID(projectileID)] then
			SendToUnsynced('MMX_ProjectileDestroyed', projectileID)
		end
	end

	function gadget:Shutdown()
		for id in pairs(nukeWeapons) do
			Script.SetWatchWeapon(id, false)
		end
	end

else
	-------------------
	-- UNSYNCED PART --
	-------------------
	local glColor = gl.Color
	local glText = gl.Text
	local glBeginText = gl.BeginText
	local glEndText = gl.EndText
	local spGetProjectilePosition = Spring.GetProjectilePosition
	local schar = string.char
	local floor = math.floor
	local max = math.max
	
	local mapX = Game.mapX * 512
	local mapY = Game.mapY * 512
	local GetTeamColor = Spring.GetTeamColor
	local drawList = {}
	local teamColourX = {}
	
	local function MMX_ShowProjectile(_, projectileID, teamID)
		drawList[projectileID] = teamID
	end

	local function MMX_ProjectileDestroyed(_,projectileID)
		drawList[projectileID] = nil
	end

	function gadget:Initialize()		
		gadgetHandler:AddSyncAction('MMX_ShowProjectile', MMX_ShowProjectile)
		gadgetHandler:AddSyncAction('MMX_ProjectileDestroyed', MMX_ProjectileDestroyed)	
		local teams = Spring.GetTeamList()
		for _, teamID in pairs(teams) do
			local r, g, b = Spring.GetTeamColor(teamID)
			teamColourX[teamID] = table.concat({"\255",schar(max(1, floor(r*255)+0.5)),schar(max(1, floor(g*255)+0.5)),schar(max(1, floor(b*255)+0.5)),"X"})
		end
	end

	function gadget:DrawInMiniMap(sx, sy)
		if drawList then
			local ratioX = sx / mapX
			local ratioY = sy / mapY
			glColor(1, 1, 1, 1)
			glBeginText()
			for projID, teamID in pairs(drawList) do
				local x,y,z = spGetProjectilePosition(projID)
				if x then
					glText(teamColourX[teamID], x*ratioX, sy-z*ratioY, 10, 'cv')
				end
			end
			glEndText()
		end
	end
end