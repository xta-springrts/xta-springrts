function gadget:GetInfo()
	return {
		name = "Team Com Ends",
		desc = "Implements com ends for allyteams",
		author = "KDR_11k (David Becker)",
		date = "2008-02-04",
		license = "Public domain",
		layer = 1,
		enabled = true
	}
end

-- this acts just like Com Ends except instead of killing a player's units when
-- his com dies it acts on an allyteam level, if all coms in an allyteam are dead
-- the allyteam is out

local commanderList = {
	arm_commander = true,
	arm_decoy_commander = true,
	arm_u0commander = true,
	arm_ucommander = true,
	arm_u2commander = true,
	arm_u3commander = true,
	arm_u4commander = true,
	arm_scommander = true,
	armcom = true,
	arm_base = true,
	arm_nincommander = true,
	core_commander = true,
	core_decoy_commander = true,
	core_u0commander = true,
	core_ucommander = true,
	core_u2commander = true,
	core_u3commander = true,
	core_u4commander = true,
	core_scommander = true,
	corcom = true,
	core_base = true,
	core_nincommander = true,
}

-- the deathmode modoption (called now just "mode") must be set to one of the following to enable this
local endmodes= {
	comcontrol=true,
	commander=true,
	comends=true,
}

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local destroyQueue = {}

local aliveCount = {}

local isAlive = {}

local GetTeamList=Spring.GetTeamList
local GetTeamUnits = Spring.GetTeamUnits
local GetUnitAllyTeam = Spring.GetUnitAllyTeam
local DestroyUnit=Spring.DestroyUnit

function gadget:GameFrame(t)
	if t % 32 < .1 then
		for at,_ in pairs(destroyQueue) do
			if aliveCount[at] <= 0 then --safety check, triggers on transferring the last com otherwise
				for _,team in ipairs(GetTeamList(at)) do
					for _,u in ipairs(GetTeamUnits(team)) do
						DestroyUnit(u, true)
					end
				end
			end
			destroyQueue[t]=nil
		end
	end
end

function gadget:UnitCreated(u, ud, team)
	isAlive[u] = true
	if commanderList[UnitDefs[ud].name] then
		local allyTeam = GetUnitAllyTeam(u)
		aliveCount[allyTeam] = aliveCount[allyTeam] + 1
	end
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	if commanderList[UnitDefs[unitDefID].name] then
		local allyTeam = GetUnitAllyTeam(unitID)
		aliveCount[allyTeam] = aliveCount[allyTeam] + 1
	end
	
end

function gadget:UnitDestroyed(u, ud, team)
	isAlive[u] = nil
	if commanderList[UnitDefs[ud].name] then
		local allyTeam = GetUnitAllyTeam(u)
		aliveCount[allyTeam] = aliveCount[allyTeam] - 1
		if aliveCount[allyTeam] <= 0 then
			destroyQueue[allyTeam] = true
		end
	end
		
	-- implement classic commander ends option
	if Spring.GetModOptions().mode == "commander" then
		if commanderList[UnitDefs[ud].name] then
			for _,u in ipairs(GetTeamUnits(team)) do
				DestroyUnit(u, true)
			end
		end
	end
end

function gadget:UnitTaken(u, ud, team)
	if isAlive[u] and commanderList[UnitDefs[ud].name] then
		local allyTeam = GetUnitAllyTeam(u)
		aliveCount[allyTeam] = aliveCount[allyTeam] - 1
		if aliveCount[allyTeam] <= 0 then
			destroyQueue[allyTeam] = true
		end
	end
end

function gadget:Initialize()
	if not endmodes[Spring.GetModOptions().mode] then
		gadgetHandler:RemoveGadget()
	end
	for _,t in ipairs(Spring.GetAllyTeamList()) do
		aliveCount[t] = 0
	end
end

else

--UNSYNCED

return false

end
