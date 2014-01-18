function widget:GetInfo()
   return {
      name      = "XTA Settings GUI",
      desc      = "Provide a GUI for some options",
      author    = "Jools",
      date      = "jan, 2014",
      license   = "GNU GPL, v2 or later",
      layer 	= 5,
      enabled   = true,  --  loaded by default?
	}
end

local posX, posY					  	= 600, 400
local buttonsize					  	= 16
local width, height					  	= 220, 360
local rowgap						  	= 24
local leftmargin						= 20
local buttontab							= 180			
local vsx, vsy 						  	= gl.GetViewSizes()
local Echo								= Spring.Echo
local PlaySoundFile						= Spring.PlaySoundFile

-- images
local optContrast						= "LuaUI/Images/ecostats/contrast.png"
local optCheckBoxOn						= "LuaUI/Images/ecostats/chkBoxOn.png"
local optCheckBoxOff					= "LuaUI/Images/ecostats/chkBoxOff.png"

--sounds
local sndButtonOn 						= 'sounds/button8.wav'
local sndButtonOff 						= 'sounds/button6.wav'

-- other
local Button				  			= {}
local Panel					  			= {}

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function widget:Initialize()
	Button["mapShading"] 			= {}
	Button["shadows"]				= {}
	Button["unitShading"]			= {}
	Button["pauseMusic"]			= {}
	Button["introMusic"]					= {}
	Button["guiOpacity"]			= {}
	Panel["main"]					= {}
	InitButtons()
end

function InitButtons()
	Button["mapShading"]["x1"]		= posX + 180
	Button["mapShading"]["x2"]  	= Button["mapShading"]["x1"] + buttonsize
	Button["mapShading"]["y1"]  	= posY + height - 80
	Button["mapShading"]["y2"]  	= Button["mapShading"]["y1"] +  buttonsize
	Button["mapShading"]["above"] 	= false 
	Button["mapShading"]["click"]	= tonumber(Spring.GetConfigInt("AdvMapShading",1) or 1) == 1
	Button["mapShading"]["command"]	= "MapShading"
	Button["mapShading"]["label"]	= "Advanced map shading:"
	
	Button["unitShading"]["x1"]		= posX + 180
	Button["unitShading"]["x2"]  	= Button["unitShading"]["x1"] + buttonsize
	Button["unitShading"]["y1"]     = Button["mapShading"]["y1"] - rowgap - buttonsize
	Button["unitShading"]["y2"] 	= Button["unitShading"]["y1"] + buttonsize
	Button["unitShading"]["above"] 	= false 
	Button["unitShading"]["click"]	= tonumber(Spring.GetConfigInt("AdvModelShading",1) or 1) == 1
	Button["unitShading"]["command"]= "UnitShading"
	Button["unitShading"]["label"]	= "Advanced unit shading:"
		
	Button["shadows"]["x1"]			= posX + 180
	Button["shadows"]["x2"]  		= Button["shadows"]["x1"] + buttonsize
	Button["shadows"]["y1"]      	= Button["unitShading"]["y1"] - rowgap - buttonsize
	Button["shadows"]["y2"] 		= Button["shadows"]["y1"] + buttonsize
	Button["shadows"]["above"] 		= false 
	Button["shadows"]["click"]		= tonumber(Spring.GetConfigInt("Shadows",1) or 1) == 1
	Button["shadows"]["command"]	= "Shadows"
	Button["shadows"]["label"]		= "Shadows:"
	
	Button["pauseMusic"]["x1"]		= posX + 180
	Button["pauseMusic"]["x2"]  	= Button["pauseMusic"]["x1"] + buttonsize
	Button["pauseMusic"]["y1"]     	= Button["shadows"]["y1"] - rowgap - buttonsize
	Button["pauseMusic"]["y2"] 		= Button["pauseMusic"]["y1"] + buttonsize
	Button["pauseMusic"]["above"] 	= false 
	Button["pauseMusic"]["click"]	= (not WG.disablePauseMusic) or false
	Button["pauseMusic"]["command"]	= "PauseMusic"
	Button["pauseMusic"]["label"]	= "Pause music:"
	
	Button["introMusic"]["x1"]		= posX + 180
	Button["introMusic"]["x2"]  	= Button["introMusic"]["x1"] + buttonsize
	Button["introMusic"]["y1"]     	= Button["pauseMusic"]["y1"] - rowgap - buttonsize
	Button["introMusic"]["y2"] 		= Button["introMusic"]["y1"] + buttonsize
	Button["introMusic"]["above"] 	= false 
	Button["introMusic"]["click"]	= tonumber(Spring.GetConfigInt('snd_intromusic',0) or 0) == 1
	Button["introMusic"]["command"]	= "introMusic"
	Button["introMusic"]["label"]	= "Intro music:"
	
	Button["guiOpacity"]["x1"]		= posX + 180
	Button["guiOpacity"]["x2"]  	= Button["guiOpacity"]["x1"] + buttonsize
	Button["guiOpacity"]["y1"]    	= Button["introMusic"]["y1"] - rowgap - buttonsize
	Button["guiOpacity"]["y2"] 		= Button["guiOpacity"]["y1"] + buttonsize
	Button["guiOpacity"]["above"] 	= false 
	Button["guiOpacity"]["click"]	= false
	Button["guiOpacity"]["divided"] = true
	Button["guiOpacity"]["less"]	= "GuiOpacityLess"
	Button["guiOpacity"]["more"]	= "GuiOpacityMore"
	Button["guiOpacity"]["value"]   = tonumber(Spring.GetConfigString('GuiOpacity')) or 0.4 
	Button["guiOpacity"]["label"]	= table.concat{"Adjust menu opacity:"," ( ",  string.format("%.1f", (Button["guiOpacity"]["value"])) ," )"}
	
	Panel["main"]["x1"]				= posX
	Panel["main"]["x2"]				= posX + width
	Panel["main"]["y1"]				= posY
	Panel["main"]["y2"]				= posY + height

end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY

end
      
function ButtonHandler (cmd)
	if cmd == "MapShading" then
		if Button["mapShading"]["click"] then
			Spring.SendCommands("AdvMapShading 0")
		else
			Spring.SendCommands("AdvMapShading 1")
		end
	elseif cmd == "UnitShading" then
		if Button["mapShading"]["click"] then
			Spring.SendCommands("AdvModelShading 0")
		else
			Spring.SendCommands("AdvModelShading 1")
		end
	elseif cmd == "Shadows" then
		if Button["shadows"]["click"] then
			Spring.SendCommands("Shadows 0")
		else
			Spring.SendCommands("Shadows 1")
		end
	elseif cmd == "PauseMusic" then
		if Button["pauseMusic"]["click"] then
			Spring.SendCommands("musicoff")
		else
			Spring.SendCommands("musicon")
		end
	elseif cmd == "introMusic" then
		if Button["introMusic"]["click"] then
			Spring.SetConfigInt('snd_intromusic', 0)
		else
			Spring.SetConfigInt('snd_intromusic', 1)
		end
	elseif cmd == "GuiOpacityLess" then
		Spring.SendCommands("DecGUIOpacity")
		Button["guiOpacity"]["value"] = math.max(Button["guiOpacity"]["value"] - 0.1,0)
	elseif cmd == "GuiOpacityMore" then
		Spring.SendCommands("IncGUIOpacity")
		Button["guiOpacity"]["value"] = math.min(Button["guiOpacity"]["value"] + 0.1,1)
	else
		Echo("Local command:",cmd)
	end
end

--------------------------------------------------------------------------------			 
-- Tweak-mode
--------------------------------------------------------------------------------

local function drawOptions()
		
	--background panel
	gl.Color(0,0,0,0.7)
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"])
	
	--border
	gl.Color(0,0,0,1)
	gl.Rect(Panel["main"]["x1"]-1,Panel["main"]["y1"], Panel["main"]["x1"], Panel["main"]["y2"])
	gl.Rect(Panel["main"]["x2"],Panel["main"]["y1"], Panel["main"]["x2"]+1, Panel["main"]["y2"])
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y1"]-1, Panel["main"]["x2"], Panel["main"]["y1"])
	gl.Rect(Panel["main"]["x1"],Panel["main"]["y2"], Panel["main"]["x2"], Panel["main"]["y2"]+1)
	
	-- Heading
	gl.Color(1,1,1,1)
	gl.Text("XTA Settings:", Panel["main"]["x1"] + leftmargin, Panel["main"]["y2"] - 20,14,'d')
	
	-- Buttons
	for _,button in pairs(Button) do
		
		if button["mouse"] then
			gl.Color(1,1,1,1)
		else
			gl.Color(0.6,0.6,0.6,1)
		end
		gl.Text(button["label"] or "N/A", posX+leftmargin, button["y1"],12,'sd')
		
		if button["divided"] then
			gl.Texture(optContrast)
		else
			if button["click"] then
				gl.Texture(optCheckBoxOn)
			else
				gl.Texture(optCheckBoxOff)
			end
		end
		gl.TexRect(button["x1"],button["y1"],button["x2"],button["y2"])
		gl.Texture(false)
	end
		
	--reset state
	gl.Texture(false)
	gl.Color(1,1,1,1)
end

local function drawIsAbove(x,y)
	--Echo("TweakIsAbove:",x,y)
	if not x or not y then return false end
	
	for _,button in pairs(Button) do
		button["mouse"] = false
	end
	
	for _,button in pairs(Button) do
		if IsOnButton(x, y, button["x1"],button["y1"],button["x2"],button["y2"]) then
			button["mouse"] = true
			return true
		end
	end
	
	return false
end

function widget:DrawScreen()

end

function widget:TweakDrawScreen()
	drawOptions()
end

function widget:IsAbove(x,y)
	--drawIsAbove(x,y)
	--this callin must be present, otherwise function widget:TweakIsAbove(z,y) isn't called. Maybe a bug in widgethandler.
end

function widget:TweakIsAbove(x,y)
	drawIsAbove(x,y)
 end

function widget:TweakMousePress(x, y, button)
	
	if button == 1 then
		for _,button in pairs(Button) do
			if IsOnButton(x, y, button["x1"],button["y1"],button["x2"],button["y2"]) then
				if not button["click"] then
					PlaySoundFile(sndButtonOn,1.0,0,0,0,0,0,0,'userinterface')
				else
					PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
				end
				if button["divided"] then
					if x < button["x1"] + buttonsize/2 then
						ButtonHandler(button["less"])
					else
						ButtonHandler(button["more"])
					end
					InitButtons()
				else 
					ButtonHandler(button["command"])
					button["click"] = not button["click"]
				end
				return true
			end	
		end
	 elseif (button == 2 or button == 3) then
		 if IsOnButton(x, y, Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"]) then
			  --Dragging
			 return true
		 end		
	 end
	 return false
 end
 
function widget:TweakMouseMove(mx, my, dx, dy, mButton)
	
      --Dragging
     if mButton == 2 or mButton == 3 then
		 posX = math.max(0, math.min(posX+dx, vsx-width))	--prevent moving off screen
		 posY = math.max(0, math.min(posY+dy, vsy-height))
		 InitButtons()
     end
 end
