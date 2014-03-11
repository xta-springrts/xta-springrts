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
local width, height					  	= 360, 540
local rowgap						  	= 36
local leftmargin						= 20
local buttontab							= 310			
local vsx, vsy 						  	= gl.GetViewSizes()
local Echo								= Spring.Echo
local PlaySoundFile						= Spring.PlaySoundFile

-- images
local optContrast						= "LuaUI/Images/tweaksettings/contrast.png"
local optCheckBoxOn						= "LuaUI/Images/tweaksettings/chkBoxOn.png"
local optCheckBoxOff					= "LuaUI/Images/tweaksettings/chkBoxOff.png"
local imgArrows							= "LuaUI/Images/tweaksettings/arrows.png"


--sounds
local sndButtonOn 						= 'sounds/button8.wav'
local sndButtonOff 						= 'sounds/button6.wav'

-- other
local Button				  			= {}
local Panel					  			= {}

-- variables

local waterType = 0

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function widget:Initialize()
	Button[1] 						= {} -- mapshading
	Button[2]						= {} -- unitshading
	Button[3]						= {} -- shadows
	Button[4]						= {} -- hardwarecursor
	Button[5]						= {} -- pausemusic
	Button[6]						= {} -- intromusic
	Button[7]						= {} -- showfps
	Button[8]						= {} -- show time
	Button[9]						= {} -- show speed
	Button[10]						= {} -- qui opacity
	Button[11]						= {} -- info table
	Button[12]						= {} -- water
	Button[13]						= {} -- stats window order
	Panel["main"]					= {}
	InitButtons()
end

function InitButtons()

	-- special buttons
	Button[10]["divided"] 		= true -- action depens on which side of button is clicked
	Button[12]["wide"]			= true -- double width as normal
	Button[12]["divided"] 		= true
	
	-- automate positions
	for i,button in ipairs(Button) do
		if button["wide"] then
			button["x1"] 	= posX + buttontab - 1 * buttonsize
			button["x2"]	= button["x1"] + 3 * buttonsize
			button["y1"]	= posY + height - 20 - i*rowgap - buttonsize
			button["y2"]	= button["y1"] + 1.5 * buttonsize
			button["above"] = false
		elseif button["divided"] then
			button["x1"] 	= posX + buttontab - 0.25 * buttonsize
			button["x2"]	= button["x1"] + 1.5 * buttonsize
			button["y1"]	= posY + height - 20 - i*rowgap - buttonsize
			button["y2"]	= button["y1"] + 1.5 * buttonsize
			button["above"] = false
		else
			button["x1"] 	= posX + buttontab
			button["x2"]	= button["x1"] + buttonsize
			button["y1"]	= posY + height - 20 - i*rowgap - buttonsize
			button["y2"]	= button["y1"] + buttonsize
			button["above"] = false
		end
	end	
	
	Button[1]["click"]			= tonumber(Spring.GetConfigInt("AdvMapShading",1) or 1) == 1
	Button[1]["command"]		= "MapShading"
	Button[1]["label"]			= "Advanced map shading:"
	
	Button[2]["click"]			= tonumber(Spring.GetConfigInt("AdvModelShading",1) or 1) == 1
	Button[2]["command"]		= "UnitShading"
	Button[2]["label"]			= "Advanced unit shading:"
		
	Button[3]["click"]			= tonumber(Spring.GetConfigInt("Shadows",1) or 1) == 1
	Button[3]["command"]		= "Shadows"
	Button[3]["label"]			= "Shadows:"
	
	Button[4]["click"]			= tonumber(Spring.GetConfigInt("hardwareCursor",1) or 1) == 1
	Button[4]["command"]		= "hardwareCursor"
	Button[4]["label"]			= "Hardware-cursor:"
	
	Button[5]["click"]			= (not WG.disablePauseMusic) or false
	Button[5]["command"]		= "PauseMusic"
	Button[5]["label"]			= "Pause music:"
	
	Button[6]["click"]			= tonumber(Spring.GetConfigInt('snd_intromusic',0) or 0) == 1
	Button[6]["command"]		= "introMusic"
	Button[6]["label"]			= "Intro music:"
	
	Button[7]["click"]			= tonumber(Spring.GetConfigInt("ShowFPS",1) or 1) == 1
	Button[7]["command"]		= "showFPS"
	Button[7]["label"]			= "Show fps indicator:"

	Button[8]["click"]			= tonumber(Spring.GetConfigInt("ShowClock",1) or 1) == 1
	Button[8]["command"]		= "showTime"
	Button[8]["label"]			= "Show game time:"
	
	Button[9]["click"]			= tonumber(Spring.GetConfigInt("ShowSpeed",0) or 0) == 1
	Button[9]["command"]		= "showSpeed"
	Button[9]["label"]			= "Show game speed:"
	
	Button[10]["click"]			= false
	Button[10]["less"]			= "GuiOpacityLess"
	Button[10]["more"]			= "GuiOpacityMore"
	
	if not Button[10]["value"] then
		Button[10]["value"]   		= tonumber(Spring.GetConfigString('GuiOpacity')) or 0.4 
	end
	Button[10]["label"]			= table.concat{"Adjust menu opacity: "," (",  string.format("%.1f", (Button[10]["value"])) ,")"}
	
	Button[11]["click"]			= tonumber(Spring.GetConfigInt("ShowPlayerInfo",0) or 0) == 1
	Button[11]["command"]		= "showInfo"
	Button[11]["label"]			= "Show simple player infotable:"
	
	Button[12]["click"]			= false
	Button[12]["img"]			= imgArrows
	Button[12]["less"]			= "waterPrev"
	Button[12]["more"]			= "waterNext"
	if not Button[12]["value"] then
		Button[12]["value"]   		= tonumber(Spring.GetConfigInt("ReflectiveWater",1)) or 0
	end
	
	if Button[12]["value"] == 0 then
		waterType = "Basic"
	elseif Button[12]["value"] == 1 then
		waterType = "Reflective"
	elseif Button[12]["value"] == 2 then
		waterType = "Dynamic"
	elseif Button[12]["value"] == 3 then
		waterType = "Reflective & refractive"
	elseif Button[12]["value"] == 4 then
		waterType = "Bumpmapped"
	end

	Button[12]["label"]			= table.concat{"Water type: "," (", tonumber(Button[12]["value"])," – ",waterType ,")"}
	
	Button[13]["click"]			= tonumber(Spring.GetConfigInt("EngineGraphFirst") or 0) == 1
	Button[13]["command"]		= "EngineGraphFirst"
	Button[13]["label"]			= "Show engine graph first:"
	
	
	Panel["main"]["x1"]			= posX
	Panel["main"]["x2"]			= posX + width
	Panel["main"]["y1"]			= posY
	Panel["main"]["y2"]			= posY + height

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
		if Button[1]["click"] then
			Spring.SendCommands("AdvMapShading 0")
		else
			Spring.SendCommands("AdvMapShading 1")
		end
	elseif cmd == "UnitShading" then
		if Button[2]["click"] then
			Spring.SendCommands("AdvModelShading 0")
		else
			Spring.SendCommands("AdvModelShading 1")
		end
	
	elseif cmd == "Shadows" then
		if Button[3]["click"] then
			Spring.SendCommands("Shadows 0")
		else
			Spring.SendCommands("Shadows 1")
		end
	elseif cmd == "hardwareCursor" then
		if Button[4]["click"] then
			Spring.SendCommands("hardwarecursor 0")
		else
			Spring.SendCommands("hardwarecursor 1")
		end
	elseif cmd == "PauseMusic" then
		if Button[5]["click"] then
			Spring.SendCommands("musicoff")
		else
			Spring.SendCommands("musicon")
		end
	elseif cmd == "introMusic" then
		if Button[6]["click"] then
			Spring.SetConfigInt('snd_intromusic', 0)
		else
			Spring.SetConfigInt('snd_intromusic', 1)
		end
	elseif cmd == "showFPS" then
		if Button[7]["click"] then
			Spring.SendCommands("fps 0")
		else
			Spring.SendCommands("fps 1")
		end
	elseif cmd == "showTime" then
		if Button[8]["click"] then
			Spring.SendCommands("clock 0")
		else
			Spring.SendCommands("clock 1")
		end	
	elseif cmd == "showSpeed" then
		if Button[9]["click"] then
			Spring.SendCommands("speed 0")
		else
			Spring.SendCommands("speed 1")
		end	
	elseif cmd == "GuiOpacityLess" then
		Spring.SendCommands("DecGUIOpacity")
		Button[10]["value"] = math.max(Button[10]["value"] - 0.1,0)
	elseif cmd == "GuiOpacityMore" then
		Spring.SendCommands("IncGUIOpacity")
		Button[10]["value"] = math.min(Button[10]["value"] + 0.1,1)
	elseif cmd == "showInfo" then
		if Button[11]["click"] then
			Spring.SendCommands("info 0")
		else
			Spring.SendCommands("info 1")
		end
	elseif cmd == "waterPrev" then
		if Button[12]["value"] ~= math.max(Button[12]["value"] - 1,0) then
			Button[12]["value"] = math.max(Button[12]["value"] - 1,0)
			Spring.SendCommands("water " .. tonumber(Button[12]["value"]))
		end
		InitButtons()
	elseif cmd == "waterNext" then	
		if Button[12]["value"] ~= math.min(Button[12]["value"] + 1,4) then
			Button[12]["value"] = math.min(Button[12]["value"] + 1,4)
			Spring.SendCommands("water " .. tonumber(Button[12]["value"]))
		end
		InitButtons()
	elseif cmd == "EngineGraphFirst" then
		if Button[13]["click"] then
			Spring.SetConfigInt("EngineGraphFirst",0)
		else
			Spring.SetConfigInt("EngineGraphFirst",1)
		end
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
	gl.Text("XTA game-settings:", Panel["main"]["x1"] + leftmargin, Panel["main"]["y2"] - 20,14,'d')
	
	-- Buttons
	for _,button in ipairs(Button) do
		
		if button["mouse"] then
			gl.Color(1,1,1,1)
		else
			gl.Color(0.6,0.6,0.6,1)
		end
		gl.Text(button["label"] or "N/A", posX+leftmargin, button["y1"],12,'d')
		
		if button["divided"] then
			if button["img"] then
				gl.Texture(button["img"])
			else
				gl.Texture(optContrast)
			end
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
	--Echo("Tweak Is Above callin:",x,y) -- This callin isn't working in spring 96. It may be fixed in the future.
	drawIsAbove(x,y)
 end

function widget:TweakMousePress(x, y, button)
	
	if button == 1 then
		for _,button in ipairs(Button) do
			if IsOnButton(x, y, button["x1"],button["y1"],button["x2"],button["y2"]) then
				if not button["click"] then
					PlaySoundFile(sndButtonOn,1.0,0,0,0,0,0,0,'userinterface')
				else
					PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
				end
				if button["divided"] then
					if button["wide"] then
						if x < button["x1"] + 3*buttonsize/2 then
							ButtonHandler(button["less"])
						else
							ButtonHandler(button["more"])
						end
					else
						if x < button["x1"] + 1.5*buttonsize/2 then
							ButtonHandler(button["less"])
						else
							ButtonHandler(button["more"])
						end
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
