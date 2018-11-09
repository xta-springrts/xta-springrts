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

		-parameters:
			- max cracks (at same time) (default = 10)
			- area of cracks (in the middle only) (default is middle = False)

		-make more logic in comet spawn loop
		-add explotions to destroyed units and features
		-balance the damage doen by comets

		# TODO
		Implement options:
			- max_cracks [0-40]
			- crackInterval
			- comet interval
			- tweak parameters (that might be set map specific)
			- damage comets parameter
			- damage crack parameter
--]]

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end


-- LOCALS --

local floor 						= math.floor
local random					    = math.random
local sqrt							= math.sqrt

local gmatch						= string.gmatch
local remove						= table.remove


local SetFeatureHealth				= Spring.SetFeatureHealth
local DestroyFeature				= Spring.DestroyFeature
local GetFeatureHealth				= Spring.GetFeatureHealth
local GetFeaturePosition			= Spring.GetFeaturePosition
local AddUnitDamage 				= Spring.AddUnitDamage
local GetFeaturesInSphere			= Spring.GetFeaturesInSphere
local GetUnitPosition				= Spring.GetUnitPosition
local GetUnitDefID					= Spring.GetUnitDefID
local Echo					      	= Spring.Echo
local GetUnitsInCylinder			= Spring.GetUnitsInCylinder
local GetGroundHeight				= Spring.GetGroundHeight
local GetGroundOrigHeight			= Spring.GetGroundOrigHeight
local SetHeightMapFunc				= Spring.SetHeightMapFunc
local PlaySoundFile					= Spring.PlaySoundFile
local SetHeightMap 					= Spring.SetHeightMap
local SpawnCEG					  	= Spring.SpawnCEG

local images 					    = include("LuaRules/gadgets/img.lua")
local images2 					  	= include("LuaRules/gadgets/img2.lua")
local images3 					  	= include("LuaRules/gadgets/img3.lua")
local crushCEG 					  	= "dirtballtrail"
local crushCEG2					  	= "FLAKFLARE"
local crushCEG3					  	= "Sparks"
local metalcloud1				  	= "buttsmoke"
local metalcloud2				  	= "smokeshell_medium"
local eceg 					      	= "gplasmaballbloom"
local mceg 					      	= "bplasmaballbloom"
local crushsnd					  	= "sounds/battle/crush3.wav"

local mapX 					      	= Game.mapX
local mapY 					      	= Game.mapY

-- SETTINGS --


local timeDelay						= 301						-- one and half minute delay
local timeDelayComet 				= 201
local crackInterval 				= 1800						-- one minute time delay new crack
local crackChange 					= 0.7
local duration						= 30 * 60 * 5 				-- 5 min crack
local crackAreaX					= floor(mapX*512*1/10)		-- defines middle of the map
local crackAreaZ					= floor(mapY*512*1/10)
local middle 					  	= false						-- is middle only cracked?
local damage 					  	= false
local maps 					    	= {							-- maps
	["TheColdPlace"] 			        = true,
	["The Cold Place Remake V3c"] 		= true,
	["The Cold Place Remake"] 		    = true,
	["Geyser_Plains_TNM04-V3"] 		    = true,
	["hotstepper_lm"] 			        = true,
	["DeltaSiegeDry"] 			        = true,
	["small_supreme_battlefield_v2"] 	= true,
	["FolsomDamFinal"] 			        = true,
	["Tabula v2"] 				        = true,
	["Small Supreme Battlefield V2"]	= true
}
local cracks						= {}
local remove_cracks					= {}
local add_cracks					= {}
local max_cracks					= 10
local max_comets					= 10
local damage_radius					= 500
local damage_value            		= 500


local fx = {
	[1] = {[1]={}, [2]={}, [3]={}, [4]={}, [5]={}},
	[2] = {[1]={}, [2]={}, [3]={}, [4]={}, [5]={}}
}

for k,v in pairs(images) do
	for key, value in pairs(v[2]) do
		if value ~= 0 and random() < 0.01 then
			fx[1][k][key] = value
		end
	end
end
for k,v in pairs(images2) do
	for key, value in pairs(v[2]) do
		if value ~= 0 and random() < 0.01 then
			fx[2][k][key] = value
		end
	end
end


-- COMET STUFF --

local cometRainRadius 				= 500
local comets						= {}
local cometheight 					= 3000
local ast_size 						= images3[1]
local ast_image						= images3[2]
local cometold          				= false
local fx_comit 						= {}
for k,v in pairs(ast_image) do
	if v ~= 0 and random() < 0.01 then
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

	-- uncommand this to add map specificity (see table: maps earlier defined)

	--if (maps[Game.mapName] == nil or maps[Game.mapName] == maps[Game.mapName] == false) then
	--  Echo("no earth_crack setup for this map found.")
	--  gadgetHandler:RemoveGadget(self)
	--else
	Echo("Seismic activity predicted in forecast models, be aware!")
	Echo("Good afternoon the weather predicts meteor showers, have a nice day!")
	--end

end


-- HELP FUCNTION --


function damage_near_units(x,z, radius)

	near_units = GetUnitsInCylinder(x,z, radius)
	local y = GetGroundHeight(x,z)
	near_features = GetFeaturesInSphere(x,y,z, radius)

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
			xf, yf, zf = GetFeaturePosition(near_features[i])
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



function emit(data)
	if data ~= nil then
		local file = data.file
		local img = data.image
		local x = data.X
		local z = data.Z

		-- emit fx on points
		for key, value in pairs(fx[file][img]) do
			for k, v in gmatch(key,"(%w+),(%w+)") do
				if random() < 0.1 then
					local y = GetGroundHeight(k,v)
					SpawnCEG(metalcloud2,tonumber(v)+x, y+10, tonumber(k)+z)
					if random() < 0.1 then
						PlaySoundFile (crushsnd, 2.0, x,y,z, 0,0,0,'battle')
					end
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
			for k, v in string.gmatch(key,"(%w+),(%w+)") do
				local height = GetGroundOrigHeight(v+x,k+z)
				if value ~= 0 then
					SetHeightMap(tonumber(v)+x,tonumber(k)+z, height - value)
				end
			end
		end
	end
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
		Z = floor(random(0, (mapY*512-img[1]["z"])))
	else
		X = floor(random(crackAreaX,  mapX*512-crackAreaX-img[1]["x"]))
		Z = floor(random(crackAreaZ,  mapY*512-crackAreaX-img[1]["z"]))
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
		if v.duration - timeDelay < 0 then
			emit(v)
			remove_cracks[#remove_cracks+1] = cracks[i]
			remove(cracks, i)
		else
			cracks[i].duration = v.duration - 2*timeDelay
		end
	end

	-- add
	if #add_cracks > 0 then
		for k,v in pairs(add_cracks) do
			-- todo add crack
			create_crack(v)
		end
		add_cracks = {}
	end
end


-- COMET FUNCTIONS


function emit_comit(comet)
	SpawnCEG(eceg, comet.X, comet.Y, comet.Z)
	SpawnCEG(metalcloud2,comet.X, comet.Y, comet.Z)
end



function emit_hit_ground(comet)
	local x = comet.X
	local y = comet.groundHeight
	local z = comet.Z
	-- optimaze by getting random values in advange
	for key, value in pairs(fx_comit) do
		for k, v in string.gmatch(key,"(%w+),(%w+)") do
			if random() < 0.2 then  -- if k+v%5 == 0  (same but faster?)
				if random() < 0.5 then -- if k+v%2==0 (same)
					SpawnCEG(metalcloud2,tonumber(v)+x+ random(0,100), y, tonumber(k)+z + random(0,100))
					SpawnCEG(eceg,tonumber(v)+x+ random(0,100), y+10, tonumber(k)+z + random(0,100))
					if random() < 0.05 then -- alternative -> if %k+v == 5 (SPEED UP?)
 						PlaySoundFile (crushsnd, 2.0,tonumber(v)+ x,y,tonumber(k)+z, 0,0,0,'battle')
					end
				else
					SpawnCEG(metalcloud2,tonumber(v)+x -random(0,100), y, tonumber(k)+z - random(0,100))
					SpawnCEG(eceg,tonumber(v)+x - random(0,100), y+10, tonumber(k)+z - random(0,100))
					if random() < 0.05 then
						PlaySoundFile (crushsnd, 2.0, tonumber(v)+x,y,tonumber(k)+z, 0,0,0,'battle')
					end

				end
			end
		end
	end
end


function add_comet(x,y)
	local X = random(x-cometRainRadius, x+cometRainRadius)
	local Z = random(y-cometRainRadius, y+cometRainRadius)
	local Y = random(3000, 6000)
	local impact = random(0,20)
	local height = GetGroundOrigHeight(X,Z)
	local originalHeight = GetGroundOrigHeight(X,Z)
	local comet = {hit = false, groundHeight = height, impact = impact, X = X, Y = Y, Z = Z}
	return comet
end


-- update comet
function update_comet()

	for i=#comets,1,-1 do
		local v = comets[i]
		if v.hit == true then
			table.remove(comets, i)
		elseif v.groundHeight-v.Y < 0 then
			emit_comit(v)
			comets[i].Y = v.Y - 30
		else
			emit_hit_ground(v)
			deform_ground(v)
			damage_near_units(v.X,v.Z, damage_radius*1)
			comets[i].hit = true
		end
	end

end


function deform_ground(comet)
	local x =floor(ast_size["x"]/2)
	local z = floor(ast_size["z"]/2)
	local xc = comet.X
	local zc = comet.Z
	local func = function()
		for key, value in pairs(ast_image) do
			for k, v in gmatch(key,"(%w+),(%w+)") do
				local height = GetGroundOrigHeight(v+xc,k+zc) --THIS MIGHT BE EXPENNSIVE (but cant consider straingt ground)
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

	-- RANDOMIZE --

	-- randomize number of comets
	if (f%100*timeDelay ==0) then
		number_of_cracks = random(0, max_cracks)
	end

	-- randomize number of cracks
	if (f%100*timeDelayComet ==0) then
		number_of_comets = random(0, max_comets)
	end

	-- COMET PART --

	--  new part begin

	if (f%5 == 0) then

		if not (#comets == 0) then

			update_comet()

		else

			-- this should be f%5==0 aswell !!!!! (bad programming)
			--if (f%timeDelayComet == 0) then
			if f%timeDelayComet == 0 then

				Echo("WARNING observatory station detects", number_of_comets,"incoming meteorites!")

				--make some comets
				local x = math.floor(random(0,  mapX*512-ast_size["x"]))
				local z = math.floor(random(0,  mapY*512-ast_size["z"]))

				for i=1,number_of_comets do
					comets[#comets+1] = add_comet(x,z)
				end
			end

		end

	end

	-- CRACK PART

	if (f%timeDelay == 0) then

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

			-- update the crack times
			update()
		end
	end
end

--local y = Spring.GetGroundHeight(xx,zz)
--Spring.LevelHeightMap(xx,zz,y+100)

--[[
Spring.GetGroundHeight
Spring.GetGroundOrigHeight
Spring.GetGroundNormal
Spring.GetGroundInfo
Spring.GetGroundBlocked
Spring.GetGroundExtremes
]]--

--spGetGroundHeight
--spGetGroundOrigHeight
--Spring.LevelHeightMap
--Spring.AdjustHeightMap
--Spring.RevertHeightMap
--Spring.SetHeightMapFunc
--Spring.AddHeightMap
--Spring.SetHeightMap

--t = {[1] = { images = 2, number =1}, [2] = { images = 2, number =1}}
--print(t[1].images)
--print(#t)
--t[#t+1] = {images = 3, number = 3}
--print(t[3].images)

