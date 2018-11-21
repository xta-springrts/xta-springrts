function gadget:GetInfo()
	return {
		name      	= "earth_crack",
		desc      	= "When the gods get angry",
		author    	= "res",
		date      	= "8-10-2018",
		license 	= "GNU GPL, v3 or later",
		layer     	= -99,
		enabled   	= true,
	}
end


--[[

		After a random period parts of the map will experience crack's in surface.
		Incomming comets might need to beavoided to prevend damage.

		Also the gadget specifies some units that do damage to other units (like radiation of powerp

		-parameters options:
			- time_delay_comet
			- duration_crack
			- max_cracks
			- max_comets
			- max_radius_damage_comets
			- max_damage_comets
			- comet_rain_radius

		# TODO
		
	 
		1. Implement mod options:
			- middleCrack (only add cracks in middle)
			- teamID of comets (only gaia, random, only players)
		2. Add map damage area fx 
		3. Draw texture on the ground for comets and map damage area
		4. Add more units that do damage to neighborhood
		5. Maybe split up map damage gadget to keep stuff clean? 

--]]	


-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end


-- LOCALS --


local floor 						= math.floor
local random					    = math.random
local sqrt							= math.sqrt
local max						= math.max

local gmatch						= string.gmatch
local remove						= table.remove

local modOptions 					= Spring.GetModOptions()
local SetFeatureHealth				= Spring.SetFeatureHealth
local DestroyFeature				= Spring.DestroyFeature
local GetFeatureHealth				= Spring.GetFeatureHealth
local GetFeaturePosition			= Spring.GetFeaturePosition
local AddUnitDamage 				= Spring.AddUnitDamage
local GetFeaturesInSphere			= Spring.GetFeaturesInSphere
local GetUnitsInSphere				= Spring.GetUnitsInSphere
local GetUnitPosition				= Spring.GetUnitPosition
local GetUnitDefID					= Spring.GetUnitDefID
local GetFeatureDefID				= Spring.GetFeatureDefID
local Echo					      	= Spring.Echo
local GetUnitsInCylinder			= Spring.GetUnitsInCylinder
local GetGroundHeight				= Spring.GetGroundHeight
local GetGroundOrigHeight			= Spring.GetGroundOrigHeight
local SetHeightMapFunc				= Spring.SetHeightMapFunc
local PlaySoundFile					= Spring.PlaySoundFile
local SetHeightMap 					= Spring.SetHeightMap
local SpawnCEG					  	= Spring.SpawnCEG
local GaiaTeamID  			= Spring.GetGaiaTeamID()
local SetUnitNeutral		= Spring.SetUnitNeutral
local SetUnitNoSelect		= Spring.SetUnitNoSelect
local CreateUnit			= Spring.CreateUnit
local DestroyUnit			= Spring.DestroyUnit
local SetUnitAlwaysVisible	=Spring.SetUnitAlwaysVisible
local SetUnitPosition 			= Spring.SetUnitPosition
local SetUnitStealth			= Spring.SetUnitStealth
local TransferUnit			= Spring.TransferUnit
local GetTeamList 			= Spring.GetTeamList()
local GetAllUnits 			= Spring.GetAllUnits
local ValidFeatureID 			= Spring.ValidFeatureID
local ValidUnitID 			= Spring.ValidUnitID

local images 					    = include("LuaRules/gadgets/img.lua")
local images2 					  	= include("LuaRules/gadgets/img2.lua")
local images3 					  	= include("LuaRules/gadgets/img3.lua")
local COMET_FIRE				  	= "RedPlasmaComet"
local COMET_HIT_GROUND				  	= "SMALL_NUKE_EXPLOSION_INIATE_COMET"
local PUFFY						= "PUFFY_COMET"
local crushsnd					  	= "sounds/battle/crush3.wav"


local mapX 					      	= Game.mapX
local mapZ 					      	= Game.mapY



-- SETTINGS --

local moving = {
	["kbotsf2"] 	= true, 
	["kbotsf3"] 	= true,					
	["kbotss2"] 	= true,						
	["kbotuw3"] 	= true,						-- gimp, spiders, moved land pelican to this
	--["kbotds2"] 	= true,	 					-- commanders
	["tankbh3"] 	= true,	 					
	["tankdh3"] 	= true,	 					-- beaver, crab, triton, crock, garpike, muskrat, zulu
	["tanksh2"] 	= true,	 					
	["tanksh2"] 	= true,	 					
	["tanksh4"] 	= true,	 					
	["tankdtcrush"] = true,	 					-- Bulldog/Reaper/Goliath can crush DT's
	["spid3"] 	= true,						
	["krogoth"] 	= true,						
	["crawlbomb"] 	= true,						-- crawling bombs
	["tankdh4"] 	= true,						-- beaver, crab, triton, crock, garpike, muskrat, zulu -- land
	["hover1"] 	= true,
	["hover2"]	= true,
	["hover3"]	= true,
	["hover4"]	= true,
	["hover9"]	= true,
	["hover10"]	= true,	
}

local TeamIDsComets 					= {} 
for _,teamID in pairs(GetTeamList) do
	if GaiaTeamID ~= teamID then
		table.insert(TeamIDsComets, teamID) 
	end
end
local damageToUnits 					= {}
local damageToFeatures 					= {}
local unitsDoDamage					= {}
local randomUnits 					= true
local unitNameComet 					= "arm_peewee"
local FALL_SPEED					= 60  -- 60 every 5th timeframe
local transfer	 					= true
local timeDelayCrack					= 30 * 60 + 1 -- 1 min
local timeDelayComet 					= tonumber(modOptions.time_delay_comet) * 30 * 60 or 30 * 60 + 1 -- 2.5 min
local timeDelayDamage					= 61 -- every second (either update or do damage)
local duration						= tonumber(modOptions.duration_crack) *30 *60 + 1 or 9000 +1 		-- 5 min crack duration
local crackAreaX					= floor(mapX*512*1/10)								-- defines middle 
local crackAreaZ					= floor(mapZ*512*1/10)
local middle 					  	= false					-- is middle only cracked?
local cracks						= {}
local remove_cracks					= {}
local add_cracks					= {}
local max_cracks					= tonumber(modOptions.max_cracks) or 10
local max_comets					= tonumber(modOptions.max_comets) or 10
local damage_radius					= tonumber(modOptions.max_radius_damage_comets) or 500
local damage_value            		= tonumber(modOptions.max_damage_comets) or 500
local randomize_number_of_cracks	= 150 -- same as below but for cracks
local randomize_number_of_comets	= 100 -- how often number of comets in rain are randomized (higher is less ofthen)
local cometRainRadius 				= tonumber(modOptions.comet_rain_radius) or 500 -- comet spreading


-- DAMAGE PARAMETERS

local damageValues = {
	["arm_peewee"] 		= {["value"] = 200, ["radius"] = 500, ["dDamage"] = 1, ["dRadius"] = 1, ["duration"] = 300, ["self"] = 20},
  	["some_other_unit"] 	= {["value"] = 20, ["radius"] = 500, ["dDamage"] = 1, ["dRadius"] = 1, ["duration"] = 300, ["self"] = 0.1}
}


-- READ IN IMAGES AN AUDIO


local fx = {
	[1] = {[1]={}, [2]={}, [3]={}, [4]={}, [5]={}},
	[2] = {[1]={}, [2]={}, [3]={}, [4]={}, [5]={}}
}
local audio = {
	[1] = {[1]={}, [2]={}, [3]={}, [4]={}, [5]={}},
	[2] = {[1]={}, [2]={}, [3]={}, [4]={}, [5]={}}
}

for k,v in pairs(images) do
	for key, value in pairs(v[2]) do
		if value ~= 0 and random() < 0.02*0.01 then
			fx[1][k][key] = value
			if random() < 0.01 then
				audio[1][k][key] = true
			else
				audio[1][k][key] = false
			end
		end
	end
end
for k,v in pairs(images2) do
	for key, value in pairs(v[2]) do
		if value ~= 0 and random() < 0.02*0.01 then
			fx[2][k][key] = value
			if random() < 0.01 then
				audio[2][k][key] = true
			else
				audio[2][k][key] = false
			end
		end
	end
end

local comets						= {}
local cometUnits 					= {}
local ast_size 						= images3[1]
local ast_image						= images3[2]
local cometold          				= false
local fx_comit 						= {}
for k,v in pairs(ast_image) do
	if v ~= 0 and random() < 0.02 then
		fx_comit[k] = v
	end
end


-- INITIALISE --


function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.earth_crack)== 0 then
		Echo("earth_crack.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	end
	Echo("earth_crack.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
	DisableMapDamage=0
	Echo("Seismic activity predicted in forecast models, be aware!")
	Echo("Good afternoon the weather predicts meteor showers, have a nice day!")
	--end

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



function emit(data)
	if data ~= nil then
		local file = data.file
		local img = data.image
		local x = data.X
		local z = data.Z

		-- emit fx on points
		for key, value in pairs(fx[file][img]) do
			for k, v in gmatch(key,"(%w+),(%w+)") do
				local y = GetGroundHeight(k,v)
				SpawnCEG(PUFFY,tonumber(v)+x, y+10, tonumber(k)+z) 
				if audio[file][img][key] == true then 
					PlaySoundFile (crushsnd, 2.0, x,y,z, 0,0,0,'battle')
				end
			end
		end
	end
end


-- CRACK FUNCTIONS


function remove_crack(data)
	local image = data.image
	local img
	if data.file == 1 then
		img = images[image]
	else
		img = images2[image]
	end
	local x = data.X
	local z = data.Z

	local func = function()
		for key, value in pairs(img[2]) do
			for k, v in gmatch(key,"(%w+),(%w+)") do
				SetHeightMap(tonumber(v)+data.X,tonumber(k)+data.Z, GetGroundOrigHeight(v+data.X,k+data.Z))
			end
		end
	end
	emit(data)
	SetHeightMapFunc(func)
end


function create_crack(data)
	local image = data.image
	local img
	if data.file == 1 then
		img = images[image]
	else
		img = images2[image]
	end
	local x = data.X
	local z = data.Z
	local func = function()
		for key, value in pairs(img[2]) do
			for k, v in gmatch(key,"(%w+),(%w+)") do
				local height = GetGroundOrigHeight(v+x,k+z)
				if value ~= 0 then
					SetHeightMap(tonumber(v)+x,tonumber(k)+z, height - value)
				end
			end
		end
	end
	emit(data)
	SetHeightMapFunc(func)
	--local xmid = x + math.floor(0.5*img[1]["x"])
	--local zmid = z + math.floor(0.5*img[1]["z"])
	--damage_near_units(xmid,zmid , damage_radius*4)
end


function add_crack()
	local file = random(1, 2)
	local image = random(1, 5)
	local X
	local Z
	local img
	if file == 1 then
		img = images[image]
	else
		img = images2[image]
	end
	if middle == false then
		X = floor(random(0,(mapX*512-img[1]["x"])))
		Z = floor(random(0, (mapZ*512-img[1]["z"])))
	else
		X = floor(random(crackAreaX,  mapX*512-crackAreaX-img[1]["x"]))
		Z = floor(random(crackAreaZ,  mapZ*512-crackAreaX-img[1]["z"]))
	end
	local crack = {file = file, duration = duration, image = image, X = X, Z = Z}
	cracks[#cracks+1] = crack
	emit(crack)
	--local xmid = X + math.floor(0.5*img[1]["x"])
	--local zmid = Z + math.floor(0.5*img[1]["z"])
	--damage_near_units(xmid,zmid , damage_radius)
	return crack
end


-- update cracks
function update()
		
	-- remove
	for i=#cracks,1,-1 do
		local v = cracks[i]
		if v.duration - timeDelayCrack < 0 then
			emit(v)
			remove_cracks[#remove_cracks+1] = cracks[i]
			remove(cracks, i)
		else
			cracks[i].duration = v.duration - 2*timeDelayCrack
		end
	end

	-- add
	if #add_cracks > 0 then
		for k,v in pairs(add_cracks) do
			create_crack(v)
		end
		add_cracks = {}
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
		local units = GetAllUnits()
		local can_move = {}
		for index, unitID in pairs(units) do
			does_move = moving[tostring(UnitDefs[GetUnitDefID(unitID)].moveDef.name)] ~= nil
			if does_move == true then 
				table.insert(can_move, GetUnitDefID(unitID))
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


-- DAMAGE FUNCTIONS


function update_damage()
	
	-- updating units causing damage
	for k,v in pairs(unitsDoDamage) do
		if ValidUnitID(k) == true then
			unitsDoDamage[k].damage = v.damage + damageValues[v.unitName].dDamage	
			unitsDoDamage[k].radius = v.radius + damageValues[v.unitName].dRadius
			local x, y, z = GetUnitPosition(k)
			unitsDoDamage[k].x = x
			unitsDoDamage[k].y = y
			unitsDoDamage[k].z = z
		elseif v.duration > 0 then
			unitsDoDamage[k].damage = v.damage - damageValues[v.unitName].dDamage
			unitsDoDamage[k].radius = v.radius - damageValues[v.unitName].dRadius
			local effectiveRadius = v.radius - damageValues[v.unitName].dRadius
			local effectiveDamage = v.damage - damageValues[v.unitName].dDamage
			unitsDoDamage[k].duration = v.duration - timeDelayDamage*2 
			if  effectiveRadius < 0 or effectiveDamage < 0 then
				unitsDoDamage[k] = nil
			end
			 
		else
			unitsDoDamage[k] = nil
		end
	end	
	

	-- update damaged to units/features
	for k,v in pairs(unitsDoDamage) do
		local near_units = GetUnitsInSphere(v.x,v.y,v.z, v.radius)
		local near_features = GetFeaturesInSphere(v.x,v.y,v.z, v.radius)

		if not (near_units == nil) then
			for i in pairs(near_units) do
				local unitID = near_units[i]
				local xu,yu,zu = GetUnitPosition(unitID)
				local multiplier = 1-sqrt( (v.x-xu)*(v.x-xu) + (v.y-yu)*(v.y-yu) + (v.z-zu)*(v.z-zu) )/v.radius
				local damage = damageToUnits[unitID] or 0
				if unitsDoDamage[unitID] == nil then
					damageToUnits[unitID] = max(v.damage *multiplier,damage)
				else 
					damageToUnits[unitID] = max(damageValues[v.unitName].self,damage)
					if k ~= unitID then
						damageToUnits[unitID] = max(damageToUnits[unitID],v.damage *multiplier)
					end 
				end
			end
		end
		if not (near_features == nil) then
			for i in pairs(near_features) do
				if not FeatureDefs[GetFeatureDefID(near_features[i])].geoThermal then 
					local featureID = near_features[i]
					local unitDefID = GetUnitDefID(featureID)
					local xf,yf,zf = GetFeaturePosition(featureID)
					local multiplier = 1-sqrt( (v.x-xf)*(v.x-xf) + (v.y-yf)*(v.y-yf) + (v.z-zf)*(v.z-zf) )/v.radius
					local damage = damageToFeatures[featureID] or 0
					damageToFeatures[featureID] = max(v.damage*multiplier,damage)
					-- remove also grass?
					-- show fx?
				end
			end
		end
		
	end
	
end


function apply_damage()
	for k,v in pairs(damageToUnits) do
		if ValidUnitID(k) == true then
			AddUnitDamage(k, v)
			damageToUnits[k] = 0
		else
			damageToUnits[k] = nil
		end			
	end
	for k,v in pairs(damageToFeatures) do
		-- test if unit exists
		if ValidFeatureID(k) then
			local feature_health = GetFeatureHealth(k)
			SetFeatureHealth(k,feature_health-v)
			damageToFeatures[k] = 0
		else
			damageToFeatures[k] = nil
		end			
	end
end


-- LOOP --


function gadget:GameFrame(f)

	-- RANDOMIZE --

	if (f%randomize_number_of_cracks*timeDelayCrack ==0) then
		number_of_cracks = random(0, max_cracks)
	end

	if (f%randomize_number_of_comets*timeDelayComet ==0) then
		number_of_comets = random(0, max_comets)
	end

	-- COMET PART --

	if (f%5 == 0) then

		if not (#comets == 0) then

			update_comet()

		else

			if f%timeDelayComet == 0 then

				if not (number_of_comets==0) then
					
					Echo("WARNING observatory station detects ".. tostring(number_of_comets) .. " incoming meteorites!")
					
					-- set new unitname for units from dropping comet
					getUnitName()

					--make some comets
					local x = floor(random(0,  mapX*512))
					local z = floor(random(0,  mapZ*512))

					for i=1,number_of_comets do
						comets[#comets+1] = add_comet(x,z)
						
					end

				end

			end

		end

	end

	-- CRACK PART

	if (f%timeDelayCrack == 0) then

		if (f%2 ==0) then

			-- check if there is room for more cracks
			if #cracks < max_cracks then

				-- add new cracks
				add_cracks[#add_cracks+1] = add_crack()

				if random() < 0.5 then
					Echo("WARNING seismic activity detected!")
				end

			end

			if #remove_cracks > 0 then

				for k,v in pairs(remove_cracks) do
					remove_crack(v)
				end
				remove_cracks = {}
			end
		else
			update()
		end
	end



	-- MAP DAMAGE TO UNITS/FEATURES PART

	if (f%timeDelayDamage == 0) then

		if (f%2 ==0) then
			
			update_damage()

		else

			apply_damage()

		end
	end

end


-- ADDITIONAL FUNCTIONS


function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	local name = UnitDefs[unitDefID].name
	if damageValues[name] ~= nil then
		local damage = damageValues[name].value
		local radius = damageValues[name].radius
		local x, y, z = GetUnitPosition(unitID)
		local duration = damageValues[name].duration
		unitsDoDamage[unitID] = {
			["damage"] = damage,
			["radius"] = radius,
			["unitName"] = name,
			["x"] = x,
			["y"] = y,
			["z"] = z,
			["duration"] = duration
		}
	end 
end 



