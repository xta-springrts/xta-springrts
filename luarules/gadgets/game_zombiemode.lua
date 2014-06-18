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
local spGetUnitPosition    = Spring.GetUnitPosition
local spGetUnitDirection   = Spring.GetUnitDirection
local spGetUnitBuildFacing = Spring.GetUnitBuildFacing
local spCreateUnit         = Spring.CreateUnit
local spGiveOrderToUnit    = Spring.GiveOrderToUnit

local modOptions    = Spring.GetModOptions()
local modOptionDefs = VFS.Include("modoptions.lua")
local modRules      = VFS.Include("gamedata/modrules.lua")

local losResMult  = 1.0
local losMipLevel = 1.0
local gaiaTeamID  = Spring.GetGaiaTeamID()

-- "modOptions" is a <string, string> map (values are not numbers!)
local haveZombies = (((modOptions["zombies"] or "0") + 0) ~= 0)
local zombieConf  = "LuaRules/Configs/game_zombiemode_defs.lua"
local zombieDefs  = VFS.FileExists(zombieConf) and include(zombieConf) or {}
local zombieQueue = {}
local zombieCount = 0

local dgunTable = { -- better to hardcode these, as many weapons are listed as dgun, for example bogus dgun
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
		losResMult  = modRules["sensors"]["los"]["losMul"     ]
		losMipLevel = modRules["sensors"]["los"]["losMipLevel"]
	end
end

-- TODO:
--   dgun should not trigger respawn? (config) *FIXED*
--   reclaiming should NOT EVER trigger respawn
--   nanoframe decay should NOT EVER trigger respawn *FIXED*
--	 morphing should not trigger respawn *FIXED*
function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	local health,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)

	if (health < 0.0 and buildProgress >= 1.0 and not dgunTable[weaponDefID]) then
		local isZombie = unitTeam == gaiaTeamID
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
			local unitID = spCreateUnit(spawn.defID, spawn.pos[1], spawn.pos[2], spawn.pos[3], spawn.facing, gaiaTeamID)

			if (unitID ~= nil) then
				spGiveOrderToUnit(unitID, CMD.FIRE_STATE, {[1] = CMD_FIRESTATE_FATW}, {})
				spGiveOrderToUnit(unitID, CMD.MOVE_STATE, {[1] = CMD_MOVESTATE_ROAM}, {})
				--spSetUnitNeutral(unitID, true)

				-- losRadius = sightDist * losResMult / (SQUARE_SIZE * (1 << losMipLevel))
				-- sightDist = losRadius * SQUARE_SIZE * math.pow(2, losMipLevel) / losResMult
				local losRadius = UnitDefs[spawn.defID].losRadius
				local sightDist = losRadius * 8 * math.pow(2, losMipLevel) / losResMult
				local patrolVec = {spawn.dir[1] * sightDist * 0.75, 0.0, spawn.dir[3] * sightDist * 0.75}

				if (not UnitDefs[spawn.defID].isImmobile) then
					spGiveOrderToUnit(unitID, CMD.PATROL, {spawn.pos[1] + patrolVec[1], spawn.pos[2], spawn.pos[3] + patrolVec[3]}, {})
				end
			end

			zombieQueue[index] = nil
		end
	end
end

