local versionNumber = "1.0"

function widget:GetInfo()
	return {
	name = "Mousecursors - XTA",
	desc = "Make cursors relevant to action",
	author = "Jools",
	date = "Oct, 2013",
	license = "All rights reserved",
	layer = -1,
	enabled = true,
	--handler = true, --access to handler
	}
end


local CMD_ATTACK 							= CMD.ATTACK
local CMD_MOVE	 							= CMD.MOVE
local CMD_DGUN								= CMD.DGUN
local CMD_RESURRECT							= CMD.RESURRECT
local CMD_AIRSTRIKE 						= 36001
local CMD_CAPTURE							= CMD.CAPTURE
local CMD_REPAIR							= CMD.REPAIR
local CMD_GUARD								= CMD.GUARD
local CMD_AREA_GUARD						= 14001
local CMD_LOAD								= CMD.LOAD_UNITS
local CMD_LOAD_ONTO							= CMD.LOAD_ONTO
local CMD_UNLOAD							= CMD.UNLOAD_UNIT
local CMD_UNLOAD_ALL						= CMD.UNLOAD_UNITS
local CMD_RECLAIM							= CMD.RECLAIM

local Echo									= Spring.Echo
local EditUnitCmdDesc						= Spring.EditUnitCmdDesc
local FindUnitCmdDesc						= Spring.FindUnitCmdDesc
local InsertUnitCmdDesc						= Spring.InsertUnitCmdDesc
local RemoveUnitCmdDesc						= Spring.RemoveUnitCmdDesc
local GetUnitDefID							= Spring.GetUnitDefID
local GiveOrderToUnit						= Spring.GiveOrderToUnit
local ta_insert								= table.insert
local GetSelectedUnits						= Spring.GetSelectedUnits
local GetMouseState							= Spring.GetMouseState
local GetActiveCommand						= Spring.GetActiveCommand
local AssignMouseCursor						= Spring.AssignMouseCursor
local SetMouseCursor						= Spring.SetMouseCursor
local GetSpectatingState					= Spring.GetSpectatingState
local IsUnitAllied							= Spring.IsUnitAllied
local GetUnitTeam							= Spring.GetUnitTeam
local GetUnitHealth							= Spring.GetUnitHealth
local GetUnitPosition						= Spring.GetUnitPosition
local GetUnitDefDimensions					= Spring.GetUnitDefDimensions
local GetTeamResources						= Spring.GetTeamResources
local GetUnitIsTransporting					= Spring.GetUnitIsTransporting
local myTeamID
local FIRSTWEAPON							= 1
local GetSelectedUnitsCounts				= Spring.GetSelectedUnitsCounts
local AreTeamsAllied						= Spring.AreTeamsAllied
local transportHovers						= (Spring.GetModOptions() and (Spring.GetModOptions().mo_transporthover == "1") and 1) or 0 == 1
local waterWeapons 							= {}
local unitDefRadius							= {}
local unitDefWaterLine						= {}
local unitDefMidY							= {}

function widget:Initialize()
	AssignMouseCursor('Airstrike', "cursorairstrike", true, false)
	AssignMouseCursor('Normal', 'cursornormal', true, false)
	AssignMouseCursor('Select', 'cursorselect', true, false)
	AssignMouseCursor('UnloadBad', 'cursorunloadbad', true, false)
	AssignMouseCursor('LoadBad', 'cursorpickupbad', true, false)
	AssignMouseCursor('BuildSurfaced', 'cursorsurfaced', true, false)
	AssignMouseCursor('BuildSubmerged', 'cursorsubmerged', true, false)
	myTeamID = Spring.GetMyTeamID()
	
	if Game.version <= "94.1" then 
		FIRSTWEAPON	= 0
	end
			
	if Game.version <= "94.1" then 
		FIRSTWEAPON	= 0
	end
		
	for id,unitDef in pairs(UnitDefs) do
		local weapons = unitDef.weapons
		local canKamikaze = unitDef.canKamikaze and unitDef.speed > 0
		
		if weapons and #weapons > 0 then
			local weaponDefID = weapons[FIRSTWEAPON].weaponDef
			local waterWeapon = WeaponDefs[weaponDefID].waterWeapon
			
			if waterWeapon then waterWeapons[id] = true end
			
		elseif canKamikaze then
			waterWeapons[id] = true 
		end
	end
end

local function checktarget(uID, udefArray)
	local _,_,_,_,midY = GetUnitPosition(uID,true)
	
	if midY and midY < 0 then
		local uTeam = GetUnitTeam(uID)
		local allied = AreTeamsAllied(uTeam, myTeamID)
		if not allied then
		
			local uDef = UnitDefs[GetUnitDefID(uID) ]
			
			if not uDef then
				return -1 
			end
			
			local radius = GetUnitDefDimensions(uDef.id)["radius"]
			local speed = uDef.speed
			
			if radius and speed and midY and speed and midY + radius < 0 and speed == 0 then
				local canAttack = false
				local canCapture = false
				local canReclaim = false
				
				for unitDefID, cnt in pairs(udefArray) do
					if unitDefID ~= 'n' then
						local unitDef = UnitDefs[unitDefID]
						if waterWeapons[unitDefID] then
							canAttack = true
							break
						end							
						if unitDef.canCapture then canCapture = true end							
						if unitDef.canReclaim then canReclaim = true end
					end
				end
			
				if canAttack then
					return 0
				else
					if canCapture then
						return 1
					elseif canReclaim then
						return 2
					end
				end

				return 3
			end
		end
	end
	
	return -1
end

function widget:DefaultCommand(type, uID)

	local sU = GetSelectedUnits()
	local sUC = GetSelectedUnitsCounts()
		
	if not sUC then return end
	
	-- nothing selected, user points at object
	if sUC['n'] == 0 then
		if type == 'unit' then		
			if myTeamID == GetUnitTeam(uID) or GetSpectatingState() then
				SetMouseCursor('Select')
			end
		end		
	else
		-- user has selected one or more units
		local _, activeCmdID = GetActiveCommand()
		
		------------------------------------------------
		-- no command chosen: override default action --
		------------------------------------------------
		if not activeCmdID then
			-- unit points at self
			if sUC['n'] == 1 and type == 'unit' and sU[1] == uID then
				local thisHP, maxHP = GetUnitHealth(uID)
				local unitDefID = GetUnitDefID(uID)
			
				if thisHP < maxHP then
					if not UnitDefs[unitDefID].canSelfRepair then
						SetMouseCursor('Select')
					end
				else
					SetMouseCursor('Select')
				end
			elseif sUC['n'] >= 0 and type == 'unit' then
				local attackCode = checktarget(uID,sUC)
				
				if attackCode > 0 then
					if attackCode == 1 then
						SetMouseCursor("Capture")
						return CMD_CAPTURE
					elseif attackCode == 2 then
						SetMouseCursor("Reclaim")
						return CMD_RECLAIM
					elseif attackCode == 3 then
						SetMouseCursor("AttackBad")
						return CMD_ATTACKBAD
					end
				end
			-- let engine handle features
			end
		---------------------------------------------------------
		-- user has chosen a command: check if it can be given --
		---------------------------------------------------------
		elseif activeCmdID >= 0 then
			----------------------------
			-- commands given on self --
			----------------------------
			-- repair: higher commanders for instance can self-repair
			if sUC['n'] == 1 and type == 'unit' and sU[1] == uID then
				if activeCmdID == CMD_REPAIR then
					local thisHP, maxHP = GetUnitHealth(uID)
					local unitDefID = GetUnitDefID(uID)
					
					if thisHP < maxHP then
						if not UnitDefs[unitDefID].canSelfRepair then
							SetMouseCursor('Normal')
						end
					else
						SetMouseCursor('Normal')
					end
				-- attack: spring doesn't permit harakiri this way
					SetMouseCursor('Normal')
				elseif activeCmdID == CMD_MOVE then
					SetMouseCursor('Normal')
				elseif activeCmdID == CMD_GUARD or activeCmdID == CMD_AREA_GUARD then
					SetMouseCursor('Normal')
				elseif activeCmdID == CMD_LOAD then
					SetMouseCursor('Normal')
				end
			--------------------------------
			-- commands not given on self --
			--------------------------------
			elseif activeCmdID == CMD_ATTACK then
				if type == 'unit' then
					local attackCode = checktarget(uID,sUC)
										
					if attackCode > 0 then
						SetMouseCursor("AttackBad")
					end
				end
			elseif activeCmdID == CMD_CAPTURE then
				if type == 'unit' then
					if myTeamID == GetUnitTeam(uID) then
						SetMouseCursor('Normal')
					end
				elseif type == 'feature' then
					SetMouseCursor('Normal')
				end
				
			elseif activeCmdID == CMD_REPAIR then
				if type == 'unit' then				
					local thisHP, maxHP = GetUnitHealth(uID)
					if thisHP >= maxHP then
						SetMouseCursor('Normal')
					end
				elseif type == 'feature' then
					SetMouseCursor('Normal')
				end
			elseif activeCmdID == CMD_DGUN then
				
				local commanderID
				for _, unitID in ipairs(sU) do
					local udef = UnitDefs[GetUnitDefID(unitID) ]
					if udef.canManualFire and not udef.customParams.isdecoycommander then
						commanderID = unitID
						break -- just get the first commander in selection
					end
				end
				
				if commanderID then
					local unitDef = UnitDefs[GetUnitDefID(commanderID) ]
					local weaponDefID = unitDef.weapons[FIRSTWEAPON+2].weaponDef
					local dgunEnergy = WeaponDefs[weaponDefID].energyCost
					local energy = Spring.GetTeamResources(myTeamID,'energy')
					
					if energy < dgunEnergy then
						SetMouseCursor('AttackBad')
					end
				end
			elseif activeCmdID == CMD.RESURRECT then
				if type == 'unit' then
					SetMouseCursor('Normal')
				end
			elseif activeCmdID == CMD_GUARD or activeCmdID == CMD_AREA_GUARD then
				if type == 'feature' then
					SetMouseCursor('Normal')
				end
			-- load command: currently only ground can be transported
			elseif activeCmdID == CMD_LOAD then
				
				if type == 'unit' then
					local unitDef = UnitDefs[GetUnitDefID(uID) ] -- unit pointed at
					
					
					local maxtransportSize = 0
						for _,unitID in pairs(sU) do
							local udef = UnitDefs[GetUnitDefID(unitID) ] -- selected unit unitdef
							maxtransportSize = math.max(udef.transportSize,maxtransportSize)
						end
	
					if unitDef.isBuilding then
						if unitDef.cantBeTransported == true then -- atm no buildings can be transported, but it could be possible in the future
							SetMouseCursor('LoadBad')
						end
					elseif unitDef.xsize > 7 and maxtransportSize < 4 then -- not clue what's the relation between movedef footprintX and lua xsize, this is empirical		
						SetMouseCursor('LoadBad')
					elseif unitDef.cantBeTransported or unitDef.transportCapacity > 0 then -- transporters cant be transported atm
						SetMouseCursor('LoadBad')
					elseif (not IsUnitAllied(uID) ) then
						if not unitDef.transportByEnemy then
							SetMouseCursor('LoadBad')
						end
					elseif (not transportHovers) then
						if unitDef.moveDef.type == "hover" then
							SetMouseCursor('LoadBad')
						end
					end
				elseif type == 'feature' then
					SetMouseCursor('Normal')
				end
			-- unload command: use fail cursor in those cases where engine will return fail sound, and otherwise just use normal cursor
			elseif activeCmdID == CMD_UNLOAD or activeCmdID == CMD_UNLOAD_ALL then
				if type == 'unit' then
					SetMouseCursor('UnloadBad')
				elseif type == 'feature' then
					SetMouseCursor('UnloadBad')
				else
					local canUnload = false
					for i, unitID in ipairs (sU) do
						local cargo = GetUnitIsTransporting(unitID)
						
						if cargo then 
							if #cargo > 0 then
								canUnload = true
								break
							else
								local orders = Spring.GetUnitCommands(unitID)
								if #orders > 0 then									
									for u, cmd in pairs (orders) do
										if cmd.id == CMD_LOAD then
											canUnload = true
											break
										end
									end
									if canUnload then break end
								end
							end
						end
					end
				
					if not canUnload then
						SetMouseCursor('Normal')
					end
				end
			end		
		---------------------------------------------------------
		-- build command from menu --
		---------------------------------------------------------
		elseif activeCmdID < 0 then
			local unitDefID = activeCmdID * -1
			
			local radius = unitDefRadius[unitDefID]
			if not radius then
				unitDefRadius[unitDefID] = math.floor(Spring.GetUnitDefDimensions(unitDefID)["radius"])
			end
			local midy = unitDefMidY[unitDefID]
			
			if not midy then
				unitDefMidY[unitDefID] = math.floor(Spring.GetUnitDefDimensions(unitDefID)["midy"])
			end
						
			local waterline = unitDefWaterLine[unitDefID]
			if not waterline then
				unitDefWaterLine[unitDefID] = UnitDefs[unitDefID].waterline
			end
				
			if radius and midy then
				local floater = UnitDefs[unitDefID].floatOnWater
				local mx, my = Spring.GetMouseState()
				local type, data = Spring.TraceScreenRay(mx,my)
					
				if type == 'ground' then
					local x,y0,z = math.floor(data[1]),math.floor(data[2]),math.floor(data[3])
					local y = math.floor(Spring.GetGroundHeight(x,z))

					local mcentre = y + midy - 5 -- put safety margin because of build position from world position
			
					if mcentre and mcentre < 0 then
					
						if mcentre + radius < 0 and (not floater or floater and radius < waterline) then
							SetMouseCursor('BuildSubmerged')
						else
							SetMouseCursor('BuildSurfaced')						
						end						
					end
				end
			end
		end
	end
end
