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
local CMD_AIRSTRIKE 						= 36001
local Echo 									= Spring.Echo

local airstrikeCmd = {
	id      = CMD_AIRSTRIKE,
	name    = "Attack",
	action  = "airstrike",
	cursor  = "Airstrike",
	type    = CMDTYPE.ICON_UNIT_OR_MAP,
	tooltip = "Order an airstrike on an unit or a position on the ground",
	hidden	= false,
}

if (gadgetHandler:IsSyncedCode()) then

	--SYNCED
	local EditUnitCmdDesc						= Spring.EditUnitCmdDesc
	local FindUnitCmdDesc						= Spring.FindUnitCmdDesc
	local InsertUnitCmdDesc						= Spring.InsertUnitCmdDesc
	local RemoveUnitCmdDesc						= Spring.RemoveUnitCmdDesc
	local GetUnitDefID							= Spring.GetUnitDefID
	local GiveOrderToUnit						= Spring.GiveOrderToUnit
	local ta_insert								= table.insert
	

	function gadget:Initialize()
		gadgetHandler:RegisterCMDID(CMD_AIRSTRIKE)
		Spring.AssignMouseCursor('Airstrike', "cursorairstrike", true, false)
		Spring.SetCustomCommandDrawData(CMD_AIRSTRIKE, 'Airstrike', {0,1,0,.8},true)
	end
		
	function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
		local uD = UnitDefs[GetUnitDefID(unitID)]
		local canBomb = uD.isBomberAirUnit
		
		if canBomb then
			local cmdAttackID = FindUnitCmdDesc(unitID,CMD_ATTACK)
			if cmdAttackID then
				EditUnitCmdDesc(unitID,cmdAttackID,{cursor= 'Airstrike'})
			end
		end
	end
	
else

end		
