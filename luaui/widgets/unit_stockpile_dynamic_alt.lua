-------------------------------------------------------------------------------
--           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
--                   Version 2, December 2004
--
--Copyright (C) 2010 BrainDamage, Deadnight Warrior
--Everyone is permitted to copy and distribute verbatim or modified
--copies of this license document, and changing it is allowed as long
--as the name is changed.
--
--           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
--  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
--
-- 0. You just DO WHAT THE FUCK YOU WANT TO.
-------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Stockpiler (dynamic, alternate version) - XTA",
    desc      = "Keeps units with stockpilable ammo at some max in storage, uses fixed values, diferent for each unit",
    author    = "BD, Deadnight Warrior",
    date      = "tomorrow",
    license   = "WTFPL",
    layer     = 0,
    enabled   = false,  --  loaded by default?
  }
end

local GetTeamUnits 	= Spring.GetTeamUnits
local GetMyTeamID	= Spring.GetMyTeamID
local SetUnitGroup	= Spring.SetUnitGroup
local GetSpectatingState= Spring.GetSpectatingState
local GetUnitDefID 	= Spring.GetUnitDefID
local GetUnitStockpile	= Spring.GetUnitStockpile
local GiveOrderToUnit	= Spring.GiveOrderToUnit
local GetUnitDefID      = Spring.GetUnitDefID
local MaxStockpile = {}

-- set this array to desired stockpile levels for individual units or use "default"
MaxStockpile["default"] = 6	--default stockpile value
MaxStockpile["arm_raven_rt"] = 40
MaxStockpile["arm_protector"] = 12
MaxStockpile["arm_scarab"] = 12
MaxStockpile["arm_repulsor"] = 12
MaxStockpile["core_fortitude_missile_defense"] = 12
MaxStockpile["core_resistor"] = 12
MaxStockpile["core_hedgehog"] = 12
MaxStockpile["lost_peacemaker"] = 12
MaxStockpile["lost_turle"] = 12

function widget:Initialize()
	if GetSpectatingState() then
		widgetHandler:RemoveWidget()
		return
	end

	-- stockpile all existing units
	UpdateStockPileAllUnits()
end

function UpdateStockPileAllUnits()
	local allUnits = GetTeamUnits(GetMyTeamID())
	for _, unitID in pairs(allUnits) do
		local unitDefID = GetUnitDefID(unitID)
		local ud = UnitDefs[unitDefID]
		if ( ud and ud.canStockpile ) then
			CancelExcessStockpile(unitID)
			DoStockPile(unitID)
		end
	end
end

function widget:PlayerChanged(playerID)
	if GetSpectatingState() then
		widgetHandler:RemoveWidget()
		return
	end
end

function DoStockPile( unitID )
	local stock,queued = GetUnitStockpile(unitID)
	local stockMax = MaxStockpile[UnitDefs[GetUnitDefID(unitID)].name]
	if ( queued and stock ) then
		if (stockMax == nil) then 
			stockMax = MaxStockpile["default"]
		end
		local count = stock + queued - stockMax
		while ( count < 0 ) do
			if (count < -100) then
				GiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "ctrl", "shift" })
				count = count + 100
			elseif (count < -20) then
				GiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "ctrl" })
				count = count + 20
			elseif (count < -5) then
				GiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "shift" })
				count = count + 5
			else
				GiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "" })
				count = count + 1
			end
		end
	end
end

function CancelExcessStockpile( unitID )
	local stock,queued = GetUnitStockpile(unitID)
	local stockMax = MaxStockpile[UnitDefs[GetUnitDefID(unitID)].name]
	if ( queued and stock ) then
		if (stockMax == nil) then 
			stockMax = MaxStockpile["default"]
		end
		local count = stock + queued - stockMax
		while ( count > 0 ) do
			if (count > 100) then
				GiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "right", "ctrl", "shift" })
				count = count - 100
			elseif (count > 20) then
				GiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "right", "ctrl" })
				count = count - 20
			elseif (count > 5) then
				GiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "right", "shift" })
				count = count - 5
			else
				GiveOrderToUnit(unitID, CMD.STOCKPILE, {}, { "right" })
				count = count - 1
			end
		end
	end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	local ud = UnitDefs[unitDefID]
	if ((ud ~= nil) and (unitTeam == GetMyTeamID())) then
		if (ud.canStockpile) then
			CancelExcessStockpile( unitID ) -- theorically when a unit is created it should have no stockpiled items, but better be paranoid and add this, plus code can be reused for unit given and captured
			DoStockPile( unitID )
		end
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
	widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:UnitCaptured(unitID, unitDefID, unitTeam)
	widget:UnitCreated(unitID, unitDefID, unitTeam)
end

function widget:StockpileChanged(unitID, unitDefID, unitTeam, weaponNum, oldCount, newCount)
	if ( unitTeam == GetMyTeamID() ) then
		DoStockPile( unitID )
	end
end