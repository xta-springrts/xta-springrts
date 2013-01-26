
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
local startUnitParamName = 'startUnit'

----------------------------------------------------------------
-- Var
----------------------------------------------------------------
local armcomDefID = UnitDefNames.arm_commander.id
local corcomDefID = UnitDefNames.core_commander.id

local sideData = {
	[30] = 'Arm',
	[166] = 'Arm',
	[231] = 'Core',
	[366] = 'Core',
	}

local typeData = {
	[30] = 'A',
	[166] = 'M',
	[231] = 'A',
	[366] = 'M',
	}

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
	end
	
    for i = 1, #teamList do
        local teamID = teamList[i]
        if teamID ~= gaiaTeamID then
            local _, _, _, _, teamSide, teamAllyID = spGetTeamInfo(teamID)
            if teamSide == 'core' then
                spSetTeamRulesParam(teamID, startUnitParamName, corcomDefID)
            else
                spSetTeamRulesParam(teamID, startUnitParamName, armcomDefID)
            end
            spawnTeams[teamID] = teamAllyID
        end
    end
end

if (Spring.GetModOptions() or {}).commander == 'choose' then
    function gadget:RecvLuaMsg(msg, playerID)
        local startUnit = tonumber(msg:match(changeStartUnitRegex))
        if startUnit and validStartUnits[startUnit] then
            local localName, _, playerIsSpec, playerTeam = spGetPlayerInfo(playerID)
            if not playerIsSpec then
                spSetTeamRulesParam(playerTeam, startUnitParamName, startUnit)
				-- Echo(localName .. " chooses " .. sideData[startUnit].." ("..typeData[startUnit]..")")
                return true
            end
        end
    end
end

function gadget:GameStart()
	 gadgetHandler:RemoveCallIn("RecvLuaMsg")	
end
