
function widget:GetInfo()
	return {
		name      = 'Commander Change',
		desc      = 'Adds buttons to choose commander',
		author    = 'Niobium, Jools',
		date      = 'March 2012',
		license   = 'GNU GPL v2',
		layer     = -100,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Var
--------------------------------------------------------------------------------
local vsx, vsy = gl.GetViewSizes()
local px, py = 300, 300
local sizex, sizey  = 320, 180
local mid = px + sizex/2
local scale = 1
local imgComAA = "LuaUI/Images/commchange/ComAA.png" -- arm auto
local imgComAM = "LuaUI/Images/commchange/ComAM.png" -- arm manual
local imgComAAD = "LuaUI/Images/commchange/ComAAD.png" -- arm auto disabled
local imgComAMD = "LuaUI/Images/commchange/ComAMD.png" -- arm manual disabled
local imgComCA = "LuaUI/Images/commchange/ComCA.png" -- core auto
local imgComCM = "LuaUI/Images/commchange/ComCM.png"
local imgComCAD = "LuaUI/Images/commchange/ComCAD.png" -- core auto disabled
local imgComCMD = "LuaUI/Images/commchange/ComCMD.png"

-- commanders
local armauto = UnitDefNames["arm_commander"].id
local armman = UnitDefNames["arm_u0commander"].id
local coreauto = UnitDefNames["core_commander"].id
local coreman = UnitDefNames["core_u0commander"].id

-- sound
local bell = 'sounds/bell.ogg'
local beep = 'sounds/BEEP1.wav'
local tock = 'sounds/ticktock.wav'

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
local spGetSpectatingState = Spring.GetSpectatingState
local spGetTeamInfo = Spring.GetTeamInfo

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
	Button["arm"]["x0"] = px
	Button["arm"]["x1"] = px + sizex/4
	Button["arm"]["y0"] = py  + sizey - 24
	Button["arm"]["y1"] = py  + sizey
	
	Button["core"]["x0"] = px + sizex/4
	Button["core"]["x1"] = px + sizex/2
	Button["core"]["y0"] = py  + sizey - 24
	Button["core"]["y1"] = py  + sizey
	
	Button["ready"]["x0"] = px + sizex/2
	Button["ready"]["x1"] = px + 4*sizex/5
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
	Button["infopanel"]["x1"] = px + sizex + 1.5*sizex
	Button["infopanel"]["y0"] = py  + sizey - sizey
	Button["infopanel"]["y1"] = py  + sizey
	
	mid = px + sizex/2
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
	if pos >= 0 then
		if myState ~= 3 then 
			myState = 1
		else
			myState = 3
		end
	else
		myState = 0
	end
end

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------
function widget:Initialize()

    if spGetSpectatingState() or Spring.GetGameFrame() > 0 or (Spring.GetModOptions() or {}).comm ~= "choose" then
        widgetHandler:RemoveWidget(self)
    end
	local X, Y = Spring.GetViewGeometry()
	scale = Y/1024	
	-- side
	updateState()
	--position:
	px, py = px*scale, py*scale
	--sizes:
	sizex 		= sizex 	* scale
	sizey 		= sizey 	* scale
	--buttons:
	initButtons()
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
	
	local function drawBorder(x0, y0, x1, y1, width)
		glRect(x0, y0, x1, y0 + width)
		glRect(x0, y1, x1, y1 - width)
		glRect(x0, y0, x0 + width, y1)
		glRect(x1, y0, x1 - width, y1)
	end
	
	--CountDown
	if gameState == 1 then
		--UseFont(font)
		glColor(1, 1, 1, 1)
		glText(cntDown, vsx/2, vsy/2, 160, 'xsn')
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
		glText("info", Button["info"]["x0"] + 10 , Button["info"]["y0"] + 6 , 20,'x')
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
			glText(side .. ", " .. uptype .. ":", x0 + 10, y1 - 20, 20, 'xn')
			glText(txt1, x0 + 10, y1 - 60, 12, 'xn')
			glText(txt2, x0 + 10, y1 - 80, 12, 'xn')
			glText(txt3, x0 + 10, y1 - 100, 12, 'xn')
			glText(txt4, x0 + 10, y1 - 120, 12, 'xn')
			glText(txt5, x0 + 10, y1 - 140, 12, 'xn')
			
		end
		-- Panel
		glColor(0, 0, 0, 0.4)
		glRect(px,py, px+sizex, py+sizey)
		-- Highlight
		glColor(0.8, 0.8, 0.2, 0.5)
		if Button["arm"]["On"] then
			glRect(Button["arm"]["x0"],Button["arm"]["y0"], Button["arm"]["x1"], Button["arm"]["y1"])
		elseif Button["core"]["On"] then
			glRect(Button["core"]["x0"],Button["core"]["y0"], Button["core"]["x1"], Button["core"]["y1"])
		elseif Button["ready"]["On"] then
			glRect(Button["ready"]["x0"],Button["ready"]["y0"], Button["ready"]["x1"], Button["ready"]["y1"])
		elseif Button["info"]["On"] then
			glRect(Button["info"]["x0"],Button["info"]["y0"], Button["info"]["x1"], Button["info"]["y1"])
		end
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
		local y0 = vsy/2
		
		glText("Players:", 10, y0 + 20, 20, 'xn')
		for i,ps in pairs(pStates) do
			if ps == "missing" then
				local _,_,_,team = Spring.GetPlayerInfo(i)
				local posx = spGetTeamStartPosition(team)
				if posx < 0 then
					glColor(0.6, 0.6, 0.2, 1)
				else
					glColor(0.3, 0.6, 0.3, 1)
				end
			elseif ps == "ready" then
				glColor(0.7, 0.9, 0.7, 1)
			else
				glColor(0.6, 0.2, 0.2, 0.8)
			end
			local name = Spring.GetPlayerInfo(i)
			glText(name, 10, y0 - 20* i, 20, 'xn')
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
		lbl = "Ready"
	else -- can not ready, grey
		glColor(0.8, 0.8, 0.8, 0.5)
		lbl = ""
	end
	if lbl == "Ready" then
		drawBorder(Button["ready"]["x0"],Button["ready"]["y0"], Button["ready"]["x1"], Button["ready"]["y1"],1)
	end
	glText(lbl, Button["ready"]["x0"] + 20, Button["ready"]["y0"] + 6, 20, 'x')
	
	-- arm/core buttons
	if mySide == "arm" then
		glColor(1, 1, 1, 1)
	else
		glColor(1, 1, 1, 0.2)
	end
	glText("Arm", Button["arm"]["x0"] + 20, Button["arm"]["y0"] + 6, 20, 'x')
	if mySide == "core" then
		glColor(1, 1, 1, 1)
	else
		glColor(1, 1, 1, 0.2)
	end
	glText("Core", Button["core"]["x0"] + 20, Button["core"]["y0"] + 6, 20, 'x')
	
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
		glText("Automatic", px+sizex/4  , py + 10 , 14,'cx')
		glText("Manual", px+3*sizex/4  , py + 10 , 14,'cx')
	end
end

function widget:GameSetup(state, ready, playerStates)
	local strS = string.sub(state,1,6)
	local strN = string.sub(state,13,13)
	pStates = playerStates
	
	if strS == "Choose" then 
		gameState = 0
	else
		gameState = 1
		cntDown = strN
	end

	if myState == 0 then
		return true,false
	elseif myState == 3 then
		return true, true
	else
		return true,false
	end
end

function widget:MousePress(mx, my, mButton)
	-- Spectator check before any action
    if spGetSpectatingState() then
		widgetHandler:RemoveWidget(self)
        return false
    end

	if IsOnButton(mx,my, px,py, px+sizex, py+sizey) then
		-- Check buttons
		if mButton == 1 then
			local startID = spGetTeamRulesParam(myTeamID, 'startUnit')			
			if IsOnButton(mx,my,Button["arm"]["x0"],Button["arm"]["y0"],Button["arm"]["x1"],Button["arm"]["y1"]) then	
				if startID == coreauto or startID == coreman then
					if startID == coreauto then
						spSendLuaRulesMsg('\177' .. armauto)
					else
						spSendLuaRulesMsg('\177' .. armman)
					end
				end
			elseif IsOnButton(mx,my,Button["core"]["x0"],Button["core"]["y0"],Button["core"]["x1"],Button["core"]["y1"]) then	
				if startID == armauto or startID == armman then
					if startID == armauto then
						spSendLuaRulesMsg('\177' .. coreauto)
					else
						spSendLuaRulesMsg('\177' .. coreman)
					end
				end
			elseif IsOnButton(mx,my,Button["auto"]["x0"],Button["auto"]["y0"],Button["auto"]["x1"],Button["auto"]["y1"]) then
				if startID == armman or startID == coreman then
					if startID == armman then
						spSendLuaRulesMsg('\177' .. armauto)
					else
						spSendLuaRulesMsg('\177' .. coreauto)
					end
				end
			elseif IsOnButton(mx,my,Button["manual"]["x0"],Button["manual"]["y0"],Button["manual"]["x1"],Button["manual"]["y1"]) and myState ~= 3 then
				if startID == armauto or startID == coreauto then
					if startID == armauto then
						spSendLuaRulesMsg('\177' .. armman)
					else
						spSendLuaRulesMsg('\177' .. coreman)
					end
				end
			elseif IsOnButton(mx,my,Button["ready"]["x0"],Button["ready"]["y0"],Button["ready"]["x1"],Button["ready"]["y1"]) and myState ~= 3 then
				local pos = spGetTeamStartPosition(myTeamID)
				if pos >= 0 then
					if myState > 0 then myState = 3 end
				end
			elseif IsOnButton(mx,my,Button["info"]["x0"],Button["info"]["y0"],Button["info"]["x1"],Button["info"]["y1"]) and myState ~= 3 then
				if myState ~= 3 then
					infoOn = not infoOn
				end
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
	elseif IsOnButton(mx,my,Button["core"]["x0"],Button["core"]["y0"],Button["core"]["x1"],Button["core"]["y1"]) and mySide == "arm" then
		Button["arm"]["On"] = false
		Button["core"]["On"] = true
		Button["ready"]["On"] = false
		Button["info"]["On"] = false
	elseif IsOnButton(mx,my,Button["ready"]["x0"],Button["ready"]["y0"],Button["ready"]["x1"],Button["ready"]["y1"]) and myState > 0 then
		Button["arm"]["On"] = false
		Button["core"]["On"] = false
		Button["ready"]["On"] = true
		Button["info"]["On"] = false
	elseif IsOnButton(mx,my,Button["info"]["x0"],Button["info"]["y0"],Button["info"]["x1"],Button["info"]["y1"]) then
		Button["arm"]["On"] = false
		Button["core"]["On"] = false
		Button["ready"]["On"] = false
		Button["info"]["On"] = true
	else
		Button["arm"]["On"] = false
		Button["core"]["On"] = false
		Button["ready"]["On"] = false
		Button["info"]["On"] = false
	end
end

function widget:GameStart()
	Spring.PlaySoundFile(bell)
	Spring.PlaySoundFile(beep)
    widgetHandler:RemoveWidget(self)
end

function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY

end

function widget:GetConfigData()
	local vsx, vsy = gl.GetViewSizes()
	return {px / vsx, py / vsy}
end

function widget:SetConfigData(data)
	local vsx, vsy = gl.GetViewSizes()
	px = math.floor(math.max(0, vsx * math.min(data[1] or 0, 0.95)))
	py = math.floor(math.max(0, vsy * math.min(data[2] or 0, 0.95)))
end
