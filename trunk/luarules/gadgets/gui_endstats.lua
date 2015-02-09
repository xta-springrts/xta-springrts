
function gadget:GetInfo()
  return {
    name      = "game_stats",
    desc      = "Game statistics and awards",
	version   = "1.0",
    author    = "Jools",
    date      = "Sep,2013",
    license   = "All rights reserved.",
    layer     = -11,
    enabled   = true,  --  loaded by default?
  }
end

-- shared synced/unsynced globals
LUAUI_DIRNAME							= 'LuaUI/'
local random  = math.random
local abs = math.abs
local Echo = Spring.Echo
local STATSFREQUENCY 		= 16 -- in seconds, frequency for calculating team statistics, keep same as engine = 16
local SAMPLEFREQUENCY 		= 60 -- in seconds, frequency for calculating influence

if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------
	do
	
		local teamData = {}
		local allyData = {}
		local gameData = {}
		local badges = {}
		badges["special"] = {}
		badges["special"]["n"] = 0
		local mapX, mapZ
		local ignoreUnits = {}
		local ignoreForAwards = {}
		local ignoreAwardsNames = include("LuaRules/Configs/gui_endstats_defs.lua")
		
		local heroUnits = {}
		local lostUnits = {}
		local MINKILLS				= 25 -- minimum kills for unit awards
		local DTAWARDLIMIT 			= 200
		local GetTeamResources 		= Spring.GetTeamResources
		local GetAllyTeamList 		= Spring.GetAllyTeamList
		local GetTeamList			= Spring.GetTeamList
		local GetTeamInfo			= Spring.GetTeamInfo
		local GetPlayerInfo  		= Spring.GetPlayerInfo
		local GetTeamUnitCount		= Spring.GetTeamUnitCount
		local GetGameFrame			= Spring.GetGameFrame
		local GetGroundHeight		= Spring.GetGroundHeight
		local IsPosInLos			= Spring.IsPosInLos
		local AreTeamsAllied		= Spring.AreTeamsAllied
		local GetUnitHealth			= Spring.GetUnitHealth
		local gaiaID				= Spring.GetGaiaTeamID()
		local _,_, CommanderTargets = include("LuaRules/Configs/unit_commander_sounds_defs.lua")
		local haveZombies 		 	= (tonumber(Spring.GetModOptions().zombies) or 0) == 1
		local holyTargets			= {}
		local impressiveTargets		= {}
		local XTA_AWARDMARKER		= '\199'
		local unitBuildpowerTable 	= {}
		local unitFirepowerTable	= {}
		local nbPlayers				= 0
						
		local commanderTable = {} -- populated in initialize, since in case of decoy start a decoy counts as commander
		local _,dgunTable, dtTable, t2Table = include("LuaRules/Configs/xta_common_defs.lua") -- arg1 is commandertable
		
		local function round(num, idp)
			return string.format("%." .. (idp or 0) .. "f", num)
		end
		
		local function getFriendlyName(tID)
			if not tID then return "N/A"
			elseif not teamData[tID] then
				return "Team " .. tID
			elseif teamData[tID]['isAI'] then
				return "Team " .. tID .. " (AI)"
			elseif teamData[tID]['leader'] then
				return teamData[tID]['leader']
			else
				return "Team " .. tID
			end
		end
		
		local function isUnitComplete(unitID)
			if unitID then
				local _,_,_,_,buildProgress = GetUnitHealth(unitID)
				if buildProgress and buildProgress>=1 then
					return true
				else
					return false
				end
			else 
				return false
			end
		end
		
		local function setTimeValues()
			for tID, data in pairs (teamData) do
				local bp = data.buildpower.current
				local fp = data.firepower.current
				data['buildpower']["values"][#data['buildpower']["values"]+1] = bp
				data['firepower']["values"][#data['firepower']["values"]+1] = fp
				
				local khp = 0
				for _, dmg in pairs (data["killedHP"]) do
					
					if type(dmg) == 'number' then
						khp = khp + dmg
					end
				end
				teamData[tID]['killedHP']['values'][#teamData[tID]['killedHP']['values']+1] = khp
								
				local lhp = teamData[tID]['lostHPmisc']['total'] or 0
				for _, dmg in pairs (data["lostHP"]) do
					
					if type(dmg) == 'number' then
						lhp = lhp + dmg
					end
				end
				teamData[tID]['lostHP']['values'][#teamData[tID]['lostHP']['values']+1] = lhp
			end		
		end
		
		local function readEngineStats()
			for teamID, data in pairs (teamData) do
				local cur_max = Spring.GetTeamStatsHistory(teamID)
				local stats = Spring.GetTeamStatsHistory(teamID, 0, cur_max)
								
				for i,stat in pairs(stats) do
					teamData[teamID]['metal']['values'][#teamData[teamID]['metal']['values']+1] = stat.metalProduced
					teamData[teamID]['energy']['values'][#teamData[teamID]['energy']['values']+1] = stat.energyProduced
				end
			end
		end
		
		local function readZoneOfControls()
			
			local zoc = {}
			local chunks = 0
			local allyList = GetAllyTeamList()
			local gaiaAllyID = select(6, GetTeamInfo(gaiaID))
			local step = 512 -- distance between map sampling points, adjust for balance in performance/data quality
			local aliveList = {}
			
			for _,aID in ipairs (allyList) do
				for i, tID in ipairs (GetTeamList(aID)) do
					if not select(3,GetTeamInfo(tID)) then 
						aliveList[aID] = true
						break
					end
				end
			end
			
			for x = 1, mapX, step do
				for z = 1, mapZ, step do
					chunks = chunks +1
					local y = GetGroundHeight(x,z)
					for i,aID in ipairs (allyList) do
						
						if aID ~= gaiaAllyID then
							if not zoc[i] then zoc[i] = 0 end
							if aliveList[aID] then
								if IsPosInLos(x,y,z,aID) then zoc[i] = zoc[i] + 1 end
							end
						end
					end
				end
			end
			
			if chunks > 0 then
				for i,aID in ipairs (allyList) do
					if allyData[i] and allyData[i]["values"] then
						allyData[i]["values"][#allyData[i]["values"]+1] = zoc[i]/chunks
					end
				end
			end
		end
		
		function gadget:Initialize()
		
			mapX = Game.mapSizeX
			mapZ = Game.mapSizeZ

			for i, aID in ipairs (GetAllyTeamList()) do	
				local gaiaAllyID = select(6, GetTeamInfo(gaiaID))
				
				if aID ~= gaiaAllyID then
					allyData[i] = {}
					allyData[i]["AID"] = aID
					allyData[i]["values"] = {}
				end
				
				for _,tID in ipairs(GetTeamList(aID)) do
					
					if haveZombies or tID ~= gaiaID then
						teamData[tID] = {}
						local _,leaderID,isDead,isAI,side 	= GetTeamInfo(tID)
						
						if leaderID then
							local leaderName,active,spectator	= GetPlayerInfo(leaderID)				
							teamData[tID]['side'] = side
							teamData[tID]['leader'] = leaderName
							
							teamData[tID]['killedHP'] = {}
							teamData[tID]['lostHP'] = {}
							teamData[tID]['killedHP']['values'] = {}
							teamData[tID]['lostHP']['values'] = {}
							teamData[tID]['killedHP']['current'] = 0
							teamData[tID]['killedHP']['current'] = 0
							
							teamData[tID]['metal'] = {}
							teamData[tID]['metal']['values'] = {}
							teamData[tID]['energy'] = {}
							teamData[tID]['energy']['values'] = {}
							
							teamData[tID]['isAI'] = isAI
							teamData[tID]['lostHPmisc'] = {} -- for losses with unreconciled attackers
							teamData[tID]['dtcount'] = 0
							teamData[tID]['isT1'] = true
							teamData[tID]['commlosses'] = 0
							teamData[tID]['commkills'] = 0
							teamData[tID]['impressivekills'] = 0
							teamData[tID]['unitcount'] = 0
							--teamData[tID]['active'] = active
							teamData[tID]['spec'] = spectator
							--teamData[tID]['killcount'] = {}
							--teamData[tID]['deathcount'] = {}
							teamData[tID]['firepower'] = {}
							teamData[tID]['buildpower'] = {}
							teamData[tID]['firepower']['values'] = {}
							teamData[tID]['buildpower']['values'] = {}
							teamData[tID]['firepower']['current'] = 0
							teamData[tID]['buildpower']['current'] = 0
						end
					end
				end
			end
			
			for id, unitDef in ipairs (UnitDefs) do
				if unitDef.customParams.dontcount then
					ignoreUnits[id] = true
				end
				if ignoreAwardsNames[unitDef.name] then
					ignoreForAwards[id] = true
				end
				
				if modOptions and modOptions.commander == DECOYSTART then
					if unitDef.customParams.iscommander then
						if unitDef.name then
							commanderTable[id] = true
						end
					end
				else
					if unitDef.customParams.iscommander and (not unitDef.customParams.isdecoycommander) then
						if unitDef.name then
							commanderTable[id] = true
						end
					end
				end
				
				local bp = unitDef.buildSpeed
				if bp and bp > 0 then
					unitBuildpowerTable[id] = bp
				end
				
				local fp = #(unitDef.weapons) > 0 and unitDef.health
				if fp and fp > 0 then
					unitFirepowerTable[id] = fp
				end
				
			end
			
			for i = 0, #CommanderTargets.ImpressiveTargetDefs do
				impressiveTargets[CommanderTargets.ImpressiveTargetDefs[i].id] = true
			end
			
			for i = 0, #CommanderTargets.HolyTargetDefs do
				holyTargets[CommanderTargets.HolyTargetDefs[i].id] = true
			end
			
		end
		
		-- Callins
		
		function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
				
			if teamID and isUnitComplete(unitID) then
				local wasMorph = (Spring.GetUnitRulesParam(unitID,'removedByMorph') or 0) == 1
				if wasMorph then return end
								
				if teamData[teamID] then
					if unitBuildpowerTable[unitDefID] then
						teamData[teamID]['buildpower']['current'] = teamData[teamID]['buildpower']['current'] - unitBuildpowerTable[unitDefID]
					end
			
					if unitFirepowerTable[unitDefID] then
						teamData[teamID]['firepower']['current'] = teamData[teamID]['firepower']['current'] - unitFirepowerTable[unitDefID]
					end
												
					if attackerTeamID then
						local _,hp = GetUnitHealth(unitID)				
						if not teamData[teamID]['lostHP'][attackerTeamID] then
							teamData[teamID]['lostHP'][attackerTeamID] = 0
						end
						teamData[teamID]['lostHP'][attackerTeamID] = teamData[teamID]['lostHP'][attackerTeamID] + hp
					elseif not ignoreUnits[unitDefID] then
						local _,hp = GetUnitHealth(unitID)
						if not teamData[teamID]['lostHPmisc']['total'] then teamData[teamID]['lostHPmisc']['total'] = 0 end
						
						teamData[teamID]['lostHPmisc']['total'] = teamData[teamID]['lostHPmisc']['total'] + hp
					end
					
					-- blue on blue counts as loss but not as kill
					
					if attackerTeamID and attackerTeamID ~=  teamID and teamData[attackerTeamID] and (not AreTeamsAllied(attackerTeamID,teamID)) then
						local _,hp = GetUnitHealth(unitID)
						
						if not teamData[attackerTeamID]['killedHP'][teamID] then
							teamData[attackerTeamID]['killedHP'][teamID] = 0
						end
						teamData[attackerTeamID]['killedHP'][teamID] = teamData[attackerTeamID]['killedHP'][teamID] + hp
						
						local kills = Spring.GetUnitRulesParam(attackerID,'kills') or 0
						if (not ignoreForAwards[attackerDefID]) and (not ignoreUnits[attackerDefID]) then
							kills = kills + 1
						end
						Spring.SetUnitRulesParam(attackerID,'kills',kills)
					end
									
					local kills = Spring.GetUnitRulesParam(unitID,'kills') or 0
					
					if kills > MINKILLS then
						local born = Spring.GetUnitRulesParam(unitID,'born')
						local frame = Spring.GetGameFrame()
						local name = UnitDefs[unitDefID].humanName
						
						if #lostUnits < 5 then
							lostUnits[#lostUnits+1] = {name,kills,round(born/1800,0),round(frame/1800,0),teamID}
							table.sort(lostUnits, function(a,b) return a[2] > b[2] end)
						else
							if kills > lostUnits[5][2] then
								lostUnits[5] = {name,kills,round(born/1800,0),round(frame/1800,0),teamID}
								table.sort(lostUnits, function(a,b) return a[2] > b[2] end)
								if #lostUnits > 5 then 
									lostUnits[6] = nil
								end
							end
						end
					end
					
					-- commloss award					
					if commanderTable[unitDefID] then
						if nbPlayers >= 4 then -- don't award unless there are at least 4 players
							if not badges["commloss"] then
								local frame = GetGameFrame()
								badges["commloss"] = {teamID,frame}
							end
						end
						
						teamData[teamID]['commlosses'] = teamData[teamID]['commlosses'] + 1
						
						if teamData[teamID]['commlosses'] >= 2 and not badges["special"]["2comms"] then
							badges["special"]["2comms"] = teamID
							badges["special"]["n"] = badges["special"]["n"] + 1
							Echo("\'Lose commander twice\'-award goes to: " .. getFriendlyName(teamID))
						end
						
						if attackerTeamID and (not AreTeamsAllied(attackerTeamID,teamID)) and teamData[attackerTeamID]then
							teamData[attackerTeamID]['commkills'] = teamData[attackerTeamID]['commkills'] + 1
							if teamData[attackerTeamID]['commkills'] >= 3 and not badges["special"]["3comms"] then
								badges["special"]["3comms"] = attackerTeamID
								badges["special"]["n"] = badges["special"]["n"] + 1
								Echo("\'Commander hitman\'-award goes to:" .. getFriendlyName(attackerTeamID))
							end
						end
					end								
				end
			end
		end
		
		function gadget:UnitDamaged(unitID, unitDefID, teamID, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
		
			if teamID and isUnitComplete(unitID) and teamData[teamID] then
				local health,hp = GetUnitHealth(unitID)
				if health < 0 then -- killed
					if weaponDefID < 0 then 				
						if weaponDefID == -1 then
							if not teamData[teamID]['lostHPmisc']['debris'] then teamData[teamID]['lostHPmisc']['debris'] = 0 end
							teamData[teamID]['lostHPmisc']['debris'] = teamData[teamID]['lostHPmisc']['debris'] + hp
						elseif weaponDefID == -2 then 
							if not teamData[teamID]['lostHPmisc']['ground'] then teamData[teamID]['lostHPmisc']['ground'] = 0 end
							teamData[teamID]['lostHPmisc']['ground'] = teamData[teamID]['lostHPmisc']['ground'] + hp
						elseif weaponDefID == -3 then
							if not teamData[teamID]['lostHPmisc']['object'] then teamData[teamID]['lostHPmisc']['object'] = 0 end
							teamData[teamID]['lostHPmisc']['object'] = teamData[teamID]['lostHPmisc']['object'] + hp
						elseif weaponDefID == -4 then 
							if not teamData[teamID]['lostHPmisc']['fire'] then teamData[teamID]['lostHPmisc']['fire'] = 0 end
							teamData[teamID]['lostHPmisc']['fire'] = teamData[teamID]['lostHPmisc']['fire'] + hp
						elseif weaponDefID == -5 then 
							if not teamData[teamID]['lostHPmisc']['water'] then teamData[teamID]['lostHPmisc']['water'] = 0 end
							teamData[teamID]['lostHPmisc']['water'] = teamData[teamID]['lostHPmisc']['water'] + hp
						elseif weaponDefID == -6 then 
							if not teamData[teamID]['lostHPmisc']['kill'] then teamData[teamID]['lostHPmisc']['kill'] = 0 end
							teamData[teamID]['lostHPmisc']['kill'] = teamData[teamID]['lostHPmisc']['kill'] + hp
						end
					else -- weapondef > 0
						if dgunTable[weaponDefID] and attackerTeam and teamData[attackerTeam] and (not AreTeamsAllied(attackerTeam,teamID)) then					
							if holyTargets[unitDefID] then
								if not badges["special"]["cygnus"] then
									badges["special"]["cygnus"] = attackerTeam
									badges["special"]["n"] = badges["special"]["n"] + 1
									Echo("\'Cygnus Nero\'-award goes to: " ..getFriendlyName(attackerTeam))
								end							
							elseif impressiveTargets[unitDefID] then
								if not badges["special"]["cygnus"] then
									if teamData[attackerTeam]['impressivekills'] >= 5 then
										badges["special"]["cygnus"] = attackerTeam
										badges["special"]["n"] = badges["special"]["n"] + 1
										Echo("\'Cygnus Nero\'-award goes to: " ..getFriendlyName(attackerTeam))
									else
										teamData[attackerTeam]['impressivekills'] = teamData[attackerTeam]['impressivekills'] + 1
									end
								end
							end
						end
					end
				end
			end
		end
				
		function gadget:UnitFinished(unitID, unitDefID, unitTeam)
			
			local frame = Spring.GetGameFrame()
			Spring.SetUnitRulesParam(unitID,'born',frame)
			
			if teamData[unitTeam] then
				if unitBuildpowerTable[unitDefID] then
					teamData[unitTeam]['buildpower']['current'] = teamData[unitTeam]['buildpower']['current'] + unitBuildpowerTable[unitDefID]
				end
				
				if unitFirepowerTable[unitDefID] then
					teamData[unitTeam]['firepower']['current'] = teamData[unitTeam]['firepower']['current'] + unitFirepowerTable[unitDefID]
				end
			
			
				if not badges["firstT2"] and t2Table[unitDefID] then
					badges["firstT2"] = {unitTeam, frame,unitDefID}
				end
				
				if not badges["special"]["dtbadge"] then
					if dtTable[unitDefID] then
						teamData[unitTeam]["dtcount"] = teamData[unitTeam]["dtcount"] + 1
						
						if teamData[unitTeam]["dtcount"] >= DTAWARDLIMIT then
							badges["special"]["dtbadge"] = unitTeam
							badges["special"]["n"] = badges["special"]["n"] + 1
							Echo("\'Fortress City\'-award goes to: " .. getFriendlyName(unitTeam))
						end
					end
				end
				
				if t2Table[unitDefID] then
					teamData[unitTeam]['isT1'] = false
				end
				
				if not dtTable[unitDefID] then
					teamData[unitTeam]['unitcount'] = teamData[unitTeam]['unitcount'] + 1
				end
			end
		end
		
		function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
			if not AreTeamsAllied (unitTeam, transportTeam) and commanderTable[unitDefID] then
				if  not badges["special"]["napaward"] then
					badges["special"]["napaward"] = transportTeam
					badges["special"]["n"] = badges["special"]["n"] + 1
					Echo("\'Napper\'-award goes to: " .. getFriendlyName(transportTeam))
				end			
			end
		end
		
		function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
						
			if teamData[oldTeam] and teamData[unitTeam] then
				if unitBuildpowerTable[unitDefID] and unitTeam then
					teamData[unitTeam]['buildpower']['current'] = teamData[unitTeam]['buildpower']['current'] + unitBuildpowerTable[unitDefID]
					if oldTeam then
						teamData[oldTeam]['buildpower']['current'] = teamData[oldTeam]['buildpower']['current'] - unitBuildpowerTable[unitDefID]
					end
				end
				
				if unitFirepowerTable[unitDefID] and unitTeam then
					teamData[unitTeam]['firepower']['current'] = teamData[unitTeam]['firepower']['current'] + unitFirepowerTable[unitDefID]
					if oldTeam then
						teamData[oldTeam]['firepower']['current'] = teamData[oldTeam]['firepower']['current'] - unitFirepowerTable[unitDefID]
					end
				end
			end
		end
				
		function gadget:GameFrame(frame)
		
			if frame%(SAMPLEFREQUENCY*30) == 0 then -- read according to sample frequency
				readZoneOfControls()
			end
			
			if frame%(STATSFREQUENCY*30) == 0 then -- read according to sample frequency
				setTimeValues()
			end			
		end

		-- this is a horribly inefficient way to send a table, but it is only sent once
		local function SendTableToUnsyncedHelper(name, el, key, ...)
			if type(el) ~= "table" then
				SendToUnsynced(name, el, key, ...)
			elseif next(el) == nil then
				SendToUnsynced(name, nil, nil, key, ...)
			else
				for k,v in pairs(el) do			
					SendTableToUnsyncedHelper(name, v, k, key, ...)
				end
			end
		end

		local function SendTableToUnsynced(name, tab)
			SendToUnsynced(name, nil, nil, nil)
			if type(tab) ~= "table" then
				SendToUnsynced(name, tab)
			elseif next(tab) == nil then
				SendToUnsynced(name, nil, nil)
			else
				for k,v in pairs(tab) do
					SendTableToUnsyncedHelper(name, v, k)
				end
			end
			SendToUnsynced(name, nil, nil, nil, nil)
		end
		
		function gadget:GameStart()		
			for _, pID in pairs(Spring.GetPlayerList()) do
				local _,active, spec = Spring.GetPlayerInfo(pID)
				if active and not spec then 
					nbPlayers = nbPlayers + 1
				end
			end
		end
		
		function gadget:GameOver()
		readZoneOfControls()
		setTimeValues()
		readEngineStats()
		local bestKills = Spring.GetGameRulesParam("BestKills") or 0
		local bestKiller = Spring.GetGameRulesParam("BestTeam")		
		
		if bestKiller then
			badges["topKiller"] = {bestKiller,bestKills}
		end
		
		for _, unitID in pairs(Spring.GetAllUnits()) do
			local kills = Spring.GetUnitRulesParam(unitID,'kills') or 0
			
			if kills > MINKILLS then
				local born = Spring.GetUnitRulesParam(unitID,'born')
				local frame = Spring.GetGameFrame()
				local unitDefID = Spring.GetUnitDefID(unitID)
				local name = UnitDefs[unitDefID].humanName
				local teamID = Spring.GetUnitTeam(unitID)
				
				if #heroUnits < 5 then
					heroUnits[#heroUnits+1] = {name,kills,round(born/1800,0),round((frame-born)/1800,0),teamID}
					table.sort(heroUnits, function(a,b) return a[2] > b[2] end)
				else
					if kills > heroUnits[5][2] then
						heroUnits[5] = {name,kills,round(born/1800,0),round((frame-born)/1800,0),teamID}
						table.sort(heroUnits, function(a,b) return a[2] > b[2] end)
						if #heroUnits > 5 then 
							heroUnits[6] = nil
						end
					end
				end
			end
		end
		
		-- only process winning team
		if GG.gamewinners then
			for _, aID in pairs (GG.gamewinners) do
				for _,tID in ipairs(GetTeamList(aID)) do
					local tdata = teamData[tID]
					
					if tID ~= gaiaID and not tdata.spec then
						if tdata.isT1 and tdata.unitcount > 100 then
							if not badges["special"]["t1badge"] then
								badges["special"]["t1badge"] = tID
								badges["special"]["n"] = badges["special"]["n"] + 1
							else
								if badges["special"]["t1badge"] >= 0 then
									badges["special"]["n"] = badges["special"]["n"] - 1
								end
								badges["special"]["t1badge"] = -1 -- contested
							end
						end
					end
				end
			end
		end
		
		SendTableToUnsynced("allyData", allyData)
		SendTableToUnsynced("teamData", teamData)
		SendTableToUnsynced("heroUnits", heroUnits)
		SendTableToUnsynced("lostUnits", lostUnits)
		SendTableToUnsynced("badges", badges)
		
		-- send luarules msg for replay site awards
		
		for i, unitData in pairs(heroUnits) do
			local name = unitData[1]
			local kills = unitData[2]
			local birth = unitData[3]
			local age = unitData[4]
			local team = unitData[5]
			local isHeroType = 1
		
			local awardsMsg = table.concat({XTA_AWARDMARKER,":",isHeroType,":",team,":",name,":",kills,":",age})
			
			Spring.SendLuaRulesMsg(awardsMsg)
		end
		
		for i, unitData in pairs(lostUnits) do
			local name = unitData[1]
			local kills = unitData[2]
			local birth = unitData[3]
			local death = unitData[4]
			local team = unitData[5]
			local isHeroType = 0
			local age = death - birth
		
			local awardsMsg = table.concat({XTA_AWARDMARKER,":",isHeroType,":",team,":",name,":",kills,":",age})
			Spring.SendLuaRulesMsg(awardsMsg)
		end
		
			-- synced part not needed anymore
			gadgetHandler:RemoveCallIn("GameFrame")
			gadgetHandler:RemoveCallIn("UnitDamaged")
			gadgetHandler:RemoveCallIn("UnitDestroyed")
			gadgetHandler:RemoveCallIn("UnitFinished")
			gadgetHandler:RemoveGadget()
			return
		end
	end
else
	-------------------
	-- UNSYNCED PART --
	-------------------
	do
		local teamList 						= Spring.GetTeamList()
		local myTeamID 						= Spring.GetMyTeamID()
		local GetTeamList 					= Spring.GetTeamList
		local GetTeamColor					= Spring.GetTeamColor
		local GetTeamInfo					= Spring.GetTeamInfo
		local GetPlayerInfo  				= Spring.GetPlayerInfo
		local glTexCoord					= gl.TexCoord
		local glVertex 						= gl.Vertex
		local glColor 						= gl.Color
		local glRect						= gl.Rect
		local glTexture 					= gl.Texture
		local glTexRect 					= gl.TexRect
		local glDepthTest 					= gl.DepthTest
		local glBeginEnd 					= gl.BeginEnd
		local glLineStipple     			= gl.LineStipple
		local GL_QUADS 						= GL.QUADS
		local glPushMatrix 					= gl.PushMatrix
		local glPopMatrix 					= gl.PopMatrix
		local glTranslate 					= gl.Translate
		local glBeginText				 	= gl.BeginText
		local glEndText 					= gl.EndText
		local glLineWidth					= gl.LineWidth
		local IsGameOver					= Spring.IsGameOver
		local PlaySoundFile 				= Spring.PlaySoundFile
		local Button 						= {}
		local Panel 						= {}
		local vsx, vsy 						= gl.GetViewSizes()
		local sizex, sizey  				= 850, 450
		local px, py 		 				= vsx/2-sizex/2, vsy/2-sizey/2
		local max, min 						= math.max, math.min
		local drawWindow					= false
		local allyData						= {}
		local nData							= {}
		local teamData						= nil
		local heroUnits						= nil
		local lostUnits						= nil
		local badges						= nil
		local bs 							= 10 	-- button space and also box size
		local bh 							= 20   -- button height
		local inited 						= false
		local maxkilled						= 0
		local maxkiller, maxloser						
		local maxlost						= 0
		local maxvalue						= 0
		local maxvalueplayer				
		local teamTotals					= {}
		local gaiaID						= Spring.GetGaiaTeamID()
		local leaderNames					= {}
		local textsize						= 12
		local myFont	 					= gl.LoadFont("FreeSansBold.otf",textsize, 1.9, 40) 
		local myFontBig	 					= gl.LoadFont("FreeSansBold.otf",16, 1.9, 40) 
		local myFontMed	 					= gl.LoadFont("FreeSansBold.otf",14, 1.9, 40) 
		local myFontHuge 					= gl.LoadFont("FreeSansBold.otf",20, 1.9, 40) 
		local button6						= "sounds/button6.wav"
		local button8						= "sounds/button8.wav"
		local beep							= "sounds/beep1.wav"
		local imgHero						= "LuaUI/Images/endstats/trophy.png"
		local imgLost						= "LuaUI/Images/endstats/rose.png"
		local imgTopKiller					= "LuaUI/Images/endstats/soldier.png"
		local imgFirstT2					= "LuaUI/Images/endstats/catpeak.png"
		local imgCommLost					= "LuaUI/Images/endstats/redfly.png"
		local imgNapper						= "LuaUI/Images/endstats/raven.png"
		local imgSize						= 24
		local areHeroes						= false
		local areLost						= false
		local areAwards						= false
		
		-- colours
		local cWhite						= {1, 1, 1, 1}
		local cBorder						= {0.2, 0.2, 0.2, 0.5}
		
		local cBack							= {0, 0, 0, 0.3}
		local cTitle						= {0.8, 0.8, 1.0, 1}
		local cPanel						= {0.5, 0.5, 0.5, 0.3}
		local cMatrix						= {0.2, 0.2, 0.3, 0.6}

		local cAxes							= {0.2, 0.2, 0.2, 0.75}
		local cAxesMinor					= {0.3, 0.3, 0.3, 0.66}
		local cAxesText						= {0.8, 0.8, 0.8, 1}
		local cChartBorder 					= {0.8, 0.8, 0.8, 1}
		
		local cLight						= {0.8, 0.8, 0.2, 0.3}
		local cSelect						= {0.8, 0.8, 0.8, 0.5}
		
		local cStatButton					= {0, 0, 0, 0.5}
		local cButton						= {0, 0, 0, 0.4}
		
		local function getTotals()

			for tID, data in pairs(teamData) do
				teamTotals[tID] = {}
				teamTotals[tID]["killed"] = 0
				teamTotals[tID]["lost"] = data["lostHPmisc"]['total'] or 0
				
				if data["lostHPmisc"]['total'] and data["lostHPmisc"]['total'] > maxvalue then
					maxvalue = data["lostHPmisc"]['total']
				end
				
				for _, dmg in pairs (data["killedHP"]) do
					if type(dmg) == 'number' then
						teamTotals[tID]["killed"] = teamTotals[tID]["killed"] + dmg
						if teamTotals[tID]["killed"] > maxkilled then
							maxkilled = teamTotals[tID]["killed"]
							maxkiller = tID
						end
						if dmg > maxvalue then
							maxvalue = dmg
							maxvalueplayer = tID
						end
					end
				end
				
				for _, dmg in pairs (data["lostHP"]) do
					if type(dmg) == 'number' then
						teamTotals[tID]["lost"] = teamTotals[tID]["lost"] + dmg 
						if teamTotals[tID]["lost"] > maxlost then
							maxlost = teamTotals[tID]["lost"]
							maxloser = tID
						end
						
						if dmg > maxvalue then
							maxvalue = dmg
							maxvalueplayer = tID
						end
					end
				end
			end
		end
		
		local function firstToUpper(str)
			return (str:sub(1,1):upper()..str:sub(2))
		end
		
		local function initButtons()
			
			areHeroes = heroUnits and heroUnits[1] and heroUnits[1][1]
			areLost = lostUnits and lostUnits[1] and lostUnits[1][1]
			
			
			
			--length of buttons
			local L1 = 120	-- proceed
			local L2 = 45	-- exit
			local L3 = 85	-- influence
			local L4 = 125	-- player matrix
			local L5 = 130	-- heroes
			local L6 = 120 	-- lost
			local L7 = 70  	-- awards
			local L8 = 120	-- team statistics
			
			--back panel for whole thing
			Panel["back"]["x0"] 	= px
			Panel["back"]["y0"] 	= py
			Panel["back"]["x1"] 	= px + sizex
			Panel["back"]["y1"] 	= py + sizey
			
			--chart area for 'influence' tab
			Panel["1"]["x0"] 		= px + 150
			Panel["1"]["y0"] 		= py + 80
			Panel["1"]["x1"] 		= px + sizex - 100
			Panel["1"]["y1"] 		= py + sizey - 100
			
			-- back panel for player matrix tab
			Panel["2"]["x0"] 		= px + 10
			Panel["2"]["y0"] 		= py + 80
			Panel["2"]["x1"] 		= px + sizex - 100
			Panel["2"]["y1"] 		= py + sizey - 60
			
			--player matrix tab, kills chart
			Panel["3"]["x0"] 		= px + 130 + 30
			Panel["3"]["y0"] 		= py + 100
			Panel["3"]["x1"] 		= px + sizex/2 - 15 + 30
			Panel["3"]["y1"] 		= py + sizey - 180
			
			--player matrix tab, losses chart
			Panel["4"]["x0"] 		= px + sizex/2 + 15 + 30
			Panel["4"]["y0"] 		= py + 100
			Panel["4"]["x1"] 		= px + sizex - 110 + 30
			Panel["4"]["y1"] 		= py + sizey - 180
			
			--lost units panel
			Panel["5"]["x0"] 		= px + 100
			Panel["5"]["y0"] 		= py + 80
			Panel["5"]["x1"] 		= px + sizex - 100
			Panel["5"]["y1"] 		= py + sizey - 100
			
			--awards panel
			Panel["awards"]["x0"] 		= px + 100
			Panel["awards"]["y0"] 		= py + 80
			Panel["awards"]["x1"] 		= px + sizex - 100
			Panel["awards"]["y1"] 		= py + sizey - 100
			
			Button["proceed"]["x0"]	= Panel["back"]["x1"] - (L1 + L2 + 2*bs)
			Button["proceed"]["y0"]	= py + 10
			Button["proceed"]["x1"]	= Button["proceed"]["x0"] + L1
			Button["proceed"]["y1"]	= py + 40
			
			Button["exit"]["x0"]	= Button["proceed"]["x1"] + bs
			Button["exit"]["y0"]	= py + 10
			Button["exit"]["x1"]	= Button["exit"]["x0"] + L2
			Button["exit"]["y1"]	= py + 40
			
			Button["awards"]["x0"]	= Panel["back"]["x0"] + bs
			Button["awards"]["y0"]	= Panel["back"]["y1"] - 40
			Button["awards"]["x1"]	= Button["awards"]["x0"] + L7
			Button["awards"]["y1"]	= Panel["back"]["y1"] - 10
			
			Button["influence"]["x0"]	= areAwards and (Button["awards"]["x1"] + bs) or Panel["back"]["x0"] + bs
			Button["influence"]["y0"]	= Panel["back"]["y1"] - 40
			Button["influence"]["x1"]	= Button["influence"]["x0"] + L3
			Button["influence"]["y1"]	= Panel["back"]["y1"] - 10
				
			Button["teamstats"]["x0"] 	= Button["influence"]["x1"] + bs
			Button["teamstats"]["y0"] 	= Panel["back"]["y1"] - 40
			Button["teamstats"]["x1"] 	= Button["teamstats"]["x0"] + L8
			Button["teamstats"]["y1"] 	= Panel["back"]["y1"] - 10			
			
			Button["teamstatsel"][1]["name"]	= "metal" -- used both as label and lookup name from synced table, keep lowercase
			Button["teamstatsel"][1]["x0"]		= px + 15
			Button["teamstatsel"][1]["y0"]		= Panel["1"]["y1"] - bh
			Button["teamstatsel"][1]["x1"]		= px + 15 + L3
			Button["teamstatsel"][1]["y1"]		= Button["teamstatsel"][1]["y0"] + bh	
									
			Button["teamstatsel"][2]["name"]	= "energy" -- used both as label and lookup name from synced table, keep lowercase
			Button["teamstatsel"][2]["x0"]		= px + 15
			Button["teamstatsel"][2]["y0"]		= Panel["1"]["y1"] - (bh+10) - bh		
			Button["teamstatsel"][2]["x1"]		= px + 15 + L3
			Button["teamstatsel"][2]["y1"]		= Button["teamstatsel"][2]["y0"] + bh
			
			Button["teamstatsel"][3]["name"]	= "buildpower" -- used both as label and lookup name from synced table, keep lowercase
			Button["teamstatsel"][3]["x0"]		= px + 15
			Button["teamstatsel"][3]["y0"]		= Panel["1"]["y1"] - 2*(bh+10) - bh		
			Button["teamstatsel"][3]["x1"]		= px + 15 + L3
			Button["teamstatsel"][3]["y1"]		= Button["teamstatsel"][3]["y0"] + bh
			
			Button["teamstatsel"][4]["name"]	= "firepower" -- used both as label and lookup name from synced table, keep lowercase
			Button["teamstatsel"][4]["x0"]		= px + 15
			Button["teamstatsel"][4]["y0"]		= Panel["1"]["y1"] - 3*(bh+10) - bh		
			Button["teamstatsel"][4]["x1"]		= px + 15 + L3
			Button["teamstatsel"][4]["y1"]		= Button["teamstatsel"][4]["y0"] + bh
			
			Button["teamstatsel"][5]["name"]	= "killedHP" -- used both as label and lookup name from synced table, keep lowercase
			Button["teamstatsel"][5]["x0"]		= px + 15
			Button["teamstatsel"][5]["y0"]		= Panel["1"]["y1"] - 4*(bh+10) - bh		
			Button["teamstatsel"][5]["x1"]		= px + 15 + L3
			Button["teamstatsel"][5]["y1"]		= Button["teamstatsel"][5]["y0"] + bh
			
			Button["teamstatsel"][6]["name"]	= "lostHP" -- used both as label and lookup name from synced table, keep lowercase
			Button["teamstatsel"][6]["x0"]		= px + 15
			Button["teamstatsel"][6]["y0"]		= Panel["1"]["y1"] - 5*(bh+10) - bh		
			Button["teamstatsel"][6]["x1"]		= px + 15 + L3
			Button["teamstatsel"][6]["y1"]		= Button["teamstatsel"][6]["y0"] + bh
			
			
			
			Button["matrix"]["x0"] 		= Button["teamstats"]["x1"] + bs
			Button["matrix"]["y0"] 		= Panel["back"]["y1"] - 40
			Button["matrix"]["x1"] 		= Button["matrix"]["x0"] + L4
			Button["matrix"]["y1"] 		= Panel["back"]["y1"] - 10
			
			Button["heroes"]["x0"]	= Button["matrix"]["x1"] + bs
			Button["heroes"]["y0"]	= Panel["back"]["y1"] - 40
			Button["heroes"]["x1"]	= Button["heroes"]["x0"] + L5
			Button["heroes"]["y1"]	= Panel["back"]["y1"] - 10
			
			Button["lost"]["x0"]	= areHeroes and (Button["heroes"]["x1"] + bs) or (Button["matrix"]["x1"] + bs)
			Button["lost"]["y0"]	= Panel["back"]["y1"] - 40
			Button["lost"]["x1"]	= Button["lost"]["x0"] + L6
			Button["lost"]["y1"]	= Panel["back"]["y1"] - 10
			
			if teamData then
				local statName = Button["teamstats"]["sel"]
				local maxval = 0
				local minval = math.huge
				
				for tID, data in pairs (teamData) do
					if tID ~= gaiaID then
						if not Button["legend"][tID] then Button["legend"][tID] = {} end
						
						local x0 = Panel["2"]["x0"]
						local y0 = Panel["2"]["y1"] - tID*(bs+5) - bs			
						
						Button["legend"][tID]["x0"] = x0 
						Button["legend"][tID]["y0"] = y0
						Button["legend"][tID]["x1"] = x0 + bs
						Button["legend"][tID]["y1"] = y0 + bs
					end
					
					local array = data[statName]["values"]
											
					for k,v in pairs( array ) do
						if type(v) == 'number' then
							maxval = max( maxval, v )
							minval = min( minval, v )
						end
					end
				end
				Button["teamstats"]["maxvalue"] = maxval
				Button["teamstats"]["minvalue"] = minval
								
				if not inited then
					Button["legend"][myTeamID]["On"] = true
					getTotals()
					inited = true
				end
			end
			
		end

		local function round(num, idp)
			return string.format("%." .. (idp or 0) .. "f", num or -1)
		end

		local function formatRes(number)
			if number == 'nil' then return nil end
			
			local label
			local number = tonumber(number)
			if number > 10000 then
				label = table.concat({math.floor(round(number/1000)),"k"})
			elseif number > 1000 then
				label = table.concat({string.sub(round(number/1000,1),1,2+string.find(round(number/1000,1),".")),"k"})
			elseif number > 10 then
				label = string.sub(round(number,0),1,3+string.find(round(number,0),"."))
			elseif number == 0 then
				label = 0
			else
				label = string.sub(round(number,1),1,2+string.find(round(number,1),"."))
			end
			return tostring(label)
		end

		local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
			if BLcornerX == nil then return false end
			-- check if the mouse is in a rectangle

			return x >= BLcornerX and x <= TRcornerX
								  and y >= BLcornerY
								  and y <= TRcornerY
		end

		local function sortBySmallest(v1,v2)
			return v2[1] > v1[1]
		end

		local function ReceiveTableFromSyncedHelper(n, tab, ...)
			local args = {...}
			if n == 1 then
				tab = args[1]
			elseif n > 1 and args[n] == nil then
				tab = {}
			else
				local idx = args[n]
				local cur = tab[idx]
				if cur == nil then
					cur = {}
					tab[idx] = cur
				end
				tab[idx] = ReceiveTableFromSyncedHelper(n - 1, cur, ...)
			end
			return tab
		end

		local function ReceiveTableFromSynced(reset, n, tab, ...)
			local args = {...}
			if n == 3 and args[3] == nil then
				if reset then
					tab = {}
				end
				return tab, true -- start of transfer
			elseif n == 4 and args[4] == nil then
				return tab, false -- end of transfer
			else
				if tab == nil then
					tab = {}
				end
				return ReceiveTableFromSyncedHelper(n, tab, ...), nil -- in progress
			end
		end

		function onTeamData(_, ...)
			teamData, _ = ReceiveTableFromSynced(true, select('#', ...), teamData, ...)
		end

		function onAllyData(_, ...)
			allyData, _ = ReceiveTableFromSynced(true, select('#', ...), allyData, ...)
			initButtons()
		end

		function onHeroUnits(_, ...)
			heroUnits, _ = ReceiveTableFromSynced(true, select('#', ...), heroUnits, ...)
			initButtons()
		end

		function onLostUnits(_, ...)
			lostUnits, _ = ReceiveTableFromSynced(true, select('#', ...), lostUnits, ...)
			initButtons()
		end

		function onBadges(_, ...)
			badges, _ = ReceiveTableFromSynced(true, select('#', ...), badges, ...)
			initButtons()
		end

		local function drawBorder(x0, y0, x1, y1, width)
			glRect(x0, y0, x1, y0 + width)
			glRect(x0, y1, x1, y1 - width)
			glRect(x0, y0, x0 + width, y1)
			glRect(x1, y0, x1 - width, y1)
		end

		local function drawAwards()
			-----------------
			-- AWARDS TAB  --
			-----------------
			local imgposx = (Panel["5"]["x0"]+Panel["5"]["x1"])/2 - 100 - imgSize
			local imgposx2 = (Panel["5"]["x0"]+Panel["5"]["x1"])/2 + 100
			local imgposy = Panel["5"]["y1"]-30
			
			
			--panel
			glColor(cPanel)
			glRect(Panel["5"]["x0"],Panel["5"]["y0"],Panel["5"]["x1"], Panel["5"]["y1"])
			
			--title
			myFontBig:Begin()
			myFontBig:SetTextColor(cTitle)
			myFontBig:Print("Awards", (Panel["5"]["x0"]+Panel["5"]["x1"])/2,Panel["5"]["y1"] - 20, 16, 'vcs')
			myFontBig:End()
			
			-- pictures
			glColor(cWhite)
			glTexture(imgHero)
			glTexRect(imgposx,imgposy,imgposx + imgSize,imgposy + imgSize)
			glTexRect(imgposx2,imgposy,imgposx2 + imgSize,imgposy + imgSize)
			glTexture(false)
			
			glColor(cTitle)
			
			-- badges
			local badgeSize = 50
			local textsize = 12
			local x0 = Panel["awards"]["x0"] + 40
			local y0 = Panel["awards"]["y1"] - 50
			local y1 = y0 - 10
			local y2 = y0 - 80
			local y3 = y2 - 80
			local x1 = (Panel["awards"]["x0"] + Panel["awards"]["x1"])/2 - 180
			local x2 = (Panel["awards"]["x0"] + Panel["awards"]["x1"])/2 + 100
			local row2 = 32
			local row3 = row2 + 14
							
			-- top killer
			if badges and badges["topKiller"] then
				local teamID = badges["topKiller"][1]
				local kills = badges["topKiller"][2]				
									
				local r,g,b = GetTeamColor(teamID)
				local _,leaderID,_,isAI = GetTeamInfo(teamID)
				local leaderName = leaderID and (GetPlayerInfo(leaderID) or (leaderNames[teamID]) or "N/A") or "N/A"
							
				if isAI then leaderName = "AI" end	
				if teamID == gaiaID then leaderName = "Gaia" end
				
				glTexture(imgTopKiller)
				glTexRect(x0,y0-badgeSize,x0+badgeSize,y0)
				glTexture(false)
				
				myFontBig:Begin()
				myFont:SetTextColor(cTitle)
				myFontBig:Print("\'Omnivore\'",x1, y0, 16, 'ts')
				myFontBig:End()
				
				myFont:Begin()
				myFont:SetTextColor({r, g, b, 1})
				myFont:Print(leaderName,x1, y0-row2, textsize, 'ds')
				myFont:SetTextColor(cTitle)
				myFont:Print(table.concat({" , ",kills," kills"}),x1+textsize*gl.GetTextWidth(leaderName), y0-row2, textsize, 'ds')
				myFont:Print("Most confirmed individual kills",x1, y0-row3, textsize, 'd')
				myFont:End()
			end
			-- first to make t2
			if badges and badges["firstT2"] then
				local teamID = badges["firstT2"][1]
				local frame = tonumber(badges["firstT2"][2])
				local unitDefID = badges["firstT2"][3]
				
				local minutes = round(frame/30/60,0)
				local name = (UnitDefs[unitDefID] or {}).humanName
				
				local r,g,b = GetTeamColor(teamID)
				local _,leaderID,_,isAI = GetTeamInfo(teamID)
				local leaderName = leaderID and (GetPlayerInfo(leaderID) or (leaderNames[teamID]) or "N/A") or "N/A"
							
				if isAI then leaderName = "AI" end	
				if teamID == gaiaID then leaderName = "Gaia" end
				
				glTexture(imgFirstT2)
				glTexRect(x0,y2-badgeSize,x0+badgeSize,y2)
				glTexture(false)
				
				myFontBig:Begin()
				myFont:SetTextColor(cTitle)
				myFontBig:Print("\'Metamorphosis\'",x1, y2, 16, 'ts')
				myFontBig:End()
				
				myFont:Begin()
				myFont:SetTextColor({r, g, b, 1})
				myFont:Print(leaderName,x1, y2-row2, textsize, 'ds')
				myFont:SetTextColor(cTitle)
				myFont:Print(table.concat({"  @ ",minutes," min, ",name}),x1+textsize*gl.GetTextWidth(leaderName), y2-row2, textsize, 'ds')
				myFont:Print("First to build an advanced building or unit",x1, y2-row3, textsize, 'd')
				myFont:End()
			end
			-- first to lose commander
			if badges and badges["commloss"] then
				local teamID = badges["commloss"][1]
				local frame = badges["commloss"][2]				
				local minutes = round(frame/30/60,0)
				
				local r,g,b = GetTeamColor(teamID)
				local _,leaderID,_,isAI = GetTeamInfo(teamID)
				local leaderName = leaderID and (GetPlayerInfo(leaderID) or (leaderNames[teamID]) or "N/A") or "N/A"
							
				if isAI then leaderName = "AI" end	
				if teamID == gaiaID then leaderName = "Gaia" end
				
				glTexture(imgCommLost)
				glTexRect(x0,y3-badgeSize,x0+badgeSize,y3)
				glTexture(false)
				
				myFontBig:Begin()
				myFont:SetTextColor(cTitle)
				myFontBig:Print("\'Ephemeron\'",x1, y3, 16, 'ts')
				myFontBig:End()
				
				myFont:Begin()
				myFont:SetTextColor({r, g, b, 1})
				myFont:Print(leaderName,x1, y3-row2, textsize, 'ds')
				myFont:SetTextColor(cTitle)
				myFont:Print(table.concat({"  @ ",minutes," min"}),x1+textsize*gl.GetTextWidth(leaderName), y3-row2, textsize, 'ds')
				myFont:Print("First to get his commander killed",x1, y3-row3, textsize, 'd')
				myFont:End()
			end
			
			-- specials
			local bsize = 24
			local bmargin = 10
			local rheight = 26
			local imgFortress = "LuaUI/Images/endstats/bologna.png"
			local imgSwarm = "LuaUI/Images/endstats/swarm.png"
			local img2comms = "LuaUI/Images/endstats/twicecomm.png"
			local img3comms = "LuaUI/Images/endstats/hitman.png"
			local imgCygnus = "LuaUI/Images/endstats/swan.png"
			local x3 = x2-bsize-bmargin
			
			if badges and badges["special"] and badges["special"]["n"] and badges["special"]["n"] > 0 then
			local rows = 0
				myFont:Begin()
				myFont:Print("Special awards",x2, y0, textsize, 'ts')
				myFont:Print("(Help us by suggesting awards)",x2, y3, textsize, 'to')
				myFont:End()
				-- dt-award
				if badges["special"]["dtbadge"] then
					rows = rows + 1
					
					local teamID = badges["special"]["dtbadge"]
					local r,g,b = GetTeamColor(teamID)
					local _,leaderID,_,isAI = GetTeamInfo(teamID)
					local leaderName = leaderID and (GetPlayerInfo(leaderID) or (leaderNames[teamID]) or "N/A") or "N/A"	
					if isAI then leaderName = "AI" end	
					if teamID == gaiaID then leaderName = "Gaia" end
					local label = "\'Fortress City\' "
					
					glTexture(imgFortress)
					glTexRect(x3,y1-rows*rheight-bsize/2,x3+bsize,y1-rows*rheight+bsize/2)
					glTexture(false)
					
					myFont:Begin()
					myFont:SetTextColor(cTitle)
					myFont:Print(label,x2, y1-rows*rheight, textsize, 'vs')
					myFont:SetTextColor({r, g, b, 1})
					myFont:Print(leaderName,x2+textsize*gl.GetTextWidth(label), y1-rows*rheight+2, textsize, 'vs')
					myFont:End()
				end 
				--t1 award
				if badges["special"]["t1badge"] and badges["special"]["t1badge"] >= 0 then
					rows = rows + 1
					
					local teamID = badges["special"]["t1badge"]
					local r,g,b = GetTeamColor(teamID)
					local _,leaderID,_,isAI = GetTeamInfo(teamID)
					local leaderName = leaderID and (GetPlayerInfo(leaderID) or (leaderNames[teamID]) or "N/A") or "N/A"	
					if isAI then leaderName = "AI" end	
					if teamID == gaiaID then leaderName = "Zombies" end
					local label = "\'T1-swarm\' "
					
					glTexture(imgSwarm)
					glTexRect(x3,y1-rows*rheight-bsize/2,x3+bsize,y1-rows*rheight+bsize/2)
					glTexture(false)
					
					myFont:Begin()
					myFont:SetTextColor(cTitle)
					myFont:Print(label,x2, y1-rows*rheight, textsize, 'vs')
					myFont:SetTextColor({r, g, b, 1})
					myFont:Print(leaderName,x2+textsize*gl.GetTextWidth(label), y1-rows*rheight, textsize, 'vs')
					myFont:End()
				end
				-- two-time commloss
				if badges["special"]["2comms"] then
					rows = rows + 1
					
					local teamID = badges["special"]["2comms"]
					local r,g,b = GetTeamColor(teamID)
					local _,leaderID,_,isAI = GetTeamInfo(teamID)
					local leaderName = leaderID and (GetPlayerInfo(leaderID) or (leaderNames[teamID]) or "N/A") or "N/A"	
					if isAI then leaderName = "AI" end	
					if teamID == gaiaID then leaderName = "Zombies" end
					local label = "\'Lost commander twice\' "
					
					glTexture(img2comms)
					glTexRect(x3,y1-rows*rheight-bsize/2,x3+bsize,y1-rows*rheight+bsize/2)
					glTexture(false)
					
					myFont:Begin()
					myFont:SetTextColor(cTitle)
					myFont:Print(label,x2, y1-rows*rheight, textsize, 'vs')
					myFont:SetTextColor({r, g, b, 1})
					myFont:Print(leaderName,x2+textsize*gl.GetTextWidth(label), y1-rows*rheight, textsize, 'vs')
					myFont:End()	
				end
				-- three commkills
				if badges["special"]["3comms"] then
					rows = rows + 1
					
					local teamID = badges["special"]["3comms"]
					local r,g,b = GetTeamColor(teamID)
					local _,leaderID,_,isAI = GetTeamInfo(teamID)
					local leaderName = leaderID and (GetPlayerInfo(leaderID) or (leaderNames[teamID]) or "N/A") or "N/A"	
					if isAI then leaderName = "AI" end	
					if teamID == gaiaID then leaderName = "Zombies" end
					local label = "\'Hitman\' "
					
					glTexture(img3comms)
					glTexRect(x3,y1-rows*rheight-bsize/2,x3+bsize,y1-rows*rheight+bsize/2)
					glTexture(false)
					
					myFont:Begin()
					myFont:SetTextColor(cTitle)
					myFont:Print(label,x2, y1-rows*rheight, textsize, 'vs')
					myFont:SetTextColor({r, g, b, 1})
					myFont:Print(leaderName,x2+textsize*gl.GetTextWidth(label), y1-rows*rheight, textsize, 'vs')
					myFont:End()	
				end
				
				-- 5 Impressive or 1 holy dgun-targets killed
				if badges["special"]["cygnus"] then
					rows = rows + 1
					
					local teamID = badges["special"]["cygnus"]
					local r,g,b = GetTeamColor(teamID)
					local _,leaderID,_,isAI = GetTeamInfo(teamID)
					local leaderName = leaderID and (GetPlayerInfo(leaderID) or (leaderNames[teamID]) or "N/A") or "N/A"	
					if isAI then leaderName = "AI" end	
					if teamID == gaiaID then leaderName = "Zombies" end
					local label = "\'Cygnus Nero\' "
					
					glTexture(imgCygnus)
					glTexRect(x3,y1-rows*rheight-bsize/2,x3+bsize,y1-rows*rheight+bsize/2)
					glTexture(false)
					
					myFont:Begin()
					myFont:SetTextColor(cTitle)
					myFont:Print(label,x2, y1-rows*rheight, textsize, 'vs')
					myFont:SetTextColor({r, g, b, 1})
					myFont:Print(leaderName,x2+textsize*gl.GetTextWidth(label), y1-rows*rheight, textsize, 'vs')
					myFont:End()	
				end
				
				-- three commkills
				if badges["special"]["napaward"] then
					rows = rows + 1
					
					local teamID = badges["special"]["napaward"]
					local r,g,b = GetTeamColor(teamID)
					local _,leaderID,_,isAI = GetTeamInfo(teamID)
					local leaderName = leaderID and (GetPlayerInfo(leaderID) or (leaderNames[teamID]) or "N/A") or "N/A"	
					if isAI then leaderName = "AI" end	
					if teamID == gaiaID then leaderName = "Zombies" end
					local label = "\'Napper\' "
					
					glTexture(imgNapper)
					glTexRect(x3,y1-rows*rheight-bsize/2,x3+bsize,y1-rows*rheight+bsize/2)
					glTexture(false)
					
					myFont:Begin()
					myFont:SetTextColor(cTitle)
					myFont:Print(label,x2, y1-rows*rheight, textsize, 'vs')
					myFont:SetTextColor({r, g, b, 1})
					myFont:Print(leaderName,x2+textsize*gl.GetTextWidth(label), y1-rows*rheight, textsize, 'vs')
					myFont:End()	
				end

			elseif not badges or (not badges["commloss"] and not badges["firstT2"] and not badges["topKiller"]) then
				myFont:Begin()
				myFont:Print("(No awards)",(Panel["5"]["x0"]+Panel["5"]["x1"])/2, y2, textsize, 'dcs')
				myFont:End()
			end
		end

		local function drawInfluence()
			--------------------
			-- INFLUENCE TAB  --
			--------------------		
			-- title
			
			myFontBig:Begin()
			myFontBig:SetTextColor(cTitle)
			myFontBig:Print("Territorial influence", (Panel["1"]["x0"]+Panel["1"]["x1"])/2,Panel["1"]["y1"] + 30, 16, 'vcs')
			myFontBig:End()
			
			--panel
			glColor(cPanel)
			glRect(Panel["1"]["x0"],Panel["1"]["y0"],Panel["1"]["x1"], Panel["1"]["y1"])
			
			-- legend
			for i, aData in ipairs (allyData) do
				local y00 = Panel["1"]["y1"] - i*(bs+5)
				local x00 = px + 15
				local aID = aData["AID"]
				
				local teamList = GetTeamList(aID)
				if #teamList > 0 then
					local teamID1 = teamList[1]
					local r,g,b = GetTeamColor(teamID1)
					glColor(r, g, b, 1)
					glRect(x00,y00,x00+bs,y00+bs)
					myFont:Begin()
					myFont:SetTextColor({r,g,b,1})
					myFont:Print("Team " .. tostring(aID),x00+20,y00, 12,'bo')
					myFont:End()
				else
					myFont:Begin()
					myFont:SetTextColor({0.8, 0.8, 0.8, 0.7})
					myFont:Print("(Empty)",x00+20,y00-2, 12,'bo')
					myFont:End()
				end
			end
			
			-- axes
			local n = #allyData[1]["values"]
			local y0 = Panel["1"]["y0"]
			local y100 = Panel["1"]["y1"]
			local y50 = Panel["1"]["y0"] + 0.50 * (Panel["1"]["y1"]-Panel["1"]["y0"])
			local y25 = Panel["1"]["y0"] + 0.25 * (Panel["1"]["y1"]-Panel["1"]["y0"])
			local y75 = Panel["1"]["y0"] + 0.75 * (Panel["1"]["y1"]-Panel["1"]["y0"])
			glColor(cAxes)
			glRect(Panel["1"]["x0"]-1,Panel["1"]["y0"],Panel["1"]["x0"], Panel["1"]["y1"]+10)
			glRect(Panel["1"]["x0"]-5,y0,Panel["1"]["x1"],y0+1)
			glRect(Panel["1"]["x0"]-5,y100,Panel["1"]["x1"],y100+1)
			glRect(Panel["1"]["x0"]-5,y50,Panel["1"]["x1"],y50+1)
			
			local imin = Button.influence.minvalue*100
			local imax = Button.influence.maxvalue*100
			imin = imin >= 10 and round(imin,0) or (round(imin,1))
			imax = imax >= 10 and round(imax,0) or (round(imax,1))
			local i50 = ((imax - imin)/2 >= 10) and round((imax-imin)/2,0) or (round((imax-imin)/2,1))
						
			myFont:Begin()
			myFont:SetTextColor(cAxesText)
			--myFont:Print("Influence", Panel["1"]["x0"]-30,Panel["1"]["y1"] + 20, 10, 'xs')
			myFont:Print(tostring(imin) .. " %", Panel["1"]["x0"]-10, y0, 12, 'vrs')
			myFont:Print(tostring(i50) .. " %", Panel["1"]["x0"]-10, y50, 10, 'vro')
			myFont:Print(tostring(imax) .. " %", Panel["1"]["x0"]-10, y100, 12, 'vrs')
			myFont:Print("Time: " .. round( (60/SAMPLEFREQUENCY)*(n-1),0) .. " min", Panel["1"]["x1"]+25,Panel["1"]["y0"]-2, 12, 'xs')
			myFont:End()
			
			glColor(cAxesMinor)
			glRect(Panel["1"]["x0"]-5,y25,Panel["1"]["x1"],y25+1)
			glRect(Panel["1"]["x0"]-5,y75,Panel["1"]["x1"],y75+1)
			
			-- values
			local r,g,b
			
			local x0 		= Panel["1"]["x0"]
			local xspace 	= Panel["1"]["x1"]-Panel["1"]["x0"]
			local yspace	= y100-y0
			
			local function DrawLine(array,i)
				local xscale = n <= 1 and 1 or 1/(n-1)
				local yscale = (imax - imin) > 1 and 100/(imax - imin) or 1
				
				for x, y in ipairs (array) do
					glVertex(x0+(x-1)*xspace*xscale, y0+y*yspace*yscale - (i-1))
				end
			end
			
			local function DrawLineShadow(array,i)
				local xscale = n <= 1 and 1 or 1/(n-1)
				local yscale = (imax - imin) > 1 and 100/(imax - imin) or 1
				
				for x, y in ipairs (array) do
					glVertex(x0+(x-1)*xspace*xscale, y0+y*yspace*yscale -1-(i-1))
				end
			end
			glLineStipple(false)
			for i, aData in ipairs (allyData) do
				local aID = aData["AID"]
				local teamList = GetTeamList(aID)
				if #teamList > 0 then
					local teamID1 = teamList[1]
					
					r,g,b = GetTeamColor(teamID1)
					glColor(r, g, b, 0.85) -- set a bit transparency to allow overlapping values
					glLineWidth (2.5)
					gl.BeginEnd(GL.LINE_STRIP, DrawLine,aData["values"],i)
					glColor(r*0.75, g*0.75, b*0.75,0.85) -- set a bit transparency to allow overlapping values
					glLineWidth (1.5)
					gl.BeginEnd(GL.LINE_STRIP, DrawLineShadow,aData["values"],i)
				end
			end
			glColor(cWhite)
		end

		local function drawMatrix()
			-----------------------
			-- PLAYER KILLS TAB  --
			-----------------------	
			-- charts
			glColor(cMatrix) 
			glRect(Panel["3"]["x0"],Panel["3"]["y0"],Panel["3"]["x1"], Panel["3"]["y1"])
			glRect(Panel["4"]["x0"],Panel["4"]["y0"],Panel["4"]["x1"], Panel["4"]["y1"])
			
			-- title
			myFontBig:Begin()
			myFontBig:SetTextColor(cTitle)
			myFontBig:Print("Player-to-player kills (in hp)", Panel["2"]["x0"]+200,Panel["1"]["y1"]+30, 16, 'vs')
			myFontBig:End()
			
			--subtitle
			myFont:Begin()
			myFont:SetTextColor(cTitle)
			myFont:Print("Most damage dealt:", Panel["2"]["x0"]+450,Panel["2"]["y1"], textsize, 'vs')
			myFont:Print("Most damage received:", Panel["2"]["x0"]+450,Panel["2"]["y1"]-20, textsize, 'vs')
			myFont:End()
			
			-- chart titles
			myFontBig:Begin()
			myFontBig:SetTextColor(cTitle)
			myFontBig:Print("Kills:", (Panel["3"]["x0"]+Panel["3"]["x1"])/2,Panel["3"]["y0"]-20, 16, 'vrs')
			myFontBig:Print("losses:", (Panel["4"]["x0"]+Panel["4"]["x1"])/2,Panel["4"]["y0"]-20, 16, 'vrs')
			myFontBig:End()
			
			--footnote
			myFont:Begin()
			myFont:SetTextColor({0.9, 0.9, 1.0, 1.0})
			myFont:Print("Other: where there is no attacker (directly) involved (grey). Gaia team damage (if any) is shown as white.", Panel["2"]["x0"]+10,Panel["2"]["y0"]-60, 10, 'v')
			
			
			--max values
			myFont:Print(tostring(round(maxkilled/1000,1)).. " k", Panel["2"]["x0"]+600,Panel["2"]["y1"], textsize, 'vs')
			myFont:Print(tostring(round(maxlost/1000,1)).. " k", Panel["2"]["x0"]+600,Panel["2"]["y1"]-20, textsize, 'vs')
			myFont:End()
			
			glColor(cWhite)
			
			if maxkiller then
				local r1,g1,b1 = GetTeamColor(maxkiller)
				local maxkillername = teamData[maxkiller].leader or (leaderNames[maxkiller] or "N/A")
				if teamData[maxkiller].isAI then maxkillername = "AI" end
				if maxkiller == gaiaID then maxkillername = "Team gaia" end
				
				myFont:Begin()
				myFont:SetTextColor({r1,g1,b1, 1})
				myFont:Print("(" .. maxkillername .. ")", Panel["2"]["x0"]+660,Panel["2"]["y1"]+2, 12, 'vs')
				myFont:End()
				
			end
			
			if maxloser then
				local r2,g2,b2 = GetTeamColor(maxloser)
				local maxlosername = teamData[maxloser].leader or (leaderNames[maxloser] or "N/A")
				if teamData[maxloser].isAI then maxlosername = "AI" end
				if maxloser == gaiaID then maxlosername = "Team gaia" end
				
				myFont:Begin()
				myFont:SetTextColor({r2,g2,b2, 1})
				myFont:Print("(" ..maxlosername .. ")", Panel["2"]["x0"]+660,Panel["2"]["y1"]-18, 12, 'vs')
				myFont:End()
			end
			
			-- axes
			local y00 = Panel["3"]["y0"]
			local y100 = Panel["3"]["y1"]
			
			glColor(cChartBorder)
			glRect(Panel["3"]["x0"]-1,Panel["3"]["y0"],Panel["3"]["x0"], Panel["3"]["y1"]+10)
			glRect(Panel["3"]["x0"]-5,y00,Panel["3"]["x1"],y00+1)
			glRect(Panel["3"]["x0"]-5,y100,Panel["3"]["x1"],y100+1)
			glRect(Panel["4"]["x0"]-1,Panel["4"]["y0"],Panel["4"]["x0"], Panel["4"]["y1"]+10)
			glRect(Panel["4"]["x0"]-5,y00,Panel["4"]["x1"],y00+1)
			glRect(Panel["4"]["x0"]-5,y100,Panel["4"]["x1"],y100+1)
			
			myFont:Begin()
			myFont:SetTextColor(cChartBorder)
			myFont:Print("0", Panel["3"]["x0"]-10, y00, 10, 'vrs')
			myFont:Print("max = " .. tostring(round(maxvalue/1000,1)) .. " k", Panel["3"]["x0"]-10, y100, 10, 'vrs')
			myFont:Print("0", Panel["4"]["x1"]+10, y00, 10, 'vs')
			myFont:Print("max = " .. tostring(round(maxvalue/1000,1)) .. " k", Panel["4"]["x1"]+10, y100, 10, 'vs')
			--myFont:Print("max = " .. tostring(round(maxvalue/1000,1)) .. " k", Panel["4"]["x0"]-10, y100, 10, 'vr')
			myFont:End()
			
			glColor(cWhite)
			-- players legend
			if teamData then
				for tID, data in pairs (teamData) do
					if tID ~= gaiaID then
						local r,g,b = GetTeamColor(tID)
						
						if not Button["legend"][tID] then
							initButtons()
						end
						
						local x0 = Button["legend"][tID]["x0"]
						local y0 = Button["legend"][tID]["y0"]			
						
						local leaderName = data.leader or (leaderNames[tID] or "N/A")
						if data.isAI then leaderName = "AI" end 
						if tID == gaiaID then leaderName = "Gaia" end
						
						glColor(r, g, b, 1)
						glRect(x0, y0, x0 + bs, y0 + bs)
						myFont:Begin()
						myFont:SetTextColor({r, g, b, 1})
						myFont:Print(leaderName, x0 + bs + 10, y0, textsize, 'bs')
						myFont:End()
				
						--highlight
						if Button["legend"][tID]["mouse"] and not Button["legend"][tID]["On"] then
							glColor(cLight)
							glRect(x0-1,y0,x0,y0+bs)
							glRect(x0+bs,y0,x0+bs+1,y0+bs)
							glRect(x0,y0-1,x0+bs,y0)
							glRect(x0,y0+bs,x0+bs,y0+bs+1)
						end
						
						--selected
						if Button["legend"][tID]["On"] then
							glColor(cWhite)
							glRect(x0-1,y0,x0,y0+bs)
							glRect(x0+bs,y0,x0+bs+1,y0+bs)
							glRect(x0,y0-1,x0+bs,y0)
							glRect(x0,y0+bs,x0+bs,y0+bs+1)
						end
											
						--values
						if Button["legend"][tID]["On"] then
							-- player name big label
							myFontHuge:Begin()
							myFontHuge:SetTextColor(r, g, b, 1)
							myFontHuge:Print(tID .. " - " .. leaderName, Panel["2"]["x0"]+280, Panel["2"]["y1"] - 79, 20, 'vs')
							myFontHuge:Print("Player:", Panel["2"]["x0"]+200, Panel["2"]["y1"] - 80, 20, 'vs')
							myFontHuge:End()
							
							-- killed/lost values
							myFontMed:Begin()
							myFontMed:SetTextColor(cWhite)
							myFontMed:Print(tostring(round(teamTotals[tID]["killed"]/1000,1)) .. " k", (Panel["3"]["x0"]+Panel["3"]["x1"])/2+10,Panel["3"]["y0"]-21, 14, 'vs')
							myFontMed:Print(tostring(round(teamTotals[tID]["lost"]/1000,1)) .. " k", (Panel["4"]["x0"]+Panel["4"]["x1"])/2+10,Panel["4"]["y0"]-21, 14, 'vs')
							myFontMed:End()
							
							-- player matrix
							local killedcount = 0
							local lostcount = 0
							
							local killsTable = {}
							local lossesTable = {}
							
							for eID, dmg in pairs(data.killedHP) do
								if type(dmg) == 'number' and dmg > 0 then
									killedcount = killedcount + 1
									killsTable[#killsTable+1] = {eID,dmg}
								end
							end
							
							for eID, dmg in pairs(data.lostHP) do
								if type(dmg) == 'number' and dmg > 0 then
									lostcount = lostcount + 1
									lossesTable[#lossesTable+1] = {eID,dmg}
								end
							end
							table.sort(killsTable, function(a,b) return a[2] > b[2] end)
							table.sort(lossesTable, function(a,b) return a[2] > b[2] end)
							
							local w1 = 9 -- bar width
							local w2 = 9 -- bar width
							local gap  = 6
							if killedcount >= 12 then
								w1 = 6
								gap = 4
							end
							
							if lostcount >= 12 then
								w2 = 6
								gap = 4
							end
							
							local x01 = Panel["3"]["x0"] + (Panel["3"]["x1"] - Panel["3"]["x0"])/2 - ((killedcount+2)*(w1+2))/2 - 10
							local x02 = Panel["4"]["x0"] + (Panel["4"]["x1"] - Panel["4"]["x0"])/2 - ((lostcount+2)*(w2+2))/2 - 10
							
							
							--kills
							for x, killsData in ipairs(killsTable) do
								local eID = killsData[1]
								local dmg = killsData[2]
								local value = dmg/maxvalue
								local r3,g3,b3 = GetTeamColor(eID)
								glColor(r3,g3,b3,1)
								glRect(x01+(w1+gap)*x,y00,x01+(w1+gap)*x+w1,y00+value*(y100-y00))
								glColor(0,0,0,1)
								glRect(x01+(w1+gap)*x+w1,y00,x01+(w1+gap)*x+w1+1,y00+value*(y100-y00))
							end
							--losses
							for x, lossesData in ipairs(lossesTable) do
								local eID = lossesData[1]
								local dmg = lossesData[2]
								local value = dmg/maxvalue
								local r4,g4,b4 = GetTeamColor(eID)
								glColor(r4,g4,b4,1)
								glRect(x02+(w2+gap)*x,y00,x02+(w2+gap)*x+w2,y00+value*(y100-y00))
								glColor(0,0,0,1)
								glRect(x02+(w2+gap)*x+w2,y00,x02+(w2+gap)*x+w2+1,y00+value*(y100-y00))
							end
							-- other losses
							local dmgOther = (data.lostHPmisc.total or 0)/maxvalue
							local dmgDebris = data.lostHPmisc.debris or 0
							local dmgGround = data.lostHPmisc.ground or 0
							local dmgObject = data.lostHPmisc.object or 0
							local dmgFire = data.lostHPmisc.fire or 0
							local dmgWater = data.lostHPmisc.water or 0
							local dmgKill = data.lostHPmisc.kill or 0
							local y01 = y00 + dmgDebris/maxvalue * (y100-y00)
							local y02 = y01 + dmgGround/maxvalue * (y100-y00)
							local y03 = y02 + dmgObject/maxvalue * (y100-y00)
							local y04 = y03 + dmgFire/maxvalue   * (y100-y00)
							local y05 = y04 + dmgWater/maxvalue  * (y100-y00)
							local y06 = y05 + dmgKill/maxvalue   * (y100-y00)
							
							-- total other losses
							local n = #Button["legend"]
							local x1 = Panel["2"]["x0"]
							local y1 = Panel["2"]["y1"] - (n+1)*(bs+5) - bs
							
							-- others legend
							if dmgOther > 0 then
								glColor(0.82,0.79,0.79,1) -- snow grey/white
								glRect(x1, y1, x1 + bs, y1 + bs)
								
								myFont:Begin()
								myFont:SetTextColor({0.82,0.79,0.79,1})
								myFont:Print("Other", x1 + bs + 10, y1, 12, 'bs')
								myFont:End()
							end
							
							glColor(0.82,0.79,0.79,1)
							glRect(Panel["4"]["x1"]-10-w2,y00,Panel["4"]["x1"]-10,y00+dmgOther*(y100-y00))
							
							-- debris
							glColor(0,0,0,1) -- black
							glRect(Panel["4"]["x1"]-10-(2*w2/3),y00,Panel["4"]["x1"]-10-(w2/3),y01)
							if dmgDebris > 0 then
								local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther*maxvalue,1))*(bs+5) - bs
								glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
								glColor(0.82,0.79,0.79,1)
								glRect(x1, y10, x1 + bs/3, y10 + bs)
								glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								
								myFont:Begin()
								myFont:SetTextColor({0.82,0.79,0.79,1})
								myFont:Print("Debris", x1 + bs + 10, y10, 12, 'bs')
								myFont:End()
								
							end
							
							--ground
							glColor(0,1,0,1) -- green
							glRect(Panel["4"]["x1"]-10-(2*w2/3),y01,Panel["4"]["x1"]-10-(w2/3),y02)
							if dmgGround > 0 then
								local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther,1)+min(dmgDebris,1))*(bs+5) - bs
								glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
								glColor(0.82,0.79,0.79,1)
								glRect(x1, y10, x1 + bs/3, y10 + bs)
								glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								
								myFont:Begin()
								myFont:SetTextColor({0.82,0.79,0.79,1})
								myFont:Print("Ground", x1 + bs + 10, y10, 12, 'bs')
								myFont:End()
							end
							
							--object
							glColor(0.63,0.13,0.94,1) -- purple
							glRect(Panel["4"]["x1"]-10-(2*w2/3),y02,Panel["4"]["x1"]-10-(w2/3),y03)
							if dmgObject > 0 then
								local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther,1)+min(dmgDebris,1)+min(dmgGround,1))*(bs+5) - bs
								glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
								glColor(0.82,0.79,0.79,1)
								glRect(x1, y10, x1 + bs/3, y10 + bs)
								glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								
								myFont:Begin()
								myFont:SetTextColor({0.82,0.79,0.79,1})
								myFont:Print("Object", x1 + bs + 10, y10, 12, 'bs')
								myFont:End()
							end
							
							--fire
							glColor(1,0,0,1) --red
							glRect(Panel["4"]["x1"]-10-(2*w2/3),y03,Panel["4"]["x1"]-10-(w2/3),y04)
							if dmgFire > 0 then
								local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther,1)+min(dmgDebris,1)+min(dmgGround,1)+min(dmgObject,1))*(bs+5) - bs
								glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
								glColor(0.82,0.79,0.79,1)
								glRect(x1, y10, x1 + bs/3, y10 + bs)
								glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								
								myFont:Begin()
								myFont:SetTextColor({0.82,0.79,0.79,1})
								myFont:Print("Fire", x1 + bs + 10, y10, 12, 'bs')
								myFont:End()
							end
							
							--water
							glColor(0,0,1,1) --blue
							glRect(Panel["4"]["x1"]-10-(2*w2/3),y04,Panel["4"]["x1"]-10-(w2/3),y05)
							if dmgWater > 0 then
								local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther,1)+min(dmgDebris,1)+min(dmgGround,1)+min(dmgObject,1)+min(dmgFire,1))*(bs+5) - bs
								glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
								glColor(0.82,0.79,0.79,1)
								glRect(x1, y10, x1 + bs/3, y10 + bs)
								glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								
								myFont:Begin()
								myFont:SetTextColor({0.82,0.79,0.79,1})
								myFont:Print("Water", x1 + bs + 10, y10, 12, 'bs')
								myFont:End()
							end
							
							--kill
							glColor(0.63,0.32,0.18,1) --brown
							glRect(Panel["4"]["x1"]-10-(2*w2/3),y05,Panel["4"]["x1"]-10-(w2/3),y06)
							if dmgKill > 0 then
								local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther,1)+min(dmgDebris,1)+min(dmgGround,1)+min(dmgObject,1)+min(dmgFire,1)+min(dmgWater,1))*(bs+5) - bs
								glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
								glColor(0.82,0.79,0.79,1)
								glRect(x1, y10, x1 + bs/3, y10 + bs)
								glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								
								myFont:Begin()
								myFont:SetTextColor({0.82,0.79,0.79,1})
								myFont:Print("Collateral", x1 + bs + 10, y10, 12, 'bs')
								myFont:End()
							end
						end
					end
				end
			end	
		end

		local function drawTeamstats()
			----------------------------
			-- PLAYER STATISTICS TAB  --
			-----------------------	----
						
			--panel
			glColor(cPanel)
			glRect(Panel["1"]["x0"],Panel["1"]["y0"],Panel["1"]["x1"], Panel["1"]["y1"])
			
			-- selected statistic
			local statName = "N/A"
						
			-- legend buttons
			for i, sbutton in pairs (Button["teamstatsel"]) do
				
				if sbutton.mouse then
					--highlight
					glColor(cLight)
				elseif sbutton.On then
					--selected
					glColor(cSelect)
					statName = sbutton.name
					
					if Button["teamstats"]["sel"] ~= statName then
						Button["teamstats"]["sel"] = statName
						initButtons()
					end
				else
					-- normal
					glColor(cStatButton)
				end
				glRect(sbutton.x0,sbutton.y0,sbutton.x1,sbutton.y1)
				glColor(cBorder)
				drawBorder(sbutton.x0,sbutton.y0,sbutton.x1,sbutton.y1,1)
				
				myFont:Begin()
				myFont:SetTextColor(cWhite)
				myFont:Print(firstToUpper(sbutton.name), sbutton.x0 + 10, sbutton.y0+3, textsize, 'bs')
				myFont:End()
			end
			
			-- caption
			myFontBig:Begin()
			myFontBig:SetTextColor(cTitle)
			myFontBig:Print(firstToUpper(statName), (Panel["1"]["x0"]+Panel["1"]["x1"])/2,Panel["1"]["y1"] + 30, 16, 'vcs')
			myFontBig:End()
											
			-- axes
			local n = #teamData[1]["buildpower"]["values"] -- x axis is same across all players and data fields, so just grab first one
			local y0 = Panel["1"]["y0"]
			local y100 = Panel["1"]["y1"]
			local y50 = Panel["1"]["y0"] + 0.50 * (Panel["1"]["y1"]-Panel["1"]["y0"])
			local y25 = Panel["1"]["y0"] + 0.25 * (Panel["1"]["y1"]-Panel["1"]["y0"])
			local y75 = Panel["1"]["y0"] + 0.75 * (Panel["1"]["y1"]-Panel["1"]["y0"])
			glColor(cAxes)
			glRect(Panel["1"]["x0"]-1,Panel["1"]["y0"],Panel["1"]["x0"], Panel["1"]["y1"]+10)
			glRect(Panel["1"]["x0"]-5,y0,Panel["1"]["x1"],y0+1)
			glRect(Panel["1"]["x0"]-5,y100,Panel["1"]["x1"],y100+1)
			glRect(Panel["1"]["x0"]-5,y50,Panel["1"]["x1"],y50+1)
			
			
			-- get max/min value
			local largestValue = Button["teamstats"]["maxvalue"] or 1
			local smallestValue = Button["teamstats"]["minvalue"] or 0
						
			myFont:Begin()
			myFont:SetTextColor(cAxesText)
			--myFont:Print(statName, Panel["1"]["x0"]-30,Panel["1"]["y1"] + 20, 10, 'xs')
			myFont:Print(formatRes(smallestValue), Panel["1"]["x0"]-10, y0, 10, 'vro')
			--myFont:Print("50 %", Panel["1"]["x0"]-10, y50, 10, 'vro')
			myFont:Print(formatRes(largestValue), Panel["1"]["x0"]-10, y100, 10, 'vrs')
			myFont:Print("Time: " .. round( (STATSFREQUENCY/60)*(n),0) .. " min", Panel["1"]["x1"]+25,Panel["1"]["y0"]-2, 10, 'xo')
			myFont:End()
			
			glColor(cAxesMinor)
			glRect(Panel["1"]["x0"]-5,y25,Panel["1"]["x1"],y25+1)
			glRect(Panel["1"]["x0"]-5,y75,Panel["1"]["x1"],y75+1)
			
			-- values
			
			local r,g,b
			local x0 		= Panel["1"]["x0"]
			local xspace 	= Panel["1"]["x1"]-Panel["1"]["x0"]
			local yspace	= y100-y0
									
			local function DrawLine(array,i)
				local xscale = n <= 1 and 1 or 1/(n-1)
				local yscale = (largestValue-smallestValue >= 1) and 1/(largestValue-smallestValue) or 1
				local ymin = smallestValue
				
				for x, y in ipairs (array) do
					glVertex(x0+(x-1)*xspace*xscale, y0+(y-ymin)*yspace*yscale) 
				end
			end
			
			local function DrawLineShadow(array,i)
				local xscale = n <= 1 and 1 or 1/(n-1)
				local yscale = (largestValue-smallestValue >= 1) and 1/(largestValue-smallestValue) or 1
				local ymin = smallestValue
								
				for x, y in ipairs (array) do
					glVertex(x0+(x-1)*xspace*xscale, y0+(y-ymin)*yspace*yscale-1)
				end
			end
			
			glLineStipple(false)
			
			if statName and statName ~= "N/A" then
				for tID, data in pairs (teamData) do						
					r,g,b = GetTeamColor(tID)
					local ylast = data[statName]["values"][#data[statName]["values"]]
					local yscale = (largestValue-smallestValue >= 1) and 1/(largestValue-smallestValue) or 1
					local ymin = smallestValue
					
					if not ylast then return end
					
					-- print last value at right border
					myFont:Begin()
					myFont:SetTextColor({r, g, b, 0.8})
					myFont:Print(formatRes(ylast), Panel["1"]["x1"]+10,y0+(ylast-ymin)*yspace*yscale, 10, 'xs')
					myFont:End()
					
					glColor(r, g, b, 0.85) -- set a bit transparency to allow overlapping values
					glLineWidth (2.5)
					gl.BeginEnd(GL.LINE_STRIP, DrawLine,data[statName]["values"],tID)
					glColor(r*0.75, g*0.75, b*0.75,0.85) -- set a bit transparency to allow overlapping values
					glLineWidth (1.5)
					gl.BeginEnd(GL.LINE_STRIP, DrawLineShadow,data[statName]["values"],tID)
				end
				glColor(cWhite)
			end
		end

		local function drawHeroes()
			-----------------
			-- HEROES TAB  --
			-----------------		
				local imgposx = (Panel["5"]["x0"]+Panel["5"]["x1"])/2 - 120 - imgSize
				local imgposx2 = (Panel["5"]["x0"]+Panel["5"]["x1"])/2 + 120
				local imgposy = Panel["5"]["y1"]-30
				
				--panel
				glColor(cPanel)
				glRect(Panel["5"]["x0"],Panel["5"]["y0"],Panel["5"]["x1"], Panel["5"]["y1"])
				
				--title
				myFontBig:Begin()
				myFontBig:SetTextColor(cTitle)
				myFontBig:Print("Heroes in victory", (Panel["5"]["x0"]+Panel["5"]["x1"])/2,Panel["5"]["y1"] - 20, 16, 'vcs')
				myFontBig:End()
				
				-- pictures
				glColor(cWhite)
				glTexture(imgHero)
				glTexRect(imgposx,imgposy,imgposx + imgSize,imgposy + imgSize)
				glTexRect(imgposx2,imgposy,imgposx2 + imgSize,imgposy + imgSize)
				glTexture(false)
				
				glColor(cTitle)
				
				if heroUnits and heroUnits[1] and heroUnits[1][1] then
					myFont:Begin()
					myFont:SetTextColor(cWhite)
					myFont:Print("#",Panel["5"]["x0"]+20, Panel["5"]["y1"]-90, textsize, 'ds')
					myFont:Print("Unit (owner)",Panel["5"]["x0"]+50, Panel["5"]["y1"]-90, textsize, 'ds')
					myFont:Print("Confirmed kills",Panel["5"]["x1"]-100, Panel["5"]["y1"]-90, textsize, 'drs')
					myFont:Print("Age",Panel["5"]["x1"]-50, Panel["5"]["y1"]-90, textsize, 'drs')
					myFont:End()
					glColor(cWhite)
					glRect(Panel["5"]["x0"]+20,Panel["5"]["y1"]-94,Panel["5"]["x1"]-50,Panel["5"]["y1"]-95)
					
					myFont:SetTextColor(cTitle)
					for i, unitdata in ipairs (heroUnits) do
						local name = unitdata[1]
						local kills = unitdata[2]
						local birth = unitdata[3]
						local age = unitdata[4]
						local teamID = unitdata[5]
						local r,g,b = GetTeamColor(teamID)
						local _,leaderID,_,isAI = GetTeamInfo(teamID)
						local leaderName
						if leaderID then
							leaderName	= GetPlayerInfo(leaderID) or (leaderNames[teamID] or "N/A")
						else
							leaderName = "N/A"
						end
						
						if isAI then leaderName = "AI" end	
						if teamID == gaiaID then leaderName = "Gaia" end
						myFont:Begin()
						myFont:Print(tostring(i)..".",Panel["5"]["x0"]+20, Panel["5"]["y1"] - i * 3 * bs - 90, textsize, 'ds')
						myFont:Print(name,Panel["5"]["x0"]+50, Panel["5"]["y1"] - i * 3 * bs - 90, textsize, 'ds')
						myFont:SetTextColor({r, g, b, 1})
						myFont:Print("("..leaderName..")",Panel["5"]["x0"] + 12* gl.GetTextWidth(name) + 60, Panel["5"]["y1"] - i * 3 * bs - 90, textsize, 'ds')
						myFont:SetTextColor(cTitle)
						myFont:Print(tostring(kills),Panel["5"]["x1"]-100, Panel["5"]["y1"]- i * 3 * bs - 90, textsize, 'dro')
						myFont:Print(tostring(age).." min",Panel["5"]["x1"]-50, Panel["5"]["y1"]- i * 3 * bs - 90, textsize, 'dro')
						myFont:End()
					end
				else
					myFont:Begin()
					myFont:Print("(No awards)",(Panel["5"]["x0"]+Panel["5"]["x1"])/2, Panel["5"]["y1"]-90, textsize, 'dcs')
					myFont:End()
				end
				glColor(cWhite)
		end

		local function drawLost()
			---------------
			-- LOST TAB  --
			---------------	

			local imgposx = (Panel["5"]["x0"]+Panel["5"]["x1"])/2 - 100 - imgSize
			local imgposx2 = (Panel["5"]["x0"]+Panel["5"]["x1"])/2 + 100
			local imgposy = Panel["5"]["y1"]-30
			
			--panel
			glColor(cPanel)
			glRect(Panel["5"]["x0"],Panel["5"]["y0"],Panel["5"]["x1"], Panel["5"]["y1"])
			
			--title
			myFontBig:Begin()
			myFontBig:SetTextColor(cTitle)
			myFontBig:Print("Lost in service", (Panel["5"]["x0"]+Panel["5"]["x1"])/2,Panel["5"]["y1"] - 20, 16, 'vcs')
			myFontBig:End()
			
			-- pictures
			glColor(cWhite)
			glTexture(imgLost)
			glTexRect(imgposx,imgposy,imgposx + imgSize,imgposy + imgSize)
			glTexRect(imgposx2,imgposy,imgposx2 + imgSize,imgposy + imgSize)
			glTexture(false)
			
			glColor(cTitle)
			
			if lostUnits and lostUnits[1] and lostUnits[1][1] then
				myFont:Begin()
				myFont:SetTextColor(cWhite)
				myFont:Print("#",Panel["5"]["x0"]+20, Panel["5"]["y1"]-90, textsize, 'ds')
				myFont:Print("Unit (owner)",Panel["5"]["x0"]+50, Panel["5"]["y1"]-90, textsize, 'ds')
				myFont:Print("Confirmed kills",Panel["5"]["x1"]-150, Panel["5"]["y1"]-90, textsize, 'drs')
				myFont:Print("Birth",Panel["5"]["x1"]-100, Panel["5"]["y1"]-90, textsize, 'drs')
				myFont:Print("Death",Panel["5"]["x1"]-50, Panel["5"]["y1"]-90, textsize, 'drs')
				myFont:End()
				glColor(cWhite)
				glRect(Panel["5"]["x0"]+20,Panel["5"]["y1"]-94,Panel["5"]["x1"]-50,Panel["5"]["y1"]-95)
				
				myFont:SetTextColor(cTitle)
				for i, unitdata in ipairs (lostUnits) do
					local name = unitdata[1]
					local kills = unitdata[2]
					local birth = unitdata[3]
					local death = unitdata[4]
					local teamID = unitdata[5]
					local r,g,b = GetTeamColor(teamID)
					local _,leaderID,_,isAI = GetTeamInfo(teamID)
					local leaderName
					if leaderID then
						leaderName	= GetPlayerInfo(leaderID) or (leaderNames[teamID] or "N/A")
					else
						leaderName = "N/A"
					end
					
					if isAI then leaderName = "AI" end	
					if teamID == gaiaID then leaderName = "Gaia" end
					
					myFont:Begin()
					myFont:Print(tostring(i)..".",Panel["5"]["x0"]+20, Panel["5"]["y1"] - i * 3 * bs - 90, textsize, 'ds')
					myFont:Print(name,Panel["5"]["x0"]+50, Panel["5"]["y1"] - i * 3 * bs - 90, textsize, 'ds')
					myFont:SetTextColor({r, g, b, 1})
					myFont:Print("("..leaderName..")",Panel["5"]["x0"] + 12* gl.GetTextWidth(name) + 60, Panel["5"]["y1"] - i * 3 * bs - 90, textsize, 'ds')
					myFont:SetTextColor(cTitle)
					myFont:Print(tostring(kills),Panel["5"]["x1"]-150, Panel["5"]["y1"]- i * 3 * bs - 90, textsize, 'dro')
					myFont:Print(tostring(birth).." min",Panel["5"]["x1"]-100, Panel["5"]["y1"]- i * 3 * bs - 90, textsize, 'dro')
					myFont:Print(tostring(death).." min",Panel["5"]["x1"]-50, Panel["5"]["y1"]- i * 3 * bs - 90, textsize, 'dro')
					myFont:End()
				end
			else
				myFont:Begin()
				myFont:Print("(No awards)",(Panel["5"]["x0"]+Panel["5"]["x1"])/2, Panel["5"]["y1"]-90, textsize, 'dcs')
				myFont:End()
			end
		end

		local function transferIsComplete()
			if allyData and #allyData > 0 then
				local maxval = 0
				local minval = math.huge					
				
				for i, aData in ipairs (allyData) do
					local array = aData["values"]
												
					for k,v in pairs( array ) do
						if type(v) == 'number' then
							maxval = max( maxval, v )
							minval = min( minval, v )
						end
					end
					
					Button["influence"]["maxvalue"] = maxval
					Button["influence"]["minvalue"] = minval
				end
			end
			
			areAwards = badges and (badges["commloss"] or badges["firstT2"] or badges["topKiller"] or (badges["special"] and badges["special"]["n"] and badges["special"]["n"] > 0) )
			
			if areAwards then
				Button["influence"]["On"] = false
				Button["awards"]["On"] = true
			end
		end
		
		function gadget:Initialize()
			--register actions to SendToUnsynced messages
			gadgetHandler:AddSyncAction("teamData", onTeamData)
			gadgetHandler:AddSyncAction("allyData", onAllyData)
			gadgetHandler:AddSyncAction("heroUnits", onHeroUnits)
			gadgetHandler:AddSyncAction("lostUnits", onLostUnits)
			gadgetHandler:AddSyncAction("badges", onBadges)
			
			-- don't update these callins ntil game has finished
			gadgetHandler:RemoveCallIn("DrawScreen")
			gadgetHandler:RemoveCallIn("MousePress")
			gadgetHandler:RemoveCallIn("MouseMove")
			gadgetHandler:RemoveCallIn("IsAbove")
			
			Button["exit"] 				= {}
			Button["proceed"] 			= {}
			Button["influence"]			= {}
			Button["influence"]["On"]	= true
			Button["matrix"]			= {}
			Button["heroes"]			= {}
			Button["lost"]				= {}
			Button["awards"]			= {}
			Button["awards"]["On"]		= false
			Button["teamstats"]			= {}
			Button["teamstats"]["sel"]	= "buildpower"
			Button["teamstatsel"]		= {}
			Button["teamstatsel"][1]    = {}
			Button["teamstatsel"][1]["On"] = true
			Button["teamstatsel"][2]    = {}
			Button["teamstatsel"][3] 	= {}
			Button["teamstatsel"][4] 	= {}
			Button["teamstatsel"][5] 	= {}
			Button["teamstatsel"][6] 	= {}
			
			Button["exit"]["label"] 		= "Exit"
			Button["proceed"]["label"] 		= "More statistics"
			Button["influence"]["label"] 	= "Influence"
			Button["matrix"]["label"] 		= "Who killed who"
			Button["heroes"]["label"] 		= "Heroes in victory"
			Button["lost"]["label"] 		= "Lost in service"
			Button["awards"]["label"] 		= "Awards"
			Button["teamstats"]["label"] 	= "Team statistics"
			
			Button["legend"]			= {}
			Panel["back"] 				= {}
			Panel["1"] 					= {}
			Panel["2"] 					= {}
			Panel["3"] 					= {}
			Panel["4"] 					= {}
			Panel["5"] 					= {}
			Panel["awards"] 			= {}
			initButtons()
			
			for _, tID in ipairs(Spring.GetTeamList()) do
				local _,leaderID = Spring.GetTeamInfo(tID)
				local name = Spring.GetPlayerInfo(leaderID)
				if name then leaderNames[tID] = name end
			end
		end	

		-- Run this part only after game over

		function gadget:Update(dt)
			
			if IsGameOver() then			
				if not drawWindow then
					drawWindow = Spring.GetGameRulesParam("ShowEnd") == 1
					if drawWindow then
						gadgetHandler:UpdateCallIn("DrawScreen")
						gadgetHandler:UpdateCallIn("MousePress")
						gadgetHandler:UpdateCallIn("MouseMove")
						gadgetHandler:UpdateCallIn("IsAbove")
						transferIsComplete()
					end
				end
			end			
		end

		-- Run this part only after game over and processing ready

		function gadget:DrawScreen()				
			if drawWindow and not Spring.IsGUIHidden() and GG.showXTAStats then 
				--back panel
				glColor(cBack)
				glRect(Panel["back"]["x0"],Panel["back"]["y0"],Panel["back"]["x1"], Panel["back"]["y1"])
				
				-- Buttons
				for name, button in pairs(Button) do
					local drawCondition
					if name == "exit" or name == "proceed" or name == "influence" or name == "matrix" or name == "teamstats" then
						drawCondition = true
					elseif name == "awards" then
						drawCondition = areAwards
					elseif name == "heroes" then
						drawCondition = areHeroes
					elseif name == "lost" then
						drawCondition = areLost
					end
					
					if drawCondition then
						if button.mouse then
							glColor(cLight)
						elseif button.On then
							glColor(cSelect)
						else
							glColor(cButton)
						end
						glRect(button.x0,button.y0,button.x1,button.y1)
						glColor(cBorder)
						drawBorder(button.x0,button.y0,button.x1,button.y1,1)
						
						-- text
						myFontMed:Begin()
						myFontMed:SetTextColor(cWhite)
						myFontMed:Print(button.label, button.x0 + 10 ,button.y0 + 10, 14, 'xs')
						myFontMed:End()
					end
				end
				
				-- chart window
				if Button["influence"]["On"] then
					if allyData and allyData[1] then
						drawInfluence()
					end
				elseif Button["teamstats"]["On"] then
					if teamData and teamData[1] then
						drawTeamstats()
					end
				elseif Button["matrix"]["On"] then
					if teamData then
						drawMatrix()
					end
				elseif Button["heroes"]["On"] then	
					drawHeroes()
				elseif Button["lost"]["On"] then
					drawLost()
				elseif Button["awards"]["On"] then
					drawAwards()
				end
			end
		end
			
		function gadget:MousePress(mx, my, mButton)
			if (not Spring.IsGUIHidden()) and drawWindow and GG.showXTAStats and IsOnButton(mx,my, Panel["back"]["x0"], Panel["back"]["y0"], Panel["back"]["x1"], Panel["back"]["y1"]) then
				if (mButton == 2 or mButton == 3) then
					-- Dragging
					return true
				elseif mButton == 1 then
					if IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
						Spring.SendCommands("quitforce")
						PlaySoundFile(beep)
						gadgetHandler:RemoveGadget()
						return true
					elseif IsOnButton(mx,my,Button["proceed"]["x0"],Button["proceed"]["y0"],Button["proceed"]["x1"],Button["proceed"]["y1"]) then
						Spring.SendCommands('endgraph 1')
						GG.showXTAStats = false
						PlaySoundFile(button6)
					elseif IsOnButton(mx,my,Button["influence"]["x0"],Button["influence"]["y0"],Button["influence"]["x1"],Button["influence"]["y1"]) then
						Button["influence"]["On"] = true
						Button["teamstats"]["On"] = false
						Button["matrix"]["On"] = false
						Button["heroes"]["On"] = false
						Button["lost"]["On"] = false
						Button["awards"]["On"] = false
						PlaySoundFile(button6)
					elseif IsOnButton(mx,my,Button["teamstats"]["x0"],Button["teamstats"]["y0"],Button["teamstats"]["x1"],Button["teamstats"]["y1"]) then
						Button["influence"]["On"] = false
						Button["teamstats"]["On"] = true
						Button["matrix"]["On"] = false
						Button["heroes"]["On"] = false
						Button["lost"]["On"] = false
						Button["awards"]["On"] = false
						PlaySoundFile(button6)
					elseif IsOnButton(mx,my,Button["matrix"]["x0"],Button["matrix"]["y0"],Button["matrix"]["x1"],Button["matrix"]["y1"]) then
						Button["matrix"]["On"] = true
						Button["influence"]["On"] = false
						Button["heroes"]["On"] = false
						Button["lost"]["On"] = false
						Button["awards"]["On"] = false
						Button["teamstats"]["On"] = false
						PlaySoundFile(button6)
					elseif areHeroes and IsOnButton(mx,my,Button["heroes"]["x0"],Button["heroes"]["y0"],Button["heroes"]["x1"],Button["heroes"]["y1"]) then
						Button["heroes"]["On"] = true
						Button["influence"]["On"] = false
						Button["matrix"]["On"] = false
						Button["lost"]["On"] = false
						Button["awards"]["On"] = false
						Button["teamstats"]["On"] = false
						PlaySoundFile(button6)
					elseif areLost and IsOnButton(mx,my,Button["lost"]["x0"],Button["lost"]["y0"],Button["lost"]["x1"],Button["lost"]["y1"]) then
						Button["lost"]["On"] = true
						Button["influence"]["On"] = false
						Button["matrix"]["On"] = false
						Button["heroes"]["On"] = false
						Button["awards"]["On"] = false
						Button["teamstats"]["On"] = false
						PlaySoundFile(button6)
					elseif areAwards and IsOnButton(mx,my,Button["awards"]["x0"],Button["awards"]["y0"],Button["awards"]["x1"],Button["awards"]["y1"]) then
						Button["awards"]["On"] = true
						Button["influence"]["On"] = false
						Button["matrix"]["On"] = false
						Button["heroes"]["On"] = false
						Button["lost"]["On"] = false
						Button["teamstats"]["On"] = false
						PlaySoundFile(button6)
					else
						if Button["matrix"]["On"] then
							for _, lbutton in pairs (Button["legend"]) do
								if IsOnButton(mx,my,lbutton["x0"],lbutton["y0"],lbutton["x1"],lbutton["y1"]) then
									for _,l2button in pairs (Button["legend"]) do
										l2button["On"] = false
									end
									lbutton["On"] = true
								end
							end
						elseif Button["teamstats"]["On"] then
							for _, lbutton in pairs (Button["teamstatsel"]) do
								if IsOnButton(mx,my,lbutton["x0"],lbutton["y0"],lbutton["x1"],lbutton["y1"]) then
									for _,l2button in pairs (Button["teamstatsel"]) do
										l2button["On"] = false
									end
									lbutton["On"] = true
									initButtons()
									PlaySoundFile(button8)
								end
							end
						end
					end
				end
			end
			return false
		end
				
		function gadget:MouseMove(mx, my, dx, dy, mButton)
			if drawWindow and GG.showXTAStats then
				-- Dragging
				if mButton == 2 or mButton == 3 then
					-- allow moving off screen
					px = px+dx
					py = py+dy
				end
				initButtons()
			end
			return false
		end

		function gadget:IsAbove(mx,my)
			if drawWindow and GG.showXTAStats then
				Button["exit"]["mouse"] = false
				Button["proceed"]["mouse"] = false
				Button["influence"]["mouse"] = false
				Button["teamstats"]["mouse"] = false
				Button["heroes"]["mouse"] = false
				Button["lost"]["mouse"] = false
				Button["matrix"]["mouse"] = false
				Button["awards"]["mouse"] = false
					
				for _,lbutton in pairs (Button["legend"]) do
					lbutton["mouse"] = false
				end
				
				for _,lbutton in pairs (Button["teamstatsel"]) do
					lbutton["mouse"] = false
				end
				
				if IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then		
					Button["exit"]["mouse"] = true
				elseif IsOnButton(mx,my,Button["proceed"]["x0"],Button["proceed"]["y0"],Button["proceed"]["x1"],Button["proceed"]["y1"]) then
					Button["proceed"]["mouse"] = true
				elseif IsOnButton(mx,my,Button["influence"]["x0"],Button["influence"]["y0"],Button["influence"]["x1"],Button["influence"]["y1"]) then
					Button["influence"]["mouse"] = true
				elseif IsOnButton(mx,my,Button["teamstats"]["x0"],Button["teamstats"]["y0"],Button["teamstats"]["x1"],Button["teamstats"]["y1"]) then
					Button["teamstats"]["mouse"] = true
				elseif IsOnButton(mx,my,Button["matrix"]["x0"],Button["matrix"]["y0"],Button["matrix"]["x1"],Button["matrix"]["y1"]) then
					Button["matrix"]["mouse"] = true
				elseif areHeroes and IsOnButton(mx,my,Button["heroes"]["x0"],Button["heroes"]["y0"],Button["heroes"]["x1"],Button["heroes"]["y1"]) then
					Button["heroes"]["mouse"] = true
				elseif areLost and IsOnButton(mx,my,Button["lost"]["x0"],Button["lost"]["y0"],Button["lost"]["x1"],Button["lost"]["y1"]) then
					Button["lost"]["mouse"] = true
				elseif areAwards and IsOnButton(mx,my,Button["awards"]["x0"],Button["awards"]["y0"],Button["awards"]["x1"],Button["awards"]["y1"]) then
					Button["awards"]["mouse"] = true
				else
					if Button["matrix"]["On"] then
						for _, lbutton in pairs (Button["legend"]) do
							if IsOnButton(mx,my,lbutton["x0"],lbutton["y0"],lbutton["x1"],lbutton["y1"]) then
								lbutton["mouse"] = true
							end
						end
					elseif Button["teamstats"]["On"] then
						for _, lbutton in pairs (Button["teamstatsel"]) do
							if IsOnButton(mx,my,lbutton["x0"],lbutton["y0"],lbutton["x1"],lbutton["y1"]) then
								if not lbutton.On then
									lbutton["mouse"] = true
								end
							end
						end
					end
				end
			end
		end

		function gadget:Shutdown()
			drawWindow = false
			gadgetHandler:RemoveSyncAction("RecieveEndStats")
			gadgetHandler:RemoveSyncAction("teamData")
			gadgetHandler:RemoveSyncAction("heroUnits")
			gadgetHandler:RemoveSyncAction("lostUnits")		
		end
	end
end