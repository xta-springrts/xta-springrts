
function widget:GetInfo()
	return {
		name      = 'Energy Conversion Info',
		desc      = 'Displays energy conversion info',
		author    = 'Niobium(modified for XTA by Deadnight Warrior)',
		date      = 'May 2011',
		license   = 'GNU GPL v2',
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Var
--------------------------------------------------------------------------------
local alterLevelFormat = string.char(137) .. '%i'

local px, py = 500, 100
local sx, sy = 140, 72

local hoverLeft = 49
local hoverRight = 135
local hoverBottom = 39
local hoverTop = 51
local barBottom = 44
local barTop = 46

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local format = string.format
local floor = math.floor

local glColor = gl.Color
local glRect = gl.Rect
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text

local spGetMyTeamID = Spring.GetMyTeamID
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spGetSpectatingState = Spring.GetSpectatingState

--------------------------------------------------------------------------------
-- Funcs
--------------------------------------------------------------------------------
function widget:Initialize()
	local playerID = Spring.GetMyPlayerID()
	local _, _, spec, _, _, _, _, _ = Spring.GetPlayerInfo(playerID)
		
	if ( spec == true ) then
		Spring.Echo("<Energy Conversion Info> Spectator mode. Widget removed.")
		widgetHandler:RemoveWidget()
	end
end

function widget:DrawScreen()
    
    -- Var
    local myTeamID = spGetMyTeamID()
    local curLevel = spGetTeamRulesParam(myTeamID, 'mmLevel')
    local curUsage = spGetTeamRulesParam(myTeamID, 'mmUse')
    local curCapacity = spGetTeamRulesParam(myTeamID, 'mmCapacity')
	local Eprod = curUsage/60
	local display
	if Eprod >= 1 then 
		display = format('%i.', Eprod) .. floor((Eprod-floor(Eprod))*10)
    else
		display = format('0.%i', curUsage/6)
	end
    -- Positioning
    glPushMatrix()
        glTranslate(px, py, 0)
        
        -- Panel
        glColor(0, 0, 0, 0.4)
        glRect(0, 0, sx, sy)
        
        -- Text
        glColor(1, 1, 1, 1)
        glBeginText()
            glText('Energy Conversion', 69, 53, 12, 'cd')
            glText('Hover:', 5, 37, 12, 'd')
            glText('E usage:', 5, 21, 12, 'd')
            glText('M production:', 5, 5, 12, 'd')
            glText(format('%i / %i', curUsage, curCapacity*32), 135, 21, 12, 'dr')
            glText(display, 135, 5, 12, 'dr')
        glEndText()
        
        -- Bar
        glRect(hoverLeft, barBottom, hoverRight, barTop)
        
        -- Slider
        local sliderX = hoverLeft + (hoverRight - hoverLeft) * curLevel
        glColor(1, 0, 0, 0.75)
        glRect(sliderX - 2, hoverBottom, sliderX + 2, hoverTop)
        
    glPopMatrix()
end

function widget:MousePress(mx, my, mButton)
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

function widget:MouseMove(mx, my, dx, dy, mButton)
    -- Dragging
    if mButton == 2 or mButton == 3 then
        px = px + dx
        py = py + dy
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
