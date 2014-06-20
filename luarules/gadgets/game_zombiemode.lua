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
local spGetFeaturePosition     = Spring.GetFeaturePosition
local spGetFeatureDefID        = Spring.GetFeatureDefID
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
local zombieDefs  = (VFS.FileExists(zombieConf) and include(zombieConf)) or {}
local zombieQueue = {}
local zombieTable = {}
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

-- NOTE:
--   dgun should not trigger respawn (config) *FIXED*
--   reclaiming should NOT EVER trigger respawn (ok, does not trigger UnitDamaged)
--   nanoframe decay should NOT EVER trigger respawn *FIXED*
--	 morphing should not trigger respawn *FIXED*
function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	local health, _,_,_, buildProgress = Spring.GetUnitHealth(unitID)
	local killed = ((health - damage) <= 0.0)
	local dgunned = dgunTable[weaponDefID]

	if (dgunned) then
		return
	end
	if (not killed) then
		return
	end
	if (zombieTable[unitID]) then
		return
	end

	if (buildProgress >= 1.0) then
		local isZombie = (unitTeam == gaiaTeamID)
		local zombieDef = zombieDefs[unitDefID] or {}

		if ((isZombie and (not zombieDef.allowRepeatSpawn)) or (not zombieDef.allowZombieSpawn)) then
			return
		end

		if ((attackerID == nil or attackerTeam == nil) and (not zombieDef.allowDebrisSpawn)) then
			return
		end

		local teamKill, allowTeamKill = (attackerTeam == unitTeam), zombieDef.allowTeamKillSpawn
		local selfKill, allowSelfKill = (attackerID == unitID), zombieDef.allowSelfKillSpawn

		-- self-kills are also team-kills, check those separately
		if ((teamKill and (not selfKill)) and (not allowTeamKill)) then
			return
		end
		if (selfKill and (not allowSelfKill)) then
			return
		end

		zombieCount = zombieCount + 1
		zombieQueue[zombieCount] = {
			id     = unitID,
			defID  = unitDefID,
			pos    = {spGetUnitPosition(unitID)},
			dir    = {spGetUnitDirection(unitID)},
			facing = spGetUnitBuildFacing(unitID),
			frame  = spGetGameFrame() + zombieDef.respawnTime
		}

		-- prevent double spawns
		zombieTable[unitID] = true
	end
end

--[[
function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts)
	if (unitTeam ~= gaiaTeamID) then
		return true
	end

	if (cmdID ~= CMD_RECLAIM) then
		return true
	end

	return true
end
--]]

function gadget:GameFrame(n)
	for index, spawn in pairs(zombieQueue) do
		if (spawn.frame == n) then
			SpawnZombie(index, spawn)
		end
	end
end



function DestroyWreck(unitDef, spawnPos)
	local featureIDs = spGetFeaturesInRectangle(spawnPos[1] - 64.0, spawnPos[3] - 64.0,  spawnPos[1] + 64.0, spawnPos[3] + 64.0)

	if (featureIDs == nil) then
		return false
	end

	-- try to make sure zombies are not stuck in their own corpses
	-- player can still suck the wrecks if he acts quickly enough
	--
	-- (could be an option to prevent spawns *if* the player manages
	-- to reclaim >= 75% of a corpse in time, but would have to make
	-- an exception for units that don't leave wrecks and for zombie
	-- builders which might reclaim corpses before they could spawn:
	-- zombies should never hurt the chances of their own "team", so
	-- with such an option feature-reclaim orders should be blocked
	-- from all patrolling zombie builders)
	--
	-- note: a corpse might have kept sliding along the ground after
	-- dying so this loop won't always find a match, but there is no
	-- general way to link a corpse back to the unit which created it
	local minFeatureID = -1
	local minFeatureDist = math.huge

	for _, featureID in ipairs(featureIDs) do
		local featureDefID = spGetFeatureDefID(featureID)
		local featureName = FeatureDefs[featureDefID].name
		local featurePos = {spGetFeaturePosition(featureID)}
		local featureDist = (featurePos[1] - spawnPos[1])^2 + (featurePos[3] - spawnPos[3])^2

		if (featureDist < minFeatureDist and featureName == unitDef.wreckName) then
			minFeatureDist = featureDist
			minFeatureID = featureID
		end
	end

	if (minFeatureID ~= -1) then
		spDestroyFeature(minFeatureID)
		return true
	end

	return false
end

function SpawnZombie(index, spawn)
	local spawnPos = spawn.pos
	local spawnDir = spawn.dir

	local unitDefID = spawn.defID
	local unitDef = UnitDefs[unitDefID]

	local unitID = spCreateUnit(unitDefID, spawnPos[1], spawnPos[2], spawnPos[3], spawn.facing, gaiaTeamID)

	DestroyWreck(unitDef, spawnPos)

	if (unitID ~= nil) then
		spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {[1] = FIRESTATE_FATW}, {})
		spGiveOrderToUnit(unitID, CMD.MOVE_STATE, {[1] = MOVESTATE_ROAM}, {})
		-- spSetUnitNeutral(unitID, true)

		local losRadius = unitDef.losRadius
		local sightDist = losRadius * losToElmos
		local patrolVec = {spawnDir[1] * sightDist * 0.666, 0.0, spawnDir[3] * sightDist * 0.666}

		if (not unitDef.isImmobile) then
			local p0 = {spawnPos[1] + patrolVec[1], spawnPos[2], spawnPos[3] + patrolVec[3]}
			local p1 = {spawnPos[1] - patrolVec[1], spawnPos[2], spawnPos[3] - patrolVec[3]}

			-- test validity of orders
			local b0 = spTestMoveOrder(unitDefID,  p0[1], p0[2], p0[3], 0.0, 0.0, 0.0,  true, true, true)
			local b1 = spTestMoveOrder(unitDefID,  p1[1], p1[2], p1[3], 0.0, 0.0, 0.0,  true, true, true)

			if (b0) then spGiveOrderToUnit(unitID, CMD.PATROL, p0, {"shift"}) end
			if (b1) then spGiveOrderToUnit(unitID, CMD.PATROL, p1, {"shift"}) end
		end
	end

	zombieQueue[index] = nil
	zombieTable[spawn.id] = nil
end

