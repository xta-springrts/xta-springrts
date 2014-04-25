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
local Echo              	= Spring.Echo

local modOptions    = Spring.GetModOptions()
local modOptionDefs = VFS.Include("modoptions.lua")

-- "modOptions" is a <string, string> map (values are not numbers!)
local haveZombies = (((modOptions["zombies"] or "0") + 0) ~= 0) or false
local zombieConf  = "LuaRules/Configs/game_zombiemode_defs.lua"
local zombieDefs  = VFS.FileExists(zombieConf) and include(zombieConf) or {}
local zombieQueue = {}
local zombieCount = 0

local dgunWeapons = {		-- better to hardcode these, as many weapons are listed as dgun, for example bogus dgun
	arm_disintegrator = true,
	core_disintegrator = true,
	core_udisintegrator = true,
	uber_disintegrator = true,
}
local dgunTable = {} -- Populated from dgunWeapons; a little better to store weapons in table by id instead of name

function gadget:Initialize()
	assert(modOptionDefs ~= nil)

	if (modOptions == nil) then
		Echo("[game_zombiemode] no mod-options")
		gadgetHandler:RemoveGadget(self)
		return
	end

	if (spGetGaiaTeamID() == 0) then
		Echo("[game_zombiemode] no Gaia-team")
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
	
	for id,weaponDef in pairs(WeaponDefs) do
		local wName = weaponDef.name
		if dgunWeapons[wName] then
			dgunTable[weaponDef.id] = true
		end
	end	
end

-- TODO:
--   dgun should not trigger respawn? (config) *FIXED*
--   reclaiming should NOT EVER trigger respawn
--   nanoframe decay should NOT EVER trigger respawn *FIXED*
--	 morphing should not trigger respawn *FIXED*
function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
	local health,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)
	if health < 0 and buildProgress >= 1 and not dgunTable[weaponDefID] then
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

