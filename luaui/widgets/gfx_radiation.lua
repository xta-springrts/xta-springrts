function widget:GetInfo()
	return {
		name = "FX radiation",
		desc = "Make radioactive units greenish, can be fps expensive",
		author = "Jools & Floris, reworked by res",
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
			- units that obtain radiation yellow
			- and circles the area/units that have radiation

	--]]


-- LOCALS

local random							= math.random
local max								= math.max
local min								= math.min
local pairs								= pairs
local sin								= math.sin
local cos 								= math.cos
local pi								= math.pi
local floor                     		= math.floor

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
local GetUnitsInSphere					= Spring.GetUnitsInSphere
local ValidUnitID						= Spring.ValidUnitID
local IsUnitVisible						= Spring.IsUnitVisible
local IsUnitAllied						= Spring.IsUnitAllied
local myTeam 							= Spring.GetLocalAllyTeamID()
local glDrawListAtUnit        			= gl.DrawListAtUnit

local IsUnitVisible						= Spring.IsUnitVisible
local GetUnitLosState 					= Spring.GetUnitLosState
local baseParts                       	= 50      -- how many sided circle?
local baseOuterSize                   	= 1.30    -- outer fade size compared to circle scale (1 = no outer fade)
local intensity
local fxParts                         = 50
local fxWidth                         = 0.2    -- 1 = 100%


-- test to make units better drawn
local cloakedUnits						= {}

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
	else
		return false
	end
end


function widget:Initialize()
	if modOptions and modOptions.lowcpu == "1" then
		Spring.Log("widget", LOG.INFO, 'Low performance mode is on, removing "gfx_radiation" widget')
		widgetHandler:RemoveWidget()
		return
	elseif gl.CreateShader then
		local visibleUnits = getAllUnits()
		--local visibleUnits = GetVisibleUnits(-1,nil,true)
		for index, unitID in pairs(visibleUnits) do
			add_radiation_unit(unitID)
			--if IsUnitInView(unidID) then
			--	visibleUnits[unitID] = true
			--end
		end
	else
		Spring.Log("widget", LOG.INFO, 'no glsl')
		widgetHandler:RemoveWidget()
		return
	end
end


function widget:UnitDestroyed(unitID)
	radiation_units[unitID] = nil
	cloakedUnits[unitID] = nil
end


local function update_radiation()
	local visibleUnits = getAllUnits()
	--local visibleUnits = GetVisibleUnits(-1,nil,true)
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





local function drawSpottersBaseOuter()
   local radstep = (2.0 * pi) / baseParts
   for i = 1, baseParts do
       local a1 = (i * radstep)
       local a2 = ((i+1) * radstep)
       --(colorSet)
       gl.Color(intensity, 1, intensity, 0.5) -- baseOpacity)
       gl.Vertex(sin(a1), 0, cos(a1))
       gl.Vertex(sin(a2), 0, cos(a2))
       --(fadeto)
       gl.Color(intensity, 1, intensity, 0.5)
       gl.Vertex(sin(a2)*baseOuterSize, 0, cos(a2)*baseOuterSize)
       gl.Vertex(sin(a1)*baseOuterSize, 0, cos(a1)*baseOuterSize)
   end
end


local function round(num, idp)
    local mult = 10^(idp or 0)
    return floor(num * mult + 0.5) / mult
end





local function drawSpotters()

   if true then

       if baseOuterSize ~= 1 then
           gl.BeginEnd(GL.QUADS, drawSpottersBaseOuter)
       end
   end

   if true then --FX?
       local parts = round(fxParts * 0.2, 0) -- 0.2 == fx multiplier
       local width = fxWidth
       if true then     --fxDetailOffset
           parts = round(parts / 1.5), 0
           width = width / 1.5
       end
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

		-- radiation areas (and units not seen)
		if radiation_units[unitID] == nil then

			-- only areas
			if not ValidUnitID(unitID) then

				if GetGameRulesParam('radiation_damage' .. unitID) ~= nil and GetGameRulesParam('radiation_damage' .. unitID) ~= 0 then

					local radius = GetGameRulesParam('radiation_radius' .. unitID)
					intensity = 1-min(max(0,GetGameRulesParam('radiation_damage' .. unitID)),1)

					gl.Color(intensity,1,intensity,a) 	--green
					gl.DrawGroundCircle(v.x, v.y, v.z, radius, 50)
					gl.Color(0.5,0.5,0.5,a) 	--black/gray
					gl.DrawGroundCircle(v.x, v.y, v.z, radius+1, 50)

					gl.Color(intensity,1,intensity,a) 	--green

					local temp = GetGameRulesParam('radiation_damage' .. unitID)
					local effectedUnits = GetUnitsInSphere(v.x,v.y,v.z, radius)
					for index, uID in pairs(effectedUnits) do
						if uID ~= unitID and radiation_units[uID] == nil then
							gl.Color(1, 1, max(intensity-0.2,0), a) --yellow
							gl.Unit(uID,true)
						end
					end

				else
					radiation_areas[unitID] = nil
				end

			end



		-- radiation units
		else

			if ValidUnitID(unitID) then

				if GetGameRulesParam('radiation_damage' .. unitID) ~= nil and GetGameRulesParam('radiation_damage' .. unitID) ~= 0 then

					-- maybe: local los = Spring.GetUnitLosState(targetID,allyTeam,false)
					-- if los and los.los then
					if not (cloakedUnits[unitID] ~= nil and not IsUnitAllied(unitID)) then

						--maybe this works
						local visible = IsUnitVisible(unitID, nil, true)
						local state = GetUnitLosState(unitID, myTeam, false)

						if state and state.los and visible then

							intensity = 1-min(max(0,GetGameRulesParam('radiation_damage' .. unitID)),1)
							local radius = GetGameRulesParam('radiation_radius' .. unitID)
							gl.Color(max(intensity-0.1,0),1,max(intensity-0.1,0),a) --green
							gl.Unit(unitID,true)
							local x,y,z = GetUnitPosition(unitID)
							radiation_areas[unitID].x = x
							radiation_areas[unitID].y = y
							radiation_areas[unitID].z = z

							gl.Color(0.5,0.5,0.5,a) 	--black
							gl.DrawGroundCircle(x, y, z, radius+1, 50)

							local temp = gl.CreateList(drawSpotters)
							glDrawListAtUnit(unitID, temp, false, radius, 1.0, radius, 45, 0,1,0)

							local effectedUnits = GetUnitsInSphere(x,y,z, radius)
							for index, uID in pairs(effectedUnits) do
								if uID ~= unitID and radiation_units[uID] == nil then
									gl.Color(1, 1, max(intensity-0.2,0), a) --yellow
									gl.Unit(uID,true)
								end
							end

						end

					end

				end
			else
				radiation_units[unitID] = nil
				cloakedUnits[unitID] = nil
			end
		end
	end
	gl.DepthTest(false)
    gl.Color(1, 1, 1, 1)

end


-- this needs a test!

--

function widget:UnitCloaked(unitID, unitDefID, unitTeam)
	cloakedUnits[unitID] = true
end

function widget:UnitDecloaked(unitID, unitDefID, unitTeam)
	cloakedUnits[unitID] = nil
end

function widget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
	local update = add_radiation_unit(unitID)
	if update then
		update_radiation()
	end
end

function widget:UnitLeftLos(unitID, unitTeam, allyTeam, unitDefID)
	if radiation_areas[unitID] ~= nil or radiation_units[unitID] ~= nil then
		radiation_areas[unitID] = nil
		radiation_units[unitID] = nil
		update_radiation()
	end
end