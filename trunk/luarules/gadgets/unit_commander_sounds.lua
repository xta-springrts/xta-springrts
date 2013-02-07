local UNIT_DAMAGED_EVENT_ID     = 20001
local UNIT_DESTROYED_EVENT_ID   = 20002
local UNIT_CLOAKED_EVENT_ID     = 20003
local UNIT_LOADED_EVENT_ID      = 20004
local UNIT_SELF_REPAIR_EVENT_ID = 20005

local CommanderUnitDefs, CommanderSounds, CommanderTargets = include("LuaRules/Configs/unit_commander_sounds_defs.lua")
local CommanderSingCmdDesc = {id = 40123, name = "Sing", }
local CommanderTauntCmdDesc = {id = 40234, name = "Taunt", }

if (gadgetHandler:IsSyncedCode()) then
	function gadget:Initialize()
		for _, unitID in ipairs(Spring.GetAllUnits()) do
			self:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
		end
	end

	function gadget:UnitCreated(unitID, unitDefID, _, _)
		if (CommanderUnitDefs[unitDefID] ~= nil) then
			Spring.InsertUnitCmdDesc(unitID, CommanderSingCmdDesc)
			Spring.InsertUnitCmdDesc(unitID, CommanderTauntCmdDesc)
		end
	end

	function gadget:UnitDamaged(unitID, unitDefID, unitTeamID, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
		SendToUnsynced(UNIT_DAMAGED_EVENT_ID, unitID, unitDefID, unitTeamID, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	end

	function gadget:UnitDestroyed(unitID, unitDefID, unitTeamID, attackerID, attackerDefID, attackerTeamID)
		SendToUnsynced(UNIT_DESTROYED_EVENT_ID, unitID, unitDefID, unitTeamID, attackerID, attackerDefID, attackerTeamID)
	end

	function gadget:UnitCloaked(unitID, unitDefID, unitTeamID)
		SendToUnsynced(UNIT_CLOAKED_EVENT_ID, unitID, unitDefID, unitTeamID)
	end

	function gadget:UnitLoaded(unitID, unitDefID, unitTeamID, transportUnitID, transportTeamID)
		SendToUnsynced(UNIT_LOADED_EVENT_ID, unitID, unitDefID, unitTeamID, transportUnitID, transportTeamID)
	end

	-- HACK:
	--    * CommandFallback is only called for unknown commands
	--    * CommandNotify *and* UnitCommand only reach widgets
	--      (even though EventHandler sets up UnitCommand with
	--      MANAGED_BIT) so use AllowCommand instead
	function gadget:AllowCommand(unitID, unitDefID, unitTeamID, cmdID, cmdParams, cmdOptions)
		if (cmdID == CMD.REPAIR and #cmdParams == 1 and unitID == cmdParams[1]) then
			SendToUnsynced(UNIT_SELF_REPAIR_EVENT_ID, unitID, unitDefID, unitTeamID)
		end

		if (CommanderUnitDefs[unitDefID] ~= nil) then
			-- note:
			--   in synced code, so these play for everyone (also non-positional)
			--   return false for Sing/Taunt so they do not cancel normal orders
			if (cmdID == CommanderSingCmdDesc.id) then
				local rnd = math.random(0, 15)
				local idx = math.min(rnd, #CommanderSounds.CommanderSongs[unitDefID])

				Spring.PlaySoundFile(CommanderSounds.CommanderSongs[unitDefID][idx], 4.0)
				return false
			end
			if (cmdID == CommanderTauntCmdDesc.id) then
				local rnd = math.random(0, 15)
				local idx = math.min(rnd, #CommanderSounds.CommanderTaunts[unitDefID])

				Spring.PlaySoundFile(CommanderSounds.CommanderTaunts[unitDefID][idx], 4.0)
				return false
			end
		end

		return true
	end


else
	local unsyncedEventHandlers = {}
	local commanderKillCounts = {}


	local function usUnitDamaged(unitID, unitDefID, unitTeamID, _, _, _, attackerID, attackerDefID, _)
		if (unitTeamID ~= Spring.GetMyTeamID()) then
			-- not one of our units
			return
		end
		if (Spring.GetUnitHealth(unitID) <= 0.0) then
			-- unit is already dead
			return
		end

		if (CommanderUnitDefs[unitDefID] == nil) then
			return
		end
		if (attackerID ~= nil and Spring.AreTeamsAllied(Spring.GetUnitTeam(unitID), Spring.GetUnitTeam(attackerID))) then
			-- ignore friendly fire
			return
		end

		local unitDef = UnitDefs[unitDefID]
		local attackerDef = UnitDefs[attackerDefID or -1]
		local unitHealth = Spring.GetUnitHealth(unitID)
		local dmgSoundIdx = 0

			if (unitHealth > (unitDef.health * 0.75)) then dmgSoundIdx = 3
		elseif (unitHealth > (unitDef.health * 0.50)) then dmgSoundIdx = 2
		elseif (unitHealth > (unitDef.health * 0.25)) then dmgSoundIdx = 1
		elseif (unitHealth > (unitDef.health * 0.01)) then dmgSoundIdx = 0
		end

		-- if fifth character of name is an underscore (ASCII code 95)
		-- then the side prefix is (probably) "core" instead of "arm"
		-- add four to the index since we have four damage levels
		if (unitDef.name:byte(5) == 95) then
			dmgSoundIdx = dmgSoundIdx + 4
		end

		Spring.PlaySoundFile(CommanderSounds.CommanderDamaged[dmgSoundIdx], 1.0, Spring.GetUnitPosition(unitID))

		-- crawling bomb damage counts as humiliation (as does being loaded)
		-- problem: the attacker has blown itself up, so attackerDef is nil
		-- if detonation is not right on top of commander (waiting damages)
		if (attackerDef == nil or (not attackerDef.canKamikaze)) then
			return
		end

		Spring.PlaySoundFile(CommanderSounds.CommanderHumiliated, 1.0, Spring.GetUnitPosition(unitID))
	end

	local function usUnitDestroyed(unitID, unitDefID, unitTeamID, attackerID, attackerDefID, attackerTeamID, _, _, _)
		if (attackerTeamID ~= Spring.GetMyTeamID()) then
			-- it was not one of our attackers that killed this unit
			return
		end
		if (attackerTeamID ~= nil and Spring.AreTeamsAllied(unitTeamID, attackerTeamID)) then
			-- one of our units was killed
			return
		end

		if (attackerDefID == nil or UnitDefs[attackerDefID] == nil) then
			-- destroyed unit had no direct or valid attacker
			return
		end
		if (CommanderUnitDefs[attackerDefID] == nil) then
			-- unit was not destroyed by a commander
			return
		end

		-- check if the destroyed unit was a special target
		for i = 0, #CommanderTargets.HolyTargetDefs do
			if (unitDefID == CommanderTargets.HolyTargetDefs[i].id) then
				Spring.PlaySoundFile(CommanderSounds.CommanderHolyTargetDestroyed, 4.0)
				return
			end
		end
		for i = 0, #CommanderTargets.ImpressiveTargetDefs do
			if (unitDefID == CommanderTargets.ImpressiveTargetDefs[i].id) then
				Spring.PlaySoundFile(CommanderSounds.CommanderImpressiveTargetDestroyed, 4.0)
				return
			end
		end

		-- otherwise just maintain kill-counter
		local f = Spring.GetGameFrame()

		if (commanderKillCounts[attackerID] == nil) then
			commanderKillCounts[attackerID] = {[0] = f, [1] = 0} -- frame, #kills
		end

		if ((f - commanderKillCounts[attackerID][0]) < (Game.gameSpeed * 4.0)) then
			commanderKillCounts[attackerID][1] = commanderKillCounts[attackerID][1] + 1

			if (commanderKillCounts[attackerID][1] >= 15) then
				Spring.PlaySoundFile(CommanderSounds.CommanderPerfectTargetsKilled, 4.0)
				commanderKillCounts[attackerID] = nil
			elseif (commanderKillCounts[attackerID][1] == 5) then
				Spring.PlaySoundFile(CommanderSounds.CommanderExcellentTargetsKilled, 4.0)
			end
		else
			commanderKillCounts[attackerID] = nil
		end
	end

	local function usUnitCloaked(unitID, unitDefID, unitTeamID, _, _, _, _, _, _)
		if (unitTeamID ~= Spring.GetMyTeamID()) then
			-- unit that cloaked was not ours
			return
		end

		if (CommanderUnitDefs[unitDefID] == nil) then
			return
		end

		Spring.PlaySoundFile(CommanderSounds.CommanderCloaked, 1.0, Spring.GetUnitPosition(unitID))
	end

	local function usUnitLoaded(unitID, unitDefID, unitTeamID, _, transTeamID, _, _, _, _)
		if (unitTeamID ~= Spring.GetMyTeamID()) then
			-- unit that got loaded was not ours
			return
		end

		if (Spring.AreTeamsAllied(unitTeamID, transTeamID)) then
			-- our unit got loaded by a friendly transport
			return
		end

		if (CommanderUnitDefs[unitDefID] == nil) then
			return
		end

		-- TODO: make synced?
		Spring.PlaySoundFile(CommanderSounds.CommanderHumiliated, 1.0, Spring.GetUnitPosition(unitID))
	end

	local function usUnitSelfRepair(unitID, unitDefID, unitTeamID, _, _, _, _, _, _)
		if (unitTeamID ~= Spring.GetMyTeamID()) then
			-- not one of our units repairing itself
			return
		end
		if (not UnitDefs[unitDefID].canSelfRepair) then
			return
		end
		if (CommanderUnitDefs[unitDefID] == nil) then
			return
		end

		Spring.PlaySoundFile(CommanderSounds.CommanderRepaired, 1.0, Spring.GetUnitPosition(unitID))
	end



	function gadget:Initialize()
		unsyncedEventHandlers[UNIT_DAMAGED_EVENT_ID    ] = usUnitDamaged
		unsyncedEventHandlers[UNIT_DESTROYED_EVENT_ID  ] = usUnitDestroyed
		unsyncedEventHandlers[UNIT_CLOAKED_EVENT_ID    ] = usUnitCloaked
		unsyncedEventHandlers[UNIT_LOADED_EVENT_ID     ] = usUnitLoaded
		unsyncedEventHandlers[UNIT_SELF_REPAIR_EVENT_ID] = usUnitSelfRepair
	end

	function gadget:RecvFromSynced(eventID, a, b, c, d, e, f, g, h, i)
		local eventHandler = unsyncedEventHandlers[eventID]

		if (eventHandler ~= nil) then
			eventHandler(a, b, c, d, e, f, g, h, i)
		end
	end
end

