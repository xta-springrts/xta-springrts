
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
local CMD_REFUEL 		= 33457
local CMD_EJECT			= 36722
local PadQueue 			= {}
local PlaneQueue		= {}
local LandedUnits		= {}
local WaitingUnits		= {}
local ejectCEG			= "Sparks"

local DEFAULTREPAIRLEVEL	= 0.3
local QUEUEREPAIRLEVEL		= 0.8

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

	Spring.Echo("Min version:",)
	if not(Script.IsEngineMinVersion(101)) then
		Spring.Echo("Repair Pad: not supported with this engine, removing gadget")
		gadgetHandler:RemoveGadget()
		return
	end
	
	for id,unitDef in pairs(UnitDefs) do
		if unitDef.canFly then
			AirDefs[id] = true
		end
		
		if unitDef.isAirBase then
			RepairPadHeight[id] = Spring.GetUnitDefDimensions(id)["maxy"]
			RepairpadList[#RepairpadList+1] = id
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
		
	local angle = math.atan2 (a1*b2-a2*b1,a1*b1+a2*b2) 
	local dec	= angle/(2*math.pi)*360
	dec = dec >= 0 and dec or dec + 360
	dec = dec <= 180 and dec or 360 - dec
	return math.floor(dec)
end

local function CalculateDeviation(a1,a2,b1,b2)
		
	local angle = math.atan2 (a1*b2-a2*b1,a1*b1+a2*b2)
	local dec	= angle/(2*math.pi)*360
	return math.floor(dec)
end

local function CountQueues()
	local padq, planeq, wl = 0,0,0
	
	for _ in pairs(PadQueue) do
		padq = padq + 1 
	end
	
	for _ in pairs(PlaneQueue) do
		planeq = planeq + 1 
	end
	
	for _ in pairs(WaitingUnits) do
		wl = wl+1
	end
	--Echo("Pads:",padq,"Planequeue:",planeq,"Waiting list:",wl)
end

local function ClearTables(padID,planeUnitID, pieceID)	
	-- 1. reset pad queue
	if PadQueue[padID] then
		for pieceID, data in pairs(PadQueue[padID]) do
			local planeID = data[1]
			if planeID == planeUnitID then
				PadQueue[padID][pieceID] = nil
				Spring.CallCOBScript(padID, "UnitTookOff", 0,0)
			end
		end
	end
	
	-- 2. reset plane queue
	PlaneQueue[planeUnitID] = nil
	
	-- 3. reset piece queue
	if PieceList[padID] then
		PieceList[padID][pieceID][3] = nil -- not occupied
	end
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
		--Echo(unitID .. " landed on:",padID,pieceNum,PieceList[padID][pieceID][1],"Q:",#PadQueue[padID])
		Spring.UnitAttach(padID, unitID, pieceNum)
		LandedUnits[unitID] = {padID,pieceID}
		Spring.GiveOrderToUnit(unitID,CMD.ONOFF,{0},{})
		--Spring.GiveOrderToUnit(padID,CMD.REPAIR,{unitID},{})
		Spring.GiveOrderToUnit(padID,CMD.INSERT,{1,CMD.REPAIR,CMD.OPT_SHIFT,unitID},{"alt"})
		
		local cmdDescID = FindUnitCmdDesc(padID, CMD_EJECT)
		Spring.EditUnitCmdDesc(padID,cmdDescID,{disabled= false})
		
		local x,y,z = Spring.GetUnitPosition(padID)
		Spring.PlaySoundFile('Sounds/unit/repair2.wav', 1.0, x, y, z,0,0,0,'battle')
		CountQueues()
		Spring.CallCOBScript(padID, "UnitLanded", 0,0,pieceNum)
	end
end

local function refuelCommand(unitID, unitDefID, cmdParams, teamID)
--Echo("Refuel:",unitID)
  local success = false
  --Echo("RC taken:",unitID,AirDefs[unitDefID],PlaneQueue[unitID],teamID)
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
					--Echo("Added pad:",UnitDefs[GetUnitDefID(uID)].name,name,number)
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
		--Echo("No pad found for:",unitID,UnitDefs[unitDefID].name)
		WaitingUnits[unitID] = true
		return false
	end
	
	if padID and PadQueue[padID] then
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
		success = true
		Spring.CallCOBScript(padID, "PrepareLanding", 0,0)
		--Echo("Called PrepareLanding:",padID)
	else
		--Echo("Pad but no queue:",padID,teamID)
	end
    
	local status
    status = '0'

	UpdateButton(unitID, status)
	return success
	end
end

local function CheckWaitingList()
	
	for unitID in pairs(WaitingUnits) do
		local health,maxhHP = Spring.GetUnitHealth(unitID)
		if health and maxhHP and health/maxhHP < QUEUEREPAIRLEVEL then		
			local unitDefID = GetUnitDefID(unitID)
			local unitTeam = Spring.GetUnitTeam(unitID)
			local success = refuelCommand(unitID, unitDefID, {}, unitTeam)
			--Echo("UHO:",unitID,unitDefID,success)
			if success then
				WaitingUnits[unitID] = nil
			else
				break;
			end
		else
			WaitingUnits[unitID] = nil
		end
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
			local rx = math.random(200,500)
			local rz = math.random(200,500)
			local sign = math.random() > 0.5 and 1 or -1
			x1 = x + sign * rx
			y1 = y+200
			z1 = z+ sign * rz
			b0 = Spring.TestMoveOrder(unitDefID,  x1, y1, z1, 0.0, 0.0, 0.0,  true, true, true)
			loops = loops +1
		until b0 or loops > 15
	end
	Spring.GiveOrderToUnit(unitID,CMD.MOVE,{x1,y1+100,z1},{})
	--Spring.SetUnitLandGoal(unitID, x1, y1+100, z1,200) makes planes land on water
	CheckWaitingList()
	CountQueues()
end

local function EjectUnit(unitID,padID)
	local pieceID = LandedUnits[unitID][2]
	
	if pieceID then
		
		ClearTables(padID,unitID, pieceID)
		LandedUnits[unitID] = nil
		
		--Echo("Detaching unit:",unitID)
		Spring.UnitDetach(unitID)
		Spring.SetUnitVelocity(unitID,0,4,0)
		local x,y,z = Spring.GetUnitPosition(padID)
		
		Spring.SpawnCEG(ejectCEG,x,y,z,0,0,0,1000)
		local cmdDescID = FindUnitCmdDesc(padID, CMD_EJECT)
		Spring.EditUnitCmdDesc(padID,cmdDescID,{disabled= true})
		
		Spring.CallCOBScript(padID, "UnitTookOff", 0,0)
		UnitHeadOff(unitID,padID)
	end
end

function gadget:GameFrame(frame)
	
	if frame%30 == 0 then
		
		for padID, Queue  in pairs(PadQueue) do
			for pieceID,data in pairs(Queue) do
				local unitID = data[1]
				local pieceID = data[2]
				--Echo("GF:","pad:",padID,"piece:",pieceID, "unit:",unitID)
				--Echo("Processing:",padID,unitID,pieceID,Spring.ValidUnitID(unitID),Spring.ValidUnitID(padID))
				
				if not Spring.ValidUnitID(padID) then
					PadQueue[padID] = nil
				elseif not Spring.ValidUnitID(unitID) then					
					ClearTables(padID,unitID, pieceID)
				elseif frame%300 == 0 then
					local health, maxHP =  Spring.GetUnitHealth(unitID)
					if health == maxHP then
						ClearTables(padID,unitID, pieceID)
					end
				end
				
				if unitID and not LandedUnits[unitID] then
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
		local health, maxHP =  Spring.GetUnitHealth(unitID)

		if health == maxHP then
			EjectUnit(unitID,padID)
		else
			Spring.PlaySoundFile('Sounds/unit/repair2.wav', 1.0, x, y, z,0,0,0,'battle')
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	
  if (AirDefs[unitDefID]) then
    AddrefuelCmdDesc(unitID)
    UpdateButton(unitID, '0')
  end
  
	if RepairPadHeight[unitDefID] then
		PadQueue[unitID] = {}
		CheckWaitingList()
	end
	CountQueues()
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	
	-- repair pad died
	if RepairPadHeight[unitDefID] then
		-- 1. reset queue to pad
		PadQueue[unitID] = nil 
		
		-- 2. reset plane queue
		for planeID,data in pairs(PlaneQueue) do
			local padID = data[1]
			--Echo("PQ:",planeID,padID,unitID)
			if padID == unitID then
				PlaneQueue[planeID] = nil
				local udID = GetUnitDefID(planeID)
				local unitTeam = Spring.GetUnitTeam(planeID)
				local success = refuelCommand(planeID, udID, {}, unitTeam)
			end
		end
		
		-- 3. reset queue to pieces
		PieceList[unitID] = nil
	end
	
	--plane died
	if PlaneQueue[unitID] then
		local padID = PlaneQueue[unitID][1]
		local pieceID = PlaneQueue[unitID][2]
		
		ClearTables(padID,unitID,pieceID)
		
		CheckWaitingList()
	end
	
	if WaitingUnits[unitID] then
		WaitingUnits[unitID] = nil
	end
	CountQueues()
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam)
	if (AirDefs[unitDefID]) and not PlaneQueue[unitID] then 
		local repairLevel  = select(8,Spring.GetUnitStates(unitID)) or DEFAULTREPAIRLEVEL
		local health,maxhHP = Spring.GetUnitHealth(unitID)
		--Echo("UD:",unitID,repairLevel,health,maxhHP)
		
		if health and maxhHP and repairLevel and health/maxhHP < repairLevel then
			refuelCommand(unitID, unitDefID, {}, unitTeam)
		end
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if RepairPadHeight[unitDefID] then
		--Echo("UG:",unitID,newTeam)
		PadQueue[unitID] = {} -- clear queue but keep it queable
		
		for planeID,data in pairs(PlaneQueue) do
			local padID = data[1]
			if padID == unitID then
				PlaneQueue[planeID] = nil
				local udID = GetUnitDefID(planeID)
				local unitTeam = Spring.GetUnitTeam(planeID)
				local success = refuelCommand(planeID, udID, {}, unitTeam)
			end	
		end
		
		for pieceID in pairs(PieceList[unitID]) do
			PieceList[unitID][pieceID][3] = nil -- not occupied
		end
		
		CheckWaitingList()
		CountQueues()
	end
	
	if PlaneQueue[unitID] then
		if AreTeamsAllied(newTeam, oldTeam) then
			-- do nothing for now
		else
			local padID = PlaneQueue[unitID][1]
			local pieceID = PlaneQueue[unitID][2]
			
			ClearTables(padID,unitID,pieceID)
			
			CheckWaitingList()
		end
	end
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, _)
  
	if cmdID == CMD_REFUEL then
		refuelCommand(unitID, unitDefID, cmdParams, teamID)  
		return false
	elseif cmdID == CMD.REPAIR then
		if RepairPadHeight[unitDefID] then
			if #cmdParams > 1 or not LandedUnits[cmdParams[1]] then
				return false
			end
		end
	elseif cmdID == CMD_EJECT and RepairPadHeight[unitDefID] then
		local padID = unitID
		if PieceList[padID] then
			for i,data in pairs(PieceList[padID]) do
				local unitID = data[3]
				if unitID and LandedUnits[unitID] then
					EjectUnit(unitID,padID)
					Spring.GiveOrderToUnit(padID,CMD.STOP,{},{})
				end
			end
		end
		return false
	end
  
  return true
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
