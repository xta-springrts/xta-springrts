function gadget:GetInfo()
	return {
		name      	= "comets",
		desc      	= "Comets from the sky",
		author    	= "res (inspired by Jools asteroids map gadget",
		date      	= "24-11-2018",
		license 	= "GNU GPL, v3 or later",
		layer     	= -99,
		enabled   	= true,
	}
end


	--[[

	Incoming comets that do damage
		-specifies comet units (fall from the sky)
		-comet units optional do damage (by radiation)

	-parameters options:
		- time_delay_comet
		- max_comets
		- max_radius_damage_comets
		- max_damage_comets
		- comet_rain_radius

	# TODO
	1. Draw texture on the ground for comets (or some fx, by spawning an explosion)
	2. Add a heatmap for commit hits
	3. Add model of a comet
	4. remove a lot of bad global decelerations

	--]]	


-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end


-- LOCALS --


local floor 				= math.floor
local random				= math.random
local sqrt					= math.sqrt
local max					= math.max
local abs					= math.abs

local gmatch				= string.gmatch
local remove				= table.remove
local insert				= table.insert

local modOptions 			= Spring.GetModOptions()
local SetFeatureHealth		= Spring.SetFeatureHealth
local DestroyFeature		= Spring.DestroyFeature
local GetFeatureHealth		= Spring.GetFeatureHealth
local GetFeaturePosition	= Spring.GetFeaturePosition
local AddUnitDamage 		= Spring.AddUnitDamage
local GetFeaturesInSphere	= Spring.GetFeaturesInSphere
local GetUnitPosition		= Spring.GetUnitPosition
local GetUnitDefID			= Spring.GetUnitDefID
local GetFeatureDefID		= Spring.GetFeatureDefID
local Echo					= Spring.Echo
local GetUnitsInCylinder	= Spring.GetUnitsInCylinder
local GetGroundHeight		= Spring.GetGroundHeight
local GetGroundOrigHeight	= Spring.GetGroundOrigHeight
local SetHeightMapFunc		= Spring.SetHeightMapFunc
local SetHeightMap 			= Spring.SetHeightMap
local SpawnCEG				= Spring.SpawnCEG
local GaiaTeamID  			= Spring.GetGaiaTeamID()
local CreateUnit			= Spring.CreateUnit
local DestroyUnit			= Spring.DestroyUnit
local GetTeamList 			= Spring.GetTeamList()
local GetTeamUnits 			= Spring.GetTeamUnits
local SetUnitNeutral		= Spring.SetUnitNeutral
local SetUnitAlwaysVisible	= Spring.SetUnitAlwaysVisible
local SetUnitStealth		= Spring.SetUnitStealth
local SetUnitSonarStealth	= Spring.SetUnitSonarStealth


-- GLOBALS


if not GG.radiation then
	GG['radiation'] = {}
end


-- SETTINGS

--TODO: fix these 3 (add)
local comet_metal			= tonumber(modOptions.comet_metal) or 30
local comet_energy			= tonumber(modOptions.comet_energy) or 30
local comet_mode			= modOptions.comet_mode or "rock"
local unitNameComet 		= comet_mode == "unit" and "arm_peewee" or "meteor"

local number_of_comets		= 1
local images3 				= include("LuaRules/gadgets/img3.lua")
local COMET_FIRE			= "RedPlasmaComet"
local COMET_HIT_GROUND		= "SMALL_NUKE_EXPLOSION_INIATE_COMET"
local PUFFY					= "PUFFY_COMET"
local mapX 					= Game.mapX
local mapZ 					= Game.mapY
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
	["spid3"] 		= true,
	["krogoth"] 	= true,						
	["crawlbomb"] 	= true,	-- crawling bombs
	["tankdh4"] 	= true,	-- beaver, crab, triton, crock, garpike, muskrat, zulu -- land
	["hover1"] 		= true,
	["hover2"]		= true,
	["hover3"]		= true,
	["hover4"]		= true,
	["hover9"]		= true,
	["hover10"]		= true,
}
local TeamIDsComets 		= {}
for _,teamID in pairs(GetTeamList) do
	if GaiaTeamID ~= teamID then
		table.insert(TeamIDsComets, teamID) 
	end
end
local randomUnits 				= true
local FALLSPEED					= 60  -- 60 every 5th timeframe
local timeDelayComet 			= tonumber(modOptions.time_delay_comet) * 30 * 60 or 30 * 60 + 1 -- 2.5 min
local damage_radius				= tonumber(modOptions.max_radius_damage_comets) or 500
local damage_value            	= tonumber(modOptions.max_damage_comets) or 500
local randomize_number_of_comets= 100 -- how often number of comets in rain are randomized (higher is less ofthen)
local cometRainRadius 			= tonumber(modOptions.comet_rain_radius) or 500 -- comet spreading
local max_comets				= tonumber(modOptions.max_comets) or 10
local comets					= {}
local ast_size 					= images3[1]
local ast_image					= images3[2]

--local random_map				= {}
--local evenx 					= mapX%2==0 and 2 or 1 -- only make 1024x1024 sectors if possible
--local evenz 					= mapZ%2==0 and 2 or 1
--for i=0,mapX*512, evenx*512 do
--	for j=0,mapZ*512, evenz*512 do
--		random_map[#random_map+1] = {random(i, i+512*evenx),random(j, j+512*evenz)}
--	end
--end
--for i=0,mapX*512, evenx*512 do
--	for j=0,mapZ*512, evenz*512 do
--		random_map[#random_map+1] = {random(i, i+512*evenx),random(j, j+512*evenz)}
--	end
--end
--local nheatmap = #random_map
--local counter = 0
--
--local function remake_heatmap()
--	local temp = {}
--	Echo("updatemap")
--	for i=0,mapX*512, evenx*512 do
--		for j=0,mapZ*512, evenz*512 do
--			random_map[#random_map+1] = {random(i, i+512*evenx),random(j, j+512*evenz)}
--		end
--	end
--	for i=0,mapX*512, evenx*512 do
--		for j=0,mapZ*512, evenz*512 do
--			random_map[#random_map+1] = {random(i, i+512*evenx),random(j, j+512*evenz)}
--		end
--	end
--	random_map = temp
--	Echo("updatemap")
--end
--
--
--local function random_coordinate()
--
--	counter = counter == 0 and nheatmap or counter -1
--	return random_map[counter][1], random_map[counter][2]
--
--end


-- INITIALISE --


function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.comets)== 0 then
		Echo("comets.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	else
		Echo("comets.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
		DisableMapDamage=0
		Echo("Good afternoon the weather predicts meteor showers, have a nice day!")
	end
end


-- HELP FUCNTION --


local function damage_near_units(x,z, radius)

	local near_units = GetUnitsInCylinder(x,z, radius)
	local y = GetGroundHeight(x,z)
	local near_features = GetFeaturesInSphere(x,y,z, radius)

	if (near_units == nil) and (near== nil) then return nil end

	if not (near_units == nil) then
		for i in pairs(near_units) do
			local unitID = near_units[i]
			local xu,yu,zu = GetUnitPosition(unitID)
			local multiplier = 1-sqrt( (x-xu)*(x-xu) + (z-zu)*(z-zu) )/radius
			local damage = damage_value *multiplier

			if (abs(yu - y) < radius) then
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
				if (abs(yf - y) < radius) then
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


local function add_comet(x,y)
	local X = random(x-cometRainRadius, x+cometRainRadius)
	local Z = random(y-cometRainRadius, y+cometRainRadius)
	
	local map_x_out = X > mapX*512 or X < 0
	local map_y_out = Z > mapZ*512 or Z < 0

	if map_x_out or map_y_out then return nil end

	local Y = random(3000, 6000)
	local impact = random(0,20)
	local height = GetGroundOrigHeight(X,Z)
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


local function deform_ground(comet)
	local x = floor(ast_size["x"]/2)
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


local function update_comet()

	for i=#comets,1,-1 do

		local v = comets[i]

		if v.hit == true then

			local height = GetGroundOrigHeight(v.X,v.Z)
			local team
			if comet_mode == "rock" then
				team = GaiaTeamID
			else
				team = random(0,#TeamIDsComets-1)
			end

			local y = GetGroundHeight(v.X,v.Z)
			SpawnCEG(COMET_HIT_GROUND,v.X, y, v.Z)


			local unitID = CreateUnit(v.unitName, v.X, height, v.Z, 0, team)
			if comet_mode == "rock" then
				SetUnitNeutral(unitID, true)
				SetUnitAlwaysVisible(unitID, true)
				SetUnitStealth(unitID, true)
				SetUnitSonarStealth(unitID,true)
			end
			local damage = 0.1 --random()
			if comet_mode == "rock" then
				GG.radiation[unitID] = {
				['radius'] = 500,		-- number
				['damage'] = 0.2,		-- number between 0,1
				['dRadius'] = -10,		-- number
				['dDamage'] = -0.001,	-- number between 0,1
				['duration'] = 50,		-- number
				['protection'] = 0.0,   -- maybe rename to somthing?
				['maxradius'] = 500
				}
			else
				GG.radiation[unitID] = {
				['radius'] = 100,		-- number
				['damage'] = damage,		-- number between 0,1
				['dRadius'] = 2,		-- number
				['dDamage'] = 0.01,	-- number between 0,1
				['duration'] = 50,		-- number
				['protection'] = 0.5,   -- maybe rename to somthing?
				['maxradius'] = 500
				}
			end
			remove(comets, i)

		elseif v.groundHeight-v.Y < 0 then
			SpawnCEG(COMET_FIRE, v.X, v.Y, v.Z)
			comets[i].Y = v.Y - FALLSPEED

			if comets[i].Y - comets[i].explode < 0 then
				SpawnCEG(PUFFY,v.X, v.Y, v.Z)
				local team
				if comet_mode == "rock" then
					team = GaiaTeamID
				else
					team = random(0,#TeamIDsComets-1)
				end
				local unitID = CreateUnit(v.unitName, v.X, v.Y, v.Z, 0, team)
				if comet_mode == "rock" then
					SetUnitNeutral(unitID, true)
					SetUnitAlwaysVisible(unitID, true)
					SetUnitStealth(unitID, true)
					SetUnitSonarStealth(unitID,true)
				end
				remove(comets, i)
				DestroyUnit(unitID)
			end
		else
			SpawnCEG(PUFFY,v.X, v.groundHeight, v.Z)
			deform_ground(v)
			damage_near_units(v.X,v.Z, damage_radius*1)
			comets[i].hit = true
		end
	end

end


local function getUnitName()
	if randomUnits == true then
		local can_move = {}
		for teamCount = 1, #TeamIDsComets do
			local teamID = TeamIDsComets[teamCount]
			local units = GetTeamUnits(teamID)
			for index, unitID in pairs(units) do
				local UDID = GetUnitDefID(unitID)
				if UnitDefs[UDID].isBuilder ~= true then
					if moving[tostring(UnitDefs[UDID].moveDef.name)] ~= nil then
						insert(can_move, GetUnitDefID(unitID))
					end
				end
			end
		end
		if #can_move > 0 then
			unitNameComet = UnitDefs[can_move[random(1,#can_move)]].name
		end
	end	
end





-- LOOP --


function gadget:GameFrame(f)

	if f<100 then return nil end

	if (f%randomize_number_of_comets*timeDelayComet ==0) then
		number_of_comets = random(0, max_comets)
	end
	if (f%5 == 0) then
		if not (#comets == 0) then
			update_comet()

			--if (f%1000==0) then
			--	remake_heatmap()
			--end


		else
			if f%timeDelayComet == 0 then
				if not (number_of_comets==0) then

					Echo("WARNING observatory station detects ".. tostring(number_of_comets) .. " incoming meteorites!")

					if comet_mode == "unit" then
						getUnitName()
					end
					local x = random(0,mapX*512)
					local z = random(0,mapZ*512)
					--local x, z = random_coordinate()

					for i=1,number_of_comets do
						comets[#comets+1] = add_comet(x,z)
					end
				end
			end
		end
	end
end
