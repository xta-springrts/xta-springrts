function widget:GetInfo()
	return {
		name    = "Energy overview",
		desc    = "Lists uses of energy",
		author  = "Jools",
		date    = "Sep, 2014",
		license = "Public domain",
		layer   = 0,
		enabled = true
	}
end

local localTeamID			
local Echo 							= Spring.Echo
local myFont	 					= gl.LoadFont("FreeSansBold.otf",14, 1.9, 40)
local myFontSmall	 				= gl.LoadFont("FreeSansBold.otf",12, 1.9, 40)
local sizex, sizey					= 400, 270
local posx, posy					= 600, 400

local vsx, vsy 						= gl.GetViewSizes()
local visible						= false
local Button						= {}
local glColor 						= gl.Color
local glRect						= gl.Rect
local glTexture 					= gl.Texture
local glTexRect 					= gl.TexRect
local energyCost					= {}
local alterLevelFormat 				= string.char(137) .. '%i'
local mySpectatorState
local leaderID, leaderName, r,g,b
local maxUnits						= Game.maxUnits
local rezzCF						= Game.resurrectEnergyCostFactor


local mohos	= {
[UnitDefNames["arm_moho_mine"].id] 					= true,
[UnitDefNames["arm_underwater_moho_mine"].id] 		= true,
[UnitDefNames["core_moho_mine"].id] 				= true,
[UnitDefNames["core_underwater_moho_mine"].id] 		= true,
[UnitDefNames["lost_moho_mine"].id] 				= true,
[UnitDefNames["lost_underwater_moho_mine"].id] 		= true,
}

local mexxes = {
[UnitDefNames["arm_metal_extractor"].id] 			= true,
[UnitDefNames["arm_moho_mine"].id] 					= true,
[UnitDefNames["arm_underwater_metal_extractor"].id] = true,
[UnitDefNames["arm_underwater_moho_mine"].id] 		= true,
[UnitDefNames["core_metal_extractor"].id] 			= true,
[UnitDefNames["core_moho_mine"].id] 				= true,
[UnitDefNames["core_underwater_metal_extractor"].id]= true,
[UnitDefNames["core_underwater_moho_mine"].id] 		= true,
[UnitDefNames["lost_metal_extractor"].id] 			= true,
[UnitDefNames["lost_moho_mine"].id] 				= true,
[UnitDefNames["lost_underwater_metal_extractor"].id]= true,
[UnitDefNames["lost_underwater_moho_mine"].id] 		= true,
}

local mmakers = {
[UnitDefNames["arm_moho_metal_maker"].id] 			= true,
[UnitDefNames["arm_metal_maker"].id] 				= true,
[UnitDefNames["arm_floating_metal_maker"].id]		= true,
[UnitDefNames["core_moho_metal_maker"].id] 			= true,
[UnitDefNames["core_metal_maker"].id] 				= true,
[UnitDefNames["core_floating_metal_maker"].id]		= true,
[UnitDefNames["lost_moho_metal_maker"].id] 			= true,
[UnitDefNames["lost_metal_maker"].id] 				= true,
[UnitDefNames["lost_floating_metal_maker"].id]		= true,
}

local others = {

}

local function round(num, idp)
		return string.format("%." .. (idp or 0) .. "f", num)
	end

local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
	if BLcornerX == nil then return false end
	-- check if the mouse is in a rectangle

	return x >= BLcornerX and x <= TRcornerX
						  and y >= BLcornerY
						  and y <= TRcornerY
end

local function drawBorder(x0, y0, x1, y1, width)
	glRect(x0, y0, x1, y0 + width)
	glRect(x0, y1, x1, y1 - width)
	glRect(x0, y0, x0 + width, y1)
	glRect(x1, y0, x1 - width, y1)
end

local function StopMohos()
	for _, unitID in pairs(Spring.GetTeamUnits(localTeamID)) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		if mohos[unitDefID] then
			Spring.GiveOrderToUnit(unitID, CMD.ONOFF, { 0 }, {} )
		end
	end
	Echo("Stopping all mohos.")
end

local function NoConvert()
	for _, unitID in pairs(Spring.GetTeamUnits(localTeamID)) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		if mmakers[unitDefID] then
			Spring.GiveOrderToUnit(unitID, CMD.ONOFF, { 0 }, {} )
		end
	end
	Spring.SendLuaRulesMsg(string.format(alterLevelFormat, 100))
	Echo("Stopping all metal makers and setting hover to 100 %")
end

local function ShowCloaked()
	for _, unitID in pairs(Spring.GetTeamUnits(localTeamID)) do
		if Spring.GetUnitIsCloaked(unitID) then
			Spring.GiveOrderToUnit(unitID, CMD.CLOAK, { 0 }, {} )
		end
	end
	Echo("Putting all cloaked units on visible!")
end

local function Waitbuilders()
	for _, unitID in pairs(Spring.GetTeamUnits(localTeamID)) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		if ud.isBuilder then
			local projectID = Spring.GetUnitIsBuilding(unitID)
			local projectCost = projectID and UnitDefs[Spring.GetUnitDefID(projectID)].energyCost or 0
			if projectCost > 0 then
				Spring.GiveOrderToUnit(unitID, CMD.WAIT, { }, {} )
			end
		end
	end
	Echo("Putting all builders on wait!")
end

local function WaitFarks()
	Echo("Putting all resurrection on wait!")
	
	for _, unitID in pairs(Spring.GetTeamUnits(localTeamID)) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		
		if ud.canResurrect then
			local cmd1 = (Spring.GetUnitCommands(unitID,1) or {})[1]
			if cmd1 and cmd1.id == CMD.RESURRECT and #cmd1.params == 1 then
				local buildPower = Spring.GetUnitCurrentBuildPower(unitID)
				if buildPower > 0 then
					local projectID = cmd1.params[1] and cmd1.params[1] - maxUnits
					local rezud = projectID and UnitDefNames[Spring.GetFeatureResurrect(projectID)]
					local projectCost = rezud and rezud.energyCost or 0
					if projectCost > 0 then
						Spring.GiveOrderToUnit(unitID, CMD.WAIT, { }, {} )
					end
				end
			end
		end
	end
end

local function DrawWindow()
	local y0 = posy + sizey
	local x0 = posx + 20
	local x1 = posx + sizex/2
		
	--back panel
	glColor(0.3, 0.3, 0.4, 0.55)
	glRect(posx,posy,posx+sizex,posy+sizey)
		
	-- Buttons
	-- Close
	glColor(0, 0, 0, 0.4)
	glRect(Button["close"]["x0"],Button["close"]["y0"], Button["close"]["x1"], Button["close"]["y1"])
	glColor(0, 0, 0, 1)
	drawBorder(Button["close"]["x0"],Button["close"]["y0"], Button["close"]["x1"], Button["close"]["y1"],1)
	
	if not mySpectatorState then
		-- Construction
		glColor(0, 0, 0, 0.4)
		glRect(Button["builderwait"]["x0"],Button["builderwait"]["y0"], Button["builderwait"]["x1"], Button["builderwait"]["y1"])
		glColor(0, 0, 0, 1)
		drawBorder(Button["builderwait"]["x0"],Button["builderwait"]["y0"], Button["builderwait"]["x1"], Button["builderwait"]["y1"],1)
		
		-- Resurrection
		glColor(0, 0, 0, 0.4)
		glRect(Button["resurrect"]["x0"],Button["resurrect"]["y0"], Button["resurrect"]["x1"], Button["resurrect"]["y1"])
		glColor(0, 0, 0, 1)
		drawBorder(Button["resurrect"]["x0"],Button["resurrect"]["y0"], Button["resurrect"]["x1"], Button["resurrect"]["y1"],1)
		
		-- cloakshow
		glColor(0, 0, 0, 0.4)
		glRect(Button["cloakshow"]["x0"],Button["cloakshow"]["y0"], Button["cloakshow"]["x1"], Button["cloakshow"]["y1"])
		glColor(0, 0, 0, 1)
		drawBorder(Button["cloakshow"]["x0"],Button["cloakshow"]["y0"], Button["cloakshow"]["x1"], Button["cloakshow"]["y1"],1)
		
		-- mohostop
		glColor(0, 0, 0, 0.4)
		glRect(Button["mohostop"]["x0"],Button["mohostop"]["y0"], Button["mohostop"]["x1"], Button["mohostop"]["y1"])
		glColor(0, 0, 0, 1)
		drawBorder(Button["mohostop"]["x0"],Button["mohostop"]["y0"], Button["mohostop"]["x1"], Button["mohostop"]["y1"],1)
		
		-- noconvert
		glColor(0, 0, 0, 0.4)
		glRect(Button["noconvert"]["x0"],Button["noconvert"]["y0"], Button["noconvert"]["x1"], Button["noconvert"]["y1"])
		glColor(0, 0, 0, 1)
		drawBorder(Button["noconvert"]["x0"],Button["noconvert"]["y0"], Button["noconvert"]["x1"], Button["noconvert"]["y1"],1)		
	end
	-- Highlight
	glColor(0.8, 0.8, 0.2, 0.5)
	if Button["close"]["mouse"] then
		glRect(Button["close"]["x0"],Button["close"]["y0"], Button["close"]["x1"], Button["close"]["y1"])
	elseif Button["builderwait"]["mouse"] then
		glRect(Button["builderwait"]["x0"],Button["builderwait"]["y0"], Button["builderwait"]["x1"], Button["builderwait"]["y1"])
	elseif Button["resurrect"]["mouse"] then
		glRect(Button["resurrect"]["x0"],Button["resurrect"]["y0"], Button["resurrect"]["x1"], Button["resurrect"]["y1"])
	elseif Button["cloakshow"]["mouse"] then
		glRect(Button["cloakshow"]["x0"],Button["cloakshow"]["y0"], Button["cloakshow"]["x1"], Button["cloakshow"]["y1"])
	elseif Button["mohostop"]["mouse"] then
		glRect(Button["mohostop"]["x0"],Button["mohostop"]["y0"], Button["mohostop"]["x1"], Button["mohostop"]["y1"])
	elseif Button["noconvert"]["mouse"] then
		glRect(Button["noconvert"]["x0"],Button["noconvert"]["y0"], Button["noconvert"]["x1"], Button["noconvert"]["y1"])
	end
	
	-- Text
	myFont:Begin()
	myFont:SetTextColor({1, 1, 1, 1})
	myFont:Print("Energy overview:",x1,y0 - 20,14,'vcs')
	myFont:Print("Close",(Button["close"]["x0"]+Button["close"]["x1"])/2,Button["close"]["y0"]+10,14,'vcs')
	myFont:End()
	
	myFontSmall:Begin()
	myFontSmall:SetTextColor({0.8, 0.8, 0.8, 1})
	myFontSmall:Print("Construction:",x0,Button["builderwait"]['y0']+4,11,'ds')
	myFontSmall:Print("Resurrection:",x0,Button["resurrect"]['y0']+4,11,'ds')
	myFontSmall:Print("Cloaking cost:",x0,Button["cloakshow"]['y0']+4,11,'ds')
	myFontSmall:Print("Metal extractors:",x0,Button["mohostop"]['y0']+4,11,'ds')
	myFontSmall:Print("Metal conversion:",x0,Button["noconvert"]['y0']+4,11,'ds')
	myFontSmall:Print("Battle:",x0,Button["battle"]['y0']+4,11,'ds')
	if not mySpectatorState then
		myFontSmall:Print("Set on wait",Button["builderwait"]['x1']-10,Button["builderwait"]['y0']+4,10,'rds')
		myFontSmall:Print("Set on wait",Button["resurrect"]['x1']-10,Button["resurrect"]['y0']+4,10,'rds')
		myFontSmall:Print("Set visible",Button["cloakshow"]['x1']-10,Button["cloakshow"]['y0']+4,10,'rds')
		myFontSmall:Print("Stop mohos",Button["mohostop"]['x1']-10,Button["mohostop"]['y0']+4,10,'rds')
		myFontSmall:Print("Stop conversion",Button["noconvert"]['x1']-10,Button["noconvert"]['y0']+4,10,'rds')
	else
		if leaderID and r and g and b then
			myFontSmall:SetTextColor({r,g,b,1})
			myFontSmall:Print(leaderName,posx+sizex-10,y0 - 26,12,'rds')
		end
	end
	myFontSmall:SetTextColor({1, 1, 0.2, 1})
	myFontSmall:Print(round(energyCost['builders'],0),x1,Button["builderwait"]['y0']+4,11,'dcs')
	myFontSmall:Print(round(energyCost['resurrect'],0),x1,Button["resurrect"]['y0']+4,11,'dcs')
	myFontSmall:Print(round(energyCost['cloak'],0),x1,Button["cloakshow"]['y0']+4,11,'dcs')
	myFontSmall:Print(round(energyCost['mohos'],0),x1,Button["mohostop"]['y0']+4,11,'dcs')
	myFontSmall:Print(round(energyCost['econvert'],0),x1,Button["noconvert"]['y0']+4,11,'dcs')
	myFontSmall:Print(round(energyCost['battle'],0),x1,Button["battle"]['y0']+4,11,'dcs')
	myFontSmall:End()
end

local function InitButtons()
	local L1 = 28	-- rowheight
	local L3 = 20   -- buttonheight
	local L2 = 100  -- button width
	local x0 = posx + 20
	local x1 = posx + sizex/2
	local x2 = posx + sizex - 10
	local y0 = posy + sizey
	local y1 = y0 - 40
	Button["close"]["x0"] 			= posx + sizex/2 - 50
	Button["close"]["x1"] 			= Button["close"]["x0"] + 100
	Button["close"]["y0"] 			= posy + 5
	Button["close"]["y1"] 			= Button["close"]["y0"] + 20
	
	Button["builderwait"]['x1']		= x2 - 20
	Button["builderwait"]['x0']		= Button["builderwait"]['x1'] - 80
	Button["builderwait"]['y0']		= y1 - L1
	Button["builderwait"]['y1'] 	= Button["builderwait"]['y0'] + L3
	
	Button["resurrect"]['x1']		= x2 - 20
	Button["resurrect"]['x0']		= Button["resurrect"]['x1'] - 80
	Button["resurrect"]['y0']		= y1 - 2*L1
	Button["resurrect"]['y1'] 		= Button["resurrect"]['y0'] + L3
	
	Button["cloakshow"]['x1']		= x2 - 20
	Button["cloakshow"]['x0']		= Button["cloakshow"]['x1'] - 80
	Button["cloakshow"]['y0']		= y1 - 3*L1
	Button["cloakshow"]['y1'] 		= Button["cloakshow"]['y0'] + L3
	
	Button["mohostop"]['x1']		= x2 - 20
	Button["mohostop"]['x0']		= Button["mohostop"]['x1'] - 80
	Button["mohostop"]['y0']		= y1 - 4*L1
	Button["mohostop"]['y1'] 		= Button["mohostop"]['y0'] + L3
	
	Button["noconvert"]['x1']		= x2 - 20
	Button["noconvert"]['x0']		= Button["noconvert"]['x1'] - 100
	Button["noconvert"]['y0']		= y1 - 5* L1
	Button["noconvert"]['y1'] 		= Button["noconvert"]['y0'] + L3
	
	Button["battle"]['x1']			= x2 - 20
	Button["battle"]['x0']			= Button["battle"]['x1'] - 100
	Button["battle"]['y0']			= y1 - 6* L1
	Button["battle"]['y1'] 			= Button["battle"]['y0'] + L3
	
end

local function IsUnitComplete(unitID)
		if unitID then
			local _,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)
			if buildProgress and buildProgress>=1 then
				return true
			else
				return false
			end
		else 
			return false
		end
	end
	
function widget:Initialize()
	localTeamID = Spring.GetLocalTeamID()
	Button["close"] 				= {}
	Button["builderwait"] 			= {}
	Button["cloakshow"] 			= {}
	Button["mohostop"] 				= {}
	Button["noconvert"] 			= {}
	Button["resurrect"]				= {}
	Button["battle"]				= {}
	Button["other"]					= {}
	InitButtons()
	energyCost["builders"] 			= 0
	energyCost["mohos"] 			= 0
	energyCost["cloak"] 			= 0
	energyCost["econvert"] 			= 0
	energyCost["resurrect"] 		= 0
	energyCost["battle"]	 		= 0
	mySpectatorState = Spring.GetSpectatingState()
end

function widget:Update()
	if mySpectatorState then
		localTeamID = Spring.GetLocalTeamID()
		leaderID = Spring.GetTeamInfo(localTeamID)
		leaderName = leaderID and Spring.GetPlayerInfo(leaderID) or "?"
		
		if leaderID then
			r,g,b = Spring.GetTeamColor(leaderID)
		else
			r = 1
			g = 1
			b = 1
		end
	end
end

function widget:GameFrame(frame)
	if frame%32 == 0 and visible then
		energyCost["builders"] 			= 0
		energyCost["mohos"] 			= 0
		energyCost["cloak"] 			= 0
		energyCost["econvert"] 			= 0
		energyCost["resurrect"] 		= 0
		energyCost["battle"]	 		= 0
		
		for _, unitID in pairs(Spring.GetTeamUnits(localTeamID)) do
			local unitDefID = Spring.GetUnitDefID(unitID)
			local ud = UnitDefs[unitDefID]
			
			-- battle
			if #ud.weapons > 0 and ud.canAttack and not Spring.GetUnitIsCloaked(unitID) then
								
				local buildPower = Spring.GetUnitCurrentBuildPower(unitID)
				local eUse = select(4,Spring.GetUnitResources(unitID))
				energyCost["battle"] = energyCost["battle"] + eUse
			
				if buildPower and buildPower > 0 then
					local projectID = Spring.GetUnitIsBuilding(unitID)
					local projectCost = projectID and UnitDefs[Spring.GetUnitDefID(projectID)].energyCost or 0
			
					if projectCost > 0 and not(IsUnitComplete(projectID) ) then
						local buildTime = projectID and UnitDefs[Spring.GetUnitDefID(projectID)].buildTime or -1
						local buildPower = Spring.GetUnitCurrentBuildPower(unitID)
						local buildSpeed = ud.buildSpeed
						local buildCost = buildSpeed * buildPower * projectCost / buildTime
			
						energyCost["battle"] = math.max(energyCost["battle"] - buildCost,0)
					end
				end
			end
			
			-- builders
			if ud.isBuilder then
				local projectID = Spring.GetUnitIsBuilding(unitID)
				local projectCost = projectID and UnitDefs[Spring.GetUnitDefID(projectID)].energyCost or 0
				
				if projectCost > 0 and not(IsUnitComplete(projectID) ) then
					local buildTime = projectID and UnitDefs[Spring.GetUnitDefID(projectID)].buildTime or -1
					local buildPower = Spring.GetUnitCurrentBuildPower(unitID)
					local buildSpeed = ud.buildSpeed
					local buildCost = buildSpeed * buildPower * projectCost / buildTime
										
					energyCost["builders"] = energyCost["builders"] + buildCost
					
				elseif ud.canResurrect then
					local cmd1 = (Spring.GetUnitCommands(unitID,1) or {})[1]
					if cmd1 and cmd1.id == CMD.RESURRECT and #cmd1.params == 1 then
						local buildPower = Spring.GetUnitCurrentBuildPower(unitID)
						
						local projectID = cmd1.params[1] and cmd1.params[1] - maxUnits
						local rezud = projectID and UnitDefNames[Spring.GetFeatureResurrect(projectID)]
						local buildTime = rezud and rezud.buildTime
						local projectCost = rezud and rezud.energyCost or 0
											
						--local projectProgress = projectID and select(3,Spring.GetFeatureHealth(projectID)) or -1
						
						
						local rezzCost =  buildPower * projectCost * ud.resurrectSpeed / buildTime * rezzCF
						--UseEnergy(ud->energyCost * resurrectSpeed / ud->buildTime * modInfo.resurrectEnergyCostFactor)
						
						energyCost["resurrect"] = energyCost["resurrect"] + rezzCost
					end
				end
			end
			
			-- cloak
			if Spring.GetUnitIsCloaked(unitID) then
				local vx,vy,vz,vt = Spring.GetUnitVelocity(unitID)
				
				if vx and vy and vz and vt and vz == 0 and vy == 0 and vz == 0 and vt == 0 then
					energyCost["cloak"] = energyCost["cloak"] + ud.cloakCost
				else
					energyCost["cloak"] = energyCost["cloak"] + ud.cloakCostMoving
				end
				
			end
			
			-- moho
			if mexxes[unitDefID] then
				local _,_,_,eUse = Spring.GetUnitResources(unitID)
				energyCost["mohos"] = energyCost["mohos"] + eUse
			end
			-- econversion
			if mmakers[unitDefID] then
				local _,_,_,eUse = Spring.GetUnitResources(unitID)
				energyCost["econvert"] = energyCost["econvert"] + eUse
			end
		end
	end
end

function widget:DrawScreen()
	if (not Spring.IsGUIHidden()) and visible then
		DrawWindow()
	end
end

function widget:MousePress(mx, my, mButton)
	if (not Spring.IsGUIHidden()) and visible then
		if mButton == 2 or mButton == 3 then
			if IsOnButton(mx,my,posx,posy,posx+sizex,posy+sizey) then
				-- Dragging
				return true
			end
		elseif mButton == 1 then
			if IsOnButton(mx,my,Button["close"]["x0"],Button["close"]["y0"],Button["close"]["x1"],Button["close"]["y1"]) then
				visible = false
				return true
			end
			if not mySpectatorState then
				if IsOnButton(mx,my,Button["builderwait"]["x0"],Button["builderwait"]["y0"],Button["builderwait"]["x1"],Button["builderwait"]["y1"]) then
					Waitbuilders()
					return true
				elseif IsOnButton(mx,my,Button["resurrect"]["x0"],Button["resurrect"]["y0"],Button["resurrect"]["x1"],Button["resurrect"]["y1"]) then
					WaitFarks()
					return true
				elseif IsOnButton(mx,my,Button["cloakshow"]["x0"],Button["cloakshow"]["y0"],Button["cloakshow"]["x1"],Button["cloakshow"]["y1"]) then
					ShowCloaked()
					return true
				elseif IsOnButton(mx,my,Button["mohostop"]["x0"],Button["mohostop"]["y0"],Button["mohostop"]["x1"],Button["mohostop"]["y1"]) then
					StopMohos()
					return true
				elseif IsOnButton(mx,my,Button["noconvert"]["x0"],Button["noconvert"]["y0"],Button["noconvert"]["x1"],Button["noconvert"]["y1"]) then
					NoConvert()
					return true
				end
			end
		end
	end
end

function widget:MouseMove(mx, my, dx, dy, mButton)
	if (not Spring.IsGUIHidden()) and visible then
		-- Dragging
		posx = math.max(0, math.min(posx+dx, vsx-sizex))	--prevent moving off screen
		posy = math.max(0, math.min(posy+dy, vsy-sizey))
		InitButtons()
	end
end

function widget:PlayerChanged(playerID)
	mySpectatorState = Spring.GetSpectatingState()
	InitButtons()
end

function widget:IsAbove(mx,my)
	if (not Spring.IsGUIHidden()) and visible then
		Button["close"]["mouse"] = false
		Button["builderwait"]["mouse"] = false
		Button["resurrect"]["mouse"] = false
		Button["cloakshow"]["mouse"] = false
		Button["mohostop"]["mouse"] = false
		Button["noconvert"]["mouse"] = false
		
		if IsOnButton(mx,my,Button["close"]["x0"],Button["close"]["y0"],Button["close"]["x1"],Button["close"]["y1"]) then		
			Button["close"]["mouse"] = true
		end
		
		if not mySpectatorState then
			if IsOnButton(mx,my,Button["builderwait"]["x0"],Button["builderwait"]["y0"],Button["builderwait"]["x1"],Button["builderwait"]["y1"]) then		
				Button["builderwait"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["resurrect"]["x0"],Button["resurrect"]["y0"],Button["resurrect"]["x1"],Button["resurrect"]["y1"]) then		
				Button["resurrect"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["mohostop"]["x0"],Button["mohostop"]["y0"],Button["mohostop"]["x1"],Button["mohostop"]["y1"]) then		
				Button["mohostop"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["cloakshow"]["x0"],Button["cloakshow"]["y0"],Button["cloakshow"]["x1"],Button["cloakshow"]["y1"]) then		
				Button["cloakshow"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["noconvert"]["x0"],Button["noconvert"]["y0"],Button["noconvert"]["x1"],Button["noconvert"]["y1"]) then		
				Button["noconvert"]["mouse"] = true
			end
		end
	end
end	

function widget:TextCommand(command)
	if command == 'energy-overview' then
		visible = true
	end
end

function widget:KeyPress(key, mods, isRepeat) 
	if (key == 0x065) and (not isRepeat) and not (mods.shift) and (not mods.alt) and mods.ctrl then -- E key
		visible = true
	elseif key == 0x01B then -- esc
		visible = false
	end
	return false
	
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