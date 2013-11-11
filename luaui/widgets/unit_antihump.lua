function widget:GetInfo()
	return {
		name      = "Anti Hump",
		desc      = "Stops humping units",
		author    = "Deadnight Warrior",
		date      = "22 Oct 2013",
		license   = "GNU LGPL v2",
		layer     = 0,
		enabled   = false
	}
end

local udefTab				= UnitDefs
local spGetSelectedUnits	= Spring.GetSelectedUnits
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitHeading		= Spring.GetUnitHeading
local spGiveOrderToUnit		= Spring.GiveOrderToUnit
local spGetGameFrame		= Spring.GetGameFrame
local sqrt					= math.sqrt
local abs					= math.abs
local pairs					= pairs
local diag = math.diag
local HeadToTR = 360/65536/0.16

local movingUnits = {}

----------------------------------------------------------------


function widget:PlayerChanged(playerID)
	local _, active = Spring.GetPlayerInfo(playerID)
	if active~=true then
		widgetHandler:RemoveWidget()
	end
end

function widget:Initialize()
	local _, _, spec, _, _, _, _, _ = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
	if spec==true then
		widgetHandler:RemoveWidget()
	end
end

function widget:CommandNotify(id, params, options)
	if id == CMD.MOVE or id<0 then
		local selUnits = spGetSelectedUnits()
		for i=1, #selUnits do
			local unitID = selUnits[i]
			local unitDefID = spGetUnitDefID(unitID)
			if not udefTab[unitDefID].canFly then
				local x,y,z = spGetUnitPosition(unitID)
				movingUnits[unitID] = {x, y, z, spGetUnitHeading(unitID), unitDefID, spGetGameFrame()}
			end
		end
	elseif id == CMD.STOP then
		local selUnits = spGetSelectedUnits()
		for i=1, #selUnits do
			movingUnits[selUnits[i]] = nil
		end
	end
end

function widget:GameFrame(n)
	if n%60==0 then
		for unitID, pos in pairs(movingUnits) do
			local x,y,z = spGetUnitPosition(unitID)
			local head = spGetUnitHeading(unitID)
			if (diag(x - pos[1], y - pos[2], z - pos[3]) < udefTab[pos[5]].speed) and (abs(head - pos[4])*HeadToTR < udefTab[pos[5]].turnRate) and (n-pos[6] >= 60) then
				if Spring.GetUnitIsBuilding(unitID)==nil then
					spGiveOrderToUnit(unitID, CMD.STOP, {}, {})
				end
				movingUnits[unitID] = nil
			else
				movingUnits[unitID] = {x, y, z, head, pos[5], n}
			end
		end
	end
end