
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Repair Pad",
    desc      = "Implements repair pads functionality",
    author    = "thor, Jools",
    date      = "Apr, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--Speed-ups

local GetUnitDefID    	= Spring.GetUnitDefID
local FindUnitCmdDesc 	= Spring.FindUnitCmdDesc
local AreTeamsAllied	= Spring.AreTeamsAllied
local RepairPadHeight 	= {}
local RepairpadList 	= {}
local PieceList			= {}
local Echo				= Spring.Echo
local AirDefs 			= {}
CMD_REFUEL = 33457

local PadQueue 			= {}
local PlaneQueue		= {}
local LandedUnits		= {}

-- local PieceNames		= {
	-- ['arm_air_repair_pad'] 		= {"landpad"},
	-- ['arm_colossus'] 			= {"landpad1"},{"landpad2"},
	-- ['core_air_repair_pad'] 	= {"pad"},
	-- ['core_hive'] 				= {"pad1"},{"pad2"},
	-- ['core_replenisher'] 		= {"pad"},
	-- ['guardian_air_repair_pad'] = {"pad"},
	-- ['lost_air_repair_pad'] 	= {"pad"},
	-- ['lost_giant'] 				= {"pad1"},{"pad2"},
-- }

local refuelCmdDesc = {
  id      = CMD_REFUEL,
  type    = CMDTYPE.ICON_MODE,
  name    = 'Repair Pad',
  cursor  = 'Refuel',
  action  = 'Refuel',
  tooltip = 'Return Immediately to Repair Pad',
  params  = { 'Refuel'}
}
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:Initialize()
	for id,unitDef in pairs(UnitDefs) do
		if unitDef.canFly then
			AirDefs[id] = true
		end
		--Echo("Pad check:",unitDef.name,unitDef.isAirBase)
		if unitDef.isAirBase then
			RepairPadHeight[id] = Spring.GetUnitDefDimensions(id)["maxy"]
			RepairpadList[#RepairpadList+1] = id
			Echo("Repair pad:",id,unitDef.name)
		end
		
	end
	gadgetHandler:RegisterCMDID(CMD_REFUEL)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = Spring.GetUnitTeam(unitID)
		local unitDefID = GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end


local function AddrefuelCmdDesc(unitID)
  if (FindUnitCmdDesc(unitID, CMD_REFUEL)) then
    return  -- already exists
  end
  local insertID = 
    FindUnitCmdDesc(unitID, CMD.CLOAK)      or
    FindUnitCmdDesc(unitID, CMD.ONOFF)      or
    FindUnitCmdDesc(unitID, CMD.TRAJECTORY) or
    FindUnitCmdDesc(unitID, CMD.REPEAT)     or
    FindUnitCmdDesc(unitID, CMD.MOVE_STATE) or
    FindUnitCmdDesc(unitID, CMD.FIRE_STATE) or
    FindUnitCmdDesc(unitID, CMD.AREA_ATTACK) or
    123456 -- back of the pack
  refuelCmdDesc.params[1] = '0'
  Spring.InsertUnitCmdDesc(unitID, insertID + 1, refuelCmdDesc)
end


local function UpdateButton(unitID, statusStr)
  local cmdDescID = FindUnitCmdDesc(unitID, CMD_REFUEL)
  if (cmdDescID == nil) then
    return
  end

  refuelCmdDesc.params[1] = statusStr

  Spring.EditUnitCmdDesc(unitID, cmdDescID, { 
    params  = refuelCmdDesc.params, 
    tooltip = tooltip,
  })
end

local function UnitLanded(unitID, padID, pieceID) 
	local pieceNum = PieceList[padID][pieceID][2]
	if pieceNum then
		Echo(unitID .. " landed on:",padID,PieceList[padID][pieceID][1],"Q:",#PadQueue[padID])
		Spring.UnitAttach(padID, unitID, pieceNum)
		LandedUnits[unitID] = {padID,pieceID}
		--Spring.GiveOrderToUnit(unitID,CMD.STOP,{},{})
		--Spring.GiveOrderToUnit(padID,CMD.REPAIR,{unitID},{})
		Spring.GiveOrderToUnit(padID,CMD.INSERT,{1,CMD.REPAIR,CMD.OPT_SHIFT,unitID},{"alt"})
		
		local x,y,z = Spring.GetUnitPosition(padID)
		Spring.PlaySoundFile('Sounds/unit/repair2.wav', 1.0, x, y, z,0,0,0,'battle')
	end
end

local function refuelCommand(unitID, unitDefID, cmdParams, teamID)

  if (AirDefs[unitDefID]) then
	--Echo("Return to base:",UnitDefs[unitDefID].name)
    --Spring.CallCOBScript(unitID, "Refuel", 0)
    Spring.SetUnitFuel(unitID, 0)

	local pads = Spring.GetTeamUnitsByDefs(teamID,RepairpadList)
	
	--Echo("Repair pads:",#pads)
	local distance = math.huge
	local padID, pieceID
	
	for _,uID in pairs(pads) do -- find a free repair pad
		
		local this_distance = Spring.GetUnitSeparation(unitID,uID) or math.huge
		
		if not PieceList[uID] then
			PieceList[uID] = {}
			for name, number in pairs (Spring.GetUnitPieceMap(uID)) do
				if name:find('pad') then
					PieceList[uID][#PieceList[uID]+1] = {name, number, nil} -- third variable is occupied state	
					--Echo("New piece found:",name, number)
				end
			end
		end
		
		
		--Echo("Pad status:",UnitDefs[Spring.GetUnitDefID(uID)].name,#PadQueue[uID])
		if this_distance < distance then
			Echo("Base found for:",UnitDefs[unitDefID].name,uID,this_distance,distance)
			for i,data in pairs(PieceList[uID]) do -- find a free spot
				Echo("Checking pad:",i,"OCcupied:",data[3])
				if not data[3] then -- not occupied
					pieceID = i
					PieceList[uID][pieceID]	= {data[1],data[2],unitID}
					padID = uID
					distance = this_distance
					Echo("Base and pad found for:",UnitDefs[unitDefID].name,data[1],data[2],uID)
					
					break;
				end
				
			end
			if not padID then
				Echo("No base found for:",unitID,UnitDefs[unitDefID].name)
			end
		end
	end
	if padID then
		table.insert(PadQueue[padID],{unitID,pieceID})
		local h = RepairPadHeight[Spring.GetUnitDefID(padID)]
		local x,y,z = Spring.GetUnitPosition(padID)
		Spring.SetUnitLandGoal(unitID, x, y+h, z)
		local pieceName = PieceList[padID][pieceID][1]
		PlaneQueue[unitID] = {padID,pieceID}
		Echo(unitID," is landing on:",UnitDefs[Spring.GetUnitDefID(padID)].name,pieceName,distance)
		
	end
    
	local status
    status = '0'

	UpdateButton(unitID, status)
	end
end

local function UnitHeadOff(unitID,padID)
	local unitHdg = Spring.GetUnitHeading(unitID)
	local vx,vz = Spring.GetVectorFromHeading(unitHdg)
	local x,y,z = Spring.GetUnitPosition(unitID)
	local x1 = x+500*vx
	local y1 = y + 200
	local z1 = z + 500*vz
	
	local dist = ((x1-x)*(x1-x)+(y1-y)*(y1-y)+(z1-z)*(z1-z))^0.5
	
	Echo("Pos1:",x,y,z)
	Echo("Pos2:",x1,y1,z1)
	Echo("Hdg:",vx,vz)
	
	--Spring.MarkerAddPoint (x,y,z,"P1")
	Spring.MarkerAddPoint (x1,y1,z1,"P2")
	Echo("Dist:",dist)
	Spring.SetUnitMoveGoal(unitID,x1,y1,z1)
	--Spring.SetUnitLandGoal(unitID, x, y+h, z)
	

end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GameFrame(frame)
	
	if frame%16 == 0 then
		for padID, Queue  in pairs(PadQueue) do
			for pieceID,data in pairs(Queue) do
				local unitID = data[1]
				local pieceID = data[2]
				--Echo("PQ:",padID,Queue,data,unitID,pieceID)
			
			
				if unitID and Spring.ValidUnitID(unitID) and not LandedUnits[unitID] then
					local distance = Spring.GetUnitSeparation(unitID,padID)
					local ud = Spring.GetUnitDefID(padID)
					local h = RepairPadHeight[ud]
					local x,y,z = Spring.GetUnitPosition(padID)
					
					Spring.SetUnitLandGoal(unitID, x, y+h, z)
					
					if distance < 100 then
						local unitHdg = Spring.GetUnitHeading(unitID)
						local padHdg = Spring.GetUnitHeading(padID)
											
						if math.abs(unitHdg-padHdg) > 6000 then
							Echo("Aborted landing:",unitID)
							UnitHeadOff(unitID,padID)
						end
					end
					
					--Echo("Repair queue:",padID,unitID,distance)
					
					if distance < 40 and pieceID then
						UnitLanded(unitID, padID, pieceID) 
					end
				end
			end
		end
	end
	
end

function gadget:TeamDied(teamID)
	Echo("Team died:",teamID)
end

function gadget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag, cmdParams, cmdOpts)
	
	if cmdID == CMD.REPAIR and LandedUnits[cmdParams[1]] then
		local padID = unitID
		local unitID = cmdParams[1]
		local pieceID = LandedUnits[unitID][2]
		Echo("Repairs done:",padID,unitID,pieceID)
		
		
		local health, maxHP =  Spring.GetUnitHealth(unitID)
		
		if health == maxHP then
			PlaneQueue[unitID] = nil
			PieceList[padID][pieceID][3] = nil -- not occupied
			
			for i,data in pairs(PadQueue[padID]) do
				if data[1] == unitID then
					table.remove(PadQueue[padID],i)
					Echo("Removed:",unitID,padID,pieceID)
				end
			end
			
			LandedUnits[unitID] = nil
			Echo("Detaching unit:",unitID)
			Spring.UnitDetach(unitID)
			UnitHeadOff(unitID,padID)				
		else
			Spring.PlaySoundFile('Sounds/unit/repair2.wav', 1.0, x, y, z,0,0,0,'battle')
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
  
  if (AirDefs[unitDefID]) then
    AddrefuelCmdDesc(unitID)
    UpdateButton(unitID, '0')
    --RetreatCommand(unitID, unitDefID, { builderInfo[1] }, teamID)
  end
  
	if RepairPadHeight[unitDefID] then
		PadQueue[unitID] = {}
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, _, _, _, preEvent)
	if (preEvent) then return end
	
	if RepairPadHeight[unitDefID] then
		PadQueue[unitID] = nil
	end
	
	if PlaneQueue[unitID] then
		local padID = PlaneQueue[unitID][1]
		local pieceID = PlaneQueue[unitID][2]
		
		for i,data in pairs(PadQueue) do
			if data[1] == unitID then
				table.remove(PadQueue[padID],i)
				Echo("Removed:",unitID,padID,pieceID)
			end
		end
		
		PlaneQueue[unitID] = nil
		PieceList[padID][pieceID][3] = nil -- not occupied
	end
	
end

function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if RepairPadHeight[unitDefID] then
		if AreTeamsAllied(newTeam, oldteam) then
			if not PadQueue[unitID] then
				PadQueue[unitID] = {}
				
			end
		else
			PadQueue[unitID] = nil
		end
	end
	
	if PlaneQueue[unitID] then
		if AreTeamsAllied(newTeam, oldteam) then
			-- do nothing for now
		else
			local padID = PlaneQueue[unitID][1]
			local pieceID = PlaneQueue[unitID][2]
			PadQueue[padID][pieceID] = nil
			
			PlaneQueue[unitID] = nil
			PieceList[padID][pieceID][3] = nil -- not occupied
		end
	end
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, _)
  local returnvalue
  if cmdID ~= CMD_REFUEL then
    return true
  end
  refuelCommand(unitID, unitDefID, cmdParams, teamID)  
  return false
end

function gadget:Shutdown()
  for _, unitID in ipairs(Spring.GetAllUnits()) do
    local cmdDescID = FindUnitCmdDesc(unitID, CMD_REFUEL)
    if (cmdDescID) then
      Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
    end
  end
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
