
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
if not gadgetHandler:IsSyncedCode() then
    return false
end

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
local isTLL	= false

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
	
	if isTLL then
		validStartUnits[UnitDefNames.lost_commander.id] = true
		validStartUnits[UnitDefNames.lost_u0commander.id] = true
	end
	
end

function gadget:GameStart()
	-- needed for voting
	--gadgetHandler:RemoveCallIn("RecvLuaMsg")	
end

-------------------------------------------------------------------------
-- communicate player ready states (in addition to statebroadcast gadget)
-------------------------------------------------------------------------
function gadget:AllowStartPosition(x,y,z,playerID,readyState)
	-- communicate readyState to all
	-- 0: unready, 1: ready, 2: game forcestarted & player not ready, 3: game forcestarted & player absent
	-- for some reason 2 is sometimes used in place of 1 and is always used for the last player to become ready
	-- we also add (only used in Initialize) the following
	-- -1: players will not be allowed to place startpoints; automatically readied once ingame
	--  4: player has placed a startpoint but is not yet ready == xta marked state (sent from statebroadcast gadget)
	
	if Game.startPosType == 2 then -- choose in game mode
		Spring.SetGameRulesParam("player_" .. playerID .. "_readyState" , readyState)
	end
	
	local _,_,_,teamID,allyTeamID,_,_,_,_,_ = Spring.GetPlayerInfo(playerID)
	if not teamID or not allyTeamID then return false end --fail
	
	return true
end

function gadget:RecvLuaMsg(msg, playerID)
	local STATEMSG = "181072"
	local COMMMSG = "\177"
	
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
				
		if startUnit and validStartUnits[startUnit] then	
			local localName, _, playerIsSpec, playerTeam = spGetPlayerInfo(playerID)
			if not playerIsSpec then
				spSetTeamRulesParam(playerTeam, 'startUnit', startUnit,{public=true})
				return true
			end
		end
	end
end


