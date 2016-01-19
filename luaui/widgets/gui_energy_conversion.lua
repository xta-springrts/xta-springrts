
function widget:GetInfo()
	return {
		name      = 'Energy Conversion Info',
		desc      = 'Displays energy conversion info',
		author    = 'Niobium(modified for XTA by Deadnight Warrior)',
		date      = 'May 2011',
		license   = 'GNU GPL v2',
		layer     = 0,
		enabled   = true,
		handler   = true
	}
end

-- Updates: 2014.09: Made it possible to unload widget and handle mmakers manually. Jools.

--------------------------------------------------------------------------------
-- Var
--------------------------------------------------------------------------------
local alterLevelFormat = string.char(137) .. '%i'
local operationPrefix = 'energyconversion:'

local X, Y = Spring.GetViewGeometry()
local px, py = 500, 100
local sx, sy = 140, 72
local scaling, fontSize, col1, col2, row1, row2, row3, row4
local onsidemargin = 2
local vsx, vsy 						= gl.GetViewSizes()

local hoverLeft, hoverRight, hoverBottom, hoverTop, barBottom, barTop
--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local format = string.format
local floor = math.floor
local bgcorner		= "luaui/images/bgcorner.png"

local glColor = gl.Color
local glRect = gl.Rect
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text
local Echo = Spring.Echo

local spGetMyTeamID = Spring.GetMyTeamID
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spGetSpectatingState = Spring.GetSpectatingState
local CMD_ENERGYCONVERT	= 39310
local displayWindow = true
--------------------------------------------------------------------------------
-- Funcs
--------------------------------------------------------------------------------
local function drawBorder(x0, y0, x1, y1, width)
	return RectRound(x0-1, y0-1, x1+1, y1+1,6) 
	
	--glRect(x0, y0, x1, y0 + width)
	--glRect(x0, y1, x1, y1 - width)
	--glRect(x0, y0, x0 + width, y1)
	--glRect(x1, y0, x1 - width, y1)
end

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
		
function RectRound(px,py,sx,sy,cs)
	cs = cs or 2
	local px,py,sx,sy,cs = math.floor(px),math.floor(py),math.ceil(sx),math.ceil(sy),math.floor(cs)
	
	gl.Texture(bgcorner)
	gl.BeginEnd(GL.QUADS, DrawRectRound, px,py,sx,sy,cs)
	gl.Texture(false)
end

function widget:Initialize()
	local playerID = Spring.GetMyPlayerID()
	local _, _, spec, _, _, _, _, _ = Spring.GetPlayerInfo(playerID)
	
	if ( spec == true ) then
		Spring.Echo("widget", LOG.INFO, "<Energy Conversion Info> Spectator mode. Widget removed.")
		displayWindow = false
		widgetHandler:RemoveWidget(self)
		return false
	end
	scaling = Y/1200
	sx, sy, fontSize = sx*scaling, sy*scaling, 12*scaling
	col1, col2, row1, row2, row3, row4 = 135*scaling, 69*scaling, 5*scaling, 21*scaling,37*scaling,53*scaling
	hoverLeft = 49*scaling
	hoverRight = 135*scaling
	hoverBottom = 39*scaling
	hoverTop = 51*scaling
	barBottom = 44*scaling
	barTop = 46*scaling
	
	local cmds = widgetHandler.commands
	local n = #(widgetHandler.commands)
	
	for i=1,n do
		if (cmds[i].id == CMD_ENERGYCONVERT) then
			cmds[i].hidden = false
		end
    end
	spSendLuaRulesMsg(table.concat({operationPrefix,1}))
end

function widget:Shutdown()
		
	local cmds = widgetHandler.commands
	local n = #(widgetHandler.commands)

	for i=1,n do
		if (cmds[i].id == CMD_ENERGYCONVERT) then
			cmds[i].hidden = true
		end
	end
	spSendLuaRulesMsg(table.concat({operationPrefix,0}))
end

function widget:CommandsChanged()
    
	local cmds = widgetHandler.commands
	local n = #(widgetHandler.commands)
	
	for i=1,n do
		if (cmds[i].id == CMD_ENERGYCONVERT) then
			cmds[i].hidden = false
		end
	end
end

function widget:DrawScreen()
    if not displayWindow then return end
	
    -- Var
    local myTeamID = spGetMyTeamID()
    local curLevel = spGetTeamRulesParam(myTeamID, 'mmLevel') or 0
    local curUsage = spGetTeamRulesParam(myTeamID, 'mmUse') or 0
    local curCapacity = spGetTeamRulesParam(myTeamID, 'mmCapacity') or 0
	
	if curCapacity <= 0 then return end
	
	local Mprod = curUsage/60
	local display
	if Mprod >= 1 then 
		display = format('%i.', Mprod) .. floor((Mprod-floor(Mprod))*10)
    else
		display = format('0.%i', curUsage/6)
	end
    -- Positioning
    glPushMatrix()
        glTranslate(px, py, 0)
        
        -- Panel
        glColor(0, 0, 0, 0.4)
        RectRound(0, 0, sx, sy)
        
        -- Text
        glColor(1, 1, 1, 1)
        glBeginText()
            glText('Energy Conversion', col2, row4, fontSize, 'cd')
            glText('Hover:', row1, row3, fontSize, 'd')
            glText('E usage:', row1, row2, fontSize, 'd')
            glText('M production:', row1, row1, fontSize, 'd')
            glText(format('%i / %i', curUsage, curCapacity), col1, row2, fontSize, 'dr')
            glText(display, col1, row1, fontSize, 'dr')
        glEndText()
        
        -- Bar
        glRect(hoverLeft, barBottom, hoverRight, barTop)
        
        -- Slider
        local sliderX = hoverLeft + (hoverRight - hoverLeft) * curLevel
        glColor(1, 0, 0, 0.75)
        glRect(sliderX - 2, hoverBottom, sliderX + 2, hoverTop)
        
    glPopMatrix()
end

function widget:TeamDied(teamID)
	
	if teamID == spGetMyTeamID() then
		displayWindow = false	
		widgetHandler:RemoveWidget(self)
		return
	end
end

function widget:MousePress(mx, my, mButton)
	if displayWindow then
		if mButton == 2 or mButton == 3 then
			if mx >= px and my >= py and mx < px + sx and my < py + sy then
				return true
			end
		elseif mButton == 1 and not spGetSpectatingState() then
			local dx, dy = mx - px, my - py
			if dx >= hoverLeft and dy >= hoverBottom and dx < hoverRight and dy < hoverTop then
				local newShare = 100 * (dx - hoverLeft) / (hoverRight - hoverLeft) -- [0, 100)
				spSendLuaRulesMsg(format(alterLevelFormat, newShare))
				return true
			end
		end
	end
end

function widget:MouseMove(mx, my, dx, dy, mButton)
    -- Dragging
	if displayWindow then
		if mButton == 2 or mButton == 3 then
			if px+sx+onsidemargin+dx>=0 and px+onsidemargin+dx<=X then px = px + dx end
			if py+sy+onsidemargin+dy>=0 and py+onsidemargin+dy<=Y then py = py + dy end
		end
	end
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
