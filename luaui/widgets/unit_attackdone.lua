
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Fly after attack",
    desc      = "Aircraft fly or return to base after attack if no targets",
    author    = "Jools",
    date      = "Feb, 2016",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end


local GetUnitDefID    	= Spring.GetUnitDefID
local Echo				= Spring.Echo
local GiveOrderToUnit	= Spring.GiveOrderToUnit
local GetGameFrame		= Spring.GetGameFrame
local ValidUnitID		= Spring.ValidUnitID
local GetUnitCommands	= Spring.GetUnitCommands

local AirDefs 			= {}
local homePos			= {}
local FlyingUnits		= {}
local CMD_REFUEL		= 34570
local goToBase			= false
local mapDist			= nil
local flyTime			= 120*30 -- 2 mins
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function Distance(p1x,p1z,p2x,p2z)
	return ((p1x-p2x)*(p1x-p2x)+(p1z-p2z)*(p1z-p2z))^0.5
end

function widget:Initialize()

	for id,unitDef in pairs(UnitDefs) do
		if unitDef.canFly then
			AirDefs[id] = true
		end
	end
	mapDist = Distance(0, 0, Game.mapSizeX, Game.mapSizeZ)
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	local x,y,z = Spring.GetUnitPosition(unitID)
	homePos[unitID] = {x,y,z}
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	homePos[unitID] = nil
	FlyingUnits[unitID] = nil
end

function widget:GameFrame(frame)
	if frame%60 == 0 then
		for unitID,flyFrame in pairs(FlyingUnits) do
			if frame > flyFrame + flyTime then
				GiveOrderToUnit(unitID, CMD.IDLEMODE, { 1 }, { })
				FlyingUnits[unitID] = nil
			end
		end
	end	
end


function widget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag, cmdParams, cmdOpts)
	
	if AirDefs[unitDefID] and (cmdID == CMD.ATTACK) then
		local cmds = GetUnitCommands(unitID,1)
		
		if not cmds[1] then
			local x,y,z = homePos[unitID][1],homePos[unitID][2],homePos[unitID][3]
			if x and y and z then
				if goToBase then	
					GiveOrderToUnit(unitID,CMD.MOVE,{x,y,z},{})
				else
					if ValidUnitID(unitID) then
						local dist = Distance(x,z,homePos[unitID][1],homePos[unitID][3])
						local frame = GetGameFrame()
						
						if dist/mapDist > 0.25 then
							GiveOrderToUnit(unitID, CMD.IDLEMODE, { 0 }, { })  -- set to fly
							GiveOrderToUnit(unitID, CMD.FIGHT, { x,y,z }, { }) -- otherwise it will still land
							FlyingUnits[unitID] = frame
						end
					end
				end
			end
		end
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
