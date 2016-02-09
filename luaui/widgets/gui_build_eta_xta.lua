-- $Id: gui_build_eta.lua 2491 2008-07-17 13:36:51Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    gui_build_eta.lua
--  brief:   display estimated time of arrival for builds
--  author:  Dave Rodgers
--
--  >> modified by: jK <<
--
--  Copyright (C) 2007,2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "BuildETA - XTA",
    desc      = "Displays estimated time of arrival for builds",
    author    = "trepan (modified by jK, Jools)",
    date      = "Aug, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
	version   = 2.0, --added by Jools
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local glBillboard = gl.Billboard
local glTranslate = gl.Translate
local glText = gl.Text
local glDepthTest = gl.DepthTest
local glColor = gl.Color
local glDrawFuncAtUnit = gl.DrawFuncAtUnit

local ta_insert = table.insert
local strfmt = string.format
local pairs = pairs
local ipairs = ipairs

local etaTable = {}

-- Localisations
local GetUnitHealth 		= Spring.GetUnitHealth
local GetGameSeconds 		= Spring.GetGameSeconds
local GetTeamUnits  		= Spring.GetTeamUnits
local GetMyTeamID  			= Spring.GetMyTeamID
local GetUnitDefID		 	= Spring.GetUnitDefID
local GetGameSpeed	 		= Spring.GetGameSpeed
local GetSpectatingState	= Spring.GetSpectatingState
local AreTeamsAllied		= Spring.AreTeamsAllied
local IsGUIHidden			= Spring.IsGUIHidden
--------------------------------------------------------------------------------

local vsx, vsy = widgetHandler:GetViewSizes()

function widget:ViewResize(viewSizeX, viewSizeY)
  vsx = viewSizeX
  vsy = viewSizeY
end


--------------------------------------------------------------------------------

local function MakeETA(unitID,unitDefID)
  if (unitDefID == nil) then return nil end
  local _,_,_,_,buildProgress = GetUnitHealth(unitID)
  if (buildProgress == nil) then return nil end

  local ud = UnitDefs[unitDefID]
  if (ud == nil)or(ud.height == nil) then return nil end

  return {
    firstSet = true,
    lastTime = GetGameSeconds(),
    lastProg = buildProgress,
    rate     = nil,
    timeLeft = nil,
    yoffset  = ud.height+14
  }
end


--------------------------------------------------------------------------------

function widget:Initialize()
  local myUnits = Spring.GetTeamUnits(GetMyTeamID())
  for _,unitID in ipairs(myUnits) do
    local _,_,_,_,buildProgress = GetUnitHealth(unitID)
    if (buildProgress < 1) then
      etaTable[unitID] = MakeETA(unitID,GetUnitDefID(unitID))
    end
  end
end


--------------------------------------------------------------------------------

local lastGameUpdate = GetGameSeconds()

function widget:Update(dt)

  local userSpeed,_,pause = GetGameSpeed()
  if (pause) then
    return
  end

  local gs = GetGameSeconds()
  if (gs == lastGameUpdate) then
    return
  end
  lastGameUpdate = gs
  
  local killTable = {}
  for unitID,bi in pairs(etaTable) do
    local _,_,_,_,buildProgress = GetUnitHealth(unitID)
    if ((not buildProgress) or (buildProgress >= 1.0)) then
      ta_insert(killTable, unitID)
    else
      local dp = buildProgress - bi.lastProg 
      local dt = gs - bi.lastTime
      if (dt > 2) then
        bi.firstSet = true
        bi.rate = nil
        bi.timeLeft = nil
      end

      local rate = (dp / dt) * userSpeed

      if (rate ~= 0) then
        if (bi.firstSet) then
          if (buildProgress > 0.001) then
            bi.firstSet = false
          end
        else
          local rf = 0.5
          if (bi.rate == nil) then
            bi.rate = rate
          else
            bi.rate = ((1 - rf) * bi.rate) + (rf * rate)
          end

          local tf = 0.1
          if (rate > 0) then
            local newTime = (1 - buildProgress) / rate
            if (bi.timeLeft and (bi.timeLeft > 0)) then
              bi.timeLeft = ((1 - tf) * bi.timeLeft) + (tf * newTime)
            else
              bi.timeLeft = (1 - buildProgress) / rate
            end
          elseif (rate < 0) then
            local newTime = buildProgress / rate
            if (bi.timeLeft and (bi.timeLeft < 0)) then
              bi.timeLeft = ((1 - tf) * bi.timeLeft) + (tf * newTime)
            else
              bi.timeLeft = buildProgress / rate
            end
          end
        end
        bi.lastTime = gs
        bi.lastProg = buildProgress
      end
    end
  end
  for _,unitID in pairs(killTable) do
    etaTable[unitID] = nil
  end
end


--------------------------------------------------------------------------------

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  local spect,spectFull = GetSpectatingState()
  if AreTeamsAllied(unitTeam,GetMyTeamID()) or (spect and spectFull) then
    etaTable[unitID] = MakeETA(unitID,unitDefID)
  end
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
		
  etaTable[unitID] = nil
end


function widgetHandler:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
  etaTable[unitID] = nil
end


function widget:UnitFinished(unitID, unitDefID, unitTeam)
  etaTable[unitID] = nil
end


--------------------------------------------------------------------------------

local function DrawEtaText(timeLeft,yoffset)
  local etaStr
  if (timeLeft == nil) then
    etaStr = '\255\255\255\1ETA\255\255\255\255:\255\1\1\255???'
  else
    if (timeLeft > 60) then
        etaStr = "\255\255\255\1ETA\255\255\255\255:" .. strfmt('\255\1\255\1%d', timeLeft / 60) .. "m, " .. strfmt('\255\1\255\1%.1f', timeLeft % 60) .. "s"
    elseif (timeLeft > 0) then
      etaStr = "\255\255\255\1ETA\255\255\255\255:" .. strfmt('\255\1\255\1%.1f', timeLeft) .. "s"
    else
      etaStr = "\255\255\255\1ETA\255\255\255\255:" .. strfmt('\255\255\1\1%.1f', -timeLeft) .. "s"
    end
  end

  glTranslate(0, yoffset+5,-4)
  glBillboard()
  glText(etaStr, 0, 0, 8, "c")
end

function widget:DrawWorld()
	if IsGUIHidden() then return end
	
	glDepthTest(true)

	glColor(1, 1, 1)

	for unitID, bi in pairs(etaTable) do
		glDrawFuncAtUnit(unitID, false, DrawEtaText, bi.timeLeft,bi.yoffset)
	end

	glDepthTest(false)
end
  

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
