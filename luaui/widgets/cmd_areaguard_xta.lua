local versionNumber = "2.1"

function widget:GetInfo()
	return {
	name = "Area guard XTA",
	desc = "Guard units in selected area",
	author = "Jools",
	date = "Dec, 2015",
	license = "tango",
	layer = 10,
	enabled = true,
	handler = true, --access to handler
	}
end

local AreTeamsAllied						= Spring.AreTeamsAllied
local CMD_AREA_GUARD 						= 14001
local CMD_GUARD 							= CMD.GUARD
local CMD_INSERT							= CMD.INSERT
local CMD_OPT_SHIFT							= CMD.OPT_SHIFT
local CMD_REPAIR 							= CMD.REPAIR
local CMD_STOP								= CMD.STOP
local Echo 									= Spring.Echo
local GL_LINE_STRIP = GL.LINE_STRIP
local GetActiveCommand						= Spring.GetActiveCommand
local GetSelectedUnits						= Spring.GetSelectedUnits
local GetSelectedUnitsCounts				= Spring.GetSelectedUnitsCounts
local GetUnitDefID							= Spring.GetUnitDefID
local GetUnitHealth							= Spring.GetUnitHealth
local GetUnitHeight							= Spring.GetUnitHeight
local GetUnitPosition						= Spring.GetUnitPosition
local GetUnitSeparation						= Spring.GetUnitSeparation
local GetUnitTeam							= Spring.GetUnitTeam
local GetUnitViewPosition					= Spring.GetUnitViewPosition
local GetUnitsInCylinder 					= Spring.GetUnitsInCylinder
local GiveOrderToUnit						= Spring.GiveOrderToUnit
local IsUnitSelected						= Spring.IsUnitSelected
local IsUnitVisible							= Spring.IsUnitVisible
local PlaySoundFile							= Spring.PlaySoundFile
local SetMouseCursor						= Spring.SetMouseCursor
local altDown 								= false
local ctrlDown 								= false
local drawTable 							= {}
local glBeginEnd = gl.BeginEnd
local glBillboard = gl.Billboard
local glColor = gl.Color
local glLineStipple = gl.LineStipple
local glLineWidth = gl.LineWidth
local glLoadIdentity = gl.LoadIdentity
local glPopMatrix = gl.PopMatrix
local glPushMatrix = gl.PushMatrix
local glScale = gl.Scale
local glTexRect	= gl.TexRect
local glTexture	= gl.Texture
local glTranslate = gl.Translate
local glVertex = gl.Vertex
local guardianTable 						= {} -- reverse list
local helpOn 								= tonumber(Spring.GetConfigInt("CommandHelpText",1) or 1) == 1
local hideGuard								= false
local math_floor							= math.floor
local myFont	 							= gl.LoadFont("FreeSansBold.otf",textsize, 1.9, 40) 
local myFontBig	 							= gl.LoadFont("FreeSansBold.otf",12, 1.9, 40)
local shiftDown 							= false
local sndButton								= 'sounds/button9.wav'
local sndButton2							= 'sounds/minesel4.wav'
local squadron 								= {} -- squadron[unitID] = array. Table by source units containing a list of guarded units
local ta_insert								= table.insert
local ta_remove								= table.remove
local ta_sort								= table.sort
local textsize								= 6
local textoffsetx							= 16
local textoffsety							= 21


local imgGuard								= 'luaui/images/areaguard/cursordefendsquad.png'
local myTeamID
 
 
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
	Spring.AssignMouseCursor('SquadronGuard', 'cursordefendb', true, false)
	Spring.AssignMouseCursor('SplitGuard', 'cursordefendc', true, false)
	myTeamID = Spring.GetMyTeamID()
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
				
				if tUD then
					local dist = GetUnitSeparation(baseUnit, tID)
					local tTeam = GetUnitTeam(tID)
					local isMovingUnit = tUD.canMove and (not tUD.isBuilding)
					local areTeamsAllied = AreTeamsAllied(sTeam,tTeam)
					
					if not squadron[tID] and areTeamsAllied and isMovingUnit then 
						targetTable[#targetTable+1] = {tID,dist}
					end
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

local function getDrawData(unitArray)
	for _, sourceID in pairs (unitArray) do
		if squadron[sourceID] then
			if not drawTable[sourceID] then
				drawTable[sourceID] = {}
			end
			
			local _,_,_,xm0,ym0,zm0 = GetUnitPosition(sourceID,true)
			drawTable[sourceID][1] = {sourceID,xm0,ym0,zm0}
			
			for j, targetID in pairs (squadron[sourceID]) do
				local _,_,_,xm,ym,zm = GetUnitPosition(targetID,true)
				drawTable[sourceID][j+1] = {targetID,xm,ym,zm}
				--Echo("GDD:",sourceID,j+1,#drawTable[sourceID][j+1])
			end
		end
	end
end

local function updateDrawData()
	
	for sourceID, sourceData in pairs (drawTable) do
		if IsUnitSelected(sourceID) then
			for i, targetData in pairs (sourceData) do
				
				local tID = targetData[1]
				local _,_,_,xm,ym,zm = GetUnitPosition(tID,true)
				targetData = {tID,xm,ym,zm}
			end
		else
			drawTable[sourceID] = nil
		end
	end
end

function widget:KeyPress(key, mods, isRepeat) 
	if (key == 0x067) and (not isRepeat) and (not mods.ctrl) and not (mods.shift) and (not mods.alt) then --g
		Spring.SetActiveCommand("areaguard")
		return true
	elseif (key == 0x130) then -- shift
		shiftDown = true
		local sU = GetSelectedUnits()
		if sU then			
			getDrawData(sU)
		end
	elseif (key == 0x134) then -- alt
		helpOn = tonumber(Spring.GetConfigInt("CommandHelpText",1) or 1) == 1
		altDown = true
	elseif (key == 0x132) then -- ctrl
		ctrlDown = true
	end
	return false
end

function widget:KeyRelease(key)
	if (key == 0x130) then -- shift
		shiftDown = false
		drawTable = {}
	elseif (key == 0x134) then -- alt
		altDown = false
	elseif (key == 0x132) then -- ctrl
		ctrlDown = false
	end
	return false
end

function widget:GameFrame(frame)
	if next(drawTable) ~= nil and (frame%16 == 0) then
		updateDrawData()
	end	
end

function widget:DefaultCommand(type, uID)

	local sUC = GetSelectedUnitsCounts()
	
	if sUC and sUC['n'] > 0 then
		-- user has selected one or more units
		local _, activeCmdID = GetActiveCommand()
		if activeCmdID == CMD_AREA_GUARD then
			if altDown then
				if ctrlDown then
					SetMouseCursor('SquadronGuard')
				else
					SetMouseCursor('SplitGuard')
				end
			else
				SetMouseCursor('Guard')
			end
		end
	end
end
	
--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------
local function drawVerts(drawData)
	
	for i, v in pairs (drawData) do
		glVertex(v[2], v[3], v[4])
		--Echo("Drawing:",i,v[1],v[2], v[3], v[4])
	end
end

function widget:DrawWorld()
	
	if next(drawTable) ~= nil then
		glColor(0, 0.6, 0.85, 0.75) 
		glLineStipple("springdefault")
		glLineWidth (0.5)
		for id,drawData in pairs (drawTable) do
			glBeginEnd(GL_LINE_STRIP,drawVerts,drawData)		
		end
		glLineStipple(false)
		glColor(1,1,1,1)		
	end
	
			
	for unitID, data in pairs(squadron) do
		if IsUnitVisible(unitID, 16, false) then --skip if zoomed out or not on screen
			if IsUnitSelected(unitID) then
				local n = #data
				if n > 0 then
					local ux, uy, uz = GetUnitViewPosition(unitID)
					local h = GetUnitHeight(unitID)
					glPushMatrix()
					glTranslate(ux, uy + h + 24, uz )
					glBillboard()
					
					glTexture(imgGuard)
					glColor(1,1,1,0.75)
					glTexRect(textoffsetx-5,textoffsety-6,textoffsetx+5,textoffsety+4)
					glColor(1,1,1,1)
					glTexture(false)
					glPopMatrix()
					-- including a number that prints how many units are guarded somehow makes this widget too costly
					-- even if we are just printing this number and not doing anything more with it
					--myFont:Begin() 
					--myFont:SetTextColor(1, 1, 1, 0.85)
					--myFont:Print(n, textoffsetx, textoffsety, textsize, "vcs")
					--myFont:End()
		
				end
			end
		end
		
	end
end

function widget:DrawScreen()
	if helpOn then
		local _, activeCmdID = GetActiveCommand()	
		if activeCmdID == CMD_AREA_GUARD then
			if altDown then
				local x,y = Spring.GetMouseState()
				if ctrlDown then
					myFont:Begin()
					myFont:SetTextColor(0, 0.6, 0.85, 0.85)
					myFont:Print("Distributed guard with persistent squadrons. Use the STOP command to end task.", x, y-100, 12, "vcs")
					myFont:End()
				else
					myFont:Begin()
					myFont:SetTextColor(0.6, 0.2, 0.85, 0.85)
					myFont:Print("Distributed guard: selected units share the guarding task", x, y-100, 12, "vcs")
					myFont:End()
				end		
			end
		end
	end
end