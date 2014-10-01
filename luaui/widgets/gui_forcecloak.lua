local versionNumber = "1.0"

function widget:GetInfo()
	return {
		name      = "Force cloak",
		desc      = "Force cloak on order",
		author    = "Jools",
		date      = "June 29, 2011",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end


function widget:Initialize()
	if Spring.GetSpectatingState() or Spring.IsReplay() then
		widgetHandler:RemoveWidget()
		return
	end
end

function widget:PlayerChanged(playerID)
if Spring.GetSpectatingState() or Spring.IsReplay() then
		Spring.Log("widget", LOG.INFO, "Force cloak: widget removed for spectators")
		widgetHandler:RemoveWidget()
		return
	end
end

--> "unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams" 
function widget:UnitCommand(uID, uDefID, uT, cmdID, cmdOpts, cmdParams) 
	
	local unitDef   = UnitDefs[uDefID or -1]
	local cp 		= unitDef.customParams or nil
	
	if unitDef and cp and cp.iscommander and cmdID == CMD.CLOAK then
		local cmd0 = Spring.GetUnitCommands(uID,1)
		-- if no orders are given:
		if cmd0 == nil or cmd0[1] == nil then return true end
		-- if orders are given:
		--local cmd1, cmd2
		--cmd1 = cmd0[1]
		--if #cmd0 > 1 then
			--cmd2 = cmd0[2]
		--end
		local cmdCloakIndex = Spring.GetCmdDescIndex(CMD.CLOAK)
		local cloakReq
		if cmdCloakIndex then cloakReq = Spring.GetActiveCmdDesc(cmdCloakIndex).params[1] ~= "1" end
		local isCloaked = Spring.GetUnitIsCloaked(uID)
		
		local cmd0ID = cmd0[1].id
		local cmd0Par = cmd0[1].params
		--local cmd1ID = cmd1.id
		--local cmd2ID = cmd2.id
		--local vx,vy,vz = Spring.GetUnitVelocity(uID)
		
		if isCloaked or (not cloakReq) then return true end --user issues decloak command	
		
		if cmd0ID ~= CMD.MOVE and cmd0ID ~= CMD.CAPTURE and cmd0ID ~= CMD.SELFD then --and (vx == 0 and vy == 0 and vz == 0) then --commands that dont require decloak
			--Spring.Echo("Widget:Forcing cloak")
			Spring.GiveOrderToUnit(uID,CMD.INSERT,{0,CMD.WAIT,0,0},{"alt"})
			--Spring.GiveOrderToUnit(uID,CMD.MOVE,{50,50,50},{})
			--Spring.GiveOrderToUnit(uID,CMD.STOP,{},{})
		end
		
	end
end