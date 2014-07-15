local versionNumber = "1.2"

function gadget:GetInfo()
	return {
	name = "Minimap attackblink",
	desc = "Blink minimap icon when attacked",
	author = "Jools",
	date = "May, 2014",
	license = "tango",
	layer = 2,
	enabled = false,
	}
end

-- shared synced/unsynced
local Echo 									= Spring.Echo
local blinkTime								= 90 -- frames
local blinkingUnits							= {}
local GetGameFrame							= Spring.GetGameFrame
local GetUnitIsDead							= Spring.GetUnitIsDead

if (gadgetHandler:IsSyncedCode()) then

--SYNCED
	
	local GetUnitDefID							= Spring.GetUnitDefID
	local GetUnitHealth							= Spring.GetUnitHealth
	local AreTeamsAllied						= Spring.AreTeamsAllied

	function gadget:GameFrame(frame)
		for unitID, startFrame in pairs(blinkingUnits) do
			if GetUnitIsDead(unitID) or frame - startFrame > blinkTime then
				blinkingUnits[unitID] = nil
			end
		end
	end

	function gadget:UnitDamaged (unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
		local buildProgress = select(5,GetUnitHealth(unitID))
		local alive = not GetUnitIsDead(unitID)
		
		if alive and (buildProgress and buildProgress>=1) then
			local frame = GetGameFrame()
			blinkingUnits[unitID] = frame
			SendToUnsynced('MB_UnitAttacked', unitID, frame)
		end
	end

	function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
		if blinkingUnits[unitID] then
			blinkingUnits[unitID] = nil
		end
	end

	function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
		
		if blinkingUnits[unitID] then
			blinkingUnits[unitID] = nil
		end
	end

	function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
		
		if blinkingUnits[unitID] and (not AreTeamsAllied(unitTeam, newTeam)) then
			blinkingUnits[unitID] = nil
		end
	end

else

	--------------
	-- UNSYNCED --
	--------------
	
	local SetUnitNoMinimap						= Spring.SetUnitNoMinimap
	
	local function MB_UnitAttacked(_, unitID, attackedFrame)
		blinkingUnits[unitID] = attackedFrame
	end
	
	
	function gadget:Initialize()
		gadgetHandler:AddSyncAction('MB_UnitAttacked', MB_UnitAttacked)
	end
		
	function gadget:Update()
	
		local frame = GetGameFrame()
		
		for unitID, startFrame in pairs(blinkingUnits) do
			
			if GetUnitIsDead(unitID) then
				blinkingUnits[unitID] = nil
			else
				if frame - startFrame > blinkTime then
					blinkingUnits[unitID] = nil
				else
					-- do the blinking
					local t = frame%30
					if t < 10 then
						SetUnitNoMinimap(unitID,false)
					elseif t < 20 then
						SetUnitNoMinimap(unitID,true)
					else
						SetUnitNoMinimap(unitID,false)
					end
				end
			end
		end
	end
end