function widget:GetInfo()
	return {
		name = "Commander visual warning",
		desc = "Displays visual warning when commander is attacked",
		author = "Jools",
		date = "May, 2014",
		license = "GPLv2",
		version = "1.2",
		layer = 1,
		enabled = true
	}
end

local commanderTable				= {}
local commanderRadiuses				= {}
local localTeamID			
local Echo = Spring.Echo
local warningList					= {}
local DISPLAYTIME					= 210
local FADETIME						= 60
local myFont	 					= gl.LoadFont("FreeSansBold.otf",13, 1.9, 40)
local myFontSmall	 				= gl.LoadFont("FreeSansBold.otf",10, 1.9, 40)
local sizeX, sizeY					= 270, 65
local posx, posy					= 600, 400
local BARWIDTH						= 10
local MARGIN						= 5
local BARLENGTH						= 100
local recsize						= 8
local vsx, vsy 						= gl.GetViewSizes()

function widget:Initialize()
    localTeamID = Spring.GetLocalTeamID()   
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget()
		return false
	end
    
	for id, unitDef in ipairs(UnitDefs) do
		if unitDef.customParams.iscommander and (not unitDef.customParams.isdecoycommander) then
			if unitDef.name then
				commanderTable[id] = true
				commanderRadiuses[id] = Spring.GetUnitDefDimensions(id)["radius"]
			end
		end
	end
end

local function getVisibleState(cloaked,cloakrequested,submerged)
	if cloaked then
		if submerged then
			return 21
		else
			return 20
		end
	else
		if cloakrequested then
			if submerged then
				return 11
			else
				return 10
			end
		else
			if submerged then
				return 1
			else
				return 0
			end
		end
	end
	return 0
end

local function getCommandName(cmdID)
	if cmdID == 0 then
		return 'Idle'
	elseif cmdID == CMD.WAIT then
		return 'Waiting'
	elseif cmdID == CMD.GUARD then
		return 'Guarding'
	elseif cmdID == CMD.MOVE then
		return 'Moving'
	elseif cmdID == CMD.ATTACK then
		return 'Attacking'
	elseif cmdID == CMD.PATROL then
		return 'Patrolling'
	elseif cmdID == CMD.SELFD then
		return 'Destructing'
	elseif cmdID == CMD.RECLAIM then
		return 'Reclaiming'
	elseif cmdID == CMD.CAPTURE then
		return 'Capturing'
	elseif cmdID == CMD.DGUN then
		return 'D-Gunning'
	else
		return ""
	end
end

function widget:UnitDamaged (unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if localTeamID ~= unitTeam Spring.IsUnitInView(unitID) then
		return --ignore other teams and units in view
	end
	
	if commanderTable[unitDefID] then 
		local health, maxhealth = Spring.GetUnitHealth(unitID)
		if health > 0 then
			local udef = UnitDefs[unitDefID]
			local now = Spring.GetGameFrame()
			local aName 
			local commanderStates = Spring.GetUnitStates(unitID)
			if attackerDefID then
				aName = table.concat({"by ",(UnitDefs[attackerDefID] or "enemy"),"!"})
			end
			warningList[1] = udef.humanName
			warningList[2] = health/maxhealth
			warningList[3] = aName
			warningList[4] = now
			warningList[5] = unitID
			warningList[6] = commanderStates["firestate"]
			warningList[7] = commanderStates["movestate"]
			
			local cloakstate = commanderStates["cloak"]
			local cloaked = Spring.GetUnitIsCloaked(unitID)
			local _,_,_,_,midY = Spring.GetUnitPosition(unitID,true)
			local radius = commanderRadiuses[unitDefID]
			local submerged = midY and (midY < 0) and radius and (midY + radius < 0)
			warningList[8] = getVisibleState(cloaked,cloakstate,submerged)
			
			local cmd1 = Spring.GetUnitCommands(unitID,1)[1]
			warningList[9] = getCommandName(cmd1 and cmd1.id or 0)
		end
	end
end

function widget:GameFrame(frame)
	if #warningList > 0 then
		if frame > warningList[4] + DISPLAYTIME then
			warningList = {}
		elseif warningList[5] and frame%16 == 0 then
			local unitID = warningList[5]
			local commanderStates = Spring.GetUnitStates(unitID)
			
			warningList[6] = commanderStates["firestate"]
			warningList[7] = commanderStates["movestate"]
			
			local cloakstate = commanderStates["cloak"]
			local cloaked = Spring.GetUnitIsCloaked(unitID)
			local _,_,_,_,midY = Spring.GetUnitPosition(unitID,true)
			local unitDefID = Spring.GetUnitDefID(unitID)
			local radius = commanderRadiuses[unitDefID]
			local submerged = midY and (midY < 0) and radius and (midY + radius < 0)
			warningList[8] = getVisibleState(cloaked,cloakstate,submerged)
			local cmd1 = Spring.GetUnitCommands(unitID,1)[1]
			warningList[9] = getCommandName(cmd1 and cmd1.id or 0)
		end
	end
end

local function DrawBar()
	
	local health = warningList[2]
	local name = table.concat({warningList[1]," attacked"})
	local attacker = warningList[3] or "!"
	local alertFrame = warningList[4]
	local frame = Spring.GetGameFrame()
	
	--back panel
	gl.Color(0, 0, 0, 0.2)
	gl.Rect(posx,posy,posx+sizeX,posy+sizeY)
	
	local r,g,b,a
	if health > 0.5 then
		r,g,b = 0,1,0  -- green
	elseif health > 0.25 then
		r,g,b = 1, 1, 0 -- yellow
	else
		r,g,b = 1, 0, 0 -- red
	end
	
	if frame < alertFrame + DISPLAYTIME - FADETIME then
		a = 1
	else
		a = (alertFrame + DISPLAYTIME - frame)/FADETIME
	end
	
	local x0 = posx + MARGIN
	local x1 = posx + BARLENGTH - MARGIN
	local y2 = posy + sizeY - MARGIN -- text top
	local y1 = y2 - 14 - MARGIN -- bar top
	local y0 = y1 - BARWIDTH  -- bar bottom
	local x2 = posx + sizeX/2 + MARGIN
	local y5 = y1
	local y4 = y5 - recsize - MARGIN
	local y3 = y4 - recsize - MARGIN
	
	--empty bar
	gl.Color(0.4,0.4,0.4,0.5*a)
	gl.Rect(x0,y0,x1,y1)
	-- empty state rectangles
	gl.Rect(x2,y5,x2+recsize,y5-recsize)
	gl.Rect(x2,y4,x2+recsize,y4-recsize)
	gl.Rect(x2,y3,x2+recsize,y3-recsize)
	local unitID = warningList[5]
	local firestate = warningList[6]
	local movestate =warningList[7]
	local visiblestate =warningList[8]
					
	myFontSmall:SetTextColor({1, 1, 1, a})

	--firestate value
	if firestate == 0 then -- hold fire
		gl.Color(0.8,0.1,0.1,0.8) -- red
		myFontSmall:Print("Hold fire",x2+recsize+MARGIN,y5-recsize,10,'bs')
	elseif firestate == 1 then
		gl.Color(1,0.65,0.1,0.8) -- amber
		myFontSmall:Print("Return fire",x2+recsize+MARGIN,y5-recsize,10,'bs')
	elseif firestate == 2 then
		gl.Color(0.1,0.95,0.2,0.8) -- green
		myFontSmall:Print("Fire at will",x2+recsize+MARGIN,y5-recsize,10,'bs')
	end
	gl.Rect(x2+1,y5-1,x2+recsize-1,y5-recsize+1)
	
	--movestate value
	if movestate == 0 then -- hold pos
		gl.Color(0.8,0.1,0.1,0.8) -- red
		myFontSmall:Print("Hold position",x2+recsize+MARGIN,y4-recsize,10,'bs')
	elseif movestate == 1 then -- manoeuvre
		gl.Color(1,0.65,0.1,0.8) -- amber
		myFontSmall:Print("Manoeuvre",x2+recsize+MARGIN,y4-recsize,10,'bs')
	elseif movestate == 2 then -- roam
		gl.Color(0.1,0.95,0.2,0.8) -- green
		myFontSmall:Print("Roam",x2+recsize+MARGIN,y4-recsize,10,'bs')
	end
	gl.Rect(x2+1,y4-1,x2+recsize-1,y4-recsize+1)
	
	-- visiblestate value
	if visiblestate == 21 then
		gl.Color(0.3, 0.5, 0.7, 0.8) -- light blue
		myFontSmall:Print("Cloaked, submerged",x2+recsize+MARGIN,y3-recsize,10,'bs')
	elseif visiblestate == 20 then
		gl.Color(0.1,0.95,0.2,0.8) -- green
		myFontSmall:Print("Cloaked",x2+recsize+MARGIN,y3-recsize,10,'bs')
	elseif visiblestate == 11 then
		gl.Color(0,0,0,0.8) -- black
		myFontSmall:Print("Cloaking, submerged",x2+recsize+MARGIN,y3-recsize,10,'bs')
	elseif visiblestate == 10 then
		gl.Color(1,0.65,0.1,0.8) -- yellow
		myFontSmall:Print("Cloaking...",x2+recsize+MARGIN,y3-recsize,10,'bs')
	elseif visiblestate == 1 then
		gl.Color(0.1,0.1,0.97,0.8) -- darker blue
		myFontSmall:Print("Submerged",x2+recsize+MARGIN,y3-recsize,10,'bs')
	else
		gl.Color(0.8,0.1,0.1,0.8) -- red
		myFontSmall:Print("Visible",x2+recsize+MARGIN,y3-recsize,10,'bs')
	end
	gl.Rect(x2+1,y3-1,x2+recsize-1,y3-recsize+1)
	
	-- Current action
	local action = warningList[9] or "?"
	myFontSmall:Print(action,posx+MARGIN,posy+MARGIN,10,'bs')
	
	-- value
	gl.Color(r,g,b,0.8*a)
	gl.Rect(x0,y0,x0 + health*(x1-x0), y1)
	gl.Color(math.max(r-0.2,0),math.max(g-0.2,0),math.max(b-0.2,0),0.8)
	gl.Rect(x0, y0, x0 + health*(x1-x0), y0+1)
	gl.Color(1, 1, 1, a)
	
	-- text
	myFont:Begin()
	myFont:SetTextColor({1, 1, 1, a})
	myFont:Print(table.concat({name, attacker}),posx+MARGIN,y2,13,'ts')
	myFont:Print(table.concat({string.format("%.0f", health*100)," %"}),x1+10,y0+2,11,'bs')
	myFont:End()
end

function widget:DrawScreen()
	if (not Spring.IsGUIHidden()) and (#warningList > 0) then
		DrawBar()
	end
end

function widget:TweakDrawScreen()
	
	local x0 = posx + MARGIN
	local x1 = posx + BARLENGTH - MARGIN
	local y0 = posy + sizeY - BARWIDTH - MARGIN
	local y1 = posy + sizeY - MARGIN
	
	--back panel
	gl.Color(0, 0, 0, 0.2)
	gl.Rect(posx,posy,posx+sizeX,posy+sizeY)
	
	--empty bar
	gl.Color(0.4,0.4,0.4,0.8)
	gl.Rect(x0,y0,x1,y1)
	
	myFont:Begin()
	myFont:Print("Commander warning GUI",posx+MARGIN,posy+MARGIN,12,'bs')
	myFont:End()
	
end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
						  and y >= BLcornerY
						  and y <= TRcornerY
end

function widget:TweakMousePress(mx, my, mButton)
		
	if IsOnButton(mx,my,posx,posy,posx+sizeX,posy+sizeY) then
		-- Dragging
		return true
	end	
end
					
function widget:TweakMouseMove(mx, my, dx, dy, mButton)
	-- Dragging
	posx = math.max(0, math.min(posx+dx, vsx-sizeX))	--prevent moving off screen
	posy = math.max(0, math.min(posy+dy, vsy-sizeY))
end

function widget:GetConfigData(data)      -- save
	return {
			posx         		= posx,
			posy				= posy,
		}
	end

function widget:SetConfigData(data)      -- load
	posx         				= data.posx or posx
	posy						= data.posy or posy
end