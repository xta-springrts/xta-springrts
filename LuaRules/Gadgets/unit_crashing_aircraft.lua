if (gadgetHandler:IsSyncedCode()) then
	local crashingUnits = {}

	function gadget:GetInfo()
		return {
			name    = "unit_crashing_aircraft",
			layer   = 0,
			enabled = true,
		}
	end

	function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
		if (not UnitDefs[unitDefID].canFly) then
			-- not an airplane
			return damage, 1.0
		end
		if (crashingUnits[unitID]) then
			-- airplane and already crashing
			return 0.0, 0.0
		end
		if (paralyzer) then
			-- paralysis damage cannot trigger a crash
			return damage, 1.0
		end

		if (damage > Spring.GetUnitHealth(unitID)) then
			Spring.SetUnitCrashing(unitID, true)
			Spring.SetUnitNoSelect(unitID, true)
			Spring.SetUnitNeutral(unitID, true)
			Spring.SetUnitCOBValue(unitID, COB.CRASHING, 1)

			crashingUnits[unitID] = true
		end

		return damage, 1.0
	end

	function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
		crashingUnits[unitID] = nil
	end
end

