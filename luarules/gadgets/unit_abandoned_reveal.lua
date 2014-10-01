function gadget:GetInfo()
	return {
		name = "Abandoned reveal",
		desc = "Sets abandoned commanders to visible",
		author = "Jools",
		date = "May, 2014",
		license = "Public domain",
		layer = 0,
		enabled = true
	}
end
-- SHARED
local GetUnitIsDead				= Spring.GetUnitIsDead
local GetUnitTeam				= Spring.GetUnitTeam
local GetTeamInfo				= Spring.GetTeamInfo
local GetPlayerList				= Spring.GetPlayerList
local GetPlayerInfo				= Spring.GetPlayerInfo
local GetTeamList				= Spring.GetTeamList
local gaiaTeamID				= Spring.GetGaiaTeamID()
local gaiaAllyID 				= select(6, Spring.GetTeamInfo(gaiaTeamID))
local GetUnitAllyTeam 			= Spring.GetUnitAllyTeam
local GetUnitPosition 			= Spring.GetUnitPosition
local Echo						= Spring.Echo

if (gadgetHandler:IsSyncedCode()) then
	--SYNCED
	local endmodes = {
	comcontrol=true,
	commander=true,
	comends=true,
}
	
	local commanderTable 		= {} 	-- table by commander unitdefid:s = true
	local commanderDefs			= {}	-- table of commander unitdefid:s
	local modOptions			= Spring.GetModOptions()
	local DECOYSTART			= "decoystart" -- value name in modoptions.commander
	local GetGameFrame			= Spring.GetGameFrame
	local GetTeamUnitDefCount	= Spring.GetTeamUnitDefCount
	local REVEALWAIT			= 1800 -- 60 seconds
	local visibleCommanders		= {}
	local GetTeamUnitsByDefs 	= Spring.GetTeamUnitsByDefs
	
	function gadget:Initialize()
		if not endmodes[modOptions.mode] then
			gadgetHandler:RemoveGadget(self)
			return
		end
		
		if modOptions and modOptions.commander == DECOYSTART then
			for id, unitDef in ipairs(UnitDefs) do
				if unitDef.customParams.iscommander then
					if unitDef.name then
						commanderTable[id] = true
						commanderDefs[#commanderDefs+1]=id
					end
				end
			end	
		else
			for id, unitDef in ipairs(UnitDefs) do	
				if unitDef.customParams.iscommander and (not unitDef.customParams.isdecoycommander) then
					if unitDef.name then
						commanderTable[id] = true
						commanderDefs[#commanderDefs+1]=id
					end				
				end
			end
		end
	end
	
	local function IsTeamActive(teamID)
		for _, pID in pairs (GetPlayerList(teamID, true)) do
			local _,active, spec = GetPlayerInfo(pID)
			if active and not spec then return true end
		end
		return false
	end
	
	local function IsAllyControlled(allyTeamID)
		if not allyTeamID then return end
		
		for _, tID in pairs (GetTeamList(allyTeamID)) do
			local _,_,isDead,isAI = GetTeamInfo(tID)
			if tID ~= gaiaTeamID and (not isDead) and (isAI or IsTeamActive(tID)) then
				return true
			end
		end
		return false
	end
	
	local function GetTeamCommanders(teamID)
		local teamComms = 0	
		
		for _,commDef in pairs(commanderDefs) do
			local count = GetTeamUnitDefCount(teamID,commDef)
			teamComms = teamComms+count
		end
		return teamComms
	end
	
	local function makeVisible(unitID)
		Spring.SetUnitAlwaysVisible(unitID,true)
		SendToUnsynced('AR_CommanderAbandoned', unitID)
	end
	
	local function makeHidden(unitID)
		Spring.SetUnitAlwaysVisible(unitID,false)
		SendToUnsynced('AR_CommanderBack', unitID)
	end
	
	function gadget:GameFrame(frame)
		
		if frame%90 == 0 then
			
			-- process and reveal visible commander candidates
			for commanderID, data in pairs (visibleCommanders) do
				local isUnitAlive = not GetUnitIsDead(commanderID)
				local allyID = GetUnitAllyTeam(commanderID)
				--Echo("Commanders:",commanderID,isUnitAlive,allyID,IsAllyControlled(allyID))
				if isUnitAlive and not IsAllyControlled(allyID) then
					if frame > data.revealFrame and not data.visible then
						makeVisible(commanderID)
						data.visible = true
					end
				elseif isUnitAlive then
					makeHidden(commanderID)
					visibleCommanders[commanderID] = nil
				end
			end
			
			-- check if commanders are abandoned
			for _, playerID in pairs(GetPlayerList()) do
				local _,active, spectator, teamID = GetPlayerInfo(playerID)
				
				if teamID and not spectator and not active then
					local _,_,isDead,isAI,_,allyID = GetTeamInfo(teamID)
					
					if not isDead and not isAI then
						if not IsAllyControlled(allyID) then
							for _,commDef in pairs(commanderDefs) do
								for _, commanderID in pairs( GetTeamUnitsByDefs(teamID,commDef)) do
									if not (visibleCommanders[commanderID] and visibleCommanders[commanderID].revealFrame) then
										visibleCommanders[commanderID] = {
											revealFrame						= frame + REVEALWAIT,
											visible 						= false,
										}
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	function gadget:TeamDied(teamID)
				
		
		local allyTeamID = select(6,Spring.GetTeamInfo(teamID))
		
		for _,tID in pairs(GetTeamList(allyTeamID)) do
			local teamComms = GetTeamCommanders(tID)
		
			-- check if allyteam has a commander
			if teamComms > 0 then
				
				local frame = GetGameFrame()
				
				for _,commDef in pairs(commanderDefs) do
					for _, commanderID in pairs( GetTeamUnitsByDefs(tID,commDef)) do
						visibleCommanders[commanderID] = {
							revealFrame						= frame + REVEALWAIT,
							visible 						= false,
						}
					end
				end
			end
		end
	end
	
else

	--UNSYNCED
	
	local abandonedCommanders 					= {}
	local myFont								= gl.LoadFont("FreeSansBold.otf",14, 1.9, 40)
	local teamColourO 							= {}
	local schar 								= string.char
	local max 									= math.max
	local floor 								= math.floor
	local mapX 									= Game.mapX * 512
	local mapY 									= Game.mapY * 512
	local GetGameFrame							= Spring.GetGameFrame
	local PINGFREQUENCY							= 1800 -- 60 s
	
	local lightTableMap 						= {}
	local lightTableModel 						= {}
	
	local function getLightTable(x,y,z,ltype)
		local ltable = {
			position 				= {x,max(y,0),z}, 
			ttl 					= (ltype == "model" and PINGFREQUENCY) or 180,
			ambientColor 			= {0.8, 0.6, 0.6},
			diffuseColor 			= {0.8, 0.8, 0.8},
			specularColor 			= {1, 1, 1},
			radius 					= (ltype == "model" and 10) or 150,
			ambientDecayRate 		= {0.98, 0.98, 0.98},
			diffuseDecayRate 		= {0.97, 0.97, 0.97},
			specularDecayRate 		= {0.95, 0.95, 0.95},
			DecayType 				= 0.3,
			}	

		return ltable
	end
	
	local function CommanderAbandoned(_, unitID)
		gadgetHandler:UpdateCallIn("Update")
		local x,y,z = GetUnitPosition(unitID)
		abandonedCommanders[unitID] = true
		if x and y and z then
			Spring.MarkerAddPoint (x,y,z,"Commander found!",false)
			lightTableMap[unitID] = Spring.AddMapLight(getLightTable(x,y,z,"map"))
			lightTableModel[unitID] = Spring.AddModelLight(getLightTable(x,y,z,"model"))
		end
	end
	
	local function CommanderBack(_, unitID)
		abandonedCommanders[unitID] = nil
	end
	
	local function IsTeamActive(teamID)
		for _, pID in pairs (GetPlayerList(teamID, true)) do
			local _,active, spec = GetPlayerInfo(pID)
			if active and not spec then return true end
		end
		return false
	end
	
	local function IsAllyControlled(allyTeamID)
		if not allyTeamID then return false end
		
		for _, tID in pairs (GetTeamList(allyTeamID)) do
			local _,_,isDead,isAI = GetTeamInfo(tID)
			if tID ~= gaiaTeamID and (not isDead) and (isAI or IsTeamActive(tID)) then
				return true
			end
		end
		return false
	end
		
	function gadget:Initialize()
		gadgetHandler:AddSyncAction('AR_CommanderAbandoned', CommanderAbandoned)
		gadgetHandler:AddSyncAction('AR_CommanderBack', CommanderBack)
		gadgetHandler:RemoveCallIn("Update")
	end
	
	function gadget:Update()
		local frame = GetGameFrame()
		if frame%180 == 0 then
			for unitID, _ in pairs(abandonedCommanders) do
				local allyID = GetUnitAllyTeam(unitID)
				local isUnitAlive = not GetUnitIsDead(unitID)
				
				if not isUnitAlive or IsAllyControlled(allyID) then
					abandonedCommanders[unitID] = nil
				else
					local x,y,z = GetUnitPosition(unitID)
					if x and y and z then
						if frame%PINGFREQUENCY == 0 then
							lightTableMap[unitID] = Spring.AddMapLight(getLightTable(x,y,z,"map"))
							lightTableModel[unitID] = Spring.AddModelLight(getLightTable(x,y,z,"model"))
						else
							if lightTableModel[unitID] then
								Spring.UpdateModelLight(lightTableModel[unitID],getLightTable(x,y,z,"model"))
							end
						end
					end
				end
			end
		end
	end
end
