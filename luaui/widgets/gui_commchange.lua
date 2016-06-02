
function widget:GetInfo()
	return {
		name      = 'Commander Change',
		desc      = 'Adds buttons to choose commander',
		version   = "1.31",
		author    = 'Niobium, Jools',
		date      = 'Jan, 2014',
		license   = 'GNU GPL v2',
		layer     = -9,
		enabled   = true,
	}
end
-- Bugfixes:
-- * Now dont filter out spectators from playerslist on the left; add code to correctly hide on F5
--
-- * Fixed a bug caused by change in ready state message by spring: it updated from "missing" to "notready" and that's why widget would never catch 
-- correct state when user has marked but not readied up. Now colour code is grey and not red when correct state is not recognised.
--

------------
-- IMAGES -- 
------------

--commander selection
local img 						= {}				
	img["ComAA"] 				= "LuaUI/Images/commchange/ComAA.png" -- arm auto
	img["ComAM"] 				= "LuaUI/Images/commchange/ComAM.png" -- arm manual
	img["ComAAD"] 				= "LuaUI/Images/commchange/ComAAD.png" -- arm auto disabled
	img["ComAMD"] 				= "LuaUI/Images/commchange/ComAMD.png" -- arm manual disabled
	img["ComCA"]				= "LuaUI/Images/commchange/ComCA.png" -- core auto
	img["ComCM"]			 	= "LuaUI/Images/commchange/ComCM.png"
	img["ComCAD"] 				= "LuaUI/Images/commchange/ComCAD.png" -- core auto disabled
	img["ComCMD"] 				= "LuaUI/Images/commchange/ComCMD.png"
	img["ComLM"] 				= "LuaUI/Images/commchange/ComLM.png"
	img["ComLMD"] 				= "LuaUI/Images/commchange/ComLMD.png"
	img["ComLA"] 				= "LuaUI/Images/commchange/ComLA.png"
	img["ComLAD"] 				= "LuaUI/Images/commchange/ComLAD.png"
	img["ComGM"] 				= "LuaUI/Images/commchange/ComGM.png"
	img["ComGMD"] 				= "LuaUI/Images/commchange/ComGMD.png"
	img["ComGA"] 				= "LuaUI/Images/commchange/ComGA.png"
	img["ComGAD"] 				= "LuaUI/Images/commchange/ComGAD.png"
	img["ComTM"] 				= "LuaUI/Images/commchange/ComTM.png"
	img["ComTMD"] 				= "LuaUI/Images/commchange/ComTMD.png"
	img["ComTA"] 				= "LuaUI/Images/commchange/ComTA.png"
	img["ComTAD"] 				= "LuaUI/Images/commchange/ComTAD.png"

	--countdown
	img["cnt3"] 				= "LuaUI/Images/commchange/3-cnt.png"
	img["cnt2"] 				= "LuaUI/Images/commchange/2-cnt.png"
	img["cnt1"] 				= "LuaUI/Images/commchange/1-cnt.png"
	img["cnt0"] 				= "LuaUI/Images/commchange/0-cnt.png"

	--faction emblems
	img["arm"] 					= "LuaUI/Images/commchange/arm.png"
	img["core"] 				= "LuaUI/Images/commchange/core.png"
	img["lost"] 				= "LuaUI/Images/commchange/lost.png"
	img["guardian"]				= "LuaUI/Images/commchange/guardian.png"
	img["talon"]				= "LuaUI/Images/commchange/talon.png"

	--other
	img["duck"]					= "LuaUI/Images/commchange/duck.png"

-- commanders
local commanderID				= {}
commanderID["arm_automatic"] 	= UnitDefNames["arm_commander"].id
commanderID["arm_manual"] 		= UnitDefNames["arm_u0commander"].id
commanderID["core_automatic"]	= UnitDefNames["core_commander"].id
commanderID["core_manual"] 		= UnitDefNames["core_u0commander"].id
commanderID["lost_automatic"]	= (UnitDefNames["lost_commander"] or {}).id
commanderID["lost_manual"] 		= (UnitDefNames["lost_u0commander"] or {}).id
commanderID["guardian_automatic"]	= (UnitDefNames["guardian_commander"] or {}).id
commanderID["guardian_manual"] 		= (UnitDefNames["guardian_u0commander"] or {}).id
commanderID["talon_automatic"]	= (UnitDefNames["talon_commander"] or {}).id
commanderID["talon_manual"] 		= (UnitDefNames["talon_u0commander"] or {}).id


-- sound
local bell = 'sounds/gui/bell.ogg'
local beep = 'sounds/unit/robobeep.wav'
local tock = 'sounds/gui/ticktock.wav'
local button = 'sounds/gui/button9.wav'
local button1 = 'sounds/gui/button1.wav'
local button2 = 'sounds/gui/button2.wav'
local button3 = 'sounds/gui/buttn01.wav'
local cancel = 'sounds/unit/cancel2.wav'

local duckSounds =	 {
	[1] = 'sounds/critters/duckcall1.wav',
	[2] = 'sounds/critters/duckcall2.wav',
	[3] = 'sounds/critters/duckcall3.wav',
	[4] = 'sounds/critters/duckcry1.wav',
	[5] = 'sounds/critters/duckcry2.wav',
	}
	
--------------------------------------------------------------------------------
-- Buttons
--------------------------------------------------------------------------------

local Button = {}
Button["arm"] = {}
Button["core"] = {}
Button["lost"] = {}
Button["guardian"] = {}
Button["talon"] = {}
Button["ready"] = {}
Button["info"] = {}
Button["infopanel"] = {}
Button["auto"] = {}
Button["manual"] = {}
Button["infolabel"] = {}
Button["exit"] = {}
Button["speclabel"] = {}
Button["duck"] = {}
Button["specinfo"] = {}

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------
local vsx, vsy 								= gl.GetViewSizes()
local scale
local px, py 								= 300, 300
local SIZEX, SIZEY  						= 480, 200 -- initial value before scaling
local mid 									= px + SIZEX/2
local sizex, sizey							-- values used after rescaling
local th 									= 16 -- text height for buttons
local th2 									= 11 -- text height for body text
local th3 									= 20 -- text height for player names
local n 									= 0 -- amount of players
local mySide, myType	
local myState 								= 0
local gameState 							= 0
local gameStarted							= false
local cntDown 								= -1
local lastCount
local playerStates							= {}
local markedStates 							= {}
local APLStates								= {} -- secondary source of player states, used by adv.playerslist
local readyStates							= {}
local lastStartID
local strInfo							
local infoOn 								= false
local teamList								= Spring.GetTeamList()
local playerList 							= Spring.GetPlayerList()
local myTeamID 								= Spring.GetMyTeamID()
--gamestates
local CHOOSE,WAITING,COUNTDOWN,ERROR		= 0,1,2,-1
local gameOver								= false
-- local player states
local PRESENT,MARKED,OTHER,READY,MISSING 	= 0,1,2,3,-1

--font
local myFont	 							= gl.LoadFont("FreeSansBold.otf",th3, 1.9, 40)
local myFontHuge							= gl.LoadFont("FreeSansBold.otf",60, 1.9, 40)
local bgcorner								= "luaui/images/bgcorner.png"
local hasSentStartMsg	 					= false
local isTLL									= false
local isGOK									= false
local isTAL									= false

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------

local Echo 							= Spring.Echo
local newSide		  				= {}
	
--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------
local cWhite				= {1, 1, 1, 1}
local cGrey					= {0.8, 0.8, 0.8, 1}
local cRank					= {0.4,0.4,0.4,1}
local cLight				= {0.8, 0.8, 0.2, 0.5}
local cUnfocus				= {0.8, 0.8, 0.8, 0.4}
local cDark					= {0, 0, 0, 0.4}
local cBlack				= {0, 0, 0, 1}
local cAlpha				= {1, 1, 1, 0.5}
local cCount				= {0.8, 0.8, 1, 1}

--------------------------------------------------------------------------------
-- Local functions
--------------------------------------------------------------------------------
local function QuadVerts(x, y, z, r)
	gl.TexCoord(0, 0); gl.Vertex(x - r, y, z - r)
	gl.TexCoord(1, 0); gl.Vertex(x + r, y, z - r)
	gl.TexCoord(1, 1); gl.Vertex(x + r, y, z + r)
	gl.TexCoord(0, 1); gl.Vertex(x - r, y, z + r)
end

local function initButtons()
	local nb = 4 --arm+core + ready + info
	nb = isTAL and nb + 1 or nb
	nb = isTLL and nb + 1 or nb
	nb = isGOK and nb + 1 or nb
	
	mid = px + sizex/2
	Button["arm"]["x0"] = px
	Button["arm"]["x1"] = Button["arm"]["x0"] + sizex/nb
	Button["arm"]["y0"] = py  + sizey - 24
	Button["arm"]["y1"] = py  + sizey
	
	Button["core"]["x0"] = Button["arm"]["x1"]
	Button["core"]["x1"] = Button["core"]["x0"] + sizex/nb
	Button["core"]["y0"] = py  + sizey - 24
	Button["core"]["y1"] = py  + sizey
	
	Button["lost"]["x0"] = Button["core"]["x1"]
	Button["lost"]["x1"] = Button["lost"]["x0"] + sizex/nb
	Button["lost"]["y0"] = py  + sizey - 24
	Button["lost"]["y1"] = py  + sizey
	
	Button["guardian"]["x0"] = isTLL and Button["lost"]["x1"] or Button["core"]["x1"]
	Button["guardian"]["x1"] = Button["guardian"]["x0"] + sizex/nb
	Button["guardian"]["y0"] = py  + sizey - 24
	Button["guardian"]["y1"] = py  + sizey
	
	Button["talon"]["x0"] = isGOK and Button["guardian"]["x1"] or isTLL and Button["lost"]["x1"] or Button["core"]["x1"]
	Button["talon"]["x1"] = Button["talon"]["x0"] + sizex/nb
	Button["talon"]["y0"] = py  + sizey - 24
	Button["talon"]["y1"] = py  + sizey
	
	Button["ready"]["x0"] = (isTAL and Button["talon"]["x1"]) or (isGOK and Button["guardian"]["x1"]) or (isTLL and Button["lost"]["x1"]) or Button["core"]["x1"]
	Button["ready"]["x1"] = Button["ready"]["x0"] + sizex/nb
	Button["ready"]["y0"] = py  + sizey - 24
	Button["ready"]["y1"] = py  + sizey
	
	Button["auto"]["x0"] = px + 10
	Button["auto"]["x1"] = mid - 10
	Button["auto"]["y0"] = py  + 24
	Button["auto"]["y1"] = py  + sizey - 34
	
	Button["manual"]["x0"] = mid + 10
	Button["manual"]["x1"] = px + sizex - 12
	Button["manual"]["y0"] = py  + 24
	Button["manual"]["y1"] = py  + sizey - 34
	
	Button["info"]["x0"] = Button["ready"]["x1"]
	Button["info"]["x1"] = px + sizex
	Button["info"]["y0"] = py  + sizey - 24
	Button["info"]["y1"] = py  + sizey
	
	Button["infopanel"]["x0"] = px + sizex
	Button["infopanel"]["x1"] = px + sizex + 400 * scale
	Button["infopanel"]["y0"] = py
	Button["infopanel"]["y1"] = py + sizey
	
	Button["infolabel"]["x0"] = px
	Button["infolabel"]["x1"] = px + sizex - 30
	Button["infolabel"]["y0"] = py + sizey
	Button["infolabel"]["y1"] = py + sizey + 30
	
	Button["exit"]["x0"] = px + sizex - 30
	Button["exit"]["x1"] = px + sizex
	Button["exit"]["y0"] = py + sizey
	Button["exit"]["y1"] = py + sizey + 30
	
	Button["speclabel"]["x0"] = px  + 30
	Button["speclabel"]["x1"] = px  + sizex - 30
	Button["speclabel"]["y0"] = py  + sizey
	Button["speclabel"]["y1"] = py  + sizey + 30
	
	Button["duck"]["x0"] = px
	Button["duck"]["x1"] = px + 30
	Button["duck"]["y0"] = py + sizey
	Button["duck"]["y1"] = py + sizey + 30
	
	Button["specinfo"]["x0"] = px + 5
	Button["specinfo"]["y0"] = py + 5
	
end

local function updateMyStartUnit()
	local startID = Spring.GetTeamRulesParam(myTeamID, 'startUnit')
	
	local startSide = UnitDefs[startID] and UnitDefs[startID].customParams and UnitDefs[startID].customParams.side
	local startType = UnitDefs[startID] and UnitDefs[startID].customParams and UnitDefs[startID].customParams.type
	
	mySide = startSide
	myType = startType
	
end

local function updateSize()
	-- update size for spectators
	if Spring.GetSpectatingState() then
		n = #(teamList)-1
		sizex = 380
		sizey = 50 + 20 * (n+2) -- add extra free row
	end
	
	if Spring.IsReplay() then
		
		for i, pID in pairs(Spring.Spring.GetPlayerList()) do
			local _,_,isSpec = Spring.Spring.GetPlayerInfo(pID)
			if not isSpec then
				if not playerStates[pID] then
					playerStates[pID] = "missing"
				end
			end
		end
		
		n = #(teamList)-1
		
		sizex = 380
		sizey = 50 + 20 * (n+2) -- add extra free row
	end
	--buttons:
	initButtons()
	
end

local function updateStates()
	
	for i,playerID in pairs (playerList) do
		local leaderName,active,spec,teamID,_,_,_,country,rank	= Spring.GetPlayerInfo(playerID)
		local posx = Spring.GetTeamStartPosition(teamID)
		
		if not active or APLStates[playerID] == 3 then
			readyStates[playerID] = MISSING
		elseif APLStates[playerID] == 1 or APLStates[playerID] == 2 then
			readyStates[playerID] = READY
		elseif APLStates[playerID] == 4 or markedStates[playerID] or (posx and posx > 0)then
			readyStates[playerID] = MARKED
		elseif APLStates[playerID] == 0 then
			readyStates[playerID] = PRESENT
		else
			if Spring.IsReplay() and active then
				readyStates[playerID] = PRESENT
			else
				readyStates[playerID] = OTHER
			end
		end
		
		-- update myState variable
		if teamID == myTeamID and not spec then
			if myState ~= READY and myState ~= MARKED then -- those are set by player in mousepress event
				myState = readyStates[playerID]
			end
		end
	end
end

local function playSound(snd)
	Spring.PlaySoundFile(snd)
end

local function DrawRectRound(px,py,sx,sy,cs)
	gl.TexCoord(0.8,0.8)
	gl.Vertex(px+cs, py, 0)
	gl.Vertex(sx-cs, py, 0)
	gl.Vertex(sx-cs, sy, 0)
	gl.Vertex(px+cs, sy, 0)
	
	gl.Vertex(px, py+cs, 0)
	gl.Vertex(px+cs, py+cs, 0)
	gl.Vertex(px+cs, sy-cs, 0)
	gl.Vertex(px, sy-cs, 0)
	
	gl.Vertex(sx, py+cs, 0)
	gl.Vertex(sx-cs, py+cs, 0)
	gl.Vertex(sx-cs, sy-cs, 0)
	gl.Vertex(sx, sy-cs, 0)
	
	local offset = 0.07		-- texture offset, because else gaps could show
	local o = offset
	-- top left
	if py <= 0 or px <= 0 then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(px, py, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(px+cs, py, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(px+cs, py+cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(px, py+cs, 0)
	-- top right
	if py <= 0 or sx >= vsx then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(sx, py, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(sx-cs, py, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(sx-cs, py+cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(sx, py+cs, 0)
	-- bottom left
	if sy >= vsy or px <= 0 then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(px, sy, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(px+cs, sy, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(px+cs, sy-cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(px, sy-cs, 0)
	-- bottom right
	if sy >= vsy or sx >= vsx then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(sx, sy, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(sx-cs, sy, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(sx-cs, sy-cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(sx, sy-cs, 0)
end
		
function RectRound(px,py,sx,sy,cs)
	cs = cs or 6
	local px,py,sx,sy,cs = math.floor(px),math.floor(py),math.ceil(sx),math.ceil(sy),math.floor(cs)
	
	gl.Texture(bgcorner)
	gl.BeginEnd(GL.QUADS, DrawRectRound, px,py,sx,sy,cs)
	gl.Texture(false)
end

local function drawBorder(x0, y0, x1, y1, width)
	gl.Rect(x0, y0, x1, y0 + width)
	gl.Rect(x0, y1, x1, y1 - width)
	gl.Rect(x0, y0, x0 + width, y1)
	gl.Rect(x1, y0, x1 - width, y1)
end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY
end

function round(num, idp)
	return string.format("%." .. (idp or 0) .. "f", num)
end

function GetSkill(customtable)
	if not customtable then return end
	local tsMu = customtable.skill
	
	if tsMu then
		tskill = tsMu and tonumber(tsMu:match("%d+%.?%d*")) or 0
		--tskill = round(tskill,0)
	else
		tskill = 0
	end
	return tskill
end

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------
function widget:Initialize()

    if Spring.GetGameFrame() > 0 or (Spring.GetModOptions() or {}).commander ~= "choose" then
        widgetHandler:RemoveWidget()
		return
    end

	vsx, vsy = gl.GetViewSizes()
	scale = vsy/1024
	
	--sizes:
	sizex = SIZEX * scale
	sizey = SIZEY * scale
	mid = px + sizex/2
	th = 16 * scale
	th2 = 11 * scale
	th3 = 20 * scale
	isTLL = tonumber( (Spring.GetModOptions() or {}).tllunits) == 1
	isGOK = tonumber( (Spring.GetModOptions() or {}).gokunits) == 1
	isTAL = tonumber( (Spring.GetModOptions() or {}).talonunits) == 1
	
	updateMyStartUnit()
	
	--marked states
	for i,player in ipairs(teamList) do
		markedStates[i] = false
	end
		
	--set default startID
	if lastStartID then
		local lastSide = UnitDefs[lastStartID] and UnitDefs[lastStartID].customParams and UnitDefs[lastStartID].customParams.side
		local lastType = UnitDefs[lastStartID] and UnitDefs[lastStartID].customParams and UnitDefs[lastStartID].customParams.type
		--Echo("Commchange:",lastSide,lastType)
		if lastSide then
			if lastSide == "arm" then
				Spring.SendLuaUIMsg('195' .. 1)
			elseif lastSide == "core" then
				Spring.SendLuaUIMsg('195' .. 2)
			elseif lastSide == "lost" then
				if isTLL then
					Spring.SendLuaUIMsg('195' .. 3)
				else
					Spring.SendLuaUIMsg('195' .. 1)
				end
			elseif lastSide == "guardian" then
				if isGOK then
					Spring.SendLuaUIMsg('195' .. 4)
				else
					Spring.SendLuaUIMsg('195' .. 1)
				end
			end
			
			if lastType then
				Spring.SendLuaRulesMsg('\177' .. commanderID[lastSide .. "_" .. lastType])
			end
		end
	else -- set manual commander as default for newbies
		mySide = (mySide or select(5,Spring.Spring.GetTeamInfo(myTeamID))) or "arm"
		if mySide == "arm" then
			Spring.SendLuaRulesMsg('\177' .. commanderID["arm_manual"])
			Spring.SendLuaUIMsg('195' .. 1)
			lastStartID = commanderID["arm_manual"]
		elseif mySide == "core" then
			Spring.SendLuaRulesMsg('\177' .. commanderID["core_manual"])
			Spring.SendLuaUIMsg('195' .. 2)
			lastStartID = commanderID["core_manual"]
		elseif mySide == "lost" then
			if isTLL then
				Spring.SendLuaRulesMsg('\177' .. commanderID["lost_manual"])
				Spring.SendLuaUIMsg('195' .. 3)
				lastStartID = commanderID["lost_manual"]
			else
				Spring.SendLuaRulesMsg('\177' .. commanderID["arm_manual"])
				Spring.SendLuaUIMsg('195' .. 1)
				lastStartID = commanderID["arm_manual"]
			end
		elseif mySide == "guardian" then
			if isGOK then
				Spring.SendLuaRulesMsg('\177' .. commanderID["guardian_manual"])
				Spring.SendLuaUIMsg('195' .. 4)
				lastStartID = commanderID["guardian_manual"]
			else
				Spring.SendLuaRulesMsg('\177' .. commanderID["arm_manual"])
				Spring.SendLuaUIMsg('195' .. 1)
				lastStartID = commanderID["arm_manual"]
			end
		end	
	end
	updateSize()
end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx, vsy = gl.GetViewSizes()
	scale = vsy/1024
	
	--sizes:
	sizex = SIZEX * scale
	sizey = SIZEY * scale
	th = 16 * scale
	th2 = 11 * scale
	th3 = 20 * scale
	initButtons()
end

function widget:Update()
	updateSize()
	
	for _,playerID in pairs (playerList) do
		local leaderName,active,spec,teamID,_,_,_,country,rank	= Spring.GetPlayerInfo(playerID)
		APLStates[playerID] = Spring.GetGameRulesParam("player_" .. tostring(playerID) .. "_readyState")
	end	
	updateStates()
	
	if not Spring.GetSpectatingState() then
		updateMyStartUnit()
	end
	
end

function widget:DrawWorld()
	if Spring.IsGUIHidden() or gameStarted then return end
		
	gl.Color(cAlpha)
    gl.DepthTest(false)
    for i = 1, #teamList do
        local teamID = teamList[i]
        local tsx, tsy, tsz = Spring.GetTeamStartPosition(teamID)
        if tsx and tsx > 0 then
			local _,_,_,_,teamside = Spring.GetTeamInfo(teamID)
			local startUnit = Spring.GetTeamRulesParam(teamID, 'startUnit')
			if startUnit then
				local cp = ((startUnit and UnitDefs[startUnit]) and UnitDefs[startUnit].customParams) or nil
				if cp and cp.side then teamside = cp.side end
			end
			
            if teamside == "arm" then
                gl.Texture(img.arm)
                gl.BeginEnd(GL.QUADS, QuadVerts, tsx, Spring.GetGroundHeight(tsx, tsz), tsz, 80)
				gl.Texture(false)
            elseif teamside == "core" then
                gl.Texture(img.core)
                gl.BeginEnd(GL.QUADS, QuadVerts, tsx, Spring.GetGroundHeight(tsx, tsz), tsz, 64)
				gl.Texture(false)
			elseif teamside == "guardian" then
                gl.Texture(img.guardian)
                gl.BeginEnd(GL.QUADS, QuadVerts, tsx, Spring.GetGroundHeight(tsx, tsz), tsz, 64)
				gl.Texture(false)
			elseif teamside == "talon" then
                gl.Texture(img.talon)
                gl.BeginEnd(GL.QUADS, QuadVerts, tsx, Spring.GetGroundHeight(tsx, tsz), tsz, 64)
				gl.Texture(false)
			else
				gl.Texture(img.lost)
                gl.BeginEnd(GL.QUADS, QuadVerts, tsx, Spring.GetGroundHeight(tsx, tsz), tsz, 64)
				gl.Texture(false)
            end
        end
    end
    gl.Texture(false)
	
end

function widget:DrawScreenEffects(vsx, vsy)
	if Spring.IsGUIHidden() then return end
	
	if not gameStarted and not gameOver then
		local h = vsy/3
		local x = vsx/2 - h/2
		local y = vsy/2 - h/2
		local x1 = x + h
		local y1 = y + h
		
		--CountDown
		if gameState == COUNTDOWN and not Spring.IsReplay() then
			gl.Color(cCount)
			
			if cntDown == "3" then
				gl.Texture(img.cnt3)
			elseif cntDown == "2" then
				gl.Texture(img.cnt2)
			elseif cntDown == "1" then
				gl.Texture(img.cnt1)
			elseif cntDown == "0" then
				gl.Texture(img.cnt0)
			else
				Echo(cntDown)
			end
			
			gl.TexRect(x,y,x1,y1)
			gl.Texture(false)
			gl.Color(cWhite)
			
			if cntDown ~= lastCount then
				Spring.PlaySoundFile(tock)
				lastCount = cntDown
			end
		end
		
		if myState ~= READY then
			if not Spring.GetSpectatingState() then
				-- Infobutton
				gl.Texture(false)
				gl.Color(cWhite)
				drawBorder(Button["info"]["x0"],Button["info"]["y0"],Button["info"]["x1"],Button["info"]["y1"],1)
				myFont:Begin()
				myFont:SetTextColor(infoOn and cWhite or cGrey)
				myFont:Print("info", 0.5 * (Button["info"]["x0"] + Button["info"]["x1"]) , 0.5 * (Button["info"]["y0"] + Button["info"]["y1"]) , th,'vcs')
				myFont:End()
				-- infopanel
				if infoOn then
					gl.Color(cDark)
					gl.Rect(Button["infopanel"]["x0"],Button["infopanel"]["y0"],Button["infopanel"]["x1"],Button["infopanel"]["y1"])
					gl.Color(cWhite)
					drawBorder(Button["infopanel"]["x0"],Button["infopanel"]["y0"],Button["infopanel"]["x1"],Button["infopanel"]["y1"],1)
					
					local x0 = Button["infopanel"]["x0"]
					local y0 = Button["infopanel"]["y0"]
					local x1 = Button["infopanel"]["x1"]
					local y1 = Button["infopanel"]["y1"]
					local txt
					local side
					local uptype
					if mySide == "arm" then
						side = "Arm"
						if myType == "automatic" then
							uptype = "automatic upgrades"
							txt = {"* Arm Commander is faster than Core.",
								"* Increases radar, sonar, laser range, and speed with more XP",
								"* Gets 20% armour and secondary laser at 0.15 XP",
								"* Paralyser beam at 0.3, Sniper Laser at 0.6 and Sat. Strike at 1.2 XP",
								"* Good to use if you will be at the front a lot as upgrades are effortless",
								"* Upgrading is very dependent on experience"}
						elseif myType == "manual" then
							uptype = "regular upgrades"
							txt = {"* Arm Commander is faster than Core.",
								"* With each upg. level commander gets more HP, build power and",
								"  produces more resources",
								"* Paralyser laser and longer D-Gun at level 2",
								"* Self-repair at level 3, Sat. Strike and at Level 4.",
								"* Commander will be stunned during manual upgrade",
								"* A manually morphed commander will increase his D-Gun range"}
						end
					elseif mySide == "core" then
						side = "Core"
						if myType == "automatic" then
							uptype = "automatic upgrades"
							txt = {"* Core is slow in the beginning, but has longer D-Gun range.",
								"* Increases radar, sonar, laser range, and speed with more XP",
								"* Gets 20% armour and secondary laser at 0.15 XP",
								"* Ion Beam at 0.3, Sumo Laser at 0.6, and Sat. Strike at 1.2 XP.",
								"* Good to use if you will be at the front a lot as upgrades are effortless",
								"* Upgrading is very dependent on experience"}
						elseif myType == "manual" then
							uptype = "regular upgrades"
							txt = {"* Core Commander is slower, but has longer D-Gun.",
								"* With each upg. level commander gets more HP, build power and",
								"  produces more resources",
								"* Gets a longer D-Gun when upgraded, and laser beam at level 2.",
								"* A level 4 Commander will have a Sat. Artillery shot.",
								"* Commander will be stunned during manual upgrade",
								"* A manually morphed commander will increase his D-Gun range"}
						end
					elseif mySide == "lost" then
						side = "Lost"
						if myType == "automatic" then
							uptype = "automatic upgrades"
							txt = {"* Automatic upgrades depend on kills and are applied automatically"}
						elseif myType == "manual" then
							uptype = "regular upgrades"
							txt = {"* TLL Commander is even slower than Core, but can D-Gun and live."}
						end
					elseif mySide == "guardian" then
						side = "Guardian"
						if myType == "automatic" then
							uptype = "automatic upgrades"
							txt = {"* Automatic upgrades depend on kills and are applied automatically"}
						elseif myType == "manual" then
							uptype = "regular upgrades"
							txt = {"* GoK Commander is even slower than Core, but can D-Gun and live."}
						end
					end
					local xofs, thofs = x0+10, th2+6
					myFont:Begin()
						if side and uptype and txt then
							myFont:Print(side .. " commander with " .. uptype .. ":", xofs, y1 - thofs, th, 'xn')
							for i=1, #txt do
								myFont:Print(txt[i], xofs, y1 - (i+2)*thofs, th2, 'xn')
							end
						else
							myFont:Print("(No commander type selected)", xofs, y1 - thofs, th, 'xn')
						end
					myFont:End()
				end
			end
			
			if gameState ~= COUNTDOWN or Spring.IsReplay() then -- replay has countdown before everything
				-- Panel
				gl.Color(cDark)
				gl.Rect(px,py, px+sizex, py+sizey)
				gl.Color(cWhite)
			end
		end
		
		-- Highlight
		gl.Color(cLight)
		if Button["arm"]["On"] then
			RectRound(Button["arm"]["x0"],Button["arm"]["y0"], Button["arm"]["x1"], Button["arm"]["y1"])
		elseif Button["core"]["On"] then
			RectRound(Button["core"]["x0"],Button["core"]["y0"], Button["core"]["x1"], Button["core"]["y1"])
		elseif Button["lost"]["On"] then
			RectRound(Button["lost"]["x0"],Button["lost"]["y0"], Button["lost"]["x1"], Button["lost"]["y1"])
		elseif Button["guardian"]["On"] then
			RectRound(Button["guardian"]["x0"],Button["guardian"]["y0"], Button["guardian"]["x1"], Button["guardian"]["y1"])
		elseif Button["ready"]["On"] then
			RectRound(Button["ready"]["x0"],Button["ready"]["y0"], Button["ready"]["x1"], Button["ready"]["y1"])
		elseif Button["info"]["On"] and myState ~= READY then
			RectRound(Button["info"]["x0"],Button["info"]["y0"], Button["info"]["x1"], Button["info"]["y1"])
		elseif Button["exit"]["On"] then
			RectRound(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
		elseif Button["duck"]["On"] then
			RectRound(Button["duck"]["x0"],Button["duck"]["y0"], Button["duck"]["x1"], Button["duck"]["y1"])
		end
		gl.Color(cWhite)
	elseif not gameOver then
		-- game started text
		if Spring.IsReplay() or Spring.GetSpectatingState() then
			local frame = Spring.GetGameFrame()
			local gs = Spring.GetGameSpeed() or 1
			local x0 = vsx/2
			if frame > 120 then
				x0 = vsx/2 + (frame - 120)*(frame - 120)*10
			end
			myFontHuge:Begin()
			myFontHuge:SetTextColor({0.75-0.5*math.sin(frame/2/gs), 0.75-0.25*math.sin(frame/2/gs), 1-0.25*math.sin(frame/2/gs), 1-0.25*math.sin(frame/2/gs)})
			myFontHuge:Print("GAME STARTED",x0,vsy/2,60,'cbs')
			myFontHuge:End()
		end
	end
end

function widget:DrawScreen()
	
	if Spring.IsGUIHidden() or gameStarted or gameOver then return end
	
	local function firstToUpper(str)
		return (str:gsub("^%l", string.upper))
	end	
	
	local startID = Spring.GetTeamRulesParam(myTeamID, 'startUnit')
	
	-- Draw list with player connection and ready up states
	myFont:Begin()
	if playerStates then
		local n = 0
		for _,_ in pairs(playerStates) do
			n = n + 1
		end
		local y0 = 40 + 0.5*(vsy + n*th3)
		
		myFont:SetTextColor(cWhite)
		myFont:Print("Players:", 10, y0 + th3+2, th3, 'xns')
		myFont:End()
		
		for _,playerID in pairs(playerList) do
			local leaderName,active,spec,team,_,_,_,country,rank	= Spring.GetPlayerInfo(playerID)
						
			myFont:Begin()
			if readyStates[playerID] == MISSING then
				myFont:SetTextColor({0.6, 0.2, 0.2, 0.8}) -- red
			elseif readyStates[playerID] == PRESENT then
				myFont:SetTextColor({0.6, 0.6, 0.2, 1}) -- yellow
			elseif readyStates[playerID] == MARKED then
				myFont:SetTextColor({0.3, 0.5, 0.7, 1}) -- blue
			elseif readyStates[playerID] == READY then
				myFont:SetTextColor({0.0, 0.5, 0.0, 1}) -- green
			elseif readyStates[playerID] == OTHER then
				myFont:SetTextColor({0.5, 0.5, 0.5, 0.8}) -- grey 
			end
						
			if not spec then
				myFont:Print(leaderName, 25, y0 - (th3+2) * playerID, th3, 'xno')
				gl.Color(cRank)
				gl.Texture("LuaUI/Images/commchange/C-Rank" .. rank ..".png")
				gl.TexRect(10, y0 - (th3+2)* playerID, 22, y0 - (th3+2) * playerID+12)
				gl.Texture (false)
			else
				if readyStates[playerID] == MISSING then
					myFont:SetTextColor({0.6, 0.2, 0.2, 0.8}) -- red
				else
					myFont:SetTextColor({0.5, 0.5, 0.5, 0.8}) -- grey 
				end
				myFont:Print(leaderName .. " (s)", 25, y0 - (th3+2)* playerID, th3, 'xno')
			end
			myFont:End()
		end
	end
	gl.Color(cWhite)
	
	if Spring.GetSpectatingState() and not gameOver then -- Draw window with info for spectators
		do
			-- duck button
			gl.Color(cDark)
			gl.Rect(Button["duck"]["x0"],Button["duck"]["y0"], Button["duck"]["x1"], Button["duck"]["y1"])
			gl.Color(cBlack)
			drawBorder(Button["duck"]["x0"],Button["duck"]["y0"], Button["duck"]["x1"], Button["duck"]["y1"],1)
			
			myFont:Begin()
			-- spectator info label
			gl.Color(cDark)
			gl.Rect(Button["speclabel"]["x0"],Button["speclabel"]["y0"], Button["speclabel"]["x1"], Button["speclabel"]["y1"])
			myFont:SetTextColor(cWhite)
			
			myFont:Print("Info for spectators", Button["speclabel"]["x0"] + 78 ,Button["speclabel"]["y0"] + 10, th, 'xs')
			
			--exit button
			gl.Color(cDark)
			gl.Rect(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
			gl.Color(cBlack)
			drawBorder(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"],1)
			gl.Color(cWhite)
			myFont:SetTextColor(cWhite)
			myFont:Print("X", Button["exit"]["x0"] + 10 ,Button["exit"]["y0"] + 10, 20, 'xs')
			myFont:End()
			
			-- textures
			local fr = 3 -- frame
			gl.Color(cWhite)
			gl.Texture(img.duck)
			gl.TexRect(Button["duck"]["x0"]+fr,Button["duck"]["y0"]+fr, Button["duck"]["x1"]-fr, Button["duck"]["y1"]-fr)
			gl.Texture(false)
			
			--player states billboard
			-- x-size = [0,320]
			local x0 		= px + 8
			local y0 		= Button["speclabel"]["y0"] - 20
			local rh 		= 15 -- row height
			local col_0 	= x0 		-- team #
			local col_1 	= x0 + 20	-- faction symbol
			local col_2 	= x0 + 40	-- commander type 
			local col_3 	= x0 + 80	-- player rank
			local col_4 	= x0 + 100	-- leader name
			local col_5 	= x0 + 240	-- status text
			local col_6 	= x0 + 320	-- skill
			local prevposy = y0 - 14
			
			if gameState ~= COUNTDOWN or Spring.IsReplay() then
				--labels
				myFont:Begin()
				myFont:SetTextColor({0.6, 0.6, 0.8, 1})
				myFont:Print("Team", 	col_0, y0 - 10, th2, 'xo')
				myFont:Print("Player", 	col_4, y0 - 10, th2, 'xo')
				myFont:Print("Status",	col_5, y0 - 10, th2, 'xo')
				myFont:Print("Skill",	col_6, y0 - 10, th2, 'xo')
				
				-- Game state info label
				myFont:SetTextColor(cWhite)
				local txt = (Spring.IsReplay() and "Waiting for replay to start...") or (strInfo or "")
				
				myFont:Print("Status: " .. txt, Button["specinfo"]["x0"] + 10 ,Button["specinfo"]["y0"] + 5, 11, 'xo')
				myFont:End()
				
				--player data
				local as = 0 -- ally separation space
				
				for _, aID in pairs(Spring.GetAllyTeamList()) do
					as = 8
					-- draw line between allies
					gl.Color(0.1, 0.1, 0.1, 0.3)
					gl.Rect(col_0, prevposy - 7, col_6+th2*gl.GetTextWidth("Skill"), prevposy - 8)
					gl.Color(0.4, 0.4, 0.4, 0.3)
					gl.Rect(col_0, prevposy - 8, col_6+th2*gl.GetTextWidth("Skill"), prevposy - 9)
					
					local teamSkill = 0
					local y2 = prevposy - as - rh
					
					for i, tID in pairs(Spring.GetTeamList(aID)) do
						
						local y1 		= prevposy - as - rh
						prevposy		= y1
						as = 0
						
						local _,leaderID,_,isAI,_,allyID = Spring.GetTeamInfo(tID)
						local leaderName,active,spec,team,allyteam,_,_,country,rank,customtable	= Spring.GetPlayerInfo(leaderID)
						local skill = GetSkill(customtable) or 0
						
						local aiID, aiName, aiHostID, aiShortName = Spring.GetAIInfo(tID)
						local isComShare = false
						local pCount = 0
						for _, pID in pairs (Spring.GetPlayerList(tID)) do
							local _,_,isSspec = Spring.GetPlayerInfo(pID)
							if isSpec == false then 
								pCount = pCount + 1 
							end
						end
												
						if pCount > 1 then isComShare = true end
						
						if isAI then 
							local remoteName = Spring.GetGameRulesParam("AI-Name"..tID) or "(remote)"
							if (not shortName) or (shortName == "") or shortName:find("KNOWN") then
								leaderName = "AI: " .. remoteName 
							else
								leaderName = "AI: " .. (shortName or "?")
							end				
						end
						
						if isComShare then leaderName = leaderName .. "+" end
						
						teamSkill = skill and teamSkill + skill or teamSkill
						
						if tID ~= Spring.GetGaiaTeamID() then
							local marked = markedStates[i]
							local startID = Spring.GetTeamRulesParam(tID, 'startUnit')
							local ps = tostring(playerStates[leaderID] or "?")
							
							local commside = UnitDefs[startID] and UnitDefs[startID].customParams and UnitDefs[startID].customParams.side or '?'
							local commtype = UnitDefs[startID] and UnitDefs[startID].customParams and UnitDefs[startID].customParams.type or '?'
							
							commtype = (commtype == "automatic" and "AT") or (commtype == "manual" and "MT") or '?'
							
							myFont:Begin()
							--data
							myFont:SetTextColor(cWhite)
							if isAI then
								myFont:SetTextColor({0.8, 0.8, 0.8, 0.8})
							end
							if i == 1 then
								myFont:Print(allyID,	 		col_0, y1, th2, 'xo')
							end
							
							--side
							if commside == 'arm' then
								gl.Texture(img.arm)
							elseif commside == 'core' then
								gl.Texture(img.core)
							elseif commside == 'lost' then
								gl.Texture(img.lost)
							else
								gl.Texture(img.cnt0)
							end
							gl.Color(1, 1, 1, 0.8)
							gl.TexRect(					col_1, y1 - 5, col_1 + 15, y1 - 5 + 15)
							gl.Color(cWhite)
							gl.Texture(false)
							myFont:Print(commtype, 			col_2, y1, th2, 'xo')
							
							--rank
							if not spec then
								gl.Color(0.7, 0.7, 0.9, 0.8)
								gl.Texture("LuaUI/Images/commchange/C-Rank" .. rank ..".png")
								gl.TexRect(				col_3, y1 - 2, col_3 + 14, y1 - 2 + 14)
								gl.Texture(false)
								gl.Color(cWhite)
							end
							--name
							myFont:Print(tostring(leaderName),col_4, y1, th2, 'xo')
							-- status and skill
							local statustext
							local posx = Spring.GetTeamStartPosition(tID)
							
							if isAI then
								if readyStates[leaderID] == MISSING then
									myFont:SetTextColor({0.5, 0.5, 0.5, 0.8}) -- grey
									statustext = "Computing"
								else
									myFont:SetTextColor({0.3, 0.3, 0.9, 1}) -- blue
									statustext = "Prepared"
								end
							else						
								if readyStates[leaderID] == MISSING then
									myFont:SetTextColor({0.6, 0.2, 0.2, 0.8}) -- red
									statustext = "Missing"
								elseif readyStates[leaderID] == PRESENT then
									myFont:SetTextColor({0.6, 0.6, 0.2, 1}) -- yellow
									statustext = "Warming up"
								elseif readyStates[leaderID] == MARKED then
									myFont:SetTextColor({0.3, 0.5, 0.7, 1}) -- blue
									statustext = "Marked"
								elseif readyStates[leaderID] == READY then
									myFont:SetTextColor({0.0, 0.5, 0.0, 1}) -- green
									statustext = "Ready"
								elseif readyStates[leaderID] == OTHER then
									myFont:SetTextColor({0.5, 0.5, 0.5, 0.8}) -- grey
									statustext = firstToUpper(ps)							
								end
							end
							myFont:Print(statustext,			col_5, y1, th2, 'xo')
							if i == #Spring.GetTeamList(aID) then
								myFont:SetTextColor({0.8,0.8,0.8,1})
								myFont:Print(round(teamSkill,0),col_6, y2, th2, 'xo')
							end
							myFont:SetTextColor(cWhite)
							myFont:End()
							gl.Color(cWhite)
							
						end
					end
				end
			end
			gl.Color(cWhite)
		end
	elseif not gameOver then -- draw window with options for active players
		do
			-- border
			gl.Color(cWhite)
			drawBorder(Button["arm"]["x0"],Button["arm"]["y0"], Button["arm"]["x1"], Button["arm"]["y1"],1)
			drawBorder(Button["core"]["x0"],Button["core"]["y0"], Button["core"]["x1"], Button["core"]["y1"],1)
			if isTLL then
				drawBorder(Button["lost"]["x0"],Button["lost"]["y0"], Button["lost"]["x1"], Button["lost"]["y1"],1)
			end
			if isGOK then
				drawBorder(Button["guardian"]["x0"],Button["guardian"]["y0"], Button["guardian"]["x1"], Button["guardian"]["y1"],1)
			end
			if isTAL then
				drawBorder(Button["talon"]["x0"],Button["talon"]["y0"], Button["talon"]["x1"], Button["talon"]["y1"],1)
			end
			myFont:Begin()
			-- Ready button
			local lbl
			if myState == MARKED then -- green
				myFont:SetTextColor({0.5, 1, 0.5, 1})
				lbl = "Ready"
			elseif myState == OTHER then -- red
				myFont:SetTextColor({1.0, 0.5, 0.5, 1})
				lbl = ""
			elseif myState == READY then -- white
				myFont:SetTextColor(cWhite)
				if gameState ~= COUNTDOWN then
				lbl = "Go back"
				else
				lbl = "Ready"
				end
			else -- cannot ready, grey
				myFont:SetTextColor({0.8, 0.8, 0.8, 0.5})
				lbl = ""
			end
			if lbl == "Ready" then
				drawBorder(Button["ready"]["x0"],Button["ready"]["y0"], Button["ready"]["x1"], Button["ready"]["y1"],1)
			end
			myFont:Print(lbl, 0.5*(Button["ready"]["x0"] + Button["ready"]["x1"]), 0.5 * (Button["ready"]["y0"] + Button["ready"]["y1"])-1, th, 'vcs')
			
			-- label/info panel
			gl.Color(cDark)
			RectRound(Button["infolabel"]["x0"],Button["infolabel"]["y0"], Button["infolabel"]["x1"], Button["infolabel"]["y1"])
			drawBorder(Button["infolabel"]["x0"],Button["infolabel"]["y0"], Button["infolabel"]["x1"], Button["infolabel"]["y1"],1)
			gl.Color(cWhite)
			local txt = strInfo or "..."
			
			if myState == PRESENT then
				txt = table.concat({strInfo," (click to change Commander)"})
			elseif myState == MARKED then
				txt = "Press ready (or click to change Commander)"
			elseif myState == OTHER then
				txt = strInfo
			elseif myState == READY then
				if gameState ~= COUNTDOWN then
					txt = strInfo
				else
					txt = strInfo
				end
			end
			myFont:SetTextColor(cWhite)
			myFont:Print(txt, Button["infolabel"]["x0"] + 10 ,Button["infolabel"]["y0"] + 10 , th2, 'ds')
			
			--exit button
			gl.Color(cDark)
			RectRound(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
			gl.Color(cBlack)
			drawBorder(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"],1)
			myFont:SetTextColor(cWhite)
			myFont:Print("X", Button["exit"]["x0"] + 10 ,Button["exit"]["y0"] + 10 , 20, 'xs')
			
			-- arm/core/lost/guardian/talon buttons
			
			--arm
			myFont:SetTextColor(mySide == "arm" and cWhite or cUnfocus)
			myFont:Print("Arm", 0.5*(Button["arm"]["x0"] + Button["arm"]["x1"]), 0.5 * (Button["arm"]["y0"] + Button["arm"]["y1"]), th, 'vcs')
			
			--core
			myFont:SetTextColor(mySide == "core" and cWhite or cUnfocus )
			myFont:Print("Core", 0.5* (Button["core"]["x0"] + Button["core"]["x1"]), 0.5 * (Button["core"]["y0"] + Button["core"]["y1"]), th, 'vcs')
			
			--lost
			if isTLL then
				myFont:SetTextColor(mySide == "lost" and cWhite or cUnfocus )
				myFont:Print("TLL", 0.5* (Button["lost"]["x0"] + Button["lost"]["x1"]), 0.5 * (Button["lost"]["y0"] + Button["lost"]["y1"]), th, 'vcs')
			end
			-- GOK
			if isGOK then
				myFont:SetTextColor(mySide == "guardian" and cWhite or cUnfocus )
				myFont:Print("GoK", 0.5* (Button["guardian"]["x0"] + Button["guardian"]["x1"]), 0.5 * (Button["guardian"]["y0"] + Button["guardian"]["y1"]), th, 'vcs')
			end
			-- TAL
			if isTAL then
				myFont:SetTextColor(mySide == "talon" and cWhite or cUnfocus )
				myFont:Print("Talon", 0.5* (Button["talon"]["x0"] + Button["talon"]["x1"]), 0.5 * (Button["talon"]["y0"] + Button["talon"]["y1"]), th, 'vcs')
			end
			myFont:SetTextColor(cWhite)
			
			if myState ~= READY then
				-- Commander Icons
				gl.Color(cWhite)
				
				if mySide == "arm" then
					if myType == "automatic" then
						gl.Texture(img.ComAA)
						gl.TexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
						gl.Texture(img.ComAMD)
						gl.TexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
					else
						gl.Texture(img.ComAAD)
						gl.TexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
						gl.Texture(img.ComAM)
						gl.TexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
					end
					gl.Texture(false)
				elseif mySide == "core" then
					if myType == "automatic" then
						gl.Texture(img.ComCA)
						gl.TexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
						gl.Texture(img.ComCMD)
						gl.TexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
					else
						gl.Texture(img.ComCAD)
						gl.TexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
						gl.Texture(img.ComCM)
						gl.TexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
					end
					gl.Texture(false)
				elseif mySide == "lost" then
					if myType == "automatic" then
						gl.Texture(img.ComLA)
						gl.TexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
						gl.Texture(img.ComLMD)
						gl.TexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
					else
						gl.Texture(img.ComLAD)
						gl.TexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
						gl.Texture(img.ComLM)
						gl.TexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
					end
				elseif mySide == "talon" then
					if myType == "automatic" then
						gl.Texture(img.ComTA)
						gl.TexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
						gl.Texture(img.ComTMD)
						gl.TexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
					else
						gl.Texture(img.ComTAD)
						gl.TexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
						gl.Texture(img.ComTM)
						gl.TexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
					end
				elseif mySide == "guardian" then
					if myType == "automatic" then
						gl.Texture(img.ComGA)
						gl.TexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
						gl.Texture(img.ComGMD)
						gl.TexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
					else
						gl.Texture(img.ComGAD)
						gl.TexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
						gl.Texture(img.ComGM)
						gl.TexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
					end
					gl.Texture(false)
				end
			
				--commander text
				myFont:SetTextColor(cWhite)
				myFont:Print("Automatic", px+sizex/4  , py + 10 , (th-2),'cxs')
				myFont:Print("Manual", px+3*sizex/4  , py + 10 , (th-2),'cxs')
			end
			myFont:End()
			gl.Color(cWhite)
		end
	end
	gl.Color(cWhite)
end

function widget:GameSetup(state, ready, playerStates)
	local strS = string.sub(state,1,6)
	local strN = string.sub(state,13,13)
	playerStates = playerStates
	strInfo = state
	
	if not gameOver then
		if strS == "Choose" then 
			gameState = CHOOSE -- gamestate == 0
		elseif strS == "Waitin" then
			gameState = WAITING -- gamestate == 1
		elseif strS == "Starti" then
			gameState = COUNTDOWN -- gamestate == 2
			cntDown = strN
			if not hasSentStartMsg then
				Spring.SendLuaUIMsg('776-717')
				hasSentStartMsg = true
			end
		else
			gameState = ERROR -- gamestate == -1
		end
		
		if gameState == COUNTDOWN then
			return true, true
		else	
			if myState == PRESENT then
				return true, false
			elseif myState == MARKED then
				return true, false
			elseif myState == READY then
				return true, true
			else
				return true, false
			end
		end
	else
		return true, false
	end
end

function widget:MousePress(mx, my, mButton)
	if not gameOver and not gameStarted then
		if Spring.GetSpectatingState()  then
			if mButton == 1 then
				if IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
					widgetHandler:RemoveWidget()
					Echo("Exit to native dialogue window.")
					playSound(cancel)
					return true
				elseif IsOnButton(mx,my,Button["duck"]["x0"],Button["duck"]["y0"],Button["duck"]["x1"],Button["duck"]["y1"]) then
					local idx = math.random(1,#duckSounds)
					playSound(duckSounds[idx])
					return true
				end
			elseif (mButton == 2 or mButton == 3) and mx < px + sizex then
				
				if mx >= px and my >= py and my < Button["exit"]["y1"] then
					-- Dragging
					return true
				end
			end
			updateMyStartUnit()
			initButtons()
		else -- player
			if IsOnButton(mx,my, px,py, px+sizex, Button["exit"]["y1"]) then
				-- Check buttons
				if mButton == 1 then
					local startID = Spring.GetTeamRulesParam(myTeamID, 'startUnit')
					local startSide = UnitDefs[startID] and UnitDefs[startID].customParams and UnitDefs[startID].customParams.side
					local startType = UnitDefs[startID] and UnitDefs[startID].customParams and UnitDefs[startID].customParams.type
					
					--Echo("Old commander:",startID,startSide,startType)
					-- arm button
					if IsOnButton(mx,my,Button["arm"]["x0"],Button["arm"]["y0"],Button["arm"]["x1"],Button["arm"]["y1"]) and startSide ~= "arm" then	
						Spring.SendLuaRulesMsg('\177' .. commanderID["arm_" .. startType])
						Spring.SendLuaUIMsg('195' .. 1)
						lastStartID = commanderID["arm_" .. startType]
						playSound(button3)
						--Echo("Click on: Arm")
				
					-- core button
					elseif IsOnButton(mx,my,Button["core"]["x0"],Button["core"]["y0"],Button["core"]["x1"],Button["core"]["y1"]) and startSide ~= "core" then
						Spring.SendLuaRulesMsg('\177' .. commanderID["core_" .. startType])
						Spring.SendLuaUIMsg('195' .. 2)
						lastStartID = commanderID["core_" .. startType]
						playSound(button3)
						--Echo("Click on: Core")
					-- lost button
					elseif isTLL and IsOnButton(mx,my,Button["lost"]["x0"],Button["lost"]["y0"],Button["lost"]["x1"],Button["lost"]["y1"]) and startSide ~= "lost" then
						Spring.SendLuaRulesMsg('\177' .. commanderID["lost_" .. startType])
						Spring.SendLuaUIMsg('195' .. 3)
						lastStartID = commanderID["lost_" .. startType]
						playSound(button3)	
						--Echo("Click on: Lost")
					-- guardian button
					elseif isGOK and IsOnButton(mx,my,Button["guardian"]["x0"],Button["guardian"]["y0"],Button["guardian"]["x1"],Button["guardian"]["y1"]) and startSide ~= "guardian" then
						Spring.SendLuaRulesMsg('\177' .. commanderID["guardian_" .. startType])
						Spring.SendLuaUIMsg('195' .. 4)
						lastStartID = commanderID["guardian_" .. startType]
						playSound(button3)	
						--Echo("Click on: Guardian")
					-- talon button
					elseif isTAL and IsOnButton(mx,my,Button["talon"]["x0"],Button["talon"]["y0"],Button["talon"]["x1"],Button["talon"]["y1"]) and startSide ~= "talon" then
						Spring.SendLuaRulesMsg('\177' .. commanderID["talon_" .. startType])
						Spring.SendLuaUIMsg('195' .. 5)
						lastStartID = commanderID["talon_" .. startType]
						playSound(button3)
						--Echo("Click on: Talon")
					-- automatic
					elseif IsOnButton(mx,my,Button["auto"]["x0"],Button["auto"]["y0"],Button["auto"]["x1"],Button["auto"]["y1"]) and myState ~= READY and startType ~= "automatic" then
						Spring.SendLuaRulesMsg('\177' .. commanderID[startSide .. "_automatic"])
						lastStartID = commanderID[startSide .. "_automatic"]
						playSound(button2)
					
					-- manual
					elseif IsOnButton(mx,my,Button["manual"]["x0"],Button["manual"]["y0"],Button["manual"]["x1"],Button["manual"]["y1"]) and myState ~= READY and startType ~= "manual" then
						Spring.SendLuaRulesMsg('\177' .. commanderID[startSide .. "_manual"])
						lastStartID = commanderID[startSide .. "_manual"]
						playSound(button2)			
					
					-- ready
					elseif IsOnButton(mx,my,Button["ready"]["x0"],Button["ready"]["y0"],Button["ready"]["x1"],Button["ready"]["y1"]) and gameState ~= COUNTDOWN then
						local pos = Spring.GetTeamStartPosition(myTeamID)
						if pos > 0 then
							if myState ~= READY then 
								myState = READY
							elseif myState == READY then
								myState = MARKED
							end
							playSound(button1)
							Echo("Click on: Ready")
						end
					-- info
					elseif IsOnButton(mx,my,Button["info"]["x0"],Button["info"]["y0"],Button["info"]["x1"],Button["info"]["y1"]) and myState ~= READY then
						if myState ~= READY then
							infoOn = not infoOn
							if infoOn then
								playSound(button)
							else
								playSound(cancel)
							end
						end
					-- exit
					elseif IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
						widgetHandler:RemoveWidget()
						Echo("Exit to native dialogue window.")
						playSound(cancel)
						return true
					end
					updateMyStartUnit()
					return true
				elseif (mButton == 2 or mButton == 3) and mx < px + sizex then
					if mx >= px and my >= py and my < Button["exit"]["y1"] then
						-- Dragging
						return true
					end
				end
				updateMyStartUnit()
				initButtons()
				return true
			elseif mButton == 3 and IsOnButton(mx,my,Button["infopanel"]["x0"],Button["infopanel"]["y0"],Button["infopanel"]["x1"],Button["infopanel"]["y1"]) and myState ~= READY then
				infoOn = false
				return true
			end
		end
	end
	return false
end

function widget:MouseMove(mx, my, dx, dy, mButton)
    -- Dragging
    if mButton == 2 or mButton == 3 and not gameStarted then
		px = math.max(0, math.min(px+dx, vsx-sizex))	--prevent moving off screen
		py = math.max(0, math.min(py+dy, vsy-sizey))
		initButtons()
    end
	
end

function widget:IsAbove(mx,my)
	if not gameOver then	
		if Spring.GetSpectatingState() and not gameStarted then
			Button["arm"]["On"] = false
			Button["core"]["On"] = false
			Button["lost"]["On"] = false
			Button["guardian"]["On"] = false
			Button["ready"]["On"] = false
			Button["info"]["On"] = false
			
			if IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then		
				Button["exit"]["On"] = true
				Button["duck"]["On"] = false
			elseif IsOnButton(mx,my,Button["duck"]["x0"],Button["duck"]["y0"],Button["duck"]["x1"],Button["duck"]["y1"]) then
				Button["exit"]["On"] = false
				Button["duck"]["On"] = true
			else
				Button["exit"]["On"] = false
				Button["duck"]["On"] = false
			end
		else
			
			if IsOnButton(mx,my,Button["arm"]["x0"],Button["arm"]["y0"],Button["arm"]["x1"],Button["arm"]["y1"]) and mySide ~= "arm" then
				Button["arm"]["On"] = true
				Button["core"]["On"] = false
				Button["lost"]["On"] = false
				Button["guardian"]["On"] = false
				Button["ready"]["On"] = false
				Button["info"]["On"] = false
				Button["exit"]["On"] = false
				
			elseif IsOnButton(mx,my,Button["core"]["x0"],Button["core"]["y0"],Button["core"]["x1"],Button["core"]["y1"]) and mySide ~= "core" then
				Button["arm"]["On"] = false
				Button["core"]["On"] = true
				Button["lost"]["On"] = false
				Button["guardian"]["On"] = false
				Button["ready"]["On"] = false
				Button["info"]["On"] = false
				Button["exit"]["On"] = false
			elseif IsOnButton(mx,my,Button["lost"]["x0"],Button["lost"]["y0"],Button["lost"]["x1"],Button["lost"]["y1"]) and mySide ~= "lost" then
				Button["arm"]["On"] = false
				Button["core"]["On"] = false
				Button["lost"]["On"] = true
				Button["guardian"]["On"] = false
				Button["ready"]["On"] = false
				Button["info"]["On"] = false
				Button["exit"]["On"] = false
			elseif IsOnButton(mx,my,Button["guardian"]["x0"],Button["guardian"]["y0"],Button["guardian"]["x1"],Button["guardian"]["y1"]) and mySide ~= "guardian" then
				Button["arm"]["On"] = false
				Button["core"]["On"] = false
				Button["lost"]["On"] = false
				Button["guardian"]["On"] = true
				Button["ready"]["On"] = false
				Button["info"]["On"] = false
				Button["exit"]["On"] = false
			elseif IsOnButton(mx,my,Button["ready"]["x0"],Button["ready"]["y0"],Button["ready"]["x1"],Button["ready"]["y1"]) and myState > PRESENT and gameState ~= COUNTDOWN then
				Button["arm"]["On"] = false
				Button["core"]["On"] = false
				Button["lost"]["On"] = false
				Button["guardian"]["On"] = false
				Button["ready"]["On"] = true
				Button["info"]["On"] = false
				Button["exit"]["On"] = false
			elseif IsOnButton(mx,my,Button["info"]["x0"],Button["info"]["y0"],Button["info"]["x1"],Button["info"]["y1"]) then
				Button["arm"]["On"] = false
				Button["core"]["On"] = false
				Button["lost"]["On"] = false
				Button["guardian"]["On"] = false
				Button["ready"]["On"] = false
				Button["info"]["On"] = true
				Button["exit"]["On"] = false
			elseif IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
				Button["arm"]["On"] = false
				Button["core"]["On"] = false
				Button["lost"]["On"] = false
				Button["guardian"]["On"] = false
				Button["ready"]["On"] = false
				Button["info"]["On"] = false
				Button["exit"]["On"] = true
			else
				Button["arm"]["On"] = false
				Button["core"]["On"] = false
				Button["lost"]["On"] = false
				Button["guardian"]["On"] = false
				Button["ready"]["On"] = false
				Button["info"]["On"] = false
				Button["exit"]["On"] = false
			end
		end
	end
end

function widget:GameFrame(frame)
	if frame > 240 then
		widgetHandler:RemoveWidget()
	end
end

function widget:GameStart()
	Spring.PlaySoundFile(bell,4.0,0,0,0,0,0,0,'userinterface')
	if not Spring.GetSpectatingState() then
		Spring.PlaySoundFile(beep,4.0,0,0,0,0,0,0,'unitreply')
	end
	gameStarted = true
end

function widget:GameOver()
	-- this can happen if game is abandoned before it starts
	gameOver = true
	return false
end

function widget:GetConfigData() -- Save
	local vsx, vsy = gl.GetViewSizes()
	return {
		px / vsx,
		py / vsy,
		lastStartID = lastStartID
		}
end

function widget:SetConfigData(data) -- Load
	local vsx, vsy = gl.GetViewSizes()
	px = math.floor(math.max(0, vsx * math.min(data[1] or 0, 0.95)))
	py = math.floor(math.max(0, vsy * math.min(data[2] or 0, 0.95)))
	lastStartID = data.lastStartID or lastStartID
end
