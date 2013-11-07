
function gadget:GetInfo()
  return {
    name      = "game_stats",
    desc      = "Game statistics and awards",
	version   = "1.0",
    author    = "Jools",
    date      = "Sep,2013",
    license   = "GNU GPL, v2 or later",
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
	
	local function round(num, idp)
		return string.format("%." .. (idp or 0) .. "f", num)
	end
	
	function gadget:Initialize()
	
		mapX = Game.mapSizeX
		mapZ = Game.mapSizeZ

		for i, aID in ipairs (GetAllyTeamList()) do
			local gaiaID = Spring.GetGaiaTeamID()				
			local gaiaAllyID = select(6, GetTeamInfo(gaiaID))
			
			if aID ~= gaiaAllyID then
				allyData[i] = {}
			end
			
			for i,tID in ipairs(GetTeamList(aID)) do
				
				if tID ~= gaiaID then
					teamData[tID] = {}
					local _,leaderID,isDead,_,side 	= GetTeamInfo(tID)
					
					if leaderID then
						local leaderName,active,spectator	= GetPlayerInfo(leaderID)				
						teamData[tID]['ally'] = aID+1
						teamData[tID]['side'] = side
						teamData[tID]['alive'] = not isDead
						teamData[tID]['hasCommander'] = false
						teamData[tID]['leader'] = leaderName
						teamData[tID]['active'] = active
						teamData[tID]['spec'] = spectator
						teamData[tID]['killcount'] = {}
						teamData[tID]['killedHP'] = {}
						teamData[tID]['deathcount'] = {}
						teamData[tID]['lostHP'] = {}
						teamData[tID]['firepower'] = {}
						teamData[tID]['buildpower'] = {}
					end
				end
			end
		end
	end
	
	function updateTeam(tID)
	
		local _,_,_,minc 					= GetTeamResources(pID,"metal")
		local _,_,_,einc 					= GetTeamResources(pID,"energy")
		local unitCount 					= GetTeamUnitCount(pID)
		
	end
	
	function isUnitComplete(unitID)
		if unitID then
			local _,_,_,_,buildProgress = GetUnitHealth(UnitID)
		
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
		local gaiaID = Spring.GetGaiaTeamID()				
		local gaiaAllyID = select(6, GetTeamInfo(gaiaID))
		local step = 512
		for x = 1, mapX, step do
			for z = 1, mapZ, step do
				chunks = chunks +1
				local y = GetGroundHeight(x,z)
				for i,aID in ipairs (allyList) do
					if aID ~= gaiaAllyID then
						if not zoc[i] then zoc[i] = 0 end
						if IsPosInLos(x,y,z,aID) then zoc[i] = zoc[i] + 1 end
					end
				end
			end
		end
		--Echo("Chunks = ", chunks)
		if chunks > 0 then
			for i, aID in ipairs (allyData) do
				allyData[i][#allyData[i]+1] = zoc[i]/chunks
			end
		end
	end
	
	function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	
		if isUnitComplete(UnitID) and attackerTeamID ~=  teamID and not AreTeamsAllied(attackerTeamID,teamID) then
			-- code
		end
	end
	
	function gadget:GameFrame(frame)
		if frame%300 == 0 then
			readZoneOfControls()
		end
	end
	
	function gadget:GameOver()
		for i, aData in ipairs (allyData) do
			allyData[i]["n"] = #allyData[i]
		end
		
		local dataID = "influence"
		for i, aID in ipairs (allyData) do
			for timeID, ZOC in pairs(allyData[i]) do
				SendToUnsynced("RecieveEndStats", dataID, i, timeID, ZOC)
			end
		end
	end
	
else
	-------------------
	-- UNSYNCED PART --
	-------------------
	
	local teamList 						= Spring.GetTeamList()
	local myTeamID 						= Spring.GetMyTeamID()
	local GetTeamList					= Spring.GetTeamList
	local GetTeamColor					= Spring.GetTeamColor
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
	
	local function initButtons()
		
		local L1 = 205	-- proceed
		local L2 = 45	-- exit
		local L3 = 80	-- influence
		local L4 = 130	-- heroes
		local L5 = 115 	-- lost
	
		local bs = 10 	-- button space
		Panel["back"]["x0"] 	= px
		Panel["back"]["y0"] 	= py
		Panel["back"]["x1"] 	= px + sizex
		Panel["back"]["y1"] 	= py + sizey
		
		Panel["1"]["x0"] 		= px + 100
		Panel["1"]["y0"] 		= py + 80
		Panel["1"]["x1"] 		= px + sizex - 100
		Panel["1"]["y1"] 		= py + sizey - 100
		
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
		
		Button["heroes"]["x0"]	= Button["influence"]["x1"] + bs
		Button["heroes"]["y0"]	= Panel["back"]["y1"] - 40
		Button["heroes"]["x1"]	= Button["heroes"]["x0"] + L4
		Button["heroes"]["y1"]	= Panel["back"]["y1"] - 10
		
		Button["lost"]["x0"]	= Button["heroes"]["x1"] + bs
		Button["lost"]["y0"]	= Panel["back"]["y1"] - 40
		Button["lost"]["x1"]	= Button["lost"]["x0"] + L5
		Button["lost"]["y1"]	= Panel["back"]["y1"] - 10
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
	
	function gadget:Initialize()
	--register actions to SendToUnsynced messages
		gadgetHandler:AddSyncAction("RecieveEndStats", RecieveEndStats)
		
		Button["exit"] 				= {}
		Button["proceed"] 			= {}
		Button["influence"]			= {}
		Button["influence"]["On"] 	= true
		Button["heroes"]			= {}
		Button["lost"]				= {}
		Panel["back"] 				= {}
		Panel["back"]["On"]			= false
		Panel["1"] 					= {}
		Panel["2"] 					= {}
		Panel["3"] 					= {}
		Panel["4"] 					= {}
		initButtons()
		
	end	
	
	function RecieveEndStats(_, dataID, allyNumber, timeID, value)	
		drawWindow = true
						
		if dataID == "influence" then
			if timeID ~= "n" then
				if not allyData[allyNumber] then allyData[allyNumber] = {} end
				allyData[allyNumber][#allyData[allyNumber]+1] = {timeID,value}
			else
				nData[allyNumber] = value
			end
		end
		
		if nData[allyNumber] and #allyData[allyNumber] >= nData[allyNumber] then
			for i, data in pairs(allyData[allyNumber]) do
			end
		end
		
		if nData[allyNumber] and #allyData[allyNumber] >= nData[allyNumber] then
			table.sort(allyData[allyNumber],sortBySmallest)
		end
		
		--don't show graph
		Spring.SendCommands('endgraph 0')
		Button["influence"]["On"] = true
		
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
			glColor(0, 0, 0, 0.3)
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
			elseif Button["heroes"]["mouse"] and not Button["heroes"]["On"] then
				glRect(Button["heroes"]["x0"],Button["heroes"]["y0"], Button["heroes"]["x1"], Button["heroes"]["y1"])
			elseif Button["lost"]["mouse"] and not Button["lost"]["On"] then
				glRect(Button["lost"]["x0"],Button["lost"]["y0"], Button["lost"]["x1"], Button["lost"]["y1"])
			end
			-- button selected
			glColor(0.8, 0.8, 0.8, 0.5)
			if Button["influence"]["On"] then
				glRect(Button["influence"]["x0"],Button["influence"]["y0"], Button["influence"]["x1"], Button["influence"]["y1"])
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
				glColor(0.8, 0.8, 1.0, 0.5)
				glRect(Panel["1"]["x0"],Panel["1"]["y0"],Panel["1"]["x1"], Panel["1"]["y1"])
				
				-- axes
				local y0 = Panel["1"]["y0"]
				local y100 = Panel["1"]["y1"]
				local y50 = Panel["1"]["y0"] + 0.50 * (Panel["1"]["y1"]-Panel["1"]["y0"])
				local y25 = Panel["1"]["y0"] + 0.25 * (Panel["1"]["y1"]-Panel["1"]["y0"])
				local y75 = Panel["1"]["y0"] + 0.75 * (Panel["1"]["y1"]-Panel["1"]["y0"])
				glColor(0.2, 0.2, 0.2, 1)
				glRect(Panel["1"]["x0"]-1,Panel["1"]["y0"],Panel["1"]["x0"], Panel["1"]["y1"]+10)
				glText("Influence", Panel["1"]["x0"]-30,Panel["1"]["y1"] + 20, 14, 'x')
				glText("0 %", Panel["1"]["x0"]-10, y0, 10, 'vr')
				glText("50 %", Panel["1"]["x0"]-10, y50, 10, 'vr')
				glText("100 %", Panel["1"]["x0"]-10, y100, 10, 'vr')
				glText("Time", Panel["1"]["x1"]+10,Panel["1"]["y0"]-2, 14, 'x')
				glRect(Panel["1"]["x0"]-5,y0,Panel["1"]["x1"],y0+1)
				glRect(Panel["1"]["x0"]-5,y100,Panel["1"]["x1"],y100+1)
				glRect(Panel["1"]["x0"]-5,y50,Panel["1"]["x1"],y50+1)
				glColor(0.6, 0.6, 0.6, 1)
				glRect(Panel["1"]["x0"]-5,y25,Panel["1"]["x1"],y25+1)
				glRect(Panel["1"]["x0"]-5,y75,Panel["1"]["x1"],y75+1)
				
				-- values
				local r,g,b
				local n = #allyData[1]
				
				local x0 		= Panel["1"]["x0"]
				local xspace 	= Panel["1"]["x1"]-Panel["1"]["x0"]
				local yspace	= y100-y0
				
				local function DrawLine(array, i)
					local xscale
					if nData[i] <= 1 then
						xscale = 1
					else
						xscale = 1/(nData[i]-1)
					end
					
					for _,data in ipairs (array) do
						local x = data[1]
						local y = data[2]
						glVertex(x0+(x-1)*xspace*xscale, y0+y*yspace)
					end
				end
				
				local function DrawLineShadow(array, i)
					local xscale
					if nData[i] <= 1 then
						xscale = 1
					else
						xscale = 1/(nData[i]-1)
					end
					
					for _,data in ipairs (array) do
						local x = data[1]
						local y = data[2]
						glVertex(x0+(x-1)*xspace*xscale, y0+y*yspace-1)
					end
				end
				glLineStipple(false)
				for i, _ in ipairs (allyData) do
					local teamID1 = GetTeamList(i-1)[1]
					r,g,b = GetTeamColor(teamID1)
					glColor(r, g, b, 1)
					glLineWidth (2.0)
					gl.BeginEnd(GL.LINE_STRIP, DrawLine,allyData[i],i)
					glColor(r*0.75, g*0.75, b*0.75,1)					
					glLineWidth (1.0)
					gl.BeginEnd(GL.LINE_STRIP, DrawLineShadow,allyData[i],i)
				end
				glColor(1, 1, 1, 1)
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
					Button["heroes"]["On"] = false
					Button["lost"]["On"] = false
				elseif IsOnButton(mx,my,Button["heroes"]["x0"],Button["heroes"]["y0"],Button["heroes"]["x1"],Button["heroes"]["y1"]) then
					Button["heroes"]["On"] = true
					Button["influence"]["On"] = false
					Button["lost"]["On"] = false
				elseif IsOnButton(mx,my,Button["lost"]["x0"],Button["lost"]["y0"],Button["lost"]["x1"],Button["lost"]["y1"]) then
					Button["lost"]["On"] = true
					Button["influence"]["On"] = false
					Button["heroes"]["On"] = false
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
				
			if IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then		
				Button["exit"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["proceed"]["x0"],Button["proceed"]["y0"],Button["proceed"]["x1"],Button["proceed"]["y1"]) then
				Button["proceed"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["influence"]["x0"],Button["influence"]["y0"],Button["influence"]["x1"],Button["influence"]["y1"]) then
				Button["influence"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["heroes"]["x0"],Button["heroes"]["y0"],Button["heroes"]["x1"],Button["heroes"]["y1"]) then
				Button["heroes"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["lost"]["x0"],Button["lost"]["y0"],Button["lost"]["x1"],Button["lost"]["y1"]) then
				Button["lost"]["mouse"] = true
			end
		end
	end
	
	function gadget:ShutDown()
		Spring.SendCommands('endgraph 1')
	end
	
end