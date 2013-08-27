function gadget:GetInfo()
  return {
    name      = "Mission Editor",
    desc      = "Simplifies placing of map locations and units and can load a mission for further editing",
    author    = "Deadnight Warrior",
    date      = "14 Jul 2012",
    license   = "GNU LGPL, v2 or later",
    layer     = 1,
    enabled   = true --  loaded by default?
  }
end

local spGetTeamInfo = Spring.GetTeamInfo
local spGetGroundHeight = Spring.GetGroundHeight
local spCreateUnit = Spring.CreateUnit
local spCreateFeature = Spring.CreateFeature
local spEcho = Spring.Echo
local spGetGameFrame = Spring.GetGameFrame

local GetUnitCommands = Spring.GetUnitCommands
local FindUnitCmdDesc = Spring.FindUnitCmdDesc
local SetUnitBuildspeed = Spring.SetUnitBuildSpeed
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitBuildFacing = Spring.GetUnitBuildFacing
local spGetFeatureTeam = Spring.GetFeatureTeam
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetFeatureHeading = Spring.GetFeatureHeading
local spGetFeatureDefID = Spring.GetFeatureDefID

local modOptions = Spring.GetModOptions()
local gaiaTeamID = Spring.GetGaiaTeamID()
local teams = Spring.GetTeamList()
for i=1, #teams do
	if teams[i] == gaiaTeamID then
		table.remove(teams, i)
		break
	end
end

local pairs = pairs
local floor = math.floor
local abs = math.abs
local min = math.min
local max = math.max

local gameData, spawnData, missionTriggers, locations, briefing = {}, {}, {}, {}, {}

CMD_DUMP = 39997
local DumpCmdDesc = {
  id      = CMD_DUMP,
  type    = CMDTYPE.ICON,
  name    = 'Dump',
  cursor  = 'Dump',
  action  = 'Dump',
  tooltip = "Store positions of all units/buildings on map into a mission template file\nsave any mission triggers, locations and briefing data as well",
}

CMD_LOC_C = 39998
local LocCCmdDesc = {
  id      = CMD_LOC_C,
  type    = CMDTYPE.ICON_AREA,
  name    = 'Loc C',
  cursor  = 'Loc C',
  action  = 'Loc C',
  tooltip = "Draw a circular map location\nSelect a center and pull out the radius\nYou can name the location by placing a map marker inside it\nDon't delete markers or location names will mix up",
}

CMD_LOC_R = 39999
local LocRCmdDesc = {
  id      = CMD_LOC_R,
  type    = CMDTYPE.ICON_UNIT_OR_RECTANGLE,
  name    = 'Loc R',
  cursor  = 'Loc R',
  action  = 'Loc R',
  tooltip = "Draw a rectangular map location\nDraw a line that's the rectangles diagonal\nYou can name the location by placing a map marker inside it\nDon't delete markers or location names will mix up",
}

CMD_DEL_LOC = 39996
local DelLocCmdDesc = {
  id      = CMD_DEL_LOC,
  type    = CMDTYPE.ICON_MAP,
  name    = 'Del Loc',
  cursor  = 'Attack',
  action  = 'Del Loc',
  tooltip = "Delete all map locations that contain selected map coordinates\nWhen you delete a location don't delete it's marker or location names will mix up",
}

if (gadgetHandler:IsSyncedCode()) then

	function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, _)
		if cmdID == CMD_DUMP then
			SendToUnsynced("Dump")
			return false
		elseif cmdID == CMD_LOC_C then
			SendToUnsynced("CircLocation", floor(cmdParams[1]+0.5), floor(cmdParams[3]+0.5), floor(cmdParams[4]+0.5))
			return false
		elseif cmdID == CMD_LOC_R then
			if #cmdParams==6 then
				local x1,x2,z1,z2 = min(cmdParams[1],cmdParams[4]), max(cmdParams[1],cmdParams[4]), min(cmdParams[3],cmdParams[6]), max(cmdParams[3],cmdParams[6])
				SendToUnsynced("RectLocation", floor(x1+0.5), floor(z1+0.5), floor(x2+0.5), floor(z2+0.5))
				return false
			end
		elseif cmdID == CMD_DEL_LOC then
			SendToUnsynced("DelLocation", cmdParams[1], cmdParams[3])
			return false
		end
		return true
	end

	function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
		if UnitDefs[unitDefID].name == "zzz_mission_wizzard" then
			if not (FindUnitCmdDesc(unitID, CMD_LOC_C)) then
				local insertID = FindUnitCmdDesc(unitID, CMD.FIRE_STATE) or	123456 -- back of the pack
				Spring.InsertUnitCmdDesc(unitID, insertID + 1, LocCCmdDesc)	
			end
			if not (FindUnitCmdDesc(unitID, CMD_LOC_R)) then
				local insertID = FindUnitCmdDesc(unitID, CMD.FIRE_STATE) or	123456 -- back of the pack
				Spring.InsertUnitCmdDesc(unitID, insertID + 1, LocRCmdDesc)	
			end
			if not (FindUnitCmdDesc(unitID, CMD_DEL_LOC)) then
				local insertID = FindUnitCmdDesc(unitID, CMD.FIRE_STATE) or	123456 -- back of the pack
				Spring.InsertUnitCmdDesc(unitID, insertID + 1, DelLocCmdDesc)	
			end
			if not (FindUnitCmdDesc(unitID, CMD_DUMP)) then
				local insertID = FindUnitCmdDesc(unitID, CMD.FIRE_STATE) or	123456 -- back of the pack
				Spring.InsertUnitCmdDesc(unitID, insertID + 1, DumpCmdDesc)	
			end
		end
	end


	function gadget:Initialize()
		gadgetHandler:RegisterCMDID(CMD_DUMP)
		for _, unitID in ipairs(Spring.GetAllUnits()) do
			local teamID = Spring.GetUnitTeam(unitID)
			local unitDefID = spGetUnitDefID(unitID)
			gadget:UnitCreated(unitID, unitDefID, teamID)
		end
		if modOptions and modOptions.mission then
			local mission = "Missions/" .. modOptions.mission ..".lua"
			if VFS.FileExists(mission) then
				gameData, spawnData, missionTriggers, locations, briefing = include(mission)
				if gameData.game == Game.modShortName then
					if gameData.map ~= Game.mapName then
						spEcho('Mission "' .. modOptions.mission .. "\" was started on a wrong map or you don't have " .. spawnData.map)
						spEcho("Swiching to mission construction mode")
						--gadgetHandler:RemoveGadget()
					end
				else
					spEcho('This mission is intended for "' .. gameData.game .. '"')
					spEcho("Swiching to mission construction mode")
					--gadgetHandler:RemoveGadget()				
				end
			else
				spEcho("Mission parameter incorrect or wrong mission file")
				spEcho("Swiching to mission construction mode")
				--gadgetHandler:RemoveGadget()
			end
		else
			--gadgetHandler:RemoveGadget()	-- blank mission
		end
	end

	function gadget:Shutdown()
		for _, unitID in ipairs(Spring.GetAllUnits()) do
			local cmdDescID = FindUnitCmdDesc(unitID, CMD_DUMP)
			if (cmdDescID) then Spring.RemoveUnitCmdDesc(unitID, cmdDescID) end
			local cmdDescID = FindUnitCmdDesc(unitID, CMD_LOC_C)
			if (cmdDescID) then Spring.RemoveUnitCmdDesc(unitID, cmdDescID) end
			local cmdDescID = FindUnitCmdDesc(unitID, CMD_LOC_R)
			if (cmdDescID) then Spring.RemoveUnitCmdDesc(unitID, cmdDescID) end
			local cmdDescID = FindUnitCmdDesc(unitID, CMD_DEL_LOC)
			if (cmdDescID) then Spring.RemoveUnitCmdDesc(unitID, cmdDescID) end
		end
	end

	function gadget:GameStart()
		for _, teamID in pairs(teams) do
			if spawnData.teams then
				for _, unitData in pairs(spawnData.teams[teamID]) do
					--local x, z = 16*floor((unitData[2]+8)/16), 16*floor((unitData[3]+8)/16)	-- snap to 16x16 grid, fails for odd footprint sizes
					--local x, z = 8*floor((unitData[2]+4)/8), 8*floor((unitData[3]+4)/8)	-- snap to 8x8 grid
					local x, z = unitData[2], unitData[3]	-- don't snap to grid, not needed if mission dumper was used
					local y = spGetGroundHeight(x, z)
					spCreateUnit(unitData[1], x, y, z, unitData[4], teamID)
				end
			end

			local teamOptions = select(7, spGetTeamInfo(teamID))
			local m = teamOptions.startmetal  or modOptions.startmetal  or 1000
			local e = teamOptions.startenergy or modOptions.startenergy or 1000
			if (m and tonumber(m) ~= 0) then
				--Spring.SetUnitResourcing(commanderID, "m", 0)
				Spring.SetTeamResource(teamID, "m", 0)
				Spring.AddTeamResource(teamID, "m", tonumber(m))
			end
			if (e and tonumber(e) ~= 0) then
				--Spring.SetUnitResourcing(commanderID, "e", 0)
				Spring.SetTeamResource(teamID, "e", 0)
				Spring.AddTeamResource(teamID, "e", tonumber(e))
			end
		end
		if spawnData.features then
			for _, featureData in pairs(spawnData.features) do
				local y = spGetGroundHeight(featureData[2], featureData[3])
				spCreateFeature(featureData[1], featureData[2], y, featureData[3], featureData[4], featureData[5])
			end
		end
		--gadgetHandler:RemoveGadget()	-- we loaded the mission for further editing
	end

	function gadget:RecvLuaMsg(msg, playerID)
		if msg:sub(1,6)=="locCol" then
			SendToUnsynced("LocationColour", msg:sub(7))
		end
	end	
	
else	--UNSYNCED

local locNames, markNames = {}, {}

local glColor = gl.Color
local glLineWidth = gl.LineWidth
local glDrawGroundCircle = gl.DrawGroundCircle
local glDrawGroundQuad = gl.DrawGroundQuad
local glBeginText = gl.BeginText
local glEndText = gl.EndText
local glText = gl.Text
local glPushMatrix = gl.PushMatrix
local glTranslate = gl.Translate
local glPopMatrix = gl.PopMatrix
local glBeginEnd = gl.BeginEnd
local glVertex = gl.Vertex
local glDepthMask = gl.DepthMask
local glDepthTest = gl.DepthTest
local glCallList = gl.CallList
local glBlending = gl.Blending
local glRect = gl.Rect
local glTexRect = gl.TexRect

local R,G,B = 1,1,1

	local function StoreSpawnData()
		local mapMarkerList = Spring.GetLastMessagePositions()
		local consBuff = Spring.GetConsoleBuffer()
		for j, line in pairs(consBuff) do
			local fnd = line.text:find(" added point: ",13,true)
			if fnd then
				markNames[#markNames+1] = line.text:sub(14+fnd)
			end
		end
		for ln, loc in pairs(locations) do
			if tonumber(ln) then
				locNames[ln]= "[" .. ln .. "]"
			else
				locNames[ln]= ln
			end
		end
		for i, pos in pairs(mapMarkerList) do
			for ln, loc in pairs(locations) do
				if loc.shape=="C" then
					local dx, dz = loc.X - pos[1], loc.Z - pos[3]
					if dx*dx + dz*dz <= loc.r*loc.r then
						locNames[ln] = markNames[#markNames-i+1]
					end
				elseif loc.shape=="R" then
					if pos[1] >= loc.X1 and pos[1] <= loc.X2 and pos[3] >= loc.Z1 and pos[3] <= loc.Z2 then
						locNames[ln] = markNames[#markNames-i+1]
					end
				end
			end
		end

		if (Script.LuaUI('DumpMission')) then
			Spring.Echo("Starting mission dump")
			local textLine = ""
			Script.LuaUI.DumpMission("BeginDump")
			if gameData.nextMission then
				Script.LuaUI.DumpMission('\tnextMission = "' .. gameData.nextMission .. '"\n}\n\nspawnData = {\n\tteams = {\n')
			else
				Script.LuaUI.DumpMission('}\n\nspawnData = {\n\tteams = {\n')
			end
			for teamID=0, #Spring.GetTeamList()-1 do
				if teamID ~= gaiaTeamID then
					Script.LuaUI.DumpMission("\t\t[" .. teamID .. "] = {\n")
					for _, unitID in pairs(Spring.GetTeamUnits(teamID)) do
						local unitDefID = spGetUnitDefID(unitID)
						if UnitDefs[unitDefID].name ~= "zzz_mission_wizzard" then
							local x,_,z = spGetUnitPosition(unitID)
							local f = spGetUnitBuildFacing(unitID)
							textLine = '\t\t\t{"' .. UnitDefs[unitDefID].name .. '", ' .. x .. ", " .. z .. ", " .. f .. "},\n"
							Script.LuaUI.DumpMission(textLine)
						end
					end
					Script.LuaUI.DumpMission("\t\t},\n")
				end
			end
			Script.LuaUI.DumpMission("\t},\n\tfeatures = {\n")
			for _, featureID in pairs(Spring.GetAllFeatures()) do
				local fOwnerID = spGetFeatureTeam(featureID)
				if fOwnerID ~= gaiaTeamID and fOwnerID ~= -1 then
					local x, _, z = spGetFeaturePosition(featureID)
					local head = spGetFeatureHeading(featureID)
					local fName = FeatureDefs[spGetFeatureDefID(featureID)].name
					textLine = '\t\t{"' .. fName .. '", ' .. x .. ", " .. z .. ", " .. head .. ", " .. fOwnerID .. "},\n"
					Script.LuaUI.DumpMission(textLine)
				end
			end
			Script.LuaUI.DumpMission("\t}\n}\n\nmissionTriggers = {\n")
			for trig, val in pairs(missionTriggers) do
				Script.LuaUI.DumpMission("\t[" .. trig .. "] = {\n")
				for tag, par in pairs(val) do
					Script.LuaUI.DumpMission("\t\t{\n\t\t\tconditions = {\n")
					for _, cond in pairs(par.conditions) do
						Script.LuaUI.DumpMission('\t\t\t\t"' .. cond ..'",\n')
					end
					Script.LuaUI.DumpMission("\t\t\t},\n\t\t\tactions = {\n")
					for _, actn in pairs(par.actions) do
						Script.LuaUI.DumpMission('\t\t\t\t"' .. actn ..'",\n')
					end
					textline = "\t\t\t},\n"
					if par.once then
						textline = textline .. "\t\t\tonce = true,\n"
					end
					Script.LuaUI.DumpMission(textline .. "\t\t},\n")
				end
				Script.LuaUI.DumpMission("\t},\n")
			end
			Script.LuaUI.DumpMission("}\n\nlocations = {\n")
			for loc, val in pairs(locations) do
				Script.LuaUI.DumpMission("\t" .. locNames[loc] .. " = {\n")
				for tag, par in pairs(val) do
					local value = tostring(par)
					if value == "C" or value == "R" then
						value = '"' .. value .. '"'
					elseif type(par)=="table" then
						value = "{" .. par[1] .. ", " .. par[2] .. ", " .. par[3] .. "}"
					end
					Script.LuaUI.DumpMission("\t\t" .. tag .. " = " .. value .. ",\n")
				end
				Script.LuaUI.DumpMission("\t},\n")
			end
			Script.LuaUI.DumpMission("}\n\nbriefing = {\n")
			for brf, val in pairs(briefing) do
				if value:find('"')then
					Script.LuaUI.DumpMission("\t'" .. value .. "',\n")
				else
					Script.LuaUI.DumpMission('\t"' .. value .. '",\n')
				end
			end
			Script.LuaUI.DumpMission("EndDump")
		end
	end

	local function DelLocation(_, x, z)
		local i = 1
		while i <= #locations do
			loc = locations[i]
			if loc.shape=="C" then
				local dx, dz = loc.X - x, loc.Z -z
				if dx*dx + dz*dz <= loc.r*loc.r then
					table.remove(locations, i)
				else
					i = i+1
				end
			elseif loc.shape=="R" then
				if x >= loc.X1 and x <= loc.X2 and z >= loc.Z1 and z <= loc.Z2 then
					table.remove(locations, i)
				else
					i = i+1
				end
			end
		end
	end
	
	local function CircLocation(_, x, z, r)
		table.insert(locations, {shape = "C", X = x, Z = z, r = r, visible = true, RGB = {R,G,B}})
	end
	
	local function RectLocation(_, x1, z1, x2, z2)
		table.insert(locations, {shape = "R", X1 = x1, Z1 = z1, X2 = x2, Z2 = z2, visible = true, RGB = {R,G,B}})
	end
	
	local function LocationColour(_, col)
		if col:sub(1,1)=="R" then
			R = tonumber(col:sub(2))
		elseif col:sub(1,1)=="G" then
			G = tonumber(col:sub(2))
		elseif col:sub(1,1)=="B" then
			B = tonumber(col:sub(2))
		end
	end

	function gadget:Initialize()
		gadgetHandler:AddSyncAction('Dump',StoreSpawnData)
		gadgetHandler:AddSyncAction('CircLocation',CircLocation)
		gadgetHandler:AddSyncAction('RectLocation',RectLocation)
		gadgetHandler:AddSyncAction('DelLocation',DelLocation)
		gadgetHandler:AddSyncAction('LocationColour',LocationColour)
		Spring.AddUnitIcon("zzz_mission_wizzard", "LuaUI/icons/zzz_mission_wizzard.png",3)
		if modOptions and modOptions.mission then
			local mission = "Missions/" .. modOptions.mission ..".lua"
			if VFS.FileExists(mission) then
				gameData, _, _, locations = include(mission)
				if gameData.game ~= Game.modShortName then
					--gadgetHandler:RemoveGadget()
				end
			else
				--gadgetHandler:RemoveGadget()
			end
		else
			--gadgetHandler:RemoveGadget()
		end
		for udid,ud in pairs(UnitDefs) do
			if ud.name=="zzz_mission_wizzard" then
				Spring.SetUnitDefIcon(udid, "zzz_mission_wizzard")
			end
		end
	end

	function gadget:DrawWorldPreUnit()
		local alpha = abs(spGetGameFrame() % 60 - 30)/30
		glLineWidth(10)
		for ln, loc in pairs(locations) do
			if loc.RGB then gl.Color(loc.RGB[1], loc.RGB[2], loc.RGB[3], alpha) else gl.Color(1.0, 1.0, 1.0, alpha) end
			if loc.shape=="C" then
				glDrawGroundCircle(loc.X, spGetGroundHeight(loc.X, loc.Z), loc.Z, loc.r-3, 24)
			elseif loc.shape=="R" then
				glDrawGroundQuad(loc.X1, loc.Z1, loc.X2, loc.Z2)
			end
		end
	end

end