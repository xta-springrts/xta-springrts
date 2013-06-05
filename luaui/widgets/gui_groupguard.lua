local versionNumber = "1.0"

function widget:GetInfo()
	return {
	name = "Group guard",
	desc = "Guard units in selected rectangle",
	author = "Jools",
	date = "Jun, 2012",
	license = "tango",
	layer = 1,
	enabled = false
	}
end

local sndButton								= 'sounds/button9.wav'
local userDrags 							= false
local Echo 									= Spring.Echo
local GetActiveCommand						= Spring.GetActiveCommand
local CMD_GUARD 							= CMD.GUARD
local CMD_INSERT							= CMD.INSERT
local CMD_OPT_SHIFT							= CMD.OPT_SHIFT
local GetUnitPosition 						= Spring.GetUnitPosition
local GetFeaturePosition					= Spring.GetFeaturePosition
local GetSelectedUnits						= Spring.GetSelectedUnits
local GetUnitSeparation						= Spring.GetUnitSeparation
local GetUnitDefID							= Spring.GetUnitDefID
local GiveOrderToUnit						= Spring.GiveOrderToUnit
local PlaySoundFile							= Spring.PlaySoundFile	
local mouse0 								= {}
local mouse1 								= {}
local radius 								= 0
local ctrlDown 								= false


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
		--gl.PushMatrix()
		--gl.Translate(mouse1[1],mouse1[2],mouse1[3])
		--gl.Billboard()
		gl.Color(0.2,0.3,0.8,0.5)
		gl.LineWidth(3)
		--gl.Rect(mouse0[1],mouse0[3],mouse1[1],mouse1[3])
		--gl.BeginEnd(GL.TRIANGLE_FAN, 2, mouse0[1], mouse0[3], dist)
		gl.DrawGroundCircle(mouse0[1],mouse0[2],mouse0[3],dist,64)
		--gl.PopMatrix()
	end
end
	
function resetInterface()
	local selectedUnits = GetSelectedUnits()
	Spring.SendCommands("deselect")
	Spring.SelectUnitArray(selectedUnits)
	--Spring.SendCommands("mouse3")
	if sndButton then
		PlaySoundFile(sndButton)
	end
end
	
function GroupGuard()
	if radius > 0 then
		
		local dist = math.sqrt( (mouse1[1]-mouse0[1])^2 + (mouse1[3]-mouse0[3])^2)
		local targetArray = Spring.GetUnitsInCylinder(mouse0[1],mouse0[3],radius)
		
		local sortedUnits = {}
		local sU = GetSelectedUnits()
		local guardTable = {}
		if sU then
			for _,tID in ipairs(targetArray) do
				if ctrlDown then -- give distributed order
					local minDist = 0
					local bestUnit
					local tUD = UnitDefs[GetUnitDefID(tID)]
					
					for _, sID in ipairs(sU) do
						if sID ~= tID then				
							local distance = GetUnitSeparation(sID,tID) 
							local sUD = UnitDefs[GetUnitDefID(sID)]
								
							if minDist == 0 then
								minDist = distance
								bestUnit = sID
							elseif minDist > 0 then
								if distance < minDist then
									minDist = distance
									bestUnit = sID
								end
							end
						end
					end
				
					if bestUnit then
						local bUD = UnitDefs[GetUnitDefID(bestUnit)]
						local bName = bUD.name
						--Echo("best unit:", bName, minDist) 
					end
				else -- not ctrlDown, give normal order
					for _, sID in ipairs(sU) do
						if sID ~= tID then
							GiveOrderToUnit(sID, CMD_INSERT,{-1,CMD_GUARD,CMD_OPT_SHIFT,tID},{"alt"})
						end
					end
				end
			end
		end
		--Echo("ctrl down:", ctrlDown)
	end
end

function widget:MousePress(mx,my,button)
	if button == 1 and not userDrags then
		local _, activeCmdID = GetActiveCommand()
		if activeCmdID == CMD_GUARD then
			local type, data  = Spring.TraceScreenRay(mx,my)
			if (type ~= 'unit' and type ~= 'feature')  then
				--Spring.Echo(type,data)
				userDrags = true
				mouse0 = data
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
		resetInterface()
		userDrags = false
	end
	return false
end

function widget:MouseMove(x, y, dx, dy, button)
	if userDrags then
		local type, data  = Spring.TraceScreenRay(x,y)
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
	if (key == 0x132) and (not isRepeat) then --ctrl
		--Echo("Ctrl down")
		ctrlDown = true
	end
	return false
end

function widget:KeyRelease(key)
	if (key == 0x132) then --ctrl
		--Echo("Ctrl up")
		ctrlDown = false
	elseif key == 0x134 then --ALT
		--Echo("alt up")
	end
	return false
end
