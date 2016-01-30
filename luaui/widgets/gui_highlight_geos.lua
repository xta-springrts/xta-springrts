
function widget:GetInfo()
	return {
		name      = 'Highlight Geos',
		desc      = 'Highlights geothermal spots when in metal map view',
		author    = 'Niobium',
		version   = '1.0',
		date      = 'Mar, 2011',
		license   = 'GNU GPL, v2 or later',
		layer     = 0,
		enabled   = true,  --  loaded by default?
	}
end

----------------------------------------------------------------
-- Globals
----------------------------------------------------------------
local geoDisplayList
local Echo = Spring.Echo
local DTid = UnitDefNames["arm_dragons_teeth"].id
local geoUnits = {
	[UnitDefNames["arm_geothermal_powerplant"].id] = true,
	[UnitDefNames["core_geothermal_powerplant"].id] = true,
	[UnitDefNames["lost_geothermal_powerplant"].id] = true,
	[UnitDefNames["guardian_geothermal_powerplant"].id] = true,
}
local updateFrame = nil
	
----------------------------------------------------------------
-- Speedups
----------------------------------------------------------------
local glLineWidth = gl.LineWidth
local glDepthTest = gl.DepthTest
local glCallList = gl.CallList
local glColor = gl.Color
local spGetMapDrawMode = Spring.GetMapDrawMode

----------------------------------------------------------------
-- Functions
----------------------------------------------------------------
local function PillarVerts(x, y, z)
	gl.Color(1, 1, 0, 1)
	gl.Vertex(x, y, z)
	gl.Color(1, 1, 0, 0)
	gl.Vertex(x, y + 1000, z)
end

local function HighlightGeos()
	local features = Spring.GetAllFeatures()
	for i = 1, #features do
		local fID = features[i]
		if FeatureDefs[Spring.GetFeatureDefID(fID)].geoThermal then
			local fx, fy, fz = Spring.GetFeaturePosition(fID)
			local blocking = Spring.TestBuildOrder(DTid,fx,fy,fz,0)
			
			if (blocking == 1 or blocking == 2) then
				gl.BeginEnd(GL.LINE_STRIP, PillarVerts, fx, fy, fz)
			end
		end
	end
end

function widget:GameFrame(frame)
	if updateFrame and frame > updateFrame + 8 then
		updateFrame = nil
		geoDisplayList = nil
	end
end

----------------------------------------------------------------
-- Callins
----------------------------------------------------------------
function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if geoUnits[unitDefID] then
		updateFrame = Spring.GetGameFrame()
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, preEvent)
	if preEvent == false then return end
	
	if geoUnits[unitDefID] then
		updateFrame = Spring.GetGameFrame()
	end
end

function widget:Shutdown()
	if geoDisplayList then
		gl.DeleteList(geoDisplayList)
	end
end

function widget:DrawWorld()
	
	if spGetMapDrawMode() == 'metal' then
		
		if not geoDisplayList then
			geoDisplayList = gl.CreateList(HighlightGeos)
		end
		
		glLineWidth(20)
		glDepthTest(true)
		glCallList(geoDisplayList)
        glColor(1, 1, 1, 1)
		glLineWidth(1)
	end
end
