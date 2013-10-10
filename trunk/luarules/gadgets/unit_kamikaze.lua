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
local Echo 									= Spring.Echo

local kamikazeUnits = {}

if (gadgetHandler:IsSyncedCode()) then

	--SYNCED
	
	local GetUnitDefID							= Spring.GetUnitDefID
	local GiveOrderToUnit						= Spring.GiveOrderToUnit
	local GetTeamUnitsByDefs					= Spring.GetTeamUnitsByDefs
	local GetTeamList							= Spring.GetTeamList
	local GetUnitPosition						= Spring.GetUnitPosition
	local GetFeaturePosition					= Spring.GetFeaturePosition
	local GetUnitCommands						= Spring.GetUnitCommands
	local ta_insert								= table.insert
	local m_abs									= math.abs

	function gadget:Initialize()
		for id,unitDef in pairs(UnitDefs) do
			if unitDef.canKamikaze then
				ta_insert(kamikazeUnits,id)
			end
		end
	end
		
	function gadget:GameFrame(frame)
	
		if frame%8 == 0 then
			for _, teamID in pairs (GetTeamList()) do
				for _, uID in pairs (GetTeamUnitsByDefs(teamID, kamikazeUnits)) do
					
					local cmdlist = GetUnitCommands(uID)
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
						elseif #cmd.params == 1 then
							local objID = cmd.params[1]
							ax, ay, az = GetUnitPosition(objID)
							if not ax or ax < 0 then
								ax, ay, az = GetFeaturePosition(objID)
							end
						end
						
						if ax and ay and az and ax >= 0 and az >= 0 then -- dont check y
							local x,y,z = GetUnitPosition(uID)
							if m_abs(ax-x) <= 10 and m_abs(az - z) <= 10 then
								Spring.DestroyUnit(uID,true)
							end
						end
					end
				end
			end
		end
	end
	
else

end		
