function gadget:GetInfo()
  return {
    name      = "Minelayer Limit",
    desc      = "Limit the amount of mines that minelayers can lay",
	version   = "1.0",
    author    = "Jools",
    date      = "Mar, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

local Echo 								= Spring.Echo
local CMD_NIL 							= 37577
local MINEAMOUNT_ARM						= 5
local MINEAMOUNT_CORE						= 6
local MINEAMOUNT_WATER						= 8

if (gadgetHandler:IsSyncedCode()) then
----------------------
-- SYNCED CODE 		--
----------------------
	local minelayerDefTable = {}
	
	local minelayerUnits = {
        arm_podger = true,
        core_spoiler = true,
		arm_valiant = true,
		core_limiter = true,
        }

	local mineTable = {}

	local mineNames = {
		-- arm_drip = true, exclude minesweepers
		-- arm_fart_mine = true, exclude minesweepers
		-- arm_fart_spidey = true, exclude sweepers
		arm_kaboom_mine = true,
		arm_mini_mine = true,
		arm_ooomph_mine = true,
		arm_popper_mine = true,
		arm_riptide = true,
		arm_surf = true,
		arm_surprise_mine = true,
		arm_upsurge = true,
		arm_water_wrinkle = true,
		core_donut = true,
		core_marshmallow = true,
		core_mazarin = true,
		core_muffin = true,
		-- core_nugget = true, exclude sweepers
		-- core_nugget_tic = true, exclude sweepers
		core_ripple = true,
		core_rogue_wave = true,
		core_shock_mine = true,
		core_spout = true,
		core_waterhole = true,
		-- core_wave = true, exclude minesweepers
	}	
	
	local minedescarm= {
	name 			= MINEAMOUNT_ARM .. " mines left",
	action			= "",
	disabled  		= true,
	id				= CMD_NIL,
	type			= CMDTYPE.ICON_AREA,
	tooltip			= "Stock of mines: " .. MINEAMOUNT_ARM,
	cursor			= "cursorattack",
	texture     	= 'unitpics/arm_genmine.png'
	}
	
	local minedesccore= {
	name 			= MINEAMOUNT_CORE .. " mines left",
	action			= "",
	disabled  		= true,
	id				= CMD_NIL,
	type			= CMDTYPE.ICON_AREA,
	tooltip			= "Stock of mines: " .. MINEAMOUNT_CORE,
	cursor			= "cursorattack",
	texture     	= 'unitpics/core_genmine.png'
	}
	
	local minedescwater= {
	name 			= MINEAMOUNT_WATER .. " mines left",
	action			= "",
	disabled  		= true,
	id				= CMD_NIL,
	type			= CMDTYPE.ICON_AREA,
	tooltip			= "Stock of mines: " .. MINEAMOUNT_WATER,
	cursor			= "cursorattack",
	texture     	= 'unitpics/water_genmine.png'
	}
	
	local mineDescID = 3 -- just a random command desc ID that works. Programmer is too stoopid/lazy to find out the right way to do it.
	
	function gadget:Initialize()
		for id,unitDef in pairs(UnitDefs) do
			local uName = unitDef.name
			if minelayerUnits[uName] then
				minelayerDefTable[unitDef.id] = true
			end
        end
	end

	local function getSide(unitname)
		if unitname == 'arm_podger' then
			return "arm"
		elseif unitname == 'core_spoiler' then
			return "core"
		else
			return "water"
		end
	end
	
	function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)	
		if cmdID < 0 and UnitDefs[-cmdID] then
			if mineNames[UnitDefs[-cmdID].name] then
				if mineTable[unitID] > 0 then
					mineTable[unitID] = mineTable[unitID] - 1
					local tex = ""
					if getSide(UnitDefs[unitDefID].name) == "arm" then
						tex = 'unitpics/arm_genmine.png'
					elseif getSide(UnitDefs[unitDefID].name) == "core" then
						tex = 'unitpics/core_genmine.png'
					else
						tex = 'unitpics/water_genmine.png'
					end
					
					if mineTable[unitID] == 1 then
						Spring.EditUnitCmdDesc(unitID, mineDescID, {
								name 			= "1 mine left",
								action			= "",
								disabled  		= true,
								id				= CMD_NIL,
								type			= CMDTYPE.ICON_AREA,
								tooltip			= "Stock of mines: " .. mineTable[unitID],
								cursor			= "cursorattack",
								texture     	= tex
						})
					else
						Spring.EditUnitCmdDesc(unitID, mineDescID, {
								name 			= mineTable[unitID] .. " mines left",
								action			= "",
								disabled  		= true,
								id				= CMD_NIL,
								type			= CMDTYPE.ICON_AREA,
								tooltip			= "Stock of mines:" .. mineTable[unitID],
								cursor			= "cursorattack",
								texture     	= tex
						})
					end
					--Echo("Mine built!", UnitDefs[-cmdID].name)
					return true
				else
					Echo(UnitDefs[unitDefID].humanName..": Mine storage empty.")
					return false
				end
			end
		end
		return true
	end


	function gadget:UnitCreated(unitID, unitDefID, teamID, builderID) 
		if minelayerDefTable[unitDefID] then
			if getSide(UnitDefs[unitDefID].name) == "arm" then
				mineTable[unitID] = MINEAMOUNT_ARM
				Spring.InsertUnitCmdDesc(unitID, mineDescID, minedescarm)
			elseif getSide(UnitDefs[unitDefID].name) == "core" then
				mineTable[unitID] = MINEAMOUNT_CORE
				Spring.InsertUnitCmdDesc(unitID, mineDescID, minedesccore)
			else
				mineTable[unitID] = MINEAMOUNT_WATER
				Spring.InsertUnitCmdDesc(unitID, mineDescID, minedescwater)
			end
			
		end
	end

	function gadget:UnitFinished(unitID, unitDefID, teamID)
		
	end

	function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
		if minelayerDefTable[unitDefID] then
			mineTable[unitID] = nil
		end
	end
	
else
	-- No unsynced code
end