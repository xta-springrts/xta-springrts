function gadget:GetInfo()
  return {
    name      	= "earth_crack",
    desc      	= "When the gods get angry",
    author    	= "res",
    date      	= "8-10-2017",
    license 	= "GNU GPL, v3 or later",
    layer     	= -99, --negative, otherwise wildlife do not disappear on death 
    enabled   	= true,
	}
end

--[[

	After a random period parts of the map will experience crack's in surface and rumbling and tunmbling noises
	TODO 	- add damage
		- make more cracks at same time
	
--]]

-- synced
if (gadgetHandler:IsSyncedCode()) then

-- locals
local Echo					= Spring.Echo
local GaiaTeamID  				= Spring.GetGaiaTeamID()
local random					= math.random
local mapX 					= Game.mapX
local mapY 					= Game.mapY
local GetGroundHeight				= Spring.GetGroundHeight
local GetGroundOrigHeight			= Spring.GetGroundOrigHeight
local SetHeightMapFunc				= Spring.SetHeightMapFunc
local PlaySoundFile				= Spring.PlaySoundFile
local SetHeightMap 				= Spring.SetHeightMap
local images 					= include("LuaRules/gadgets/img.lua")
local images2 					= include("LuaRules/gadgets/img2.lua")
local images3 					= include("LuaRules/gadgets/img3.lua")
local crushCEG 					= "dirtballtrail"
local crushCEG2					= "FLAKFLARE"
local crushCEG3					= "Sparks"
local metalcloud1				= "buttsmoke"
local metalcloud2				= "smokeshell_medium"
local SpawnCEG					= Spring.SpawnCEG
local eceg 					= "gplasmaballbloom"
local mceg 					= "bplasmaballbloom"
local crushsnd					= "sounds/battle/crush3.wav"
local fx_placement 				= {}

-- settings
local timeDelay					= 301				-- one and half minute delay
local crackInterval 				= 1800				-- one minute time delay new crack
local crackChange 				= 0.7
local duration					= 30 * 60 * 5 			-- 5 min crack
local crackAreaX				= math.floor(mapX*512*1/10)	-- defines middle of the map
local crackAreaZ				= math.floor(mapY*512*1/10)
local middle 					= false				-- is middle only cracked?
local damage 					= false
local maps 					= {				-- maps
	["TheColdPlace"] 			= true,
	["The Cold Place Remake V3c"] 		= true,
	["The Cold Place Remake"] 		= true,
	["Geyser_Plains_TNM04-V3"] 		= true,
	["hotstepper_lm"] 			= true,
}
local cracks					= {}
local remove_cracks				= {}
local add_cracks				= {}
local max_cracks				= 10


local fx = { 
	[1] = {[1]={}, [2]={}, [3]={}, [4]={}, [5]={}},
	[2] = {[1]={}, [2]={}, [3]={}, [4]={}, [5]={}}
}

for k,v in pairs(images) do
	for key, value in pairs(v[2]) do
		if value ~= 0 and random() < 0.001 then
			fx[1][k][key] = value
		end
	end
end
for k,v in pairs(images2) do
	for key, value in pairs(v[2]) do
		if value ~= 0 and random() < 0.001 then
			fx[2][k][key] = value
		end
	end
end

-- comet
local cometx 			= nil
local cometz 			= nil
local cometheight 		= 3000
local ast_size 			= images3[1]
local ast_image			= images3[2]
local comet = false
local fx_comit 			= {}
for k,v in pairs(ast_image) do
	if v ~= 0 and random() < 0.001 then
		fx_comit[k] = v
	end
end


function gadget:Initialize()
	local mo = Spring.GetModOptions()
	if mo and tonumber(mo.earth_crack)== 0 then
		Echo("earth_crack.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	end
	
	Echo("gaia_wildlife.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
	if (maps[Game.mapName] == nil or maps[Game.mapName] == maps[Game.mapName] == false) then
		Echo("no earth_crack setup for this map found.")
		gadgetHandler:RemoveGadget(self)
	else
		Echo("Seismic activity predicted in forecast models, be aware!")
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
			for k, v in string.gmatch(key,"(%w+),(%w+)") do
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
			for k, v in string.gmatch(key,"(%w+),(%w+)") do
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
		X = math.floor(random(0,(mapX*512-img[1]["x"])))
		Z = math.floor(random(0, (mapY*512-img[1]["z"])))
	else
		X = math.floor(random(crackAreaX,  mapX*512-crackAreaX-img[1]["x"]))
		Z = math.floor(random(crackAreaZ,  mapY*512-crackAreaX-img[1]["z"]))
	end
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
		if v.duration - timeDelay < 0 then
			--emit(cracks[k])
			remove_cracks[#remove_cracks+1] = cracks[i]
			table.remove(cracks, i) 
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


function gadget:GameFrame(f)
	
	if (f%100*timeDelay ==0) then
		number_of_cracks = random(0, max_cracks)
	end 
	
	if (f%5 == 0) then
		if comet == false and random() < 0.05 then
			comitx = math.floor(random(0,  mapX*512-ast_size["x"]))
			comitz = math.floor(random(0,  mapY*512-ast_size["z"]))
			comet = true
		elseif comet == false then
			if comitx ~= nil then
				for key, value in pairs(fx_comit) do
					for k, v in string.gmatch(key,"(%w+),(%w+)") do
						if random() < 0.2 then
							local y = GetGroundHeight(k+comitx,v+comitz)
							if random() < 0.5 then
								SpawnCEG(metalcloud2,tonumber(v)+comitx+ math.floor(random(0,100)), y, tonumber(k)+comitz + math.floor(random(0,100)))
								SpawnCEG(eceg,tonumber(v)+comitx+ math.floor(random(0,100)), y+10, tonumber(k)+comitz + math.floor(random(0,100)))
								if random() < 0.1 then
									PlaySoundFile (crushsnd, 2.0,tonumber(v)+ comitx,y,tonumber(k)+comitz, 0,0,0,'battle')
								end
							else
								SpawnCEG(metalcloud2,tonumber(v)+comitx - math.floor(random(0,100)), y, tonumber(k)+comitz - math.floor(random(0,100)))
								SpawnCEG(eceg,tonumber(v)+comitx - math.floor(random(0,100)), y+10, tonumber(k)+comitz - math.floor(random(0,100)))
								if random() < 0.1 then
									PlaySoundFile (crushsnd, 2.0, tonumber(v)+comitx,y,tonumber(k)+comitz, 0,0,0,'battle')
								end
							
							end
						end
					end
				end
			end
		else
			local x = math.floor(ast_size["x"]/2)
			local z = math.floor(ast_size["z"]/2)
			local height = GetGroundOrigHeight(comitx,comitz) + cometheight
			SpawnCEG(eceg,comitx+x, height, comitz+z)
			SpawnCEG(eceg,comitx+x, height-1, comitz+z)
			SpawnCEG(eceg,comitx+x, height+1, comitz+z)
			SpawnCEG(eceg,comitx+x-1, height-1, comitz-1+z)
			SpawnCEG(eceg,comitx+x+1, height-1, comitz+1+z)
			SpawnCEG(eceg,comitx+x-1, height+1, comitz+1+z)
			SpawnCEG(eceg,comitx+x+1, height+1, comitz-1+z)
			SpawnCEG(metalcloud2,comitx+x, height, comitz+z)
			SpawnCEG(metalcloud2,comitx+x, height-1, comitz+z)
			SpawnCEG(metalcloud2,comitx+x, height+1, comitz+z)
			SpawnCEG(metalcloud2,comitx+x-1, height-1, comitz-1+z)
			SpawnCEG(metalcloud2,comitx+x+1, height-1, comitz+1+z)
			SpawnCEG(metalcloud2,comitx+x-1, height+1, comitz+1+z)
			SpawnCEG(metalcloud2,comitx+x+1, height+1, comitz-1+z)
			if GetGroundOrigHeight(comitx,comitz) + cometheight < 0 then
				--comitx = math.floor(random(0,  mapX*512))
				--comitz = math.floor(random(0,  mapY*512))
				local func = function()
					for key, value in pairs(ast_image) do
						for k, v in string.gmatch(key,"(%w+),(%w+)") do
							local height = GetGroundOrigHeight(v+comitx,k+comitz)
							if value ~= 0 then
								SetHeightMap(tonumber(v)+comitx,tonumber(k)+comitz, height + value -21)
							end
						 end
					end
				end
				SetHeightMapFunc(func)	

				comet = false
				cometheight = 4000
			else
				cometheight = cometheight - 60
			end
		end
		
	end
	
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
					-- todo add crack
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
 
--unsynced
else
	return false
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
			
