
function widget:GetInfo()
	return {
		name      = 'Commander Change',
		desc      = 'Adds buttons to choose commander',
		author    = 'Niobium, Jools',
		date      = 'March 2012',
		license   = 'GNU GPL v2',
		layer     = -100,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Var
--------------------------------------------------------------------------------
local px, py = 300, 300
local sizex, sizey, t, sidep, infop, labelp = 440, 260, 18, 60, 60, 100
local middle = labelp+(sizex-labelp)/2
local scale = 1

local imgComAA = "LuaUI/Images/commchange/ComAA.png"
local imgComAM = "LuaUI/Images/commchange/ComAM.png"
local imgComAAD = "LuaUI/Images/commchange/ComAAD.png"
local imgComAMD = "LuaUI/Images/commchange/ComAMD.png"
local imgComCA = "LuaUI/Images/commchange/ComCA.png"
local imgComCM = "LuaUI/Images/commchange/ComCM.png"
local imgComCAD = "LuaUI/Images/commchange/ComCAD.png"
local imgComCMD = "LuaUI/Images/commchange/ComCMD.png"


--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local teamList = Spring.GetTeamList()
local myTeamID = Spring.GetMyTeamID()

local glTexCoord = gl.TexCoord
local glVertex = gl.Vertex
local glColor = gl.Color
local glRect = gl.Rect
local glTexture = gl.Texture
local glTexRect = gl.TexRect
local glDepthTest = gl.DepthTest
local glBeginEnd = gl.BeginEnd
local GL_QUADS = GL.QUADS
local glPushMatrix = gl.PushMatrix
local glPopMatrix = gl.PopMatrix
local glTranslate = gl.Translate
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text

local spGetTeamStartPosition = Spring.GetTeamStartPosition
local spGetTeamRulesParam = Spring.GetTeamRulesParam
local spGetGroundHeight = Spring.GetGroundHeight
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg
local spGetSpectatingState = Spring.GetSpectatingState
local spGetTeamInfo = Spring.GetTeamInfo
--------------------------------------------------------------------------------
-- Funcs
--------------------------------------------------------------------------------
local function QuadVerts(x, y, z, r)
	glTexCoord(0, 0); glVertex(x - r, y, z - r)
	glTexCoord(1, 0); glVertex(x + r, y, z - r)
	glTexCoord(1, 1); glVertex(x + r, y, z + r)
	glTexCoord(0, 1); glVertex(x - r, y, z + r)
end

--------------------------------------------------------------------------------
-- Callins
--------------------------------------------------------------------------------
function widget:Initialize()
    if spGetSpectatingState() or Spring.GetGameFrame() > 0 or (Spring.GetModOptions() or {}).comm ~= "choose" then
        widgetHandler:RemoveWidget(self)
    end
	local X, Y = Spring.GetViewGeometry()
	scale = Y/1200
	px, py = 300*scale, 300*scale
	sizex, sizey, t, sidep, infop, labelp = 440*scale, 260*scale, 18*scale, 60*scale, 60*scale, 100*scale
	middle = labelp+(sizex-labelp)/2

end

function widget:DrawWorld()
    glColor(1, 1, 1, 0.5)
    glDepthTest(false)
    for i = 1, #teamList do
        local teamID = teamList[i]
        local tsx, tsy, tsz = spGetTeamStartPosition(teamID)
        if tsx and tsx > 0 then
            local teamStartUnit = spGetTeamRulesParam(teamID, 'startUnit')
            if (teamStartUnit == 30) or (teamStartUnit == 166) then
                glTexture('LuaUI/Images/commchange/arm.png')
                glBeginEnd(GL_QUADS, QuadVerts, tsx, spGetGroundHeight(tsx, tsz), tsz, 80)
            elseif (teamStartUnit == 236) or (teamStartUnit == 375) then
                glTexture('LuaUI/Images/commchange/core.png')
                glBeginEnd(GL_QUADS, QuadVerts, tsx, spGetGroundHeight(tsx, tsz), tsz, 64)
            end
        end
    end
    glTexture(false)
end

function widget:DrawScreen()
    
    -- Spectator check
    if spGetSpectatingState() then
        widgetHandler:RemoveWidget(self)
        return
    end
    
	local suid = spGetTeamRulesParam(myTeamID, 'startUnit')
	
    -- Positioning
    glPushMatrix()
        glTranslate(px, py, 0)
        
        -- Panel
        glColor(0, 0, 0, 0.5)
        glRect(0, 0, sizex, sizey)
        
        -- Highlight
        glColor(0.4, 0.4, 0.8, 0.5)
        if suid == 30 or suid == 236 then
            glRect(labelp+1, sidep+infop+1, middle-1, sizey-1)
        else
            glTexRect(middle+1, sidep+infop+1, sizex-1, sizey-1)
        end
        glColor(1, 1, 0, 0.5)
		if suid == 30 or suid == 166 then
			glRect(labelp+1, infop+1, middle-1, sidep+infop-1)
		else
			glTexRect(middle+1, infop+1, sizex-1, sidep+infop-1)
		end
		
        -- Commander Icons
		if suid == 30 or suid == 236 then -- Automatic commanders selected
			glColor(1, 1, 1, 1)
			if suid == 30 then 			-- ARM
				glTexture(imgComAA)
			else  						-- CORE
				glTexture(imgComCA)
			end
		else -- Manual commanders selected
			glColor(1, 1, 1, 0.3)
			if suid == 166 then  		-- ARM
				glTexture(imgComAAD) 
			else						--CORE
				glTexture(imgComCAD) 
			end
		end
		glColor(1, 1, 1, 1)
        glTexRect(labelp+t, t+sidep+infop, middle-t, sizey-t) -- draw left box
        if suid == 166 or suid == 375 then  -- Manual commanders selected
			if suid == 166 then
				glTexture(imgComAM) --ARM
			else
				glTexture(imgComCM) --CORE
			end
		else								-- Automatic commanders selected
			glColor(1, 1, 1, 0.3)
			if suid == 30 then
				glTexture(imgComAMD) --ARM
			else
				glTexture(imgComCMD) --CORE
			end
		end
		glColor(1, 1, 1, 1)
        glTexRect(middle+t, t+sidep+infop, sizex-t, sizey-t) -- draw right box
        glTexture(false)
		
		-- Faction Icons
		glColor(1, 1, 1, 1)
        glTexture('LuaUI/Images/commchange/ARM.png')
        glTexRect(labelp+2*t, infop + t, middle-2*t, sidep+infop-t)
        glTexture('LuaUI/Images/commchange/CORE.png')
        glTexRect(middle+2*t, infop + t, sizex-2*t, sidep+infop-t)
        glTexture(false)
		
		-- Text
		glBeginText()
		-- Labelpanel
		local indent, font1, font2, font3 = 40*scale, 14*scale, 12*scale, 10*scale
        glText('Type', indent, sidep+infop + 70*scale, font1, 'd')
        glText('Faction', indent, infop + 30*scale, font1, 'd')
        glText('Info', indent, 30*scale, font1, 'd')
		-- Labels
        glText('Choose Your Commander:', sizex/2, sizey, 16*scale, 'cd')
        glText('Automatic', labelp + (sizex-labelp)/4, sidep+infop, font2, 'cd')
        glText('Manual', middle + (sizex-labelp)/4, sidep+infop, font2, 'cd')
        --Info
		local txt1, txt2, txt3
		if suid == 30 then
			txt1 = "*Type-A, Arm Commander is faster than Core."
			txt2 = "*Will get longer radar, speed and laser range with more XP"
			txt3 = "*Paralyser beam at 0.3, Sniper Laser at 0.6 and Sat. Strike at 1.2 XP"
		elseif suid == 166 then
			txt1 = "*Type-M, Arm Commander is faster than Core."
			txt2 = "*Paralyser laser and longer D-Gun at level 2"
			txt3 = "*Self-repair at level 3, Raven-rockets and at Level 4."
		elseif suid == 236 then
			txt1 = "*Type-A, Core is slow in the beginning."
			txt2 = "*Will get longer radar, speed and laser range with more XP"
			txt3 = "*Ion Beam at 0.3, Sumo Laser at 0.6, and Sat. Strike at 1.2 XP."
		elseif suid == 375 then
			txt1 = "*Type-M, Core Commander is slower, but has longer D-Gun."
			txt2 = "*Gets a longer D-Gun when upgraded, and laser beam at level 2."
			txt3 = "*A level 4 Commander will have a Mobile Artillery shot."
		end
		glText(txt1, labelp, 45*scale, font3, 'd')
		glText(txt2, labelp, 25*scale, font3, 'd')
		glText(txt3, labelp, 5*scale, font3, 'd')
		glEndText()
		glPopMatrix()
end

-- function widget:MapDrawCmd(playerID, cmdType, px, py, pz, labeltext)
	-- if playerID == myTeamID then
		-- local tsx, tsy, tsz = spGetTeamStartPosition(teamID)
		-- if tsx and tsx > 0 then widgetHandler:RemoveWidget(self) end
	-- end
-- end

function widget:MousePress(mx, my, mButton)
    
    -- Check buttons
    if mButton == 1 then
	
		-- Check 3 of the 4 sides
		if mx >= px + labelp and my >= py and my < py + sizey then
        
            -- Spectator check before any action
            if spGetSpectatingState() then
                widgetHandler:RemoveWidget(self)
                return false
            end
            
			local suid = spGetTeamRulesParam(myTeamID, 'startUnit')
			-- Which button?
			if my >= py+sidep+infop then -- commander type
				if mx < px + middle then  -- M TO A
					if suid ~= 30 and suid ~= 236 then	-- is 166 or 375
						if suid == 166 then
							spSendLuaRulesMsg('\17730')
						else
							spSendLuaRulesMsg('\177236')
						end
					end
					return true
				elseif mx < px + sizex then
					-- A TO M
					if suid ~= 166 and suid ~= 375 then -- is 30 or 236
						if suid == 30 then
							spSendLuaRulesMsg('\177166')
						else
							spSendLuaRulesMsg('\177375')
						end
					end
					return true
				end
			elseif my >= py+infop then -- faction
				if mx < px + middle then --CORE TO ARM
					if suid ~= 30 and suid ~= 166 then -- = 236 or 375
						if suid == 236 then
							spSendLuaRulesMsg('\17730')
						else
							spSendLuaRulesMsg('\177166')
						end
					end
					return true
				elseif mx < px + sizex then -- ARM TO CORE
					if suid ~= 236 and suid ~= 375 then	 -- = 30 or 166
						if suid == 30 then
							spSendLuaRulesMsg('\177236')
						else
							spSendLuaRulesMsg('\177375')
						end
					end
					return true
				end	
			end
		end
		
	elseif (mButton == 2 or mButton == 3) and mx < px + sizex then
		if mx >= px and my >= py and my < py + sizey then
			-- Dragging
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

function widget:GameStart()
    widgetHandler:RemoveWidget(self)
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
