local versionNumber = "2.0"

function widget:GetInfo()
	return {
	name = "Area guard XTA",
	desc = "Guard units in selected area",
	author = "Jools",
	date = "Jun, 2013",
	license = "tango",
	layer = 1,
	enabled = true,
	handler = true, --access to handler
	}
end
local CMD_AREA_GUARD 						= 14001
local Echo 									= Spring.Echo
local GetSelectedUnits						= Spring.GetSelectedUnits
local CMD_GUARD 							= CMD.GUARD
local CMD_REPAIR 							= CMD.REPAIR
local CMD_INSERT							= CMD.INSERT
local CMD_OPT_SHIFT							= CMD.OPT_SHIFT
local CMD_STOP								= CMD.STOP
local GetUnitSeparation						= Spring.GetUnitSeparation
local GetUnitDefID							= Spring.GetUnitDefID
local GetUnitHealth							= Spring.GetUnitHealth
local GiveOrderToUnit						= Spring.GiveOrderToUnit
local PlaySoundFile							= Spring.PlaySoundFile
local GetUnitsInCylinder 					= Spring.GetUnitsInCylinder
local GetUnitTeam							= Spring.GetUnitTeam
local AreTeamsAllied						= Spring.AreTeamsAllied
local altDown 								= false
local ctrlDown 								= false
local squadron 								= {} -- squadron[unitID] = array. Table by source units containing a list of guarded units
local guardianTable 						= {} -- reverse list
local ta_insert								= table.insert
local ta_sort								= table.sort
local ta_remove								= table.remove
local math_floor							= math.floor
local sndButton								= 'sounds/button9.wav'
local sndButton2							= 'sounds/minesel4.wav'
local hideGuard								= false
 
function widget:Initialize()
	local cmds = widgetHandler.commands
	local n = #(widgetHandler.commands)
	
	for i=1,n do
		if (cmds[i].id == CMD_GUARD) then
			hideGuard = cmds[i].hidden
			cmds[i].hidden = true
			
		elseif (cmds[i].id == CMD_AREA_GUARD) then
			cmds[i].hidden = false
		end
    end
end
	
function widget:Shutdown()
	if not hideGuard then
	
		local cmds = widgetHandler.commands
		local n = #(widgetHandler.commands)
	
		for i=1,n do
			if (cmds[i].id == CMD_GUARD) then
				cmds[i].hidden = false
				
			elseif (cmds[i].id == CMD_AREA_GUARD) then
				cmds[i].hidden = true
			end
		end
	end
end

function widget:CommandsChanged()
    
	local cmds = widgetHandler.commands
	local n = #(widgetHandler.commands)
	
	for i=1,n do
		if (cmds[i].id == CMD_GUARD) then
			cmds[i].hidden = true
		elseif (cmds[i].id == CMD_AREA_GUARD) then
				cmds[i].hidden = false
		end
	end
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_AREA_GUARD then
		local sU = GetSelectedUnits()
		local cmdOptions2 = {}
		
		if (cmdOptions.shift) then ta_insert(cmdOptions2, "shift")   end
		if (cmdOptions.alt)   then ta_insert(cmdOptions2, "alt")   end
		if (cmdOptions.ctrl)  then ta_insert(cmdOptions2, "ctrl")  end
		if (cmdOptions.right) then ta_insert(cmdOptions2, "right") end
	
		if #cmdParams == 1 then
			for _, unitID in ipairs(sU) do
				GiveOrderToUnit(unitID, CMD_GUARD, {cmdParams[1]}, cmdOptions2)
			end
			return true
		else
			GroupGuard(sU,cmdParams, cmdOptions)
			
			if cmdOptions.ctrl and sndButton2 then
				PlaySoundFile(sndButton2)
			end
		
			if cmdOptions.alt and sndButton then
				PlaySoundFile(sndButton)
			end
			return true
		end
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdOpts, cmdParams) 	
	if cmdID == CMD_STOP then
	
		if squadron[unitID] then 
			squadron[unitID] = nil 
			for tID, sID in pairs (guardianTable) do
				if sID == unitID then guardianTable[tID] = nil end
			end
		end
	end
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
	
	local function sortByHP(v1,v2)
		return v1[2] < v2[2]
	end
	
	if guardianTable[unitID] then
		local sID = guardianTable[unitID]
		local ttable = squadron[sID]
		
		local sortedTable = {}
		
		for i, tID in ipairs(ttable) do
			--local tUD = UnitDefs[GetUnitDefID(tID)]
			local damage, maxdamage = GetUnitHealth(tID)
			if damage then
				sortedTable[i] = {tID, damage/maxdamage}
			else
				Echo("Areaguard:Invalid unit-ID for calculating damage")
			end
		end
		
		ta_sort(sortedTable,sortByHP)
		local newTarget = sortedTable[1][1]
		GiveOrderToUnit(sID, CMD_INSERT,{0,CMD_REPAIR,CMD_OPT_SHIFT,newTarget},{"alt"})
	end
	
end

function widget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	
	if guardianTable[unitID] then
		local sID = guardianTable[unitID]
		guardianTable[unitID] = nil
	
		for i,tID in ipairs (squadron[sID]) do
			if tID == unitID then
				ta_remove(squadron[sID],i)
			end
		end
	end
	
	if squadron[unitID] then 
		squadron[unitID] = nil 
		for tID, sID in pairs (guardianTable) do
			if sID == unitID then guardianTable[tID] = nil end
		end
	end
	
	for i,v in pairs (squadron) do
		if #v == 0 then squadron[i] = nil end
	end	
end

function GroupGuard(unitArray,cmdParams, cmdOptions)

	local function sortByDist(v1,v2)
		return v1[2] < v2[2]
	end
	
	guardianTable 	= {}
	squadron		= {}
	
	local altDown = cmdOptions.alt
	local ctrlDown = cmdOptions.ctrl
	
	local x,y,z,radius = unpack(cmdParams)
	
	local targetArray = GetUnitsInCylinder(x,z,radius)
	local sU = unitArray
	
	if sU then
		if altDown then -- give distributed order				
			local squadronList = {} -- squadronList[index] = sourceUnitID, indexed list of squadrons
			local targetTable ={} -- list of units that should be guarded
			
			-- filter out selected units that cannot guard. Unitdef tags are sometimes fucked up, because programmers are by nature lazy. 
			-- (Why are you even reading this, go out in the sun and play with the kids.)
			for _, sID in ipairs(sU) do
				local sUD = UnitDefs[GetUnitDefID(sID)]
				local canAttack = #sUD.weapons > 0 or false
				local canGuard = sUD.canGuard and (sUD.canRepair or sUD.canMove or canAttack) 
				if canGuard then
					squadron[sID] = {}
					squadronList[#squadronList+1] = sID
				end
			end
			
			
			-- filter out selected units from target units
			-- filter out enemy units
			-- filter out buidlings
			local baseUnit = sU[1]
			local sTeam = GetUnitTeam(baseUnit)
			
			for _,tID in ipairs(targetArray) do
				local tUD = UnitDefs[GetUnitDefID(tID)]
				local dist = GetUnitSeparation(baseUnit, tID)
				local tTeam = GetUnitTeam(tID)
				local isMovingUnit = tUD.canMove and (not tUD.isBuilding)
				local areTeamsAllied = AreTeamsAllied(sTeam,tTeam)
				
				if not squadron[tID] and areTeamsAllied and isMovingUnit then 
					targetTable[#targetTable+1] = {tID,dist}
				end
			end
			ta_sort(targetTable, sortByDist)
			
			local nbSource = countIndex(squadron)
			local nbTargets = #targetTable
			local amount = math_floor(nbTargets/nbSource)
			local rest = nbTargets%nbSource
			local rest2 = rest
			local modifier = ""
			
			local thisSq = 1
			local count = 1
			
			for i, array in ipairs(targetTable) do
				local tID = array[1]
				local extra = 0
				if rest > 0 then 
					extra = 1 
				end
				
				local limit = amount+extra
				
				local sID = squadronList[thisSq]
				local ttable = squadron[sID]
				if ttable then 
					ttable[#ttable+1] = tID 
				else
					Echo("Invalid squadron:", i, count, thisSq, limit, extra, tID, sID, rest)
				end
				
				count = count + 1
				if count > limit then
					count = 1
					thisSq = thisSq+1
					if rest > 0 then rest = rest - 1 end
				end					
			end
			
			local fullSquadrons = countItems(squadron)
			
			if ctrlDown and nbTargets > 0 then
				local plural = " "
				if fullSquadrons < nbSource then
					if amount > 0 then plural = "s " end
					Echo("Formed " .. fullSquadrons .. modifier .. " squadrons with " .. amount+1 .. " member"..plural.. "each")
				else				
					if rest2 == 0 then
						if amount > 1 then plural = "s " end
						Echo("Formed " .. fullSquadrons .. modifier .. " squadrons with " .. amount .. " member" ..plural.. "each")
					else
						if amount > 0 then plural = "s " end
						Echo("Formed " .. fullSquadrons .. modifier .." squadrons with " .. amount .. " to " .. amount+1 .. " member" ..plural.."each")
					end
				end
			end
			
			for sID, targets in pairs(squadron) do
				local sUD = UnitDefs[GetUnitDefID(sID)]
				for j, tID in pairs (targets) do					
					GiveOrderToUnit(sID, CMD_INSERT,{-1,CMD_GUARD,CMD_OPT_SHIFT,tID},{"alt"})
					guardianTable[tID] = sID
				end
			end
		else -- not altDown, give order to all selected units to guard all target units
			for i, sID in ipairs(sU) do
				local sTeam = GetUnitTeam(sID)
				for _,tID in ipairs(targetArray) do					
					local tTeam = GetUnitTeam(tID)
					local areTeamsAllied = AreTeamsAllied(sTeam,tTeam)
					if sID ~= tID and areTeamsAllied then
						GiveOrderToUnit(sID, CMD_INSERT,{-1,CMD_GUARD,CMD_OPT_SHIFT,tID},{"alt"})
					end
				end
			end
		end
	end
	-- if not ctrl down, dont make squadrons persistent
	if not ctrlDown then
		guardianTable 	= {}
		squadron		= {}
	end
end
	
function countIndex(tbl)
	local count = 0
	for i, _ in pairs (tbl) do
		if i then
			count = count + 1
		end
	end
	return count
end

function countItems(tbl)
	local count = 0
	for _, item in pairs (tbl) do
		if #item > 0 then
			count = count + 1
		end
	end
	return count
end

function widget:KeyPress(key, mods, isRepeat) 
	if (key == 0x067) and (not isRepeat) and (not mods.ctrl) and not (mods.shift) and (not mods.alt) then --g
		Spring.SetActiveCommand("areaguard")
		return true
	end
	return false
end