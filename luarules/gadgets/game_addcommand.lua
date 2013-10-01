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
local CMD_UPGRADE_MEXX						= 31244 
local SetCustomCommandDrawData				= Spring.SetCustomCommandDrawData

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local CMD_GUARD 							= CMD.GUARD
local Echo 									= Spring.Echo
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

	gadgetHandler:RegisterCMDID(CMD_AREA_GUARD)
	gadgetHandler:RegisterCMDID(CMD_UPGRADE_MEXX)
	Spring.AssignMouseCursor("Guardprotect", "cursorprotect", true, false)
	
	local result = SetCustomCommandDrawData(CMD_AREA_GUARD, CMDTYPE.ICON_UNIT_OR_AREA, {1,0,0,0.8},true)
	--Echo("Editing custom draw data: ",result)
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
--UNSYNCED
end