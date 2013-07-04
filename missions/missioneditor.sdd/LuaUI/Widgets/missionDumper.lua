
function widget:GetInfo()
	return {
		name      = 'Mission Dumper',
		desc      = 'Stores units/buildings/locations position into a mission template file',
		author    = 'Deadnight Warrior',
		date      = '20 Jul 2012',
		license   = 'GNU GPL v2',
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------
local noFile = true
local file
local fileName = "LuaUI/" .. Game.modShortName .. "_mission_editor_dump.lua"

local spGetViewGeometry = Spring.GetViewGeometry
local spSendLuaRulesMsg = Spring.SendLuaRulesMsg

local glColor = gl.Color
local glLineWidth = gl.LineWidth
local glDrawGroundCircle = gl.DrawGroundCircle
local glDrawGroundQuad = gl.DrawGroundQuad
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text
local glPushMatrix = gl.PushMatrix
local glTranslate = gl.Translate
local glPopMatrix = gl.PopMatrix
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local glDepthMask = gl.DepthMask
local glDepthTest = gl.DepthTest
local glCallList = gl.CallList
local glBlending = gl.Blending
local glRect = gl.Rect
local glTexRect = gl.TexRect

local X, Y = spGetViewGeometry()
local scale = Y/1200
local x1, y1 = X*.26, Y*.87
local x2, y2 = x1+60*scale, y1+120*scale		
local R,G,B = 1,1,1
local length, margin = 114*scale, 3*scale

local function DumpMission(textLine)
	if textLine == "BeginDump" and noFile==true then
		file = io.open(fileName, 'w')
		file:write('gameData = {\n\tmap = "' .. Game.mapName .. '",\n\tgame = "' .. Game.modShortName .. '",\n')
		noFile = false
	elseif textLine == "EndDump" and noFile==false then
		file:write("}\n\nreturn gameData, spawnData, missionTriggers, locations, briefing")
		file:flush()
		file:close()
		noFile = true
		Spring.Echo("SpawnData dumped into Spring/" .. fileName)
	elseif noFile==false then
		file:write(textLine)
	end
end

function widget:Initialize()
	widgetHandler:RegisterGlobal("DumpMission", DumpMission)
end

function widget:ViewResize(viewSizeX, viewSizeY)
	X, Y = spGetViewGeometry()
	scale = Y/1200
	x1, y1 = X*.26, Y*.87
	x2, y2 = x1+60*scale, y1+120*scale		
	length, margin = 114*scale, 3*scale
end

function widget:MousePress(mx, my, mButton)
	if mButton == 1 then
		local val
		local dx, dy = mx - x1-2*scale, my - y1-margin
		if dy>=0 and dy<=length then
			val = dy/length
			if dx >= 0 and dx<=10*scale then
				R = val
				spSendLuaRulesMsg("locColR" .. R)
				return true
			elseif dx >= 11*scale and dx<=19*scale then
				G = val
				spSendLuaRulesMsg("locColG" .. G)
				return true
			elseif dx >= 24*scale and dx<=30*scale then
				B = val
				spSendLuaRulesMsg("locColB" .. B)
				return true
			end
		end
	end
end

function widget:MouseMove(mx, my, dx, dy, mButton)
	if mButton == 1 then
		local val
		local ex, ey = mx - x1-2*scale, my - y1-margin
		if ey>=0 and ey<=length then
			val = ey/length
			if ex >= 0 and ex<=10*scale then
				R = val
				spSendLuaRulesMsg("locColR" .. R)
			elseif ex >= 11*scale and ex<=19*scale then
				G = val
				spSendLuaRulesMsg("locColG" .. G)
			elseif ex >= 24*scale and ex<=30*scale then
				B = val				
				spSendLuaRulesMsg("locColB" .. B)
			end
		end
	end
end

function widget:DrawScreen()
	glPushMatrix()
	glTranslate(0,0,-0.1)
		glColor(0,0,0,1)
		glRect(x1,y1,x2,y2)
		glColor(1,0,0,1)
		glRect(x1+margin,y1+margin,x1+9*scale,y2-margin)
		glColor(0,1,0,1)
		glRect(x1+15*scale,y1+margin,x1+21*scale,y2-margin)
		glColor(0,0,1,1)	
		glRect(x1+27*scale,y1+margin,x1+33*scale,y2-margin)
		glColor(R,G,B,1)
		glRect(x2-16*scale,y1+margin,x2-margin,y2-margin)
		glColor(1,1,1,1)
		glRect(x1+1*scale,y1+R*length+1,x1+11*scale,y1+R*length+3)
		glRect(x1+13*scale,y1+G*length+1,x1+23*scale,y1+G*length+3)
		glRect(x1+25*scale,y1+B*length+1,x1+35*scale,y1+B*length+3)
	glPopMatrix()
end

