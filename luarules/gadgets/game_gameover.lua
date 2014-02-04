function gadget:GetInfo()
  return {
    name      = "Gameover procedure",
    desc      = "Do things related to gameover",
	version   = "1.0",
    author    = "Jools",
    date      = "Sep, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

local Echo = Spring.Echo
local CMD_FIRE_STATE 		= CMD.FIRE_STATE
local CMD_STOP 				= CMD.STOP

if gadgetHandler:IsSyncedCode() then
	
	-------------------
	-- SYNCED PART --
	-------------------
	local gameover 			= false
	local ENDTIME			= 180 -- frames
	local endReadyFrame		
	
	function gadget:Initialize()
		Spring.SetGameRulesParam("ShowEnd",0)
	end
	
	function gadget:GameOver()
	-- GameOver callin gets trapped if called from other gadgets with a lower layer first.
		gameover = true
		Spring.PlaySoundFile("sounds/victory1.wav",8.0,0,0,0,0,0,0,'userinterface')
		
		for _, winner in pairs (GG.gamewinners) do
			SendToUnsynced("gameWinnners",winner, #GG.gamewinners)
		end
	end
	
	function ShowEndGraphs()
		
		for _, unitID in ipairs(Spring.GetAllUnits()) do
			Spring.SetUnitNeutral(unitID, true)
			Spring.SetUnitNoSelect(unitID, true)
			Spring.GiveOrderToUnit(unitID, CMD_FIRE_STATE, {0}, {})
			Spring.GiveOrderToUnit(unitID, CMD_STOP,{},{})
		end
		Spring.PlaySoundFile("sounds/beep1.wav",3.0,0,0,0,0,0,0,'userinterface')
		Spring.SetGameRulesParam("ShowEnd",1)
		--Echo("Graph Frame:",Spring.GetGameFrame())
		gadgetHandler:RemoveGadget()
	end
	
	function gadget:GameFrame(frame)
		--Echo(frame,"GF:",Spring.GetGameRulesParam("WaitForComends"),endReadyFrame)
		if gameover and (Spring.GetGameRulesParam("WaitForComends") == 0) then
			if not endReadyFrame then
				endReadyFrame = Spring.GetGameFrame()
				--Echo("End frame:",endReadyFrame)		
			end
			
			if endReadyFrame and (frame > endReadyFrame + ENDTIME) then
				ShowEndGraphs()
			end
		end
	end
else

	-------------------
	-- UNSYNCED PART --
	-------------------
	
	local myFontHuge 	 				= gl.LoadFont("FreeSansBold.otf",72, 1.9, 40) 
	local vsx, vsy 						= gl.GetViewSizes()
	local myTeamID 						= Spring.GetMyTeamID()
	local myAllyID 						= select(6, Spring.GetTeamInfo(myTeamID))
	local gaiaID						= Spring.GetGaiaTeamID()
	local gaiaAllyID 					= select(6, Spring.GetTeamInfo(gaiaID))
	local winners						= {}
	local transferComplete				= false
	
	function gadget:Initialize()
		gadgetHandler:AddSyncAction("gameWinnners", GetGameWinners)
	end
	
	function GetGameWinners(_, winner, n)
		winners[winner] = true
		
		local count = 0
		for _,_ in pairs(winners) do
			count = count + 1
		end
		
		if n == count then transferComplete = true end
	end
	
	function gadget:DrawScreen()
		if not Spring.IsGUIHidden() and Spring.IsGameOver() and Spring.GetGameRulesParam("ShowEnd") ~= 1 and transferComplete then
			local label
			myFontHuge:Begin()
			if winners and winners[myAllyID] then
				label = "VICTORY"
				myFontHuge:SetTextColor({1, 1, 1, 1})
			elseif winners then
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