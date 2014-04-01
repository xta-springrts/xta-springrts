function gadget:GetInfo()
  return {
    name      = "Gameover procedure",
    desc      = "Do things related to gameover",
	version   = "1.0",
    author    = "Jools",
    date      = "Sep, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 2,
    enabled   = true,  --  loaded by default?
  }
end

local Echo = Spring.Echo
local CMD_FIRE_STATE 		= CMD.FIRE_STATE
local CMD_STOP 				= CMD.STOP

-- This gadget collects information from the other game end gadgets and manages the end procedure in a central way. The game end gadgets that
-- manage when the game ends are game_end and additionally game_teamcomends in case the commander ends option is enabled. These two gadgets
-- set a global variable called GG.gamewinners for who has won the game and they also tell to spring that the game is over.
--
-- This gadget collects that information and does a number of things before it shows the end statistics window. For instance, it plays sounds
-- and displays victory/defeat text. During this time the end statistics window is hidden using the command Spring.SendCommands('endgraph 0'). 
-- The time this phase takes can be altered with the ENDTIME variable (in frames).
--
-- When this time has elapsed this gadget shows the end statistics window. Which one is displayed depends on user setting (gui_tweakmode_settings) 
-- and set by widget.
-- Spring.GetConfigInt("EngineGraphFirst"). 0 = XTA statistics window, 1 = Default Statistics window. These can be changed by pressing buttons in -- top right corner.


if gadgetHandler:IsSyncedCode() then
	
	-------------------
	-- SYNCED PART --
	-------------------
	local ENDTIME			= 60 -- frames
	local gameOverFrame
	local transferStarted	= false
	
	function gadget:Initialize()
		Spring.SetGameRulesParam("ShowEnd",0)
	end
	
	function gadget:ShutDown()
		ShowEndGraphs()
		Spring.SetGameRulesParam("ShowEnd",1)
	end
	
	function gadget:GameOver()
	-- GameOver callin gets trapped if called from other gadgets with a lower layer first.
		gameOverFrame = Spring.GetGameFrame()
		if not transferStarted then
			if GG.gamewinners then
				for _, winner in pairs (GG.gamewinners) do
					SendToUnsynced("gameWinnners",winner, #GG.gamewinners)
				end
			else
				SendToUnsynced("gameWinnners",nil, 0)
			end
		end
	end
	
	function ShowEndGraphs()
		if Spring.GetGameRulesParam("ShowEnd") == 0 then
			for _, unitID in ipairs(Spring.GetAllUnits()) do
				Spring.SetUnitNeutral(unitID, true)
				--Spring.SetUnitNoSelect(unitID, true)
				Spring.GiveOrderToUnit(unitID, CMD_FIRE_STATE, {0}, {})
				Spring.GiveOrderToUnit(unitID, CMD_STOP,{},{})
			end
			Spring.PlaySoundFile("sounds/beep1.wav",3.0,0,0,0,0,0,0,'userinterface')
			Spring.SetGameRulesParam("ShowEnd",1)
		end
		--gadgetHandler:RemoveGadget()
	end
	
	function gadget:GameFrame(frame)
		if Spring.IsGameOver() then
			if (Spring.GetGameRulesParam("WaitForComends") == 0) or (not Spring.GetGameRulesParam("WaitForComends")) then
				if gameOverFrame and (frame > gameOverFrame + ENDTIME) then
					ShowEndGraphs()
				end
			end	
		end
		
		if not transferStarted and frame%16 == 0 and GG.gamewinners then
			transferStarted = true
			for _, winner in pairs (GG.gamewinners) do
				SendToUnsynced("gameWinnners",winner, #GG.gamewinners)
			end
		end
	end
else

	-------------------
	-- UNSYNCED PART --
	-------------------
	
	local myFontHuge 	 				= gl.LoadFont("FreeSansBold.otf",72, 1.9, 40)
	local myFont						= gl.LoadFont("FreeSansBold.otf",12, 1.9, 40)
	local vsx, vsy 						= gl.GetViewSizes()
	local myTeamID 						= Spring.GetMyTeamID()
	local myAllyID 						= select(6, Spring.GetTeamInfo(myTeamID))
	local gaiaID						= Spring.GetGaiaTeamID()
	local gaiaAllyID 					= select(6, Spring.GetTeamInfo(gaiaID))
	local winners						= {}
	local transferComplete				= false
	local buttonBarW					= 200
	local buttonBarH					= 20
	local bbx							= vsx - buttonBarW
	local bby							= vsy - buttonBarH
	local Button						= {}
	GG.showXTAStats						= true
	local hideEndGraphs					= true
	local debugMode						= false
	local mySpectatingState
	
	local function SetUpButtons()
		Button["xta"]		= {}
		Button["engine"]	= {}
		
		Button["xta"]["x0"]		= bbx 
		Button["xta"]["x1"]		= bbx + buttonBarW/2
		Button["xta"]["y0"]		= bby
		Button["xta"]["y1"] 	= bby + buttonBarH
		Button["xta"]["click"]  = GG.showXTAStats
		Button["xta"]["mouse"] 	= false
		
		Button["engine"]["x0"]		= bbx + buttonBarW/2
		Button["engine"]["x1"]		= bbx + buttonBarW
		Button["engine"]["y0"]		= bby
		Button["engine"]["y1"] 		= bby + buttonBarH
		Button["engine"]["click"]  	= GG.showXTAStats
		Button["engine"]["mouse"]	= false	
	end
	
	local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
		if BLcornerX == nil then return false end
		-- check if the mouse is in a rectangle

		return x >= BLcornerX and x <= TRcornerX
							  and y >= BLcornerY
							  and y <= TRcornerY
	end
	
	function gadget:Initialize()
		gadgetHandler:AddSyncAction("gameWinnners", GetGameWinners)
		SetUpButtons()
		mySpectatingState = Spring.GetSpectatingState()
	end
		
	function GetGameWinners(_, winner, n)
		if winner then
			winners[winner] = true
		end
		
		local count = 0
		for _,_ in pairs(winners) do
			count = count + 1
		end
		
		if n >= count or (not winner) then 
			transferComplete = true
			GG.showXTAStats	= tonumber(Spring.GetConfigInt("EngineGraphFirst",0) or 0) == 0
			
			-- hide end graphs while the end text is displayed
			Spring.SendCommands('endgraph 0')
			
			-- play victory/defeat sounds
			
			if winners and winners[myAllyID] and (not mySpectatingState) then
				Spring.PlaySoundFile("sounds/victory1.wav",8.0,0,0,0,0,0,0,'userinterface')
			elseif mySpectatingState then
				Spring.PlaySoundFile("sounds/victory1.wav",8.0,0,0,0,0,0,0,'userinterface')
			end
		end
	end
	
	function gadget:DrawScreen()
		if (not Spring.IsGUIHidden()) and transferComplete then
			
			local showGraph = Spring.GetGameRulesParam("ShowEnd") == 1
			-- end graph related options
			if Spring.IsGameOver() then
				-- show stats buttons
				-- unhide end graphs
				if showGraph and (not GG.showXTAStats) and hideEndGraphs then
					hideEndGraphs = false
					Spring.SendCommands('endgraph 1')
				end
				
				-- show buttons to choose between xta/engine graphs
				--background
				if Button["xta"]["mouse"] then
					gl.Color(0.8, 0.8, 0.2, 0.5) -- yellow on mouseover
				else
					gl.Color(0.3, 0.3, 0.4, 0.55) -- grey
				end
				gl.Rect(Button["xta"]["x0"],Button["xta"]["y0"],Button["xta"]["x1"],Button["xta"]["y1"])
				
				if Button["engine"]["mouse"] then
					gl.Color(0.8, 0.8, 0.2, 0.5) -- yellow on mouseover
				else
					gl.Color(0.3, 0.3, 0.4, 0.55) -- grey
				end
				gl.Rect(Button["engine"]["x0"],Button["engine"]["y0"],Button["engine"]["x1"],Button["engine"]["y1"])
				
				-- button text
				myFont:Begin()
				
				-- xta stats button
				if GG.showXTAStats then  
					myFont:SetTextColor({1, 1, 1, 1})
				else
					myFont:SetTextColor({0.6, 0.6, 0.6, 1})
				end
				myFont:Print("XTA stats",Button["xta"]["x0"]+buttonBarW/4,Button["engine"]["y0"]+6,12,'cs')
				
				-- engine stats button
				if GG.showXTAStats then 
					myFont:SetTextColor({0.6, 0.6, 0.6, 1})
				else
					myFont:SetTextColor({1, 1, 1, 1})
				end
				myFont:Print("Engine stats",Button["engine"]["x0"]+buttonBarW/4,Button["engine"]["y0"]+6,12,'cs')
				myFont:End()
				gl.Color(1,1,1,1)
			end
			
			-- End text
			if not showGraph then
				-- show victory/defeat text		
				local label
				myFontHuge:Begin()
				
				if winners and winners[myAllyID] and (not mySpectatingState) then
					label = "VICTORY"
					myFontHuge:SetTextColor({1, 1, 1, 1})
				elseif winners and (not mySpectatingState) then
					label = "DEFEAT"
					myFontHuge:SetTextColor({1, 0, 0, 1})
				else
					label = "THE END"
					myFontHuge:SetTextColor({1, 0, 0, 1})
				end
				
				myFontHuge:Print(label,vsx/2,vsy/2,72,'cbs')
				myFontHuge:End()
			end
		end
	end
	
	function gadget:KeyPress(key, mods, isRepeat)
		if mods['alt'] and mods['ctrl'] then -- numpad5			
			if key == 0x105 then			
				if not debugMode then
					Echo("XTA debug mode activated, press Ctrl-Alt-NumPad 5 to disable it")
				else
					Echo("XTA debug mode deactivated")
				end
				debugMode = not debugMode
			end
		end
		return false
	end
	
	function gadget:Update()
		if debugMode and Spring.IsGameOver() then
			Echo("Debug info: Wait comends status:", Spring.GetGameRulesParam("WaitForComends"), "Show End status:", Spring.GetGameRulesParam("ShowEnd"))		
		end
	end
	
	function gadget:MousePress(mx, my, mButton)
		
		if (not Spring.IsGUIHidden()) and Spring.IsGameOver() and transferComplete then
			if IsOnButton(mx,my,Button["xta"]["x0"],Button["xta"]["y0"],Button["engine"]["x1"],Button["engine"]["y1"]) then
				if mButton == 1 then
					local showGraph = Spring.GetGameRulesParam("ShowEnd") == 1
					if showGraph then
						if IsOnButton(mx,my,Button["xta"]["x0"],Button["xta"]["y0"],Button["xta"]["x1"],Button["xta"]["y1"]) then
							Spring.SendCommands('endgraph 0')
							GG.showXTAStats = true
						elseif IsOnButton(mx,my,Button["engine"]["x0"],Button["engine"]["y0"],Button["engine"]["x1"],Button["engine"]["y1"]) then
							Spring.SendCommands('endgraph 1')
							GG.showXTAStats = false
						end
					else
						if IsOnButton(mx,my,Button["xta"]["x0"],Button["xta"]["y0"],Button["xta"]["x1"],Button["xta"]["y1"]) then
							GG.showXTAStats = true
						elseif IsOnButton(mx,my,Button["engine"]["x0"],Button["engine"]["y0"],Button["engine"]["x1"],Button["engine"]["y1"]) then
							GG.showXTAStats = false
						end
					end
				elseif mButton == 2 then
					-- At least smooth scroll widget interferes with this: it steals mouse ownership
					-- Dragging
					return true
				end
			end
		end
		return false
	end
	
	function gadget:MouseRelease(mx, my, mButton)
		return false
	end
	
	function gadget:MouseMove(mx, my, dx, dy, mButton)
		if (not Spring.IsGUIHidden()) and Spring.IsGameOver() and transferComplete then
			-- Dragging
			if mButton == 2 then
				bbx = math.max(0, math.min(bbx+dx, vsx-buttonBarW))	--prevent moving off screen
				bby = math.max(0, math.min(bby+dy, vsy-buttonBarH))
			end
			SetUpButtons()
		end
		return false
	end
	
	function gadget:IsAbove(mx,my)
		if (not Spring.IsGUIHidden()) and Spring.IsGameOver() and transferComplete then
			Button["xta"]["mouse"] = false
			Button["engine"]["mouse"] = false
			if IsOnButton(mx,my,Button["xta"]["x0"],Button["xta"]["y0"],Button["xta"]["x1"],Button["xta"]["y1"]) then
				Button["xta"]["mouse"] = true
			elseif IsOnButton(mx,my,Button["engine"]["x0"],Button["engine"]["y0"],Button["engine"]["x1"],Button["engine"]["y1"]) then
				Button["engine"]["mouse"] = true
			end
		end
	end
end