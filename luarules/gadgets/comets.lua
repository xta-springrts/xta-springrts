function gadget:GetInfo()
	return {
		name      	= "comets",
		desc      	= "Comets from the sky",
		author    	= "res (inspired by Jools astroids map gadget",
		date      	= "24-11-2018",
		license 	= "GNU GPL, v3 or later",
		layer     	= -99,
		enabled   	= true,
	}
end


	--[[

	Incomming comets that do damage 
		-specifies comet units (fall from the sky)
		-comet units optinal do damage (by radiation)

	-parameters options:
		- time_delay_comet
		- max_comets
		- max_radius_damage_comets
		- max_damage_comets
		- comet_rain_radius

	# TODO
	
 
	1. Implement mod options:
		- teamID of comets (only gaia, random, only players)
	2. Make comets terra forming optional
	3. Draw texture on the ground for comets

	--]]	


-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end


-- LOCALS --


local floor 			= math.floor
local random			= math.random
local sqrt			= math.sqrt
local max			= math.max

local gmatch			= string.gmatch
local remove			= table.remove

local modOptions 		= Spring.GetModOptions()
local SetFeatureHealth		= Spring.SetFeatureHealth
local DestroyFeature		= Spring.DestroyFeature
local GetFeatureHealth		= Spring.GetFeatureHealth
local GetFeaturePosition	= Spring.GetFeaturePosition
local AddUnitDamage 		= Spring.AddUnitDamage
local GetFeaturesInSphere	= Spring.GetFeaturesInSphere
local GetUnitsInSphere		= Spring.GetUnitsInSphere
local GetUnitPosition		= Spring.GetUnitPosition
local GetUnitDefID		= Spring.GetUnitDefID
local GetFeatureDefID		= Spring.GetFeatureDefID
local Echo			= Spring.Echo
local GetUnitsInCylinder	= Spring.GetUnitsInCylinder
local GetGroundHeight		= Spring.GetGroundHeight
local GetGroundOrigHeight	= Spring.GetGroundOrigHeight
local SetHeightMapFunc		= Spring.SetHeightMapFunc
local PlaySoundFile		= Spring.PlaySoundFile
local SetHeightMap 		= Spring.SetHeightMap
local SpawnCEG			= Spring.SpawnCEG
local GaiaTeamID  		= Spring.GetGaiaTeamID()
local SetUnitNeutral		= Spring.SetUnitNeutral
local SetUnitNoSelect		= Spring.SetUnitNoSelect
local CreateUnit		= Spring.CreateUnit
local DestroyUnit		= Spring.DestroyUnit
local SetUnitAlwaysVisible	= Spring.SetUnitAlwaysVisible
local SetUnitPosition 		= Spring.SetUnitPosition
local SetUnitStealth		= Spring.SetUnitStealth
local TransferUnit		= Spring.TransferUnit
local GetTeamList 		= Spring.GetTeamList()
local GetAllUnits 		= Spring.GetAllUnits
local ValidFeatureID 		= Spring.ValidFeatureID
local ValidUnitID 		= Spring.ValidUnitID
local GetTeamUnits 		= Spring.GetTeamUnits

local images 			= include("LuaRules/gadgets/img.lua")
local images2 			= include("LuaRules/gadgets/img2.lua")
local images3 			= include("LuaRules/gadgets/img3.lua")
local COMET_FIRE		= "RedPlasmaComet"
local COMET_HIT_GROUND		= "SMALL_NUKE_EXPLOSION_INIATE_COMET"
local PUFFY			= "PUFFY_COMET"
local crushsnd			= "sounds/battle/crush3.wav"

local mapX 			= Game.mapX
local mapZ 			= Game.mapY


-- SETTINGS --

local moving = {
	["kbotsf2"] 	= true, 
	["kbotsf3"] 	= true,					
	["kbotss2"] 	= true,						
	["kbotuw3"] 	= true,	-- gimp, spiders, moved land pelican to this
	--["kbotds2"] 	= true,	 		-- commanders
	["tankbh3"] 	= true,	 					
	["tankdh3"] 	= true,	-- beaver, crab, triton, crock, garpike, muskrat, zulu
	["tanksh2"] 	= true,	 					
	["tanksh2"] 	= true,	 					
	["tanksh4"] 	= true,	 					
	["tankdtcrush"] = true,	-- Bulldog/Reaper/Goliath can crush DT's
	["spid3"] 	= true,						
	["krogoth"] 	= true,						
	["crawlbomb"] 	= true,	-- crawling bombs
	["tankdh4"] 	= true,	-- beaver, crab, triton, crock, garpike, muskrat, zulu -- land
	["hover1"] 	= true,
	["hover2"]	= true,
	["hover3"]	= true,
	["hover4"]	= true,
	["hover9"]	= true,
	["hover10"]	= true,	
}

local TeamIDsComets 		= {} 
for _,teamID in pairs(GetTeamList) do
	if GaiaTeamID ~= teamID then
		table.insert(TeamIDsComets, teamID) 
	end
end
local damageToUnits 		= {}
local damageToFeatures 		= {}
local randomUnits 		= true
local unitNameComet 		= "arm_peewee"
local FALL_SPEED		= 60  -- 60 every 5th timeframe
local transfer	 		= true

local timeDelayComet 		= tonumber(modOptions.time_delay_comet) * 30 * 60 or 30 * 60 + 1 -- 2.5 min
local damage_radius		= tonumber(modOptions.max_radius_damage_comets) or 500
local damage_value            	= tonumber(modOptions.max_damage_comets) or 500
local randomize_number_of_comets= 100 -- how often number of comets in rain are randomized (higher is less ofthen)
local cometRainRadius 		= tonumber(modOptions.comet_rain_radius) or 500 -- comet spreading
local max_comets					= tonumber(modOptions.max_comets) or 10

-- READ IN IMAGES AN AUDIO


local comets			= {}
local cometUnits 		= {}
local ast_size 			= images3[1]
local ast_image			= images3[2]
local cometold          	= false
local fx_comit 			= {}
for k,v in pairs(ast_image) do
	if v ~= 0 and random() < 0.02 then
		fx_comit[k] = v
	end
end


-- INITIALISE --


function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.comets)== 0 then
		Echo("comets.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	end
	Echo("comets.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
	DisableMapDamage=0
	Echo("Good afternoon the weather predicts meteor showers, have a nice day!")
end


-- HELP FUCNTION --


function damage_near_units(x,z, radius)

	local near_units = GetUnitsInCylinder(x,z, radius)
	local y = GetGroundHeight(x,z)
	local near_features = GetFeaturesInSphere(x,y,z, radius)

	if (near_units == nil) and (near== nil) then return nil end

	if not (near_units == nil) then
		for i in pairs(near_units) do
			local unitID = near_units[i]
			local unitDefID = GetUnitDefID(unitID)
			local xu,yu,zu = GetUnitPosition(unitID)
			local multiplier = 1-sqrt( (x-xu)*(x-xu) + (z-zu)*(z-zu) )/radius
			local damage = damage_value *multiplier

			if (math.abs(yu - y) < radius) then
				AddUnitDamage(unitID, damage)
			end
		end
	end

	if not (near_features == nil) then
		for i in pairs(near_features) do
			if not FeatureDefs[GetFeatureDefID(near_features[i])].geoThermal then  
				local xf, yf, zf = GetFeaturePosition(near_features[i])
				local multiplier = 1-sqrt( (x-xf)*(x-xf) + (z-zf)*(z-zf) )/radius
				local damage = damage_value*multiplier
				local feature_health = GetFeatureHealth(near_features[i])
				if (math.abs(yf - y) < radius) then
					if feature_health - damage < 0 then
						DestroyFeature(near_features[i])
					else
						SetFeatureHealth(near_features[i],feature_health-damage)
					end
				end
			end
		end
	end
end


-- COMET FUNCTIONS


function add_comet(x,y)
	local X = random(x-cometRainRadius, x+cometRainRadius)
	local Z = random(y-cometRainRadius, y+cometRainRadius)
	
	local map_x_out = X > mapX*512 or X < 0
	local map_y_out = Z > mapZ*512 or Z < 0

	if map_x_out or map_y_out then return nil end

	local Y = random(3000, 6000)
	local impact = random(0,20)
	local height = GetGroundOrigHeight(X,Z)
	local originalHeight = GetGroundOrigHeight(X,Z)
	local explode = random(500, 2000)
	local unitName = unitNameComet

	if random() < 0.5 then
		explode = -explode
	end
	local comet = {explode = explode,
		hit = false,
		groundHeight = height,
		impact = impact,
		X = X,
		Y = Y,
		Z = Z,
		unitName = unitName}
	return comet
end


function update_comet()

	for i=#comets,1,-1 do

		local v = comets[i]
		
		if v.hit == true then
			
			local height = GetGroundOrigHeight(v.X,v.Z)
			local team = random(0,#TeamIDsComets-1)
			local unitID = CreateUnit(v.unitName, v.X, height, v.Z, 0, team)
			if transfer ~= true then
				DestroyUnit(unitID)
			end
			table.remove(comets, i)

		elseif v.groundHeight-v.Y < 0 then
			SpawnCEG(COMET_FIRE, v.X, v.Y, v.Z)
			comets[i].Y = v.Y - FALL_SPEED

			if comets[i].Y - comets[i].explode < 0 then
				SpawnCEG(PUFFY,v.X, v.Y, v.Z)
				local team = random(0,#TeamIDsComets-1)
				local unitID = CreateUnit(v.unitName, v.X, v.Y, v.Z, 0, team)
				table.remove(comets, i)
				DestroyUnit(unitID)
			end
		else
			SpawnCEG(COMET_HIT_GROUND,v.X, v.groundHeight, v.Z)  
			SpawnCEG(PUFFY,v.X, v.groundHeight, v.Z)			
			deform_ground(v)
			damage_near_units(v.X,v.Z, damage_radius*1)
			comets[i].hit = true
		end
	end

end


function getUnitName()
	if randomUnits == true then
		local can_move = {}
		for teamCount = 1, #TeamIDsComets do
			Echo(TeamIDsComets[teamCount])
			local teamID = TeamIDsComets[teamCount]
			local units = GetTeamUnits(teamID)
			for index, unitID in pairs(units) do
				does_move = moving[tostring(UnitDefs[GetUnitDefID(unitID)].moveDef.name)] ~= nil
				if does_move == true then 
					table.insert(can_move, GetUnitDefID(unitID))
				end
			end
		end
		if #can_move > 0 then
			unitNameComet = UnitDefs[can_move[random(1,#can_move)]].name
		end
	end	
end


function deform_ground(comet)
	local x =floor(ast_size["x"]/2)
	local z = floor(ast_size["z"]/2)
	local xc = comet.X - x
	local zc = comet.Z - z
	local func = function()
		for key, value in pairs(ast_image) do
			for k, v in gmatch(key,"(%w+),(%w+)") do
				local height = GetGroundOrigHeight(v+xc,k+zc) 
				if value ~= 0 then
					SetHeightMap(tonumber(v)+xc,tonumber(k)+zc, height + value -21)
				end
			end
		end
	end
	SetHeightMapFunc(func)
end


-- LOOP --


function gadget:GameFrame(f)
	if (f%randomize_number_of_comets*timeDelayComet ==0) then
		number_of_comets = random(0, max_comets)
	end
	if (f%5 == 0) then
		if not (#comets == 0) then
			update_comet()
		else
			if f%timeDelayComet == 0 then
				if not (number_of_comets==0) then
					Echo("WARNING observatory station detects ".. tostring(number_of_comets) .. " incoming meteorites!")
					getUnitName()
					local x = floor(random(0,  mapX*512))
					local z = floor(random(0,  mapZ*512))
					for i=1,number_of_comets do
						comets[#comets+1] = add_comet(x,z)
					end
				end
			end
		end
	end
end
