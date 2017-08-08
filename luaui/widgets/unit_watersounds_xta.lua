function widget:GetInfo()
  return {
    name = "soundy units in water",
    desc = "in tha water",
    author = "res (tx to pic)",
    date = "23,Jul,2017",
    license = "GNU GPL, v3 or later",
    layer = 0,
    enabled = true
  }
end

-- TODO
-- How it works with enemy units?? (fix: make a gadget)
-- Unit should not make noice when they are building, gaurding, ... etc (fix: commander)
-- Add a bubbles animation when going submerge (with sound)
-- Building hover platforms, tidels, metal makers, radar and ... splashes (these should be removed from soundfx)
-- Add the option to make crittes in water LOS only visible

local IsWaterDragUnit = {
	["kbotsf2"] 	= true, 
	["kbotsf3"] 	= true,					
	["kbotss2"] 	= true,						
	["kbotuw3"] 	= true,						-- gimp, spiders, moved land pelican to this
	["kbotds2"] 	= true,	 					-- commanders
	["tankbh3"] 	= true,	 					
	["tankdh3"] 	= true,	 					-- beaver, crab, triton, crock, garpike, muskrat, zulu
	["tanksh2"] 	= true,	 					
	["tanksh2"] 	= true,	 					
	["tanksh4"] 	= true,	 					
	["tankdtcrush"] = true,	 					-- Bulldog/Reaper/Goliath can crush DT's
	["spid3"] 		= true,						
	["krogoth"] 	= true,						
	["crawlbomb"] 	= true,						-- crawling bombs
	["tankdh4"] 	= true,						-- beaver, crab, triton, crock, garpike, muskrat, zulu -- land	
}

local IsHover = {
	["hover1"] 		= true,
	["hover2"]		= true,
	["hover3"]		= true,
	["hover4"]		= true,
	["hover9"]		= true,
	["hover10"]		= true,	
}

--Speed-ups           
local GetLocalTeamID			= Spring.GetLocalTeamID
local PlaySoundFile				= Spring.PlaySoundFile
local GetUnitPosition			= Spring.GetUnitPosition
local GetSpectatingState		= Spring.GetSpectatingState
local GetGameFrame				= Spring.GetGameFrame
local GetUnitTeam				= Spring.GetUnitTeam
local GetUnitDefID				= Spring.GetUnitDefID
local Echo						= Spring.Echo
local GetAllUnits				= Spring.GetAllUnits
local GetUnitDefDimensions		= Spring.GetUnitDefDimensions
local GaiaTeamID  				= Spring.GetGaiaTeamID()

-- locals
local WATER_MOVEMENT			= "sounds/unit/watfusn1.wav"
local NONHOVER_SPLASH			= "sounds/battle/splslrg.wav"
local DESTROYED_SPLASH 			= "sounds/battle/splsmed.wav"
local HOVER_PLASH				= "sounds/unit/hovmdof1.wav"
local UNDERWATER_MOVING			= "sounds/unit/suarmmov.wav"
local waterUnits 				= {}
local CMD_MOVE 					= CMD.MOVE
local volume 					= 1.0
local unitDefRadius				= {}
local localTeamID				= nil

function widget:Initialize()
	
	-- removes the specs 
    localTeamID = GetLocalTeamID()   
	if (GetSpectatingState() == true) then
		widgetHandler:RemoveWidget()
		return false
	end
	
	-- reloading add units in water back to the table
	for _, unitID in ipairs(GetAllUnits()) do
		
		local unitDefID = GetUnitDefID(unitID)
		local unitTeam = GetUnitTeam(unitID)
		local x,y,z = GetUnitPosition(unitID)
		
		if y < 0 and (localTeamID == unitTeam) then
				if IsWaterDragUnit[tostring(UnitDefs[unitDefID].moveDef.name)] ~= nil then
					waterUnits[unitID] = 1
				end
		end
	end
	Spring.Log("widget",LOG.INFO,"Unit water sounds (XTA) loaded.")
	
end


function widget:Update(dt)
	
	--repeat after some time sound effect of moving
	for k,v in pairs(waterUnits) do
		if (v < 2 and v > 1) then
			
			local x,y,z = GetUnitPosition(k)
			local unitDefID = GetUnitDefID(k)
			local height = GetUnitDefDimensions(unitDefID)["height"]
			local level = GetUnitDefDimensions(unitDefID)["height"] + y
			
			--not submersive
			if  (level > 0) then
				PlaySoundFile(WATER_MOVEMENT,volume * 4 * (level/height),x,y,x,0,0,0,'battle')
			--submersive
			else
				PlaySoundFile(UNDERWATER_MOVING, volume + 4 / (1-level),x,y,x,0,0,0,'battle')
			end
			waterUnits[k] = 3
		
		else
			waterUnits[k] = v - dt
		end
	end
	
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag) 
   
	if waterUnits[unitID] then
		if cmdID == CMD_MOVE then
			local x,y,z = GetUnitPosition(unitID)			
			waterUnits[unitID] = 3
		end
	end
	
end

function widget:UnitIdle(unitID, unitDefID, unitTeam)
   
	if waterUnits[unitID] then
		local x,y,z = GetUnitPosition(unitID)
		--maybe play blub blub sound?
		--PlaySoundFile(CD1,1.0,x,y,z,0,0,0,'battle')
		waterUnits[unitID] = 1
	end
	
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
		
	if waterUnits[unitID] then
		local x,y,z = GetUnitPosition(unitID)
		local radius = GetUnitDefDimensions(unitDefID)["radius"]
		--make water explode sound
		PlaySoundFile(DESTROYED_SPLASH, volume * abs((radius-10))/60, x,y,z,0,0,0,'battle')
		waterUnits[unitID] = nil
	end
	
end


function widget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	
	if waterUnits[unitID] then
		waterUnits[unitID] = nil
	end
	
end


function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	
	if waterUnits[unitID] and (not AreTeamsAllied(unitTeam, newTeam)) then
		waterUnits[unitID] = nil
	end
	
end


function widget:UnitEnteredWater(unitID, unitDefID, unitTeam)

	--all units splash in water comming in to the water
	local x,y,z = GetUnitPosition(unitID)
	local unitTeam = GetUnitTeam(unitID)
	
	if unitTeam ~= GaiaTeamID then
	--make sure units created in water dont splash
		if y > -10 then
			local radius = GetUnitDefDimensions(unitDefID)["radius"]
			if IsHover[tostring(UnitDefs[unitDefID].moveDef.name)] then
				PlaySoundFile(HOVER_PLASH, volume * math.abs((radius-10))/60 ,x,y,z,0,0,0,'battle')
			else
				PlaySoundFile(NONHOVER_SPLASH, volume * math.abs((radius-10))/60,x,y,z,0,0,0,'battle')
			end
		end
		
		--store soundy units in water
		if IsWaterDragUnit[tostring(UnitDefs[unitDefID].moveDef.name)] ~= nil then
			--Echo(UnitDefs[unitDefID].name)
			waterUnits[unitID] = 2
		end
	end
end


function widget:UnitLeftWater(unitID, unitDefID, unitTeam)

	waterUnits[unitID] = nil
	
end

function widget:Shutdown()

end