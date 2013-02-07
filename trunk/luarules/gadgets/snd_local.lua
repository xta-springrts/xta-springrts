
function gadget:GetInfo()
  return {
    name      = "snd_local",
    desc      = "Make sounds local based on LOS",
	version   = "1.2",
    author    = "Jools",
    date      = "Jan, 2013",
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
local PROJECTILE_GENERATED_EVENT_ID = 10011
local PROJECTILE_DESTROYED_EVENT_ID = 10012
local PROJECTILE_EXPLOSION_EVENT_ID = 10013
local TEAM_DIED_EVENT_ID = 10014

local LUAMESSAGE = 	"20121120"

local Echo 					= Spring.Echo


if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------

	local SetWatchWeapon 		= Script.SetWatchWeapon
	local IsPosInLos			= Spring.IsPosInLos
	local GetProjectilePosition	= Spring.GetProjectilePosition
	local GetGroundHeight 		= Spring.GetGroundHeight
	local GetPlayerInfo			= Spring.GetPlayerInfo
	local len 					= string.len
	local sub 					= string.sub
		
	function gadget:Initialize()	
		local modOptions = Spring.GetModOptions()
		
		if modOptions and modOptions.globalsounds == '1' then
			Echo("[" .. (self:GetInfo()).name .. "] local sounds disabled")
			gadgetHandler:RemoveGadget(self)
		end
		
		for id,weaponDef in pairs(WeaponDefs) do
			if weaponDef.customParams then				
				SetWatchWeapon(weaponDef.id, true)
			end
		end
	end
	
	function gadget:GameFrame(frame)
		-- Test if gadget is really removed
		--if frame%30 == 0 then
			--Echo("Local sounds running for: " .. frame/30 .." seconds")
		--end	
	end
	
	function gadget:ProjectileCreated(projectileID, projectileOwnerID, projectileWeaponDefID)
		local x,y,z = GetProjectilePosition(projectileID)
		SendToUnsynced(PROJECTILE_GENERATED_EVENT_ID, projectileID, projectileOwnerID, projectileWeaponDefID, x,y,z)
	end

	function gadget:ProjectileDestroyed(projectileID)
		local x,y,z = GetProjectilePosition(projectileID)
		SendToUnsynced(PROJECTILE_DESTROYED_EVENT_ID, projectileID, y)
	end

	function gadget:Explosion(weaponDefID, posx, posy, posz, ownerID)
		local h = GetGroundHeight(posx,posz)
		SendToUnsynced(PROJECTILE_EXPLOSION_EVENT_ID, weaponDefID, posx, posy, posz, posz,h)
		return false -- noGFX
	end
		
	function gadget:Shutdown()
		for id,weaponDef in pairs(WeaponDefs) do
			if (weaponDef ~= nil) then
				SetWatchWeapon(weaponDef.id, false)
			end
		end
	end
	
	function gadget:PlayerAdded(playerID) 
		Echo("Player added:", playerID) -- doesn't seem to work
	end
	
	function gadget:TeamDied(teamID)
		SendToUnsynced(TEAM_DIED_EVENT_ID, teamID)
	end
	
	
else
	-------------------
	-- UNSYNCED PART --
	-------------------
	
	local GetLocalPlayerID				= Spring.GetLocalPlayerID
	local SendLuaRulesMsg				= Spring.SendLuaRulesMsg
	local PlaySoundFile					= Spring.PlaySoundFile
	local IsPosInLos					= Spring.IsPosInLos
	local GetLocalAllyTeamID			= Spring.GetLocalAllyTeamID
	local GetSpectatingState			= Spring.GetSpectatingState
	local len 							= string.len
	local tainsert						= table.insert
	local taremove						= table.remove
	local clientIsSpec					
	
	
	local sndwet = {}
	local snddry = {}
	local sndstart = {}
	local pID
	local allyID
	local pTable = {}
	local Channel 						= 'battle'
	local volume 						= 3.0
	local shallowLimit 					= -25
	local shallowHitLimit				= -5
	
	local nonexplosiveWeapons = {
		LaserCannon = true,
		BeamLaser = true,
		EmgCannon = true,
		Flame = true,
		LightningCannon = true,
		DGun = true,
	}


	
	function gadget:Initialize()
		
		pID = GetLocalPlayerID()
		allyID = GetLocalAllyTeamID()
		clientIsSpec = GetSpectatingState()
			
		--get weapon sounds from customparams
		for id, weaponDef in pairs(WeaponDefs) do
			--if (weaponDef.name == nil or weaponDef.name:find("Disintegrator") == nil) then
				if (weaponDef.customParams ~= nil) then
					if weaponDef.customParams.soundhitwet and len(weaponDef.customParams.soundhitwet) > 0 then
						sndwet[id] = weaponDef.customParams.soundhitwet
						--Echo("Wet sound for:", id, weaponDef.name, ":", sndwet[id])
					else
						--Echo("No wet sound for:", id, weaponDef.name)
					end
					if weaponDef.customParams.soundhitdry and len(weaponDef.customParams.soundhitdry) > 0 then
						snddry[id] = weaponDef.customParams.soundhitdry
					else
						--Echo("No dry sound for:", id, weaponDef.name)
					end
					if weaponDef.customParams.soundstart and len(weaponDef.customParams.soundstart) > 0 then
						sndstart[id] = weaponDef.customParams.soundstart
					else
						--Echo("No start sound for:", id, weaponDef.name)
					end
				end
			--end
		end
		
		-- Make a soundcheck of the available sounds
		local vol = 0
		--Echo("Loading sounds:", Spring.LoadSoundDef("gamedata/sounds.lua"))
		for i, snd in pairs(sndstart) do
			--Echo("Testing start sound:",i,snd)
			PlaySoundFile("sounds/" .. snd .. ".wav",vol,0,0,0,0,0,0,Channel)
		end
		for i, snd in pairs(sndwet) do
			--Echo("Testing wet sound:",i,snd)
			PlaySoundFile("sounds/" .. snd .. ".wav",vol,0,0,0,0,0,0,Channel)
		end
		for i, snd in pairs(snddry) do
			--Echo("Testing dry sound:",i,snd)
			PlaySoundFile("sounds/" .. snd .. ".wav",vol,0,0,0,0,0,0,Channel)
		end
		
		
	end
	
	function table.removekey(table, key)
		local element = table[key]
		table[key] = nil
		return element
	end
	
		
	--SendToUnsynced(PROJECTILE_GENERATED_EVENT_ID, projectileID, projectileOwnerID, projectileWeaponDefID, x,y,z)
	local function ProjectileCreated(projectileID, projectileOwnerID, projectileWeaponDefID,x,y,z)
		
		local wType 
		if WeaponDefs[projectileWeaponDefID] then wType = WeaponDefs[projectileWeaponDefID].type end
		
		--Echo("ProjectileCreated: ", projectileID, projectileWeaponDefID, LOS, wType)
		
		local LOS = clientIsSpec or IsPosInLos(x,y,z,allyID)
		
		if LOS and projectileWeaponDefID and sndstart[projectileWeaponDefID] then
			if wType then			
				--Echo("Normal weapon sound playing")
				PlaySoundFile("sounds/"..sndstart[projectileWeaponDefID]..".wav",volume,x,y,z,0,0,0,Channel)
			end
		end
	end
	
	local function ProjectileDestroyed(projectileID)		
		--table.remove(pTable,projectileID)
		for i,array in ipairs (pTable) do
			if array[3] == projectileID then taremove(pTable,i) end
		end
	end
	
	--SendToUnsynced(PROJECTILE_EXPLOSION_EVENT_ID, weaponDefID, posx, posy, posz, h)
	local function ProjectileExplosion(weaponDefID, x, y, z, gh)
			
	
		--Echo("ProjectileExplosion: ", weaponDefID, LOS, y,gh)
		-- This part determines what sound the explosion will play. In the following, the variable y is the height coordinate of 
		-- the projectile, whereas gh is that of the ground height. The wet sound is typically a splash sound, but we don't want splash 
		-- sounds in the following cases: i) explosion above water level ii) explosion very deep, like from torpedoes. If something hits 
		-- shallow water, we want both splash and land explosion. 
		
		local LOS = clientIsSpec or IsPosInLos(x,y,z,allyID)
		
		if LOS and weaponDefID then
				if gh >= 0 then -- explosion on land
				if snddry[weaponDefID] then PlaySoundFile("sounds/"..snddry[weaponDefID]..".wav",volume,x,y,z,0,0,0,Channel) end
				--Echo("Land")
			else -- explosion on water
				if y > 0 then -- hits something above water level, use dry sounds
					if snddry[weaponDefID] then PlaySoundFile("sounds/"..snddry[weaponDefID]..".wav",volume,x,y,z,0,0,0,Channel) end
					--Echo("On water but above water level")
				else
					if y > shallowHitLimit then -- projectile hits close to surface
						if gh > shallowLimit then -- water is shallow
							--Echo("Shallow water")
							if snddry[weaponDefID] then PlaySoundFile("sounds/"..snddry[weaponDefID]..".wav",volume/2,x,y,z,0,0,0,Channel) end
							if sndwet[weaponDefID] then PlaySoundFile("sounds/"..sndwet[weaponDefID]..".wav",volume/2,x,y,z,0,0,0,Channel) end
							
						else -- hits deep water
							--Echo("Deep water")
							if sndwet[weaponDefID] then PlaySoundFile("sounds/"..sndwet[weaponDefID]..".wav",volume,x,y,z,0,0,0,Channel) end
						end
					else -- projectile hits at a depth, ideally, there would be another type of explosion sound in this case. However,
						-- this is already considered in weapon explosions, for example the wet sound of torpedoes is xplodep2, which is
						-- a deep water sound. We still use standard wet sounds, this division is kept for future needs.
						if sndwet[weaponDefID] then PlaySoundFile("sounds/"..sndwet[weaponDefID]..".wav",volume,x,y,z,0,0,0,Channel) end
					end
				end
			end
		end
	end
	
	local function TeamDied(teamID)
		clientIsSpec = GetSpectatingState()
	end
	
	function gadget:PlayerChanged(playerID)
		Echo("Player Changed:",playerID) -- doesn't seem to work
		clientIsSpec = GetSpectatingState()
	end
	
	function gadget:RecvFromSynced(eventID, arg0, arg1, arg2, arg3, arg4, arg5)
		
		if eventID == PROJECTILE_GENERATED_EVENT_ID then
			ProjectileCreated(arg0, arg1, arg2, arg3, arg4, arg5)
		elseif eventID == PROJECTILE_DESTROYED_EVENT_ID then
			ProjectileDestroyed(arg0)
		elseif eventID == PROJECTILE_EXPLOSION_EVENT_ID then
			ProjectileExplosion(arg0, arg1, arg2, arg3, arg4)
		elseif eventID == TEAM_DIED_EVENT_ID then
			TeamDied(arg0)
		end
	end
end
