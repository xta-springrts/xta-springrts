function widget:GetInfo()
	return {
		name    = "Simple menu",
		desc    = "Show a simple menu button",
		author  = "Jools",
		date    = "Oct, 2014",
		license = "Public domain",
		layer   = 0,
		enabled = true
	}
end

local Echo 							= Spring.Echo
local myFontBig	 					= gl.LoadFont("FreeSansBold.otf",14, 1.9, 40)
local myFont	 					= gl.LoadFont("FreeSansBold.otf",12, 1.9, 40)
local sizex, sizey					= 200, 300
local vsx, vsy 						= gl.GetViewSizes()
local posX, posY					= vsx/2, vsy/2
local rowgap						= 27
local rowheight						= 26
local margin						= 20
local myTeamID						= nil
local myAllyTeamID					= nil
local mySpectatorState				= Spring.GetSpectatingState()

local Button						= {}
local ButtonMenu					= {}
ButtonMenu.click					= false
local Panel							= {}
local glColor 						= gl.Color
local glRect						= gl.Rect
local glTexture 					= gl.Texture
local glTexRect 					= gl.TexRect
local PlaySoundFile 				= Spring.PlaySoundFile



-- colors
local cLight						= {0.8, 0.8, 0.2, 0.3}
local cSelect						= {0.8, 0.8, 0.8, 0.5}
local cWhite						= {1, 1, 1, 1}
local cBorder						= {0.2, 0.2, 0.2, 0.5}		
local cBack							= {0, 0, 0, 0.3}
local cTitle						= {0.8, 0.8, 1.0, 1}
local cPanel						= {0.2, 0.2, 0.2, 0.4}
local cShadow						= {0.6, 0.6, 0.6, 0.6}
local cDisabled						= {0.4, 0.4, 0.4, 1.0}

--sounds
local button6						= "sounds/button6.wav"
local button8						= "sounds/button8.wav"

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY

end

local function InitButtons()
	local L1 = 28	-- rowheight
	local L3 = 20   -- buttonheight
	local L2 = 100  -- button width
	
	Button[7].disabled 				= mySpectatorState
	
	for i,button in ipairs(Button) do
		button["x1"] 	= posX + margin
		button["x2"]	= posX + sizex - margin
		button["y1"]	= posY + sizey - 2*rowheight - i*rowgap
		button["y2"]	= button.y1 + rowheight
		button["above"] = false
		button["click"] = false
	end
	
	Panel["main"]["x1"]			= posX
	Panel["main"]["x2"]			= posX + sizex
	Panel["main"]["y1"]			= posY
	Panel["main"]["y2"]			= posY + sizey
	
end

function widget:Initialize()
	myTeamID = Spring.GetLocalTeamID()
	myAllyTeamID = select(6,Spring.GetTeamInfo(myTeamID))
	ButtonMenu.x1					= vsx - 40
	ButtonMenu.x2					= vsx
	ButtonMenu.y1					= vsy - 30
	ButtonMenu.y2					= vsy
	
	
	Button[1] 						= {} -- resume
	Button[1]["command"]			= "resume"
	Button[1]["label"]				= "Return to game"
	
	Button[2] 						= {} -- options
	Button[2]["command"]			= "opt"
	Button[2]["label"]				= "Game settings"
	
	Button[3] 						= {} -- energyview
	Button[3]["command"]			= "energy"
	Button[3]["label"]				= "Energy overview"
	
	Button[4] 						= {} -- modopt
	Button[4]["command"]			= "modopt"
	Button[4]["label"]				= "View mod-options"
	
	Button[5] 						= {} -- modopt
	Button[5]["command"]			= "mapopt"
	Button[5]["label"]				= "View map-options"
		
	Button[6] 						= {} -- widget
	Button[6]["command"]			= "widget"
	Button[6]["label"]				= "Widget selector"
	
	Button[7] 						= {} -- propose draw
	Button[7]["command"]			= "offer-draw"
	Button[7]["label"]				= "Offer draw"
	Button[7].disabled 				= mySpectatorState
	
	Button[8] 						= {} -- vote for surrender
	Button[8]["command"]			= "vote-end"
	Button[8]["label"]				= "Accept surrender"
	Button[8].disabled 				= true
	
	Button[9] 						= {} -- quit
	Button[9]["command"]			= "quit"
	Button[9]["label"]				= "Quit game"
	
	Button["close"] 				= {}
	Panel["main"]					= {}
	InitButtons()
		
end

local function DrawMenu()
	
	--background panel
	gl.Color(cBack)
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"])
	
	--border
	gl.Color(cBorder)
	gl.Rect(Panel["main"]["x1"]-1,Panel["main"]["y1"], Panel["main"]["x1"], Panel["main"]["y2"])
	gl.Rect(Panel["main"]["x2"],Panel["main"]["y1"], Panel["main"]["x2"]+1, Panel["main"]["y2"])
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y1"]-1, Panel["main"]["x2"], Panel["main"]["y1"])
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y2"], Panel["main"]["x2"], Panel["main"]["y2"]+1)
	
	-- Heading
	myFontBig:SetTextColor(cTitle)
	myFontBig:Begin()
	myFontBig:Print("XTA simple game menu:", Panel["main"]["x1"] + margin, Panel["main"]["y2"] - 20,14,'ds')
	myFontBig:End()
	
	-- Buttons
	for _,button in ipairs(Button) do
		myFont:Begin()
		if button["disabled"] then
			myFont:SetTextColor(cDisabled)
			gl.Color(cPanel)
		elseif button["above"] then
			myFont:SetTextColor(cWhite)
			gl.Color(cLight)
		else
			myFont:SetTextColor(cWhite)
			gl.Color(cPanel)
		end
		gl.Rect(button.x1,button.y1,button.x2,button.y2)
		myFont:Print(button["label"] or "N/A", button.x1+margin, (button.y1+button.y2)/2,12,'vs')
		myFont:End()
		
	end
		
	--reset state
	gl.Texture(false)
	gl.Color(1,1,1,1)
end

local function ButtonHandler (cmd)
	if cmd == "resume" then
		ButtonMenu.click = false
		PlaySoundFile(button6)
	elseif cmd == "opt" then
		ButtonMenu.click = false
		Spring.SendCommands("xta-options")
		PlaySoundFile(button8)
	elseif cmd == "energy" then
		ButtonMenu.click = false
		Spring.SendCommands("energy-overview")
		PlaySoundFile(button8)
	elseif cmd == "modopt" then
		ButtonMenu.click = false
		Spring.SendCommands("show-modoptions")
		PlaySoundFile(button8)
	elseif cmd == "mapopt" then
		ButtonMenu.click = false
		Spring.SendCommands("show-mapoptions")
		PlaySoundFile(button8)
	elseif cmd == "widget" then
		ButtonMenu.click = false
		Spring.SendCommands("selector")
		PlaySoundFile(button8)
	elseif cmd == "quit" then
		ButtonMenu.click = false
		Spring.SendCommands("quitmenu")
		PlaySoundFile(button8)
	elseif cmd == "offer-draw" then
		ButtonMenu.click = false
		Spring.SendCommands("luarules votefordraw")
		PlaySoundFile(button8)
	elseif cmd == "vote-end" then
		ButtonMenu.click = false
		Spring.SendCommands("luarules voteforend")
		PlaySoundFile(button8)
	else
		Echo("Local command:",cmd)
		ButtonMenu.click = false
	end
end

function widget:DrawScreen()
		
	-- draw menu button
	if ButtonMenu.above then
		glColor(cLight)
	elseif ButtonMenu.click then
		glColor(cSelect)
	else
		glColor(cBack)
	end
	glRect(ButtonMenu.x1,ButtonMenu.y1,ButtonMenu.x2,ButtonMenu.y2)
	
	glColor(cPanel)
	local mg = 10
	-- draw three stripes to symbolise menu drawer
	glRect(ButtonMenu.x1+mg,ButtonMenu.y2 - 11,ButtonMenu.x2-mg,ButtonMenu.y2 - 13)
	glRect(ButtonMenu.x1+mg,ButtonMenu.y2 - 16,ButtonMenu.x2-mg,ButtonMenu.y2 - 18)
	glRect(ButtonMenu.x1+mg,ButtonMenu.y2 - 21,ButtonMenu.x2-mg,ButtonMenu.y2 - 23)
	glColor(cShadow)
	glRect(ButtonMenu.x1+mg,ButtonMenu.y2 - 13,ButtonMenu.x2-mg,ButtonMenu.y2 - 14)
	glRect(ButtonMenu.x1+mg,ButtonMenu.y2 - 18,ButtonMenu.x2-mg,ButtonMenu.y2 - 19)
	glRect(ButtonMenu.x1+mg,ButtonMenu.y2 - 23,ButtonMenu.x2-mg,ButtonMenu.y2 - 24)
	
	--menu border
	glColor(cShadow)
	glRect(ButtonMenu.x1,ButtonMenu.y1,ButtonMenu.x1+1,ButtonMenu.y2)
	glRect(ButtonMenu.x2-1,ButtonMenu.y1,ButtonMenu.x2,ButtonMenu.y2)
	glRect(ButtonMenu.x1,ButtonMenu.y1,ButtonMenu.x2,ButtonMenu.y1+1)
	glRect(ButtonMenu.x1,ButtonMenu.y2-1,ButtonMenu.x2,ButtonMenu.y2)
	
	-- draw menu
	if (not Spring.IsGUIHidden()) and ButtonMenu.click then
		DrawMenu()
	end
end

function widget:MousePress(mx, my, mButton)
	if not Spring.IsGUIHidden() then
		
		if mButton == 1 then
			if IsOnButton(mx, my, ButtonMenu["x1"],ButtonMenu["y1"],ButtonMenu["x2"],ButtonMenu["y2"]) then
				ButtonMenu.click = true
				PlaySoundFile(button6)
				
				mySpectatorState = Spring.GetSpectatingState()
				local canVoteTeam = Spring.GetGameRulesParam("VotingAllyID")
			
				if not mySpectatorState and canVoteTeam and canVoteTeam == myAllyTeamID then
					Button[7].disabled 				= false
				else
					Button[7].disabled 				= true
				end			
				
				return true
			end
		end
		
		if ButtonMenu.click then		
			if mButton == 1 then
			
				for _,button in pairs(Button) do
					if IsOnButton(mx, my, button["x1"],button["y1"],button["x2"],button["y2"]) then
						if not button.disabled then
							button["click"] = true
							ButtonHandler(button["command"])
							return true
						end
					end
				end
		
			elseif mButton == 2 or mButton == 3 then
				
				if IsOnButton(mx, my, Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"]) then
					--Dragging
					return true
				end
			end
		end
	end
	
	return false
 end	

function widget:MouseMove(mx, my, dx, dy, mButton)
      --Dragging
     if mButton == 2 or mButton == 3 then
		 posX = math.max(0, math.min(posX+dx, vsx-sizex))	--prevent moving off screen
		 posY = math.max(0, math.min(posY+dy, vsy-sizey))
		 InitButtons()
     end
 end

function widget:IsAbove(mx,my)
	if not Spring.IsGUIHidden() then
		ButtonMenu.above = IsOnButton(mx, my, ButtonMenu["x1"],ButtonMenu["y1"],ButtonMenu["x2"],ButtonMenu["y2"])
	
		if ButtonMenu.click then
			
			for _,button in pairs(Button) do
				button["above"] = false
			end
			
			for _,button in pairs(Button) do
				if IsOnButton(mx, my, button["x1"],button["y1"],button["x2"],button["y2"]) then
					button["above"] = true
					return true
				end
			end
		end
	end
	
	return false		
		
end	

function widget:KeyPress(key, mods, isRepeat) 
	if key == 0x01B then -- esc
		if ButtonMenu.click then
			ButtonMenu.click = false
			PlaySoundFile(button8)		
			return true
		end
	end
	
	return false
end

function widget:PlayerChanged(playerID)
	mySpectatorState = Spring.GetSpectatingState()
	InitButtons()
end

function widget:GameOver()
	widgetHandler:RemoveWidget()
end
		
function widget:GetConfigData(data)      -- save
	local vsx, vsy = gl.GetViewSizes()
	return {
			posX         		= posX,
			posY         		= posY,
		}
	end

function widget:SetConfigData(data)      -- load
	posX         			= data.posX or posX
	posY         			= data.posY or posY
end