local versionNumber = "1.0"

function gadget:GetInfo()
	return {
	name = "Kamikaze",
	desc = "Make kamikaze units explode on attack target",
	author = "Jools",
	date = "Oct, 2013",
	license = "tango",
	layer = 2,
	enabled = true,
	}
end

-- Shared SYNCED/UNSYNCED

local CMD_ATTACK 							= CMD.ATTACK
local CMD_SELFD								= CMD.SELFD
local CMD_WAIT								= CMD.WAIT
local Echo 									= Spring.Echo

if (gadgetHandler:IsSyncedCode()) then

	--SYNCED
	
	local GetUnitCommands						= Spring.GetUnitCommands
	local GetUnitPosition						= Spring.GetUnitPosition
	local DestroyUnit							= Spring.DestroyUnit
	local m_abs									= math.abs
	local kamikazeUnits 						= {}

	function gadget:Initialize()
		for id,unitDef in ipairs(UnitDefs) do
			if unitDef.canKamikaze then
				kamikazeUnits[id] = true
			end
		end
	end
			
	function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
		if cmdID == CMD_WAIT and kamikazeUnits[unitDefID] then
			local cmdlist = GetUnitCommands(unitID,1)
			local cmd = cmdlist[1]
			
			if cmd and cmd.id == CMD_ATTACK then
				local ax, ay,az
				if #cmd.params == 4 then
					ax = cmd.params[1]
					ay = cmd.params[2]
					az = cmd.params[3]
				elseif #cmd.params == 3 then
					ax = cmd.params[1]
					ay = cmd.params[2]
					az = cmd.params[3]
				end
			
				if ax and ay and az and ax >= 0 and az >= 0 then -- don't check y
					local x,_,z = GetUnitPosition(unitID)
					if m_abs(ax-x) <= 15 and m_abs(az - z) <= 15 then
						DestroyUnit(unitID,true)
					end
				end
			end
		end
		return true
	end
end		
