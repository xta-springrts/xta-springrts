function widget:GetInfo()
  return {
    name      = "Commander Name Tags",
    desc      = "Displays a name tag above commanders.",
    author    = "Evil4Zerggin, Jools, DeadnightWarrior",
    date      = "12.2015",
    license   = "GNU GPL, v2 or later",
    layer     = 2,
    enabled   = true,  --  loaded by default?
  }
end


--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local nameScaling			= true
local useThickLeterring		= true
local heightOffset			= 50
local fontSize				= WG.commNameTagFontSize or 15		-- not real fontsize, it will be scaled
local scaleFontAmount		= 120
local fontShadow			= true		-- only shows if font has a white outline
local shadowOpacity			= 0.35

local font					= gl.LoadFont("FreeSansBold.otf", 55, 10, 10)
local shadowFont 			= gl.LoadFont("FreeSansBold.otf", 55, 38, 1.6)
local noShadowFont			= gl.LoadFont("FreeSansBold.otf", 55, 0, 0)
local myFont				= font

local haveZombies 		  	= (tonumber((Spring.GetModOptions() or {}).zombies) or 0) == 1
local isDecoyStart		  	= false
local gaiaID 				= Spring.GetGaiaTeamID()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetUnitTeam        		= Spring.GetUnitTeam
local GetTeamInfo        		= Spring.GetTeamInfo
local GetPlayerInfo      		= Spring.GetPlayerInfo
local GetPlayerList    		    = Spring.GetPlayerList
local GetTeamColor       		= Spring.GetTeamColor
local GetVisibleUnits    		= Spring.GetVisibleUnits
local GetUnitDefID       		= Spring.GetUnitDefID
local GetAllUnits        		= Spring.GetAllUnits
local IsUnitInView	 	 		= Spring.IsUnitInView
local GetCameraPosition  		= Spring.GetCameraPosition
local GetUnitPosition    		= Spring.GetUnitPosition
local GetFPS					= Spring.GetFPS
local GetSpectatingState		= Spring.GetSpectatingState
local GetUnitHeight				= Spring.GetUnitHeight
local glDepthTest        		= gl.DepthTest
local glAlphaTest        		= gl.AlphaTest
local glColor            		= gl.Color
local glText             		= gl.Text
local glTranslate        		= gl.Translate
local glBillboard        		= gl.Billboard
local glDrawFuncAtUnit   		= gl.DrawFuncAtUnit
local glDrawListAtUnit   		= gl.DrawListAtUnit
local GL_GREATER     	 		= GL.GREATER
local GL_SRC_ALPHA				= GL.SRC_ALPHA	
local GL_ONE_MINUS_SRC_ALPHA	= GL.ONE_MINUS_SRC_ALPHA
local glBlending          		= gl.Blending
local glScale          			= gl.Scale
local Echo						= Spring.Echo

local glCreateList				= gl.CreateList
local glBeginEnd				= gl.BeginEnd
local glDeleteList				= gl.DeleteList
local glCallList				= gl.CallList

local diag						= math.diag

--------------------------------------------------------------------------------

local comms = {}
local drawShadow = fontShadow
local comnameList = {}
local CheckedForSpec = false
local commanderDefs = {}
--------------------------------------------------------------------------------

--gets the name, color, and height of the commander
local function GetCommAttributes(unitID, unitDefID)
	
	local team = GetUnitTeam(unitID)
	if not team then return end
	
	local players = GetPlayerList(team)
	local name = (#players>0) and GetPlayerInfo(players[1]) or 'Robert Paulson'
	local isGaia = team == gaiaID
	local _,player,_,isAI = GetTeamInfo(team)
	local side = commanderDefs[unitDefID]
	
	if isAI then
		local id,botName,host,aiName = Spring.GetAIInfo(team)
		name = (aiName ~= 'UNKNOWN' and aiName ~= 'UKNOWN' and aiName) or (not botName:find('bot') and botName) or side or 'Robert Paulson'
		name = name:gsub("^%l", string.upper)	
	elseif isGaia then
		name = haveZombies and 'Zombie' or 'Gaia'
	else
		name = GetPlayerInfo(player) or side:gsub("^%l", string.upper)
	end
	
	local r, g, b, a = GetTeamColor(team)
	local bgColor = {0,0,0,1}
	if (r + g*1.35 + b*0.5) < 0.75 then  -- not acurate (enough) with playerlist   but...   font:SetAutoOutlineColor(true)   doesnt seem to work
	bgColor = {1,1,1,1}
	end

	local height = GetUnitHeight(unitID) + heightOffset
	
	return {name, {r, g, b, a}, height, bgColor}
end

local function createComnameList(attributes)
	
	comnameList[attributes[1]] = gl.CreateList( function()
		local outlineColor = {0,0,0,1}
		if (attributes[2][1] + attributes[2][2]*1.35 + attributes[2][3]*0.5) < 0.8 then
			outlineColor = {1,1,1,1}
		end
		if useThickLeterring then
			if outlineColor[1] == 1 and fontShadow then
			  glTranslate(0, -(fontSize/44), 0)
			  shadowFont:Begin()
			  shadowFont:SetTextColor({0,0,0,shadowOpacity})
			  shadowFont:SetOutlineColor({0,0,0,shadowOpacity})
			  shadowFont:Print(attributes[1], 0, 0, fontSize, "con")
			  shadowFont:End()
			  glTranslate(0, (fontSize/44), 0)
			end
			
			myFont:SetTextColor(outlineColor)
			myFont:SetOutlineColor(outlineColor)
			local attrib = fontShadow and "con" or "csn"
			
			myFont:Print(attributes[1], -(fontSize/38), -(fontSize/33), fontSize, attrib)
			myFont:Print(attributes[1], (fontSize/38), -(fontSize/33), fontSize, attrib)
			
		end
		myFont:Begin()
		myFont:SetTextColor(attributes[2])
		myFont:SetOutlineColor(outlineColor)
		myFont:Print(attributes[1], 0, 0, fontSize, "con")
		myFont:End()
	end)
end

local function DrawName(unitID, attributes, shadow)
	if comnameList[attributes[1]] == nil then
		createComnameList(attributes)
	end
	glTranslate(0, attributes[3], 0)
	glBillboard()
	if nameScaling then
		glScale(usedFontSize/fontSize,usedFontSize/fontSize,usedFontSize/fontSize)
	end
	glCallList(comnameList[attributes[1]])
	
	if nameScaling then
		glScale(1,1,1)
	end
end

local vsx, vsy = Spring.GetViewGeometry()
function widget:ViewResize()
  vsx,vsy = Spring.GetViewGeometry()
end

function widget:DrawWorld()
  if Spring.IsGUIHidden() then return end
  
  if not CheckedForSpec and Spring.GetGameFrame() > 1 then
	  if GetSpectatingState() then
		CheckedForSpec = true
		CheckAllComs()
	  end
  end
  
  glDepthTest(true)
  glAlphaTest(GL_GREATER, 0)
  glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
   
  local camX, camY, camZ = GetCameraPosition()
  
  for unitID, attributes in pairs(comms) do
    
    -- calc opacity
	if IsUnitInView(unitID) then
		local x,y,z = GetUnitPosition(unitID)
		camDistance = diag(camX-x, camY-y, camZ-z) 
		
	    usedFontSize = (fontSize*0.5) + (camDistance/scaleFontAmount)
	    
		glDrawFuncAtUnit(unitID, false, DrawName, unitID, attributes, fontShadow)
	end
  end
  
  glAlphaTest(false)
  glColor(1,1,1,1)
  glDepthTest(false)
end

--------------------------------------------------------------------------------

function CheckCom(unitID, unitDefID)
  if commanderDefs[unitDefID] then
      comms[unitID] = GetCommAttributes(unitID, unitDefID)
  end
end

function CheckAllComs()
  local allUnits = GetAllUnits()
  for _, unitID in pairs(allUnits) do
    local unitDefID = GetUnitDefID(unitID)
    if commanderDefs[unitDefID] then
      comms[unitID] = GetCommAttributes(unitID, unitDefID)
    end
  end
end

function widget:Initialize()
	widgetHandler:AddAction("comnamescale", toggleNameScaling)
	widgetHandler:AddAction("comnameshadow", toggleNameShadow)
	widgetHandler:AddAction("comnametagsize", setFontSize)
	isDecoyStart = modOptions and modOptions.commander == "decoystart"
	
	for i=1, #UnitDefs do
		local cp = UnitDefs[i].customParams
		if cp and cp.iscommander and (not cp.isdecoycommander or isDecoyStart) then
			local side = cp.side
			commanderDefs[i] = side
		end
	end
	
	CheckAllComs()
end

function widget:Shutdown()
	widgetHandler:RemoveAction("comnamescale")
	widgetHandler:RemoveAction("comnameshadow")
	widgetHandler:RemoveAction("comnametagsize")
end

-- doesnt get triggered anymore!?
function widget:PlayerChanged(playerID)
   if Spring.GetGameFrame()<30*5 then
     CheckAllComs() -- handle substitutions, etc
   end
end
    
function widget:UnitCreated(unitID, unitDefID, unitTeam)
  CheckCom(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  comms[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
  CheckCom(unitID, unitDefID, unitTeam)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  CheckCom(unitID, unitDefID, unitTeam)
end

function widget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
	local unitDefID = GetUnitDefID(unitID)
	CheckCom(unitID, unitDefID, unitTeam)
end

function UpdateDrawList()
	comnameList = {}
end

function toggleNameScaling()
	nameScaling = not nameScaling
	WG.nameScaling = nameScaling
end

function toggleNameShadow()
	fontShadow = not fontShadow
	WG.fontShadow = fontShadow
	if fontShadow then
		myFont = font
		fontSize = WG.commNameTagFontSize or 15
	else
		myFont = noShadowFont
		myFont:SetAutoOutlineColor(true)
		fontSize = WG.commNameTagFontSize or 6
		
	end
	UpdateDrawList()
	CheckAllComs()
end

function setFontSize(_,size)
		
	if size and #tostring(size) == 0 then
		size = 12
		Echo("Error: setting default font size")
	end
	
	WG.commNameTagFontSize = size
	fontSize = size or 12
	comnameList = {}
end


function widget:GetConfigData() --save
    return 
		{
        nameScaling = nameScaling,
		fontShadow = fontShadow,
		fontSize = fontSize,
		}
end

function widget:SetConfigData(data) --load config
	
	if data.nameScaling ~= nil then
		nameScaling = data.nameScaling
		WG.nameScaling = nameScaling
	end
	
	if data.fontShadow ~= nil then
		fontShadow = data.fontShadow
		WG.fontShadow = fontShadow
	end
	
	if data.fontSize ~= nil then
		WG.commNameTagFontSize = data.fontSize
		fontSize = WG.commNameTagFontSize or 15
	end
	
end
