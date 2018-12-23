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

-- locals and speed ups
local Echo								= Spring.Echo
local radiation_units					= {}
local GetUnitPosition 					= Spring.GetUnitPosition
local GetVisibleUnits					= Spring.GetVisibleUnits
local GetGameRulesParam 				= Spring.GetGameRulesParam



local function add_radiation_unit(unitID)
	if GetGameRulesParam('radiation_radius' .. unitID) ~= nil then
		if radiation_units[unitID] ~= nil then
			radiation_units[unitID]["radius"] = GetGameRulesParam('radiation_radius' .. unitID)
			radiation_units[unitID]["damage"] = GetGameRulesParam('radiation_damage' .. unitID)
		else
			radiation_units[unitID] = {["radius"] = GetGameRulesParam('radiation_radius' .. unitID),
									   ["damage"] = GetGameRulesParam('radiation_damage' .. unitID)}
		end
	end
end


function widget:Initialize()
	if modOptions and modOptions.lowcpu == "1" then
		Spring.Log("widget", LOG.INFO, 'Low performance mode is on, removing "gfx_radiation" widget')
		widgetHandler:RemoveWidget()
		return
	elseif gl.CreateShader then
		local visibleUnits = GetVisibleUnits()
		for index, unitID in pairs(visibleUnits) do
			add_radiation_unit(unitID)
		end
	else
		Spring.Log("widget", LOG.INFO, 'no glsl')
		widgetHandler:RemoveWidget()
		return
	end
end

function widget:UnitEnteredLos(unitID, teamID)
	add_radiation_unit(unitID)
end

function widget:UnitLeftLos(unitID)
	radiation_units[unitID] = nil
end

function widget:UnitCreated(unitID, unitDefID, teamID)
	add_radiation_unit(unitID)
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	radiation_units[unitID] = nil
end

function widget:UnitGiven(unitID, unitDefID, teamID)
	radiation_units[unitID] = nil
end


local smoothPolys				= (gl.Smoothing ~= nil) and false
local texName 					= LUAUI_DIRNAME .. 'Images/highlight_strip.png'
local outlineWidth 				= 1
local Echo						= Spring.Echo


local function update_radiation()
	local visibleUnits = GetVisibleUnits()
	radiation_units = {}
	for index, unitID in pairs(visibleUnits) do
		add_radiation_unit(unitID)
	end
end


function widget:GameFrame(dt)
	if (dt%3 == 0) then
		update_radiation()
		widgetHandler:UpdateWidgetCallIn("DrawWorld", self)
	end
end

function widget:DrawWorld()
	gl.DepthTest(true)
	gl.PolygonOffset(-2, -2)


	local r,g,b,a
	gl.Blending(GL.DST_COLOR, GL.ZERO)
	r,g,b, a = 0.3,0.9,0.1, 0.5 --green?


	if (smoothPolys) then
		gl.Smoothing(nil, nil, true)
	end

	gl.TexCoord(0, 0)
	gl.TexGen(GL.T, GL.TEXTURE_GEN_MODE, GL.EYE_LINEAR)
	gl.TexGen(GL.T, GL.EYE_PLANE, 0, 1 , 0, 1)
	gl.Texture(texName)

	for index, unitID in pairs(GetVisibleUnits()) do
		if radiation_units[unitID] then
			if GetGameRulesParam('radiation_damage' .. unitID) ~= nil then
				local a = 1 - GetGameRulesParam('radiation_damage' .. unitID)
				gl.Color(r,g,b,a)
				gl.Unit(unitID,true)
			end
		end
	end
	gl.Blending("default")
	gl.Color(1,1,1,1)
	gl.Texture(false)
	gl.TexGen(GL.T, false)

	if (smoothPolys) then
		gl.Smoothing(nil, nil, false)
	end
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.PolygonOffset(false)
	gl.DepthTest(false)
end
