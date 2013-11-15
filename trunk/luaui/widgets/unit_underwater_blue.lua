function widget:GetInfo()
	return {
		name = "Underwater blue",
		desc = "Make underwater units blueish",
		author = "Jools",
		date = "Nov, 2013",
		license = "GPLv2",
		version = "1.2",
		layer = 1,
		enabled = false
	}
end

local smoothPolys				= (gl.Smoothing ~= nil) and false
local inWater					= {}
local texName 					= LUAUI_DIRNAME .. 'Images/highlight_strip.png'
local outlineWidth 				= 1
local gaiaID					= Spring.GetGaiaTeamID()
local unitDefRadius				= {}

function widget:Initialize()
	for i, uID in pairs(Spring.GetAllUnits()) do
		local _,_,_,_,midY = Spring.GetUnitPosition(uID,true)
		local teamID = Spring.GetUnitTeam(uID)
		if midY < 0 and teamID ~= gaiaID then
			inWater[uID] = true
		end
	end
end

function widget:UnitEnteredWater(unitID, unitDefID, teamID)
	if unitDefID and teamID ~= gaiaID then
		local radius = unitDefRadius[unitDefID]
		if not radius then
			unitDefRadius[unitDefID] = Spring.GetUnitDefDimensions(unitDefID)["radius"]
		end
		inWater[unitID] = true
	end
end

function widget:UnitEnteredLos(unitID, teamID)
	local _,_,_,_,midY = Spring.GetUnitPosition(unitID,true)
	if midY < 0 and teamID ~= gaiaID then
		local unitDefID = Spring.GetUnitDefID(unitID)
		local radius = unitDefRadius[unitDefID]
		if not radius then
			unitDefRadius[unitDefID] = Spring.GetUnitDefDimensions(unitDefID)["radius"]
		end
		inWater[unitID] = true
	end
end

function widget:UnitLeftLos(unitID)
	inWater[unitID] = nil
end

function widget:UnitLeftWater(unitID, unitDefID, teamID)
	if unitDefID then
		inWater[unitID] = nil
	end
end

function widget:UnitCreated(unitID, unitDefID, teamID)
	local _,_,_,_,midY = Spring.GetUnitPosition(unitID,true)
	if midY < 0 and teamID ~= gaiaID then
		local radius = unitDefRadius[unitDefID]
		if not radius then
			unitDefRadius[unitDefID] = Spring.GetUnitDefDimensions(unitDefID)["radius"]
		end
		inWater[unitID] = true
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	inWater[unitID] = nil
end


function widget:DrawWorld()
	gl.DepthTest(true)
	gl.PolygonOffset(-2, -2)
	
	local water = Spring.GetWaterMode()
	local r,g,b,a
	if water == 0 then
		gl.Blending(GL.DST_COLOR, GL.ZERO)
		r,g,b,a = 0.3,0.7,0.9,0.8 --blue
	elseif water == 1 then
		gl.Blending(GL.DST_COLOR, GL.ZERO)
		r,g,b,a = 0.3,0.7,0.9,0.8 --blue
	elseif water == 2 then
		return -- doesn't work in water 2
	elseif water == 3 then
		gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
		r,g,b,a = 0,0.2,0.6,0.5 --blue
	elseif water == 4 then
		gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
		r,g,b,a = 0.2,0.4,0.8,0.4 --blue
	end
	
	if (smoothPolys) then
		gl.Smoothing(nil, nil, true)
	end

	gl.TexCoord(0, 0)
	gl.TexGen(GL.T, GL.TEXTURE_GEN_MODE, GL.EYE_LINEAR)
	gl.TexGen(GL.T, GL.EYE_PLANE, 0, 1 , 0, 1)
	gl.Texture(texName)

	for _, uID in pairs(Spring.GetVisibleUnits()) do
		if inWater[uID] then
			local _,_,_,_,midY = Spring.GetUnitPosition(uID,true)
			local unitDefID = Spring.GetUnitDefID(uID)
			local unitDef = UnitDefs[unitDefID]
			if unitDef then
				local radius = unitDefRadius[unitDefID]
				if not radius then
					unitDefRadius[unitDefID] = Spring.GetUnitDefDimensions(unitDefID)["radius"]
				end

				if midY and (midY < 0) and radius and (midY + radius < 0) then
					gl.Color(r,g,b,a)
					gl.Unit(uID,true)
				end
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