function widget:GetInfo()
  return {
    name      = "Ceasefire",
    desc      = "Handles reciprocating ceasefires with a voting system.",
    author    = "CarRepairer",
    date      = "2009-01-15",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = false -- loaded by default?
  }
end

-- 2009-08-26 moved UI into widget

local testMode = false
local testOnce = true

local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end

if tobool(Spring.GetModOptions().noceasefire) or Spring.FixedAllies() then
  return
end 

local Echo 				= Spring.Echo
local spGetPlayerInfo	= Spring.GetPlayerInfo
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetTeamList		= Spring.GetTeamList
local spGetAllyTeamList	= Spring.GetAllyTeamList
local spAreTeamsAllied	= Spring.AreTeamsAllied
local spGetAllUnits     = Spring.GetAllUnits
local spGetUnitDefID    = Spring.GetUnitDefID

local rzRadius			= 200

local spGetGameFrame 		= Spring.GetGameFrame
local SendLuaRulesMsg 		= Spring.SendLuaRulesMsg
local spSendCommands		= Spring.SendCommands
local spGetSpectatingState 	= Spring.GetSpectatingState
local spTraceScreenRay		= Spring.TraceScreenRay
local spGetUnitsInCylinder	= Spring.GetUnitsInCylinder
local spGetLocalAllyTeamID	= Spring.GetLocalAllyTeamID
local spGetLocalTeamID		= Spring.GetLocalTeamID

local CallAsTeam = CallAsTeam

local glPushMatrix			= gl.PushMatrix
local glPopMatrix			= gl.PopMatrix
local glTexture				= gl.Texture
local glTexRect				= gl.TexRect
local glTranslate			= gl.Translate
local glColor				= gl.Color
local glBeginEnd			= gl.BeginEnd
local glVertex				= gl.Vertex
local GL_QUADS     			= GL.QUADS
local glDrawGroundCircle	= gl.DrawGroundCircle
local glLineWidth			= gl.LineWidth
local glDepthTest			= gl.DepthTest

LUAUI_DIRNAME = 'LuaUI/'
local fontHandler   = loadstring(VFS.LoadFile(LUAUI_DIRNAME.."modfonts.lua", VFS.ZIP_FIRST))()
local bigFont			= LUAUI_DIRNAME.."Fonts/FreeSansBold_14"
local smallFont			= LUAUI_DIRNAME.."Fonts/FreeSansBold_12"
local fhDraw    		= fontHandler.Draw
local fhDrawCentered	= fontHandler.DrawCentered

local winW, winH 		= 100,100
local expand 			= false
local blink 			= true
local cycle				= 1
local shortcycle		= 1
local rZonePlaceMode	= false
local rZones			= {}
local rZoneSize			= 250
local rZoneCount		= 0
local spec				= true

local myAllyID 		= spGetLocalAllyTeamID()
local myTeamID 		= spGetLocalTeamID()
local myCeasefires 	= {}

local inColors, teamNames = {}, {}
local notifies, notify = {}, true
local cfData
local myCfData
local allowUpdate = true
local remakeSoon = false

local x, y = -100,-100

local Chili = VFS.Include(LUAUI_DIRNAME.."Widgets/chiligui/chiligui.lua")
--local Chili = VFS.Include(LUARULES_DIRNAME.."Gadgets/chiligui/chiligui.lua")
local Button = Chili.Button
local Control = Chili.Control
local Label = Chili.Label
local Colorbars = Chili.Colorbars
local Checkbox = Chili.Checkbox
local Trackbar = Chili.Trackbar
local Window = Chili.Window
local ScrollPanel = Chili.ScrollPanel
local StackPanel = Chili.StackPanel
local Grid = Chili.Grid
local TextBox = Chili.TextBox
local Image = Chili.Image

local th
local CELL_W = 150

local white = {1,1,1,1}
local transblack = {0,0,0,0.2}

--------------------------------------------------------
				
-- LuaRules callins
local function ceasefire(a1, a2, onoff)
	if not spec and myAllyID == a1 then
		if onoff then
			spSendCommands({'ally '.. a2 .. ' 1'})
			myCeasefires[a2] = true
		else
			spSendCommands({'ally '.. a2 .. ' 0'})
			myCeasefires[a2] = nil
		end
	end
end

local function setVote(alliance, enAlliance, teamID, value)
  cfData[alliance][enAlliance].votes[teamID] = value
end

local function setCeasefired(alliance, enAlliance, value)
  cfData[alliance][enAlliance].ceasefired = value
end

local function setCeasefireOffered(alliance, enAlliance, value)
  cfData[alliance][enAlliance].ceasefireOffered = value
end

local function removeAlliance(alliance)
  cfData[alliance] = nil
  for _, aData in pairs(cfData) do
    aData[alliance] = nil
  end
end

-- end of LuaRules callins

local function FindClosestRZone(sx, _, sz)
	local closestDistSqr = math.huge
	local cx, cy, cz  --  closest coordinates
	for rZoneID, pos in pairs(rZones) do
		local hx, hy, hz = pos[1], pos[2], pos[3]
		if hx then 
			local dSquared = (hx - sx)^2 + (hz - sz)^2
			if (dSquared < closestDistSqr) then
				closestDistSqr = dSquared
				cx = hx; cy = hy; cz = hz
				cRZoneID = rZoneID
			end
		end
	end
	if (not cx) then return -1, -1, -1, -1 end
	return cx, cy, cz, closestDistSqr, cRZoneID
end

local function addRZone(x, y, z)
	rZoneCount = rZoneCount + 1
	rZones[#rZones+1] = {x, y, z}
end

local function removeRZone(rZoneID)
	if rZones[rZoneID] then
		rZoneCount = rZoneCount - 1
	end
	rZones[rZoneID] = nil
end

function inRZones(cAlliance)
	local teamList = spGetTeamList(cAlliance)
	for _,teamID in ipairs(teamList) do
		for rZoneID, pos in pairs(rZones) do
			local units = CallAsTeam(myTeamID, function () return spGetUnitsInCylinder(pos[1], pos[3], rzRadius, teamID) end)
			if units and units[1] then
				return true
			end
		end
	end
	return false
end

-----------------------------------------------------------------------------

local oldPrint = print
local function print(...)
  oldPrint(...)
  io.flush()
end

function getTeamListCell(alliance, ceasefired, ceasefireoffered)

	local children = {}

	local textColor = {1,0,0,1}
	if ceasefired then
		textColor = {0,1,0,1}
	elseif ceasefireoffered then
		textColor = {1,0.4,0,1}
	end
	
	children[#children + 1] =  Label:New{ caption = '- Alliance' .. alliance .. ' - ', textColor = textColor,  }
	
	teamList = spGetTeamList(alliance)	
	for k,teamID in ipairs(teamList) do
		if teamNames[teamID] then
			children[#children + 1] =  Label:New{ caption = '  '.. teamNames[teamID], textColor = {Spring.GetTeamColor(teamID)}, }
		end
	end
	
	local innerStack = StackPanel:New{
		padding = {0,0,0,0},
		itemPadding = {1,1,1,1},
		itemMargin = {0,0,0,0},
		height = #children * 15,
		width = CELL_W,
		--resizeItems=false,
		children = children
	}
	
	--return innerStack.height, innerStack
	-- [[
	return innerStack.height, 
		StackPanel:New{
			padding = {0,0,0,0},
			itemPadding = {0,0,0,0},
			itemMargin = {0,0,0,0},
			autoArrangeV=false,
			autoArrangeH=false,
			centerItems = false,
			resizeItems = false,
			height = innerStack.height,
			width = innerStack.width,
			children = { innerStack },
		}
	--]]
end

function getAllianceFriendsCell(alliance)
	local cfFriends = '['
	for enAlliance, enData in pairs(cfData[alliance]) do
		if enData.ceasefired then
			cfFriends = cfFriends .. enAlliance .. ', '
		end
	end
	cfFriends = cfFriends == '[' and '[ ]' or (cfFriends:sub(1,-3) .. ']')
	return Label:New{ caption = cfFriends, textColor = white }
end

local function vote_cf(self)
	SendLuaRulesMsg('cf:' .. (self.checked and 'y' or 'n') .. self.value )
	remakeSoon = true
end

local posX, posY = 1,1
function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
	posX = vsx/3
	posY = vsy/3
end
widget:ViewResize(Spring.GetViewGeometry())



local screen0 = Chili.Screen:New{}

local gridWindow = Window:New{ visible=false, parent=screen0, x = -1000}


local function makeNewCfWindow(x, y)
	if not myCfData then 
		return Window:New{  
			parent = screen0,  
			x = x,  
			y = y,
			height = 100,
			width = 100,
			resizable = false,
			children = {
				Label:New{ caption = 'Please wait...', } 
			}
		}
		
	end
	local childrengrid = {}
	local row = 1
	local col = 1
	
	local row1_height = 0
	
	childrengrid[1] = { [1] = Label:New{ caption = '|[ CeaseFires ]|', textColor=white, align='center'} }
	
	for alliance, aData in pairs(myCfData) do
		col = col + 1
		local cellheight, teamListCell = getTeamListCell(alliance, aData.ceasefired, aData.ceasefireOffered)
		if cellheight > row1_height then
			row1_height = cellheight
		end
		childrengrid[1][col] = teamListCell
	end
	
	col=1
	childrengrid[2] = { [1] = 
		Label:New{ caption = 'Voters\1\1\1\1   \255\255\255\255Friends ->', textColor=white },
	}
	for alliance, aData in pairs(myCfData) do
		col = col + 1
		childrengrid[2][col] = getAllianceFriendsCell(alliance)
	end
	
	col=1
	for alliance, aData in pairs(myCfData) do
		col = col + 1
		row = 2
						
		for teamID, vote in pairs(aData.votes) do
			row = row + 1
			
			if not childrengrid[row] then
				if teamID == myTeamID then
					childrengrid[row] = { [1] = Label:New{ caption = 'My Vote', textColor = {Spring.GetTeamColor(teamID)}, textColor=white,  } }
				else
					childrengrid[row] = { [1] = Label:New{ caption = teamNames[teamID], textColor = {Spring.GetTeamColor(teamID)}, textColor=white,   } }
				end
			end
		
			if aData.ceasefired then
				childrengrid[row][col] = Button:New{ caption='Break Ceasefire', OnMouseUp = {function() SendLuaRulesMsg('cf:b' .. alliance ) remakeSoon = true 	end}, value = alliance}
			else
				if teamID == myTeamID then
					childrengrid[row][col] = 
						StackPanel:New{
							height = 20,
							width = 40,
							resizeItems=false,
							centerItems=false,
							padding = {0,0,0,0},
							itemPadding = {0,0,0,0},
							itemMargin = {0,0,0,0},
							children = {
								Checkbox:New{ checked = vote, caption = (vote and 'Yes' or 'No'), width=35, height=15,OnMouseUp = {vote_cf}, value = alliance, textColor=white }
							}
						}
						
				else
					childrengrid[row][col] = Label:New{ caption = (vote and 'Yes' or 'No'), textColor=white }
				end
			end
		end
	
	end
	
	newChildren = {}
	
	for i,row in ipairs(childrengrid) do
		for j,cell in ipairs(row) do
			newChildren[#newChildren + 1] = cell
		end
	end

	local row_height = 20
	local winwidth = CELL_W * col
	
	local newChildren1, newChildren2  = {}, {}
	for i=1,col do
		newChildren1[#newChildren1+1] = newChildren[i]
	end
	for i=col+1,#newChildren do
		newChildren2[#newChildren2+1] = newChildren[i]
	end
 	
	local gridControl1 = Grid:New{
		padding = {0,0,0,0},
		itemPadding = {2,0,0,0},
		itemMargin = {0,0,0,0},
		autoArrangeH = false,
		autoArrangeV = false,
		centerItems = false,
		width = winwidth,  
		height = row1_height,
		rows=1,
		columns=col,
		children = newChildren1
	}
	local height2 = (row_height+10)*(row-1)
	local gridControl2 = Grid:New{
		width = winwidth,  
		height = height2,
		rows=row-1,
		columns=col,
		--itemPadding = {0, 0, 0, 10},
		children = newChildren2
	}
	
	local winheight = row1_height+height2 + 30
	
	return Window:New{  
		parent = screen0,  
		x = x,  
		y = y,  
		resizable = false,
		clientWidth = winwidth ,
		clientHeight = winheight ,  
		backgroundColor = transblack,
		children = {
			
			StackPanel:New{
				autoArrangeV=false,
				centerItems=false,
				padding = {0,0,0,0},
				itemPadding = {0,10,0,0},
				itemMargin = {0,0,0,0},
				height=winheight,
				width = winwidth ,
				resizeItems=false,
				children = {
					gridControl1,
					gridControl2,
				}, 
			}
			
		}
	}
end

local function remakeCfWindow()
	if gridWindow then
		if x < 0 then
			x,y=400,400
		else
			x,y = gridWindow.x, gridWindow.y
		end
	end
	gridWindow:Dispose()
	if expand then
		gridWindow = makeNewCfWindow(x, y)
	end
end


local window_cfbutton = Window:New{  
	x = posX ,  
	y = posY ,
	clientWidth  = 85,
	clientHeight = 80,
	resizable = false,
	draggable = true,
	parent = screen0,
	backgroundColor = transblack,
	children = {
		Label:New{ caption= 'Ceasefires', x=15, y=0, textColor=white},
		Button:New{backgroundColor = {0.7,0.5,0,1}, textColor = {1,1,1,1}, caption = "Voting Panel", OnMouseUp = {function() expand=not expand remakeCfWindow() end}, width=75, x=5, y=25},
		Label:New{ caption= 'Place Restricted',width = 95,  x=0, y=45, textColor=white},
		Checkbox:New{ checked = rZonePlaceMode, caption = 'Zones', OnMouseUp = {function() rZonePlaceMode = not rZonePlaceMode end},  width=75,x=0, y=65, textColor=white},
	}
}



function widget:MousePress(x,y,button)

  local alt, ctrl, meta, shift = Spring.GetModKeyState()
  local mods = {alt=alt, ctrl=ctrl, meta=meta, shift=shift}

  if screen0:MouseDown(x,y,button,mods) then
    allowUpdate = false
    return true
  end
  if (button==1) then
		if rZonePlaceMode then
			
			local _,pos = spTraceScreenRay(x,y,true)
			if pos then
				local wx,wy,wz = pos[1], pos[2], pos[3]
				local _, _, _, dSquared, closestRZoneID = FindClosestRZone(wx,wy,wz)
				if dSquared ~= -1 and dSquared < rZoneSize*rZoneSize then
					removeRZone(closestRZoneID)
				else
					addRZone(wx,wy,wz)
				end
				return true
			end
		end
	end
	return false
end


function widget:MouseRelease(x,y,button)

	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	local mods = {alt=alt, ctrl=ctrl, meta=meta, shift=shift}

	allowUpdate = true
	if screen0:MouseUp(x,y,button,mods) then
		return true
	end
end


function widget:MouseMove(x,y,dx,dy,button)

  local alt, ctrl, meta, shift = Spring.GetModKeyState()
  local mods = {alt=alt, ctrl=ctrl, meta=meta, shift=shift}

  if screen0:MouseMove(x,y,dx,dy,button,mods) then
    return true
  end
end
-----------------------------------------------------------------------------


function widget:DrawScreen()
  th.Update()
  gl.PushMatrix()
  local vsx,vsy = gl.GetViewSizes()
  gl.Translate(0,vsy,0)
  gl.Scale(1,-1,1)
  screen0:Draw()
  gl.PopMatrix()
end

function widget:DrawWorld()
	if rZonePlaceMode then
		glDepthTest(true)
		for _,pos in pairs(rZones) do
			glLineWidth(4)
			if blink then 
				glColor(1,0,0,1)
			else
				glColor(0,0,0,1)
			end
			glDrawGroundCircle(pos[1],0,pos[3], rZoneSize, 32)
			glLineWidth(2)
			if blink then 
				glColor(0,0,0,1)
			else
				glColor(1,0,0,1)
			end
			
			glDrawGroundCircle(pos[1],0,pos[3], rZoneSize, 32)
		end
		glDepthTest(false)
		glLineWidth(1)
	end
end


function widget:Initialize()
	widgetHandler:RegisterGlobal("CeasefireEventCeasefire",ceasefire)
	widgetHandler:RegisterGlobal("CeasefireEventSetVote",setVote)
	widgetHandler:RegisterGlobal("CeasefireEventSetCeasefired", setCeasefired)
	widgetHandler:RegisterGlobal("CeasefireEventSetCeasefireOffered", setCeasefireOffered)
	widgetHandler:RegisterGlobal("CeasefireEventRemoveAlliance", removeAlliance)

	local teamList = spGetTeamList()
	for _,teamID in ipairs(teamList) do
		local _, leaderPlayerID = spGetTeamInfo(teamID)
		if leaderPlayerID and leaderPlayerID ~= -1 then
			
			teamNames[teamID] = '<' .. (spGetPlayerInfo(leaderPlayerID) or '?? Rob P. ??') .. '>'
			local r,g,b,a = Spring.GetTeamColor(teamID)
			
			if r == 0 then r = 0.01 end
			if g == 0 then g = 0.01 end
			if b == 0 then b = 0.01 end
			if a == 0 then a = 0.01 end
			
			inColors[teamID] = '\\255\\255\\255\\255'
			if r then
				inColors[teamID] = string.char(a*255) .. string.char(r*255) ..  string.char(g*255) .. string.char(b*255)
			end		
			--teamNames[teamID] = inColors[teamID] .. '<' .. '\255\255\255' .. teamNames[teamID] .. inColors[teamID] .. '>'		
		end
	end
	-- initialize cfData
	cfData = {}
	gaiaTeam = Spring.GetGaiaTeamID()
        _,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam)
	local allianceList = spGetAllyTeamList()
        local enAllianceList = spGetAllyTeamList()
	for _, alliance in ipairs(allianceList) do
                if alliance ~= gaiaAlliance then
                        cfData[alliance] = {}
			for _, enAlliance in ipairs(enAllianceList) do
                                if enAlliance ~= alliance and enAlliance ~= gaiaAlliance then
                                        cfData[alliance][enAlliance] = {}
                                        cfData[alliance][enAlliance].votes = {}
                                        local teamList = spGetTeamList(alliance)
                                        for _,teamID in ipairs(teamList) do
                                                cfData[alliance][enAlliance].votes[teamID] = false
                                        end
                                end
                        end
                end
        end

	-- request full data (needed in case of widget reload)
	SendLuaRulesMsg("cf:requestData")
end

function widget:Shutdown()
  widgetHandler:DeregisterGlobal("CeasefireEventCeasefire")
  widgetHandler:DeregisterGlobal("CeasefireEventSetVote")
  widgetHandler:DeregisterGlobal("CeasefireEventSetCeasefired", setCeasefired)
  widgetHandler:DeregisterGlobal("CeasefireEventSetCeasefireOffered", setCeasefireOffered)
  widgetHandler:DeregisterGlobal("CeasefireEventRemoveAlliance", removeAlliance)

end

function widget:Update()
	
	shortcycle = cycle % 32 + 1
	cycle = cycle % (32*5) + 1
	
	if shortcycle == 1 then
		blink = not blink
		if remakeSoon and allowUpdate then
			remakeSoon = false
			remakeCfWindow()
		end
	end
	spec = spGetSpectatingState()
	
	if cycle == 1 then
		myAllyID = spGetLocalAllyTeamID()
		myTeamID = spGetLocalTeamID()
		myCfData = cfData[myAllyID]
		
		if not spec then
			for cAlliance, _ in pairs(myCeasefires) do
				if inRZones(cAlliance) then
					SendLuaRulesMsg('ceasefire:'..cAlliance)
					remakeSoon = true
				end
				local cTeamList = spGetTeamList(cAlliance)	
				if not spAreTeamsAllied(cTeamList[1], myTeamID) then
					spSendCommands({'ally '.. cAlliance .. ' 1'})
					Echo('Ceasefire: Please use the control panel to break ceasefires, '..teamNames[myTeamID] ..'!!')
				end
			end
			
			if not myCfData then return end
			for alliance, aData in pairs(myCfData) do
				if aData.ceasefired then
					if not notifies[alliance] then
						notifies[alliance] = true
						notify = true
					end
				else
					if aData.ceasefireOffered then
						if not notifies[alliance] then
							notifies[alliance] = true
							notify = true
						end
					else
						if notifies[alliance] then
							notifies[alliance] = nil
							notify = true
						end
					end
				end
			end	
		end
		
		if allowUpdate then
			remakeCfWindow()
		end
		
	end
	if (not th) then
		th = Chili.TextureHandler
	--	th.Initialize()
	end
	Chili.TaskHandler.Update()		
end

function widget:IsAbove(x,y)
  if screen0:IsAbove(x,y) then
    return true
  end
end

