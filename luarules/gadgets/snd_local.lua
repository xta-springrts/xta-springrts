
function gadget:GetInfo()
  return {
    name      = "snd_local",
    desc      = "Make sounds local based on LOS",
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
local PROJECTILE_GENERATED_EVENT_ID = 10011
local PROJECTILE_DESTROYED_EVENT_ID = 10012
local PROJECTILE_EXPLOSION_EVENT_ID = 10013
local LUAMESSAGE = 	"20121120"

if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------

	--local isWater = Spring.GetGroundHeight(px,pz) < 0
	--local aoe = WeaponDefs[weaponID]["damageAreaOfEffect"] / 2
	--local wType = WeaponDefs[weaponID].type
	
	local clientID
	local clientIsSpec
	local clientAllyID
		
	function gadget:Initialize()	
		--Spring.SendCommands ("cheat") 	
		--Spring.SendCommands ("nocost")
		
		local modOptions = Spring.GetModOptions()
		
		if modOptions and modOptions.globalsounds == '1' then
			Spring.Echo("[" .. (self:GetInfo()).name .. "] synced client has disabled local sounds")
			gadgetHandler:RemoveGadget(self)
		end
		
		for id,weaponDef in pairs(WeaponDefs) do
			if weaponDef.customParams then				
				Script.SetWatchWeapon(weaponDef.id, true)
			end
		end
	end
	
	function gadget:ProjectileCreated(projectileID, projectileOwnerID, projectileWeaponDefID)
		local x,y,z = Spring.GetProjectilePosition(projectileID)
		local clientLOS = clientIsSpec or Spring.IsPosInLos(x,y,z, clientAllyID)
		SendToUnsynced(PROJECTILE_GENERATED_EVENT_ID, projectileID, projectileOwnerID, projectileWeaponDefID, clientLOS,x,y,z)
	end

	function gadget:ProjectileDestroyed(projectileID)
		local x,y,z = Spring.GetProjectilePosition(projectileID)
		local clientLOS = clientIsSpec or Spring.IsPosInLos(x,y,z, clientAllyID)
		SendToUnsynced(PROJECTILE_DESTROYED_EVENT_ID, projectileID, clientLOS, y)
	end

	function gadget:Explosion(weaponDefID, posx, posy, posz, ownerID)
		local clientLOS = clientIsSpec or Spring.IsPosInLos(posx, posy, posz, clientAllyID)
		local h = Spring.GetGroundHeight(posx,posz)
		SendToUnsynced(PROJECTILE_EXPLOSION_EVENT_ID, weaponDefID, clientLOS, posz, posy, posz,h)
		return false -- noGFX
	end
	
	function gadget:RecvLuaMsg(msg, playerID)
		--Spring.Echo("Got a message from " .. playerID .. " :",msg,string.len(msg))
		local localSND_msg = (msg:find(LUAMESSAGE,1,true))
		if msg and string.len(msg) >= 9 and localSND_msg then	
			local sms = string.sub(msg, string.len(LUAMESSAGE)+1) 
			clientID = tonumber(string.sub(sms,1,1))
			--Echo("Local client = ", clientID)
			_,_,clientIsSpec,_,clientAllyID = Spring.GetPlayerInfo(clientID)
		end
	end
	
	function gadget:Shutdown()
		for id,weaponDef in pairs(WeaponDefs) do
			if (weaponDef ~= nil) then
				Script.SetWatchWeapon(weaponDef.id, false)
			end
		end
	end
else
	-------------------
	-- UNSYNCED PART --
	-------------------
	
	local sndwet = {}
	local snddry = {}
	local sndstart = {}
	local pID = Spring.GetLocalPlayerID()
	local pTable = {}
	local nonexplosiveWeapons = {
		LaserCannon = true,
		BeamLaser = true,
		EmgCannon = true,
		Flame = true,
		LightningCannon = true,
		DGun = true,
	}

	function gadget:Initialize()
		--Echo("Sound files:")
		--Echo("-------------")
		local pID = Spring.GetLocalPlayerID()
		Spring.SendLuaRulesMsg(LUAMESSAGE .. pID)
		for id, weaponDef in pairs(WeaponDefs) do
			if (weaponDef.name == nil or weaponDef.name:find("Disintegrator") == nil) then
				if (weaponDef.customParams ~= nil) then
					if weaponDef.customParams.soundhitwet and string.len(weaponDef.customParams.soundhitwet) > 0 then
						sndwet[id] = weaponDef.customParams.soundhitwet
					else
						--Echo("No wet sound for:", id, weaponDef.name)
					end
					if weaponDef.customParams.soundhitdry and string.len(weaponDef.customParams.soundhitdry) > 0 then
						snddry[id] = weaponDef.customParams.soundhitdry
					else
						--Echo("No dry sound for:", id, weaponDef.name)
					end
					if weaponDef.customParams.soundstart and string.len(weaponDef.customParams.soundstart) > 0 then
						sndstart[id] = weaponDef.customParams.soundstart
					else
						--Echo("No start sound for:", id, weaponDef.name)
					end
				end
			end
		end
	end
	
	function table.removekey(table, key)
		local element = table[key]
		table[key] = nil
		return element
	end
	
		
	--SendToUnsynced(PROJECTILE_GENERATED_EVENT_ID, projectileID, projectileOwnerID, projectileWeaponDefID, clientLOS,x,y,z)
	local function ProjectileCreated(projectileID, projectileOwnerID, projectileWeaponDefID, LOS, x,y,z)
		
		local wType 
		if WeaponDefs[projectileWeaponDefID] then wType = WeaponDefs[projectileWeaponDefID].type end
		
		--Echo("ProjectileCreated: ", projectileID, projectileWeaponDefID, LOS, wType)
		
		if LOS and projectileWeaponDefID and sndstart[projectileWeaponDefID] then
			if wType then
				if nonexplosiveWeapons[wType] then
					local soundBusy = false
					for i,array in ipairs (pTable) do
						local count = 0
						--Echo(i, array[1],array[2],array[3],"Match for: ",projectileOwnerID)
						if array[1] == projectileOwnerID then
							count = count +1 
						end
						if array[1] == projectileOwnerID then 
							soundBusy = true
							--Echo("Yoyo", soundBusy, count)
							--return
						end
					end
					--Echo(wType, soundBusy)
					if soundBusy then
						--Echo("Sound busy for:",projectileOwnerID, wType)
					else
						table.insert(pTable,{projectileOwnerID, projectileWeaponDefID, projectileID})
						--Echo("Playing beam weapon type sound")
						--Echo("Projectile added: ",#pTable, projectileOwnerID, projectileWeaponDefID, projectileID)
						--Echo(pTable[#pTable][1],pTable[#pTable][2],pTable[#pTable][3])
						Spring.PlaySoundFile("Sounds/"..sndstart[projectileWeaponDefID]..".WAV",1,'battle')					
					end
				else
					--Echo("Normal weapon sound playing")
					Spring.PlaySoundFile("Sounds/"..sndstart[projectileWeaponDefID]..".WAV",1,'battle')
				end
			end
		end
	end
	
	local function ProjectileDestroyed(projectileID, LOS)		
		--table.remove(pTable,projectileID)
		for i,array in ipairs (pTable) do
			if array[3] == projectileID then table.remove(pTable,i) end
		end
		--Echo("ProjectileDestroyed: ",projectileID, LOS, #pTable)
	end
	
	--SendToUnsynced(PROJECTILE_EXPLOSION_EVENT_ID, weaponDefID, clientLOS, posz, posy, posz,h)
	local function ProjectileExplosion(weaponDefID, LOS, x, y, z, gh)
		--Echo("ProjectileExplosion: ", weaponDefID, LOS, y,gh)
		if LOS and weaponDefID then
				if gh >= 0 then -- explosion on land
				if snddry[weaponDefID] then Spring.PlaySoundFile("Sounds/"..snddry[weaponDefID]..".WAV",1,'battle') end
				--Echo("Land")
			else -- explosion on water
				if y > 0 then -- hits something above water level, use dry sounds
					if snddry[weaponDefID] then Spring.PlaySoundFile("Sounds/"..snddry[weaponDefID]..".WAV",1,'battle') end
					--Echo("On water but above water level")
				elseif y <= 0 and gh > -50 then -- hits shallow water
					if snddry[weaponDefID] then Spring.PlaySoundFile("Sounds/"..snddry[weaponDefID]..".WAV",1,'battle') end
					if sndwet[weaponDefID] then Spring.PlaySoundFile("Sounds/"..sndwet[weaponDefID]..".WAV",1,'battle') end
					--Echo("Shallow water")
				elseif y <= 0 and gh <= -50 then -- hits deep water
					if sndwet[weaponDefID] then Spring.PlaySoundFile("Sounds/"..sndwet[weaponDefID]..".WAV",1,'battle') end
					--Echo("Deep water")
				end
			end
		end
	end
	
	function gadget:RecvFromSynced(eventID, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
		
		if eventID == PROJECTILE_GENERATED_EVENT_ID then
			ProjectileCreated(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
		elseif eventID == PROJECTILE_DESTROYED_EVENT_ID then
			ProjectileDestroyed(arg0, arg1)
		elseif eventID == PROJECTILE_EXPLOSION_EVENT_ID then
			ProjectileExplosion(arg0, arg1, arg2, arg3, arg4, arg5)
		end
	end
end
