--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "DontMove - XTA",
    desc      = "Sets some long ranged units on hold position.",
    author    = "quantum",
    date      = "Jan 8, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetUnitDefID = Spring.GetUnitDefID
local myTeamID = Spring.GetMyTeamID()

local unitSet = {}

local unitArray = {
	"arm_commander",
	"arm_decoy_commander",
	"arm_u0commander",
	"arm_ucommander",
	"arm_u2commander",
	"arm_u3commander",
	"arm_u4commander",
	"arm_scommander",
	"armcom",
	"arm_base",
	"arm_nincommander",
	"core_commander",
	"core_decoy_commander",
	"core_u0commander",
	"core_ucommander",
	"core_u2commander",
	"core_u3commander",
	"core_u4commander",
	"core_scommander",
	"corcom",
	"core_base",
	"core_nincommander",

	"arm_rocko",
	"arm_rocko_rt",
	"core_storm",
	"core_storm_rt",
	"arm_jethro",
	"arm_jethro_rt",
	"core_crasher",
	"core_crasher_rt",
	"arm_samson",
	"arm_samson_rt",
	"core_slasher",
	"core_slasher_rt",
	"arm_hammer",
	"core_thud",
	"arm_swatter",
	"arm_swatter_rt",
	"core_slinger",
	"core_slinger_rt",
	"core_morty",
	"arm_fido",
	"arm_luger",
	"core_diplomat",
	"core_diplomat_rt",
	"arm_penetrator",
	"core_mobile_artillery",
	"core_mobile_artilleryold",
	"core_krogoth",
	"arm_merl",
	"arm_merl_rt",
	"arm_shooter",
	"arm_sniper",
	"arm_raven",
	"arm_raven_rt",
	"core_dominator",
	"core_dominator_rt",
	"core_sumo",
	"core_can",
	"core_warlord",
	"arm_millenium",
	"arm_podger",
	"core_spoiler",
	"arm_eraser",
	"core_spectre",
	"arm_jammer",
	"core_deleter",
	"arm_scarab",
	"core_hedgehog",
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize() 
	for i, v in pairs(unitArray) do
		unitSet[v] = true
	end
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam)
	local ud = UnitDefs[unitDefID]
	if ((ud ~= nil) and (unitTeam == myTeamID)) then
		if (unitSet[ud.name]) then
			Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, { 0 }, {})
		end
	end
end

function widget:Update()
	if Spring.GetGameSeconds() > 1 then
		local modOptions = Spring.GetModOptions()
		if modOptions and modOptions.mission then
			for _, unitID in pairs(Spring.GetTeamUnits(myTeamID)) do
				widget:UnitFromFactory(unitID, spGetUnitDefID(unitID), myTeamID)
			end
		end
		widgetHandler:RemoveCallIn("Update")
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

