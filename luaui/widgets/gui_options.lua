function widget:GetInfo()
   return {
      name      = "XTA Options",
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
local width, height					  	= 360, 620
local iWidth							= 400
local iRowHeight						= 14
local rows								= 0
local height0							= 160
local iHeight
local rowgap						  	= 26
local leftmargin						= 20
local buttontab							= 310			
local vsx, vsy 						  	= gl.GetViewSizes()
local Echo								= Spring.Echo
local PlaySoundFile						= Spring.PlaySoundFile
local showModOptions					= false
local showMapOptions					= false
local showSettings						= false
local textSize							= 10
local myFont							= gl.LoadFont("FreeSansBold.otf",textSize, 1.9, 40)
local myFontBig							= gl.LoadFont("FreeSansBold.otf",14, 1.9, 40)
local myFontBigger						= gl.LoadFont("FreeSansBold.otf",18, 1.9, 40)
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
local ButtonClose		 				= {}
local Panel					  			= {}

-- variables

local waterType = 0
local modOptions 						= Spring.GetModOptions()
local Options							= {}
Options["general"]						= {}
Options["other"]						= {}
Options["multipliers"]					= {}
Options["koth"]							= {}
Options["experimental"]					= {}
Options["map"]							= {}
Options["fleabowl"]						= {}

local mapOptions 						= Spring.GetMapOptions()

local OptionCount						= {}
local MapOptionCount					= 0

--colors
local cLight 							= {1,1,1,1}
local cWhite 							= {1,1,1,1}
local cButton							= {0.8,0.8,0.8,1}
local cBack 							= {0,0,0,0.8}
local cGreen							= {0.2, 0.8, 0.2, 1}
local cRed								= {0.8, 0.2, 0.2, 1}
local cGrey								= {0.8, 0.8, 0.8, 0.2}
local cYellow							= {0.8, 0.8, 0.2, 1}
local cRow								= {0.2,0.6,0.9,0.1}
local cBorder							= {0,0,0,1}
local cAbove							= {0.8,0.8,0,0.5}


--------------------------------------------------------------------------------			 
-- Local functions
--------------------------------------------------------------------------------

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function firstToUpper(str)
		return (str:gsub("^%l", string.upper))
	end

local function formatLabel(value,type,name)
	local label 

	if type == "bool" then
		if value == 1 or value == "1" then
			label = "Yes"
			myFont:SetTextColor(cGreen) -- green
		elseif value == 0 or value == "0" then
			label = "No"
			myFont:SetTextColor(cRed) -- red
		else
			label = "N/A"
			myFont:SetTextColor(cGrey) -- grey
		end
	else
		label = firstToUpper(tostring(value))
		if name == "Game mode:" then
			if label == "Killall" or label == "None" then
				myFont:SetTextColor(cRed) -- red
			elseif label ~= "N/A" then
				myFont:SetTextColor(cGreen) -- green
			else
				myFont:SetTextColor(cGrey) -- grey
			end
		else
			myFont:SetTextColor(cButton)
		end
		if label == "N/A" then
			myFont:SetTextColor(cGrey) -- grey
		end
	end
	return label
end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY

end
      
-----------	  
-- INIT  --
-----------	  
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
	Button[14]						= {} -- disable move-failed sounds
	Button[15]						= {} -- disable move-failed sounds
	Button[16]						= {} -- full screen
	Button[17]						= {} -- disable blinking units
	Button[18]						= {} -- show/don't show grass
	Button[19]						= {} -- show/don't show help text
	Button[20]						= {} -- show/don't show noob-buttons
	Button[21]						= {} -- scale commander names to res.
	
	Panel["main"]					= {}
	Panel["info"]					= {} -- info screen with mod options
	InitButtons()
	
	
	if modOptions then
		--general
		Options["general"] = {
			{
			name	= "Start metal:",
			type	= "value",
			value	= modOptions["startmetal"] or "N/A",
			},
			
			{	
			name	= "Start energy:",
			type	= "value",
			value	= modOptions["startenergy"] or "N/A",
			},
			
			{
			name	= "Min. speed:",
			type	= "value",
			value	= modOptions["minspeed"] or "N/A",
			},
			
			{	
			name	= "Max. speed:",
			type	= "value",
			value	= modOptions["maxspeed"] or "N/A",
			},
			
			{
			name	= "Max. units:",
			type	= "value",
			value	= modOptions["maxunits"] or "N/A",
			},
			
			{
			name	= "Commander type:",
			type	= "value",
			value	= modOptions["commander"] or "N/A",
			},
			
			{
			name	= "Game mode:",
			type	= "value",
			value	= modOptions["mode"] or "N/A",
			},
					
			{
			name	= "Reclaim method is lump sum:",
			type	= "bool",
			value	= modOptions["reclaim_method"] or "N/A",
			},
			
			{
			name	= "Ghosted buildings:",
			type	= "bool",
			value	= modOptions["ghostedbuildings"] or "N/A",
			},
			
			{
			name	= "Sounds mode:",
			type	= "value",
			value	= modOptions["sounds"] or "N/A",
			},
			
			{
			name 	= "Enable units to slow down on slopes",
			type 	= bool,
			value 	= modOptions["enableslopemods"] or "N/A",
			},
		}
		
		-- other options
		Options["other"] = {
			{
			name		= "Aircraft do not collide:",
			type		= "bool",
			value		= modOptions["airnocollide"] or "N/A",
			},
			
			{
			name		= "Disable friendly unit projectile collisions:",
			type		= "bool",
			value		= modOptions["nocollide"] or "N/A",
			},
			
			{
			name		= "Limit D-Gun:",
			type		= "bool",
			value		= modOptions["limitdgun"] or "N/A",
			},
			
			{
			name		= "Intercept nukes:",
			type		= "bool",
			value		= modOptions["nuke"] or "N/A",
			},
			
			{
			name		= "Disable map damage:",
			type		= "bool",
			value		= modOptions["disablemapdamage"] or "N/A",
			},
			
			{
			name		= "Allow transport of enemies:",
			type		= "value",
			value		= modOptions["mo_transportenemy"] or "N/A",
			},
			
			{
			name		= "Allow transport of hovercraft:",
			type		= "bool",
			value		= modOptions["mo_transporthover"] or "N/A",
			},
			
			{
			name		= "No wrecks:",
			type		= "bool",
			value		= modOptions["mo_nowrecks"] or "N/A",
			},
			{
			name	= "Critters:",
			type	= "bool",
			value	= modOptions["critters"] or "N/A",
			},					
			{
			name	= "Dynamic lights:",
			type	= "bool",
			value	= modOptions["dynamiclights"] or "N/A",
			},
			
		}
		-- unit packs
		Options["unitpacks"] = {
			
			{
			name		= "XTAIDS unit pack:",
			type		= "bool",
			value		= modOptions["xtaidunits"] or "N/A",
			},
			
			{
			name		= "Spider & Tortoise unit pack:",
			type		= "bool",
			value		= modOptions["spidertortoise"] or "N/A",
			},
			
			{
			name		= "The Lost Legacy faction:",
			type		= "bool",
			value		= modOptions["tllunits"] or "N/A",
			},
			
			{
			name		= "The Guardians of Kadesh faction:",
			type		= "bool",
			value		= modOptions["gokunits"] or "N/A",
			},
			
			{
			name		= "Disable all new units after XTA version 8.1:",
			type		= "bool",
			value		= modOptions["newunits"] or "N/A",
			},	
		}
		
		
		-- multiplier options
		Options["multiplier"] = {
			{
			name		= "Metal:",
			type		= "value",
			value		= modOptions["metalmult"] or "N/A",
			},
			
			{
			name		= "Energy:",
			type		= "value",
			value		= modOptions["energymult"] or "N/A",
			},
			
			{
			name		= "Worker:",
			type		= "value",
			value		= modOptions["workermult"] or "N/A",
			},
		
			{
			name		= "Velocity:",
			type		= "value",
			value		= modOptions["velocitymult"] or "N/A",
			},
			
			{
			name		= "Hits:",
			type		= "value",
			value		= modOptions["hitmult"] or "N/A",
			},
		}
		
		-- KOTH options
		Options["koth"] = {
			{
			name		= "Enable KOTH mode:",
			type		= "bool",
			value		= modOptions["koth"] or "N/A",
			},
			
			{
			name		= "Hill time (min):",
			type		= "value",
			value		= modOptions["hilltime"] or "N/A",
			},
			
			{
			name		= "Grace time (min):",
			type		= "value",
			value		= modOptions["gracetime"] or "N/A",
			},
		}
		-- Fleabowl options
		Options["fleabowl"] = {
			
			{
			name		= "Spawn bosses",
			type		= "bool",
			value		= modOptions["bosses"] or "N/A",
			},
			
			{
			name		= "Fleagoth time (min):",
			type		= "value",
			value		= modOptions["mo_gothtime"] or "N/A",
			},
			
			{
			name		= "Max fleas:",
			type		= "value",
			value		= modOptions["mo_maxfleas"] or "N/A",
			},
			
			{
			name		= "Max flea dens:",
			type		= "value",
			value		= modOptions["mo_maxburrows"] or "N/A",
			},
		}
			
		-- Experimental options
		Options["experimental"] = {
			{
			name		= "Cannon velocity:",
			type		= "value",
			value		= modOptions["gravity"] or "N/A",
			},
			
			{
			name		= "Enable zombies:",
			type		= "bool",
			value		= modOptions["zombies"] or "N/A",
			},
			
			{
			name		= "Enable QT pathfinding system:",
			type		= "bool",
			value		= modOptions["qtpfs"] or "N/A",
			},
			
			{
			name		= "Enable additional rocket type for some units:",
			type		= "bool",
			value		= modOptions["rockettoggle"] or "N/A",
			},
			
			{
			name		= "Enable variable production rate gadget:",
			type		= "bool",
			value		= modOptions["buildspeed"] or "N/A",
			},
		}
	end

	for optionName, data in pairs(Options) do
		OptionCount[optionName] = 0
		for _, value in pairs(data) do
			if value.value and value.value ~= "N/A" then
				OptionCount[optionName] = OptionCount[optionName] + 1
			end
		end
	end
	
	for optionName, value in pairs(mapOptions) do
		
		MapOptionCount = MapOptionCount + 1
		Options["map"][optionName] = {
			name	= optionName,
			type	= "value",
			value	= value or "N/A",
		}
	end
end

function updateHeights()
	iHeight	 					= height0  + rows * (iRowHeight+4)
	Panel["info"]["y2"]			= posY + iHeight
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

	Button[12]["label"]			= table.concat{"Water type: "," (", tonumber(Button[12]["value"])," - ",waterType ,")"}
	
	Button[13]["click"]			= tonumber(Spring.GetConfigInt("XTA_EngineGraphFirst") or 0) == 1
	Button[13]["command"]		= "XTA_EngineGraphFirst"
	Button[13]["label"]			= "Show engine graph first:"
	
	Button[14]["click"]			= tonumber(Spring.GetConfigInt("XTA_DisableMoveFailedSound",0) or 0) == 1
	Button[14]["command"]		= "disableMoveFailed"
	Button[14]["label"]			= "Disable move-failed unit reply sound:"
	
	Button[15]["click"]			= tonumber(Spring.GetConfigInt("XTA_DisableMoveFailedText",0) or 0) == 1
	Button[15]["command"]		= "disableMoveFailedText"
	Button[15]["label"]			= "Disable move-failed unit reply text:"
	
	Button[16]["click"]			= tonumber(Spring.GetConfigInt("Fullscreen",1) or 1) == 1
	Button[16]["command"]		= "fullscreen"
	Button[16]["label"]			= "Full screen:"
	
	Button[17]["click"]			= tonumber(Spring.GetConfigInt("TeamHighlight",1) or 1) == 1
	Button[17]["command"]		= "blinking"
	Button[17]["label"]			= "Blinking units:"
	
	Button[18]["click"]			= tonumber(Spring.GetConfigInt("GrassDetail",1) or 1) == 1
	Button[18]["command"]		= "grass"
	Button[18]["label"]			= "Show grass on maps:"
	
	Button[19]["click"]			= tonumber(Spring.GetConfigInt("XTA_CommandHelpText",1) or 1) == 1
	Button[19]["command"]		= "help"
	Button[19]["label"]			= "Show interface help text:"
	
	Button[20]["click"]			= tonumber(Spring.GetConfigInt("XTA_ShowNoobButtons",1) or 1) == 1
	Button[20]["command"]		= "noob-buttons"
	Button[20]["label"]			= "Show noob-buttons in order menu:"
	
	Button[21]["click"]			= WG.nameScaling or false
	Button[21]["command"]		= "scale-names"
	Button[21]["label"]			= "Scale commander names to zoom-level:"
	
	Panel["main"]["x1"]			= posX
	Panel["main"]["x2"]			= posX + width
	Panel["main"]["y1"]			= posY
	Panel["main"]["y2"]			= posY + height
	
	iHeight						= height0  + rows * (iRowHeight+4)
	
	Panel["info"]["x1"]			= posX
	Panel["info"]["x2"]			= posX + iWidth
	Panel["info"]["y1"]			= posY
	Panel["info"]["y2"]			= posY + iHeight
	
	ButtonClose["x1"] 			= posX + width/2 - 30
	ButtonClose["y1"] 			= posY + 20
	ButtonClose["x2"] 			= ButtonClose["x1"] + 60
	ButtonClose["y2"] 			= posY + 50
	
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
	elseif cmd == "XTA_EngineGraphFirst" then
		if Button[13]["click"] then
			Spring.SetConfigInt("XTA_EngineGraphFirst",0)
		else
			Spring.SetConfigInt("XTA_EngineGraphFirst",1)
		end
	elseif cmd == "disableMoveFailed" then
		if Button[14]["click"] then
			Spring.SetConfigInt("XTA_DisableMoveFailedSound",0)
		else
			Spring.SetConfigInt("XTA_DisableMoveFailedSound",1)
		end
		
	elseif cmd == "disableMoveFailedText" then
		if Button[15]["click"] then
			Spring.SetConfigInt("XTA_DisableMoveFailedText",0)
		else
			Spring.SetConfigInt("XTA_DisableMoveFailedText",1)
		end	
	elseif cmd == "fullscreen" then
		if Button[16]["click"] then
			Spring.SendCommands("fullscreen 0")
		else
			Spring.SendCommands("fullscreen 1")
		end
	elseif cmd == "blinking" then
		if Button[17]["click"] then
			Spring.SendCommands("teamhighlight 0")
		else
			Spring.SendCommands("teamhighlight 1")
		end
	elseif cmd == "grass" then
		if Button[18]["click"] then
			Spring.SetConfigInt("GrassDetail",0)
		else
			Spring.SetConfigInt("GrassDetail",1)
		end
	elseif cmd == "help" then
		if Button[19]["click"] then
			Spring.SetConfigInt("XTA_CommandHelpText",0)
		else
			Spring.SetConfigInt("XTA_CommandHelpText",1)
		end
	elseif cmd == "noob-buttons" then
		if Button[20]["click"] then
			Spring.SetConfigInt("XTA_ShowNoobButtons",0)
		else
			Spring.SetConfigInt("XTA_ShowNoobButtons",1)
		end
	elseif cmd == "scale-names" then
		Spring.SendCommands("comnamescale")
	else
		Echo("Local command:",cmd)
	end
end

--------------------------------------------------------------------------------			 
-- Callins
--------------------------------------------------------------------------------

local function drawRow(optData,i,lastY)
	local name = optData["name"]
	local type = optData["type"]
	local value = optData["value"]
	
	local yi = lastY - 14
	lastY = lastY - 14
	
	local label = formatLabel(value,type,name)
	
	if label ~= "N/A" and type then
		myFont:Print(label, Panel["info"]["x2"] - leftmargin, yi,textSize,'rdo')
		myFont:SetTextColor(cButton)
		myFont:Print(name, Panel["info"]["x1"] + leftmargin, yi,textSize,'do')
		i = i + 1
		rows = rows + 1
	else
		lastY = lastY + 14
	end
	myFont:SetTextColor(cButton)
	
	if i%2 ~= 0 and type and label ~= "N/A" then
		gl.Color(cRow)
		gl.Rect(Panel["info"]["x1"]+ leftmargin, yi, Panel["info"]["x2"]-leftmargin,yi + 14)
		gl.Color(cWhite)
	end
	return i,lastY
end

local function drawModOptions()

	--background panel
	gl.Color(cBack)
	gl.Rect(Panel["info"]["x1"],Panel["info"]["y1"], Panel["info"]["x2"], Panel["info"]["y2"])
	
	--border
	gl.Color(cBorder)
	gl.Rect(Panel["info"]["x1"]-1,Panel["info"]["y1"], Panel["info"]["x1"], Panel["info"]["y2"])
	gl.Rect(Panel["info"]["x2"],Panel["info"]["y1"], Panel["info"]["x2"]+1, Panel["info"]["y2"])
	gl.Rect(Panel["info"]["x1"],Panel["info"]["y1"]-1, Panel["info"]["x2"], Panel["info"]["y1"])
	gl.Rect(Panel["info"]["x1"],Panel["info"]["y2"], Panel["info"]["x2"], Panel["info"]["y2"]+1)
	
	-- Heading
	myFontBigger:Begin()
	myFontBigger:SetTextColor(cWhite)
	myFontBigger:Print("XTA Mod options", (Panel["info"]["x1"] + Panel["info"]["x2"])/2 , Panel["info"]["y2"] - 20,18,'cds')
	myFontBigger:End()
	-- content
	local lastY = Panel["info"]["y2"] - 20
	rows = 0
	
	--General options heading
	do
		myFontBig:Begin()
		if Options["general"] and OptionCount["general"] > 0 then
			myFontBig:SetTextColor(cYellow) -- yellow
			myFontBig:Print("General:", Panel["info"]["x1"] + leftmargin, lastY - 40,14,'do')
			lastY = lastY - 40
		end
		myFontBig:End()
		
		--General options
		myFont:Begin()
		local i = 0
		
		for _,opt in pairs(Options["general"]) do
			i,lastY = drawRow(opt,i,lastY)
		end
		myFont:End()
	end
	--Other options heading 
	do
		if Options["other"] and OptionCount["other"] > 0 then
			myFontBig:Begin()
			myFontBig:SetTextColor(cYellow) -- yellow
			myFontBig:Print("More options:", Panel["info"]["x1"] + leftmargin, lastY - 40,14,'do')
			lastY = lastY - 40
			myFontBig:End()
		end
		
		--Other options
		myFont:Begin()
		local i = 0
		for _,opt in pairs(Options["other"]) do
			i,lastY = drawRow(opt,i,lastY)
		end
		myFont:End()
	end
	-- unit packs heading
	do
		if Options["unitpacks"] and OptionCount["unitpacks"] > 0 then
			myFontBig:Begin()
			myFontBig:SetTextColor(cYellow) -- yellow
			myFontBig:Print("Unit packs:", Panel["info"]["x1"] + leftmargin, lastY - 40,14,'do')
			lastY = lastY - 40
			myFontBig:End()
		end
		
		-- unit packs
		myFont:Begin()
		local i = 0
		for _,opt in pairs(Options["unitpacks"]) do
			i,lastY = drawRow(opt,i,lastY)
		end
		myFont:End()
	end
	--multiplier options heading
	do
		if Options["multiplier"] and OptionCount["multiplier"] > 0 then
			myFontBig:Begin()
			myFontBig:SetTextColor(cYellow) -- yellow
			myFontBig:Print("Multiplier settings:", Panel["info"]["x1"] + leftmargin, lastY - 40,14,'do')
			lastY = lastY - 40
			myFontBig:End()
		end
		
		--multiplier options
		myFont:Begin()
		local i = 0
		for _,opt in pairs(Options["multiplier"]) do
			i,lastY = drawRow(opt,i,lastY)
		end
		myFont:End()
	end
	--KOTH options heading
	do
		if Options["koth"] and (Options["koth"][1]["value"] == 1 or Options["koth"][1]["value"] == "1") then
			if Options["koth"] then
				myFontBig:Begin()
				myFontBig:SetTextColor(cYellow) -- yellow
				myFontBig:Print("King of the hill options", Panel["info"]["x1"] + leftmargin, lastY - 40,14,'do')
				lastY = lastY - 40
				myFontBig:End()
			end
			
			--KOTH options
			myFont:Begin()
			local i = 0
			for _,opt in pairs(Options["koth"]) do
				i,lastY = drawRow(opt,i,lastY)
			end
			myFont:End()
		end
	end
	
	--Fleabowl options heading
	do
		
		if (Spring.GetGameRulesParam('Fleabowl') == 1 or Spring.GetGameRulesParam('Fleabowl') == '1') then
			if Options["fleabowl"] then
				myFontBig:Begin()
				myFontBig:SetTextColor(cYellow) -- yellow
				myFontBig:Print("Fleabowl options", Panel["info"]["x1"] + leftmargin, lastY - 40,14,'do')
				lastY = lastY - 40
				myFontBig:End()
			end
			
			--FB options
			myFont:Begin()
			local i = 0
			for _,opt in pairs(Options["fleabowl"]) do
				i,lastY = drawRow(opt,i,lastY)
			end
			myFont:End()
		end
	end
	
	
	--Experimental options heading
	do
		if Options["experimental"] and OptionCount["experimental"] > 0 then
			myFontBig:Begin()
			myFontBig:SetTextColor(cYellow) -- yellow
			myFontBig:Print("Experimental options:", Panel["info"]["x1"] + leftmargin, lastY - 40,14,'do')
			lastY = lastY - 40
			myFontBig:End()
		end
		
		--Experimental options
		myFont:Begin()
		local i = 0
		for _,opt in pairs(Options["experimental"]) do
			i,lastY = drawRow(opt,i,lastY)
		end
		myFont:End()
	end
	-- update height and position of window
	updateHeights()
	
	-- exitbutton
	if ButtonClose.above then
		gl.Color(cAbove)
	else
		gl.Color(cGrey)
	end
	gl.TexRect(ButtonClose["x1"],ButtonClose["y1"],ButtonClose["x2"],ButtonClose["y2"])
	myFontBig:Begin()
	myFontBig:SetTextColor(cWhite)
	myFontBig:Print("Close", (ButtonClose["x1"]+ButtonClose["x2"])/2, (ButtonClose["y1"]+ButtonClose["y2"])/2,14,'vcs')
	myFontBig:End()
		
	--reset state
	gl.Texture(false)
	gl.Color(cWhite)
end

local function drawMapOptions()
	
	--background panel
	gl.Color(cBack)
	gl.Rect(Panel["info"]["x1"],Panel["info"]["y1"], Panel["info"]["x2"], Panel["info"]["y2"])
	
	--border
	gl.Color(cBorder)
	gl.Rect(Panel["info"]["x1"]-1,Panel["info"]["y1"], Panel["info"]["x1"], Panel["info"]["y2"])
	gl.Rect(Panel["info"]["x2"],Panel["info"]["y1"], Panel["info"]["x2"]+1, Panel["info"]["y2"])
	gl.Rect(Panel["info"]["x1"],Panel["info"]["y1"]-1, Panel["info"]["x2"], Panel["info"]["y1"])
	gl.Rect(Panel["info"]["x1"],Panel["info"]["y2"], Panel["info"]["x2"], Panel["info"]["y2"]+1)
	
	-- Heading
	myFontBigger:Begin()
	myFontBigger:SetTextColor(cWhite)
	myFontBigger:Print(Game.mapName, (Panel["info"]["x1"] + Panel["info"]["x2"])/2 , Panel["info"]["y2"] - 20,18,'cds')
	myFontBigger:End()
	-- content
	local lastY = Panel["info"]["y2"] - 20
	rows = 0
	
	--Map options
	do
		myFontBig:Begin()
		if Options["general"] and OptionCount["general"] > 0 then
			myFontBig:SetTextColor(cYellow) -- yellow
			myFontBig:Print("Map options:", Panel["info"]["x1"] + leftmargin, lastY - 40,14,'do')
			lastY = lastY - 40
		end
		myFontBig:End()
		
		--General options
		myFont:Begin()
		local i = 0
		
		for _,opt in pairs(Options["map"]) do
			i,lastY = drawRow(opt,i,lastY)
		end
		myFont:End()
	end
	
	-- update height and position of window
	updateHeights()
	
	-- exitbutton
	if ButtonClose.above then
		gl.Color(cAbove)
	else
		gl.Color(cGrey)
	end
	gl.TexRect(ButtonClose["x1"],ButtonClose["y1"],ButtonClose["x2"],ButtonClose["y2"])
	myFontBig:Begin()
	myFontBig:SetTextColor(cWhite)
	myFontBig:Print("Close", (ButtonClose["x1"]+ButtonClose["x2"])/2, (ButtonClose["y1"]+ButtonClose["y2"])/2,14,'vcs')
	myFontBig:End()
		
	--reset state
	gl.Texture(false)
	gl.Color(cWhite)
end

local function drawSettings()
	
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
	myFontBig:Begin()
	myFontBig:SetTextColor(cWhite)
	myFontBig:Print("XTA game-settings:", Panel["main"]["x1"] + leftmargin, Panel["main"]["y2"] - 20,14,'ds')
	myFontBig:End()
	-- Buttons
	
	-- exit
	if ButtonClose.above then
		gl.Color(cAbove)
	else
		gl.Color(cGrey)
	end
	gl.TexRect(ButtonClose["x1"],ButtonClose["y1"],ButtonClose["x2"],ButtonClose["y2"])
	myFontBig:Begin()
	myFontBig:SetTextColor(cWhite)
	myFontBig:Print("Close", (ButtonClose["x1"]+ButtonClose["x2"])/2, (ButtonClose["y1"]+ButtonClose["y2"])/2,14,'vcs')
	myFontBig:End()
	
	-- other
	for _,button in ipairs(Button) do
		
		myFont:Begin()
		if button["mouse"] then
			myFont:SetTextColor(cLight)
		else
			myFont:SetTextColor(cButton)
		end
		
		myFont:Print(button["label"] or "N/A", posX+leftmargin, button["y1"],12,'do')
		myFont:End()
		
		gl.Color(cWhite)
		
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
	gl.Color(cWhite)
end

local function drawIsAbove(x,y)
	
	if not x or not y then return false end
	
	for _,button in pairs(Button) do
		button["mouse"] = false
	end
	ButtonClose.above = false
	
	for _,button in pairs(Button) do
		if IsOnButton(x, y, button["x1"],button["y1"],button["x2"],button["y2"]) then
			button["mouse"] = true
			return true
		end
	end
	
	if IsOnButton(x, y, ButtonClose["x1"],ButtonClose["y1"],ButtonClose["x2"],ButtonClose["y2"]) then
		ButtonClose.above = true
	end
	
	return false
end

function widget:DrawScreen()
	if (not Spring.IsGUIHidden()) then
		if showModOptions then
			drawModOptions()
		elseif showSettings then
			drawSettings()
		elseif showMapOptions then
			drawMapOptions()
		end
	end
end

function widget:IsAbove(x,y)
	if (not Spring.IsGUIHidden()) then
		if showModOptions or showSettings or showMapOptions then
			drawIsAbove(x,y)
		end
	end
	--this callin must be present, otherwise function widget:TweakIsAbove(x,y) isn't called. Maybe a bug in widgethandler.
end

function widget:TextCommand(command)
	
	if command == 'draw' or command == 'votefordraw' then
		Spring.SendCommands("luarules votefordraw")
	elseif command == 'voting' or command == 'voteforend'then
		Spring.SendCommands("luarules voteforend")
	elseif command == 'show-modoptions' then
		showModOptions = true
	elseif command == 'show-mapoptions' then
		showMapOptions = true
	elseif command == 'xta-options' then
		showSettings = true
	end
end

function widget:MouseMove(mx, my, dx, dy, mButton)
	
      --Dragging
     if mButton == 2 or mButton == 3 then
		 posX = math.max(0, math.min(posX+dx, vsx-width))	--prevent moving off screen
		 posY = math.max(0, math.min(posY+dy, vsy-height))
		 InitButtons()
     end
 end 
 
function widget:MousePress(x, y, button)
	 if button == 1 and (showSettings or showModOptions or showMapOptions) then
		
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
		if IsOnButton(x, y, ButtonClose["x1"],ButtonClose["y1"],ButtonClose["x2"],ButtonClose["y2"]) then
			PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
			showSettings = false
			showModOptions = false
			showMapOptions = false
		end
		
	elseif button == 2 or button == 3 then
		if (showModOptions or showMapOptions) and IsOnButton(x, y, Panel["info"]["x1"],Panel["info"]["y1"], Panel["info"]["x2"], Panel["info"]["y2"]) then			
			--Dragging
			return true			
		elseif showSettings and IsOnButton(x, y, Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"]) then
			--Dragging
			return true
		end
	end
	return false
 end
 
function widget:KeyPress(key, mods, isRepeat) 
	if (key == 0x069) and mods["ctrl"] and (not isRepeat) then 				-- i-key
		showModOptions = not showModOptions
		return true
	elseif key == 0x01B then -- ESC
		showModOptions = false
		showMapOptions = false
		showSettings = false
		return false
	elseif key == 0x124 and mods.ctrl then -- CTRL-F11
		showSettings = true
		return false
	end
	return false
end

--------------------------------------------------------------------------------			 
-- Tweak-mode
--------------------------------------------------------------------------------

function widget:TweakDrawScreen()
	if showSettings then
		drawSettings()
	end
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
		
		if IsOnButton(x, y, ButtonClose["x1"],ButtonClose["y1"],ButtonClose["x2"],ButtonClose["y2"]) then
			PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
			showSettings = false
			showModOptions = false
			showMapOptions = false
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
 