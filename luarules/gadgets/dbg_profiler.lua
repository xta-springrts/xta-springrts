-- $Id: dbg_profiler.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Profiler",
    desc      = "",
    author    = "jK",
    date      = "2007,2008,2009",
    license   = "GNU GPL, v2 or later",
    layer     = math.huge,
    handler   = true,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local modOptions = Spring.GetModOptions()
local enable = false

if modOptions and modOptions.debugmode then
	if modOptions.debugmode == '1' then 
		enable = true 
	end
else
	if Game.modVersion =='$VERSION' then 
		enable = true 
	end
end

if not enable then 	-- allow profiling info only for SVN version
	return false
end

local pairs = pairs
local ipairs = ipairs
local table = table
local math = math
local string = string
local unpack = unpack
local Spring = Spring
local gl = gl

local callinTimes       = {}
local callinTimesSYNCED = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SCRIPT_DIR = Script.GetName() .. '/'

local Hook = function(g,name) return function(...) return g[name](...) end end --//place holder

local inHook = false
local listOfHooks = {}
setmetatable(listOfHooks, { __mode = 'k' })

local function IsHook(func)
  return listOfHooks[func]
end

if (gadgetHandler:IsSyncedCode()) then
  Hook = function (g,name)
    local origFunc = g[name]

    local hook_func = function(...)
      if (inHook) then
        return origFunc(...)
      end

      inHook = true
      SendToUnsynced("prf_started", g.ghInfo.name, name)
      local results = {origFunc(...)}
      SendToUnsynced("prf_finished", g.ghInfo.name, name)
      inHook = false
      return unpack(results)
    end

    listOfHooks[hook_func] = true --note: using function in keys is unsafe in synced code!!!

    return hook_func
  end
else
  Hook = function (g,name)
    local spGetTimer = Spring.GetTimer
    local spDiffTimers = Spring.DiffTimers
    local gadgetName = g.ghInfo.name

    local realFunc = g[name]

    if (gadgetName=="Profiler") then
      return realFunc
    end
    local gadgetCallinTime = callinTimes[gadgetName] or {}
    callinTimes[gadgetName] = gadgetCallinTime
    gadgetCallinTime[name] = gadgetCallinTime[name] or {0,0}
    local timeStats = gadgetCallinTime[name]

    local t

    local helper_func = function(...)
      local dt = spDiffTimers(spGetTimer(),t)
      timeStats[1] = timeStats[1] + dt
      timeStats[2] = timeStats[2] + dt
      inHook = nil
      return ...
    end

    local hook_func = function(...)
      if (inHook) then
        return realFunc(...)
      end

      inHook = true
      t = spGetTimer()
      return helper_func(realFunc(...))
    end

    listOfHooks[hook_func] = true

    return hook_func
  end
end

local function ArrayInsert(t, f, g)
  if (f) then
    local layer = g.ghInfo.layer
    local index = 1
    for i,v in ipairs(t) do
      if (v == g) then
        return -- already in the table
      end
      if (layer >= v.ghInfo.layer) then
        index = i + 1
      end
    end
    table.insert(t, index, g)
  end
end


local function ArrayRemove(t, g)
  for k,v in ipairs(t) do
    if (v == g) then
      table.remove(t, k)
      -- break
    end
  end
end

local hookset = false

local function StartHook()
  if (hookset) then return end
  hookset = true
  Spring.Echo("start profiling")

  local gh = gadgetHandler

  local CallInsList = {}
  for name,e in pairs(gh) do
    local i = name:find("List")
    if (i)and(type(e)=="table") then
      CallInsList[#CallInsList+1] = name:sub(1,i-1)
    end
  end

  --// hook all existing callins
  for _,callin in ipairs(CallInsList) do
    local callinGadgets = gh[callin .. "List"]
    for _,g in ipairs(callinGadgets or {}) do
      g[callin] = Hook(g,callin)
    end
  end

  Spring.Echo("hooked all callins: OK")

  oldUpdateGadgetCallIn = gh.UpdateGadgetCallIn
  gh.UpdateGadgetCallIn = function(self,name,g)
    local listName = name .. 'List'
    local ciList = self[listName]
    if (ciList) then
      local func = g[name]
      if (type(func) == 'function') then
        if (not IsHook(func)) then
          g[name] = Hook(g,name)
        end
        ArrayInsert(ciList, func, g)
      else
        ArrayRemove(ciList, g)
      end
      self:UpdateCallIn(name)
    else
      print('UpdateGadgetCallIn: bad name: ' .. name)
    end
  end

  Spring.Echo("hooked UpdateCallin: OK")
    
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

	function gadget:Initialize()
		gadgetHandler.actionHandler.AddChatAction(gadget, 'profile', StartHook,
		" : starts the gadget profiler (for debugging issues)")
		gadgetHandler.actionHandler.AddChatAction(gadget, 'start-profile', StartProfile,"")
		gadgetHandler.actionHandler.AddChatAction(gadget, 'stop-profile', StopProfile,"")
		StartHook()
	end

	function gadget:Shutdown()
		gadgetHandler.actionHandler.RemoveChatAction(gadget,'profile')
		gadgetHandler.actionHandler.RemoveChatAction(gadget, 'stop-profile')
  end

	function StopProfile()
		SendToUnsynced('hide-profiler')
	end
	
	function StartProfile()
		StartHook()
		SendToUnsynced('show-profiler')
	end
	
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
else

	

  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------

 local startTimer
 local startTimerSYNCED
 local profile_unsynced = true
 local profile_synced = true
 local vsx, vsy, x0,y0
 vsx, vsy = gl.GetViewSizes()
 local hidden = true
 
 local min = math.min
 local max = math.max
 local sizex = 250
 local sizey = 30
 x0,y0 = vsx-sizex, vsy-sizey-100
 local onButtonX = false
 local onButtonV = false
 
 
 local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
			if BLcornerX == nil then return false end
			-- check if the mouse is in a rectangle

			return x >= BLcornerX and x <= TRcornerX
								  and y >= BLcornerY
								  and y <= TRcornerY
		end 

 local function UpdateDrawCallin()
    --[[gadget.DrawScreen = gadget.DrawScreen_
    gadgetHandler:UpdateGadgetCallIn("DrawScreen", gadget)]]
  end

 local function Start(cmd, msg, words, playerID)
    if (Spring.GetLocalPlayerID() ~= playerID) then
      return
    end

    --if (not profile_unsynced) then
      UpdateDrawCallin()
      UpdateDrawCallin()
      startTimer = Spring.GetTimer()
      --StartHook()
      --profile_unsynced = true
    --end
  end
 local function StartSYNCED(cmd, msg, words, playerID)
    --[[if (Spring.GetLocalPlayerID() ~= playerID) then
      return
    end]]

    --if (not profile_synced) then
	startTimer = Spring.GetTimer()
      startTimerSYNCED = Spring.GetTimer()
      --profile_synced = true
      UpdateDrawCallin()
      UpdateDrawCallin()
    --end
  end

 local timers = {}
 function SyncedCallinStarted(_,gname,cname)
    local t  = Spring.GetTimer()
    timers[#timers+1] = t
  end

 function SyncedCallinFinished(_,gname,cname)
    local dt = Spring.DiffTimers(Spring.GetTimer(),timers[#timers])
    timers[#timers]=nil

    local gadgetCallinTime = callinTimesSYNCED[gname] or {}
    callinTimesSYNCED[gname] = gadgetCallinTime
    gadgetCallinTime[cname] = gadgetCallinTime[cname] or {0,0}
    local timeStats = gadgetCallinTime[cname]

    timeStats[1] = timeStats[1] + dt
    timeStats[2] = timeStats[2] + dt
  end

 function gadget:RecvFromSynced(a,b,c)
	if a == "prf_started" then
		SyncedCallinStarted(a,b,c)
	end
	if a == "prf_finished" then
		SyncedCallinFinished(a,b,c)
	end
end

 function gadget:Initialize()
    --gadgetHandler:AddSyncAction("prf_started",SyncedCallinStarted) 
    --gadgetHandler:AddSyncAction("prf_finished",SyncedCallinFinished)
	gadgetHandler.actionHandler.AddSyncAction(gadget, 'show-profiler',ShowProfiler)
	gadgetHandler.actionHandler.AddSyncAction(gadget, 'hide-profiler',HideProfiler)

    StartHook()
	StartSYNCED()
	
  end
  
  function gadget:ShutDown()
	gadgetHandler.actionHandler.RemoveSyncAction(gadget, 'start-profiler')
	gadgetHandler.actionHandler.RemoveSyncAction(gadget, 'stop-profiler')
  end
  
  function ShowProfiler()
	Spring.Echo("Show profiler")
	gadgetHandler:UpdateGadgetCallIn("DrawScreen",gadget)
  end
  
  function HideProfiler()
	gadgetHandler:RemoveGadgetCallIn("DrawScreen",gadget)
	Spring.Echo("Hide profiler")
  end

 local tick = 0.1
 local averageTime = 5
 local loadAverages = {}

 local function CalcLoad(old_load, new_load, t)
  return old_load*math.exp(-tick/t) + new_load*(1 - math.exp(-tick/t)) 
  --return (old_load-new_load)*math.exp(-tick/t) + new_load
end

 local maximum = 0
 local maximumSYNCED = 0
 local totalLoads = {}
 local allOverTime = 0
 local allOverTimeSYNCED = 0
 local allOverTimeSec = 0

 local sortedList = {}
 local sortedListSYNCED = {}
 local function SortFunc(a,b)
  --if (a[2]==b[2]) then
    return a[1]<b[1]
  --else
  --  return a[2]>b[2]
  --end
end



 function gadget:DrawScreen()
	
	
    if not (next(callinTimes)) then
      return --// nothing to do
    end

    if (profile_unsynced) then
      local deltaTime = Spring.DiffTimers(Spring.GetTimer(),startTimer)
      if (deltaTime>=tick) then
        startTimer = Spring.GetTimer()

        totalLoads = {}
        maximum = 0
        allOverTime = 0
        local n = 1
        for wname,callins in pairs(callinTimes) do
          local total = 0
          local cmax  = 0
          local cmaxname = ""
          for cname,timeStats in pairs(callins) do
            total = total + timeStats[1]
            if (timeStats[2]>cmax) then
              cmax = timeStats[2]
              cmaxname = cname
            end
            timeStats[1] = 0
          end

          local load = 100*total/deltaTime
          loadAverages[wname] = CalcLoad(loadAverages[wname] or load, load, averageTime)

          allOverTimeSec = allOverTimeSec + total
 
          local tLoad = loadAverages[wname]
          sortedList[n] = {wname..'('..cmaxname..')',tLoad}
          allOverTime = allOverTime + tLoad
          if (maximum<tLoad) then maximum=tLoad end
          n = n + 1
        end

        table.sort(sortedList,SortFunc)
      end
    end

    if (profile_synced) then
      local deltaTimeSYNCED = Spring.DiffTimers(Spring.GetTimer(),startTimerSYNCED)
      if (deltaTimeSYNCED>=tick) then
        startTimerSYNCED = Spring.GetTimer()

        totalLoads = {}
        maximumSYNCED = 0
        allOverTimeSYNCED = 0
        local n = 1
        for wname,callins in pairs(callinTimesSYNCED) do
          local total = 0
          local cmax  = 0
          local cmaxname = ""
          for cname,timeStats in pairs(callins) do
            total = total + timeStats[1]
            if (timeStats[2]>cmax) then
              cmax = timeStats[2]
              cmaxname = cname
            end
            timeStats[1] = 0
          end

          local load = 100*total/deltaTimeSYNCED
          loadAverages[wname] = CalcLoad(loadAverages[wname] or load, load, averageTime)

          allOverTimeSec = allOverTimeSec + total
 
          local tLoad = loadAverages[wname]
          sortedListSYNCED[n] = {wname..'('..cmaxname..')',tLoad}
          allOverTimeSYNCED = allOverTimeSYNCED + tLoad
          if (maximumSYNCED<tLoad) then maximumSYNCED=tLoad end
          n = n + 1
        end

        table.sort(sortedListSYNCED,SortFunc)
      end
    end

    if (not sortedList[1]) then
      return --// nothing to do
    end

    
    local x,y = x0,y0
	
	gl.Color(0.5,0.2,0.2,0.33)
	gl.Rect(x0,y0,x0+sizex,y0+sizey)
	gl.Color(0.8,0.5,0.5,0.66)
	gl.Text("Gadget profiler:",x0+10,y0+15,14,'vo')
	
	if onButtonX then
		gl.Color(0.7,0.7,0.5,0.4)
	else
		gl.Color(0,0,0,0.2)
	end
	gl.Rect(x0+sizex-30,y0,x0+sizex,y0+sizey)
	gl.Color(0,0,0,0.75)
	gl.Text("X",x0+sizex-15,y0+sizey/2,18,'vco')
    
	if onButtonV then
		gl.Color(0.7,0.7,0.5,0.4)
	else
		gl.Color(0,0,0,0.2)
	end
	gl.Rect(x0+sizex-60,y0,x0+sizex-30,y0+sizey)
	
	gl.Color(1,1,1,0.75)
	gl.Texture('luaui/images/arrow_up.png')
	
	if not hidden then
		gl.TexRect(x0+sizex-60,y0,x0+sizex-30,y0+sizey)	
	else
		gl.TexRect(x0+sizex-60,y0+sizey,x0+sizex-30,y0)
	end
	gl.Texture(false)
	gl.Color(1,1,1,1)
	
	if hidden then 
		gl.Text("\255\255\064\064"..('%.1f%%'):format(allOverTime+allOverTimeSYNCED),x0+sizex-100,y0+sizey/2,12,'vco')
		return 
	end
	
	local maximum_ = (maximumSYNCED > maximum) and (maximumSYNCED) or (maximum)

    gl.Color(1,1,1,1)
    gl.BeginText()
    if (profile_unsynced) then
	
	  y = y - 24
	  gl.Text("UNSYNCED", x+115, y-3, 12, "nOc")
      y = y - 5
      
	  for i=1,#sortedList do
        local v = sortedList[i]
        local wname = v[1]
        local tLoad = v[2]
        if maximum > 0 then
          gl.Rect(x+100-tLoad/maximum_*100, y+1-(12)*i, x+100, y+9-(12)*i)
        end
        gl.Text(wname, x+150, y+1-(12)*i, 10)
        gl.Text(('%.3f%%'):format(tLoad), x+105, y+1-(12)*i, 10)
      end
    end
    if (profile_synced) then
	  y = y-10
      local j = #sortedList + 1

      --gl.Rect(x, y+5-(12)*j, x+230, y+4-(12)*j)
      gl.Color(1,0,0)   
      gl.Text("SYNCED", x+115, y-3-(12)*j, 12, "nOc")
      gl.Color(1,1,1,1)
      j = j

      for i=1,#sortedListSYNCED do
        local v = sortedListSYNCED[i]
        local wname = v[1]
        local tLoad = v[2]
        if maximum > 0 then
          gl.Rect(x+100-tLoad/maximum_*100, y+1-(12)*(j+i), x+100, y+9-(12)*(j+i))
        end
        gl.Text(wname, x+150, y+1-(12)*(j+i), 10)
        gl.Text(('%.3f%%'):format(tLoad), x+105, y+1-(12)*(j+i), 10)
      end
    end
    local i = #sortedList + #sortedListSYNCED + 2
    gl.Text("\255\255\064\064total time", x+150, y-1-(12)*i, 12)
    gl.Text("\255\255\064\064"..('%.3fs'):format(allOverTimeSec), x+105, y-1-(12)*i, 12)
    i = i+1
    gl.Text("\255\255\064\064total FPS cost", x+150, y-1-(12)*i, 12)
    gl.Text("\255\255\064\064"..('%.1f%%'):format(allOverTime+allOverTimeSYNCED), x+105, y-1-(12)*i, 12)
    gl.EndText()
  end

  
 function gadget:MousePress(mx, my, mButton)
	if mButton == 1 then
		if IsOnButton(mx,my,x0+sizex-30,y0,x0+sizex,y0+sizey) then 
			HideProfiler()
			return true
		elseif IsOnButton(mx,my,x0+sizex-60,y0,x0+sizex-30,y0+sizey) then
			if hidden then
				--Spring.Echo("Profiler is now visible")
			else
				--Spring.Echo("Profiler is now hidden")
			end
			hidden = not hidden
			return true
		end
		return false
	end
	
	if (mButton == 2 or mButton == 3) and IsOnButton(mx,my,x0,y0,x0+sizex,y0+sizey) then
		-- Dragging
		return true
	end
	
	return false
 end

 function gadget:MouseMove(mx, my, dx, dy, mButton)
	-- Dragging
	if mButton == 2 or mButton == 3 then
		x0 = max(0, min(x0+dx, vsx-sizex))	--prevent moving off screen
		y0 = max(0, min(y0+dy, vsy-sizey))
		return true
	end
	return false
 end 
	
 function gadget:IsAbove(mx,my)
	onButtonX = false
	onButtonV = false
	
	if IsOnButton(mx,my,x0+sizex-30,y0,x0+sizex,y0+sizey) then 
		onButtonX = true
		return true
	elseif IsOnButton(mx,my,x0+sizex-60,y0,x0+sizex-30,y0+sizey) then
		onButtonV = true
		return true
	end
	
	return false
 end  
  
end





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------