if (not gadgetHandler:IsSyncedCode()) then
	return false
end

local FIRESTATE_FATW = 2
local MOVESTATE_ROAM = 2

local spGetUnitNeutral = Spring.GetUnitNeutral
local spSetUnitNeutral = Spring.SetUnitNeutral
local spGetGameFrame = Spring.GetGameFrame
local spGetGaiaTeamID = Spring.GetGaiaTeamID
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitBuildFacing = Spring.GetUnitBuildFacing
local spCreateUnit = Spring.CreateUnit
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spEcho = Spring.Echo

local modOptions = Spring.GetModOptions()
local modOptionDefs = VFS.Include("modoptions.lua")

local zombieConf = "LuaRules/Configs/game_zombiemode_defs.lua"
local zombieDefs = VFS.FileExists(zombieConf) and include(zombieConf) or {}
local zombieQueue = {}
local haveZombies = modOptions.zombies or false

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
			end
		end
	end

	if (not haveZombies) then
		spEcho("[game_zombiemode] zombies disabled")
		gadgetHandler:RemoveGadget(self)
		return
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	local isZombie = spGetUnitNeutral(unitID)
	local zombieDef = zombieDefs[unitDefID] or {}
	local canRespawn = zombieDef.canRespawn
	local respawnTime = zombieDef.respawnTime

	if ((isZombie) or (not canRespawn)) then
		return
	end

	zombieQueue[unitID] = {
		defID = unitDefID,
		pos = {spGetUnitPosition(unitID)},
		facing = spGetUnitBuildFacing(unitID),
		frame = spGetGameFrame() + respawnTime
	}
end

function gadget:GameFrame(n)
	for id, spawn in pairs(zombieQueue) do
		if (spawn.frame == n) then
			local unitID = spCreateUnit(spawn.defID, spawn.pos[1], spawn.pos[2], spawn.pos[3], spawn.facing, spGetGaiaTeamID())

			if (unitID ~= nil) then
				spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {[1] = CMD_FIRESTATE_FATW}, {})
				spGiveOrderToUnit(unitID, CMD.MOVE_STATE, {[1] = CMD_MOVESTATE_ROAM}, {})
				spSetUnitNeutral(unitID, true)
			end

			zombieQueue[id] = nil
		end
	end
end

