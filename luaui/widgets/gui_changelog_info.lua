
function widget:GetInfo()
return {
	name    = "Changelog Info",
	desc    = "Leftmouse: scroll down,  Rightmouse: scroll up,  ctrl/shift/alt combi: speedup)",
	author  = "Floris",
	date    = "August 2015",
	license = "Dental flush",
	layer   = -1,
	enabled = true,
}
end

--local show = true
include("keysym.h.lua")

local loadedFontSize = 16
local myFont = gl.LoadFont(LUAUI_DIRNAME .. "fonts/ebrima.ttf",loadedFontSize, 16,2)

local bgcorner = ":n:"..LUAUI_DIRNAME.."images/bgcorner.png"
local closeButtonTex = ":n:"..LUAUI_DIRNAME.."images/close.dds"
local Echo	= Spring.Echo
local changelogFile = VFS.LoadFile("changelog.nfo")

local bgMargin = 6

local closeButtonSize = 30
local screenHeight = 520-bgMargin-bgMargin
local screenWidth = 1050-bgMargin-bgMargin

local textareaMinLines = 10		-- wont scroll down more, will show at least this amount of lines 

local customScale = 1

local startLine = 1

local vsx,vsy = Spring.GetViewGeometry()
local screenX = (vsx*0.5) - (screenWidth/2)
local screenY = (vsy*0.5) + (screenHeight/2)
  
local spIsGUIHidden = Spring.IsGUIHidden
local showHelp = false

local glColor = gl.Color
local glLineWidth = gl.LineWidth
local glPolygonMode = gl.PolygonMode
local glRect = gl.Rect
local glText = gl.Text
local glShape = gl.Shape
local glGetTextWidth = gl.GetTextWidth
local glGetTextHeight = gl.GetTextHeight

local bgColorMultiplier = 0

local glCreateList = gl.CreateList
local glCallList = gl.CallList
local glDeleteList = gl.DeleteList

local glPopMatrix = gl.PopMatrix
local glPushMatrix = gl.PushMatrix
local glTranslate = gl.Translate
local glScale = gl.Scale

local GL_FILL = GL.FILL
local GL_FRONT_AND_BACK = GL.FRONT_AND_BACK
local GL_LINE_STRIP = GL.LINE_STRIP

local widgetScale = 1
local vsx, vsy = Spring.GetViewGeometry()

local versions = {}
local changelogLines = {}
local totalChangelogLines = 0

function widget:ViewResize()
  vsx,vsy = Spring.GetViewGeometry()
  screenX = (vsx*0.5) - (screenWidth/2)
  screenY = (vsy*0.5) + (screenHeight/2)
  widgetScale = (0.75 + (vsx*vsy / 7500000)) * customScale
  if changelogList then gl.DeleteList(changelogList) end
  changelogList = gl.CreateList(DrawWindow)
end

local myTeamID = Spring.GetMyTeamID()
local amNewbie = (Spring.GetTeamRulesParam(myTeamID, 'isNewbie') == 1)
local gameStarted = (Spring.GetGameFrame()>0)
function widget:GameStart()
    gameStarted = true
end

-- button
local textSize		= 0.75
local textMargin	= 0.25
local lineWidth		= 0.0625

local posX = 0.1
local posY = 0
local showOnceMore = false		-- used because of GUI shader delay
local buttonGL
local startPosX = posX

local function DrawRectRound(px,py,sx,sy,cs, tl,tr,br,bl)
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
	
	-- bottom left
	if ((py <= 0 or px <= 0)  or (bl ~= nil and bl == 0)) and bl ~= 2   then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(px, py, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(px+cs, py, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(px+cs, py+cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(px, py+cs, 0)
	-- bottom right
	if ((py <= 0 or sx >= vsx) or (br ~= nil and br == 0)) and br ~= 2   then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(sx, py, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(sx-cs, py, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(sx-cs, py+cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(sx, py+cs, 0)
	-- top left
	if ((sy >= vsy or px <= 0) or (tl ~= nil and tl == 0)) and tl ~= 2   then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(px, sy, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(px+cs, sy, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(px+cs, sy-cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(px, sy-cs, 0)
	-- top right
	if ((sy >= vsy or sx >= vsx)  or (tr ~= nil and tr == 0)) and tr ~= 2   then o = 0.5 else o = offset end
	gl.TexCoord(o,o)
	gl.Vertex(sx, sy, 0)
	gl.TexCoord(o,1-o)
	gl.Vertex(sx-cs, sy, 0)
	gl.TexCoord(1-o,1-o)
	gl.Vertex(sx-cs, sy-cs, 0)
	gl.TexCoord(1-o,o)
	gl.Vertex(sx, sy-cs, 0)
end
function RectRound(px,py,sx,sy,cs, tl,tr,br,bl)		-- (coordinates work differently than the RectRound func in other widgets)
	gl.Texture(bgcorner)
	gl.BeginEnd(GL.QUADS, DrawRectRound, px,py,sx,sy,cs, tl,tr,br,bl)
	gl.Texture(false)
end

function DrawButton()
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
	RectRound(0,0,4.5,1.05,0.25, 2,2,0,0)
	local vertices = {
		{v = {0, 1, 0}},
		{v = {0, 0, 0}},
		{v = {1, 0, 0}},
	}
	glShape(GL_LINE_STRIP, vertices)
    glText("Changelog", textMargin, textMargin, textSize, "no")
end


local versionOffsetX = 0
local versionOffsetY = 14
local versionFontSize = 16

local versionQuickLinks = {}
function DrawSidebar(x,y,width,height)
	local fontSize		= versionFontSize
	local fontOffsetY	= versionOffsetY
	local fontOffsetX	= versionOffsetX
	
	-- background
	gl.Color(0.72,0.5,0.12,0.3)
	RectRound(x,y-height,x+width,y,6)
	
	-- version links
	versionQuickLinks = {}
	if changelogFile then
		myFont:Begin()
		myFont:SetOutlineColor(0.25,0.2,0,0.3)
		myFont:SetTextColor(1,0.8,0.1,1)
		local lineKey = 1
		local yOffset = 24
		local j = 0
		while j < 22 do	
			if ((fontSize+fontOffsetY)*j)+4 > height-yOffset then
				break;
			end
			if versions[lineKey] == nil then
				break;
			end
			local line = changelogLines[versions[lineKey]] or "N/A"
			
			-- version button title
			line = " " .. (string.match(line, '( %d*%d.?%d+)') or " ")
			local textY = y-((fontSize+fontOffsetY)*j)-20
			myFont:Print(line, x+9+fontOffsetX, textY, fontSize, "on")
			
			versionQuickLinks[j] = {
				x,
				textY-(versionFontSize*0.66),
				x+70,
				textY+(versionFontSize*1.21)
			}
			
			j = j + 1
			lineKey = lineKey + 1
		end
		myFont:End()
	end
end


function DrawTextarea(x,y,width,height,scrollbar)
	local scrollbarOffsetTop 		= 18	-- note: wont add the offset to the bottom, only to top
	local scrollbarOffsetBottom 	= 12	-- note: wont add the offset to the top, only to bottom
	local scrollbarMargin    		= 10
	local scrollbarWidth     		= 8
	local scrollbarPosWidth  		= 6
	local scrollbarPosMinHeight 	= 8
	local scrollbarBackgroundColor	= {0,0,0,0.24	}
	local scrollbarBarColor			= {1,1,1,0.08}
	
	local fontSizeTitle				= 20		-- is version number
	local fontSizeHeading			= 16		
	local fontSizeAuthors			= 14	
	local fontSizeDate				= 14
	local fontSizeLine				= 14
	local ls						= 5
	
	local fontColorTitle			= {1,1,1,1}
	local fontColorHeading			= {0.8,0.8,0.4,1}
	local fontColorAuthors			= {0.8,0.4,0.4,1}
	local fontColorDate				= {0.66,0.88,0.66,1}
	local fontColorLine				= {0.8,0.77,0.74,1}
	local fontColorLineBullet		= {0.9,0.6,0.2,1}
	
	local textRightOffset = scrollbar and scrollbarMargin+scrollbarWidth+scrollbarWidth or 0
	local maxLines = math.floor((height-5)/fontSizeLine)
	
	-- textarea scrollbar
	if scrollbar then
		if (totalChangelogLines > maxLines or startLine > 1) then	-- only show scroll above X lines
			local scrollbarTop       = y-scrollbarOffsetTop-scrollbarMargin-(scrollbarWidth-scrollbarPosWidth)
			local scrollbarBottom    = y-scrollbarOffsetBottom-height+scrollbarMargin+(scrollbarWidth-scrollbarPosWidth)
			local scrollbarPosHeight = math.max(((height-scrollbarMargin-scrollbarMargin) / totalChangelogLines) * ((height-scrollbarMargin-scrollbarMargin) / 25), scrollbarPosMinHeight)
			local scrollbarPos       = scrollbarTop + (scrollbarBottom - scrollbarTop) * ((startLine-1) / totalChangelogLines)
			scrollbarPos             = scrollbarPos + ((startLine-1) / totalChangelogLines) * scrollbarPosHeight	-- correct position taking position bar height into account

			-- background
			gl.Color(scrollbarBackgroundColor)
			RectRound(
				x+width-scrollbarMargin-scrollbarWidth,
				scrollbarBottom-(scrollbarWidth-scrollbarPosWidth),
				x+width-scrollbarMargin,
				scrollbarTop+(scrollbarWidth-scrollbarPosWidth),
				scrollbarWidth/2
			)
			-- bar
			gl.Color(scrollbarBarColor)
			RectRound(
				x+width-scrollbarMargin-scrollbarWidth + (scrollbarWidth - scrollbarPosWidth),
				scrollbarPos,
				x+width-scrollbarMargin-(scrollbarWidth - scrollbarPosWidth),
				scrollbarPos - (scrollbarPosHeight),
				scrollbarPosWidth/2
			)
		end
	end
	
	-- draw textarea
	if changelogFile then
		myFont:Begin()
		local lineKey = startLine
		local j = 1
		while j < maxLines do	-- maxlines is not exact, just a failsafe
			if (fontSizeTitle)*j > height then
				break;
			end
			if changelogLines[lineKey] == nil then
				break;
			end
			
			local line = changelogLines[lineKey]
			
			if string.find(line, '^([0-3][0-9][/%.][0-1][0-9][/%.][0-9][0-9])') or string.find(line, '^([1-9][/%.][0-1][0-9][/%.][0-9][0-9])') or string.find(line, '^([0-3][0-9][/%.][0-1][0-9][/%.][0-9][0-9][0-9][0-9])') or string.find(line, '^([1-9][/%.][0-1][0-9][/%.][0-9][0-9][0-9][0-9])') then
				-- date line
				line = "  " .. line
				myFont:SetTextColor(fontColorDate)
				myFont:Print(line, x, y-fontSizeTitle*j, fontSizeDate, "n")
			elseif string.find(line, '^(XTA[^(]+)') then
				-- version line
				local versionStrip = string.match(line, '^(XTA[^(]+)')
				if versionStrip ~= nil then
					line = " " .. versionStrip
 				else
					line = " " .. line
				end
				myFont:SetTextColor(fontColorTitle)
				myFont:Print(line, x-9, y-fontSizeTitle*j, fontSizeTitle, "n")
			elseif (string.find(line, ':%s$') or string.find(line, ':$')) and #line <36 then
				-- heading line
				myFont:SetTextColor(fontColorHeading)
				y = y-9
				myFont:Print(line, x, y-fontSizeTitle*j, fontSizeHeading, "n")
			elseif string.find(line, '^|') then
				-- authors line
				
				myFont:SetTextColor(fontColorAuthors)
				line = "  " .. string.gsub(line,"|","by ")
				line = string.gsub(line,'jls','Jools')
				line = string.gsub(line,'klt','Kloot')
				line = string.gsub(line,'dnw','DeadNightWarrior')
				line = string.gsub(line,'rar','Raaar')
				line = string.gsub(line,'nor','Noruas')
				line = string.gsub(line,'kno','Knorke')
				
				
				myFont:Print(line, x+screenWidth-150, y+fontSizeTitle-fontSizeTitle*j, fontSizeAuthors, "rn")
			else
				myFont:SetTextColor(fontColorLine)
				
				if string.find(line, '^(%s+[%*%-%+%d]%)?%s+%w)') and #line > 5 then
					-- bullet
					--Echo("Bullet:",line)
					if string.find(line, '^%s%*') then
						-- bulletpointed line
						local firstLetterPos = 3
						y = y-6
						
						if string.find(line, '^( - )') or string.find(line, '^( + )') or string.find(line, '^( * )')then
							firstLetterPos = 4
						end
						line = string.upper(string.sub(line, firstLetterPos, firstLetterPos))..string.sub(line, firstLetterPos+1)
						
						line, numLines = myFont:WrapText(line, (width - 40 - textRightOffset)*(loadedFontSize/fontSizeLine))
						if (fontSizeTitle)*(j+numLines-1) > height then 
							break;
						end
						myFont:Print("·", x+8, y-fontSizeTitle*j, fontSizeLine, "n")
						myFont:Print(line, x+22, y-fontSizeTitle*j, fontSizeLine, "n")
						
					else
						-- bullet level 2
						
						local firstLetterPos = 3
						y = y-6
						
						if string.find(line, '^( - )') or string.find(line, '^( + )') or string.find(line, '^( * )')then
							firstLetterPos = 4
						elseif string.find(line, '^(%s%d[%)%.])') then
							firstLetterPos = 5
						end
						--Echo("Bullet2:",line,firstLetterPos)
						line = string.upper(string.sub(line, firstLetterPos, firstLetterPos))..string.sub(line, firstLetterPos+1)
						line, numLines = myFont:WrapText(line, (width - 40 - textRightOffset)*(loadedFontSize/fontSizeLine))
						if (fontSizeTitle)*(j+numLines-1) > height then 
							break;
						end
						myFont:Print("-", x+22, y-fontSizeTitle*j, fontSizeLine, "n")
						myFont:Print(line, x+32, y-fontSizeTitle*j, fontSizeLine, "n")
										
					end
				else
					-- line
					y = y - 4
					line = "  " .. line
					line, numLines = myFont:WrapText(line, (width-200)*(loadedFontSize/fontSizeLine))
					if (fontSizeTitle)*(j+numLines-1) > height then 
						break;
					end
					myFont:Print(line, x, y-(fontSizeTitle)*j, fontSizeLine, "n")
				end
				j = j + (numLines - 1)
			end

			j = j + 1
			lineKey = lineKey + 1
		end
		myFont:End()
	end
end


function DrawWindow()
    local vsx,vsy = Spring.GetViewGeometry()
    local x = screenX --rightwards
    local y = screenY --upwards
	
	-- background
    gl.Color(0,0,0,0.8)
	RectRound(x-bgMargin,y-screenHeight-bgMargin,x+screenWidth+bgMargin,y+bgMargin,8, 0,1,1,1)
	-- content area
	gl.Color(0.33,0.33,0.33,0.15)
	RectRound(x,y-screenHeight,x+screenWidth,y,6)
	
	-- close button
    gl.Color(1,1,1,1)
	gl.Texture(closeButtonTex)
	gl.TexRect(screenX+screenWidth-closeButtonSize,screenY,screenX+screenWidth,screenY-closeButtonSize)
	gl.Texture(false)
	
	-- title
    local title = "Changelog"
	local titleFontSize = 18
    gl.Color(0,0,0,0.8)
    titleRect = {x-bgMargin, y+bgMargin, x+(glGetTextWidth(title)*titleFontSize)+27-bgMargin, y+37}
	RectRound(titleRect[1], titleRect[2], titleRect[3], titleRect[4], 8, 1,1,0,0)
	myFont:Begin()
	myFont:SetTextColor(1,1,1,1)
	myFont:SetOutlineColor(0,0,0,0.4)
	myFont:Print(title, x-bgMargin+(titleFontSize*0.75), y+bgMargin+8, titleFontSize, "on")
	myFont:End()
	
	-- version links
	DrawSidebar(x, y, 70, screenHeight)
	
	-- textarea
	DrawTextarea(x+90, y-10, screenWidth-90, screenHeight-24, 1)
end


function widget:DrawScreen()
    if spIsGUIHidden() then return end
    if amNewbie and not gameStarted then return end
    
    -- draw the button
    if not buttonGL then
        buttonGL = gl.CreateList(DrawButton)
    end
    
    glLineWidth(lineWidth)

    glPushMatrix()
        glTranslate(posX*vsx, posY*vsy, 0)
        glScale(17*widgetScale, 17*widgetScale, 1)
		glColor(0, 0, 0, (0.3*bgColorMultiplier))
        glCallList(buttonGL)
    glPopMatrix()

    glColor(1, 1, 1, 1)
    glLineWidth(1)
    
    -- draw the help
    if not changelogList then
        changelogList = gl.CreateList(DrawWindow)
    end
    
    if show or showOnceMore then
    
		-- draw the changelog panel
		glPushMatrix()
			glTranslate(-(vsx * (widgetScale-1))/2, -(vsy * (widgetScale-1))/2, 0)
			glScale(widgetScale, widgetScale, 1)
			glCallList(changelogList)
		glPopMatrix()
		if (WG['guishader_api'] ~= nil) then
			local rectX1 = ((screenX-bgMargin) * widgetScale) - ((vsx * (widgetScale-1))/2)
			local rectY1 = ((screenY+bgMargin) * widgetScale) - ((vsy * (widgetScale-1))/2)
			local rectX2 = ((screenX+screenWidth+bgMargin) * widgetScale) - ((vsx * (widgetScale-1))/2)
			local rectY2 = ((screenY-screenHeight-bgMargin) * widgetScale) - ((vsy * (widgetScale-1))/2)
			WG['guishader_api'].InsertRect(rectX1, rectY2, rectX2, rectY1, 'changelog')
		end
		showOnceMore = false
		
		-- draw button hover
		local usedScreenX = (vsx*0.5) - ((screenWidth/2)*widgetScale)
		local usedScreenY = (vsy*0.5) + ((screenHeight/2)*widgetScale)

		local x,y = Spring.GetMouseState()
		if changelogFile then
			local lineKey = 1
			local j = 0
			local yOffset = 24
			local yOffsetUp = (((versionFontSize*0.66)+yOffset)*widgetScale)
			local yOffsetDown = (((versionFontSize*1.21)-yOffset)*widgetScale)
			while j < 22 do	
				if ((versionFontSize+versionOffsetY)*j)+4 > (screenHeight-yOffset) then
					break;
				end
				if versions[lineKey] == nil then
					break;
				end
				if versionQuickLinks[j] == nil then
					break;
				end
				
				--local cc = (versionQuickLinks[j][1]/vsx) * vsx/widgetScale
				--Spring.Echo(usedScreenX..'  '..versionQuickLinks[j][1]..'  '..cc)
				
				-- version title
				local textX = usedScreenX-((10+versionOffsetX)*widgetScale)
				local textY = usedScreenY-((((versionFontSize+versionOffsetY)*j)-5)*widgetScale)
				local x1 = usedScreenX
				local y1 = textY-yOffsetUp
				local x2 = usedScreenX+(70*widgetScale)
				local y2 = textY+yOffsetDown
				if IsOnRect(x, y, x1, y1, x2, y2) then
					gl.Color(1,0.93,0.75,0.22)
					RectRound(x1, y1, x2, y2, 5*widgetScale)
					break;
				end
				j = j + 1
				lineKey = lineKey + 1
			end
		end
    else
		if (WG['guishader_api'] ~= nil) then
			WG['guishader_api'].RemoveRect('changelog')
		end
	end
end

function IsOnRect(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	
	-- check if the mouse is in a rectangle
	return x >= BLcornerX and x <= TRcornerX
	                      and y >= BLcornerY
	                      and y <= TRcornerY
end

function widget:IsAbove(x, y)
	-- on window
	if show then
		local rectX1 = ((screenX-bgMargin) * widgetScale) - ((vsx * (widgetScale-1))/2)
		local rectY1 = ((screenY+bgMargin) * widgetScale) - ((vsy * (widgetScale-1))/2)
		local rectX2 = ((screenX+screenWidth+bgMargin) * widgetScale) - ((vsx * (widgetScale-1))/2)
		local rectY2 = ((screenY-screenHeight-bgMargin) * widgetScale) - ((vsy * (widgetScale-1))/2)
		return IsOnRect(x, y, rectX1, rectY2, rectX2, rectY1)
	else
		return false
	end
end

function widget:GetTooltip(mx, my)
	if show and widget:IsAbove(mx,my) then
		return string.format(
			"\255\255\255\1Left mouse\255\255\255\255 on textarea to scroll down.\n"..
			"\255\255\255\1Right mouse\255\255\255\255 on textarea  to scroll up.\n\n"..
			"Add CTRL or SHIFT to scroll faster, or combine CTRL+SHIFT (+ALT).")
	end
end

function widget:MouseWheel(up, value)
	
	if show then	
		local addLines = value*-6 -- direction is retarded
		
		startLine = startLine + addLines
		if startLine < 1 then startLine = 1 end
		if startLine > totalChangelogLines - textareaMinLines then startLine = totalChangelogLines - textareaMinLines end
		
		if changelogList then
			glDeleteList(changelogList)
		end
		
		changelogList = gl.CreateList(DrawWindow)
		return true
	else
		return false
	end
end

function widget:MousePress(x, y, button)
	if spIsGUIHidden() then return false end
    if amNewbie and not gameStarted then return end
    
    if show then 
		-- on window
		local rectX1 = ((screenX-bgMargin) * widgetScale) - ((vsx * (widgetScale-1))/2)
		local rectY1 = ((screenY+bgMargin) * widgetScale) - ((vsy * (widgetScale-1))/2)
		local rectX2 = ((screenX+screenWidth+bgMargin) * widgetScale) - ((vsx * (widgetScale-1))/2)
		local rectY2 = ((screenY-screenHeight-bgMargin) * widgetScale) - ((vsy * (widgetScale-1))/2)
		if IsOnRect(x, y, rectX1, rectY2, rectX2, rectY1) then
		
			-- on close button
			local brectX1 = rectX2 - (closeButtonSize+bgMargin+bgMargin * widgetScale)
			local brectY2 = rectY1 - (closeButtonSize+bgMargin+bgMargin * widgetScale)
			if IsOnRect(x, y, brectX1, brectY2, rectX2, rectY1) then
				showOnceMore = true		-- show once more because the guishader lags behind, though this will not fully fix it
				show = not show
				return true
			end
			
			-- version buttons
			if button == 1 then
			local yOffset = 24
				local usedScreenX = (vsx*0.5) - ((screenWidth/2)*widgetScale)
				local usedScreenY = (vsy*0.5) + ((screenHeight/2)*widgetScale)
				
				local x,y = Spring.GetMouseState()
				if changelogFile then
					local lineKey = 1
					local j = 0
					while j < 25 do	
						if (versionFontSize+versionOffsetY)*j > (screenHeight-yOffset) then
							break;
						end
						if versions[lineKey] == nil then
							break;
						end
						
						-- version title
						local textX = usedScreenX-((10+versionOffsetX)*widgetScale)
						local textY = usedScreenY-((((versionFontSize+versionOffsetY)*j)-5)*widgetScale)
						
						local x1 = usedScreenX
						local y1 = textY-(((versionFontSize*0.66)+yOffset)*widgetScale)
						local x2 = usedScreenX+((70*widgetScale))
						local y2 = textY+(((versionFontSize*1.21)-yOffset)*widgetScale)
						if IsOnRect(x, y, x1, y1, x2, y2) then
							startLine = versions[lineKey]
							if changelogList then
								glDeleteList(changelogList)
							end
							changelogList = gl.CreateList(DrawWindow)
							break;
						end
						
						j = j + 1
						lineKey = lineKey + 1
					end
				end
			end
			
			-- close on RMB
			if button == 1 or button == 3 then
				if button == 3 then
					show = not show
				end
				return true
			end
			
		elseif titleRect == nil or not IsOnRect(x, y, (titleRect[1] * widgetScale) - ((vsx * (widgetScale-1))/2), (titleRect[2] * widgetScale) - ((vsy * (widgetScale-1))/2), (titleRect[3] * widgetScale) - ((vsx * (widgetScale-1))/2), (titleRect[4] * widgetScale) - ((vsy * (widgetScale-1))/2)) then
			showOnceMore = true		-- show once more because the guishader lags behind, though this will not fully fix it
			show = not show
		end
		return true
    else
		tx = (x - posX*vsx)/(17*widgetScale)
		ty = (y - posY*vsy)/(17*widgetScale)
		if tx < 0 or tx > 4.5 or ty < 0 or ty > 1.05 then return false end
		
		showOnceMore = show		-- show once more because the guishader lags behind, though this will not fully fix it
		show = not show
    end
	return false
end

function widget:KeyPress(key, mods, isRepeat)
  if show and key == KEYSYMS.ESCAPE then
	show = not show
    return true
  end
end

function lines(str)
  local t = {}
  local function helper(line) table.insert(t, line) return "" end
  helper((str:gsub("(.-)\r?\n", helper)))
  return t
end

function widget:Initialize()
	if changelogFile then
		-- somehow there are a few characters added at the start that we need to remove
		-- for xta we need to remove the ascii art in the beginning
		
		changelogFile = string.sub(changelogFile, 1+select(2,string.find(changelogFile,"here")))
		
		-- store changelog into array
		changelogLines = lines(changelogFile)
		--Echo("CLI lines:",#changelogLines,changelogFile)
		local versionKey = 0
		for i, line in ipairs(changelogLines) do
			--Echo("Line:",i,line,string.find(line, '^(XTA[^(]+)'))
			--%d*%d.?%d+ /-)'
			if string.find(line, '^(XTA[^(]+)') then
				versionKey = versionKey + 1
				versions[versionKey] = i
			end
			totalChangelogLines = i
		end
		
	else
		Spring.Echo("Changelog: couldn't load the changelog file")
		widgetHandler:RemoveWidget()
	end
end

function widget:Shutdown()
    if buttonGL then
        glDeleteList(buttonGL)
        buttonGL = nil
    end
    if changelogList then
        glDeleteList(changelogList)
        changelogList = nil
    end
end
