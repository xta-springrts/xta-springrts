--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    game_end.lua
--  brief:   spawns start unit and sets storage levels
--  author:  Andrea Piras
--
--  Copyright (C) 2010,2011.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Game End",
		desc      = "Handles team/allyteam deaths and declares gameover",
		author    = "Andrea Piras, modified by Jools",
		date      = "December, 2012",
		license   = "GNU GPL, v2 or later",
		layer     = 10, -- must be higher than layer for game_gameover gadget, otherwise GameOver callin is trapped
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local Echo = Spring.Echo

---------------
-- SYNCED PART --
---------------
if (gadgetHandler:IsSyncedCode()) then

	local modOptions = Spring.GetModOptions()

	local TEAMZERO = "killall" -- each player is removed if he has no units left
	local ALLYZERO = "team" -- players are left alive and only removed if whole team dies
	local TEAMCOMENDS = "comends" -- team commander ends, teams are killed if they have no commanders left
	local COMMANDER = "commander" -- classic commander ends, if commander is killed, all units die of that player.


	-- teamDeathMode possible values: "none", "teamzerounits" , "allyzerounits". Teamzerounits = killall, allyzerounits = team
	local teamDeathMode = modOptions.mode or TEAMZERO

	-- ignoreGaia is a C-like bool
	local ignoreGaia = 1

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	local gaiaTeamID 						= Spring.GetGaiaTeamID()
	local KillTeam 							= Spring.KillTeam
	local GetAllyTeamList 					= Spring.GetAllyTeamList
	local GetTeamList 						= Spring.GetTeamList
	local GetTeamInfo 						= Spring.GetTeamInfo
	local GameOver 							= Spring.GameOver
	local AreTeamsAllied 					= Spring.AreTeamsAllied
	local GetPlayerInfo						= Spring.GetPlayerInfo

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	local gaiaAllyTeamID
	local allyTeams 						= GetAllyTeamList()
	local teamsUnitCount 					= {}
	local allyTeamUnitCount 				= {}
	local allyTeamAliveTeamsCount 			= {}
	local teamToAllyTeam 					= {}
	local aliveAllyTeamCount 				= 0
	local killedAllyTeams 					= {}
	local gameoverframe 					= nil
	local gamewinners 						= nil
	local GAMEOVERDELAY						= 96 -- To allow explosions to calm down and to show end text before end graph
	local VOTEDELAY							= 150 -- 5 seconds
	local voteForEnd						= false
	local voteForDraw						= false
	local voteStartFrame					= nil
	local votingStarted						= false
	local VOTETIME							= 30 -- seconds
	local voteRegex 						= '^\174(%d+)$'
	local votingAllyID						= nil
	local VOTEMSG							= '\174'
	local VOTEMSGSIZE						= #VOTEMSG
	local hideVoting						= false
	local votingDrawTable					= nil -- indexed table of players that are allowed to vote for draw
	local votingDrawPlayers					= {}  -- lookup table with playerID = true
	-------------------------------------------------------------------------------
	--------------------------------------------------------------------------------

	function gadget:GameOver()
		-- This callin gets trapped here and no other gadgets can use the same callin, unless the layer 
		-- of this gadget is higher than the other ones. It doesn't mattre if you return true, false or nil from this callin.
		--
		--remove ourself after successful game over
		gadgetHandler:RemoveGadget()
	end

	local function IsCandidateWinner(allyTeamID)
		local isAlive = (killedAllyTeams[allyTeamID] ~= true)
		local gaiaCheck = (ignoreGaia == 0) or (allyTeamID ~= gaiaAllyTeamID)
		return isAlive and gaiaCheck
	end
	
	local function IsTeamActive(teamID)
		for _, pID in pairs (Spring.GetPlayerList(teamID, true)) do
			local _,active, spec = Spring.GetPlayerInfo(pID)
			if active and not spec then return true end
		end
		return false
	end

	local function IsAllyControlled(allyTeamID)
		
		for _, tID in pairs (Spring.GetTeamList(allyTeamID)) do
			local _,_,isDead,isAI = GetTeamInfo(tID)
			if tID ~= gaiaTeamID and not (isDead or teamsUnitCount[tID] == 0) and (isAI or IsTeamActive(tID)) then
				return true
			end
		end
		return false
	end

	local function CheckSingleAllyVictoryEnd()
		
		if aliveAllyTeamCount ~= 1 then
			
			local controlledCount = 0
			for allyID,_ in pairs(allyTeamAliveTeamsCount) do
				if IsAllyControlled(allyID) then
					controlledCount = controlledCount + 1
					if controlledCount > 1 then
						break;
					end	
				end
			end
			
			if controlledCount > 1 then
				Spring.SetGameRulesParam("VoteForEnd",0)
				Spring.SetGameRulesParam("VotingAllyID",-1)
				return false
			elseif controlledCount == 0 then
				return {}
			elseif not hideVoting then -- one controlled team left and more uncontrolled
				--Echo("Uncontrolled teams voting...")
				voteForEnd = true
				if not voteStartFrame then
					voteStartFrame = Spring.GetGameFrame() + VOTEDELAY
				end
				voteForDraw = false
				Spring.SetGameRulesParam("VoteForDraw",0)
				
				-- find last remaining allyteam that is controlled
				for i,candidateWinner in ipairs(allyTeams) do
					if IsCandidateWinner(candidateWinner) and IsAllyControlled(candidateWinner) then
						votingAllyID = candidateWinner
						Spring.SetGameRulesParam("VotingAllyID",votingAllyID)
						return false
					end
				end
			else
				return false
			end
		end

		-- find the last remaining allyteam
		for _,candidateWinner in ipairs(allyTeams) do
			if IsCandidateWinner(candidateWinner) then
				return {candidateWinner}
			end
		end

		return {}
	end

	local function AreAllyTeamsDoubleAllied( firstAllyTeamID,  secondAllyTeamID )
		-- we need to check for both directions of alliance
		return AreTeamsAllied( firstAllyTeamID,  secondAllyTeamID ) and AreTeamsAllied( secondAllyTeamID, firstAllyTeamID )
	end

	local function CheckGameOver()
		local winners
		
		if aliveAllyTeamCount == 0 then
			winners = {}
		else
			winners = CheckSingleAllyVictoryEnd()
		end
		
		if winners and (not gameoverframe) then
			if not voteStarted then
				local frame = Spring.GetGameFrame()
				gamewinners = winners
				if not GG.gamewinners then
					GG.gamewinners = winners -- pass information to game_gameover.lua
				end
				gameoverframe = frame + GAMEOVERDELAY
			end
		end
	end
	
	local function GetControlledAllyTeams()
		local controlledCount = 0
		local winningAllyTeam = nil
		for allyID,_ in pairs(allyTeamAliveTeamsCount) do
			if IsAllyControlled(allyID) then
				controlledCount = controlledCount + 1
				if controlledCount > 1 then
					break;
				end	
			end
		end
		
		if controlledCount == 1 then
			for i,candidateWinner in ipairs(allyTeams) do
				if IsCandidateWinner(candidateWinner) and IsAllyControlled(candidateWinner) then
					winningAllyTeam = candidateWinner
					break;
				end
			end
		end
		return aliveAllyTeamCount,controlledCount,winningAllyTeam
	end
	
	local function KillTeamsZeroUnits()
		-- kill all the teams that have zero units

		for teamID, unitCount in pairs(teamsUnitCount) do
			if unitCount == 0 then
				KillTeam( teamID )
			end
		end
	end

	local function KillAllyTeamsZeroUnits()
		-- kill all the allyteams that have zero units

		for allyTeamID, unitCount in pairs(allyTeamUnitCount) do
			if unitCount == 0 then
				-- kill all the teams in the allyteam
				local teamList = GetTeamList(allyTeamID)
				for _,teamID in ipairs(teamList) do
					KillTeam( teamID )
				end				
			end
		end
	end

	local function KillResignedTeams()
		-- Check for teams w/o leaders -> all players resigned & no AIs left in the team
		-- Note: In the case a player drops he will still be the leader of the team!
		--       So he can reconnect and take his units.
		local teamList = Spring.GetTeamList()
		for i=1, #teamList do
			local teamID = teamList[i]
			local leaderID = select(2, GetTeamInfo(teamID))
			if (leaderID < 0) then
				KillTeam(teamID)
			end
		end
	end

	local function GetVotes(votingAllyID)
		local votesYes = 0
		local votesNo = 0
		local votesAbs = 0
		if votingAllyID then
			for _, teamID in pairs (GetTeamList(votingAllyID)) do
				local vote = Spring.GetTeamRulesParam(teamID,"Vote")
				if  vote == 0 then
					votesNo = votesNo + 1
				elseif vote == 1 then
					votesYes = votesYes + 1
				else
					votesAbs = votesAbs + 1
				end
			end
		end
		return votesYes,votesNo,votesAbs
	end
	
	local function GetVotesForDraw()
		local votesYes = 0
		local votesNo = 0
		local votesAbs = 0
		
		for _, playerID in pairs (votingDrawTable) do
			local teamID = select(4,Spring.GetPlayerInfo(playerID))
			if teamID then
				local vote = Spring.GetTeamRulesParam(teamID,"DrawVote")
				if  vote == 3 then
					votesNo = votesNo + 1
				elseif vote == 4 then
					votesYes = votesYes + 1
				else
					votesAbs = votesAbs + 1
				end
			end
		end
		return votesYes,votesNo,votesAbs
	end
	
	local function EndVoting()
		voteForEnd = false
		voteForDraw = false
		voteStartFrame = nil
		Spring.SetGameRulesParam("VoteForEnd",0)
		Spring.SetGameRulesParam("VoteForDraw",0)
		hideVoting = true
		Spring.SetGameRulesParam("VoteTime",0)
		votingDrawPlayers = {}
		votingDrawTable	= nil
		votingStarted = false
	end
	
	local function ResetVotes(votingAllyID)
		for _, teamID in pairs (GetTeamList(votingAllyID)) do
			Spring.SetTeamRulesParam(teamID,"Vote", 2)
		end
	end
	
	local function ResetVotesForDraw()
		for _, playerID in pairs (votingDrawTable) do
			local teamID = select(4,Spring.GetPlayerInfo(playerID))
			if teamID then
				Spring.SetTeamRulesParam(teamID,"DrawVote", 2)
			end
		end
	end
	
	function gadget:GameFrame(frame)
		
		-- trigger gameover with a delay to let all explosions calm down
		if gameoverframe and frame >= gameoverframe and (gamewinners or GG.gamewinners) then
			if not GG.gamewinners then
				GG.gamewinners = gamewinners
			else
				gamewinners = GG.gamewinners
			end
			GameOver(gamewinners)
		elseif GG.gamewinners and not gameoverframe then -- handle teamcomends gameover call
			gameoverframe = frame + GAMEOVERDELAY
		end

		-- only do a check in slowupdate
		if not votingStarted then
			if (frame%32) == 0 then
				CheckGameOver()
				-- kill teams after checking for gameover to avoid to trigger instantly gameover
				if teamDeathMode == TEAMZERO or teamDeathMode == COMMANDER then
					KillTeamsZeroUnits()
				elseif teamDeathMode == ALLYZERO or teamDeathMode == TEAMCOMENDS then
					KillAllyTeamsZeroUnits()
				end
				KillResignedTeams()
			end
		end
		
		if voteStartFrame and frame > voteStartFrame then
			if not votingStarted then
				if voteForEnd then
					Spring.SetGameRulesParam("VoteForEnd",1)
					votingStarted = true
					 voteForDraw = false
					 Spring.SetGameRulesParam("VoteForDraw",0)
				elseif voteForDraw then
					Spring.SetGameRulesParam("VoteForDraw",1)
					votingStarted = true
					voteForEnd = false
					Spring.SetGameRulesParam("VoteForEnd",0)
				else
					EndVoting()
				end
			else
				if (frame%30) == 0 then
					local timeRemaining = VOTETIME*30 - (frame - voteStartFrame)
					Spring.SetGameRulesParam("VoteTime",timeRemaining)
					
					if timeRemaining <= 0 then 
						if voteForEnd then
							local voteY,voteN,voteA = GetVotes(votingAllyID)
							
							if voteY > 0 and voteN == 0 then -- nobody votes No and someone votes Yes
								gamewinners = {votingAllyID}
								GG.gamewinners = gamewinners
								gameoverframe = frame + GAMEOVERDELAY
							else
								Echo("Vote failed: you may call another vote by clicking the white flag" )
							end
							ResetVotes(votingAllyID)
							EndVoting()
						elseif voteForDraw then
							local voteY,voteN,voteA = GetVotesForDraw()
							if voteY > 0 and voteN == 0 and voteA == 0 then -- everyone votes yes
								gamewinners = {}
								GG.gamewinners = {}
								gameoverframe = frame + GAMEOVERDELAY
								EndVoting()
							else
								Echo("Vote failed. Go kill each other!")
								ResetVotesForDraw()
								EndVoting()
							end
						end
							
					else -- vote time left
						if voteForEnd then
							local voteY,voteN,voteA = GetVotes(votingAllyID)						
							if voteY > 0 and voteN == 0 and voteA == 0 then -- everyone votes yes
								gamewinners = {votingAllyID}
								GG.gamewinners = gamewinners
								gameoverframe = frame + GAMEOVERDELAY
								EndVoting()
							elseif voteY == 0 and voteN > 0 and voteA == 0 then -- everyone votes no
								Echo("Vote failed: you may call another vote by clicking the white flag" )
								ResetVotes(votingAllyID)
								EndVoting()
							end
						elseif voteForDraw then
							local voteY,voteN,voteA = GetVotesForDraw()
							if voteY > 0 and voteN == 0 and voteA == 0 then -- everyone votes yes
								gamewinners = {}
								GG.gamewinners = {}
								gameoverframe = frame + GAMEOVERDELAY
								EndVoting()
							elseif voteY == 0 and voteN > 0 and voteA == 0 then -- everyone votes no
								Echo("Vote failed. Go kill each other!")
								ResetVotesForDraw()
								EndVoting()
							end							
						end
					end
				end
			end
		end
	end

	function gadget:TeamDied(teamID)
		
		local teamUnitCount = teamsUnitCount[teamID] or 0
		teamsUnitCount[teamID] = nil
		
		local allyTeamID = teamToAllyTeam[teamID]
		local aliveTeamCount = allyTeamAliveTeamsCount[allyTeamID]
		if aliveTeamCount then
			aliveTeamCount = aliveTeamCount - 1
			allyTeamAliveTeamsCount[allyTeamID] = aliveTeamCount
			
			
			
			-- teams can die with units alive	
			local allyUnitCount = allyTeamUnitCount[allyTeamID] or 0
			allyUnitCount = allyUnitCount - teamUnitCount
			allyTeamUnitCount[allyTeamID] = allyUnitCount
			
			if aliveTeamCount <= 0 then
				-- one allyteam just died
				aliveAllyTeamCount = aliveAllyTeamCount - 1
				allyTeamUnitCount[allyTeamID] = nil
				killedAllyTeams[allyTeamID] = true
			end
		end
	end

	function gadget:Initialize()
		gadgetHandler:AddChatAction('voteforend', CallEndVote, "Call vote to accept surrender")
		gadgetHandler:AddChatAction('votefordraw', CallDrawVote, "Call vote to draw the game")
		if teamDeathMode == "none" then
			gadgetHandler:RemoveGadget()
		end
		
		gaiaAllyTeamID = select(6, GetTeamInfo(gaiaTeamID))
		-- at start, fill in the table of all alive allyteams
		for _,allyTeamID in ipairs(allyTeams) do
			local teamList = GetTeamList(allyTeamID)
			local teamCount = 0

			for _,teamID in ipairs(teamList) do
				teamToAllyTeam[teamID] = allyTeamID
				if (ignoreGaia == 0) or (teamID ~= gaiaTeamID) then
					teamCount = teamCount + 1
				end
			end
			
			allyTeamAliveTeamsCount[allyTeamID] = teamCount
			
			if teamCount > 0 then
				 aliveAllyTeamCount = aliveAllyTeamCount + 1
			end
		end

	end
	
	function gadget:Shutdown()
		gadgetHandler:RemoveChatAction('voteforend')
		gadgetHandler:RemoveChatAction('votefordraw')
	end

	function gadget:UnitCreated(unitID, unitDefID, unitTeamID)
	
		local _,_,isTeamDead = GetTeamInfo(unitTeamID)
		
		if not isTeamDead then
			local teamUnitCount = teamsUnitCount[unitTeamID] or 0
			teamUnitCount = teamUnitCount + 1
			teamsUnitCount[unitTeamID] = teamUnitCount
			local allyTeamID = teamToAllyTeam[unitTeamID]
			local allyUnitCount = allyTeamUnitCount[allyTeamID] or 0
			allyUnitCount = allyUnitCount + 1
			allyTeamUnitCount[allyTeamID] = allyUnitCount		
		end
	end

	gadget.UnitGiven = gadget.UnitCreated
	gadget.UnitCaptured = gadget.UnitCreated

	function gadget:UnitDestroyed(unitID, unitDefID, unitTeamID)
		if unitTeamID == gaiaTeamID and ignoreGaia ~= 0 then
			-- skip gaia
			return
		end
		
		local _,_,isTeamDead = GetTeamInfo(unitTeamID)
		if not isTeamDead then
			local teamUnitCount = teamsUnitCount[unitTeamID]
			if teamUnitCount then
				teamUnitCount = teamUnitCount - 1
				teamsUnitCount[unitTeamID] = teamUnitCount
			end
			local allyTeamID = teamToAllyTeam[unitTeamID]
			local allyUnitCount = allyTeamUnitCount[allyTeamID]
			if allyUnitCount then
				allyUnitCount = allyUnitCount - 1
				allyTeamUnitCount[allyTeamID] = allyUnitCount
			end
		end
	end

	gadget.UnitTaken = gadget.UnitDestroyed
	
	function CallEndVote()
		-- needs spec-check
		if not voteForEnd and not voteForDraw then
			Echo("Calling vote on accepting enemy surrender...")
			local aliveCount,controlledCount,winningTeam = GetControlledAllyTeams()
			--Echo("Alive teams:",aliveCount,"Controlled:",controlledCount,"Winner:",winningTeam or "no-one")
						
			if winningTeam then
				voteForEnd = true
				if not voteStartFrame then
					voteStartFrame = Spring.GetGameFrame()
				end
				Spring.SetGameRulesParam("VoteForEnd",1)
				votingAllyID = winningTeam
				hideVoting = false
				Spring.SetGameRulesParam("VotingAllyID",votingAllyID)
				
				voteForDraw = false
				Spring.SetGameRulesParam("VoteForDraw",0)
			else
				Echo("You adversaries do not surrender. Go kill them!")
			end
		else
			Echo("A vote is already in progress")
		end
	end
	
	function CallDrawVote()
		-- needs spec-check
		if not voteForEnd and not voteForDraw then
			Echo("Calling vote to agree to truce...")
			votingDrawTable = Spring.GetPlayerList(-1,true)
			votingDrawPlayers = {}
			for _, playerID in ipairs (votingDrawTable) do
				votingDrawPlayers[playerID] = true
			end
			
			if #votingDrawTable > 1 then
				voteForDraw = true
				Spring.SetGameRulesParam("VoteForDraw",1)
				if not voteStartFrame then
					voteStartFrame = Spring.GetGameFrame()
				end
				
				voteForEnd = false
				Spring.SetGameRulesParam("VoteForEnd",0)
			else
				Echo("There is no response... (the AI will not draw)")
			end
		else
			Echo("A vote is already in progress")
		end
	end
	
	function gadget:RecvLuaMsg(msg, playerID)
		
		if msg:sub(1,VOTEMSGSIZE) ~= VOTEMSG then --invalid message
			return
		end

		local vote  = tonumber(msg:match(voteRegex))
		local _, _, playerIsSpec, teamID, allyID = GetPlayerInfo(playerID)
		local _,_,isDead,isAI 	= GetTeamInfo(teamID)
		
		if votingAllyID and votingAllyID == allyID and not playerIsSpec then
			if vote == 1 or vote == 0 then
				Spring.SetTeamRulesParam(teamID,"Vote", vote)
			elseif vote == 9 then
				CallEndVote()
			end
			return true
		elseif teamID and not isDead and not playerIsSpec and votingDrawPlayers[playerID] then
			if vote == 3 or vote == 4 then
				Spring.SetTeamRulesParam(teamID,"DrawVote", vote)
			end
		end
	end
		
else
	---------------
-- UNSYNCED PART -- Handles voting in case there are abandoned teams
	---------------
		
	local myTeamID				= Spring.GetMyTeamID()
	local myAllyID				= Spring.GetMyAllyTeamID()
	local GetTeamList 			= Spring.GetTeamList
	local GetTeamInfo 			= Spring.GetTeamInfo
	local GetPlayerList			= Spring.GetPlayerList
	local GetPlayerInfo			= Spring.GetPlayerInfo
	local Window				= {}
	local Button				= {}
	local windowH				= 260
	local windowW				= 450
	local vsx, vsy 			= gl.GetViewSizes()
	local posx					= vsx/2 - windowW/2
	local posy					= vsy/2 - windowH/2
	local voteForEnd			= false
	local voteForDraw			= false
	local userHasVoted			= false
	local voteTime				= nil
	local votingAllyID			= nil
	local votingCountDown		= nil
	local myFont				= gl.LoadFont("FreeSansBold.otf",14, 1.9, 40)
	local SendLuaRulesMsg		= Spring.SendLuaRulesMsg
	local VOTEMSG				= '\174'
	local votersList			= nil
	local n						= 0
	local vbx,vby				= vsx - 30,vsy - 30
	local imgFlag				= "LuaUI/Images/whiteflag.png"
	local spectator 			= Spring.GetSpectatingState()
	local isReplay				= Spring.IsReplay()
	local hideVoting			= false
	local playedVoteSound		= false
	 
	local function SetUpButtons()
		if votersList then n = #votersList or 0 end
		
		Window["voting"]["x0"]		= posx
		Window["voting"]["x1"]		= posx + windowW
		Window["voting"]["y0"]		= posy
		Window["voting"]["y1"]		= posy + windowH + n * 20
		
		Window["voteinfo"]["x0"]	= posx + 5
		Window["voteinfo"]["x1"]	= posx + windowW - 5
		Window["voteinfo"]["y0"]	= posy + 75
		Window["voteinfo"]["y1"]	= Window["voting"]["y1"]-120
		
		Button["yes"]["x0"]			= posx + 160
		Button["yes"]["x1"]			= posx + 205
		Button["yes"]["y0"]			= posy + 10
		Button["yes"]["y1"]			= posy + 40
		Button["yes"]["mouse"]		= false
		 
		Button["no"]["x0"]			= posx + 245
		Button["no"]["x1"]			= posx + 290
		Button["no"]["y0"]			= posy + 10
		Button["no"]["y1"]			= posy + 40
		Button["no"]["mouse"]		= false
		
		Button["exit"]["x0"]		= Window["voting"]["x1"] - 30
		Button["exit"]["x1"]		= Window["voting"]["x1"]
		Button["exit"]["y0"]		= Window["voting"]["y1"] - 30
		Button["exit"]["y1"]		= Window["voting"]["y1"]
		Button["exit"]["mouse"]		= false
		
		Button["flag"]["x0"]		= vbx
		Button["flag"]["x1"]		= vbx + 30
		Button["flag"]["y0"]		= vby
		Button["flag"]["y1"]		= vby + 30
		Button["flag"]["mouse"]		= false
		
	 end
	 
	local function IsOnButton(x, y, BLcornerX, BLcornerY,TRcornerX,TRcornerY)
		if BLcornerX == nil then return false end
		-- check if the mouse is in a rectangle

		return x >= BLcornerX and x <= TRcornerX
							  and y >= BLcornerY
							  and y <= TRcornerY
	end
	 
	local function round(num, idp)
		return string.format("%." .. (idp or 0) .. "f", num)
	end
	
	local function drawBorder(x0, y0, x1, y1, width)
		gl.Rect(x0, y0, x1, y0 + width)
		gl.Rect(x0, y1, x1, y1 - width)
		gl.Rect(x0, y0, x0 + width, y1)
		gl.Rect(x1, y0, x1 - width, y1)
	end
	
	function gadget:Initialize()
		Window["voting"]	= {}
		Window["voteinfo"]	= {}
		Button["yes"]		= {}
		Button["no"]		= {}
		Button["flag"]		= {}
		Button["exit"]		= {}
		SetUpButtons()
	 end
	 
	function gadget:Update()
		voteForEnd = Spring.GetGameRulesParam("VoteForEnd") == 1
		voteForDraw = Spring.GetGameRulesParam("VoteForDraw") == 1
		
		if (voteForEnd or voteForDraw) and (votetime == nil or votetime == 0) and not playedVoteSound then
			Spring.PlaySoundFile("sounds/beep1.wav",3.0,0,0,0,0,0,0,'userinterface')
			playedVoteSound = true
		end
		
		if voteForEnd or voteForDraw then
			votetime = Spring.GetGameRulesParam("VoteTime")
			if votetime and votetime > 0 then
				votingAllyID = Spring.GetGameRulesParam("VotingAllyID")
				votingCountDown = table.concat({tostring(round(votetime/30,0))," s"})
			end
		else
			votetime = 0
			playedVoteSound = false
		end	
	 end
	 
	function gadget:DrawScreen()
		if (not Spring.IsGUIHidden()) and not Spring.IsGameOver() then
			if (voteForEnd or voteForDraw) and not hideVoting then
				if votetime and votetime > 0 then										
					if (votingAllyID and votingAllyID >= 0) or voteForDraw then
						if not votersList then
							if voteForEnd then
								votersList = GetTeamList(votingAllyID)
							else
								votersList = GetPlayerList(-1,true)
							end
							SetUpButtons()
						end
					
						-- window
						gl.Color(0.3, 0.3, 0.4, 0.4) -- grey
						gl.Rect(Window["voting"]["x0"],Window["voting"]["y0"],Window["voting"]["x1"],Window["voting"]["y1"])
						
						-- voteinfo-window
						gl.Color(0.6, 0.6, 0.6, 0.6) -- greyer
						gl.Rect(Window["voteinfo"]["x0"],Window["voteinfo"]["y0"],Window["voteinfo"]["x1"],Window["voteinfo"]["y1"])
						--border
						gl.Color(0.3, 0.3, 0.3, 0.8) -- black
						drawBorder(Window["voteinfo"]["x0"],Window["voteinfo"]["y0"],Window["voteinfo"]["x1"],Window["voteinfo"]["y1"],1)
												
						if not userHasVoted and not isReplay and not spectator then
							--yes button 
							if Button["yes"]["mouse"] then
								gl.Color(0.8, 0.8, 0.2, 0.5) -- yellow on mouseover
							else
								gl.Color(0.3, 0.3, 0.4, 0.55) -- grey
							end
							gl.Rect(Button["yes"]["x0"],Button["yes"]["y0"],Button["yes"]["x1"],Button["yes"]["y1"])	
							
							--no button 
							if Button["no"]["mouse"] then
								gl.Color(0.8, 0.8, 0.2, 0.5) -- yellow on mouseover
							else
								gl.Color(0.3, 0.3, 0.4, 0.55) -- grey
							end
							gl.Rect(Button["no"]["x0"],Button["no"]["y0"],Button["no"]["x1"],Button["no"]["y1"])
							gl.Color(1, 1, 1, 1)
						end
						
						-- exit button
						if Button["exit"]["mouse"] then
							gl.Color(0.8, 0.8, 0.2, 0.5) -- yellow on mouseover
						else
							gl.Color(0.3, 0.3, 0.4, 0.55) -- grey
						end
						gl.Rect(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"])
						
						gl.Color(0, 0, 0, 1)
						drawBorder(Button["exit"]["x0"],Button["exit"]["y0"], Button["exit"]["x1"], Button["exit"]["y1"],1)
						gl.Color(1, 1, 1, 1)
						myFont:Begin()
						myFont:SetTextColor({1, 1, 1, 1})
						myFont:Print("X", Button["exit"]["x0"] + 10 ,Button["exit"]["y0"] + 10, 20, 'xs')
						myFont:End()
						
						local label_1,label_2,label_3
						if voteForEnd then
							label_1 = "Sir, all enemy commanders have deserted their ranks"
							label_2 = "and the remaining units wish to surrender. "
							label_3 = "Do you wish to accept and end the game now?"
						else
							label_1 = "Do you agree to mutually end this game and call"
							label_2 = "it a draw?"
							label_3 = "(This will only succeed if *everyone* votes yes)"
						end
						--text
						myFont:Begin()
						myFont:SetTextColor({1, 1, 1, 1.0}) -- was ({0.8, 0.8, 0.4, 1.0}) yellow
						myFont:Print(label_1,Window["voting"]["x0"]+10,Window["voting"]["y1"]-30,14,'bs')
						myFont:Print(label_2,Window["voting"]["x0"]+10,Window["voting"]["y1"]-50,14,'bs')
						myFont:Print(label_3,Window["voting"]["x0"]+10,Window["voting"]["y1"]-85,14,'bs')
						myFont:Print(votingCountDown,Window["voting"]["x1"]-10,Window["voting"]["y0"]+10,14,'rbs')
						
						myFont:SetTextColor({0.8, 0.8, 0.8, 1.0})
						myFont:Print("Player",Window["voteinfo"]["x0"]+20,Window["voteinfo"]["y1"]-15,11,'bs')
						myFont:Print("Vote",Window["voteinfo"]["x1"]-20,Window["voteinfo"]["y1"]-15,11,'rbs')						
						
						for i,listID in pairs (votersList) do
							local tID, leaderID, isAI, leaderName, spectator
							if voteForEnd then
								tID = listID
								_,leaderID,_,isAI = GetTeamInfo(tID)
								spectator = false
							else
								leaderID = listID
								isAI = false
								_,_,spectator,tID = GetPlayerInfo(leaderID)
							end
							if not spectator then
								if leaderID then
									if isAI then
										leaderName = "AI"
									else
										leaderName = GetPlayerInfo(leaderID) or "N/A"
									end
								else
									leaderName = "N/A"
								end
								myFont:SetTextColor({1, 1, 1, 1.0})
								myFont:Print(leaderName,Window["voteinfo"]["x0"]+20,Window["voteinfo"]["y1"]-15-20*i,11,'bo')
								local vote
								
								if voteForEnd then
									vote = Spring.GetTeamRulesParam(tID, "Vote") or 2 -- abstain
								else
									vote = Spring.GetTeamRulesParam(tID, "DrawVote") or 2 -- abstain
								end
								
								local voteStr
								if vote == 0 or vote == 3 then
									voteStr = "Nay"
									myFont:SetTextColor({0.8, 0.2, 0.2, 1}) -- red
								elseif vote == 1 or vote == 4 then
									voteStr = "Yea"
									myFont:SetTextColor({0.2, 0.8, 0.2, 1}) -- green
								else
									voteStr = "Abstain"
									myFont:SetTextColor({0.8, 0.8, 0.8, 0.2}) -- grey
								end
								myFont:Print(voteStr,Window["voteinfo"]["x1"]-20,Window["voteinfo"]["y1"]-15-20*i,11,'rbo')
							end
						end
						myFont:SetTextColor({1, 1, 1, 1.0})
						if not userHasVoted and not isReplay and not spectator then
							myFont:Print("Yes",(Button["yes"]["x0"]+Button["yes"]["x1"])/2,Button["yes"]["y0"]+3,14,'cds')
							myFont:Print("No",(Button["no"]["x0"]+Button["no"]["x1"])/2,Button["no"]["y0"]+3,14,'cds')
						end
						myFont:End()
					end
				else
					voteForEnd = false
					userHasVoted = false
					votersList = nil
					hideVoting = false
				end
			else
				if (not votetime) or votetime <= 0 then
					hideVoting = false
				end
				userHasVoted = false
				votersList = nil
				if votingAllyID and votingAllyID >= 0 then
					--white flag button 
					if Button["flag"]["mouse"] then
						gl.Color(0.8, 0.8, 0.2, 1) -- yellow on mouseover
					else
						gl.Color(0.9, 0.9, 0.9, 1) -- grey
					end
					gl.Texture(imgFlag)
					gl.TexRect(Button["flag"]["x0"],Button["flag"]["y0"],Button["flag"]["x1"],Button["flag"]["y1"])	
					gl.Texture(false)
					gl.Color(1, 1, 1, 1) -- grey
				end
			end
		end
	 end
	 
	function gadget:MousePress(mx, my, mButton)
		if (not Spring.IsGUIHidden()) then
			if mButton == 1 then			
				if IsOnButton(mx,my,Window["voting"]["x0"],Window["voting"]["y0"],Window["voting"]["x1"],Window["voting"]["y1"]) then				
					if (voteForEnd or voteForDraw) then
						if IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
							hideVoting = true
						end
						if not spectator and not isReplay and not userHasVoted then
							if IsOnButton(mx,my,Button["yes"]["x0"],Button["yes"]["y0"],Button["yes"]["x1"],Button["yes"]["y1"]) then
								userHasVoted = true
								if voteForEnd then
									SendLuaRulesMsg(table.concat({VOTEMSG,1}))
								elseif voteForDraw then
									SendLuaRulesMsg(table.concat({VOTEMSG,4}))
								end
							elseif IsOnButton(mx,my,Button["no"]["x0"],Button["no"]["y0"],Button["no"]["x1"],Button["no"]["y1"]) then
								userHasVoted = true
								if voteForEnd then
									SendLuaRulesMsg(table.concat({VOTEMSG,0}))
								elseif voteForDraw then
									SendLuaRulesMsg(table.concat({VOTEMSG,3}))
								end
							end
						end
					elseif not spectator and not isReplay and not userHasVoted then
						if IsOnButton(mx,my,Button["flag"]["x0"],Button["flag"]["y0"],Button["flag"]["x1"],Button["flag"]["y1"]) then
							SendLuaRulesMsg(table.concat({VOTEMSG,9}))
						end
					end
				end
			elseif mButton == 2 or mButton == 3 then
				if (voteForEnd or voteForDraw) then
					if IsOnButton(mx,my,Window["voting"]["x0"],Window["voting"]["y0"],Window["voting"]["x1"],Window["voting"]["y1"]) then
						-- At least smooth scroll widget interferes with this: it steals mouse ownership
						-- Dragging
						return true
					end
				end
			end
		end
		return false
	end
	
	function gadget:MouseRelease(mx, my, mButton)
		return false
	end
	
	function gadget:MouseMove(mx, my, dx, dy, mButton)
		if (not Spring.IsGUIHidden()) and (voteForEnd or voteForDraw) and not userHasVoted then
			-- Dragging
			if mButton == 2 or mButton == 3 then
				posx = math.max(0, math.min(posx+dx, vsx-windowW))	--prevent moving off screen
				posy = math.max(0, math.min(posy+dy, vsy-windowH))
			end
			SetUpButtons()
		end
		return false
	end
	
	function gadget:IsAbove(mx,my)
		if (not Spring.IsGUIHidden()) then
			Button["yes"]["mouse"] = false
			Button["no"]["mouse"] = false
			Button["flag"]["mouse"] = false
			Button["exit"]["mouse"] = false			
			
			if IsOnButton(mx,my,Button["exit"]["x0"],Button["exit"]["y0"],Button["exit"]["x1"],Button["exit"]["y1"]) then
				Button["exit"]["mouse"] = true
			end
			
			if not userHasVoted then
				if not spectator and not isReplay then
					if (voteForEnd or voteForDraw) then
						if IsOnButton(mx,my,Button["yes"]["x0"],Button["yes"]["y0"],Button["yes"]["x1"],Button["yes"]["y1"]) then
							Button["yes"]["mouse"] = true
						elseif IsOnButton(mx,my,Button["no"]["x0"],Button["no"]["y0"],Button["no"]["x1"],Button["no"]["y1"]) then
							Button["no"]["mouse"] = true
						end
					elseif not voteForEnd then
						if IsOnButton(mx,my,Button["flag"]["x0"],Button["flag"]["y0"],Button["flag"]["x1"],Button["flag"]["y1"]) then
							Button["flag"]["mouse"] = true
						end
					end
				end	
			end
		end
	end

end
