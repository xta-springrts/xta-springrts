--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_allu_res.lua
--  brief:   Shows your allies resources and allows quick resource transfer
--  author:  Owen Martindell
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Ally Resource Bars - XTA",
    desc      = "Shows your allies resources and allows quick resource transfer (v1.4)",
    author    = "TheFatController, AF & Jools",
    date      = "Jan, 2014",
    license   = "MIT/x11",
    layer     = -9,
    enabled   = true  --  loaded by default?
  }
end

-- The MIT License (MIT)

-- Copyright (c) <year> <copyright holders>

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local TOOL_TIPS = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetTeamResources = Spring.GetTeamResources
local GetMyTeamID = Spring.GetMyTeamID
local GetMouseState = Spring.GetMouseState
local GetSpectatingState = Spring.GetSpectatingState
local IsReplay = Spring.IsReplay
local IsGUIHidden = Spring.IsGUIHidden
local ShareResources = Spring.ShareResources
local GetGameFrame = Spring.GetGameFrame
local GetTeamList = Spring.GetTeamList
local GetMyAllyTeamID = Spring.GetMyAllyTeamID
local Echo = Spring.Echo
local mathMin = math.min
local gl, GL = gl, GL
local sF = string.format
local showAll = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local displayList
local staticList
local viewSizeX, viewSizeY = 0,0
local BAR_HEIGHT       = 4
local BAR_SPACER       = 3
local BAR_WIDTH        = 60
local BAR_GAP          = 18
local LOGO_OFFSET	   = 6
local RESTEXT		   = 30
local HEIGHTADJUST	   = 20
local TOTAL_BAR_HEIGHT = (BAR_SPACER + BAR_HEIGHT + BAR_HEIGHT)
local TOP_HEIGHT       = (BAR_GAP + BAR_GAP)
local BAR_OFFSET       = (TOP_HEIGHT + BAR_SPACER)
local START_HEIGHT     = (TOTAL_BAR_HEIGHT + BAR_GAP + TOP_HEIGHT)
local FULL_BAR         = (BAR_WIDTH + BAR_GAP + BAR_GAP + BAR_SPACER)
local w                = (BAR_WIDTH + BAR_OFFSET + BAR_GAP) + RESTEXT
local h                = START_HEIGHT
local x1               = 600
local y1               = 400
local topy			   = y1 + h - HEIGHTADJUST
local mx, my
local sentSomething = false
local enabled       = false
local transferring  = false
local transferTeam
local transferType
local teamList   = {}
local teamRes    = {}
local teamColors = {}
local teamIcons  = {}
local deadTeams  = {}
local sendEnergy = {}
local sendMetal  = {}
local trnsEnergy = {}
local trnsMetal  = {}
local labelText  = {}
local sentEnergy = 0
local sentMetal  = 0
local myID
local gaiaID				= Spring.GetGaiaTeamID()
local imgTex				= "LuaUI/Images/allyres/metaltex.png"
local textsize				= 10
local myFont	 			= gl.LoadFont("FreeSansBold.otf",textsize, 1.9, 40)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function getTeamNames()
	local teamNames = {}
	local playerList = Spring.GetPlayerList()
	for _,playerID in ipairs(playerList) do
		local name,_,spec,teamID = Spring.GetPlayerInfo(playerID)
		if not spec then
			if name and teamID then
				teamNames[teamID] = name
			end
		end
	end
	return teamNames
end

local function firstToUpper(str)
	if not str then return nil end
	return (str:gsub("^%l", string.upper))
end	
	
local function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function formatRes(number)
	local label
	if number > 10000 then
		label = table.concat({math.floor(round(number/1000)),"k"})
	elseif number > 10 then
		label = string.sub(round(number,0),1,3+string.find(round(number,0),"."))
	else
		label = string.sub(round(number,1),1,2+string.find(round(number,1),"."))
	end
	return tostring(label)
end

local function setUpTeam()
	teamList = {}
	teamRes = {}
	teamColors = {}
	myID = GetMyTeamID()
	local getTeams = nil
	local teamCount = 0
	mx, my = 0,0
	if GetSpectatingState() or IsReplay() then
		local myAllyID = Spring.GetMyAllyTeamID()
		
		if showAll then
			getTeams = Spring.GetTeamList()
		else
			getTeams = Spring.GetTeamList(myAllyID)
		end
		
		if getTeams ~= nil then
			for _,teamID in pairs(getTeams) do				
				--local eCur = GetTeamResources(teamID, "energy")
				--if eCur and (not deadTeams[teamID]) then
				if not deadTeams[teamID] and teamID ~= gaiaID then
					teamList[teamID] = true
					teamCount = (teamCount + 1)
				end
			end
		end		
	else
		getTeams = Spring.GetTeamList(Spring.GetMyAllyTeamID())
		for _,teamID in pairs(getTeams) do
			local eCur = GetTeamResources(teamID, "energy")
			if eCur and (not deadTeams[teamID]) then
				
				teamList[teamID] = true
				teamCount = (teamCount + 1)
			end
		end
	end

	for teamID in pairs(teamList) do
		local r,g,b = Spring.GetTeamColor(teamID)
		teamColors[teamID] = {r=r,g=g,b=b}
	end
	
	if (teamCount > 1) and Spring.GetGameFrame() > 1 then
		enabled = true
		return true
	else
		enabled = false
		return false
	end
end

local function transferResources(n)
  local sCur, sMax = GetTeamResources(transferTeam, transferType)
  local lCur, _, _, lInc, _, _, _, lRec = GetTeamResources(myID, transferType)
  if (transferType == "metal") then
    lCur = (lCur - sentMetal)
    sCur = sCur + (sendMetal[transferTeam] or 0)
  else
    lCur = (lCur - sentEnergy)
    sCur = sCur + (sendEnergy[transferTeam] or 0)
  end
  local send = mathMin(mathMin((sMax-sCur),((lInc+lRec)*0.2)),lCur)
  if (send > 0) then
    if (transferType == "energy") then
      if sendEnergy[transferTeam] then
        sendEnergy[transferTeam] = (sendEnergy[transferTeam] + send)
      else
        sendEnergy[transferTeam] = send
        sentSomething = true
      end
      sentEnergy = (sentEnergy + send)
      trnsEnergy[transferTeam] = (send * 30)
    else
      if sendMetal[transferTeam] then
        sendMetal[transferTeam] = (sendMetal[transferTeam] + send)
      else
        sendMetal[transferTeam] = send
        sentSomething = true
      end
      sentMetal = (sentMetal + send)
      trnsMetal[transferTeam] = (send * 30)
    end
  end
end

local function updateStatics()
	
	if (staticList) then gl.DeleteList(staticList) end
	local y1 = topy - h
	
	local function staticFunction()
		gl.Color(0, 0, 0, 0.2)
		gl.Rect(x1, y1, x1+w,topy-HEIGHTADJUST)
		local height = h - TOP_HEIGHT
		local teamNames = getTeamNames()
		teamIcons = {}
		for teamID in pairs(teamList) do
			if (teamID ~= myID or showAll) then
				local x01 			= x1+BAR_GAP-LOGO_OFFSET
				local y01 			= topy-TOTAL_BAR_HEIGHT - height - BAR_HEIGHT
				local w01 			= TOTAL_BAR_HEIGHT
				local _,_,_,_,side = Spring.GetTeamInfo(teamID)

				gl.Color(0, 0, 0, 0.5)
				gl.Rect(x01-1,y01-1,x01+w01+1,y01+w01+1)
				gl.Color(teamColors[teamID].r,teamColors[teamID].g,teamColors[teamID].b,1)
				gl.Texture(imgTex)
				gl.TexRect(x01,y01,x01+w01,y01+w01)
				gl.Texture(false)
				gl.Color(1, 1, 1, 1)

				teamIcons[teamID] =
					{
					name = (teamNames[teamID] or firstToUpper(side)) or "No player",
					iy1 = topy- height - BAR_HEIGHT,
					iy2 = topy-TOTAL_BAR_HEIGHT - height - BAR_HEIGHT,
					}
				height = (height - TOTAL_BAR_HEIGHT - BAR_GAP)
			end
		end
	end
 
	staticList = gl.CreateList( staticFunction )
	
end

local function updateBars()

	local y1 = topy - h
	
	if (myID ~= GetMyTeamID()) then
		if setUpTeam() then
			updateStatics()
			updateBars()
		end
		return false
	end
  
	local eCur, eMax, mCur, mMax, eInc,eRec,mInc,mRec
	local height = h - TOP_HEIGHT
  
	for teamID in pairs(teamList) do
		if (teamID ~= myID or showAll) then
			eCur, eMax = GetTeamResources(teamID, "energy")
			mCur, mMax = GetTeamResources(teamID, "metal")
			eCur = eCur + (sendEnergy[teamID] or 0)
			mCur = mCur + (sendMetal[teamID] or 0)
			_, _, _, eInc, _, _, _, eRec = GetTeamResources(teamID, "energy")
			_, _, _, mInc, _, _, _, mRec = GetTeamResources(teamID, "metal")
	  
			local xoffset = (x1+BAR_OFFSET)
			teamRes[teamID] =
			{
				ex1  = xoffset,
				ey1  = y1+height-BAR_HEIGHT-BAR_SPACER,--
				ex2  = xoffset+BAR_WIDTH,
				ex2b = xoffset+(BAR_WIDTH * (eCur / eMax)),
				ey2  = y1+height-TOTAL_BAR_HEIGHT,--
				mx1  = xoffset,
				my1  = y1+height,
				mx2  = xoffset+BAR_WIDTH,
				mx2b = xoffset+(BAR_WIDTH * (mCur / mMax)),
				my2  = y1+height-BAR_HEIGHT,
				eVal = table.concat({"+", formatRes(eInc+eRec)}),
				mVal = table.concat({"+", formatRes(mInc+mRec)}),
			}
	  
	  
			if (teamID == transferTeam) then
				if (transferType == "energy") then
					teamRes[teamID].eRec = true
				else
					teamRes[teamID].mRec = true
				end
			end
			height = (height - TOTAL_BAR_HEIGHT - BAR_GAP)
		end
	end

	if (height ~= 0) then
		
		h = (h - height)
		updateStatics()
		checkScreen()
	end
  
	if (displayList) then gl.DeleteList(displayList) end
  
	local function displayFunction ()
		for _,d in pairs(teamRes) do
			if d.eRec then
				gl.Color(0.8, 0, 0, 0.8)
			else
				gl.Color(0.8, 0.8, 0, 0.3)
			end
			gl.Rect(d.ex1,d.ey1,d.ex2,d.ey2)

			gl.Color(1, 1, 0, 1)
			gl.Rect(d.ex1,d.ey1,d.ex2b,d.ey2)
			gl.Color(0.8, 0.8, 0, 1)
			gl.Rect(d.ex1,d.ey2,d.ex2b,d.ey2+1)

			if d.mRec then
				gl.Color(0.8, 0, 0, 0.8)
			else
				gl.Color(0.8, 0.8, 0.8, 0.3)
			end
			gl.Rect(d.mx1,d.my1,d.mx2,d.my2)
			gl.Color(1, 1, 1, 1)
			gl.Rect(d.mx1,d.my1,d.mx2b,d.my2)
			gl.Color(0.8, 0.8, 0.8, 1)
			gl.Rect(d.mx1,d.my2,d.mx2b,d.my2+1)

			myFont:Begin()
			myFont:SetTextColor({1, 1, 0, 1})
			myFont:Print(d.eVal,d.mx2+RESTEXT,d.my1-4-textsize,textsize,'rs')
			myFont:SetTextColor({0.8,0.8,0.8,1})
			myFont:Print(d.mVal,d.mx2+RESTEXT,d.my1-4,textsize,'rs')
			myFont:End()
		end
	end
  
	displayList = gl.CreateList(displayFunction)
	
end

function checkScreen()
		
	topy = math.min(viewSizeY+HEIGHTADJUST,topy)
	topy = math.max(0,topy)
	x1 = math.min(viewSizeX-w,x1)
	x1 = math.max(0,x1)
	
	updateBars()
	updateStatics()
end

function widget:Initialize()
	--x1 = math.floor(x1 - viewSizeX)
	--y1 = math.floor(y1 - viewSizeY)
	viewSizeX, viewSizeY = gl.GetViewSizes()
	--x1 = viewSizeX + x1
	--y1 = viewSizeY + y1
	myID = GetMyTeamID()

	if Spring.GetGameFrame() > 1 then
		enabled = true
		setUpTeam()
		updateStatics()
		updateBars()
		updateBars() -- must be run twice because of schmucks
		checkScreen()
	end
end

function widget:Shutdown()
  gl.DeleteList(displayList)
end

function widget:TeamDied(teamID)
  deadTeams[teamID] = true
  if setUpTeam() then
    updateStatics()
    updateBars()
	checkScreen()
  end
end

function widget:TextCommand(command)
		
	if (string.find(command, "allyres")) then 
			
		if (string.find(command, "showall")) then 
			showAll = true
		else
			showAll = false
		end
		setUpTeam()
		updateBars()
		updateStatics()
		checkScreen()
	end
		
	return false
end

function widget:PlayerAdded()
	if setUpTeam() then
		updateStatics()
		updateBars()
		checkScreen()
	end
 end

function widget:PlayerRemoved()
	if setUpTeam() then
		updateStatics()
		updateBars()
		checkScreen()
	end
 end
 
function widget:PlayerChanged()
	if setUpTeam() then
		updateStatics()
		updateBars()
		checkScreen()
	end
 end
 
function widget:UnitCreated(unitID, unitDefID, unitTeam)
  if deadTeams[unitTeam] then
    deadTeams[unitTeam] = nil
    if setUpTeam() then
      updateStatics()
      updateBars()
    end
  end
end

function widget:GameFrame(n)
    gameFrame = n
end

function widget:Update()
	local speed,_,paused = Spring.GetGameSpeed()
	local updateFreq
	if GetMyTeamID() ~= myID or showAll then
		updateBars()	-- must be run twice because schmucks
		updateBars()
	end
	if speed < 0.5 then
		updateFreq = 4
	elseif speed < 1.0 then
		updateFreq = 8
	elseif speed < 2.0 then
		updateFreq = 16
	elseif speed < 4.0 then
		updateFreq = 32
	else
		updateFreq = 128
	end
	if (gameFrame ~= lastFrame and gameFrame%updateFreq == 0) or paused then

		if enabled then
			lastFrame = gameFrame
			updateBars()
			
			if transferTeam then
				transferResources(gameFrame)
			end
			
			if sentSomething and ((gameFrame % 16) == 0) then
				for teamID,send in pairs(sendEnergy) do
					ShareResources(teamID,"energy",send)
				end
				
				for teamID,send in pairs(sendMetal) do
					ShareResources(teamID,"metal",send)
				end
				
				sendEnergy = {}
				sendMetal = {}
				trnsEnergy = {}
				trnsMetal = {}
				sentEnergy = 0
				sentMetal = 0
				sentSomething = false
			end
			
		if TOOL_TIPS then
			local x, y = GetMouseState()
			
			if (mx ~= x) or (my ~= y) or transferring or ((gameFrame % 15) == 0) then
				mx = x
				my = y
				local y1 = topy - h
				
				if (x > x1) and (y > y1 + BAR_GAP) and (x < (x1 + FULL_BAR)) and (y < (y1 + h - TOP_HEIGHT)) then
					
					for teamID,defs in pairs(teamIcons) do
						
						if (y < defs.iy1) and (y >= defs.iy2) then
							local eCur, eMax = GetTeamResources(teamID, "energy")
							local mCur, mMax = GetTeamResources(teamID, "metal")

							labelText[1] =
								{
								label=defs.name,
								x=x1-BAR_SPACER,
								y=defs.iy2-1,
								size=TOTAL_BAR_HEIGHT*1.5,
								config="orn",
								}
							
							labelText[2] =
								{
								label= table.concat({"(M: ",formatRes(mCur), " / ", formatRes(mMax),")"}),
								x=x1-BAR_SPACER,
								y=defs.iy2-TOTAL_BAR_HEIGHT-3,
								size=TOTAL_BAR_HEIGHT,
								config="orn",
								}
							
							labelText[3] =
								{
								label= table.concat({"(E: ", formatRes(eCur), " / ", formatRes(eMax),")"}),
								x=x1-BAR_SPACER,
								y=defs.iy2-2*TOTAL_BAR_HEIGHT-3,
								size=TOTAL_BAR_HEIGHT,
								config="orn",
								}
							return
						end
					end
					updateStatics()
					if (labelText) then labelText = {} end
				elseif (labelText) then labelText = {} end
			end
		end
		
		elseif (#GetTeamList(GetMyAllyTeamID()) > 1) then
			setUpTeam()
			updateStatics()
			updateBars()
		end
	end
end

function widget:GameStart()
  enabled = true
  setUpTeam()
  updateStatics()
end

function widget:DrawScreen()
  
  if enabled and (not IsGUIHidden()) then
    gl.PushMatrix()
      gl.CallList(staticList)
      gl.CallList(displayList)
      if (labelText[1]) then
        gl.Color(1, 1, 1, 0.8)
        gl.Text(labelText[1].label,labelText[1].x,labelText[1].y,labelText[1].size,labelText[1].config)
        gl.Color(0.8, 0.8, 0.8, 0.8)
        gl.Text(labelText[2].label,labelText[2].x,labelText[2].y,labelText[2].size,labelText[2].config)
		gl.Text(labelText[3].label,labelText[3].x,labelText[3].y,labelText[3].size,labelText[3].config)		
      end
    gl.PopMatrix()
  end
end

function widget:MouseMove(x, y, dx, dy, button)
  if (enabled) then
    if moving then
      x1 = x1 + dx
      topy= topy + dy
      updateBars()
      updateStatics()
	  checkScreen()
    elseif transferring then
      transferTeam = nil
      if (x > (x1+BAR_OFFSET)) and (x < (x1+BAR_OFFSET+BAR_WIDTH)) then
        if (transferType == "energy") then
          for teamID,defs in pairs(teamRes) do
            if (y < defs.ey1) and (y > defs.ey2) then
              transferTeam = teamID
              return
            end
          end
        else
          for teamID,defs in pairs(teamRes) do
            if (y < defs.my1) and (y > defs.my2) then
              transferTeam = teamID
              return
            end
          end
        end
      end
    end
  end
end

function widget:MousePress(x, y, button)
	local y1 = topy - h
  if (enabled) and ((x > x1) and (y > y1) and (x < (x1 + w)) and (y < (y1 + h))) then
    if y > (y1 + h - TOP_HEIGHT) then
      capture = true
      moving  = true
      return capture
    end
    if GetSpectatingState() or IsReplay() then
      if (x > (x1+BAR_OFFSET)) and (x < (x1+BAR_OFFSET+BAR_WIDTH)) then
        for teamID,defs in pairs(teamRes) do
          if (y < defs.ey1) and (y >= defs.ey2) then
          local tid = teamID
         Spring.SendCommands('specteam '..tid)
		 checkScreen()
            --transferTeam = teamID
            --transferType = "energy"
            --transferring = true
            return true
          elseif (y < defs.my1) and (y >= defs.my2) then
            local tid = teamID
         Spring.SendCommands('specteam '..tid)
		 checkScreen()
         --transferTeam = teamID
            --transferType = "metal"
            --transferring = true
            return true
          end
        end
      end
     --return false
    end
    if (x > (x1+BAR_OFFSET)) and (x < (x1+BAR_OFFSET+BAR_WIDTH)) then
      for teamID,defs in pairs(teamRes) do
        if (y < defs.ey1) and (y >= defs.ey2) then
          transferTeam = teamID
          transferType = "energy"
          transferring = true
          return true
        elseif (y < defs.my1) and (y >= defs.my2) then
          transferTeam = teamID
          transferType = "metal"
          transferring = true
          return true
        end
      end
    end
  end
  return false
end

function widget:MouseRelease(x, y, button)
  capture = nil
  moving  = nil
  transferring = false
  transferTeam = nil
  return capture
end

function widget:ViewResize(vsx, vsy)
  viewSizeX, viewSizeY = vsx, vsy
  updateBars()
  updateStatics()
  checkScreen()
end

function widget:GetConfigData(data)      -- save
	local vsx, vsy = gl.GetViewSizes()
	return {
			vsx                	= vsx,
			vsy                	= vsy,
			x1         			= x1,
			topy				= topy,
			showAll				= showAll,
		}
	end

function widget:SetConfigData(data)      -- load
	viewSizeX					= data.vsx or viewSizeX
	viewSizeY 					= data.vsy or viewSizeY
	x1         					= data.x1 or x1
	topy						= data.topy or topy
	showAll 					= data.showAll or false
	checkScreen()
end