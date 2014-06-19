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

local spGetUnitNeutral         = Spring.GetUnitNeutral
local spSetUnitNeutral         = Spring.SetUnitNeutral
local spGetGameFrame           = Spring.GetGameFrame
local spGetUnitPosition        = Spring.GetUnitPosition
local spGetUnitDirection       = Spring.GetUnitDirection
local spGetUnitBuildFacing     = Spring.GetUnitBuildFacing
local spGetFeaturesInRectangle = Spring.GetFeaturesInRectangle
local spCreateUnit             = Spring.CreateUnit
local spDestroyFeature         = Spring.DestroyFeature
local spTestMoveOrder          = Spring.TestMoveOrder
local spGiveOrderToUnit        = Spring.GiveOrderToUnit

local modOptions    = Spring.GetModOptions()
local modOptionDefs = VFS.Include("modoptions.lua")
local modRules      = VFS.Include("gamedata/modrules.lua")

local losToElmos = 1.0
local gaiaTeamID = Spring.GetGaiaTeamID()

-- "modOptions" is a <string, string> map (values are not numbers!)
local haveZombies = (((modOptions["zombies"] or "0") + 0) ~= 0)
local zombieConf  = "LuaRules/Configs/game_zombiemode_defs.lua"
local zombieDefs  = VFS.FileExists(zombieConf) and include(zombieConf) or {}
local zombieQueue = {}
local zombieCount = 0

-- better to hardcode these, as many weapons are listed as dgun, for example bogus dgun
local dgunTable = {
	[WeaponDefNames[  "arm_disintegrator"].id] = true,
	[WeaponDefNames[ "core_disintegrator"].id] = true,
	[WeaponDefNames["core_udisintegrator"].id] = true,
	[WeaponDefNames[ "uber_disintegrator"].id] = true,
}

function gadget:Initialize()
	assert(modOptionDefs ~= nil)

	if (modOptions == nil) then
		Spring.Echo("[game_zombiemode] no mod-options")
		gadgetHandler:RemoveGadget(self)
		return
	end

	if (gaiaTeamID == 0) then
		Spring.Echo("[game_zombiemode] no Gaia-team")
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
		--Spring.Log("",LOG.INFO,"[game_zombiemode] no zombies no fun")
		gadgetHandler:RemoveGadget(self)
		return
	end

	if (modRules ~= nil and modRules["sensors"] ~= nil and modRules["sensors"]["los"] ~= nil) then
		local losResMult  = modRules["sensors"]["los"]["losMul"     ]
		local losMipLevel = modRules["sensors"]["los"]["losMipLevel"]

		-- losRadius = sightDist * losResMult / (SQUARE_SIZE * (1 << losMipLevel))
		-- sightDist = losRadius * SQUARE_SIZE * (1 << losMipLevel) / losResMult
		losToElmos = 8 * math.pow(2, losMipLevel) / losResMult
	end
end

-- TODO:
--   dgun should not trigger respawn (config) *FIXED*
--   reclaiming should NOT EVER trigger respawn (ok, does not trigger UnitDamaged)
--   nanoframe decay should NOT EVER trigger respawn *FIXED*
--	 morphing should not trigger respawn *FIXED*
function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	local health,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)

	if (health < 0.0 and buildProgress >= 1.0 and not dgunTable[weaponDefID]) then
		local isZombie = (unitTeam == gaiaTeamID)
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
			dir    = {spGetUnitDirection(unitID)},
			facing = spGetUnitBuildFacing(unitID),
			frame  = spGetGameFrame() + respawnTime
		}
	end
end

function gadget:GameFrame(n)
	for index, spawn in pairs(zombieQueue) do
		if (spawn.frame == n) then
			SpawnZombie(index, spawn)
		end
	end
end


function SpawnZombie(index, spawn)
	local spawnPos = spawn.pos
	local spawnDir = spawn.dir
	local features = spGetFeaturesInRectangle(spawnPos[1] - 8.0, spawnPos[3] - 8.0,  spawnPos[1] + 8.0, spawnPos[3] + 8.0)

	if (features ~= nil) then
		-- make sure zombies are not stuck in their own corpses
		-- player can still suck the wrecks if he acts quickly
		-- (could be an option to prevent spawns if the player
		-- manages to reclaim >= 75% of a corpse in time)
		for _, featureID in ipairs(features) do
			spDestroyFeature(featureID)
		end
	end

	local udefID = spawn.defID
	local unitID = spCreateUnit(udefID, spawnPos[1], spawnPos[2], spawnPos[3], spawn.facing, gaiaTeamID)

	if (unitID ~= nil) then
		spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {[1] = CMD_FIRESTATE_FATW}, {})
		spGiveOrderToUnit(unitID, CMD.MOVE_STATE, {[1] = CMD_MOVESTATE_ROAM}, {})
		--spSetUnitNeutral(unitID, true)

		local losRadius = UnitDefs[udefID].losRadius
		local sightDist = losRadius * losToElmos
		local patrolVec = {spawnDir[1] * sightDist * 0.666, 0.0, spawnDir[3] * sightDist * 0.666}

		if (not UnitDefs[udefID].isImmobile) then
			local p0 = {spawnPos[1] + patrolVec[1], spawnPos[2], spawnPos[3] + patrolVec[3]}
			local p1 = {spawnPos[1] - patrolVec[1], spawnPos[2], spawnPos[3] - patrolVec[3]}

			-- test validity of orders
			local b0 = spTestMoveOrder(udefID,  p0[1], p0[2], p0[3], 0.0, 0.0, 0.0,  true, true, true)
			local b1 = spTestMoveOrder(udefID,  p1[1], p1[2], p1[3], 0.0, 0.0, 0.0,  true, true, true)

			if (b0) then spGiveOrderToUnit(unitID, CMD.PATROL, p0, {"shift"}) end
			if (b1) then spGiveOrderToUnit(unitID, CMD.PATROL, p1, {"shift"}) end
		end
	end

	zombieQueue[index] = nil
end

