if (gadgetHandler:IsSyncedCode()) then
	
	local random = math.random 
	local crashingUnits = {}
	
	local CRASHCUTOFF = 0.33
	local MINHEALTH = 0.5
	
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
			-- paralysis damage cannot trigger a crash <--- wonder why not
			return damage, 1.0
		end
		
		if (damage > MINHEALTH * Spring.GetUnitHealth(unitID)) and random() < CRASHCUTOFF then
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

