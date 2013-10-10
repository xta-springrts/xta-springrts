local zombieDefs = {
}

for unitDefName, unitDef in pairs(UnitDefs) do
	zombieDefs[unitDef.id] = {canRespawn = true, respawnTime = Game.gameSpeed * 15}
end

return zombieDefs

