
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

--------------------------------------------------------------------------------
--IMAGES
--------------------------------------------------------------------------------

--commander selection
local imgComAA 				= "LuaUI/Images/commchange/ComAA.png" -- arm auto
local imgComAM 				= "LuaUI/Images/commchange/ComAM.png" -- arm manual
local imgComAAD 			= "LuaUI/Images/commchange/ComAAD.png" -- arm auto disabled
local imgComAMD 			= "LuaUI/Images/commchange/ComAMD.png" -- arm manual disabled
local imgComCA 				= "LuaUI/Images/commchange/ComCA.png" -- core auto
local imgComCM			 	= "LuaUI/Images/commchange/ComCM.png"
local imgComCAD 			= "LuaUI/Images/commchange/ComCAD.png" -- core auto disabled
local imgComCMD 			= "LuaUI/Images/commchange/ComCMD.png"

--countdown
local img3 					= "LuaUI/Images/commchange/3-cnt.png"
local img2 					= "LuaUI/Images/commchange/2-cnt.png"
local img1 					= "LuaUI/Images/commchange/1-cnt.png"
local img0 					= "LuaUI/Images/commchange/0-cnt.png"

--faction emblems
local imgARM 				= "LuaUI/Images/commchange/arm.png"
local imgCORE 				= "LuaUI/Images/commchange/core.png"

--other
local imgDuck				= "LuaUI/Images/commchange/duck.png"

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
local button1 = 'sounds/button1.wav'
local button2 = 'sounds/button2.wav'
local button3 = 'sounds/buttn01.wav'
local cancel = 'sounds/cancel2.wav'

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
local vsx, vsy 							= gl.GetViewSizes()
local scale
local px, py 							= 300, 300
local SIZEX, SIZEY  					= 320, 180 -- initial value before scaling
local mid 								= px + SIZEX/2
local sizex, sizey						-- values used after rescaling
local th 								= 16 -- text height for buttons
local th2 								= 11 -- text height for body text
local th3 								= 20 -- text height for player names
local n 								= 0 -- amount of players
local mySide, myType
local myState 							= 0
local gameState 						= 0
local gameStarted						= false
local cntDown 							= -1
local lastCount
local pStates							= {}
local markedStates 						= {}
local lastStartID
local strInfo							
local infoOn 							= false
local teamList							= Spring.GetTeamList()
local myTeamID 							= Spring.GetMyTeamID()
--gamestates
local CHOOSE,WAITING,COUNTDOWN,ERROR	= 0,1,2,-1
local gameOver							= false
-- local player states
local PRESENT,MARKED,OTHER,READY		= 0,1,2,3

--font
local myFont	 						= gl.LoadFont("FreeSansBold.otf",th3, 1.9, 40)
local myFontHuge						= gl.LoadFont("FreeSansBold.otf",60, 1.9, 40)

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local GetTeamList					= Spring.GetTeamList
local glTexCoord					= gl.TexCoord
local glVertex 						= gl.Vertex
local glColor 						= gl.Color
local glRect						= gl.Rect
local glTexture 					= gl.Texture
local glTexRect 					= gl.TexRect
local glDepthTest 					= gl.DepthTest
local glBeginEnd 					= gl.BeginEnd
local GL_QUADS 						= GL.QUADS
local Echo 							= Spring.Echo
local spectator 					= Spring.GetSpectatingState()
local spGetTeamStartPosition 		= Spring.GetTeamStartPosition
local spGetTeamRulesParam 			= Spring.GetTeamRulesParam
local spGetGroundHeight	 			= Spring.GetGroundHeight
local spSendLuaRulesMsg 			= Spring.SendLuaRulesMsg
local spSendLuaUIMsg 				= Spring.SendLuaUIMsg
local GetTeamInfo 					= Spring.GetTeamInfo
local PlaySoundFile 				= Spring.PlaySoundFile
local IsGUIHidden					= Spring.IsGUIHidden
local GetPlayerInfo					= Spring.GetPlayerInfo
local GetPlayerList					= Spring.GetPlayerList
local GetAllyTeamList				= Spring.GetAllyTeamList
local GetAIInfo						= Spring.GetAIInfo
local max, min 						= math.max, math.min
local newSide		  				= {}

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
	if myState ~= READY then
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
		if myState ~= READY then 
			myState = MARKED
		else
			myState = READY
		end
	else
		myState = PRESENT
	end
end

local function updateSize()
	-- update size for spectators
	if spectator then
		n = #(teamList)-1
		sizex = 380
		sizey = 50 + 20 * (n+2) -- add extra free row
	end
	
	if Spring.IsReplay() then
		n = 0
		for i, pID in pairs(Spring.GetPlayerList()) do
			local _,_,isSpec = Spring.GetPlayerInfo(pID)
			if not isSpec then
				if not pStates[pID] then
					pStates[pID] = "missing"
				end
				n = n + 1
			end
		end
		
		sizex = 380
		sizey = 80 + 20 * (n+2) -- add extra free row
	end
	--buttons:
	initButtons()
end

local function playSound(snd)
	PlaySoundFile(snd)
end

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------
function widget:Initialize()

    if Spring.GetGameFrame() > 0 or (Spring.GetModOptions() or {}).commander ~= "choose" then
        widgetHandler:RemoveWidget(self)
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
	
	updateState()
	
	--marked states
	for i,player in ipairs(teamList) do
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
	else -- set manual commander as default for newbies
		mySide = (mySide or select(5,Spring.GetTeamInfo(myTeamID))) or "arm"
		if mySide == "arm" then
			spSendLuaRulesMsg('\177' .. armman)
			spSendLuaUIMsg('195' .. 1)
			lastStartID = armman
		elseif mySide == "core" then
			spSendLuaRulesMsg('\177' .. coreman)
			spSendLuaUIMsg('195' .. 2)
			lastStartID = coreman
		end	
	end
	updateSize()
end

function widget:RecvLuaMsg(msg, playerID)
	local STATEMSG = "181072"
	local SIDEMSG = '195' -- set by this widget gui_commchange.lua
		
	if (msg:sub(1,#STATEMSG) ~= STATEMSG) or (msg:sub(1,#SIDEMSG) ~= SIDEMSG)  then --invalid message
		return
	end
	
	if msg and string.len(msg) >= 8 then	
		local sms = string.sub(msg, string.len(STATEMSG)+1) 
		local state = tonumber(string.sub(sms,1,1))
		local player = tonumber(string.sub(sms,2))
		
		if player then
			if state == 0 then
				markedStates[player+1] = false
			elseif state == 1 then
				markedStates[player+1] = true
			end
		end
	elseif msg and string.len(msg) == 4 then
		local sms = msg:sub(SIDEMSG:len()+1) 
		local side = tonumber(sms:sub(1,1))
		local _, _,_, playerTeam = GetPlayerInfo(playerID)
			
		if side == 1 then
			newSide[playerTeam] = 1
		elseif side == 2 then
			newSide[playerTeam] = 2
		end
	end
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
end

function widget:DrawWorld()
	if IsGUIHidden() or gameStarted then return end
	
	if not spectator then
		checkState()
		updateState()
	end
	
	glColor(1, 1, 1, 0.5)
    glDepthTest(false)
    for i = 1, #teamList do
        local teamID = teamList[i]
        local tsx, tsy, tsz = spGetTeamStartPosition(teamID)
        if tsx and tsx > 0 then
			local _,_,_,_,teamside = GetTeamInfo(teamID)
			
			if newSide[teamID] and newSide[teamID] > 0 then
				if newSide[teamID] == 1 then
					teamside = "arm"
				elseif newSide[teamID] == 2 then
					teamside = "core"
				end
			end
			
            if teamside == "arm" then
                glTexture(imgARM)
                glBeginEnd(GL_QUADS, QuadVerts, tsx, spGetGroundHeight(tsx, tsz), tsz, 80)
				glTexture(false)
            else 
                glTexture(imgCORE)
                glBeginEnd(GL_QUADS, QuadVerts, tsx, spGetGroundHeight(tsx, tsz), tsz, 64)
				glTexture(false)
            end
        end
    end
    glTexture(false)
	
end

local function drawBorder(x0, y0, x1, y1, width)
	glRect(x0, y0, x1, y0 + width)
	glRect(x0, y1, x1, y1 - width)
	glRect(x0, y0, x0 + width, y1)
	glRect(x1, y0, x1 - width, y1)
end

function widget:DrawScreenEffects(vsx, vsy)
	if IsGUIHidden() then return end
	
	if not gameStarted and not gameOver then
		local h = vsy/3
		local x = vsx/2 - h/2
		local y = vsy/2 - h/2
		local x1 = x + h
		local y1 = y + h
		
		--CountDown
		if gameState == COUNTDOWN and not Spring.IsReplay() then
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
				Echo(cntDown)
			end
			
			glTexRect(x,y,x1,y1)
			glTexture(false)
			glColor(1, 1, 1, 1)
			
			if cntDown ~= lastCount then
				PlaySoundFile(tock)
				lastCount = cntDown
			end
		end
		
		if myState ~= READY then
			if not spectator then
				-- Infobutton
				glTexture(false)
				glColor(1, 1, 1, 1)
				drawBorder(Button["info"]["x0"],Button["info"]["y0"],Button["info"]["x1"],Button["info"]["y1"],1)
				myFont:Begin()
				if infoOn then
					myFont:SetTextColor({1, 1, 1, 1})
				else
					myFont:SetTextColor({0.8, 0.8, 0.8, 1})
				end
				myFont:Print("info", 0.5 * (Button["info"]["x0"] + Button["info"]["x1"]) , 0.5 * (Button["info"]["y0"] + Button["info"]["y1"]) , th,'vcs')
				myFont:End()
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
					local txt
					local side
					local uptype
					if mySide == "arm" then
						side = "Arm"
						if myType == "auto" then
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
					else
						side = "Core"
						if myType == "auto" then
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
					end
					local xofs, thofs = x0+10, th2+6
					myFont:Begin()
						myFont:Print(side .. " commander with " .. uptype .. ":", xofs, y1 - thofs, th, 'xn')
						for i=1, #txt do
							myFont:Print(txt[i], xofs, y1 - (i+2)*thofs, th2, 'xn')
						end
					myFont:End()
				end
			end
			
			if gameState ~= COUNTDOWN or Spring.IsReplay() then -- replay has countdown before everything
				-- Panel
				glColor(0, 0, 0, 0.4)
				glRect(px,py, px+sizex, py+sizey)
				glColor(1,1,1,1)
			end
		end
		
		-- Highlight
		glColor(0.8, 0.8, 0.2, 0.5)
		if Button["arm"]["On"] then
			glRect(Button["arm"]["x0"],Button["arm"]["y0"], Button["arm"]["x1"], Button["arm"]["y1"])
		elseif Button["core"]["On"] then
			glRect(Button["core"]["x0"],Button["core"]["y0"], Button["core"]["x1"], Button["core"]["y1"])
		elseif Button["ready"]["On"] then
			glRect(Button["ready"]["x0"],Button["ready"]["y0"], Button["ready"]["x1"], Button["ready"]["y1"])
		elseif Button["info"]["On"] and myState ~= READY then
			glRect(Button["info"]["x0"],Button["info"]["y0"], Button["info"]["x1"], Button["info"]["y1"])
		elseif Button["exit"]["On"] then
			glRect(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
		elseif Button["duck"]["On"] then
			glRect(Button["duck"]["x0"],Button["duck"]["y0"], Button["duck"]["x1"], Button["duck"]["y1"])
		end
		glColor(1,1,1,1)
	elseif not gameOver then
		-- game started text
		if Spring.IsReplay() or spectator then
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
	if IsGUIHidden() or gameStarted then return end
	
	local function firstToUpper(str)
		return (str:gsub("^%l", string.upper))
	end	
	
	local startID = spGetTeamRulesParam(myTeamID, 'startUnit')
	-- Draw list with player connection and ready up states
	myFont:Begin()
	if pStates then
		local n = 0
		for _,_ in pairs(pStates) do
			n = n + 1
		end
		local y0 = 40 + 0.5*(vsy + n*th3)
		
		myFont:SetTextColor({1,1,1,1})
		myFont:Print("Players:", 10, y0 + th3+2, th3, 'xns')
		myFont:End()
		
		for i,ps in pairs(pStates) do
			local leaderName,active,spec,team,_,_,_,country,rank	= GetPlayerInfo(i)
			if not spec then
				myFont:Begin()
				if not active then
					myFont:SetTextColor({0.6, 0.2, 0.2, 0.8}) -- red
				else
					if ps == "missing" then
						if Spring.IsReplay() then
							local posx = spGetTeamStartPosition(team)
							if not posx or posx < 0 then
								if markedStates and markedStates[i+1] then
									myFont:SetTextColor({0.3, 0.5, 0.7, 1}) -- blue
								else
									myFont:SetTextColor({0.6, 0.6, 0.2, 1}) -- yellow
								end
							else
								myFont:SetTextColor({0.3, 0.5, 0.7, 1}) -- blue
							end
						else
							myFont:SetTextColor({0.6, 0.2, 0.2, 0.8}) -- red
						end
					elseif ps == "notready" then
						local posx = spGetTeamStartPosition(team)
						if not posx or posx < 0 then
							if markedStates and markedStates[i+1] then
								myFont:SetTextColor({0.3, 0.5, 0.7, 1}) -- blue
							else
								myFont:SetTextColor({0.6, 0.6, 0.2, 1}) -- yellow
							end
						else
							myFont:SetTextColor({0.3, 0.5, 0.7, 1}) -- blue
						end
					elseif ps == "ready" then
						myFont:SetTextColor({0.0, 0.5, 0.0, 1}) -- green -- glColor(0.7, 0.9, 0.7, 1) -- white/green
					else
						myFont:SetTextColor({0.5, 0.5, 0.5, 0.8}) -- grey -- glColor(0.7, 0.9, 0.7, 1) -- white/green
					end
				end
				myFont:Print(leaderName, 25, y0 - (th3+2)* i, th3, 'xno')
				myFont:End()
				glColor(0.4,0.4,0.4,1)
				glTexture("LuaUI/Images/commchange/C-Rank" .. rank ..".png")
				glTexRect(10, y0 - (th3+2)* i, 22, y0 - (th3+2)* i+12)
				glTexture (false)
			else
				myFont:Begin()
				if not active or ps == "missing" then
					if Spring.IsReplay() then
						myFont:SetTextColor({0.6, 0.6, 0.2, 1}) -- yellow
					else
						myFont:SetTextColor({0.6, 0.2, 0.2, 0.8}) -- red
					end
				else
					myFont:SetTextColor({0.5, 0.5, 0.5, 0.8}) -- grey 
				end
				myFont:Print(leaderName .. " (s)", 25, y0 - (th3+2)* i, th3, 'xno')
				myFont:End()
			end
		end
	end
	glColor(1,1,1,1)
	
	-- Draw window with info for spectators
	if spectator and not gameOver then
		
		-- duck button
		glColor(0, 0, 0, 0.4)
		glRect(Button["duck"]["x0"],Button["duck"]["y0"], Button["duck"]["x1"], Button["duck"]["y1"])
		glColor(0, 0, 0, 1)
		drawBorder(Button["duck"]["x0"],Button["duck"]["y0"], Button["duck"]["x1"], Button["duck"]["y1"],1)
		
		myFont:Begin()
		-- spectator info label
		glColor(0, 0, 0, 0.4)
		glRect(Button["speclabel"]["x0"],Button["speclabel"]["y0"], Button["speclabel"]["x1"], Button["speclabel"]["y1"])
		myFont:SetTextColor({1, 1, 1, 1})
		
		myFont:Print("Info for spectators", Button["speclabel"]["x0"] + 78 ,Button["speclabel"]["y0"] + 10, th, 'xs')
		
		--exit button
		glColor(0, 0, 0, 0.4)
		glRect(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
		glColor(0, 0, 0, 1)
		drawBorder(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"],1)
		glColor(1, 1, 1, 1)
		myFont:SetTextColor({1, 1, 1, 1})
		myFont:Print("X", Button["exit"]["x0"] + 10 ,Button["exit"]["y0"] + 10, 20, 'xs')
		myFont:End()
		
		-- textures
		local fr = 3 -- frame
		glColor(1, 1, 1, 1)
		glTexture(imgDuck)
		glTexRect(Button["duck"]["x0"]+fr,Button["duck"]["y0"]+fr, Button["duck"]["x1"]-fr, Button["duck"]["y1"]-fr)
		glTexture(false)
		
		--player states billboard
		-- x-size = [0,320]
		local x0 		= px + 8
		local y0 		= Button["speclabel"]["y0"] - 20
		local rh 		= 15 -- row height
		local th4 		= th2
		local col_0 	= x0 		-- team #
		local col_1 	= x0 + 20	-- faction symbol
		local col_2 	= x0 + 40	-- commander type 
		local col_3 	= x0 + 80	-- player rank
		local col_4 	= x0 + 100	-- leader name
		local col_5 	= x0 + 240	-- status text
		local col_6 	= x0 + 300	-- remarks
		local col_7 	= x0 + 310	-- for future use
		local commside	= "arm"
		local commtype	= "AT"
		local prevposy = y0 - 14
		
		if gameState ~= COUNTDOWN or Spring.IsReplay() then
			--labels
			myFont:Begin()
			myFont:SetTextColor({0.6, 0.6, 0.8, 1})
			myFont:Print("Team", 		col_0, y0 - 10, th4, 'xo')
			myFont:Print("Player", 	col_4, y0 - 10, th4, 'xo')
			myFont:Print("Status",	col_5, y0 - 10, th4, 'xo')
			--myFont:Print("Remarks",	col_6, y0 - 10, th4, 'x')
			
			-- Game state info label
			myFont:SetTextColor({1, 1, 1, 1})
			local txt = (Spring.IsReplay() and "Waiting for replay to start...") or (strInfo or "")
			
			myFont:Print("Status: " .. txt, Button["specinfo"]["x0"] + 10 ,Button["specinfo"]["y0"] + 5, 11, 'xo')
			myFont:End()
			
			--player data
			local as = 0 -- ally separation space
			
			for _, aID in pairs(GetAllyTeamList()) do
				as = 8
				-- draw line between allies
				glColor(0.1, 0.1, 0.1, 0.3)
				glRect(col_0, prevposy - 7, col_6, prevposy - 8)
				glColor(0.4, 0.4, 0.4, 0.3)
				glRect(col_0, prevposy - 8, col_6, prevposy - 9)
				local newteam = true
				
				for i, tID in pairs(GetTeamList(aID)) do
					
					local y1 		= prevposy - as - rh
					prevposy		= y1
					as = 0
					
					local _,leaderID,_,isAI,_,allyID = GetTeamInfo(tID)
					local leaderName,active,spec,team,allyteam,_,_,country,rank	= GetPlayerInfo(leaderID)
					local aiID, aiName, aiHostID, aiShortName = GetAIInfo(tID)
					local isComShare = false
					local pCount = 0
					for _, pID in pairs (GetPlayerList(tID)) do
						local lName,_,isSspec = GetPlayerInfo(pID)
						if isSpec == false then 
							pCount = pCount + 1 
						end
					end
					
					if pCount > 1 then isComShare = true end
					
					if isAI then leaderName = "AI: "..aiShortName end
					if isComShare then leaderName = leaderName .. "+" end
					
					if tID ~= Spring.GetGaiaTeamID() then
						local marked = markedStates[i]
						local startID = spGetTeamRulesParam(tID, 'startUnit')
						local ps = tostring(pStates[leaderID] or "?")
						
						if startID == armauto then
							commside = 'arm'
							commtype = 'AT'
						elseif startID == armman then
							commside = 'arm'
							commtype = 'M'
						elseif startID == coreauto then
							commside = 'core'
							commtype = 'AT'
						elseif startID == coreman then
							commside = 'core'
							commtype = 'M'
						else
							commside = '?'
							commtype = '?'
						end
						
						myFont:Begin()
						--data
						myFont:SetTextColor({1, 1, 1, 1})
						if isAI then
							myFont:SetTextColor({0.8, 0.8, 0.8, 0.8})
						end
						if newteam then
							myFont:Print(allyID,	 		col_0, y1, th4, 'xo')
						end
						newteam = false
						--side
						if commside == 'arm' then
							glTexture(imgARM)
						elseif commside == 'core' then
							glTexture(imgCORE)
						else
							glTexture(img0)
						end
						glColor(1, 1, 1, 0.8)
						glTexRect(					col_1, y1 - 5, col_1 + 15, y1 - 5 + 15)
						glColor(1, 1, 1, 1)
						glTexture(false)
						myFont:Print(commtype, 			col_2, y1, th4, 'xo')
						
						--rank
						if not spec then
							glColor(0.7, 0.7, 0.9, 0.8)
							glTexture("LuaUI/Images/commchange/C-Rank" .. rank ..".png")
							glTexRect(				col_3, y1 - 2, col_3 + 14, y1 - 2 + 14)
							glTexture(false)
							glColor(1, 1, 1, 1)
						end
						--name
						myFont:Print(tostring(leaderName),col_4, y1, th4, 'xo')
						-- status and remarks
						local statustext, remarks
						local posx = spGetTeamStartPosition(tID)
						
						if not active then
							statustext = "Missing"
							myFont:SetTextColor({0.6, 0.2, 0.2, 0.8}) -- red
						elseif ps == 'missing' then
							if Spring.IsReplay() then
								if posx and posx > 0 or marked then
									statustext = "Marked"
									myFont:SetTextColor({0.3, 0.5, 0.7, 1}) -- blue
								else									
									statustext = "Warming up ..."
									myFont:SetTextColor({0.6, 0.6, 0.2, 1}) -- yellow
								end
							else
								statustext = "Missing"
								myFont:SetTextColor({0.6, 0.2, 0.2, 0.8}) -- red
							end
						elseif ps == 'notready' then
							if posx and posx > 0 or marked then
								statustext = "Marked"
								myFont:SetTextColor({0.3, 0.5, 0.7, 1}) -- blue
							else									
								statustext = "Warming up ..."
								myFont:SetTextColor({0.6, 0.6, 0.2, 1}) -- yellow
							end
						elseif ps == 'ready' then
							statustext = "Ready"
							myFont:SetTextColor({0.0, 0.5, 0.0, 1}) -- green
						else
							statustext = firstToUpper(ps)
							myFont:SetTextColor({0.5, 0.5, 0.5, 0.8}) -- grey
						end
						myFont:Print(statustext,			col_5, y1, th4, 'xo')
						myFont:SetTextColor({1,1,1,1})
						myFont:End()
						glColor(1, 1, 1, 1)
						if isAI then
							remarks = "AI"
						else
							if leaderName == "[2up]knorke" then
								remarks = "TP"
							else
								remarks = country
							end
						end						
					end
				end
			end
		end
		glColor(1,1,1,1)
	elseif not gameOver then
		-- draw window with options for active players
		
		-- border
		glColor(1, 1, 1, 1)
		drawBorder(Button["arm"]["x0"],Button["arm"]["y0"], Button["arm"]["x1"], Button["arm"]["y1"],1)
		drawBorder(Button["core"]["x0"],Button["core"]["y0"], Button["core"]["x1"], Button["core"]["y1"],1)
		
		myFont:Begin()
		-- Ready button
		local lbl
		if myState == MARKED then -- green
			myFont:SetTextColor({0.5, 1, 0.5, 1})
			lbl = "Ready"
		elseif myState == OTHER then -- red
			myFont:SetTextColor({1.0, 0.5, 0.5, 1})
			lbl = "Ready"
		elseif myState == READY then -- white
			myFont:SetTextColor({1, 1, 1, 1})
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
		glColor(0, 0, 0, 0.4)
		glRect(Button["infolabel"]["x0"],Button["infolabel"]["y0"], Button["infolabel"]["x1"], Button["infolabel"]["y1"])
		drawBorder(Button["infolabel"]["x0"],Button["infolabel"]["y0"], Button["infolabel"]["x1"], Button["infolabel"]["y1"],1)
		glColor(1, 1, 1, 1)
		local txt = strInfo or "..."
		
		if myState == PRESENT then
			txt = strInfo .. " (click to change Commander)"
		elseif myState == MARKED then
			txt = "Press ready (or click to change Commander)"
		elseif myState == OTHER then
			txt = "Press ready..."
		elseif myState == READY then
			if gameState ~= COUNTDOWN then
				txt = strInfo
			else
				txt = strInfo
			end
		end
		myFont:SetTextColor({1,1,1,1})
		myFont:Print(txt, Button["infolabel"]["x0"] + 10 ,Button["infolabel"]["y0"] + 10 , th2, 'ds')
		
		--exit button
		glColor(0, 0, 0, 0.4)
		glRect(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
		glColor(0, 0, 0, 1)
		drawBorder(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"],1)
		myFont:SetTextColor({1, 1, 1, 1})
		myFont:Print("X", Button["exit"]["x0"] + 10 ,Button["exit"]["y0"] + 10 , 20, 'xs')
		
		-- arm/core buttons
		if mySide == "arm" then
			myFont:SetTextColor({1, 1, 1, 1})
		else
			myFont:SetTextColor({0.8, 0.8, 0.8, 0.4})
		end
		myFont:Print("Arm", 0.5*(Button["arm"]["x0"] + Button["arm"]["x1"]), 0.5 * (Button["arm"]["y0"] + Button["arm"]["y1"]), th, 'vcs')
		if mySide == "core" then
			myFont:SetTextColor({1, 1, 1, 1})
		else
			myFont:SetTextColor({0.8, 0.8, 0.8, 0.4})
		end
		myFont:Print("Core", 0.5* (Button["core"]["x0"] + Button["core"]["x1"]), 0.5 * (Button["core"]["y0"] + Button["core"]["y1"]), th, 'vcs')
		
		myFont:SetTextColor({1, 1, 1, 1})
		
		if myState ~= READY then
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
				glTexture(false)
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
				glTexture(false)
			end
			--commander text
			myFont:SetTextColor({1, 1, 1, 1})
			myFont:Print("Automatic", px+sizex/4  , py + 10 , (th-2),'cxs')
			myFont:Print("Manual", px+3*sizex/4  , py + 10 , (th-2),'cxs')
		end
		myFont:End()
		glColor(1,1,1,1)
	end
	glColor(1,1,1,1)
end

function widget:GameSetup(state, ready, playerStates)
	local strS = string.sub(state,1,6)
	local strN = string.sub(state,13,13)
	pStates = playerStates
	strInfo = state
	
	if not gameOver then
		if strS == "Choose" then 
			gameState = CHOOSE -- gamestate == 0
		elseif strS == "Waitin" then
			gameState = WAITING -- gamestate == 1
		elseif strS == "Starti" then
			gameState = COUNTDOWN -- gamestate == 2
			cntDown = strN
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

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY
end

function widget:MousePress(mx, my, mButton)
	if not gameOver and not gameStarted then
		if spectator  then
			if mButton == 1 then
				if IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
					widgetHandler:RemoveWidget(self)
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
			updateState()
			initButtons()
		else -- player
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
							playSound(button3)
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
							playSound(button3)
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
							playSound(button2)
						end
					elseif IsOnButton(mx,my,Button["manual"]["x0"],Button["manual"]["y0"],Button["manual"]["x1"],Button["manual"]["y1"]) and myState ~= READY then
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
							playSound(button2)
						end
					elseif IsOnButton(mx,my,Button["ready"]["x0"],Button["ready"]["y0"],Button["ready"]["x1"],Button["ready"]["y1"]) and gameState ~= COUNTDOWN then
						local pos = spGetTeamStartPosition(myTeamID)
						if pos >= 0 then
							if myState ~= READY then 
								myState = READY
							elseif myState == READY then
								myState = MARKED
							end
							playSound(button1)
						end
					elseif IsOnButton(mx,my,Button["info"]["x0"],Button["info"]["y0"],Button["info"]["x1"],Button["info"]["y1"]) and myState ~= READY then
						if myState ~= READY then
							infoOn = not infoOn
							if infoOn then
								playSound(button)
							else
								playSound(cancel)
							end
						end
					elseif IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
						widgetHandler:RemoveWidget(self)
						Echo("Exit to native dialogue window.")
						playSound(cancel)
						return true
					end
					updateState()
					return true
				elseif (mButton == 2 or mButton == 3) and mx < px + sizex then
					if mx >= px and my >= py and my < Button["exit"]["y1"] then
						-- Dragging
						return true
					end
				end
				updateState()
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
		px = max(0, min(px+dx, vsx-sizex))	--prevent moving off screen
		py = max(0, min(py+dy, vsy-sizey))
		initButtons()
    end
	
end

function widget:IsAbove(mx,my)
	if not gameOver then	
		if spectator and not gameStarted then
			Button["arm"]["On"] = false
			Button["core"]["On"] = false
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
			elseif IsOnButton(mx,my,Button["ready"]["x0"],Button["ready"]["y0"],Button["ready"]["x1"],Button["ready"]["y1"]) and myState > PRESENT and gameState ~= COUNTDOWN then
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
	end
end

function widget:GameFrame(frame)
	if frame > 240 then
		widgetHandler:RemoveWidget()
	end
end

function widget:GameStart()
	PlaySoundFile(bell,4.0,0,0,0,0,0,0,'userinterface')
	if not spectator then
		PlaySoundFile(beep,4.0,0,0,0,0,0,0,'unitreply')
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
	px = math.floor(max(0, vsx * min(data[1] or 0, 0.95)))
	py = math.floor(max(0, vsy * min(data[2] or 0, 0.95)))
	lastStartID = data.lastStartID or lastStartID
end
