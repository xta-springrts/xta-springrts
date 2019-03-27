function gadget:GetInfo()
	return {
		name      	= "earthquake",
		desc      	= "Cracks appear in the map",
		author    	= "res",
		date      	= "8-10-2018",
		license 	= "GNU GPL, v3 or later",
		layer     	= 1,
		enabled   	= true,
	}
end


	--[[

		Does: 
			- after a random period parts of the map will experience crack's in surface.
			- after an hour the surface cracks

		parameters options:
			- duration_crack
			- max_cracks

		# TODO:
			- maybe make units deal damage near an appearing crack?

	--]]	


-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end


-- LOCALS --


local floor 						= math.floor
local random						= math.random
local sqrt							= math.sqrt
local max							= math.max

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
local GaiaTeamID  					= Spring.GetGaiaTeamID()
local SetUnitNeutral				= Spring.SetUnitNeutral
local SetUnitNoSelect				= Spring.SetUnitNoSelect
local CreateUnit					= Spring.CreateUnit
local DestroyUnit					= Spring.DestroyUnit
local SetUnitAlwaysVisible			= Spring.SetUnitAlwaysVisible
local SetUnitPosition 				= Spring.SetUnitPosition
local SetUnitStealth				= Spring.SetUnitStealth
local TransferUnit					= Spring.TransferUnit
local GetTeamList 					= Spring.GetTeamList()
local GetAllUnits 					= Spring.GetAllUnits
local ValidFeatureID 				= Spring.ValidFeatureID
local ValidUnitID 					= Spring.ValidUnitID

local earthquakeWeapons 			= include("LuaRules/Configs/earthquake_config.lua")
local images 					    = include("LuaRules/gadgets/img.lua")
local images2 					  	= include("LuaRules/gadgets/img2.lua")
local images3 					  	= include("LuaRules/gadgets/img3.lua")
local COMET_FIRE				  	= "RedPlasmaComet"
local COMET_HIT_GROUND				= "SMALL_NUKE_EXPLOSION_INIATE_COMET"
local PUFFY							= "PUFFY_COMET"
local crushsnd					  	= "sounds/battle/crush3.wav"
local mapX 					      	= Game.mapX
local mapZ 					      	= Game.mapY


-- SETTINGS --


local damageToUnits 				= {}
local damageToFeatures 				= {}
local unitsDoDamage					= {}
local timeDelayCrack				= 30 * 60 + 1 -- 1 min  (should be uneven)
local duration						= tonumber(modOptions.duration_crack) *30 *60 + 1 or 9000 +1 	-- 5 min crack duration
local crackAreaX					= floor(mapX*512*1/10)											-- defines middle 
local crackAreaZ					= floor(mapZ*512*1/10)
local middle 					  	= tonumber(modOptions.middle_crack) or false					-- is middle only cracked?
local cracks						= {}
local remove_cracks					= {}
local add_cracks					= {}
local max_cracks					= tonumber(modOptions.max_cracks) or 10
local randomize_number_of_cracks	= 150 -- same as below but for cracks
local armmageddon_frame				= 30 * 60 * 60 --60


-- READ IN IMAGES AND AUDIO


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


-- INITIALISE --


function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.earthquake)== 0 then
		Echo("earthquake.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	else
		Echo("earthquake.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
		DisableMapDamage=0
		Echo("Seismic activity predicted in forecast models, be aware!")
		for w,_ in pairs(earthquakeWeapons) do
			Script.SetWatchWeapon(w, true)
		end
	end
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


function add_crack_weapon(x,z)
	local file = random(1, 2)
	local image = random(1, 5)
	local img
	if file == 1 then
		img = images[image]
	else
		img = images2[image]
	end
	local X = floor(x-img[1]["x"]*0.5)
	local Z = floor(z-img[1]["z"]*0.5)
	local crack = {file = file, duration = duration, image = image, X = X, Z = Z}
	cracks[#cracks+1] = crack
	emit(crack)
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


function gadget:Explosion(weaponID, px, py, pz, ownerID, ProjectileID)
	if (earthquakeWeapons[weaponID]) then -- if selfradiation undo the onwner~=nil check
		local radius = earthquakeWeapons[weaponID].radius or 500
		local x = random(px-radius, px+radius)
		local z = random(pz-radius, pz+radius)
		add_cracks[#add_cracks+1] = add_crack_weapon(x,z)
	end
end


-- LOOP --


function gadget:GameFrame(f)

	-- RANDOMIZE --
	if (f%randomize_number_of_cracks*timeDelayCrack ==0) then
		number_of_cracks = random(0, max_cracks)
	end

	if f == armmageddon_frame then
		Echo("WARNING observatory station detects a huge seismic activity!")
		max_cracks = 20
		number_of_cracks = 10
		duration = 30 * 60 * 10 + 1 -- 10 min
		timeDelayCrack = 30 * 10 + 1 -- 1 min  (should be uneven)
	end
	
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

end
