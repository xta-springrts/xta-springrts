function widget:GetInfo()
	return {
		name = "FX radiation",
		desc = "Make radioactive units greenish, can be fps expensive",
		author = "Jools, reworked by res",
		date = "Nov, 2018",
		license = "GPLv2",
		version = "0.1",
		layer = 1,
		enabled = true,
		handler = true,
	}
end


--[[

	Colors 	- radiation units green
			- units that obain radiation yellow
			- and circles the area/units that have radiation

	--]]


-- LOCALS

local random							= math.random
local max								= math.max
local min								= math.min

local Echo								= Spring.Echo
local radiation_units					= {}
local radiation_areas					= {}
local GetUnitPosition 					= Spring.GetUnitPosition
local GetVisibleUnits					= Spring.GetVisibleUnits
local getAllUnits						= Spring.GetAllUnits
local GetGameRulesParam 				= Spring.GetGameRulesParam
local smoothPolys						= (gl.Smoothing ~= nil) and false
local texName 							= LUAUI_DIRNAME .. 'Images/highlight_strip.png'
local update_number						= GetGameRulesParam('radiation_update_number') or 0
local ValidUnitID 						= Spring.ValidUnitID
local GetUnitsInSphere					= Spring.GetUnitsInSphere
local ValidUnitID						= Spring.ValidUnitID


-- FUNCTIONS


local function add_radiation_unit(unitID)
	if GetGameRulesParam('radiation_radius' .. unitID) ~= nil and GetGameRulesParam('radiation_radius' .. unitID) ~= 0 then
		radiation_units[unitID] = {["radius"] = GetGameRulesParam('radiation_radius' .. unitID),
									   ["damage"] = GetGameRulesParam('radiation_damage' .. unitID)}
		radiation_areas[unitID] = radiation_units[unitID]
		local x,y,z = GetUnitPosition(unitID)
		radiation_areas[unitID].x = x
		radiation_areas[unitID].y = y
		radiation_areas[unitID].z = z
	end
end


function widget:Initialize()
	if modOptions and modOptions.lowcpu == "1" then
		Spring.Log("widget", LOG.INFO, 'Low performance mode is on, removing "gfx_radiation" widget')
		widgetHandler:RemoveWidget()
		return
	elseif gl.CreateShader then
		local visibleUnits = getAllUnits()
		for index, unitID in pairs(visibleUnits) do
			add_radiation_unit(unitID)
		end
	else
		Spring.Log("widget", LOG.INFO, 'no glsl')
		widgetHandler:RemoveWidget()
		return
	end
end


function widget:UnitDestroyed(unitID)
	radiation_units[unitID] = nil
end


local function update_radiation()
	local visibleUnits = getAllUnits()
	radiation_units = {}
	for index, unitID in pairs(visibleUnits) do
		add_radiation_unit(unitID)
	end

	for unitID, v in pairs(radiation_areas) do
		if GetGameRulesParam('radiation_radius' .. unitID) == nil or GetGameRulesParam('radiation_radius' .. unitID) == 0 then
			radiation_areas[unitID] = nil
		else
			if ValidUnitID(k) == true then
				local x,y,z = GetUnitPosition(unitID)
				--radiation_areas[unitID].x = x
				--radiation_areas[unitID].y = y
				--radiation_areas[unitID].z = z
			end
		end
	end
end


function widget:GameFrame(dt)
	if GetGameRulesParam('radiation_update_number') ~= update_number then
		update_radiation()
		update_number = update_number + 1

	end
end

function widget:DrawWorld()
	gl.DepthTest(true)
	gl.PolygonOffset(-2, -2)

	gl.Blending(GL.DST_COLOR, GL.ZERO)
	local r,g,b, a = 0.3,0.9,0.1, 0.5 --green?

	if (smoothPolys) then
		gl.Smoothing(nil, nil, true)
	end

	gl.TexCoord(0, 0)
	gl.TexGen(GL.T, GL.TEXTURE_GEN_MODE, GL.EYE_LINEAR)
	gl.TexGen(GL.T, GL.EYE_PLANE, 0, 1 , 0, 1)
	gl.Texture(texName)
	local a = 0.5

	for unitID, v in pairs(radiation_areas) do

		-- radiation areas
		if radiation_units[unitID] == nil then

			if GetGameRulesParam('radiation_damage' .. unitID) ~= nil and GetGameRulesParam('radiation_damage' .. unitID) ~= 0 then
				local radius = GetGameRulesParam('radiation_radius' .. unitID)

				local intensity = 1-min(max(0,GetGameRulesParam('radiation_damage' .. unitID)),1)
				gl.Color(intensity,1,intensity,a) 	--green
				gl.DrawGroundCircle(v.x, v.y, v.z, radius, 25)
				local temp = GetGameRulesParam('radiation_damage' .. unitID)
				local effectedUnits = GetUnitsInSphere(v.x,v.y,v.z, radius)
				for index, uID in pairs(effectedUnits) do
					if uID ~= unitID and radiation_units[uID] == nil then
						gl.Color(1, 1, intensity, a) --yellow
						gl.Unit(uID,true)
					end
				end
			else
				radiation_areas[unitID] = nil
			end

		-- radiation units
		else

			if ValidUnitID(unitID) then
				if GetGameRulesParam('radiation_damage' .. unitID) ~= nil and GetGameRulesParam('radiation_damage' .. unitID) ~= 0 then
					local intensity = 1-min(max(0,GetGameRulesParam('radiation_damage' .. unitID)),1)
					local radius = GetGameRulesParam('radiation_radius' .. unitID)
					gl.Color(intensity,1,intensity,a) --green
					gl.Unit(unitID,true)
					local x,y,z = GetUnitPosition(unitID)
					radiation_areas[unitID].x = x
					radiation_areas[unitID].y = y
					radiation_areas[unitID].z = z
					gl.DrawGroundCircle(x, y, z, radius, 25)
					local effectedUnits = GetUnitsInSphere(x,y,z, radius)
					for index, uID in pairs(effectedUnits) do
						if uID ~= unitID and radiation_units[uID] == nil then
							gl.Color(1, 1, intensity, a) --yellow
							gl.Unit(uID,true)
						end
					end
				end
			else
				radiation_units[unitID] = nil
			end
		end
	end

end
