local versionNumber = "1.0"

function gadget:GetInfo()
	return {
	name = "Airstrikes",
	desc = "Add separate icon for air strikes",
	author = "Jools",
	date = "Oct, 2013",
	license = "tango",
	layer = 2,
	enabled = true,
	}
end

-- Shared SYNCED/UNSYNCED

local CMD_ATTACK 							= CMD.ATTACK
local Echo 									= Spring.Echo
	
if (gadgetHandler:IsSyncedCode()) then

	--SYNCED
	local EditUnitCmdDesc						= Spring.EditUnitCmdDesc
	local FindUnitCmdDesc						= Spring.FindUnitCmdDesc
	local InsertUnitCmdDesc						= Spring.InsertUnitCmdDesc

	function gadget:Initialize()
		Spring.AssignMouseCursor("Airstrike", "cursorairstrike", true, false)
	end

	
else

--UNSYNCED
	
	local GetUnitDefID							= Spring.GetUnitDefID
	local SetMouseCursor						= Spring.SetMouseCursor
	local GetActiveCommand						= Spring.GetActiveCommand
	local GetSelectedUnits						= Spring.GetSelectedUnits
	
	
	function gadget:Update()
		local _, activeCmdID = GetActiveCommand()
		
		if activeCmdID == CMD_ATTACK then
			local sU = GetSelectedUnits()
			local onlyBombers = true 
			
			for i=1, #sU do
				if not UnitDefs[GetUnitDefID(sU[i])].isBomberAirUnit then 
					onlyBombers = false
					break
				end
			end
			if onlyBombers then
				SetMouseCursor("Airstrike")	
			end
		end
	end	
end