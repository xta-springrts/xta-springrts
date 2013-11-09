function gadget:GetInfo()
	return {
		name    = "game_zombiemode",
		desc    = "handles the 'zombies' modoption",
		author  = "",
		date    = "Okt, 2013",
		license = "Public domain",
		layer   = 0,
		enabled = true
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return false
end

local FIRESTATE_FATW = 2
local MOVESTATE_ROAM = 2

local spGetUnitNeutral     = Spring.GetUnitNeutral
local spSetUnitNeutral     = Spring.SetUnitNeutral
local spGetGameFrame       = Spring.GetGameFrame
local spGetGaiaTeamID      = Spring.GetGaiaTeamID
local spGetUnitPosition    = Spring.GetUnitPosition
local spGetUnitBuildFacing = Spring.GetUnitBuildFacing
local spCreateUnit         = Spring.CreateUnit
local spGiveOrderToUnit    = Spring.GiveOrderToUnit
local spEcho               = Spring.Echo

local modOptions    = Spring.GetModOptions()
local modOptionDefs = VFS.Include("modoptions.lua")

-- "modOptions" is a <string, string> map (values are not numbers!)
local haveZombies = ((modOptions["zombies"] + 0) ~= 0) or false
local zombieConf  = "LuaRules/Configs/game_zombiemode_defs.lua"
local zombieDefs  = VFS.FileExists(zombieConf) and include(zombieConf) or {}
local zombieQueue = {}
local zombieCount = 0

function gadget:Initialize()
	assert(modOptionDefs ~= nil)

	if (modOptions == nil) then
		spEcho("[game_zombiemode] no mod-options")
		gadgetHandler:RemoveGadget(self)
		return
	end

	if (spGetGaiaTeamID() == 0) then
		spEcho("[game_zombiemode] no Gaia-team")
		gadgetHandler:RemoveGadget(self)
		return
	end

	if (not haveZombies) then
		for idx, tbl in ipairs(modOptionDefs) do
			if (tbl.key == "zombies") then
				haveZombies = haveZombies or tbl.def
				break
			end
		end
	end

	if (not haveZombies) then
		spEcho("[game_zombiemode] no zombies no fun")
		gadgetHandler:RemoveGadget(self)
		return
	end
end

-- TODO:
--   dgun should not trigger respawn? (config)
--   reclaiming should NOT EVER trigger respawn
--   nanoframe decay should NOT EVER trigger respawn
function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	local isZombie = spGetUnitNeutral(unitID)
	local zombieDef = zombieDefs[unitDefID] or {}
	local canRespawn = zombieDef.canRespawn
	local respawnTime = zombieDef.respawnTime

	if ((isZombie) or (not canRespawn)) then
		return
	end
	if (attackerTeam ~= nil and attackerTeam == unitTeam) then
		return
	end

	zombieCount = zombieCount + 1
	zombieQueue[zombieCount] = {
		id     = unitID,
		defID  = unitDefID,
		pos    = {spGetUnitPosition(unitID)},
		facing = spGetUnitBuildFacing(unitID),
		frame  = spGetGameFrame() + respawnTime
	}
end

function gadget:GameFrame(n)
	for index, spawn in pairs(zombieQueue) do
		if (spawn.frame == n) then
			local unitID = spCreateUnit(spawn.defID, spawn.pos[1], spawn.pos[2], spawn.pos[3], spawn.facing, spGetGaiaTeamID())

			if (unitID ~= nil) then
				spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {[1] = CMD_FIRESTATE_FATW}, {})
				spGiveOrderToUnit(unitID, CMD.MOVE_STATE, {[1] = CMD_MOVESTATE_ROAM}, {})
				spSetUnitNeutral(unitID, true)
			end

			zombieQueue[index] = nil
		end
	end
end

