if (gadgetHandler:IsSyncedCode()) then
	local RandNumGen = math.random 
	local crashingUnits = {}

	local CRASHRISK = 0.33
	local DAMAGELIMIT = 1.0

	local SetUnitCrashing 		= Spring.SetUnitCrashing
	local SetUnitNoSelect 		= Spring.SetUnitNoSelect
	local SetUnitNeutral 		= Spring.SetUnitNeutral
	local SetUnitSensorRadius 	= Spring.SetUnitSensorRadius
	local SetUnitCOBValue 		= Spring.SetUnitCOBValue
	local GiveOrderToUnit 		= Spring.GiveOrderToUnit
	local CMD_FIRE_STATE 		= CMD.FIRE_STATE
	local CMD_ATTACK 			= CMD.ATTACK

	function gadget:GetInfo()
		return {
			name    = "unit_crashing_aircraft",
			layer   = 0,
			enabled = true,
		}
	end

	function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam)
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

		if ((damage > DAMAGELIMIT * Spring.GetUnitHealth(unitID)) and (RandNumGen() < CRASHRISK)) then
			SetUnitCrashing(unitID, true)
			SetUnitNoSelect(unitID, true)
			SetUnitNeutral(unitID, true)
			SetUnitSensorRadius (unitID, "los", 0)
			SetUnitSensorRadius (unitID, "airLos", 0)
			SetUnitSensorRadius (unitID, "radar", 0)
			SetUnitSensorRadius (unitID, "sonar", 0)
			SetUnitSensorRadius (unitID, "seismic", 0)
			SetUnitSensorRadius (unitID, "radarJammer", 0)
			SetUnitSensorRadius (unitID, "sonarJammer", 0)
			-- hold fire and prevent unit from continuing to attack.
			-- must be the last order before crashing state, or the
			-- engine will find a new target.
			GiveOrderToUnit(unitID, CMD_FIRE_STATE, {0}, {})
			GiveOrderToUnit(unitID, CMD_ATTACK, {0.0, 0.0, 0.0}, {""})
			SetUnitCOBValue(unitID, COB.CRASHING, 1)

			crashingUnits[unitID] = true
		end

		return damage, 1.0
	end

	function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
		crashingUnits[unitID] = nil
	end
end

