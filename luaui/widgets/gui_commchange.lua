
function widget:GetInfo()
	return {
		name      = 'Commander Change',
		desc      = 'Adds buttons to choose commander',
		version   = "1.1",
		author    = 'Niobium, Jools',
		date      = 'October, 2012',
		license   = 'GNU GPL v2',
		layer     = -9,
		enabled   = true,
	}
end
-- Bugfixes:
--
-- * Fixed a bug caused by change in ready state message by spring: it updated from "missing" to "notready" and that's why widget would never catch 
-- correct state when user has marked but not readied up. Now colour code is grey and not red when correct state is not recognised.
--
--------------------------------------------------------------------------------
-- Var
--------------------------------------------------------------------------------
local vsx, vsy = gl.GetViewSizes()
local scale
local px, py = 300, 300
local sizex, sizey  = 320, 180
local mid = px + sizex/2
local th = 16 -- text height for buttons
local th2 = 11 -- text height for body text
local th3 = 20 -- text height for player names
local imgComAA 				= "LuaUI/Images/commchange/ComAA.png" -- arm auto
local imgComAM 				= "LuaUI/Images/commchange/ComAM.png" -- arm manual
local imgComAAD 			= "LuaUI/Images/commchange/ComAAD.png" -- arm auto disabled
local imgComAMD 			= "LuaUI/Images/commchange/ComAMD.png" -- arm manual disabled
local imgComCA 				= "LuaUI/Images/commchange/ComCA.png" -- core auto
local imgComCM			 	= "LuaUI/Images/commchange/ComCM.png"
local imgComCAD 			= "LuaUI/Images/commchange/ComCAD.png" -- core auto disabled
local imgComCMD 			= "LuaUI/Images/commchange/ComCMD.png"

local img3 					= "LuaUI/Images/commchange/3-cnt.png"
local img2 					= "LuaUI/Images/commchange/2-cnt.png"
local img1 					= "LuaUI/Images/commchange/1-cnt.png"
local img0 					= "LuaUI/Images/commchange/0-cnt.png"

-- commanders
local armauto = UnitDefNames["arm_commander"].id
local armman = UnitDefNames["arm_u0commander"].id
local coreauto = UnitDefNames["core_commander"].id
local coreman = UnitDefNames["core_u0commander"].id

-- sound
local bell = 'sounds/bell.ogg'
local beep = 'sounds/BEEP1.wav'
local tock = 'sounds/ticktock.wav'
local button = 'sounds/button9.wav'
local cancel = 'sounds/cancel2.wav'

--------------------------------------------------------------------------------
-- Buttons
--------------------------------------------------------------------------------

local Button = {}
Button["arm"] = {}
Button["core"] = {}
Button["ready"] = {}
Button["info"] = {}
Button["infopanel"] = {}
Button["auto"] = {}
Button["manual"] = {}
Button["infolabel"] = {}
Button["exit"] = {}
--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local teamList = Spring.GetTeamList()
local myTeamID = Spring.GetMyTeamID()
local mySide, myType
local myState = 0
local gameState = 0
local cntDown = -1
local lastCount
local pStates
local markedStates = {}
local lastStartID

local strInfo
local infoOn = false
--local font            						= "LuaUI/Fonts/FreeMonoBold_12"
--local font2         						= "LuaUI/Fonts/FreeSansBold_14"
--local UseFont             		 			= fontHandler.UseFont
local glTexCoord = gl.TexCoord
local glVertex = gl.Vertex
local glColor = gl.Color
local glRect = gl.Rect
local glTexture = gl.Texture
local glTexRect = gl.TexRect
local glDepthTest = gl.DepthTest
local glBeginEnd = gl.BeginEnd
local GL_QUADS = GL.QUADS
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text
local Echo = Spring.Echo

local spGetTeamStartPosition = Spring.GetTeamStartPosition
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spGetGroundHeight = Spring.GetGroundHeight
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spSendLuaUIMsg = Spring.SendLuaUIMsg
local spGetSpectatingState = Spring.GetSpectatingState
local spGetTeamInfo = Spring.GetTeamInfo
local PlaySoundFile = Spring.PlaySoundFile
--------------------------------------------------------------------------------
-- Local functions
--------------------------------------------------------------------------------
local function QuadVerts(x, y, z, r)
	glTexCoord(0, 0); glVertex(x - r, y, z - r)
	glTexCoord(1, 0); glVertex(x + r, y, z - r)
	glTexCoord(1, 1); glVertex(x + r, y, z + r)
	glTexCoord(0, 1); glVertex(x - r, y, z + r)
end

local function initButtons()
	mid = px + sizex/2
	Button["arm"]["x0"] = px
	Button["arm"]["x1"] = px + sizex/4
	Button["arm"]["y0"] = py  + sizey - 24
	Button["arm"]["y1"] = py  + sizey
	
	Button["core"]["x0"] = px + sizex/4
	Button["core"]["x1"] = px + sizex/2
	Button["core"]["y0"] = py  + sizey - 24
	Button["core"]["y1"] = py  + sizey
	
	Button["ready"]["x0"] = px + sizex/2
	if myState ~= 3 then
		Button["ready"]["x1"] = px + 4*sizex/5
	else
		Button["ready"]["x1"] = px + sizex
	end
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
	
	Button["info"]["x0"] = px + 4*sizex/5
	Button["info"]["x1"] = px + sizex
	Button["info"]["y0"] = py  + sizey - 24
	Button["info"]["y1"] = py  + sizey
	
	Button["infopanel"]["x0"] = px + sizex
	Button["infopanel"]["x1"] = px + sizex + 400
	Button["infopanel"]["y0"] = py
	Button["infopanel"]["y1"] = py  + sizey
	
	Button["infolabel"]["x0"] = px
	Button["infolabel"]["x1"] = px + sizex - 30
	Button["infolabel"]["y0"] = py + sizey
	Button["infolabel"]["y1"] = py + sizey + 30
	
	Button["exit"]["x0"] = px + sizex - 30
	Button["exit"]["x1"] = px + sizex
	Button["exit"]["y0"] = py + sizey
	Button["exit"]["y1"] = py + sizey + 30
end

local function updateState()
	local startID = spGetTeamRulesParam(myTeamID, 'startUnit')
	if startID == armauto or startID == armman then
		mySide = "arm"
	else
		mySide = "core"
	end
	
	if startID == armauto or startID == coreauto then
		myType = "auto"
	else
		myType = "manual"
	end
end

local function checkState()
	local pos = spGetTeamStartPosition(myTeamID)
	if pos and pos >= 0 then
		if myState ~= 3 then 
			myState = 1
		else
			myState = 3
		end
	else
		myState = 0
	end
end

local function playSound(snd)
	PlaySoundFile(snd)
end

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------
function widget:Initialize()

    if spGetSpectatingState() or Spring.GetGameFrame() > 0 or (Spring.GetModOptions() or {}).commander ~= "choose" then
        widgetHandler:RemoveWidget(self)
    end
	--local X, Y = Spring.GetViewGeometry()
	vsx, vsy = gl.GetViewSizes()
	scale = vsy/1024
	--sizes:
	sizex 	= sizex * scale
	sizey 	= sizey * scale
	th = 16 * scale
	th2 = 11 * scale
	th3 = 20 * scale
	--position:
	--px, py = px*scale, py*scale
	-- side
	updateState()
	--buttons:
	initButtons()
	--marked states
	for i,player in ipairs(Spring.GetTeamList()) do
		markedStates[i] = false
	end
	
	--set default startID
	if lastStartID then
		if lastStartID == armauto then
			spSendLuaRulesMsg('\177' .. armauto)
			spSendLuaUIMsg('195' .. 1)
		elseif lastStartID == armman then
			spSendLuaRulesMsg('\177' .. armman)
			spSendLuaUIMsg('195' .. 1)
		elseif lastStartID == coreauto then
			spSendLuaRulesMsg('\177' .. coreauto)
			spSendLuaUIMsg('195' .. 2)
		elseif lastStartID == coreman then
			spSendLuaRulesMsg('\177' .. coreman)
			spSendLuaUIMsg('195' .. 2)
		end
	end
end

function widget:RecvLuaMsg(msg, playerID)
	local positionRegex = "181072"
	--Spring.Echo("Got a message...",msg, playerID,string.len(msg))
	if msg and string.len(msg) >= 8 then	
		local sms = string.sub(msg, string.len(positionRegex)+1) 
		local state = tonumber(string.sub(sms,1,1))
		local player = tonumber(string.sub(sms,2))
		
		--Spring.Echo("Got a msg:", player,": ",state, msg)
		--display the message in the UI
		if player then
			if state == 0 then
				markedStates[player+1] = false
			elseif state == 1 then
				markedStates[player+1] = true
			end
		end
		
		--for i,st in pairs(markedStates) do
			--Spring.Echo("Markedstates for player " .. i-1 .. ":" ,st)
		--end
		
	end
end

function widget:DrawWorld()
	checkState()
	updateState()
	initButtons()
	
	glColor(1, 1, 1, 0.5)
    glDepthTest(false)
    for i = 1, #teamList do
        local teamID = teamList[i]
        local tsx, tsy, tsz = spGetTeamStartPosition(teamID)
        if tsx and tsx > 0 then
            if mySide == "arm" then
			--if (teamStartUnit == 30) or (teamStartUnit == 166) then
                glTexture('LuaUI/Images/commchange/arm.png')
                glBeginEnd(GL_QUADS, QuadVerts, tsx, spGetGroundHeight(tsx, tsz), tsz, 80)
            else 
                glTexture('LuaUI/Images/commchange/core.png')
                glBeginEnd(GL_QUADS, QuadVerts, tsx, spGetGroundHeight(tsx, tsz), tsz, 64)
            end
        end
    end
    glTexture(false)
	
end

function widget:DrawScreenEffects(vsx, vsy)
	
	local h = vsy/3
	local x = vsx/2 - h/2
	local y = vsy/2 - h/2
	local x1 = x + h
	local y1 = y + h
	
	local function drawBorder(x0, y0, x1, y1, width)
		glRect(x0, y0, x1, y0 + width)
		glRect(x0, y1, x1, y1 - width)
		glRect(x0, y0, x0 + width, y1)
		glRect(x1, y0, x1 - width, y1)
	end
	
	--CountDown
	if gameState == 2 then
		--UseFont(font)
		glColor(0.8, 0.8, 1, 1)
		
		if cntDown == "3" then
			glTexture(img3)
		elseif cntDown == "2" then
			glTexture(img2)
		elseif cntDown == "1" then
			glTexture(img1)
		elseif cntDown == "0" then
			glTexture(img0)
		else
			Spring.Echo(cntDown)
		end
		
		glTexRect(x,y,x1,y1)
		glColor(1, 1, 1, 1)
		--glText(cntDown, vsx/2, vsy/2+100, 160, 'xsn')
		
		if cntDown ~= lastCount then
			Spring.PlaySoundFile(tock)
			lastCount = cntDown
		end
		--UseFont(font)
	end
	
	if myState ~= 3 then
	
	-- Infobutton
		if infoOn then
			glColor(1, 1, 1, 1)
		else
			glColor(1, 1, 1, 0.3)
		end
		drawBorder(Button["info"]["x0"],Button["info"]["y0"],Button["info"]["x1"],Button["info"]["y1"],1)
		glText("info", 0.5 * (Button["info"]["x0"] + Button["info"]["x1"]) , 0.5 * (Button["info"]["y0"] + Button["info"]["y1"]) , th,'vc')
		-- infopanel
		if infoOn then
			glColor(0, 0, 0, 0.5)
			glRect(Button["infopanel"]["x0"],Button["infopanel"]["y0"],Button["infopanel"]["x1"],Button["infopanel"]["y1"])
			glColor(1, 1, 1, 1)
			drawBorder(Button["infopanel"]["x0"],Button["infopanel"]["y0"],Button["infopanel"]["x1"],Button["infopanel"]["y1"],1)
			
			local x0 = Button["infopanel"]["x0"]
			local y0 = Button["infopanel"]["y0"]
			local x1 = Button["infopanel"]["x1"]
			local y1 = Button["infopanel"]["y1"]
			local txt1
			local txt2
			local txt3
			local txt4
			local side
			local uptype
			if mySide == "arm" then
				side = "Arm"
				if myType == "auto" then
					uptype = "automatic upgrades"
					txt1 = "* Arm Commander is faster than Core."
					txt2 = "* Will get longer radar, speed and laser range with more XP"
					txt3 = "* Paralyser beam at 0.3, Sniper Laser at 0.6 and Sat. Strike at 1.2 XP"
					txt4 = "* Good to use if you will be at the front a lot as upgrades are effortless"
					txt5 = "* Upgrading is very dependent on experience"
				elseif myType == "manual" then
					uptype = "manual upgrades"
					txt1 = "* Arm Commander is faster than Core."
					txt2 = "* Paralyser laser and longer D-Gun at level 2"
					txt3 = "* Self-repair at level 3, Raven-rockets and at Level 4."
					txt4 = "* Commander will be stunned during manual upgrade"
					txt5 = "* A manually morphed commander will increase his D-Gun range"
				end
			else
				side = "Core"
				if myType == "auto" then
					uptype = "automatic upgrades"
					txt1 = "* Core is slow in the beginning."
					txt2 = "* Will get longer radar, speed and laser range with more XP"
					txt3 = "* Ion Beam at 0.3, Sumo Laser at 0.6, and Sat. Strike at 1.2 XP."
					txt4 = "* Good to use if you will be at the front a lot as upgrades are effortless"
					txt5 = "* Upgrading is very dependent on experience"
				elseif myType == "manual" then
					uptype = "manual upgrades"
					txt1 = "* Core Commander is slower, but has longer D-Gun."
					txt2 = "* Gets a longer D-Gun when upgraded, and laser beam at level 2."
					txt3 = "* A level 4 Commander will have a Mobile Artillery shot."
					txt4 = "* Commander will be stunned during manual upgrade"
					txt5 = "* A manually morphed commander will increase his D-Gun range"
				end
			end
			glText(side .. " commander with " .. uptype .. ":", x0 + 10, y1 - (th2+6), th, 'xn')
			glText(txt1, x0 + 10, y1 - 3*(th2+6), th2, 'xn')
			glText(txt2, x0 + 10, y1 - 4*(th2+6), th2, 'xn')
			glText(txt3, x0 + 10, y1 - 5*(th2+6), th2, 'xn')
			glText(txt4, x0 + 10, y1 - 6*(th2+6), th2, 'xn')
			glText(txt5, x0 + 10, y1 - 7*(th2+6), th2, 'xn')
			
		end
		-- Panel
		glColor(0, 0, 0, 0.4)
		glRect(px,py, px+sizex, py+sizey)
	end
	-- Highlight
	glColor(0.8, 0.8, 0.2, 0.5)
	if Button["arm"]["On"] then
		glRect(Button["arm"]["x0"],Button["arm"]["y0"], Button["arm"]["x1"], Button["arm"]["y1"])
	elseif Button["core"]["On"] then
		glRect(Button["core"]["x0"],Button["core"]["y0"], Button["core"]["x1"], Button["core"]["y1"])
	elseif Button["ready"]["On"] then
		glRect(Button["ready"]["x0"],Button["ready"]["y0"], Button["ready"]["x1"], Button["ready"]["y1"])
	elseif Button["info"]["On"] and myState ~= 3 then
		glRect(Button["info"]["x0"],Button["info"]["y0"], Button["info"]["x1"], Button["info"]["y1"])
	elseif Button["exit"]["On"] then
		glRect(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
	end
end

function widget:DrawScreen()
	local function drawBorder(x0, y0, x1, y1, width)
		glRect(x0, y0, x1, y0 + width)
		glRect(x0, y1, x1, y1 - width)
		glRect(x0, y0, x0 + width, y1)
		glRect(x1, y0, x1 - width, y1)
	end
	
	-- Spectator check
    if spGetSpectatingState() then
        widgetHandler:RemoveWidget(self)
        return
    end
	local startID = spGetTeamRulesParam(myTeamID, 'startUnit')
	-- Player states
	if pStates then
		local n = 0
		for i,ps in pairs(pStates) do
			n = n +1
			--Spring.Echo(i, "N = " .. n, ps)
		end
		--Spring.Echo("N = " .. n)
		local y0 = 40 + vsy/2 + 0.5*n*th3
	
		glText("Players:", 10, y0 + th3+2, th3, 'xno')
		
		for i,ps in pairs(pStates) do
			local leaderName,active,spectator,team,_,_,_,country,rank	= Spring.GetPlayerInfo(i)
			local mked = markedStates[i+1]
			--Spring.Echo("State for player: ",i,team,active, mked,ps)
			if not spectator then
				if not active then
					glColor(0.6, 0.2, 0.2, 0.8) -- red
				else
					if ps == "missing" then
						glColor(0.6, 0.2, 0.2, 0.8) -- red
					elseif ps == "notready" then
						local posx = spGetTeamStartPosition(team)
						if not posx or posx < 0 then
							if markedStates and markedStates[i+1] then
								glColor(0.3, 0.5, 0.7, 1) -- blue
							else
								glColor(0.6, 0.6, 0.2, 1) -- yellow
							end
						else
							glColor(0.3, 0.5, 0.7, 1) -- blue
						end
					elseif ps == "ready" then
						glColor(0.0, 0.5, 0.0, 1) -- green -- glColor(0.7, 0.9, 0.7, 1) -- white/green
					else
						glColor(0.5, 0.5, 0.5, 0.8) -- grey -- glColor(0.7, 0.9, 0.7, 1) -- white/green
					end
				end
				glText(leaderName, 10, y0 - (th3+2)* i, th3, 'xn')
			end
		end
	end
	glColor(1, 1, 1, 1)
	drawBorder(Button["arm"]["x0"],Button["arm"]["y0"], Button["arm"]["x1"], Button["arm"]["y1"],1)
	drawBorder(Button["core"]["x0"],Button["core"]["y0"], Button["core"]["x1"], Button["core"]["y1"],1)
	
	-- Ready button
	local lbl
	if myState == 1 then -- green
		glColor(0.5, 1, 0.5, 1)
		lbl = "Ready"
	elseif myState == 2 then -- red
		glColor(1.0, 0.5, 0.5, 1)
		lbl = "Ready"
	elseif myState == 3 then -- white
		glColor(1, 1, 1, 1)
		if gameState ~= 2 then
		lbl = "Go back"
		else
		lbl = "Ready"
		end
	else -- cannot ready, grey
		glColor(0.8, 0.8, 0.8, 0.5)
		lbl = ""
	end
	if lbl == "Ready" then
		drawBorder(Button["ready"]["x0"],Button["ready"]["y0"], Button["ready"]["x1"], Button["ready"]["y1"],1)
	end
	glText(lbl, 0.5*(Button["ready"]["x0"] + Button["ready"]["x1"]), 0.5 * (Button["ready"]["y0"] + Button["ready"]["y1"]) - 2, th, 'vc') --correction for strange alignment error in y position
	
	-- label/info panel
	glColor(0, 0, 0, 0.4)
	glRect(Button["infolabel"]["x0"],Button["infolabel"]["y0"], Button["infolabel"]["x1"], Button["infolabel"]["y1"])
	drawBorder(Button["infolabel"]["x0"],Button["infolabel"]["y0"], Button["infolabel"]["x1"], Button["infolabel"]["y1"],1)
	glColor(1, 1, 1, 1)
	local txt = strInfo or "..."
	
	if myState == 0 then
		txt = strInfo .. " (click to change Commander)"
	elseif myState == 1 then
		txt = "Press ready (or click to change Commander)"
	elseif myState == 2 then
		txt = "Press ready..."
	elseif myState == 3 then
		if gameState ~= 2 then
			txt = strInfo
		else
			txt = strInfo
		end
	end
	glText(txt, Button["infolabel"]["x0"] + 10 ,Button["infolabel"]["y0"] + 10 , th2, 'd')
	
	--exit button
	glColor(0, 0, 0, 0.4)
	glRect(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
	glColor(0, 0, 0, 1)
	drawBorder(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"],1)
	glColor(1, 1, 1, 1)
	glText("X", Button["exit"]["x0"] + 10 ,Button["exit"]["y0"] + 10 , 20, 'x')
	
	-- arm/core buttons
	if mySide == "arm" then
		glColor(1, 1, 1, 1)
	else
		glColor(1, 1, 1, 0.2)
	end
	glText("Arm", 0.5*(Button["arm"]["x0"] + Button["arm"]["x1"]), 0.5 * (Button["arm"]["y0"] + Button["arm"]["y1"]), th, 'vc')
	if mySide == "core" then
		glColor(1, 1, 1, 1)
	else
		glColor(1, 1, 1, 0.2)
	end
	glText("Core", 0.5* (Button["core"]["x0"] + Button["core"]["x1"]), 0.5 * (Button["core"]["y0"] + Button["core"]["y1"]), th, 'vc')
	
	if myState ~= 3 then
		-- Commander Icons
		glColor(1, 1, 1, 1)
		if mySide == "arm" then
			if myType == "auto" then
				glTexture(imgComAA)
				glTexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
				glTexture(imgComAMD)
				glTexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
			else
				glTexture(imgComAAD)
				glTexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
				glTexture(imgComAM)
				glTexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
			end
		else
			if myType == "auto" then
				glTexture(imgComCA)
				glTexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
				glTexture(imgComCMD)
				glTexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
			else
				glTexture(imgComCAD)
				glTexRect(Button["auto"]["x0"],Button["auto"]["y0"], Button["auto"]["x1"], Button["auto"]["y1"])
				glTexture(imgComCM)
				glTexRect(Button["manual"]["x0"],Button["manual"]["y0"], Button["manual"]["x1"], Button["manual"]["y1"])
			end
		end
		--commander text
		glText("Automatic", px+sizex/4  , py + 10 , (th-2),'cxo')
		glText("Manual", px+3*sizex/4  , py + 10 , (th-2),'cxo')
	end
end

function widget:GameSetup(state, ready, playerStates)
	local strS = string.sub(state,1,6)
	local strN = string.sub(state,13,13)
	pStates = playerStates
	strInfo = state
	
	--for i,ps in pairs(pStates) do
		--Spring.Echo("State for player" .. i+1 .. ":",ps)
		--Spring.Echo("State for player" .. i+1 .. ":",markedStates[i])
	--end
	
	if strS == "Choose" then 
		gameState = 0
	elseif strS == "Waitin" then
		gameState = 1
	elseif strS == "Starti" then
		gameState = 2
		cntDown = strN
	else
		gameState = -1
	end
	
	if gameState == 2 then
		return true, true
	else	
		if myState == 0 then
			return true, false
		elseif myState == 1 then
			return true, false
		elseif myState == 3 then
			return true, true
		else
			return true, false
		end
	end
end

function widget:MousePress(mx, my, mButton)
	-- Spectator check before any action
    if spGetSpectatingState() then
		widgetHandler:RemoveWidget(self)
        return false
    end

	if IsOnButton(mx,my, px,py, px+sizex, Button["exit"]["y1"]) then
		-- Check buttons
		if mButton == 1 then
			local startID = spGetTeamRulesParam(myTeamID, 'startUnit')			
			if IsOnButton(mx,my,Button["arm"]["x0"],Button["arm"]["y0"],Button["arm"]["x1"],Button["arm"]["y1"]) then	
				if startID == coreauto or startID == coreman then
					if startID == coreauto then
						spSendLuaRulesMsg('\177' .. armauto)
						spSendLuaUIMsg('195' .. 1)
						lastStartID = armauto
					else
						spSendLuaRulesMsg('\177' .. armman)
						spSendLuaUIMsg('195' .. 1)
						lastStartID = armman
					end
					playSound(button)
				end
			elseif IsOnButton(mx,my,Button["core"]["x0"],Button["core"]["y0"],Button["core"]["x1"],Button["core"]["y1"]) then
				if startID == armauto or startID == armman then
					if startID == armauto then
						spSendLuaRulesMsg('\177' .. coreauto)
						spSendLuaUIMsg('195' .. 2)
						lastStartID = coreauto
					else
						spSendLuaRulesMsg('\177' .. coreman)
						spSendLuaUIMsg('195' .. 2)
						lastStartID = coreman
					end
					playSound(button)
				end
			elseif IsOnButton(mx,my,Button["auto"]["x0"],Button["auto"]["y0"],Button["auto"]["x1"],Button["auto"]["y1"]) then
				if startID == armman or startID == coreman then
					if startID == armman then
						spSendLuaRulesMsg('\177' .. armauto)
						spSendLuaUIMsg('195' .. 1)
						lastStartID = armauto
					else
						spSendLuaRulesMsg('\177' .. coreauto)
						spSendLuaUIMsg('195' .. 2)
						lastStartID = coreauto
					end
					playSound(button)
				end
			elseif IsOnButton(mx,my,Button["manual"]["x0"],Button["manual"]["y0"],Button["manual"]["x1"],Button["manual"]["y1"]) and myState ~= 3 then
				if startID == armauto or startID == coreauto then
					if startID == armauto then
						spSendLuaRulesMsg('\177' .. armman)
						spSendLuaUIMsg('195' .. 1)
						lastStartID = armman
					else
						spSendLuaRulesMsg('\177' .. coreman)
						spSendLuaUIMsg('195' .. 2)
						lastStartID = coreman
					end
					playSound(button)
				end
			elseif IsOnButton(mx,my,Button["ready"]["x0"],Button["ready"]["y0"],Button["ready"]["x1"],Button["ready"]["y1"]) and gameState ~= 2 then
				local pos = spGetTeamStartPosition(myTeamID)
				if pos >= 0 then
					if myState ~= 3 then 
						myState = 3
					elseif myState == 3 then
						myState = 1
					end
					playSound(button)
				end
			elseif IsOnButton(mx,my,Button["info"]["x0"],Button["info"]["y0"],Button["info"]["x1"],Button["info"]["y1"]) and myState ~= 3 then
				if myState ~= 3 then
					infoOn = not infoOn
					if infoOn then
						playSound(button)
					else
						playSound(cancel)
					end
				end
			elseif IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
				widgetHandler:RemoveWidget(self)
				Spring.Echo("Exit to native dialogue window.")
				playSound(cancel)
				return true
			end
			updateState()
			return true
		elseif (mButton == 2 or mButton == 3) and mx < px + sizex then
			if mx >= px and my >= py and my < py + sizey then
				-- Dragging
				return true
			end
		end
		updateState()
		return true
	elseif mButton == 3 and IsOnButton(mx,my,Button["infopanel"]["x0"],Button["infopanel"]["y0"],Button["infopanel"]["x1"],Button["infopanel"]["y1"]) and myState ~= 3 then
		infoOn = false
		return true
	end
	return false
end

function widget:MapDrawCmd(playerID, cmdType, px, py, pz, labeltext)
	if playerID == myTeamID then
		--checkState()
		--return true
	end
end

function widget:MouseMove(mx, my, dx, dy, mButton)
    -- Dragging
    if mButton == 2 or mButton == 3 then
        px = px + dx
        py = py + dy
		initButtons()
    end
	
end

function widget:IsAbove(mx,my)
	if IsOnButton(mx,my,Button["arm"]["x0"],Button["arm"]["y0"],Button["arm"]["x1"],Button["arm"]["y1"]) and mySide == "core" then
		Button["arm"]["On"] = true
		Button["core"]["On"] = false
		Button["ready"]["On"] = false
		Button["info"]["On"] = false
		Button["exit"]["On"] = false
	elseif IsOnButton(mx,my,Button["core"]["x0"],Button["core"]["y0"],Button["core"]["x1"],Button["core"]["y1"]) and mySide == "arm" then
		Button["arm"]["On"] = false
		Button["core"]["On"] = true
		Button["ready"]["On"] = false
		Button["info"]["On"] = false
		Button["exit"]["On"] = false
	elseif IsOnButton(mx,my,Button["ready"]["x0"],Button["ready"]["y0"],Button["ready"]["x1"],Button["ready"]["y1"]) and myState > 0 and gameState ~= 2 then
		Button["arm"]["On"] = false
		Button["core"]["On"] = false
		Button["ready"]["On"] = true
		Button["info"]["On"] = false
		Button["exit"]["On"] = false
	elseif IsOnButton(mx,my,Button["info"]["x0"],Button["info"]["y0"],Button["info"]["x1"],Button["info"]["y1"]) then
		Button["arm"]["On"] = false
		Button["core"]["On"] = false
		Button["ready"]["On"] = false
		Button["info"]["On"] = true
		Button["exit"]["On"] = false
	elseif IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
		Button["arm"]["On"] = false
		Button["core"]["On"] = false
		Button["ready"]["On"] = false
		Button["info"]["On"] = false
		Button["exit"]["On"] = true
	else
		Button["arm"]["On"] = false
		Button["core"]["On"] = false
		Button["ready"]["On"] = false
		Button["info"]["On"] = false
		Button["exit"]["On"] = false
	end
end

function widget:GameStart()
	Spring.PlaySoundFile(bell,4.0,0,0,0,0,0,0,'userinterface')
	Spring.PlaySoundFile(beep,4.0,0,0,0,0,0,0,'unitreply')
    widgetHandler:RemoveWidget(self)
end

function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY

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
