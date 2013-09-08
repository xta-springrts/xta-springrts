local versionNumber = "1.2"

function gadget:GetInfo()
	return {
	name = "Add commands",
	desc = "Add custom commands to build menu",
	author = "Jools",
	date = "Jun, 2013",
	license = "tango",
	layer = 2,
	enabled = true,
	}
end

-- Shared SYNCED/UNSYNCED

local CMD_AREA_GUARD 						= 14001
local SetCustomCommandDrawData				= Spring.SetCustomCommandDrawData
local Echo 									= Spring.Echo

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local CMD_GUARD 							= CMD.GUARD
local EditUnitCmdDesc						= Spring.EditUnitCmdDesc
local FindUnitCmdDesc						= Spring.FindUnitCmdDesc
local InsertUnitCmdDesc						= Spring.InsertUnitCmdDesc
local GetUnitDefID							= Spring.GetUnitDefID


local areaGuardCmd = {
id      = CMD_AREA_GUARD,
name    = "Guard",
action  = "areaguard",
cursor  = 'Guard',
type    = CMDTYPE.ICON_UNIT_OR_AREA,
tooltip = "Guard the unit or units. ALT: distribute to squadrons, ALT+CTRL: persistent squadrons",
hidden	= true,
}

function gadget:Initialize()

	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, team)
	end
end

function gadget:UnitCreated(unitID, unitDefID, team)
	local uD = UnitDefs[unitDefID]
	--Echo(uD.canGuard,uD.canMove,uD.canAttack, uD.canRepair)
	if uD.canGuard then
		InsertUnitCmdDesc(unitID, 75, areaGuardCmd)
	end
end

else 

--------------
-- UNSYNCED --
--------------

	function gadget:Initialize()
		local result = Spring.SetCustomCommandDrawData(CMD_AREA_GUARD,"Guard", {1,0,0,0.8})
		Echo("Editing custom draw data: ",result)
	end
end