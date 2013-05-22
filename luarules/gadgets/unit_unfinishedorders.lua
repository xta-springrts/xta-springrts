function gadget:GetInfo()
  return {
    name      = "Unfinished unit orders",
    desc      = "Prevent some orders to unfinished units",
	version   = "1.0",
    author    = "Jools",
    date      = "Jan, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

local CMD_SELFD 						= CMD.SELFD

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_SELFD then
		local _,_,_,_,progress = Spring.GetUnitHealth(unitID)
		if progress < 1.0 then
			--return false
		end
	end
	return true
end