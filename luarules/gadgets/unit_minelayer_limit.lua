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

	local InsertUnitCmdDesc 				= Spring.InsertUnitCmdDesc
	local EditUnitCmdDesc					= Spring.EditUnitCmdDesc
	local GetUnitCommands					= Spring.GetUnitCommands
	local minelayerDefTable 				= {} -- table with minelayer unitdefID:s
	local mineDefTable						= {}
	
	local minelayerStock					= {} -- table with the stock of mines by minelayer unitid 
	local pendingMines						= {} -- table by builderID of pending mines
	
	local mineDescID 						= 3 -- just a random command desc ID that works. Programmer is too stoopid/lazy to find out the right way to do it.
	
	local minelayerNames = {				-- table of minelayer unit names
		arm_podger = true,
		core_spoiler = true,
		arm_valiant = true,
		core_limiter = true,
		tadg05 = true, -- Filcher
		tadg06 = true, -- Vandal
	}	

	local mineNames = {						-- table of mine unit names
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
	
	local MD_arm	= 	{
		name 			= MINEAMOUNT_ARM .. " mines left",
		action			= "",
		disabled  		= true,
		id				= CMD_NIL,
		type			= CMDTYPE.ICON_AREA,
		tooltip			= "Stock of mines: " .. MINEAMOUNT_ARM,
		cursor			= "cursorattack",
		texture     	= 'unitpics/arm_genmine.png'
		}	
	local MD_core		= {
		name 			= MINEAMOUNT_CORE .. " mines left",
		action			= "",
		disabled  		= true,
		id				= CMD_NIL,
		type			= CMDTYPE.ICON_AREA,
		tooltip			= "Stock of mines: " .. MINEAMOUNT_CORE,
		cursor			= "cursorattack",
		texture     	= 'unitpics/core_genmine.png'
		}
	local MD_water		= {
		name 			= MINEAMOUNT_WATER .. " mines left",
		action			= "",
		disabled  		= true,
		id				= CMD_NIL,
		type			= CMDTYPE.ICON_AREA,
		tooltip			= "Stock of mines: " .. MINEAMOUNT_WATER,
		cursor			= "cursorattack",
		texture     	= 'unitpics/water_genmine.png'
		}
		
	
	function gadget:Initialize()
		for id,unitDef in pairs(UnitDefs) do
			local uName = unitDef.name
			if minelayerNames[uName] then
				minelayerDefTable[unitDef.id] = true
			end
			
			if mineNames[uName] then
				mineDefTable[unitDef.id] = true
			end
			
        end
	end

	local function getSide(unitname)
		if unitname == "arm_podger" or unitname == "tadg05" then
			return "arm"
		elseif unitname == "core_spoiler"  or unitname == "tadg06" then
			return "core"
		else
			return "water"
		end
	end
	
	local function countMineQueue(unitID, limit)
		local queue = GetUnitCommands(unitID)
		local mines = 0
		for _, cmd in pairs(queue) do
			if mineDefTable[-cmd["id"]] then 
				mines = mines + 1
				if mines > limit then break end
			end
		end
		--Echo("Mines pending: ",mines,"/",limit)
		return mines
	end
	
	local function isOrderCancellation(unitID, cmdID, cmdParams)
		local queue = GetUnitCommands(unitID)
		local x = cmdParams[1]
		local y = cmdParams[2]
		local z = cmdParams[3]
		
		for i, cmd in pairs(queue) do
			local params = cmd["params"]
			if cmd["id"] == cmdID and params[1] == x and params[2] == y and params[3] == z then
				return true
			end
		end
		return false
	end

	function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
		
		if cmdID < 0 and mineDefTable[-cmdID] then
			if mineNames[UnitDefs[-cmdID].name] then
				local stock = minelayerStock[unitID] or 0
				if stock == 0 then
					return false
				else
					local pendingMines = countMineQueue(unitID, stock)
					if not stock or not pendingMines then
						Echo("Error in minelayer limit gadget. Stock:", stock, " Queue: ", pendingMines)
					end
					if  stock > pendingMines then
						return true
					elseif stock == pendingMines then
						if isOrderCancellation(unitID, cmdID, cmdParams) then
							return true
						else
							return false
						end
					else
						return false
					end
				end
			end
		end
		return true
	end

	function gadget:UnitCreated(unitID, unitDefID, teamID, builderID) 
		if minelayerDefTable[unitDefID] then
			if getSide(UnitDefs[unitDefID].name) == "arm" then
				minelayerStock[unitID] = MINEAMOUNT_ARM
				InsertUnitCmdDesc(unitID, mineDescID, MD_arm)
			elseif getSide(UnitDefs[unitDefID].name) == "core" then
				minelayerStock[unitID] = MINEAMOUNT_CORE
				InsertUnitCmdDesc(unitID, mineDescID, MD_core)
			else
				minelayerStock[unitID] = MINEAMOUNT_WATER
				InsertUnitCmdDesc(unitID, mineDescID, MD_water)
			end
		end
		
		if mineDefTable[unitDefID] then
			pendingMines[unitID] = builderID
		end
	end

	function gadget:UnitFinished(unitID, unitDefID, teamID)
		local builderID = pendingMines[unitID] or nil 
		
		if builderID then
			if minelayerStock[builderID] > 0 then
				minelayerStock[builderID] = minelayerStock[builderID] -1
				pendingMines[unitID] = nil
				
				local builderDefID = Spring.GetUnitDefID(builderID)
				local tex = ""
				local caption
				
				-- get current stock for button caption
				if minelayerStock[builderID] == 0 then
					caption = "No mines"
				elseif minelayerStock[builderID] == 1 then
					caption = "1 mine left"
				else
					caption = minelayerStock[builderID].. " mines left"
				end
					
				-- get minelayer side for caption
				if getSide(UnitDefs[builderDefID].name) == "arm" then
					tex = 'unitpics/arm_genmine.png'
				elseif getSide(UnitDefs[builderDefID].name) == "core" then
					tex = 'unitpics/core_genmine.png'
				else
					tex = 'unitpics/water_genmine.png'
				end
				
				-- change button caption
				EditUnitCmdDesc(builderID, mineDescID, {
					name 			= caption,
					action			= "",
					disabled  		= true,
					id				= CMD_NIL,
					type			= CMDTYPE.ICON_AREA,
					tooltip			= "Stock of mines:" .. minelayerStock[builderID],
					cursor			= "cursorattack",
					texture     	= tex
					}
				)
									
				--Echo("Mine built!", UnitDefs[unitDefID].humanName)
			else
			-- if minelayer has no stock, mine was built using an exploit: remove mine
				Spring.DestroyUnit(unitID,false,true)
			end
		end
	end

	function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
		if minelayerDefTable[unitDefID] then
			minelayerStock[unitID] = nil
		end
	end
	
else
	-- No unsynced code
end