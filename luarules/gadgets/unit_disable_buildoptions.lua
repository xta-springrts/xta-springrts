-- $Id: unit_disable_buildoptions.lua 3636 2009-01-02 22:57:43Z evil4zerggin $
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name	= "Disable Buildoptions",
		desc	= "Disables units if wind is too low/high, or if waterdepth is not appropriate.",
		author	= "quantum", -- modified for XTA by Deadnight Warrior
		date	= "May 11, 2008",
		license = "GNU GPL, v2 or later",
		layer	= 0,
		enabled = true	--	loaded by default?
	}
end

--------------------------------------------------------------------------------
--config
--------------------------------------------------------------------------------

local breakEvenWind = 9.1
local modOptions = Spring.GetModOptions()
local windLowMess = "Wind generator disabled: Wind is too weak on this map."
local hovAtmLowMess = "Hovercrafts disabled: Atmosphere pressure too low on this map."
local airAtmLowMess = "Aircrafts disabled: Atmosphere pressure too low on this map."
local windExtrMess = "Aircrafts disabled: Wind speed too extreme on this map."
--------------------------------------------------------------------------------
--speedups
--------------------------------------------------------------------------------

local FindUnitCmdDesc = Spring.FindUnitCmdDesc
local GetUnitPosition = Spring.GetUnitPosition
local GetGroundHeight = Spring.GetGroundHeight
local GetUnitPosition = Spring.GetUnitPosition
local disableWind
local disableAir = 0
local disableHovers = false
--values: {unitID, reason,}
local alwaysDisableTable = {}

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------


if (not gadgetHandler:IsSyncedCode()) then
	return false
end


local function DisableBuildButtons(unitID, disableTable)
	for _, disable in ipairs(disableTable) do
		local cmdDescID = Spring.FindUnitCmdDesc(unitID, -disable[1])
		if (cmdDescID) then
			local cmdArray = {disabled = true, tooltip = disable[2]}
			Spring.EditUnitCmdDesc(unitID, cmdDescID, cmdArray)
		end
	end
end

function gadget:Initialize()
	disableWind = Game.windMax < breakEvenWind
	if not modOptions.space_mode or (modOptions.space_mode and modOptions.space_mode=="0") then
		local map = Game.mapHumanName:lower()
		if Game.windMin <= 1 and Game.windMax <= 4 then
			disableAir = 1
			disableHovers = true
		elseif map:find("comet") or map:find("moon") then
			disableAir = 1
			disableHovers = true
		end
		if Game.windMin >= 30 or Game.windMax >= 35 then
			disableAir = 2
		end
	end
	if (disableWind) then
		table.insert(alwaysDisableTable, {UnitDefNames["arm_wind_generator"].id, windLowMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["core_wind_generator"].id, windLowMess,})
	end
	if (disableHovers) then
		table.insert(alwaysDisableTable, {UnitDefNames["arm_hovercraft_platform"].id, hovAtmLowMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["core_hovercraft_platform"].id, hovAtmLowMess,})
	end
	if (disableAir==1) then
		table.insert(alwaysDisableTable, {UnitDefNames["arm_aircraft_plant"].id, airAtmLowMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["arm_adv_aircraft_plant"].id, airAtmLowMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["arm_seaplane_platform"].id, airAtmLowMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["core_aircraft_plant"].id, airAtmLowMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["core_adv_aircraft_plant"].id, airAtmLowMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["core_seaplane_platform"].id, airAtmLowMess,})
	elseif (disableAir==2) then
		table.insert(alwaysDisableTable, {UnitDefNames["arm_aircraft_plant"].id, windExtrMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["arm_adv_aircraft_plant"].id, windExtrMess,})	
		table.insert(alwaysDisableTable, {UnitDefNames["arm_seaplane_platform"].id, windExtrMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["core_aircraft_plant"].id, windExtrMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["core_adv_aircraft_plant"].id, windExtrMess,})
		table.insert(alwaysDisableTable, {UnitDefNames["core_seaplane_platform"].id, windExtrMess,})
	end
end

function gadget:UnitCreated(unitID, unitDefID)
	local disableTable = {}
	local unitDef = UnitDefs[unitDefID]
	local posX, posY, posZ = GetUnitPosition(unitID)
	local groundheight = GetGroundHeight(posX, posZ)
	
	for key, value in ipairs(alwaysDisableTable) do
		disableTable[key] = value
	end
	
	--amph facs
	if (unitDef.isFactory and unitDef.buildOptions) then
		for _, buildoptionID in ipairs(unitDef.buildOptions) do
			if (UnitDefs[buildoptionID] and UnitDefs[buildoptionID].moveData) then
				local moveData = UnitDefs[buildoptionID].moveData
				if (moveData and moveData.family and moveData.depth) then
					if (moveData.family == "ship") then
						if (-groundheight < moveData.depth) then
							table.insert(disableTable, {buildoptionID, "Unit disabled: Water is too shallow here."})
						end
					elseif (moveData.family ~= "hover") then
						if (-groundheight > moveData.depth) then
							table.insert(disableTable, {buildoptionID, "Unit disabled: Water is too deep here."})
						end
					end
				end
			end
		end
	end
	
	DisableBuildButtons(unitID, disableTable)
end

-- AllowCommand is probably overkill

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

