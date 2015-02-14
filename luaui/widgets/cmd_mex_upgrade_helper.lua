function widget:GetInfo() 
  return { 
    name      = "MexUpg Helper", 
    desc      = "", 
    author    = "author: BigHead", 
    date      = "September 13, 2007", 
    license   = "GNU GPL, v2 or later", 
    layer     = -100, 
    enabled   = true -- loaded by default? 
  } 
end 


local upgradeMouseCursor = "Reclaim" 

local CMD_UPGRADEMEX = 31244 

local builderDefs = nil
local showUpgrades = false

local GetUnitDefID = Spring.GetUnitDefID 
local GiveOrderToUnit = Spring.GiveOrderToUnit 
local GetSelectedUnits = Spring.GetSelectedUnits 
local TraceScreenRay = Spring.TraceScreenRay 
local GetActiveCommand = Spring.GetActiveCommand 
local Echo = Spring.Echo
local upgradingMexes = {}
local myTeamID = Spring.GetMyTeamID()
local IsUnitInView = Spring.IsUnitInView
local GetUnitPosition = Spring.GetUnitPosition


local glColor               = gl.Color
local glDepthTest           = glDepthTest
local glUnitShape			= gl.UnitShape
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glTexture				= gl.Texture
local glTexRect				= gl.TexRect
local glCallList			= gl.CallList

local glLineStipple 		= gl.LineStipple
local glBeginEnd			= gl.BeginEnd
local glLineWidth			= gl.LineWidth
local glDepthTest			= gl.DepthTest
local glDepthMask			= gl.DepthMask
local drawList

local mexUnits = {	
	[1] = UnitDefNames["arm_metal_extractor"].id,
	[2] = UnitDefNames["arm_underwater_metal_extractor"].id,
	[3] = UnitDefNames["core_metal_extractor"].id,
	[4] = UnitDefNames["core_underwater_metal_extractor"].id,
	[5] = UnitDefNames["guardian_metal_extractor"].id,
	[6] = UnitDefNames["guardian_underwater_metal_extractor"].id,
	[7] = UnitDefNames["lost_metal_extractor"].id,
	[8] = UnitDefNames["lost_underwater_metal_extractor"].id,	
}

local mexDefs = {}
for _, id in pairs(mexUnits) do
	mexDefs[id] = true
end

local minx = {}
local minz = {}
local maxx = {}
local maxz = {}

local function DoSquare(x1,x2, z1,z2, y)
    gl.Vertex(x1, y, z1)
    gl.Vertex(x1, y, z2)
	gl.Vertex(x2, y, z2)
	gl.Vertex(x2, y, z1)
	gl.Vertex(x1, y, z1)
end

local function GetUpgradingMexes()
	upgradingMexes = {}
	
	local sU = GetSelectedUnits()		
	for _, unitID in pairs(sU) do
		local cmds = Spring.GetUnitCommands (unitID,7)
		for _,cmd in pairs (cmds) do
			if cmd.id == CMD_UPGRADEMEX then
				if #cmd.params == 4 then
					local x = cmd.params[1]
					local y = cmd.params[2]
					local z = cmd.params[3]
					local radius = cmd.params[4]
					
					for _, unitID in pairs (Spring.GetUnitsInSphere(x,y,z,radius,myTeamID)) do
						local mohoDefID = Spring.GetUnitRulesParam(unitID,"UpgradingTo")
						if mohoDefID then
							upgradingMexes[unitID] = mohoDefID
						end
					end
					
					break;
				end
			end
		end
	end
end

local function drawSquares()
	-- not used but left in case someone wants to switch the drawing back from call lists mode
	glDepthTest(false)	
	glLineWidth(0.49)
	glColor(0, 0.5, 1 , 0.50 )
	
	for unitID, mohoDefID in pairs(upgradingMexes) do
		local x, y, z = GetUnitPosition(unitID)
		if x and ( IsUnitInView(unitID) ) then
											
			local x1 = x + (minx[mohoDefID] or -40)
			local x2 = x + (maxx[mohoDefID] or 40)
			local z1 = z + (minz[mohoDefID] or -40)
			local z2 = z + (maxz[mohoDefID] or 40)
			
			glBeginEnd(GL.LINE_STRIP, DoSquare, x1,x2, z1,z2, y)
			
			-- showing unit shape is too expensive
			--glPushMatrix()
			--glTranslate( x, y + 5 , z)
			--glColor(1, 1, 1 , 0.45 )
			--glUnitShape( mohoDefID, myTeamID)		
			--glPopMatrix()
		end
	end
	glLineWidth(1.0)
	glColor(1, 1, 1, 1)

end

local function drawFunction()
	
	glDepthTest(false)	
	glLineWidth(0.49)
	glColor(0, 0.75, 1 , 0.50 )
	
	for unitID, mohoDefID in pairs(upgradingMexes) do
		local x, y, z = GetUnitPosition(unitID)
		if x and ( IsUnitInView(unitID) ) then
											
			local x1 = x + (minx[mohoDefID] or -40)
			local x2 = x + (maxx[mohoDefID] or 40)
			local z1 = z + (minz[mohoDefID] or -40)
			local z2 = z + (maxz[mohoDefID] or 40)
			
			glBeginEnd(GL.LINE_STRIP, DoSquare, x1,x2, z1,z2, y)
			
		end
	end
	
	glLineWidth(1.0)
	glColor(1, 1, 1, 1)

end

local function makeDrawList()
	
	if (drawList) then gl.DeleteList(drawList) end
	drawList = gl.CreateList(drawFunction)	
end

function widget:Initialize() 
	widgetHandler:RegisterGlobal('registerUpgradePairs', registerUpgradePairs) 
	Spring.AssignMouseCursor("Upgrademex", "cursorupgrade", true, false)
	Spring.SetCustomCommandDrawData(CMD_UPGRADEMEX,"Upgrademex",{1.0,1.0,0,0.8},false)
	
	for id,unitDef in pairs(UnitDefs) do
		if unitDef.extractsMetal then
			local dim = Spring.GetUnitDefDimensions(id)
			minz[id] = dim.minz
			maxz[id] = dim.maxz
			minx[id] = dim.minx
			maxx[id] = dim.maxx
		end
	end
end

function widget:Shutdown() 
  widgetHandler:DeregisterGlobal('registerUpgradePairs') 
end 

function registerUpgradePairs(v) 
  builderDefs = v
  return true 
end 

function widget:UpdateLayout(commandsChanged,page,alt,ctrl,meta, shift) 
return true 
end 

-- remove on game over
function widget:GameOver()
	widgetHandler:RemoveWidget()
	return
end

function widget:GameFrame(n)
	if n > 0 then
		Spring.SendCommands({"luarules registerUpgradePairs 1"})
		widgetHandler:RemoveCallIn("GameFrame")
	end
end

function widget:MousePress(x, y, b)
	
  if rightClickUpgradeParams and b==3 then 
    local alt, ctrl, meta, shift = Spring.GetModKeyState() -- 
    local options = {} 
    if shift then options = {"shift"} end 
    GiveOrderToUnit(rightClickUpgradeParams.builderID, CMD_UPGRADEMEX, {rightClickUpgradeParams.mexID}, options) 
    return true 
  end  
end 

function widget:KeyPress(key, mods, isRepeat)
	if key == 0x130 and not isRepeat then -- shift 
		showUpgrades = true
		GetUpgradingMexes()
		makeDrawList()
	elseif key == 0x06D and mods.ctrl and not isRepeat then -- ctrl-M 
		GetUpgradingMexes()
		makeDrawList()
	end
	return false
end

function widget:KeyRelease(key)
	if key == 0x130 then -- shift 
		showUpgrades = false
		drawList = nil
		upgradingMexes = {}
	end
	return false
end

function widget:GetTooltip(x,y) 
  local tooltip = nil 
  if rightClickUpgradeParams then 
    local unitDef = UnitDefs[rightClickUpgradeParams.upgradeTo] 
    tooltip = "Right click to upgrade to " .. unitDef.humanName 
    Spring.SetMouseCursor("Upgrademex") 
  else 
    tooltip = "NO TOOLTIP AVALIABLE" 
  end 
  return tooltip 
end 

function widget:IsAbove(x,y) 
  if not builderDefs then 
    return 
  end 
  rightClickUpgradeParams = nil 
  
  if GetActiveCommand() ~= 0 then 
    return false 
  end 
  
  local selectedUnits = GetSelectedUnits() 
  
  if #selectedUnits ~= 1 then 
    return false 
  end 
  
  local builderID = selectedUnits[1] 
  local upgradePairs = builderDefs[GetUnitDefID(builderID)] 

  if not upgradePairs then 
    return false 
  end 

  local type, unitID = TraceScreenRay(x, y) 

  if type ~= "unit" then 
    return false 
  end 

  local upgradeTo = upgradePairs[GetUnitDefID(unitID)] 
  if not upgradeTo then 
    return false 
  end 

  rightClickUpgradeParams = {builderID = builderID, mexID = unitID, upgradeTo = upgradeTo} 
  return true 
end
	
function widget:DrawWorld()
	if showUpgrades then
		
		if not drawList then makeDrawList() end
		
		glPushMatrix()
		glCallList(drawList)
		glPopMatrix()
	end
end

