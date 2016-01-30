
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
local TurnRadiuses		= {}
local GunshipDefs		= {}
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

	local version = Game.version
	if not(version > "100" and version:sub(1,1) == "1") then
		gadgetHandler:RemoveGadget()
		return
	end
	
	for id,unitDef in pairs(UnitDefs) do
		if unitDef.canFly then
			AirDefs[id] = true
		end
		--Echo("Pad check:",unitDef.name,unitDef.isAirBase)
		if unitDef.isAirBase then
			RepairPadHeight[id] = Spring.GetUnitDefDimensions(id)["maxy"]
			RepairpadList[#RepairpadList+1] = id
		--Echo("Repair pad:",id,unitDef.name)
		end
		
	end
	gadgetHandler:RegisterCMDID(CMD_REFUEL)
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local teamID = Spring.GetUnitTeam(unitID)
		local unitDefID = GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

local function CalculateAngle(a1,a2,b1,b2)
	--Echo("Vectors:",a1,a2,b1,b2)
	
	local angle = math.atan2 (a1*b2-a2*b1,a1*b1+a2*b2) 
	local dec	= angle/(2*math.pi)*360
	dec = dec >= 0 and dec or dec + 360
	dec = dec <= 180 and dec or 360 - dec
	--Echo("Angle:",math.floor(dec))
	return math.floor(dec)
end

local function CalculateDeviation(a1,a2,b1,b2)
	--Echo("Vectors:",a1,a2,b1,b2)
	
	local angle = math.atan2 (a1*b2-a2*b1,a1*b1+a2*b2)
	local dec	= angle/(2*math.pi)*360
	--Echo("Dev=",dec)
	return math.floor(dec)
end


local function CalculateDeviation2(a1,a2,b1,b2)
	--Echo("Vectors:",a1,a2,b1,b2)
	
	local angle = math.atan2 (a1*b2-a2*b1,a1*b1+a2*b2)
	return angle
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
		--Echo(unitID .. " landed on:",padID,PieceList[padID][pieceID][1],"Q:",#PadQueue[padID])
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
--Echo("Refuel:",unitID)
  if (AirDefs[unitDefID]) and not PlaneQueue[unitID] then
--Echo("--------------------> Unit:",unitID)
	local pads = Spring.GetTeamUnitsByDefs(teamID,RepairpadList)
	local distance = math.huge
	local padID, pieceID
	
	if not TurnRadiuses[unitDefID] then
		TurnRadiuses[unitDefID] = UnitDefs[unitDefID].turnRadius
		--Echo("Turnradius:",UnitDefs[unitDefID].name,TurnRadiuses[unitDefID],UnitDefs[unitDefID].turnRate)
	end
	
	GunshipDefs[unitDefID] = UnitDefs[unitDefID].hoverAttack
	
	for j,uID in pairs(pads) do -- find a free repair pad
	--Echo("-------------------------------------------")
	--Echo("Checking pad-base:",j,uID,UnitDefs[GetUnitDefID(uID)].name)
		local this_distance = Spring.GetUnitSeparation(unitID,uID) or math.huge
		
		if not PieceList[uID] then
			PieceList[uID] = {}
			for name, number in pairs (Spring.GetUnitPieceMap(uID)) do
				if name:find('pad') then
					PieceList[uID][#PieceList[uID]+1] = {name, number, nil} -- third variable is occupied state	
				end
			end
		end
		
		
		--Echo("Pad status:",UnitDefs[Spring.GetUnitDefID(uID)].name,#PadQueue[uID])
		if this_distance < distance then
			local occupant = ""
			
			for i,data in pairs(PieceList[uID]) do -- find a free spot
				--Echo("Checking pad:",i,data[3] and "Taken" or "---")
				if data[3] then -- occupied
					occupant = occupant.."-"..data[3]
					--Echo("Occupied by:",UnitDefs[GetUnitDefID(data[3])].name)
				else
					pieceID = i
					PieceList[uID][pieceID]	= {data[1],data[2],unitID}
					padID = uID
					distance = this_distance
					break;
				end
			end
			--Echo("Occupied by:",occupant)
		end
		if padID then 
			--Echo("Pad found for:",UnitDefs[unitDefID].name," ==> ",padID,PieceList[uID][1],PieceList[uID][2])
			break;
		end
	end
	
	if not padID then
		--Echo("No base found for:",unitID,UnitDefs[unitDefID].name)
	end
	
	if padID then
		table.insert(PadQueue[padID],{unitID,pieceID})
		local h = RepairPadHeight[Spring.GetUnitDefID(padID)]
		local x,y,z = Spring.GetUnitPosition(padID)
		local ux,_,uz = Spring.GetUnitPosition(unitID)
		local pieceName = PieceList[padID][pieceID][1]
		local bvx, bvz = x-ux, z-uz
		local pvx,_,pvz = Spring.GetUnitDirection(padID)
		
		local angle = CalculateAngle(bvx,bvz,pvx,pvz)
		PlaneQueue[unitID] = {padID,pieceID}
		
		--Echo(unitID," is landing on:",UnitDefs[Spring.GetUnitDefID(padID)].name,pieceName,distance,angle)
		
		if angle < 45 then
			Spring.SetUnitLandGoal(unitID, x, y+h, z)
		else
			local x1 = x - 500*pvx
			local y1 = y + 200
			local z1 = z - 500*pvz
			Spring.SetUnitMoveGoal(unitID,x1,y1,z1)
		end
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
	local unitDefID = Spring.GetUnitDefID(unitID)
	local x1 = x+500*vx
	local y1 = y + 200
	local z1 = z + 500*vz
	
	local b0 = Spring.TestMoveOrder(unitDefID,  x1, y1, z1, 0.0, 0.0, 0.0,  true, true, true)
	if not b0 then
		local loops = 0
		repeat
			x1 = x + math.random(-500,500)
			y1 = y+200
			z1 = z+ math.random(-500,500)
			b0 = Spring.TestMoveOrder(unitDefID,  x1, y1, z1, 0.0, 0.0, 0.0,  true, true, true)
			loops = loops +1
		until b0 or loops > 15
	end
		
	--local dist = ((x1-x)*(x1-x)+(y1-y)*(y1-y)+(z1-z)*(z1-z))^0.5
		
	--Spring.MarkerAddPoint (x,y,z,"P1")
	--Spring.MarkerAddPoint (x1,y1,z1,"P4")
	--Echo("Dist:",dist)
	--Spring.SetUnitMoveGoal(unitID,x1,y1,z1)
	Spring.SetUnitLandGoal(unitID, x1, y1+100, z1)
	

end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function WayPoint3()

end

function gadget:GameFrame(frame)
	
	if frame%32 == 0 then
		
		for padID, Queue  in pairs(PadQueue) do
			for pieceID,data in pairs(Queue) do
				local unitID = data[1]
				local pieceID = data[2]
						
				if unitID and Spring.ValidUnitID(unitID) and not LandedUnits[unitID] then
					local distance = Spring.GetUnitSeparation(unitID,padID)
					local x,y,z = Spring.GetUnitPosition(padID)
					
					local pieceNum	= PieceList[padID][pieceID][2]					
					local poff = Spring.GetUnitPieceInfo(padID,pieceNum)["offset"]
					
					
					--Echo("Pos1:",pmin[1],pmin[2],pmin[3])
					--Echo("Pos2:",pmax[1],pmax[2],pmax[3])
					
					
					local px = x + poff[1]/2
					local pz = z + poff[3]/2
					
					 -- for i, num in pairs(Spring.GetUnitPieceList(padID)) do
					
						 -- local pInfo = Spring.GetUnitPieceInfo(padID,i)
						 -- Echo("Piece:",i,num,pInfo)
						 -- pInfo = pInfo or {}
						 -- for i,v in pairs(pInfo) do
							-- if type(v) == type({}) then
								-- for u,w in pairs(v) do
									-- Echo("Info---->:",i,u,w)
								-- end
							-- else
								-- Echo("Info:",i,v)
							 -- end
						 -- end
					 -- end
					
					--Echo("Pos:",pieceID,pieceNum,x,pvx,y,py,z,pvz)
					
					local udid	= GetUnitDefID(unitID)
					local ux,_,uz = Spring.GetUnitPosition(unitID)
					local bvx, bvz = x-ux, z-uz
					local pvx,_,pvz = Spring.GetUnitDirection(padID)
					local movementAngle = CalculateAngle(bvx,bvz,pvx,pvz) 	-- angle between unit movement vector and base facing
					local uvx,_,uvz = Spring.GetUnitDirection(unitID)						
					local facingAngle = CalculateAngle(uvx,uvz,pvx,pvz) 	-- facingAngle between unit facing and base facing
					local turnrad = TurnRadiuses[udid]
					local L1 = 300 + 0.33 * turnrad
					local L2 = GunshipDefs[udid] and 500 or 3.0 * turnrad
					local P1Turn = GunshipDefs[udid] and 100 or 350
					local P2Turn = GunshipDefs[udid] and 100 or 250
					
					local p0 = {px, y+25, pz}
					local p1 = {px - L1*pvx, y+60, pz-L1*pvz}
					local p2 = {px - L2*pvx, y+200, pz-L2*pvz}
					
					local dev = CalculateDeviation(bvx,bvz,pvx,pvz)
					local dev2 = CalculateDeviation2(bvx,bvz,pvx,pvz)
					local vP = {-pvz,0,pvx}
					local vE = {vP[1]*distance*math.tan(dev2),0,vP[3]*distance*math.tan(dev2)}
										
					local pC = {p0[1]-vE[1],y+60,p0[3]-vE[3]}
					
					
					if (distance > 300 or movementAngle > 180) and not GunshipDefs[udid] then
						-- not close to approach yet
						if movementAngle < 30 and facingAngle < 30 + 35 * distance/turnrad  then	
							-- either land or prepare point
							local distP1 = ((ux-p1[1])*(ux-p1[1])+(uz-p1[3])*(uz-p1[3]))^0.5
							if distP1 > P1Turn and distance > P1Turn then
								if movementAngle < 30 then
									--waypoint Correction
									Spring.SetUnitLandGoal(unitID,pC[1], pC[2],pC[3])
								else
									-- land goal
									Spring.SetUnitLandGoal(unitID, p0[1], p0[2],p0[3],10)
									local vx,vy,vz = Spring.GetUnitVelocity(unitID)
									Spring.SetUnitVelocity(unitID,0.75*vx,0.75*vy,0.75*vz)
									--Echo("Set land goal B:",movementAngle, facingAngle,distance,"P1:",distP1)
								end
							else
								-- land goal
								Spring.SetUnitLandGoal(unitID, p0[1], p0[2],p0[3],10)
								local vx,vy,vz = Spring.GetUnitVelocity(unitID)
								Spring.SetUnitVelocity(unitID,0.75*vx,0.75*vy,0.75*vz)
								--Echo("Set land goal A:",movementAngle, facingAngle,distance,"P1:",distP1)
								--Spring.MarkerAddPoint (p0[1], p0[2],p0[3],"P")
							end
						else
							-- waypoint further
							local distP2 = ((ux-p2[1])*(ux-p2[1])+(uz-p2[3])*(uz-p2[3]))^0.5
							
							if distP2 < P2Turn  then
								--waypoint P1
								Spring.SetUnitLandGoal(unitID,p1[1], p1[2],p1[3])
								--Echo("Set waypoint 1B:",movementAngle, facingAngle,distance,"P2:",distP2)
							else
								--waypoint P2
								Spring.SetUnitLandGoal(unitID,p2[1], p2[2],p2[3])
								
								--Echo("Set  waypoint 2:",movementAngle, facingAngle,distance,"P2:",distP2)
							end
						end
					else
						local vx,vy,vz = Spring.GetUnitVelocity(unitID)
						Spring.SetUnitVelocity(unitID,0.5*vx,0.5*vy,0.5*vz)
						Spring.SetUnitLandGoal(unitID, p0[1], p0[2],p0[3],10)
						--Echo("Set land goal B:",movementAngle, facingAngle,distance)
						if distance < 150 and movementAngle < 180 and not GunshipDefs[udid] then
							if facingAngle > 15 then
								--Echo("Aborted landing:",unitID,movementAngle,facingAngle,distance)
								UnitHeadOff(unitID,padID)
							end
						end
						
						if distance < 60 and pieceID then
							UnitLanded(unitID, padID, pieceID) 
						end
					end
				end
			end
		end
	end
	
end

function gadget:UnitCmdDone(unitID, unitDefID, unitTeam, cmdID, cmdTag, cmdParams, cmdOpts)
	
	if cmdID == CMD.REPAIR and LandedUnits[cmdParams[1]] then
		local padID = unitID
		local unitID = cmdParams[1]
		local pieceID = LandedUnits[unitID][2]
		--Echo("Repairs done:",padID,unitID,pieceID)
		
		
		local health, maxHP =  Spring.GetUnitHealth(unitID)
		
		if health == maxHP then
			PlaneQueue[unitID] = nil
		--Echo("Piecelist status before:",padID)
			
			for i,data in pairs(PieceList[padID]) do
			--Echo("Pad:", i, data[1], data[2], data[3])
			end
			
			PieceList[padID][pieceID][3] = nil -- not occupied
			
			
		--Echo("After--->")
			for i,data in pairs(PieceList[padID]) do
			--Echo("Pad:", i, data[1], data[2], data[3])
			end
			
			for i,data in pairs(PadQueue[padID]) do
				if data[1] == unitID then
					table.remove(PadQueue[padID],i)
					--Echo("Removed:",unitID,padID,pieceID)
				end
			end
			
			LandedUnits[unitID] = nil
			--Echo("Detaching unit:",unitID)
			Spring.UnitDetach(unitID)
			Spring.SetUnitVelocity(unitID,0,4,0)
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

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, _, _, _)
	
	if RepairPadHeight[unitDefID] then
		PadQueue[unitID] = nil
	end
	
	if PlaneQueue[unitID] then
		local padID = PlaneQueue[unitID][1]
		local pieceID = PlaneQueue[unitID][2]
		
		for i,data in pairs(PadQueue) do
			if data[1] == unitID then
				table.remove(PadQueue[padID],i)
			--Echo("Removed:",unitID,padID,pieceID)
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
