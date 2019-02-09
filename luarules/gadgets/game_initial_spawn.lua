
function gadget:GetInfo()
    return {
        name      = 'Initial Spawn',
        desc      = 'Handles initial spawning of units',
        author    = 'Niobium',
        version   = 'v1.0',
        date      = 'April 2011',
        license   = 'GNU GPL, v2 or later',
        layer     = 0,
        enabled   = true
    }
end

----------------------------------------------------------------
-- Synced only
----------------------------------------------------------------
--if not gadgetHandler:IsSyncedCode() then
--   return false
--end
if gadgetHandler:IsSyncedCode() then

----------------------------------------------------------------
-- Config
----------------------------------------------------------------
local changeStartUnitRegex = '^\177(%d+)$'

----------------------------------------------------------------
-- Var
----------------------------------------------------------------
local armcomDefID = UnitDefNames.arm_commander.id
local corcomDefID = UnitDefNames.core_commander.id
local lostcomDefID = UnitDefNames.lost_commander.id
local guardiancomDefID = UnitDefNames.guardian_commander.id
local taloncomDefID = UnitDefNames.talon_commander.id

local isTLL	= false
local isGOK	= false
local isTAL	= false

local validStartUnits = {
	[UnitDefNames.arm_commander.id] = true,
	[UnitDefNames.arm_u0commander.id] = true,
	[UnitDefNames.core_commander.id] = true,
	[UnitDefNames.core_u0commander.id] = true,
   }	
local spawnTeams = {} -- spawnTeams[teamID] = allyID

local modOptions = Spring.GetModOptions() or {}
local comStorage = true
-- if ((modOptions.mo_storageowner) and (modOptions.mo_storageowner == "com")) then
  -- comStorage = true
-- end
local startMetal  = tonumber(modOptions.startmetal)  or 1000
local startEnergy = tonumber(modOptions.startenergy) or 1000

----------------------------------------------------------------
-- Speedups
----------------------------------------------------------------
local spGetPlayerInfo 				= Spring.GetPlayerInfo
local spGetTeamInfo 				= Spring.GetTeamInfo
local spGetTeamRulesParam 			= Spring.GetTeamRulesParam
local spSetTeamRulesParam 			= Spring.SetTeamRulesParam
local spGetTeamStartPosition 		= Spring.GetTeamStartPosition
local spGetAllyTeamStartBox 		= Spring.GetAllyTeamStartBox
local spCreateUnit 					= Spring.CreateUnit
local spGetGroundHeight 			= Spring.GetGroundHeight
local Echo 							= Spring.Echo

----------------------------------------------------------------
-- Callins
----------------------------------------------------------------
function gadget:Initialize()
    local gaiaTeamID = Spring.GetGaiaTeamID()
    local teamList = Spring.GetTeamList()
	if (Spring.GetModOptions() or {}).commander ~= 'choose' then
		gadgetHandler:RemoveGadget(self) 
		return
	end
	
    for i = 1, #teamList do
        local teamID = teamList[i]
        if teamID ~= gaiaTeamID then
            local _, _, _, _, teamSide, teamAllyID = spGetTeamInfo(teamID)
            if teamSide == 'core' then
                spSetTeamRulesParam(teamID, 'startUnit', corcomDefID)
            elseif teamSide == 'arm' then
                spSetTeamRulesParam(teamID, 'startUnit', armcomDefID)
			elseif teamSide == 'lost' then
				spSetTeamRulesParam(teamID, 'startUnit', lostcomDefID)
			--elseif teamSide == 'guardian' then
				--spSetTeamRulesParam(teamID, 'startUnit', guardiancomDefID)
			--elseif teamSide == 'talon' then
				--spSetTeamRulesParam(teamID, 'startUnit', taloncomDefID)
            end
            spawnTeams[teamID] = teamAllyID
        end
    end
	
	-- mark all players as not placed
	local initState = (Game.startPosType ~= 2 and -1) or 0
	local playerList = Spring.GetPlayerList()
	for _,playerID in pairs(playerList) do
		Spring.SetGameRulesParam("player_" .. playerID .. "_readyState" , initState)
	end
	isTLL = tonumber( (Spring.GetModOptions() or {}).tllunits) == 1
	isGOK = tonumber( (Spring.GetModOptions() or {}).gokunits) == 1
	isTAL = tonumber( (Spring.GetModOptions() or {}).talonunits) == 1
	
	if isTLL then
		validStartUnits[UnitDefNames.lost_commander.id] = true
		validStartUnits[UnitDefNames.lost_u0commander.id] = true
	end
	
	if isGOK then
		validStartUnits[UnitDefNames.guardian_commander.id] = true
		validStartUnits[UnitDefNames.guardian_u0commander.id] = true
	end
	
	if isTAL then
		validStartUnits[UnitDefNames.talon_commander.id] = true
		validStartUnits[UnitDefNames.talon_u0commander.id] = true
	end
	
end

function gadget:GameStart()
	-- needed for voting
	--gadgetHandler:RemoveCallIn("RecvLuaMsg")	
end

----------------------------------------------------------------
-- Startpoints
----------------------------------------------------------------

function gadget:AllowStartPosition(playerID,teamID,readyState,x,y,z)
	-- readyState:
	-- 0: player did not place startpoint, is unready
	-- 1: game starting, player is ready
	-- 2: player pressed ready OR game is starting and player is forcibly readied (note: if the player chose a startpoint, reconnected and pressed ready without re-placing, this case will have the wrong x,z)
	-- 3: game forcestarted & player absent

	-- we also add the following
	-- -1: players will not be allowed to place startpoints; automatically readied once ingame
	--  4: player has placed a startpoint but is not yet ready

	-- communicate readyState to all
	Spring.SetGameRulesParam("player_" .. playerID .. "_readyState" , readyState)

	--[[
	-- for debugging
	local name,_,_,tID = Spring.GetPlayerInfo(playerID)
	Spring.Echo(name,tID,x,z,readyState, (startPointTable[tID]~=nil))
	Spring.MarkerAddPoint(x,y,z,name .. " " .. readyState)
	]]

	if Game.startPosType ~= 2 then return true end -- accept blindly unless we are in choose-in-game mode
	--if useFFAStartPoints then return true end

	local _,_,_,teamID,allyTeamID,_,_,_,_,_ = Spring.GetPlayerInfo(playerID)
	if not teamID or not allyTeamID then return false end --fail

	-- don't allow player to place startpoint unless its inside the startbox, if we have a startbox
	if allyTeamID == nil then return false end
	local xmin, zmin, xmax, zmax = spGetAllyTeamStartBox(allyTeamID)
	if xmin>=xmax or zmin>=zmax then
		return true
	else
		local isOutsideStartbox = (xmin+1 >= x) or (x >= xmax-1) or (zmin+1 >= z) or (z >= zmax-1) -- the engine rounds startpoints to integers but does not round the startbox (wtf)
		if isOutsideStartbox then
			return false
		end
	end


	-- record table of starting points for startpoint assist to use
	if readyState == 2 then
		-- player pressed ready (we have already recorded their startpoint when they placed it) OR game was force started and player is forcibly readied
		--if not startPointTable[teamID] then
		--	startPointTable[teamID]={-5000,-5000} -- if the player was forcibly readied without having placed a startpoint, place an invalid one far away (thats what the StartPointGuesser wants)
		--end
	else
		-- player placed startpoint OR game is starting and player is ready
		--startPointTable[teamID]={x,z}
		if readyState ~= 1 then
			-- game is not starting (therefore, player cannot yet have pressed ready)
			Spring.SetGameRulesParam("player_" .. playerID .. "_readyState" , 4)
			SendToUnsynced("StartPointChosen", playerID)
		end
	end

	return true
end

function gadget:RecvLuaMsg(msg, playerID)
	local STATEMSG = "181072"
	local COMMMSG = "\177"
	local AIMSG = "231689123"
		
	if msg:sub(1,#STATEMSG) == STATEMSG then
		local sms = string.sub(msg, string.len(STATEMSG)+1) 
		local state = tonumber(string.sub(sms,1,1))			
		local playerIDMsg = tonumber(string.sub(sms,2))
		
		if playerIDMsg then -- player id is included in message and needs to be used if this was sent from gadget
			if state == 0 then
				Spring.SetGameRulesParam("player_" .. playerIDMsg .. "_readyState" , 0)
			elseif state == 1 then
				-- set state to marked if previous state = unready
				local prevState = Spring.GetGameRulesParam("player_" .. playerIDMsg .. "_readyState")
				if prevState == 0 then
					Spring.SetGameRulesParam("player_" .. playerIDMsg .. "_readyState" , 4)
				end
			end
		end
	elseif msg:sub(1,#COMMMSG) == COMMMSG then
		local startUnit = tonumber(msg:match(changeStartUnitRegex))
		--Spring.Echo("Got msg with startUnit = ", startUnit,validStartUnits[startUnit])
		if startUnit and validStartUnits[startUnit] then	
			local localName, _, playerIsSpec, playerTeam = spGetPlayerInfo(playerID)
			if not playerIsSpec then
				spSetTeamRulesParam(playerTeam, 'startUnit', startUnit,{public=true})
				--Spring.Echo("Set team start unit to:",playerTeam,startUnit)
				return true
			end
		end
	elseif msg:sub(1,#AIMSG) == AIMSG then
		local sms = msg:sub(#(AIMSG)+1)
		local separationInd = sms:find(":")
				
		if not separationInd then return end
		
		local teamID = tonumber(sms:sub(1,separationInd-1))
		local shortName = tostring(sms:sub(separationInd+1))
				
		Spring.SetGameRulesParam("AI-Name"..teamID,shortName) 
	end
end

--		gl.PushMatrix()
--			gl.Translate(readyX+(readyW/2),readyY+(readyH/2),0)
--			gl.Scale(uiScale, uiScale, 1)

			if not readied and readyButton and Game.startPosType == 2 and gameStarting==nil and not spec and not isReplay then
			--if not readied and readyButton and not spec and not isReplay then

				-- draw ready button and text
				local x,y = Spring.GetMouseState()
				x,y = correctMouseForScaling(x,y)
				if x > readyX-bgMargin and x < readyX+readyW+bgMargin and y > readyY-bgMargin and y < readyY+readyH+bgMargin then
					gl.CallList(readyButtonHover)
					colorString = "\255\255\222\0"
				else
					gl.CallList(readyButton)
			  		timer2 = timer2 + Spring.GetLastUpdateSeconds()
					if timer2 % 0.75 <= 0.375 then
						colorString = "\255\233\215\20"
					else
						colorString = "\255\255\255\255"
					end
				end
				gl.Text(colorString .. "Ready", -((readyW/2)-12.5), -((readyH/2)-9.5), 25, "o")
				gl.Color(1,1,1,1)
			end

			if gameStarting and not isReplay then
				timer = timer + Spring.GetLastUpdateSeconds()
				if timer % 0.75 <= 0.375 then
					colorString = "\255\233\233\20"
				else
					colorString = "\255\255\255\255"
				end
				local text = colorString .. "Game starting in " .. math.max(1,3-math.floor(timer)) .. " seconds..."
				gl.Text(text, vsx*0.5 - gl.GetTextWidth(text)/2*17, vsy*0.75, 17, "o")
			end
	--	gl.PopMatrix()

		--remove if after gamestart
		if Spring.GetGameFrame() > 0 then
			gadgetHandler:RemoveGadget(self)
			return
		end

end