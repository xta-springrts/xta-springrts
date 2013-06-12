local versionNumber = "1.1"

function widget:GetInfo()
	return {
	name = "Area guard",
	desc = "Guard units in selected area",
	author = "Jools",
	date = "Jun, 2013",
	license = "tango",
	layer = 1,
	enabled = false
	}
end

local sndButton								= 'sounds/button9.wav'
local sndButton2							= 'sounds/minesel4.wav'
local userDrags 							= false
local Echo 									= Spring.Echo
local GetActiveCommand						= Spring.GetActiveCommand
local CMD_GUARD 							= CMD.GUARD
local CMD_INSERT							= CMD.INSERT
local CMD_OPT_SHIFT							= CMD.OPT_SHIFT
local CMD_STOP								= CMD.STOP
local GetUnitPosition 						= Spring.GetUnitPosition
local GetFeaturePosition					= Spring.GetFeaturePosition
local GetSelectedUnits						= Spring.GetSelectedUnits
local GetUnitSeparation						= Spring.GetUnitSeparation
local GetUnitDefID							= Spring.GetUnitDefID
local GetUnitHealth							= Spring.GetUnitHealth
local GiveOrderToUnit						= Spring.GiveOrderToUnit
local PlaySoundFile							= Spring.PlaySoundFile
local GetUnitsInCylinder 					= Spring.GetUnitsInCylinder
local TraceScreenRay						= Spring.TraceScreenRay
local SendCommands							= Spring.SendCommands
local SelectUnitArray						= Spring.SelectUnitArray
local mouse0 								= {}
local mouse1 								= {}
local radius 								= 0
local altDown 								= false
local ctrlDown 								= false
local squadron 								= {} -- squadron[unitID] = array. Table by source units containing a list of guarded units
local guardianTable 						= {} -- reverse list
local ta_sort								= table.sort
local ta_remove								= table.remove
local math_floor							= math.floor

function drawBorder(x0, y0, x1, y1, width)
	 gl.Rect(x0, y0, x1, y0 + width)
	 gl.Rect(x0, y1, x1, y1 - width)
	 gl.Rect(x0, y0, x0 + width, y1)
	 gl.Rect(x1, y0, x1 - width, y1)
end

function widget:DrawWorld()
	--Echo(userDrags)
	if userDrags and mouse1 and mouse1[1] then
		local dist = math.sqrt( (mouse1[1]-mouse0[1])^2 + (mouse1[3]-mouse0[3])^2)
		radius = dist
		--Echo(dist)
		local x, y, z = mouse0[1],mouse0[2],mouse0[3]
		local txt = ""
		if altDown then 
			if ctrlDown then
				txt = "Persistent squadrons: draw circle to select units"
			else
				txt = "Squadron guard: Hold ctrl to make squadrons persistent"
			end
		else
			txt = "Area guard: Hold alt to distribute guard order into squadrons"
		end
		gl.PushMatrix()
		gl.Translate(x,y,z)
		gl.Billboard()
		gl.Color(0.2,0.3,0.8,0.5)
		gl.LineWidth(3)
		--gl.Rect(mouse0[1],mouse0[3],mouse1[1],mouse1[3])
		--gl.BeginEnd(GL.TRIANGLE_FAN, 2, mouse0[1], mouse0[3], dist)
		gl.Text(txt,0,0,28, 'cv')
		gl.PopMatrix()
		gl.DrawGroundCircle(mouse0[1],mouse0[2],mouse0[3],dist,64)
	end
end
	
function postProcess()
	local selectedUnits = GetSelectedUnits()
	SendCommands("deselect")
	SelectUnitArray(selectedUnits)
	--SendCommands("mouse3")
	--Echo("alt/ctrl:",altDown, ctrlDown)
	if ctrlDown and sndButton2 then
		PlaySoundFile(sndButton2)
	end
	
	if altDown and sndButton then
		PlaySoundFile(sndButton)
	end
end
	
function getCount(tbl)
	local count = 0
	for i, item in pairs (tbl) do
		if item ~= nil then
			count = count + 1
		end
	end
	return count
end

function GroupGuard()

	local function sortByDist(v1,v2)
		return v1[2] < v2[2]
	end

	if radius > 0 then
		
		local dist = math.sqrt( (mouse1[1]-mouse0[1])^2 + (mouse1[3]-mouse0[3])^2)
		local targetArray = GetUnitsInCylinder(mouse0[1],mouse0[3],radius)
		
		local sU = GetSelectedUnits()
	
		if sU then
			if altDown then -- give distributed order				
				
				local squadronList = {} -- squadronList[index] = sourceUnitID, indexed list of squadrons
				local targetTable ={} -- list of units that should be guarded
				
				-- filter out selected units that cannot guard
				for _, sID in ipairs(sU) do
					local sUD = UnitDefs[GetUnitDefID(sID)]
					local canAttack = #sUD.weapons > 0 or false
					local canGuard = sUD.canRepair or sUD.canMove or canAttack
					--Echo(sUD.name, " canGuard:", canGuard, sUD.canRepair, sUD.canMove, canAttack)
					if canGuard then
						squadron[sID] = {}
						squadronList[#squadronList+1] = sID
					end
				end
				local nbSource = getCount(squadron)
				
				--filter out selected units from target units
				local baseUnit = sU[1]
				
				for _,tID in ipairs(targetArray) do
					local tUD = UnitDefs[GetUnitDefID(tID)]
					local dist = GetUnitSeparation(baseUnit, tID)
					if not squadron[tID] then 
						targetTable[#targetTable+1] = {tID,dist}
					end
				end
				ta_sort(targetTable, sortByDist)
				
				local amount = math_floor(#targetTable/nbSource)
				local rest = #targetTable%nbSource
				local modifier = ""
				if ctrlDown then modifier = " persistent" end
				
				if rest == 0 then
					Echo("Formed " .. nbSource .. modifier .. " squadrons with " .. amount .. " members each")
				else
					Echo("Formed " .. nbSource .. modifier .." squadrons with " .. amount .. " to " .. amount+1 .. " members each")
				end
				local thisSq = 1
				local count = 1
				-- 
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
						Echo("Invalid squadron:", i, count, thisSq, limit, extra, tID, sID)
					end
					
					count = count + 1
					if count > limit then
						count = 1
						thisSq = thisSq+1
						if rest > 0 then rest = rest - 1 end
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
				for _, sID in ipairs(sU) do
					for _,tID in ipairs(targetArray) do
						if sID ~= tID then
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
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
	
	local function sortByHP(v1,v2)
		return v1[2] < v2[2]
	end
	
	if guardianTable[unitID] then
		local sID = guardianTable[unitID]
		local ttable = squadron[sID]
		
		local stable = {}
		
		for i, tID in ipairs(ttable) do
			--local tUD = UnitDefs[GetUnitDefID(tID)]
			local damage, maxdamage = GetUnitHealth(tID)
			if damage then
				stable[i] = {tID, damage/maxdamage}
			else
				Echo("Areaguard:Invalid unit-ID for calculating damage")
			end
		end
		
		ta_sort(stable,sortByHP)
		GiveOrderToUnit(sID, CMD_STOP,{},{})
		for i, array in ipairs(stable) do
			local tID = array[1]
			local hp = array[2]
			GiveOrderToUnit(sID, CMD_INSERT,{-1,CMD_GUARD,CMD_OPT_SHIFT,tID},{"alt"})
		end
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

function widget:MousePress(mx,my,button)
	if button == 1 and not userDrags then
		local _, activeCmdID = GetActiveCommand()
		if activeCmdID == CMD_GUARD then
			local type, data  = TraceScreenRay(mx,my)
			if (type ~= 'unit' and type ~= 'feature')  then
				-- Echo(type,data)
				userDrags = true
				mouse0 = data
				return true
			else
				local ufID = data
				if type == 'unit' then
					mouse0[1], mouse0[2],mouse0[3] = GetUnitPosition(ufID)
				elseif type == 'feature' then
					mouse0[1], mouse0[2],mouse0[3] = GetFeaturePosition(ufID)
				end
				--userDrags = true
				return true
			end
		end
	end
	return false
end

function widget:CommandNotify(id, params, options)	
	--Echo(id,params,options)
end

 function widget:MouseRelease(mx,my,button)
	if button == 1 then
		GroupGuard()
		mouse0 = {}
		mouse1 = {}
		radius = 0
		postProcess()
		userDrags = false
	end
	return false
end

function widget:MouseMove(x, y, dx, dy, button)
	if userDrags then
		local type, data  = TraceScreenRay(x,y)
		if (type ~= 'unit' and type ~= 'feature')  then
			mouse1 = data
		else
			local ufID = data
			if type == 'unit' then
				mouse1[1], mouse1[2],mouse1[3] = GetUnitPosition(ufID)
			elseif type == 'feature' then
				mouse1[1], mouse1[2],mouse1[3] = GetFeaturePosition(ufID)
			end
		end
	end	
end

function widget:KeyPress(key, mods, isRepeat) 
	if (key == 0x134) and (not isRepeat) then --alt
		altDown = true
	elseif(key == 0x132) and (not isRepeat) then
		ctrlDown = true
	end
	return false
end

function widget:KeyRelease(key)
	if (key == 0x134) then --alt
		altDown = false
	elseif(key == 0x132) then
		ctrlDown = false
	end
	return false
end
