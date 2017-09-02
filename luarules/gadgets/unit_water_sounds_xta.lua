function gadget:GetInfo()
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
local abs						= math.abs
local random 					= math.random           
--local GetLocalTeamID			= Spring.MY_UNITS
local PlaySoundFile				= Spring.PlaySoundFile
local GetUnitPosition			= Spring.GetUnitPosition
local GetGameFrame				= Spring.GetGameFrame
local GetUnitTeam				= Spring.GetUnitTeam
local GetUnitDefID				= Spring.GetUnitDefID
local Echo						= Spring.Echo
local GetAllUnits				= Spring.GetAllUnits
local GetUnitDefDimensions		= Spring.GetUnitDefDimensions
local GaiaTeamID  				= Spring.GetGaiaTeamID()
local GetUnitVelocity			= Spring.GetUnitVelocity

-- locals
local WATER_MOVEMENT			= "sounds/unit/watfusn1.wav"
local NONHOVER_SPLASH			= "sounds/battle/splslrg.wav"
local DESTROYED_SPLASH 			= "sounds/battle/splsmed.wav"
local HOVER_PLASH				= "sounds/unit/hovmdof1.wav"
local UNDERWATER_MOVING			= "sounds/unit/suarmmov.wav"
local waterUnits 				= {}
local notMovingWaterUnits		= {}
local CMD_MOVE 					= CMD.MOVE
local volume 					= 1.0
local unitDefRadius				= {}
local SECOND					= 31
local delaySounds				= {}
local pairs						= pairs


function gadget:Initialize()
	
	-- after reloading and startup add units in water back to the table
	for _, unitID in ipairs(GetAllUnits()) do
		local unitDefID = GetUnitDefID(unitID)
		local unitTeam = GetUnitTeam(unitID)
		local x,y,z = GetUnitPosition(unitID)
		
		if y < 0 then --and (localTeamID == unitTeam) then
			if IsWaterDragUnit[tostring(UnitDefs[unitDefID].moveDef.name)] ~= nil then
				waterUnits[unitID] = true
			end
		end
	end
	Spring.Log("gadget",LOG.INFO,"Unit water sounds (XTA) loaded.")
	
end


function delay(unitID, submerge)
	
end


function dragSound(unitID)
	local x,y,z = GetUnitPosition(unitID)
	local unitDefID = GetUnitDefID(unitID)
	if unitDefID ~= nil and x ~= nil and (notMovingWaterUnits[unitID] ~= nil or waterUnits[unitID] ~= nil) then
		local height = GetUnitDefDimensions(unitDefID)["height"]
		local level = GetUnitDefDimensions(unitDefID)["height"] + y
		local velocity = GetUnitVelocity(unitID)
		
		if velocity > 0.0001 then 
			--not submersive
			if  (level > 0) then
				
				PlaySoundFile(WATER_MOVEMENT,volume * 4 * (level/height),x,y,x,0,0,0,'battle')
				
			--submersive
			else
				PlaySoundFile(UNDERWATER_MOVING, volume + 4 / (1-level),x,y,x,0,0,0,'battle')
			end
		else
			notMovingWaterUnits[unitID] = nil
			waterUnits[unitID] = true
		end
	end
end


function updateDelaySounds(delaySounds)
	for unitID, delay in pairs(delaySounds) do
		if (notMovingWaterUnits[unitID] ~= nil or waterUnits[unitID] ~= nil) then
			if delaySounds[unitID] < 0 then
				dragSound(unitID)
			else
				delaySounds[unitID] = delaySounds[unitID] - 1
			end
		end
	end
end 


function gadget:GameFrame(f)
	
	updateDelaySounds(delaySounds) 
	
	if f%SECOND == 0 then
	
		if f%2 == 0 then
			
			-- updating 
			
			-- checking if moving units are still moving
			for unitID,v in pairs(notMovingWaterUnits) do
				local velocity = GetUnitVelocity(unitID)
				if velocity > 0.0001 then
					notMovingWaterUnits[unitID] = nil
					waterUnits[unitID] = true
				end
			end
		else
			
			-- making watery sounds
			for unitID,v in pairs(waterUnits) do
				delaySounds[unitID] = random(1,SECOND)				
			end
		end
	end
end


function gadget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)  
	if notMovingWaterUnits[unitID] then
		if cmdID == CMD_MOVE then
			local x,y,z = GetUnitPosition(unitID)			
			waterUnits[unitID] = true
			notMovingWaterUnits[unitID] = nil
		end
	end
end

function gadget:UnitIdle(unitID, unitDefID, unitTeam)
	if waterUnits[unitID] then
		notMovingWaterUnits[unitID] = true
		waterUnits[unitID] = nil
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)	
	if waterUnits[unitID] or notMovingWaterUnits[unitID] then
		local x,y,z = GetUnitPosition(unitID)
		local radius = GetUnitDefDimensions(unitDefID)["radius"]
		PlaySoundFile(DESTROYED_SPLASH, volume * abs((radius-10))/60, x,y,z,0,0,0,'battle')
		waterUnits[unitID] = nil
		notMovingWaterUnits[unitID] = nil
	end	
end


function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	if waterUnits[unitID] or notMovingWaterUnits[unitID] then
		waterUnits[unitID] = nil
		notMovingWaterUnits[unitID] = nil
	end
end


function gadget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	if (waterUnits[unitID] or notMovingWaterUnits[unitID])and (not AreTeamsAllied(unitTeam, newTeam)) then
		waterUnits[unitID] = nil
		notMovingWaterUnits[unitID] = nil
	end
end


function gadget:UnitEnteredWater(unitID, unitDefID, unitTeam)

	--all units splash comming in to the water
	local x,y,z = GetUnitPosition(unitID)
	local unitTeam = GetUnitTeam(unitID)
	local velocity = GetUnitVelocity(unitID)
	if unitTeam ~= GaiaTeamID then
	--make sure units created in water dont splash (Still they do)
		if y > -10 and velocity > 0.001 then
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
			waterUnits[unitID] = true
		end
	end
end


function gadget:UnitLeftWater(unitID, unitDefID, unitTeam)
	
	notMovingWaterUnits[unitID] = nil
	waterUnits[unitID] = nil
	
end