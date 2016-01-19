function widget:GetInfo()
   return {
      name      = "XTA Options",
      desc      = "Provide a GUI for some options",
      author    = "Jools",
      date      = "jan, 2014",
      license   = "GNU GPL, v2 or later",
      layer 	= 5,
      enabled   = true,  --  loaded by default?
	  handler	= true,
	}
end

local posX, posY					  	= 600, 400
local buttonsize					  	= 16
local tabWidth							= 90
local tabHeight							= 20
local Echo								= Spring.Echo
local Button, Section, Presets 			= include("configs/settings_defs.lua")
local maxbuttons						= 4


for i,section in pairs(Section) do
	local n = 0
	for j,button in pairs(Button) do
		if button.section == section.name then
			n = button.type == "scale" and n + 1.75 or n + 1
			maxbuttons = math.max(maxbuttons,n)
		end
	end
end		

local rowgap						  	= 26
local iRowHeight						= 14
local width, height					  	= 640, 120 + maxbuttons*(rowgap+iRowHeight)
local iWidth							= 400

local rows								= 0
local height0							= 160
local iHeight

local scaleWidth						= width/3
local scaleOffset						= 50
local margin							= 10
local rmargin 							= 60
local lmargin 							= 60
local buttontab							= width - buttonsize - rmargin
local vsx, vsy 						  	= gl.GetViewSizes()
local PlaySoundFile						= Spring.PlaySoundFile
local showModOptions					= false
local showMapOptions					= false
local showSettings						= false
local textSize							= 10
local myFont							= gl.LoadFont("FreeSansBold.otf",textSize, 1.9, 40)
local myFontBig							= gl.LoadFont("FreeSansBold.otf",14, 1.9, 40)
local myFontBigger						= gl.LoadFont("FreeSansBold.otf",18, 1.9, 40)
local bgcorner							= "luaui/images/bgcorner.png"

-- images
local optContrast						= "LuaUI/Images/tweaksettings/contrast.png"
local optCheckBoxOn						= "LuaUI/Images/tweaksettings/chkBoxOn.png"
local optCheckBoxOff					= "LuaUI/Images/tweaksettings/chkBoxOff.png"
local imgArrows							= "LuaUI/Images/tweaksettings/arrows.png"
local imgMarker							= "luaui/images/commchange/duck.png"

--sounds
local sndButtonOn 						= 'sounds/button8.wav'
local sndButtonOff 						= 'sounds/button6.wav'
local sndButtonTab 						= 'sounds/button5.wav'
local sndButtonSlide					= 'sounds/button3.wav'
local sndButtonDone						= 'sounds/butmain.wav'

-- other
local ButtonClose		 				= {}
local Panel					  			= {}
local FirstButtonYes					= {}
local FirstButtonNo						= {}

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
local currentSection					= "graphics"
local currentPreset						= nil
local configured						= false

--colors
local cLight 							= {1,1,1,1}
local cLight2 							= {0.9,0.9,1,0.4}
local cWhite 							= {1,1,1,1}
local cButton							= {0.8,0.8,0.8,1}
local cSelect							= {0.4, 0.4, 0.8, 1}
local cSection							= {0.33,0.33,0.33,0.2}
local cBack								= {0, 0, 0, 0.3}
local cGreen							= {0.2, 0.8, 0.2, 1}
local cRed								= {0.8, 0.2, 0.2, 1}
local cBlue								= {0.6, 0.6, 0.8, 1}
local cGrey								= {0.8, 0.8, 0.8, 0.2}
local cDark								= {0.4, 0.4, 0.4, 0.2}
local cYellow							= {0.8, 0.8, 0.2, 0.4}
local cYellow2							= {0.8, 0.8, 0.2, 0.3}
local cRow								= {0.2,0.6,0.9,0.1}
local cBorder							= {0, 0, 0, 0.6}
local cAbove							= {0.8,0.8,0,0.5}
local cText								= {0.8,0.8,0.4,0.55}
local cText2							= {0.8,0.8,0.6,0.75}


--------------------------------------------------------------------------------			 
-- Local functions
--------------------------------------------------------------------------------

local function RefreshOptions()
	Button,_,_  = include("configs/settings_defs.lua")
	InitButtons()
end

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
	
	Panel["main"]					= {}
	Panel["info"]					= {} -- info screen with mod options
	Panel["firsttimer"]				= {} -- info screen with mod options
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
	
	-- positions
	for i, button in ipairs(Section) do
		button.chosen 			= button.name == currentSection
		button.x1				= posX + (i-1) * tabWidth + lmargin
		button.x2				= button.x1 + tabWidth
		button.y1				= posY	+ height - tabHeight - 60
		button.y2				= button.y1 + tabHeight
	end
	
	local n = 1
	for name,button in pairs(Button) do
		if currentSection == button["section"] then
			button["x1"] 	= posX + buttontab
			button["x2"]	= button["x1"] + buttonsize
			button["y1"]	= posY + height - 100 - n*rowgap - buttonsize
			button["y2"]	= button["y1"] + buttonsize
			n 				= n+1
			if button.type then
				if button.type == "scale" then
					button.x0	= button.x2 - scaleWidth
					n = n+1
				end
			end
		end
	end	
	
	
	
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
	
	Panel["firsttimer"]["x1"]	= 400		
	Panel["firsttimer"]["x2"]	= 800
	Panel["firsttimer"]["y1"]	= 440
	Panel["firsttimer"]["y2"]	= 600
	
	local row = 0
	local column = 0
	local w = width/3.66
	local h = w
	local b = 60
	local m = 50
	
	FirstButtonYes["x1"]		= Panel["firsttimer"]["x1"] + 80
	FirstButtonYes["x2"]		= FirstButtonYes["x1"] + 100
	FirstButtonYes["y1"]		= Panel["firsttimer"]["y1"] + 20
	FirstButtonYes["y2"]		= FirstButtonYes["y1"] + 20
	FirstButtonYes["label"]		= "Yes, please!"
	
	FirstButtonNo["x2"]			= Panel["firsttimer"]["x2"] - 80
	FirstButtonNo["x1"]			= FirstButtonNo["x2"] - 100
	FirstButtonNo["y1"]			= Panel["firsttimer"]["y1"] + 20
	FirstButtonNo["y2"]			= FirstButtonNo["y1"] + 20
	FirstButtonNo["label"]		= "Not now."
	
	
	for i, button in ipairs(Presets) do
		button.above 			= false
		button.x1				= Panel["main"]["x1"] + column * w + 100
		button.x2				= button.x1 + w - b
		button.y1				= Panel["main"]["y2"] - row * h - 230 - row*m
		button.y2				= button.y1 + h - b
		
		if column < 2 then
			column = column +1
		else
			column = 0
			row = row +1
		end
	end
	
end

--------------------------------------------------------------------------------			 
-- Callins
--------------------------------------------------------------------------------

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

local function RectRound(px,py,sx,sy,cs)
	cs = cs or 6
	local px,py,sx,sy,cs = math.floor(px),math.floor(py),math.ceil(sx),math.ceil(sy),math.floor(cs)
	
	gl.Texture(bgcorner)
	gl.BeginEnd(GL.QUADS, DrawRectRound, px,py,sx,sy,cs)
	gl.Texture(false)
end

local function DrawBorder(x0, y0, x1, y1, width)
	return RectRound(x0-1, y0-1, x1+1, y1+1,6) 
end

local function drawRow(optData,i,lastY)
	local name = optData["name"]
	local type = optData["type"]
	local value = optData["value"]
	
	local yi = lastY - 14
	lastY = lastY - 14
	
	local label = formatLabel(value,type,name)
	
	if label ~= "N/A" and type then
		myFont:Print(label, Panel["info"]["x2"] - margin, yi,textSize,'rdo')
		myFont:SetTextColor(cButton)
		myFont:Print(name, Panel["info"]["x1"] + margin, yi,textSize,'do')
		i = i + 1
		rows = rows + 1
	else
		lastY = lastY + 14
	end
	myFont:SetTextColor(cButton)
	
	if i%2 ~= 0 and type and label ~= "N/A" then
		gl.Color(cRow)
		gl.Rect(Panel["info"]["x1"]+ margin, yi, Panel["info"]["x2"]-margin,yi + 14)
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
			myFontBig:Print("General:", Panel["info"]["x1"] + margin, lastY - 40,14,'do')
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
			myFontBig:Print("More options:", Panel["info"]["x1"] + margin, lastY - 40,14,'do')
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
			myFontBig:Print("Unit packs:", Panel["info"]["x1"] + margin, lastY - 40,14,'do')
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
			myFontBig:Print("Multiplier settings:", Panel["info"]["x1"] + margin, lastY - 40,14,'do')
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
				myFontBig:Print("King of the hill options", Panel["info"]["x1"] + margin, lastY - 40,14,'do')
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
				myFontBig:Print("Fleabowl options", Panel["info"]["x1"] + margin, lastY - 40,14,'do')
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
			myFontBig:Print("Experimental options:", Panel["info"]["x1"] + margin, lastY - 40,14,'do')
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
			myFontBig:Print("Map options:", Panel["info"]["x1"] + margin, lastY - 40,14,'do')
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
	
	local function DrawLine(x0, y0, x1, y1)
		gl.Vertex(x0, y0)
		gl.Vertex(x1, y1)
	end
	
	--border
	gl.Color(cBorder)
	DrawBorder(Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"])
	
	--background panel
	gl.Color(cBack)
	RectRound(Panel["main"]["x1"],Panel["main"]["y1"], Panel["main"]["x2"], Panel["main"]["y2"])
	
	-- Heading
	myFontBigger:Begin()
	myFontBigger:SetTextColor(cWhite)
	myFontBigger:Print("XTA game-settings", Panel["main"]["x1"]+width/2, Panel["main"]["y2"] - 30,18,'dcs')
	myFontBigger:End()
	
	-- Sections
	for i, button in pairs(Section) do
		--border
		
		gl.Color(cBorder)
		DrawBorder(button["x1"],button["y1"], button["x2"], button["y2"])
		
		--background panel
		if button.chosen then
			gl.Color(cSelect)
		elseif button.mouse then
			gl.Color(cAbove)
		else
			gl.Color(cSection)
		end
		RectRound(button["x1"],button["y1"], button["x2"], button["y2"])
	
		myFontBig:Begin()
		myFontBig:SetTextColor(cWhite)
		myFontBig:Print(button.label, (button.x1+button.x2)/2 , button.y1,14,'dco')
		myFontBig:End()
	
	end
	
	-- Presets
	
		if currentSection == 'presets' then
			
			for _,preset in pairs(Presets) do
								
				myFontBig:Begin()
				myFontBig:SetTextColor(cWhite)
				myFontBig:Print(preset.label, (preset.x1+preset.x2)/2, preset.y1-30,14,'dcs')
				myFontBig:End()
				
				myFont:Begin()
				myFont:SetTextColor(cText)
				myFont:Print(preset.desc, preset.x1, preset.y1-45,10,'do')
				myFont:Print(preset.desc2, preset.x1, preset.y1-60,10,'do')
				myFont:Print(#preset.widgets .. " widgets and " .. #preset.settings .. " settings", preset.x1, preset.y1-75,10,'do')
				myFont:End()
				
				if preset.mouse then
					gl.Color(cLight2)
				else
					gl.Color(cDark)
				end
				RectRound(preset.x1,preset.y1,preset.x2,preset.y2,4)
				
				gl.Texture(preset.image)
				if preset.label == currentPreset then
					gl.Color(cWhite)
				else
					gl.Color(cYellow)
				end
				gl.TexRect(preset.x1,preset.y1,preset.x2,preset.y2)
				gl.Texture(false)
				
				
			end
			
		end
	
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
	for _,button in pairs(Button) do
		if currentSection == button["section"] then
			myFont:Begin()
			if button["mouse"] then
				myFont:SetTextColor(cLight)
			else
				myFont:SetTextColor(cButton)
			end
			
			myFont:Print(button["label"] or "N/A", posX+lmargin, button["y1"],12,'do')
			myFont:End()
			
			gl.Color(cWhite)
			
			if not button.type then
				if button["value"] then
					gl.Texture(optCheckBoxOn)
				else
					gl.Texture(optCheckBoxOff)
				end
				gl.TexRect(button["x1"],button["y1"],button["x2"],button["y2"])
				gl.Texture(false)
			elseif button.type == "scale" then
				local size = 20
				local ymid = button.y1 + (button.y2-button.y1)/2
				local offset = scaleOffset
				local desc = button.items[button.newValue] or button.items[button.value]
								
				local y1	= button.y1 + buttonsize/4
				local y2	= button.y2 - buttonsize/4
								
				local w = button.x2 - button.x0
				local dx = w/(button.max-button.min)
				
				gl.Color(cDark)
				RectRound(button.x0-offset,button.y1,button.x2-offset,button.y2,2)
				gl.Color(cYellow)
				
				if (button.max - button.min) / button.step > 50 then
					for x =button.min,button.max,button.step do
						if ((x-button.min)/button.step)%10 == 0 or x == button.min or x == button.max then
							gl.Color(cYellow)
							RectRound(button.x0+(x-button.min)*dx-offset,button.y1+buttonsize/4,button.x0+(x-button.min)*dx+1-offset,button.y2-buttonsize/4,1)
						end
					end
				elseif  (button.max - button.min) / button.step > 20 then
					for x =button.min,button.max,button.step do
						if ((x-button.min)/button.step)%5 == 0 or x == button.min or x == button.max then
							gl.Color(cYellow)
							RectRound(button.x0+(x-button.min)*dx-offset,button.y1+buttonsize/4,button.x0+(x-button.min)*dx+1-offset,button.y2-buttonsize/4,1)
						end
					end
				else				
					for x =button.min,button.max,button.step do
						RectRound(button.x0+(x-button.min)*dx-offset,button.y1+buttonsize/4,button.x0+(x-button.min)*dx+1-offset,button.y2-buttonsize/4,1)
					end
				end
				
				gl.LineWidth (1)
				gl.LineStipple(1,4369)
				gl.BeginEnd(GL.LINE_STRIP, DrawLine,button.x0-offset , ymid,button.x2-offset,ymid)
				gl.LineStipple(false)
				gl.Texture(imgMarker)
								
				if (not button.newValue) or button.value == button.newValue then
					gl.Color(cWhite)
					gl.TexRect(button.x0+(button.value-button.min)*dx-size/2-offset,ymid-size/2,button.x0+(button.value-button.min)*dx+size/2-offset,ymid+size/2)
				else
					gl.Color(cBlue)
					gl.TexRect(button.x0+(button.newValue-button.min)*dx-size/2-offset,ymid-size/2,button.x0+(button.newValue-button.min)*dx+size/2-offset,ymid+size/2)
				end
				gl.Texture(false)
				
				gl.Color(cDark)
				RectRound(button.x1-buttonsize,button.y1,button.x2,button.y2,2)
				
				local str = button.newValue and tostring(button.newValue) or tostring(button.value)
				if str:find("%.") then -- FIXME: only supports integers or 1 decimal values
					str = string.format("%.1f",str)
				end
				
				myFont:Begin()
				myFont:SetTextColor(cButton)
				myFont:Print(str or "?", button.x2-buttonsize/4, button.y1,10,'drs')
				myFont:Print(desc or "", button.x2-buttonsize/4, button.y1-size,10,'drs')
				myFont:End()
				
			end
		end
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
	for _,button in pairs(Section) do
		button["mouse"] = false
	end
	
	for _,button in pairs(Presets) do
		button["mouse"] = false
	end
	
	ButtonClose.above = false
	
	for _,button in pairs(Section) do
		if IsOnButton(x, y, button["x1"],button["y1"],button["x2"],button["y2"]) then
			button["mouse"] = true
			return true
		end
	end
	
	for _,button in pairs(Presets) do
		if IsOnButton(x, y, button["x1"],button["y1"],button["x2"],button["y2"]) then
			button["mouse"] = true
			return true
		end
	end
	
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
	
		if not configured then
			-- first time message
			
			--border
			gl.Color(cBorder)
			DrawBorder(Panel["firsttimer"]["x1"],Panel["firsttimer"]["y1"], Panel["firsttimer"]["x2"], Panel["firsttimer"]["y2"])
	
			--background panel
			gl.Color(cBack)
			RectRound(Panel["firsttimer"]["x1"],Panel["firsttimer"]["y1"], Panel["firsttimer"]["x2"], Panel["firsttimer"]["y2"])
			
			--buttons
			if FirstButtonYes.mouse then 
				gl.Color(cAbove)
			else
				gl.Color(cSection)
			end
			
			RectRound(FirstButtonYes["x1"],FirstButtonYes["y1"], FirstButtonYes["x2"], FirstButtonYes["y2"])
			DrawBorder(FirstButtonYes["x1"],FirstButtonYes["y1"], FirstButtonYes["x2"], FirstButtonYes["y2"])
			
			if FirstButtonNo.mouse then 
				gl.Color(cAbove)
			else
				gl.Color(cSection)
			end
			RectRound(FirstButtonNo["x1"],FirstButtonNo["y1"], FirstButtonNo["x2"], FirstButtonNo["y2"])
			DrawBorder(FirstButtonNo["x1"],FirstButtonNo["y1"], FirstButtonNo["x2"], FirstButtonNo["y2"])
			
			myFontBig:Begin()
			myFontBig:SetTextColor(cWhite)
			myFontBig:Print("Welcome to XTA!", (Panel["firsttimer"]["x1"]+Panel["firsttimer"]["x2"])/2, Panel["firsttimer"]["y2"]-20,14,'vcs')
			myFontBig:SetTextColor(cText2)
			myFontBig:Print("Do you want to select a different layout preset?",Panel["firsttimer"]["x1"] + 20, Panel["firsttimer"]["y2"]-70,14,'do')
			myFontBig:End()
			
			myFont:Begin()
			myFont:SetTextColor(cWhite)
			
			myFont:Print(FirstButtonNo.label,(FirstButtonNo["x1"]+FirstButtonNo["x2"])/2,FirstButtonNo["y1"],12,'dcs')
			myFont:Print(FirstButtonYes.label,(FirstButtonYes["x1"]+FirstButtonYes["x2"])/2,FirstButtonYes["y1"],12,'dcs')
			myFont:End()
			
		end
	
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
		
		if not configured then
			FirstButtonNo["mouse"] = false
			FirstButtonYes["mouse"] = false
			if IsOnButton(x, y, FirstButtonNo["x1"],FirstButtonNo["y1"],FirstButtonNo["x2"],FirstButtonNo["y2"]) then
				FirstButtonNo["mouse"] = true
			elseif IsOnButton(x, y, FirstButtonYes["x1"],FirstButtonYes["y1"],FirstButtonYes["x2"],FirstButtonYes["y2"]) then
				FirstButtonYes["mouse"] = true
			end
		end
	end
	--this callin must be present, otherwise function widget:TweakIsAbove(x,y) isn't called. Maybe a bug in widgethandler.
end

local function SetGuiOpacity(value)
	Echo("Setting opacity to:" .. value)
	local oldvalue = tonumber(Spring.GetConfigString("GuiOpacity"))
	local deciold = round(10*oldvalue,0)
	local decinew = round(10*tonumber(value),0)
		
	if deciold == decinew then
		return
	elseif deciold < decinew then
		repeat
			deciold = deciold + 1
			Spring.SendCommands("IncGUIOpacity")
		until deciold >= decinew or deciold >= 10
	elseif deciold > decinew then
		repeat
			deciold = deciold - 1
			Spring.SendCommands("DecGUIOpacity")	
		until deciold <= decinew or deciold <= 0
	end
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
	elseif command == 'xta-options' or command == 'settings' then
		showSettings = true
	elseif string.lower(command):find("^setguiopacity") then
		local value = command:sub(14)
		if value then
			SetGuiOpacity(value)
		end
	end
end

local function GetNearestvalue(x,xmin,xmax,vmin,vmax,vstep)
		
	local xscale = xmax-xmin
	local vscale = vmax-vmin
	
	local val = (x-xmin)/xscale
	
	if val <= 0 then 
		return vmin
	elseif val >= 1 then
		return vmax
	end
	
	local e = vmin
	local smaller = e
	local larger = vmin + vstep
	
	while e < vmax do
		local t = vmin + val * vscale
				
		if e < t then
			smaller = e
			larger = e + vstep
		end
		e = e + vstep
	end
	
	local distUp = larger - val * vscale
	local distDown	= val * vscale - smaller
	local target = distDown > distUp and larger or smaller
	if not target then return end
	
	return target
end

function widget:MouseMove(mx, my, dx, dy, mButton)
	
	if mButton == 1 then
		for _,button in pairs(Button) do
			if button.section == currentSection then
				if button.type == "scale" then
					if IsOnButton(mx, my, button.x0-scaleOffset,button.y1,button.x2-scaleOffset,button.y2) and 
						mx+dx < button.x2-scaleOffset and mx+dx > button.x0-scaleOffset then
						 
						local newValue = GetNearestvalue(mx+dx,button.x0-scaleOffset,button.x2-scaleOffset,button.min,button.max,button.step)
						
						if newValue and tostring(newValue):find("%.") then
							local str = tostring(newValue)
							local dec = str:find("%.")
							local dstr = dec and str:sub(1,dec+1) or str
							newValue = dstr
						else
							newValue = tostring(newValue)
						end
						button.newValue = newValue
						return true
						
					elseif my < button.y2 and my > button.y1 then
						if mx+dx < button.x0-scaleOffset then
							button.newValue = tostring(button.min)
							return true
						elseif mx+dx > button.x2-scaleOffset then
							button.newValue = tostring(button.max)
							return true
						end
					end
				end
			end
		end
	end
	
	
      --Dragging
     if mButton == 2 or mButton == 3 then
		 posX = math.max(0, math.min(posX+dx, vsx-width))	--prevent moving off screen
		 posY = math.max(0, math.min(posY+dy, vsy-height))
		 InitButtons()
     end
 end 
 
function widget:MousePress(x, y, button)
	 if button == 1 and (showSettings or showModOptions or showMapOptions) then
		
		for _,button in pairs(Button) do
			if button.section == currentSection then
				if not button.type then --checkbox
					if IsOnButton(x, y, button["x1"],button["y1"],button["x2"],button["y2"]) then
						if not button["value"] then
							PlaySoundFile(sndButtonOn,1.0,0,0,0,0,0,0,'userinterface')
						else
							PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
						end
						currentPreset = nil
						
						if button.value then
							button.deaction[1](button.deaction[2],button.deaction[3])
						else
							button.action[1](button.action[2],button.action[3])
						end
						button["value"] = not button["value"]
						
						if button.key == "noob-buttons" then
							if button.value then
								widgetHandler:DisableWidget("Hide commands")
							else
								widgetHandler:EnableWidget("Hide commands")
							end
						end
						
						if button.reloadwidgets then
							for _, widgetName in pairs(button.reloadwidgets) do
								if widgetHandler.knownWidgets[widgetName].active then
									Echo("Reloading widget:",widgetName)
									widgetHandler:DisableWidget(widgetName)
									widgetHandler:EnableWidget(widgetName)
								end
							end
						end
						RefreshOptions()
						
						return true
					end
				else
					if button.type == "scale" then
						if IsOnButton(x, y, button.x0-scaleOffset,button.y1,button.x2-scaleOffset,button.y2) then
							local newValue = GetNearestvalue(x,button.x0-scaleOffset,button.x2-scaleOffset,button.min,button.max,button.step)
							if newValue and tostring(newValue):find("%.") then
								newValue = 0.1*math.floor(10 * newValue+0.5)
								local str = tostring(newValue)
								local dec = str:find("%.")
								local dstr = dec and str:sub(1,dec+1) or str
								newValue = dstr
							else
								newValue = tostring(newValue)
							end
							
							if newValue and newValue ~= button.newValue then
								button.newValue = newValue
							end
							
							return true
						end
					end
				end	
			end
		end
		
		for _,button in pairs(Section) do
			if IsOnButton(x, y, button["x1"],button["y1"],button["x2"],button["y2"]) then
				if not button.chosen then				
					currentSection = button.name
					PlaySoundFile(sndButtonTab,4.0,0,0,0,0,0,0,'userinterface')
					InitButtons()
					return true
				end
			end	
		end
		
		local myName = widget:GetInfo().name
		
		if currentSection == "presets" then
			for _,button in pairs(Presets) do
							
				if IsOnButton(x, y, button["x1"],button["y1"],button["x2"],button["y2"]) then
					PlaySoundFile(sndButtonOff,4.0,0,0,0,0,0,0,'userinterface')
					InitButtons()				
					
					if button.settings and #button.settings > 0 then
						
						for _,setting in pairs (button.settings) do
							if #setting == 2 then
								setting[1](setting[2])
								--Echo("Settings:",setting[1],setting[2])
							elseif #setting == 3 then
								setting[1](setting[2],setting[3])
								--Echo("Settings:",setting[1],setting[2],setting[3])
							end
						end
						
						PlaySoundFile(sndButtonDone,4.0,0,0,0,0,0,0,'userinterface')
					end
					
					if button.widgets and #button.widgets > 0 then
						
						Echo("Loading preset: " .. button.label)
						for name,data in pairs(widgetHandler.knownWidgets) do
							--Echo("Processing widget:",name,data)
							if name ~= myName then
								widgetHandler:DisableWidget(name)
							end
						end
						
						for _,wname in pairs (button.widgets) do
							widgetHandler:EnableWidget(wname)
						end
						
						for _,noobButton in pairs(Button) do
							if noobButton.key == "noob-buttons" then
								if noobButton.value then
									widgetHandler:DisableWidget("Hide commands")
								else
									widgetHandler:EnableWidget("Hide commands")
								end
							end
						end
						
						widgetHandler:SaveConfigData()
						currentPreset = button.label
						Echo("... Done!")
						PlaySoundFile(sndButtonDone,4.0,0,0,0,0,0,0,'userinterface')
					end
					
					
					
					RefreshOptions()
					return true
				end	
			end
		end
		
		if IsOnButton(x, y, ButtonClose["x1"],ButtonClose["y1"],ButtonClose["x2"],ButtonClose["y2"]) then
			PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
			showSettings = false
			showModOptions = false
			showMapOptions = false
		end
	elseif button == 1 and not configured then
		if IsOnButton(x, y, FirstButtonNo["x1"],FirstButtonNo["y1"],FirstButtonNo["x2"],FirstButtonNo["y2"]) then
			configured = true
			InitButtons()
			PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
		elseif IsOnButton(x, y, FirstButtonYes["x1"],FirstButtonYes["y1"],FirstButtonYes["x2"],FirstButtonYes["y2"]) then
			showSettings = true
			configured = true
			currentSection = 'presets'
			InitButtons()
			PlaySoundFile(sndButtonOff,1.0,0,0,0,0,0,0,'userinterface')
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
 
function widget:MouseRelease(x, y, button)
	if button == 1 and (showSettings or showModOptions or showMapOptions) then
		for _,button in pairs(Button) do
			if button.section == currentSection and button.type and button.type == "scale" then	
				
				if button.x0 and IsOnButton(x, y, button.x0-scaleOffset,button.y1,button.x2-scaleOffset,button.y2) then
					if button.x0 and button.newValue then
						x = math.max(x,button.x0-scaleOffset)
						x = math.min(x,button.x2-scaleOffset)
						
						button.value = button.newValue
						
						if button.action and #button.action == 3 then
							if button.action[3] == -1 then
								button.action[1](table.concat({button.action[2]," ",button.value}))
							elseif button.action[3] == -2 then
								Echo("MR:",button.key,#button.action,button.action[1],button.action[2])
								button.action[1](button.action[2],button.value)
							else
								button.action[1](button.action[2],button.action[3])
							end
							PlaySoundFile(sndButtonSlide,1.0,0,0,0,0,0,0,'userinterface')
							currentPreset = nil
						elseif button.action and #button.action == 2 then
							--Echo("MR:",button.key,button.value)
							button.action[1](button.action[2],button.value)
							PlaySoundFile(sndButtonSlide,1.0,0,0,0,0,0,0,'userinterface')
							currentPreset = nil
						end
						if button.reloadwidgets then
							for _, widgetName in pairs(button.reloadwidgets) do
								if widgetHandler.knownWidgets[widgetName].active then
									Echo("Reloading widget:",widgetName)
									widgetHandler:DisableWidget(widgetName)
									widgetHandler:EnableWidget(widgetName)
								end
							end
						end
						
					end
					RefreshOptions()
					return true
				elseif button.newValue and button.value ~= button.newValue then
					if y < button.y2 and y > button.y1 then 
						
						button.value = button.newValue
						
						if button.action and #button.action == 3 then
							if button.action[3] == -1 then
								button.action[1](table.concat({button.action[2]," ",button.value}))
							elseif button.action[3] == -2 then
								button.action[1](button.action[2],button.value)
							else
								button.action[1](button.action[2],button.action[3])
							end
						elseif button.action and #button.action == 2 then
							button.action[1](button.action[2],button.value)
						end
						
						PlaySoundFile(sndButtonSlide,1.0,0,0,0,0,0,0,'userinterface')
						currentPreset = nil						
						
					else
						button.newValue = button.value
						RefreshOptions()
					end						
				end
			end
		end
	end
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
	end
	return false
end

function widget:GetConfigData(data)      -- save
	local vsx, vsy = gl.GetViewSizes()
	return {
			posX         		= posX,
			posY         		= posY,
			configured			= configured,
		}
	end

function widget:SetConfigData(data)      -- load
	configured				= data.configured or false
	posX         			= data.posX or posX
	posY         			= data.posY or posY
end
 