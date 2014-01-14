
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
	
if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------
	
	local teamData = {}
	local allyData = {}
	local gameData = {}
	local mapX, mapZ
	local ignoreUnits = {}
	local heroUnits = {}
	local lostUnits = {}
	local MINKILLS	= 25 -- minimum kills for awards
	local SAMPLEFREQUENCY = 60 -- in seconds
	
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
	
	local function round(num, idp)
		return string.format("%." .. (idp or 0) .. "f", num)
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
				
				if true then --tID ~= gaiaID then
					teamData[tID] = {}
					local _,leaderID,isDead,isAI,side 	= GetTeamInfo(tID)
					
					if leaderID then
						local leaderName,active,spectator	= GetPlayerInfo(leaderID)				
						teamData[tID]['side'] = side
						teamData[tID]['leader'] = leaderName
						teamData[tID]['killedHP'] = {}
						teamData[tID]['lostHP'] = {}
						teamData[tID]['isAI'] = isAI
						teamData[tID]['lostHPmisc'] = {} -- for losses with unreconciled attackers
						--teamData[tID]['ally'] = aID+1
						--teamData[tID]['alive'] = not isDead
						--teamData[tID]['hasCommander'] = false
						--teamData[tID]['active'] = active
						--teamData[tID]['spec'] = spectator
						--teamData[tID]['killcount'] = {}
						--teamData[tID]['deathcount'] = {}
						--teamData[tID]['firepower'] = {}
						--teamData[tID]['buildpower'] = {}
						
					end
				end
			end
		end
		
		for id, unitDef in ipairs (UnitDefs) do
			if unitDef.customParams.dontcount then
				ignoreUnits[id] = true
			end
		end
	
	end
	
	function isUnitComplete(unitID)
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
	
	function readZoneOfControls()
		
		local zoc = {}
		local chunks = 0
		local allyList = GetAllyTeamList()
		local frame = GetGameFrame()
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
	
	function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
				
		if teamID and isUnitComplete(unitID) then 
			
			local _,hp = GetUnitHealth(unitID)
			if attackerTeamID then			
				if not teamData[teamID]['lostHP'][attackerTeamID] then
					teamData[teamID]['lostHP'][attackerTeamID] = 0
				end
				teamData[teamID]['lostHP'][attackerTeamID] = teamData[teamID]['lostHP'][attackerTeamID] + hp
			elseif not ignoreUnits[unitDefID] then
				if not teamData[teamID]['lostHPmisc']['total'] then teamData[teamID]['lostHPmisc']['total'] = 0 end
				
				teamData[teamID]['lostHPmisc']['total'] = teamData[teamID]['lostHPmisc']['total'] + hp
			end
			
			-- blue on blue counts as loss but not as kill
			if attackerTeamID and attackerTeamID ~=  teamID and (not AreTeamsAllied(attackerTeamID,teamID)) then			
				if not teamData[attackerTeamID]['killedHP'][teamID] then
					teamData[attackerTeamID]['killedHP'][teamID] = 0
				end
				teamData[attackerTeamID]['killedHP'][teamID] = teamData[attackerTeamID]['killedHP'][teamID] + hp
				
				local kills = Spring.GetUnitRulesParam(attackerID,'kills') or 0
				kills = kills + 1
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
		end
	end
	
	function gadget:UnitDamaged(unitID, unitDefID, teamID, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
		if teamID and isUnitComplete(unitID) and weaponDefID < 0 then --and teamID ~= gaiaID and attackerTeam ~= gaiaID then
			local health,hp = GetUnitHealth(unitID)
			if health < 0 then
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
			end
		end
	end
	
	function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
		local frame = Spring.GetGameFrame()
		Spring.SetUnitRulesParam(unitID,'born',frame)
	end
	
	function gadget:GameFrame(frame)
		if frame%(SAMPLEFREQUENCY*30) == 0 then -- read according to sample frequency
			readZoneOfControls()
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

	
	function gadget:GameOver()
		readZoneOfControls()
		
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
		
		SendTableToUnsynced("allyData", allyData)
		SendTableToUnsynced("teamData", teamData)
		SendTableToUnsynced("heroUnits", heroUnits)
		SendTableToUnsynced("lostUnits", lostUnits)
		
	end
	
else
	-------------------
	-- UNSYNCED PART --
	-------------------
	
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
	local glText 						= gl.Text
	local glLineWidth					= gl.LineWidth
	local Button 						= {}
	local Panel 						= {}
	local vsx, vsy 						= gl.GetViewSizes()
	local sizex, sizey  				= 800, 450
	local px, py 		 				= vsx/2-sizex/2, vsy/2-sizey/2
	local max, min 						= math.max, math.min
	local drawWindow					= false
	local allyData						= {}
	local nData							= {}
	local teamData						= nil
	local heroUnits						= nil
	local lostUnits						= nil
	local bs 							= 10 	-- button space and also box size
	local inited 						= false
	local maxkilled						= 0
	local maxkiller, maxloser						
	local maxlost						= 0
	local maxvalue						= 0
	local maxvalueplayer				
	local teamTotals					= {}
	local gaiaID						= Spring.GetGaiaTeamID()
	
	local function getTotals()
	
		for tID, data in pairs(teamData) do
			teamTotals[tID] = {}
			teamTotals[tID]["killed"] = 0
			teamTotals[tID]["lost"] = data["lostHPmisc"]['total'] or 0
			
			if data["lostHPmisc"]['total'] and data["lostHPmisc"]['total'] > maxvalue then
				maxvalue = data["lostHPmisc"]['total']
			end
			
			for _, dmg in pairs (data["killedHP"]) do
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
			
			for _, dmg in pairs (data["lostHP"]) do
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
	
	local function initButtons()
		
		--length of buttons
		local L1 = 205	-- proceed
		local L2 = 45	-- exit
		local L3 = 80	-- influence
		local L4 = 160	-- player matrix
		local L5 = 130	-- heroes
		local L6 = 115 	-- lost
		
		--back panel for whole thing
		Panel["back"]["x0"] 	= px
		Panel["back"]["y0"] 	= py
		Panel["back"]["x1"] 	= px + sizex
		Panel["back"]["y1"] 	= py + sizey
		
		--chart area for 'influence' tab
		Panel["1"]["x0"] 		= px + 130
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
		Panel["3"]["y0"] 		= py + 80
		Panel["3"]["x1"] 		= px + sizex/2 - 15 + 30
		Panel["3"]["y1"] 		= py + sizey - 200
		
		--player matrix tab, losses chart
		Panel["4"]["x0"] 		= px + sizex/2 + 15 + 30
		Panel["4"]["y0"] 		= py + 80
		Panel["4"]["x1"] 		= px + sizex - 110 + 30
		Panel["4"]["y1"] 		= py + sizey - 200
		
		--lost units panel
		Panel["5"]["x0"] 		= px + 100
		Panel["5"]["y0"] 		= py + 80
		Panel["5"]["x1"] 		= px + sizex - 100
		Panel["5"]["y1"] 		= py + sizey - 100
		
		Button["proceed"]["x0"]	= Panel["back"]["x1"] - (L1 + L2 + 2*bs)
		Button["proceed"]["y0"]	= py + 10
		Button["proceed"]["x1"]	= Button["proceed"]["x0"] + L1
		Button["proceed"]["y1"]	= py + 40
		
		Button["exit"]["x0"]	= Button["proceed"]["x1"] + bs
		Button["exit"]["y0"]	= py + 10
		Button["exit"]["x1"]	= Button["exit"]["x0"] + L2
		Button["exit"]["y1"]	= py + 40
		
		Button["influence"]["x0"]	= Panel["back"]["x0"] + bs
		Button["influence"]["y0"]	= Panel["back"]["y1"] - 40
		Button["influence"]["x1"]	= Button["influence"]["x0"] + L3
		Button["influence"]["y1"]	= Panel["back"]["y1"] - 10
		
		Button["matrix"]["x0"] 		= Button["influence"]["x1"] + bs
		Button["matrix"]["y0"] 		= Panel["back"]["y1"] - 40
		Button["matrix"]["x1"] 		= Button["matrix"]["x0"] + L4
		Button["matrix"]["y1"] 		= Panel["back"]["y1"] - 10
		
		Button["heroes"]["x0"]	= Button["matrix"]["x1"] + bs
		Button["heroes"]["y0"]	= Panel["back"]["y1"] - 40
		Button["heroes"]["x1"]	= Button["heroes"]["x0"] + L5
		Button["heroes"]["y1"]	= Panel["back"]["y1"] - 10
		
		Button["lost"]["x0"]	= Button["heroes"]["x1"] + bs
		Button["lost"]["y0"]	= Panel["back"]["y1"] - 40
		Button["lost"]["x1"]	= Button["lost"]["x0"] + L6
		Button["lost"]["y1"]	= Panel["back"]["y1"] - 10
		
		if teamData then
			for tID, _ in pairs (teamData) do
				if tID ~= gaiaID then
					if not Button["legend"][tID] then Button["legend"][tID] = {} end
					
					local x0 = Panel["2"]["x0"]
					local y0 = Panel["2"]["y1"] - tID*(bs+5) - bs			
					
					Button["legend"][tID]["x0"] = x0 
					Button["legend"][tID]["y0"] = y0
					Button["legend"][tID]["x1"] = x0 + bs
					Button["legend"][tID]["y1"] = y0 + bs
				end
			end
			
			if not inited then
				Button["legend"][myTeamID]["On"] = true
				getTotals()
				inited = true
			end
		end
		
	end
	
	local function round(num, idp)
		return string.format("%." .. (idp or 0) .. "f", num)
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
		
		--set up endgame graph
		drawWindow = true
		Spring.SendCommands('endgraph 0')
		initButtons()
		Button["influence"]["On"] = true
		
	end

	function onHeroUnits(_, ...)
		heroUnits, _ = ReceiveTableFromSynced(true, select('#', ...), heroUnits, ...)
	end

	function onLostUnits(_, ...)
		lostUnits, _ = ReceiveTableFromSynced(true, select('#', ...), lostUnits, ...)
	end
	
	function gadget:Initialize()
	--register actions to SendToUnsynced messages
		gadgetHandler:AddSyncAction("teamData", onTeamData)
		gadgetHandler:AddSyncAction("allyData", onAllyData)
		gadgetHandler:AddSyncAction("heroUnits", onHeroUnits)
		gadgetHandler:AddSyncAction("lostUnits", onLostUnits)
		
		Button["exit"] 				= {}
		Button["proceed"] 			= {}
		Button["influence"]			= {}
		Button["influence"]["On"] 	= true
		Button["matrix"]			= {}
		Button["heroes"]			= {}
		Button["lost"]				= {}
		Button["legend"]			= {}
		Panel["back"] 				= {}
		Panel["back"]["On"]			= false
		Panel["1"] 					= {}
		Panel["2"] 					= {}
		Panel["3"] 					= {}
		Panel["4"] 					= {}
		Panel["5"] 					= {}
		initButtons()
	end	
	
	function gadget:DrawScreen()
		
		local function drawBorder(x0, y0, x1, y1, width)
			glRect(x0, y0, x1, y0 + width)
			glRect(x0, y1, x1, y1 - width)
			glRect(x0, y0, x0 + width, y1)
			glRect(x1, y0, x1 - width, y1)
		end
		
		if drawWindow and not Spring.IsGUIHidden() then 
			--back panel
			glColor(0.3, 0.3, 0.4, 0.4)
			glRect(Panel["back"]["x0"],Panel["back"]["y0"],Panel["back"]["x1"], Panel["back"]["y1"])
			--exit button
			glColor(0, 0, 0, 0.4)
			glRect(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
			glColor(0, 0, 0, 1)
			drawBorder(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"],1)
			glColor(1, 1, 1, 1)
			glText("Exit", Button["exit"]["x0"] + 10 ,Button["exit"]["y0"] + 10, 14, 'x')
			--proceed button
			glColor(0, 0, 0, 0.4)
			glRect(Button["proceed"]["x0"],Button["proceed"]["y0"], Button["proceed"]["x1"], Button["proceed"]["y1"])
			glColor(0, 0, 0, 1)
			drawBorder(Button["proceed"]["x0"],Button["proceed"]["y0"], Button["proceed"]["x1"], Button["proceed"]["y1"],1)
			glColor(1, 1, 1, 1)
			glText("Proceed to engine statistics", Button["proceed"]["x0"] + 10 ,Button["proceed"]["y0"] + 10, 14, 'x')
			--influence tab button
			glColor(0, 0, 0, 0.4)
			glRect(Button["influence"]["x0"],Button["influence"]["y0"], Button["influence"]["x1"], Button["influence"]["y1"])
			glColor(0, 0, 0, 1)
			drawBorder(Button["influence"]["x0"],Button["influence"]["y0"], Button["influence"]["x1"], Button["influence"]["y1"],1)
			glColor(1, 1, 1, 1)
			glText("Influence", Button["influence"]["x0"] + 10 ,Button["influence"]["y0"] + 10, 14, 'x')
			-- player matrix tab button
			glColor(0, 0, 0, 0.4)
			glRect(Button["matrix"]["x0"],Button["matrix"]["y0"], Button["matrix"]["x1"], Button["matrix"]["y1"])
			glColor(0, 0, 0, 1)
			drawBorder(Button["matrix"]["x0"],Button["matrix"]["y0"], Button["matrix"]["x1"], Button["matrix"]["y1"],1)
			glColor(1, 1, 1, 1)
			glText("Player kills/losses", Button["matrix"]["x0"] + 10 ,Button["matrix"]["y0"] + 10, 14, 'x')
			--heroes tab button
			glColor(0, 0, 0, 0.4)
			glRect(Button["heroes"]["x0"],Button["heroes"]["y0"], Button["heroes"]["x1"], Button["heroes"]["y1"])
			glColor(0, 0, 0, 1)
			drawBorder(Button["heroes"]["x0"],Button["heroes"]["y0"], Button["heroes"]["x1"], Button["heroes"]["y1"],1)
			glColor(1, 1, 1, 1)
			glText("Heroes in victory", Button["heroes"]["x0"] + 10 ,Button["heroes"]["y0"] + 10, 14, 'x')
			--lost tab button
			glColor(0, 0, 0, 0.4)
			glRect(Button["lost"]["x0"],Button["lost"]["y0"], Button["lost"]["x1"], Button["lost"]["y1"])
			glColor(0, 0, 0, 1)
			drawBorder(Button["lost"]["x0"],Button["lost"]["y0"], Button["lost"]["x1"], Button["lost"]["y1"],1)
			glColor(1, 1, 1, 1)
			glText("Lost in service", Button["lost"]["x0"] + 10 ,Button["lost"]["y0"] + 10, 14, 'x')			
			-- Highlight
			glColor(0.8, 0.8, 0.2, 0.5)
			if Button["exit"]["mouse"] then
				glRect(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
			elseif Button["proceed"]["mouse"] then
				glRect(Button["proceed"]["x0"],Button["proceed"]["y0"], Button["proceed"]["x1"], Button["proceed"]["y1"])
			elseif Button["influence"]["mouse"] and not Button["influence"]["On"] then
				glRect(Button["influence"]["x0"],Button["influence"]["y0"], Button["influence"]["x1"], Button["influence"]["y1"])
			elseif Button["matrix"]["mouse"] and not Button["matrix"]["On"] then
				glRect(Button["matrix"]["x0"],Button["matrix"]["y0"], Button["matrix"]["x1"], Button["matrix"]["y1"])
			elseif Button["heroes"]["mouse"] and not Button["heroes"]["On"] then
				glRect(Button["heroes"]["x0"],Button["heroes"]["y0"], Button["heroes"]["x1"], Button["heroes"]["y1"])
			elseif Button["lost"]["mouse"] and not Button["lost"]["On"] then
				glRect(Button["lost"]["x0"],Button["lost"]["y0"], Button["lost"]["x1"], Button["lost"]["y1"])
			end
			-- button selected
			glColor(0.8, 0.8, 0.8, 0.5)
			if Button["influence"]["On"] then
				glRect(Button["influence"]["x0"],Button["influence"]["y0"], Button["influence"]["x1"], Button["influence"]["y1"])
			elseif Button["matrix"]["On"] then
				glRect(Button["matrix"]["x0"],Button["matrix"]["y0"], Button["matrix"]["x1"], Button["matrix"]["y1"])
			elseif Button["heroes"]["On"] then
				glRect(Button["heroes"]["x0"],Button["heroes"]["y0"], Button["heroes"]["x1"], Button["heroes"]["y1"])
			elseif Button["lost"]["On"] then
				glRect(Button["lost"]["x0"],Button["lost"]["y0"], Button["lost"]["x1"], Button["lost"]["y1"])
			end
			
			-- chart window
			if Button["influence"]["On"] then
				-- title
				glColor(0.8, 0.8, 1.0, 1)
				glText("Territorial influence over time", (Panel["1"]["x0"]+Panel["1"]["x1"])/2,Panel["1"]["y1"] + 30, 16, 'vc')
				glColor(0.7, 0.7, 1.0, 0.4)
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
						glText("Team " .. tostring(aID),x00+20,y00, 12,'b')
					else
						glColor(0.8, 0.8, 0.8, 0.7)
						glText("(Empty)",x00+20,y00-2, 12,'b')
					end
				end
				
				-- axes
				local n = #allyData[1]["values"]
				local y0 = Panel["1"]["y0"]
				local y100 = Panel["1"]["y1"]
				local y50 = Panel["1"]["y0"] + 0.50 * (Panel["1"]["y1"]-Panel["1"]["y0"])
				local y25 = Panel["1"]["y0"] + 0.25 * (Panel["1"]["y1"]-Panel["1"]["y0"])
				local y75 = Panel["1"]["y0"] + 0.75 * (Panel["1"]["y1"]-Panel["1"]["y0"])
				glColor(0.2, 0.2, 0.2, 1)
				glRect(Panel["1"]["x0"]-1,Panel["1"]["y0"],Panel["1"]["x0"], Panel["1"]["y1"]+10)
				glText("Influence", Panel["1"]["x0"]-30,Panel["1"]["y1"] + 20, 12, 'x')
				glText("0 %", Panel["1"]["x0"]-10, y0, 10, 'vr')
				glText("50 %", Panel["1"]["x0"]-10, y50, 10, 'vr')
				glText("100 %", Panel["1"]["x0"]-10, y100, 10, 'vr')
				glText("Time: " .. n-1 .. " min", Panel["1"]["x1"]+10,Panel["1"]["y0"]-2, 12, 'x')
				glRect(Panel["1"]["x0"]-5,y0,Panel["1"]["x1"],y0+1)
				glRect(Panel["1"]["x0"]-5,y100,Panel["1"]["x1"],y100+1)
				glRect(Panel["1"]["x0"]-5,y50,Panel["1"]["x1"],y50+1)
				glColor(0.3, 0.3, 0.3, 1)
				glRect(Panel["1"]["x0"]-5,y25,Panel["1"]["x1"],y25+1)
				glRect(Panel["1"]["x0"]-5,y75,Panel["1"]["x1"],y75+1)
				
				-- values
				local r,g,b
				
				
				local x0 		= Panel["1"]["x0"]
				local xspace 	= Panel["1"]["x1"]-Panel["1"]["x0"]
				local yspace	= y100-y0
				
				local function DrawLine(array,i)
					local xscale
					if n <= 1 then
						xscale = 1
					else
						xscale = 1/(n-1)
					end
					for x, y in ipairs (array) do
						glVertex(x0+(x-1)*xspace*xscale, y0+y*yspace-(i-1))
					end
				end
				
				local function DrawLineShadow(array,i)
					local xscale
					if n <= 1 then
						xscale = 1
					else
						xscale = 1/(n-1)
					end
					
					for x, y in ipairs (array) do
						glVertex(x0+(x-1)*xspace*xscale, y0+y*yspace-1-(i-1))
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
						glLineWidth (2.0)
						gl.BeginEnd(GL.LINE_STRIP, DrawLine,aData["values"],i)
						glColor(r*0.75, g*0.75, b*0.75,0.85) -- set a bit transparency to allow overlapping values
						glLineWidth (1.0)
						gl.BeginEnd(GL.LINE_STRIP, DrawLineShadow,aData["values"],i)
					end
				end
				glColor(1, 1, 1, 1)
			elseif Button["matrix"]["On"] then
				
				-- charts
				glColor(0.2, 0.2, 0.3, 0.6)
				glRect(Panel["3"]["x0"],Panel["3"]["y0"],Panel["3"]["x1"], Panel["3"]["y1"])
				glRect(Panel["4"]["x0"],Panel["4"]["y0"],Panel["4"]["x1"], Panel["4"]["y1"])
				
				-- title
				glColor(0.8, 0.8, 1.0, 1)
				glText("Most damage dealt:", Panel["2"]["x0"]+200,Panel["2"]["y1"], 12, 'v')
				glText("Most damage received:", Panel["2"]["x0"]+200,Panel["2"]["y1"]-20, 12, 'v')
				glText("Total kills:", (Panel["3"]["x0"]+Panel["3"]["x1"])/2,Panel["3"]["y1"]+20, 14, 'vr')
				glText("Total losses:", (Panel["4"]["x0"]+Panel["4"]["x1"])/2,Panel["4"]["y1"]+20, 14, 'vr')
				
				--footnote
				glColor(0.8, 0.8, 1.0, 0.75)
				glText("Other: where there is no attacker (directly) involved (grey). Gaia team damage (if any) is shown as white.", Panel["2"]["x0"]+10,Panel["2"]["y0"]-60, 10, 'v')
				--max values
				glText(tostring(round(maxkilled/1000,1)).. " khp", Panel["2"]["x0"]+400,Panel["2"]["y1"], 12, 'v')
				glText(tostring(round(maxlost/1000,1)).. " khp", Panel["2"]["x0"]+400,Panel["2"]["y1"]-20, 12, 'v')
				
				glColor(1,1,1,1)
				
				
				if maxkiller then
					local r1,g1,b1 = GetTeamColor(maxkiller)
					glColor(r1,g1,b1, 1)
					local maxkillername = teamData[maxkiller].leader or "N/A"
					if teamData[maxkiller].isAI then maxkillername = "AI" end
					if maxkiller == gaiaID then maxkillername = "Team gaia" end
					
					glText("(" .. maxkillername .. ")", Panel["2"]["x0"]+460,Panel["2"]["y1"]+2, 12, 'v')
				end
				
				if maxloser then
					local r2,g2,b2 = GetTeamColor(maxloser)
					glColor(r2,g2,b2, 1)
					local maxlosername = teamData[maxloser].leader or "N/A"
					if teamData[maxloser].isAI then maxlosername = "AI" end
					if maxloser == gaiaID then maxlosername = "Team gaia" end
					
					glText("(" ..maxlosername .. ")", Panel["2"]["x0"]+460,Panel["2"]["y1"]-18, 12, 'v')
				end
				
				-- axes
				local y00 = Panel["3"]["y0"]
				local y100 = Panel["3"]["y1"]
				
				glColor(0.8, 0.8, 0.8, 1)
				glRect(Panel["3"]["x0"]-1,Panel["3"]["y0"],Panel["3"]["x0"], Panel["3"]["y1"]+10)
				glText("0", Panel["3"]["x0"]-10, y00, 10, 'vr')
				glText("max = " .. tostring(round(maxvalue/1000,1)) .. " khp", Panel["3"]["x0"]-10, y100, 10, 'vr')
				glRect(Panel["3"]["x0"]-5,y00,Panel["3"]["x1"],y00+1)
				glRect(Panel["3"]["x0"]-5,y100,Panel["3"]["x1"],y100+1)
				
				glRect(Panel["4"]["x0"]-1,Panel["4"]["y0"],Panel["4"]["x0"], Panel["4"]["y1"]+10)
				glText("0", Panel["4"]["x1"]+10, y00, 10, 'v')
				glText("max = " .. tostring(round(maxvalue/1000,1)) .. " khp", Panel["4"]["x1"]+10, y100, 10, 'v')
				--glText("max = " .. tostring(round(maxvalue/1000,1)) .. " khp", Panel["4"]["x0"]-10, y100, 10, 'vr')
				glRect(Panel["4"]["x0"]-5,y00,Panel["4"]["x1"],y00+1)
				glRect(Panel["4"]["x0"]-5,y100,Panel["4"]["x1"],y100+1)
							
				glColor(1,1,1,1)
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
							
							local leaderName = data.leader or "N/A"
							if data.isAI then leaderName = "AI" end 
							if tID == gaiaID then leaderName = "Gaia" end
							
							glColor(r, g, b, 1)
							glRect(x0, y0, x0 + bs, y0 + bs)
							glText(leaderName, x0 + bs + 10, y0, 12, 'b')
							
							--highlight
							if Button["legend"][tID]["mouse"] and not Button["legend"][tID]["On"] then
								glColor(0.8, 0.8, 0.2,1)
								glRect(x0-1,y0,x0,y0+bs)
								glRect(x0+bs,y0,x0+bs+1,y0+bs)
								glRect(x0,y0-1,x0+bs,y0)
								glRect(x0,y0+bs,x0+bs,y0+bs+1)
							end
							
							--selected
							if Button["legend"][tID]["On"] then
								glColor(1, 1, 1,1)
								glRect(x0-1,y0,x0,y0+bs)
								glRect(x0+bs,y0,x0+bs+1,y0+bs)
								glRect(x0,y0-1,x0+bs,y0)
								glRect(x0,y0+bs,x0+bs,y0+bs+1)
							end
												
							--values
							if Button["legend"][tID]["On"] then
								-- player name big label
								glColor(r, g, b, 1)
								glText(tID .. " - " .. leaderName, Panel["2"]["x0"]+280, Panel["2"]["y1"] - 79, 20, 'v')
								glColor(1, 1, 1, 1)
								glText("Player:", Panel["2"]["x0"]+200, Panel["2"]["y1"] - 80, 20, 'v')
								glText(tostring(round(teamTotals[tID]["killed"]/1000,1)) .. " khp", (Panel["3"]["x0"]+Panel["3"]["x1"])/2+10,Panel["3"]["y1"]+18, 14, 'v')
								glText(tostring(round(teamTotals[tID]["lost"]/1000,1)) .. " khp", (Panel["4"]["x0"]+Panel["4"]["x1"])/2+10,Panel["4"]["y1"]+18, 14, 'v')
								
								-- player matrix
								local w = 6 -- bar width
								--kills
								for eID, dmg in pairs(data.killedHP) do
									local value = dmg/maxvalue
									local r3,g3,b3 = GetTeamColor(eID)
									glColor(r3,g3,b3,1)
									glRect(Panel["3"]["x0"]+(w+2)*eID+5,y00,Panel["3"]["x0"]+(w+2)*eID+w+5,y00+value*(y100-y00))
								end
								--losses
								for eID, dmg in pairs(data.lostHP) do
									local value = dmg/maxvalue
									local r4,g4,b4 = GetTeamColor(eID)
									glColor(r4,g4,b4,1)
									glRect(Panel["4"]["x0"]+(w+2)*eID+5,y00,Panel["4"]["x0"]+(w+2)*eID+w+5,y00+value*(y100-y00))
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
									glText("Other", x1 + bs + 10, y1, 12, 'b')
								end
								
								glColor(0.82,0.79,0.79,1)
								glRect(Panel["4"]["x1"]-10-w,y00,Panel["4"]["x1"]-10,y00+dmgOther*(y100-y00))
								
								-- debris
								glColor(0,0,0,1) -- black
								glRect(Panel["4"]["x1"]-10-(2*w/3),y00,Panel["4"]["x1"]-10-(w/3),y01)
								if dmgDebris > 0 then
									local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther*maxvalue,1))*(bs+5) - bs
									glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
									
									glColor(0.82,0.79,0.79,1)
									glText("Debris", x1 + bs + 10, y10, 12, 'b')
									glRect(x1, y10, x1 + bs/3, y10 + bs)
									glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								end
								
								--ground
								glColor(0,1,0,1) -- green
								glRect(Panel["4"]["x1"]-10-(2*w/3),y01,Panel["4"]["x1"]-10-(w/3),y02)
								if dmgGround > 0 then
									local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther,1)+min(dmgDebris,1))*(bs+5) - bs
									glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
									
									glColor(0.82,0.79,0.79,1)
									glText("Ground", x1 + bs + 10, y10, 12, 'b')
									glRect(x1, y10, x1 + bs/3, y10 + bs)
									glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								end
								
								--object
								glColor(0.63,0.13,0.94,1) -- purple
								glRect(Panel["4"]["x1"]-10-(2*w/3),y02,Panel["4"]["x1"]-10-(w/3),y03)
								if dmgObject > 0 then
									local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther,1)+min(dmgDebris,1)+min(dmgGround,1))*(bs+5) - bs
									glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
									
									glColor(0.82,0.79,0.79,1)
									glText("Object", x1 + bs + 10, y10, 12, 'b')
									glRect(x1, y10, x1 + bs/3, y10 + bs)
									glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								end
								
								--fire
								glColor(1,0,0,1) --red
								glRect(Panel["4"]["x1"]-10-(2*w/3),y03,Panel["4"]["x1"]-10-(w/3),y04)
								if dmgFire > 0 then
									local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther,1)+min(dmgDebris,1)+min(dmgGround,1)+min(dmgObject,1))*(bs+5) - bs
									glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
									
									glColor(0.82,0.79,0.79,1)
									glText("Fire", x1 + bs + 10, y10, 12, 'b')
									glRect(x1, y10, x1 + bs/3, y10 + bs)
									glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								end
								
								--water
								glColor(0,0,1,1) --blue
								glRect(Panel["4"]["x1"]-10-(2*w/3),y04,Panel["4"]["x1"]-10-(w/3),y05)
								if dmgWater > 0 then
									local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther,1)+min(dmgDebris,1)+min(dmgGround,1)+min(dmgObject,1)+min(dmgFire,1))*(bs+5) - bs
									glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
									
									glColor(0.82,0.79,0.79,1)
									glText("Water", x1 + bs + 10, y10, 12, 'b')
									glRect(x1, y10, x1 + bs/3, y10 + bs)
									glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								end
								
								--kill
								glColor(0.63,0.32,0.18,1) --brown
								glRect(Panel["4"]["x1"]-10-(2*w/3),y05,Panel["4"]["x1"]-10-(w/3),y06)
								if dmgKill > 0 then
									local y10 = Panel["2"]["y1"] - (n+1+min(dmgOther,1)+min(dmgDebris,1)+min(dmgGround,1)+min(dmgObject,1)+min(dmgFire,1)+min(dmgWater,1))*(bs+5) - bs
									glRect(x1+bs/3, y10, x1 + 2*bs/3, y10 + bs)
									
									glColor(0.82,0.79,0.79,1)
									glText("Collateral", x1 + bs + 10, y10, 12, 'b')
									glRect(x1, y10, x1 + bs/3, y10 + bs)
									glRect(x1+2*bs/3, y10, x1 + bs, y10 + bs)
								end
							end
						end
					end
				end
			elseif Button["heroes"]["On"] then
			
				--panel
				glColor(0.3, 0.2, 0.2, 0.5)
				glRect(Panel["5"]["x0"],Panel["5"]["y0"],Panel["5"]["x1"], Panel["5"]["y1"])
				
				--title
				glColor(0.8, 0.8, 1.0, 1)
				glText("Heroes in victory", (Panel["5"]["x0"]+Panel["5"]["x1"])/2,Panel["5"]["y1"] - 20, 16, 'vc')
				
				if heroUnits and heroUnits[1] and heroUnits[1][1] then
					glColor(1, 1, 1, 1)
					glText("#",Panel["5"]["x0"]+20, Panel["5"]["y1"]-90, 12, 'd')
					glText("Unit (owner)",Panel["5"]["x0"]+50, Panel["5"]["y1"]-90, 12, 'd')
					glText("Confirmed kills",Panel["5"]["x1"]-100, Panel["5"]["y1"]-90, 12, 'dr')
					glText("Age",Panel["5"]["x1"]-50, Panel["5"]["y1"]-90, 12, 'dr')
					glRect(Panel["5"]["x0"]+20,Panel["5"]["y1"]-94,Panel["5"]["x1"]-50,Panel["5"]["y1"]-95)
					
					glColor(0.8, 0.8, 1.0, 1)
					for i, unitdata in sipairs (heroUnits) do
						local name = unitdata[1]
						local kills = unitdata[2]
						local birth = unitdata[3]
						local age = unitdata[4]
						local teamID = unitdata[5]
						local r,g,b = GetTeamColor(teamID)
						local _,leaderID,_,isAI = GetTeamInfo(teamID)
						local leaderName
						if leaderID then
							leaderName	= GetPlayerInfo(leaderID) or "N/A"
						else
							leaderName = "N/A"
						end
						
						if isAI then leaderName = "AI" end	
						if teamID == gaiaID then leaderName = "Gaia" end
						
						glText(tostring(i)..".",Panel["5"]["x0"]+20, Panel["5"]["y1"] - i * 3 * bs - 90, 12, 'd')
						glText(name,Panel["5"]["x0"]+50, Panel["5"]["y1"] - i * 3 * bs - 90, 12, 'd')
						glColor(r, g, b, 1)
						glText("("..leaderName..")",Panel["5"]["x0"] + 12* gl.GetTextWidth(name) + 60, Panel["5"]["y1"] - i * 3 * bs - 90, 12, 'd')
						glColor(0.8, 0.8, 1.0, 1)
						glText(tostring(kills),Panel["5"]["x1"]-100, Panel["5"]["y1"]- i * 3 * bs - 90, 12, 'dr')
						glText(tostring(age).." min",Panel["5"]["x1"]-50, Panel["5"]["y1"]- i * 3 * bs - 90, 12, 'dr')
					end
				else
					glText("(No awards)",(Panel["5"]["x0"]+Panel["5"]["x1"])/2, Panel["5"]["y1"]-90, 12, 'dc')
				end
		
			elseif Button["lost"]["On"] then
				
				--panel
				glColor(0.3, 0.2, 0.2, 0.5)
				glRect(Panel["5"]["x0"],Panel["5"]["y0"],Panel["5"]["x1"], Panel["5"]["y1"])
				
				--title
				glColor(0.8, 0.8, 1.0, 1)
				glText("Lost in service", (Panel["5"]["x0"]+Panel["5"]["x1"])/2,Panel["5"]["y1"] - 20, 16, 'vc')
				
				if lostUnits and lostUnits[1] and lostUnits[1][1] then
					glColor(1, 1, 1, 1)
					glText("#",Panel["5"]["x0"]+20, Panel["5"]["y1"]-90, 12, 'd')
					glText("Unit (owner)",Panel["5"]["x0"]+50, Panel["5"]["y1"]-90, 12, 'd')
					glText("Confirmed kills",Panel["5"]["x1"]-150, Panel["5"]["y1"]-90, 12, 'dr')
					glText("Birth",Panel["5"]["x1"]-100, Panel["5"]["y1"]-90, 12, 'dr')
					glText("Death",Panel["5"]["x1"]-50, Panel["5"]["y1"]-90, 12, 'dr')
					glRect(Panel["5"]["x0"]+20,Panel["5"]["y1"]-94,Panel["5"]["x1"]-50,Panel["5"]["y1"]-95)
					
					glColor(0.8, 0.8, 1.0, 1)
					for i, unitdata in sipairs (lostUnits) do
						local name = unitdata[1]
						local kills = unitdata[2]
						local birth = unitdata[3]
						local death = unitdata[4]
						local teamID = unitdata[5]
						local r,g,b = GetTeamColor(teamID)
						local _,leaderID,_,isAI = GetTeamInfo(teamID)
						local leaderName
						if leaderID then
							leaderName	= GetPlayerInfo(leaderID) or "N/A"
						else
							leaderName = "N/A"
						end
						
						if isAI then leaderName = "AI" end	
						if teamID == gaiaID then leaderName = "Gaia" end
						
						glText(tostring(i)..".",Panel["5"]["x0"]+20, Panel["5"]["y1"] - i * 3 * bs - 90, 12, 'd')
						glText(name,Panel["5"]["x0"]+50, Panel["5"]["y1"] - i * 3 * bs - 90, 12, 'd')
						glColor(r, g, b, 1)
						glText("("..leaderName..")",Panel["5"]["x0"] + 12* gl.GetTextWidth(name) + 60, Panel["5"]["y1"] - i * 3 * bs - 90, 12, 'd')
						glColor(0.8, 0.8, 1.0, 1)
						glText(tostring(kills),Panel["5"]["x1"]-150, Panel["5"]["y1"]- i * 3 * bs - 90, 12, 'dr')
						glText(tostring(birth).." min",Panel["5"]["x1"]-100, Panel["5"]["y1"]- i * 3 * bs - 90, 12, 'dr')
						glText(tostring(death).." min",Panel["5"]["x1"]-50, Panel["5"]["y1"]- i * 3 * bs - 90, 12, 'dr')
					end
				else
					glText("(No awards)",(Panel["5"]["x0"]+Panel["5"]["x1"])/2, Panel["5"]["y1"]-90, 12, 'dc')
				end
			end
		end
	end
	
	function gadget:MousePress(mx, my, mButton)
		if drawWindow then
			if (mButton == 2 or mButton == 3) and mx < Panel["back"]["x1"] then
				if mx >= Panel["back"]["x0"] and my >= Panel["back"]["y0"] and my < Panel["back"]["y1"] then
					-- Dragging
					return true
				end
			elseif mButton == 1 then								
				if IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
					Spring.SendCommands("quitforce")
					gadgetHandler:RemoveGadget()
					return true
				elseif IsOnButton(mx,my,Button["proceed"]["x0"],Button["proceed"]["y0"],Button["proceed"]["x1"],Button["proceed"]["y1"]) then
					Spring.SendCommands('endgraph 1')
					gadgetHandler:RemoveGadget()
					return true
				elseif IsOnButton(mx,my,Button["influence"]["x0"],Button["influence"]["y0"],Button["influence"]["x1"],Button["influence"]["y1"]) then
					Button["influence"]["On"] = true
					Button["matrix"]["On"] = false
					Button["heroes"]["On"] = false
					Button["lost"]["On"] = false
				elseif IsOnButton(mx,my,Button["matrix"]["x0"],Button["matrix"]["y0"],Button["matrix"]["x1"],Button["matrix"]["y1"]) then
					Button["matrix"]["On"] = true
					Button["influence"]["On"] = false
					Button["heroes"]["On"] = false
					Button["lost"]["On"] = false
				elseif IsOnButton(mx,my,Button["heroes"]["x0"],Button["heroes"]["y0"],Button["heroes"]["x1"],Button["heroes"]["y1"]) then
					Button["heroes"]["On"] = true
					Button["influence"]["On"] = false
					Button["matrix"]["On"] = false
					Button["lost"]["On"] = false
				elseif IsOnButton(mx,my,Button["lost"]["x0"],Button["lost"]["y0"],Button["lost"]["x1"],Button["lost"]["y1"]) then
					Button["lost"]["On"] = true
					Button["influence"]["On"] = false
					Button["matrix"]["On"] = false
					Button["heroes"]["On"] = false
				else
					for _, lbutton in pairs (Button["legend"]) do
						if IsOnButton(mx,my,lbutton["x0"],lbutton["y0"],lbutton["x1"],lbutton["y1"]) then
							for _,l2button in pairs (Button["legend"]) do
								l2button["On"] = false
							end
							lbutton["On"] = true
						end
					end
				end
			end
		end
	end
			
	function gadget:MouseMove(mx, my, dx, dy, mButton)
		if drawWindow then
			-- Dragging
			if mButton == 2 or mButton == 3 then
				px = max(0, min(px+dx, vsx-sizex))	--prevent moving off screen
				py = max(0, min(py+dy, vsy-sizey))
			end
			initButtons()
		end
	end
	
	function gadget:IsAbove(mx,my)
		if drawWindow then
			Button["exit"]["mouse"] = false
			Button["proceed"]["mouse"] = false
			Button["influence"]["mouse"] = false
			Button["heroes"]["mouse"] = false
			Button["lost"]["mouse"] = false
			Button["matrix"]["mouse"] = false
				
			for _,lbutton in pairs (Button["legend"]) do
				lbutton["mouse"] = false
			end
			
			if IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then		
				Button["exit"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["proceed"]["x0"],Button["proceed"]["y0"],Button["proceed"]["x1"],Button["proceed"]["y1"]) then
				Button["proceed"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["influence"]["x0"],Button["influence"]["y0"],Button["influence"]["x1"],Button["influence"]["y1"]) then
				Button["influence"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["matrix"]["x0"],Button["matrix"]["y0"],Button["matrix"]["x1"],Button["matrix"]["y1"]) then
				Button["matrix"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["heroes"]["x0"],Button["heroes"]["y0"],Button["heroes"]["x1"],Button["heroes"]["y1"]) then
				Button["heroes"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["lost"]["x0"],Button["lost"]["y0"],Button["lost"]["x1"],Button["lost"]["y1"]) then
				Button["lost"]["mouse"] = true
			else
				for _, lbutton in pairs (Button["legend"]) do
					if IsOnButton(mx,my,lbutton["x0"],lbutton["y0"],lbutton["x1"],lbutton["y1"]) then
						lbutton["mouse"] = true
					end
				end
			end
		end
	end
	
	function gadget:ShutDown()
		Spring.SendCommands('endgraph 1')
		
		gadgetHandler:RemoveSyncAction("RecieveEndStats")
		gadgetHandler:RemoveSyncAction("teamData")
		gadgetHandler:RemoveSyncAction("heroUnits")
		gadgetHandler:RemoveSyncAction("lostUnits")		
	end
	
end