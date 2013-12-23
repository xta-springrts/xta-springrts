local versionNumber = "1.0"

function widget:GetInfo()
	return {
		name      = "Clock",
		desc      = "Display real world clock",
		author    = "Jools",
		date      = "Dec, 2013",
		license   = "All rights reserved",
		layer     = 0,
		enabled   = true,
	}
end

local Echo							= Spring.Echo
local glColor 						= gl.Color
local glRect						= gl.Rect
local glText 						= gl.Text
local max							= math.max
local min							= math.min

local vsx, vsy 						= gl.GetViewSizes()
local px							= 3*vsx/4
local py							= 3*vsy/4
local sizex							= 60
local sizey							= 24
local digitsize						= 14
local Button						= {}
Button["clock"]						= {}
local hours, minutes,timestring

local function initButtons()
	Button["clock"]["x0"] = px
	Button["clock"]["x1"] = px + sizex
	Button["clock"]["y0"] = py
	Button["clock"]["y1"] = py + sizey
end

function widget:Initialize()
	initButtons()
end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY
end

function widget:Update() 	
	minutes = os.date("%M")	
	hours = os.date("%H")
	timestring = hours ..":"..minutes
end

function widget:DrawScreen()
	if Spring.IsGUIHidden() then return end
	
	glColor(0, 0, 0, 0.4)
	glRect(Button["clock"]["x0"],Button["clock"]["y0"], Button["clock"]["x1"], Button["clock"]["y1"])
	
	glColor(0.2, 0.5, 1, 1) -- cerulean blue
	-- Highlight
	if Button["clock"]["mouse"] then
		glColor(1, 1, 1, 1)
	end
	
	if timestring then
		glText(timestring, Button["clock"]["x0"]+10,Button["clock"]["y0"]+8, digitsize, 'x')
	end
	
	glColor(1, 1, 1, 1)
end

function widget:IsAbove(mx,my)	
	Button["clock"]["mouse"] = false
	if IsOnButton(mx,my,Button["clock"]["x0"],Button["clock"]["y0"],Button["clock"]["x1"],Button["clock"]["y1"]) then		
		Button["clock"]["mouse"] = true
	end	
end

function widget:MousePress(mx, my, mButton)
	if (mButton == 2 or mButton == 3) and mx < px + sizex then
		if mx >= px and my >= py and my < py + sizey then
			-- Dragging
			return true
		end
	end
end

function widget:MouseMove(mx, my, dx, dy, mButton)
    -- Dragging
    if mButton == 2 or mButton == 3 then
		px = max(0, min(px+dx, vsx-sizex))	--prevent moving off screen
		py = max(0, min(py+dy, vsy-sizey))
		initButtons()
	end
end

function widget:GetConfigData(data)      -- save
	local vsx, vsy = gl.GetViewSizes()
	return {
			vsx                = vsx,
			vsy                = vsy,
			px         = px,
			py         = py,
		}
	end

function widget:SetConfigData(data)      -- load
	vsx					= data.vsx or vsx
	vsy 				= data.vsy or vsy
	px         	= data.px or px
	py         	= data.py or py
end
