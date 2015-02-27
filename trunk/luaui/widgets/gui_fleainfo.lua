function widget:GetInfo()
	return {
		name    = "Fleas GUI",
		desc    = "Shows fleas statistics",
		author  = "Jools",
		date    = "Feb, 2015",
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
local FleaMenu						= {}
FleaMenu.click						= false

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
local cTex							= {1, 1, 1, 0.75}


--sounds
local button6						= "sounds/button6.wav"
local button8						= "sounds/button8.wav"

local imgFlea						= "luaui/images/fleabowl/armflea.png"
local fleaData						= {}


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
	
	
	Panel["main"]["x1"]			= posX
	Panel["main"]["x2"]			= posX + sizex
	Panel["main"]["y1"]			= posY
	Panel["main"]["y2"]			= posY + sizey
	
	Button["close"]["x1"]		= posX
	Button["close"]["x2"]		= posX + sizex
	Button["close"]["y1"]		= posY
	Button["close"]["y2"]		= posY + sizey
	Button["close"]["above"] 	= false
	
end

function widget:Initialize()
	myTeamID = Spring.GetLocalTeamID()
	myAllyTeamID = select(6,Spring.GetTeamInfo(myTeamID))
	FleaMenu.x1					= vsx - 70
	FleaMenu.x2					= vsx - 40
	FleaMenu.y1					= vsy - 30
	FleaMenu.y2					= vsy

	Button["close"] 				= {}
	Panel["main"]					= {}
	InitButtons()
		
	widgetHandler:RegisterGlobal('ChickenEvent', ChickenEvent)
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal('ChickenEvent')
end

local function DrawFleaStats()
	
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
	myFontBig:Print("XTA Flea Bowl:", Panel["main"]["x1"] + margin, Panel["main"]["y2"] - 20,14,'ds')
	myFontBig:End()
	
	-- Info
	
	local y0 = Panel["main"]["y2"] - 40
	local kills = Spring.GetGameRulesParam("killedFleas") or 0
	myFont:Begin()		
	myFont:SetTextColor(cTitle)
	myFont:Print("Wave:", Panel["main"]["x1"]+margin, y0 ,12,'vs')
	myFont:Print("Spawned flea dens:", Panel["main"]["x1"]+margin, y0 - 20,12,'vs')
	myFont:Print("Flea kills:", Panel["main"]["x1"]+margin, y0 - 40,12,'vs')
	
	myFont:SetTextColor(cWhite)
	myFont:Print(fleaData["wave"] or "-", Panel["main"]["x2"]-margin, y0 ,12,'rvs')
	myFont:Print(fleaData["burrow"] or "-", Panel["main"]["x2"]-margin, y0 - 20,12,'rvs')
	myFont:Print(kills or "-", Panel["main"]["x2"]-margin, y0 - 40,12,'rvs')
	myFont:End()
	
	
		
	--reset state
	gl.Texture(false)
	gl.Color(1,1,1,1)
end

function ChickenEvent(data)
	Echo("Chicken Event:")
	if data.type == 'wave' then
		if not fleaData["wave"] then
			fleaData["wave"] = 0
		end
		fleaData["wave"] = fleaData["wave"] + 1
	elseif data.type == 'burrowSpawn' then
		if not fleaData["burrow"] then
			fleaData["burrow"] = 0
		end
		fleaData["burrow"] = fleaData["burrow"] + 1
	end
	
	for i, j in pairs (data) do
		Echo("Info:",i,j)
	end
end

function widget:DrawScreen()
		
	-- draw menu button
	if FleaMenu.above then
		glColor(cLight)
	elseif FleaMenu.click then
		glColor(cSelect)
	else
		glColor(cBack)
	end
	glRect(FleaMenu.x1,FleaMenu.y1,FleaMenu.x2,FleaMenu.y2)
	local mg = 2
	
	gl.Color(cTex)
	glTexture(imgFlea)
	glTexRect(FleaMenu.x1+mg,FleaMenu.y1+mg,FleaMenu.x2-mg,FleaMenu.y2-mg)
	
	glTexture(false)
	glColor(cPanel)
			
	--menu border
	glColor(cShadow)
	glRect(FleaMenu.x1,FleaMenu.y1,FleaMenu.x1+1,FleaMenu.y2)
	glRect(FleaMenu.x2-1,FleaMenu.y1,FleaMenu.x2,FleaMenu.y2)
	glRect(FleaMenu.x1,FleaMenu.y1,FleaMenu.x2,FleaMenu.y1+1)
	glRect(FleaMenu.x1,FleaMenu.y2-1,FleaMenu.x2,FleaMenu.y2)
	
	-- draw flea window
	if (not Spring.IsGUIHidden()) and FleaMenu.click then
		DrawFleaStats()
	end
end

function widget:MousePress(mx, my, mButton)
	if not Spring.IsGUIHidden() then
		
		if mButton == 1 then
			if IsOnButton(mx, my, FleaMenu["x1"],FleaMenu["y1"],FleaMenu["x2"],FleaMenu["y2"]) then
				FleaMenu.click = not FleaMenu.click
				PlaySoundFile(button6)				
				return true
			end
		end
		
		if FleaMenu.click then		
			if mButton == 1 then
				-- add close button
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
		FleaMenu.above = IsOnButton(mx, my, FleaMenu["x1"],FleaMenu["y1"],FleaMenu["x2"],FleaMenu["y2"])
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