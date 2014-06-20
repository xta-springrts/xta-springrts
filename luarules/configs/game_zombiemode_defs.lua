local zombieDefs = {}

for unitDefName, unitDef in pairs(UnitDefs) do
	zombieDefs[unitDef.id] = {
		respawnTime = Game.gameSpeed * 15,

		allowZombieSpawn = true,
		allowRepeatSpawn = false,
		allowDebrisSpawn = true,

		allowTeamKillSpawn = true,
		allowSelfKillSpawn = true,
	}
end

return zombieDefs

