
function gadget:GetInfo()
  return {
    name = "unit water sounds",
    desc = "sounds from unit in the water",
    author = "res (tx to picasso)",
    date = "23,Jul,2017",
    license = "GNU GPL, v3 or later",
    layer = 0,
    enabled = true
  }
end

-- TODO
-- Add a bubbles animation when going submerge (with sound)
-- Add the option to have only in LOS sounds (maybe)?

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
	for _, unitID in ipairs(GetAllUnits()) do
		local unitDefID = GetUnitDefID(unitID)
		local x,y,z = GetUnitPosition(unitID)
		local unitTeam = GetUnitTeam(unitID)
		if y < 0 and unitTeam ~= GaiaTeamID then 
			if IsWaterDragUnit[tostring(UnitDefs[unitDefID].moveDef.name)] ~= nil then
				waterUnits[unitID] = true
			end
		end
	end
	Spring.Log("gadget",LOG.INFO,"Unit water sounds (XTA) loaded.")
end


function dragSound(unitID)
	local x,y,z = GetUnitPosition(unitID)
	local unitDefID = GetUnitDefID(unitID)
	if unitDefID ~= nil and x ~= nil and (notMovingWaterUnits[unitID] ~= nil or waterUnits[unitID] ~= nil) then
		local height = GetUnitDefDimensions(unitDefID)["height"]
		local level = GetUnitDefDimensions(unitDefID)["height"] + y
		local velocity = GetUnitVelocity(unitID)
		
		if y < 0 then
			if abs(velocity) > 0.0001 then 
				if  (level > 0) then				
					PlaySoundFile(WATER_MOVEMENT,volume * 4 * (level/height),x,y,x,0,0,0,'battle')
				else
					PlaySoundFile(UNDERWATER_MOVING, volume + 4 / (1-level),x,y,x,0,0,0,'battle')
				end
			else
				notMovingWaterUnits[unitID] = nil
				waterUnits[unitID] = true
			end
		else
			notMovingWaterUnits[unitID] = nil
			waterUnits[unitID] = nil
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
			
			-- checking if moving units are still moving
			for unitID,v in pairs(notMovingWaterUnits) do
				local velocity = GetUnitVelocity(unitID)
				if abs(velocity) > 0.0001 then
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


function gadget:UnitEnteredWater(unitID, unitDefID, unitTeam)
	local x,y,z = GetUnitPosition(unitID)
	local unitTeam = GetUnitTeam(unitID)
	local velocity = GetUnitVelocity(unitID)
	if unitTeam ~= GaiaTeamID then
		if abs(velocity) > 0.001 then
			local radius = GetUnitDefDimensions(unitDefID)["radius"]
			if IsHover[tostring(UnitDefs[unitDefID].moveDef.name)] then
				PlaySoundFile(HOVER_PLASH, volume * math.abs((radius-10))/60 ,x,y,z,0,0,0,'battle')
			else
				PlaySoundFile(NONHOVER_SPLASH, volume * math.abs((radius-10))/60,x,y,z,0,0,0,'battle')
			end
		end
		if IsWaterDragUnit[tostring(UnitDefs[unitDefID].moveDef.name)] ~= nil then
			waterUnits[unitID] = true
		end
	end
end


function gadget:UnitLeftWater(unitID, unitDefID, unitTeam)
	notMovingWaterUnits[unitID] = nil
	waterUnits[unitID] = nil
end