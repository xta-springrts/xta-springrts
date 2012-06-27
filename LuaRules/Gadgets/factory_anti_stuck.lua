function gadget:GetInfo()
  return {
    name      = "Factory Anti-Stuck",
    desc      = "Teleports units out from factory build area, workaround for QTPFS bug",
    author    = "Deadnight Warrior",
    date      = "27 Jun 2012",
    license   = "GNU LGPL, v2 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitVectors = Spring.GetUnitVectors
local spGetUnitRadius = Spring.GetUnitRadius
local spSetUnitPosition = Spring.SetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight

local problemMoveDefs = {
	--mediumboat = true,
	--kbotsf3 = true,
	--kbotuw3 = true,
	tankbh3 = true,
	tankdh3 = true,
	tankdtcrush = true,
	tankhover4 = true,
	tanksh3 = true,
	tanksh4 = true,
	--boatsub = true,
}
local problemFactories = {
	arm_kbot_lab = true,
	core_kbot_lab = true,
	arm_adv_kbot_lab = true,
	core_adv_kbot_lab = true,
	arm_vehicle_plant = true,
	core_vehicle_plant = true,
	arm_adv_vehicle_plant = true,
	core_adv_vehicle_plant = true,
}

function gadget:Initialize()
	local modOptions = Spring.GetModOptions()
	Spring.Echo(modOptions.qtpfs)
	if (not modOptions) or (not modOptions.qtpfs) or modOptions.qtpfs ~= "1" then
		gadgetHandler:RemoveGadget()
	end
end
	
if (gadgetHandler:IsSyncedCode()) then

function gadget:UnitFromFactory(unitID, unitDefID, teamID, factoryID, factoryDefID)
	--if problemMoveDefs[UnitDefs[unitDefID].moveData.name] and problemFactories[UnitDefs[factoryDefID].name] then
	if problemFactories[UnitDefs[factoryDefID].name] then
		local x, y, z = spGetUnitPosition(unitID)
		local v = spGetUnitVectors(factoryID)
		local r = spGetUnitRadius(unitID)*2 + 16
		local px, pz = x + v[1]*r, z + v[3]*r
		local gh = spGetGroundHeight(px,pz)
		spSetUnitPosition(unitID, px, gh, pz)
	end
end

end
