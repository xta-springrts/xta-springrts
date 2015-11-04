local CommanderUnitDefs, CommanderSounds, CommanderTargets = include("LuaRules/Configs/unit_commander_sounds_defs.lua")
local CommanderSingCmdDesc = {id = 40123, name = "Sing", }
local CommanderTauntCmdDesc = {id = 40234, name = "Taunt", }
local GLHFCmdDesc = {id = 40531, name = "GL & HF", }
local TYCmdDesc = {id = 40532, name = "Say thx", }

local spPlaySoundFile = Spring.PlaySoundFile
local rnd = math.random
local volume = 4.0
local Echo = Spring.Echo


if (gadgetHandler:IsSyncedCode()) then
	
	local FindUnitCmdDesc = Spring.FindUnitCmdDesc
	local RemoveUnitCmdDesc = Spring.RemoveUnitCmdDesc
	local teamsThatHaveSaidThanks = {}
	local firstGreetDone = false

	function gadget:Initialize()
		for _, unitID in ipairs(Spring.GetAllUnits()) do
			self:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
		end
	end
	
	local function switchGreetButtons() -- switches glhf button to thx, for all units
		for _, unitID in ipairs(Spring.GetAllUnits()) do
			local cmdDescID = FindUnitCmdDesc(unitID, GLHFCmdDesc.id)
			if (cmdDescID) then
				RemoveUnitCmdDesc(unitID, cmdDescID)
				Spring.InsertUnitCmdDesc(unitID, cmdDescID, TYCmdDesc)		
			end
		end
	end
	
	local function switchThxButton(teamID) -- switches thx-button to sing button for this team
		for _, unitID in ipairs(Spring.GetTeamUnits(teamID)) do
			local cmdDescID = FindUnitCmdDesc(unitID, TYCmdDesc.id)
			if (cmdDescID) then
				RemoveUnitCmdDesc(unitID, cmdDescID)		
				Spring.InsertUnitCmdDesc(unitID, cmdDescID, CommanderSingCmdDesc)
			end
		end
	end
	
	function gadget:UnitCreated(unitID, unitDefID, unitTeamID, builderID)
		if (CommanderUnitDefs[unitDefID] ~= nil) then
			
			local cmdDescID = FindUnitCmdDesc(unitID, GLHFCmdDesc.id)
			
			
			-- sing command is only available after you have said thank you :)
			if not firstGreetDone then
				Spring.InsertUnitCmdDesc(unitID, GLHFCmdDesc)
			elseif not teamsThatHaveSaidThanks[unitTeamID] then
				Spring.InsertUnitCmdDesc(unitID, TYCmdDesc)
			else
				Spring.InsertUnitCmdDesc(unitID, CommanderSingCmdDesc)
			end
			
			--taunt button on the other hand goes to all commanders
			Spring.InsertUnitCmdDesc(unitID, CommanderTauntCmdDesc)
		end
	end

	-- I think this is annoying so I disabled this callin. Jools.
	--function gadget:UnitDamaged(unitID, unitDefID, unitTeamID, damage, paralyzer, weaponID, projectileID, attackerID, attackerDefID, attackerTeamID)
		
		--SendToUnsynced('usUnitDamaged', unitID, unitDefID, unitTeamID, damage, paralyzer, weaponID, projectileID, attackerID, attackerDefID, attackerTeamID)
	--end

	function gadget:UnitDestroyed(unitID, unitDefID, unitTeamID, attackerID, attackerDefID, attackerTeamID)
		SendToUnsynced('usUnitDestroyed', unitID, unitDefID, unitTeamID, attackerID, attackerDefID, attackerTeamID)
	end
	
	--function gadget:UnitCloaked(unitID, unitDefID, unitTeamID)
		--SendToUnsynced('usUnitCloaked', unitID, unitDefID, unitTeamID)
	--end

	--function gadget:UnitLoaded(unitID, unitDefID, unitTeamID, transportUnitID, transportTeamID)
		--SendToUnsynced('usUnitLoaded', unitID, unitDefID, unitTeamID, transportUnitID, transportTeamID)
	--end

	-- HACK:
	--    * CommandFallback is only called for unknown commands
	--    * CommandNotify *and* UnitCommand only reach widgets
	--      (even though EventHandler sets up UnitCommand with
	--      MANAGED_BIT) so use AllowCommand instead
	function gadget:AllowCommand(unitID, unitDefID, unitTeamID, cmdID, cmdParams, cmdOptions)
		--if (cmdID == CMD.REPAIR and #cmdParams == 1 and unitID == cmdParams[1]) then
			--SendToUnsynced('usUnitSelfRepair', unitID, unitDefID, unitTeamID)
		--end

		if (CommanderUnitDefs[unitDefID] ~= nil) then
			-- note:
			--   in synced code, so these play for everyone (also non-positional)
			--   return false for Sing/Taunt so they do not cancel normal orders
			--   Original cob-gadget had these probabilities, that's why they are retained.
			--   The first sing sound is the original one, that's why it's more probable.
			
			-- sing command
			if (cmdID == CommanderSingCmdDesc.id) then
				local idx = 0

				if (rnd(0, 10) >= 5) then 
					idx = rnd(1, #CommanderSounds.CommanderSongs[unitDefID])
				end

				spPlaySoundFile(CommanderSounds.CommanderSongs[unitDefID][idx], volume)
				return false
			end
			
			--taunt command
			if (cmdID == CommanderTauntCmdDesc.id) then
				local snds = CommanderSounds.CommanderTaunts[unitDefID]
				local sidx = rnd(0, #snds)

				spPlaySoundFile(snds[sidx], volume)
				return false
			end
			
			--greet command
			if (CommanderUnitDefs[unitDefID] ~= nil) then
				if (cmdID == GLHFCmdDesc.id) then
					local idx = rnd(0, #CommanderSounds.GLHFSongs[unitDefID])
					
					spPlaySoundFile(CommanderSounds.GLHFSongs[unitDefID][idx], volume)
					switchGreetButtons()
					firstGreetDone = true
					return false
				--ty command
				elseif (cmdID == TYCmdDesc.id) then
					local idx = rnd(0, #CommanderSounds.TYSongs[unitDefID])
					spPlaySoundFile(CommanderSounds.TYSongs[unitDefID][idx], volume)
					switchThxButton(unitTeamID)
					teamsThatHaveSaidThanks[unitTeamID] = true
					return false
				end
			end
		end
		
		return true
	end


else
	local unsyncedEventHandlers = {}
	local commanderKillCounts = {}
	local myTeamID = Spring.GetMyTeamID()	-- we assume that players can't change control of teams

	local spGetUnitTeam = Spring.GetUnitTeam
	local spAreTeamsAllied = Spring.AreTeamsAllied
	local spGetUnitHealth = Spring.GetUnitHealth
	local spGetUnitPosition = Spring.GetUnitPosition
	local spGetGameFrame = Spring.GetGameFrame
	
	local function usUnitDamaged(_, unitID, unitDefID, unitTeamID, _, _, _, _, attackerID, attackerDefID, attackerTeamID)
		if (CommanderUnitDefs[unitDefID] == nil) then
			return true	-- not a commander
		end
		if (unitTeamID ~= myTeamID) then
			return true	-- not one of our units
		end
		if (spGetUnitHealth(unitID) <= 0.0) then
			return true	-- unit is already dead
		end
		if (attackerTeamID ~= nil and spAreTeamsAllied(unitTeamID, attackerTeamID)) then
			return true	-- ignore friendly fire
		end

		local unitDef = UnitDefs[unitDefID]
		local attackerDef = UnitDefs[attackerDefID or -1]
		local unitHealth = spGetUnitHealth(unitID)
		local dmgSoundIdx = 0

			if (unitHealth > (unitDef.health * 0.75)) then dmgSoundIdx = 3
		elseif (unitHealth > (unitDef.health * 0.50)) then dmgSoundIdx = 2
		elseif (unitHealth > (unitDef.health * 0.25)) then dmgSoundIdx = 1
		elseif (unitHealth > (unitDef.health * 0.01)) then dmgSoundIdx = 0
		end

		-- if fifth character of name is an underscore (ASCII code 95)
		-- then the side prefix is (probably) "core" instead of "arm"
		-- add four to the index since we have four damage levels
		
		-- use "side" tag instead
		local cp = unitDef.customParams
		if cp and cp.side == 'core' then
			if CommanderSounds.CommanderDamaged[dmgSoundIdx+4] then
				dmgSoundIdx = dmgSoundIdx + 4
			end
		elseif cp and cp.side == 'lost' then
			if CommanderSounds.CommanderDamaged[dmgSoundIdx+8] then
				dmgSoundIdx = dmgSoundIdx + 8 
			end
		elseif cp and cp.side == 'guardian' then
			if CommanderSounds.CommanderDamaged[dmgSoundIdx+12] then
				dmgSoundIdx = dmgSoundIdx + 12 
			end
		end

		spPlaySoundFile(CommanderSounds.CommanderDamaged[dmgSoundIdx], 1.0, spGetUnitPosition(unitID))

		-- crawling bomb damage counts as humiliation (as does being loaded)
		-- problem: the attacker has blown itself up, so attackerDef is nil
		-- if detonation is not right on top of commander (waiting damages)
		if (attackerDef == nil or (not attackerDef.canKamikaze)) then
			return true
		end

		spPlaySoundFile(CommanderSounds.CommanderHumiliated, 1.0, spGetUnitPosition(unitID))
		return true
	end

	local function usUnitDestroyed(_, unitID, unitDefID, unitTeamID, attackerID, attackerDefID, attackerTeamID)
		if (CommanderUnitDefs[attackerDefID] == nil) then
			return true	-- unit was not destroyed by a commander
		end
		if (attackerTeamID ~= myTeamID) then
			return true	-- it was not one of our attackers that killed this unit
		end
		if (attackerTeamID ~= nil and spAreTeamsAllied(unitTeamID, attackerTeamID)) then
			return true	-- one of our units was killed
		end
		if (attackerDefID == nil or UnitDefs[attackerDefID] == nil) then
			return true	-- destroyed unit had no direct or valid attacker
		end

		-- check if the destroyed unit was a special target
		for i = 0, #CommanderTargets.HolyTargetDefs do
			if (unitDefID == CommanderTargets.HolyTargetDefs[i].id) then
				spPlaySoundFile(CommanderSounds.CommanderHolyTargetDestroyed, volume)
				return true
			end
		end
		for i = 0, #CommanderTargets.ImpressiveTargetDefs do
			if (unitDefID == CommanderTargets.ImpressiveTargetDefs[i].id) then
				spPlaySoundFile(CommanderSounds.CommanderImpressiveTargetDestroyed, volume)
				return true
			end
		end

		-- otherwise just maintain kill-counter
		local f = spGetGameFrame()

		if (commanderKillCounts[attackerID] == nil) then
			commanderKillCounts[attackerID] = {[0] = f, [1] = 0} -- frame, #kills
		end

		if ((f - commanderKillCounts[attackerID][0]) < (Game.gameSpeed * 4.0)) then
			commanderKillCounts[attackerID][1] = commanderKillCounts[attackerID][1] + 1

			if (commanderKillCounts[attackerID][1] >= 15) then
				spPlaySoundFile(CommanderSounds.CommanderPerfectTargetsKilled, volume)
				commanderKillCounts[attackerID] = nil
			elseif (commanderKillCounts[attackerID][1] == 5) then
				spPlaySoundFile(CommanderSounds.CommanderExcellentTargetsKilled, volume)
			end
		else
			commanderKillCounts[attackerID] = nil
		end
		return true
	end

	local function usUnitCloaked(_, unitID, unitDefID, unitTeamID)
		if (unitTeamID ~= myTeamID) then
			return true	-- unit that cloaked was not ours
		end
		if (CommanderUnitDefs[unitDefID] == nil) then
			return true
		end

		spPlaySoundFile(CommanderSounds.CommanderCloaked, 1.0, spGetUnitPosition(unitID))
		return true
	end

	local function usUnitLoaded(_, unitID, unitDefID, unitTeamID, _, transTeamID)
		if (unitTeamID ~= myTeamID) then
			return true	-- unit that got loaded was not ours
		end
		if (spAreTeamsAllied(unitTeamID, transTeamID)) then
			return true	-- our unit got loaded by a friendly transport
		end
		if (CommanderUnitDefs[unitDefID] == nil) then
			return true	-- not a commander
		end

		-- TODO: make synced?
		spPlaySoundFile(CommanderSounds.CommanderHumiliated, 1.0, spGetUnitPosition(unitID))
		return true
	end

	local function usUnitSelfRepair(_, unitID, unitDefID, unitTeamID)
		if (unitTeamID ~= myTeamID) then
			return true	-- not one of our units repairing itself
		end
		if (not UnitDefs[unitDefID].canSelfRepair) then
			return true
		end
		if (CommanderUnitDefs[unitDefID] == nil) then
			return true
		end

		spPlaySoundFile(CommanderSounds.CommanderRepaired, 1.0, spGetUnitPosition(unitID))
		return true
	end



	function gadget:Initialize()
		gadgetHandler:AddSyncAction('usUnitDamaged', usUnitDamaged)
		gadgetHandler:AddSyncAction('usUnitDestroyed', usUnitDestroyed)
		--gadgetHandler:AddSyncAction('usUnitCloaked', usUnitCloaked)
		--gadgetHandler:AddSyncAction('usUnitLoaded', usUnitLoaded)
		--gadgetHandler:AddSyncAction('usUnitSelfRepair', usUnitSelfRepair)
		
		--[[
		Note: Not all sync actions are in use, and all should return true so that SendToUnsynced
		      doesn't get passed to all other gadget:RecvFromUnsynced(), as gadgetHandler has
		      if (actionHandler.RecvFromSynced(...)) then
		        return
		      end
		      for _,g in ipairs(self.RecvFromSyncedList) do
		        if (g:RecvFromSynced(...)) then
		          return
		        end
		      end
		--]]

	end

end

