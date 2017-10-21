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
	
--]]


-- synced
if (gadgetHandler:IsSyncedCode()) then

-- locals
local Echo						= Spring.Echo
local GaiaTeamID  				= Spring.GetGaiaTeamID()
local random					= math.random
local mapX 						= Game.mapX
local mapY 						= Game.mapY
local crackChange 				= 0.3
local duration					= 0.7
local GetGroundHeight			= Spring.GetGroundHeight
local PlaySoundFile				= Spring.PlaySoundFile
local img 						= include("LuaRules/gadgets/img.lua")
local crushCEG 					= "dirtballtrail"
local crushCEG2					= "FLAKFLARE"
local crushCEG3					= "Sparks"
local metalcloud1				= "buttsmoke"
local metalcloud2				= "smokeshell_medium"
local SpawnCEG					= Spring.SpawnCEG
local eceg 						= "gplasmaballbloom"
local mceg 						= "bplasmaballbloom"
local crushsnd					= "sounds/battle/crush3.wav"
local positionCrackX 			= 0
local positionCrackZ 			= 0
local crack 					= false
local noCracks 					= true
local crackAreaX				= math.floor(mapX*512*1/10)
local crackAreaZ				= math.floor(mapY*512*1/10)
local maps 						= {
	["TheColdPlace"] = true,
	["The Cold Place Remake V3c"] = true,
	["The Cold Place Remake"] =  true,
	["Geyser_Plains_TNM04-V3"] = true,
}

local fx_placement = {}
for key, value in pairs(img) do
	if value ~= 0 and random() < 0.01 then
		fx_placement[key] = value
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


function gadget:GameFrame(f)
	
	if (f%120 == 0) and crack == false then
 
		if random() < crackChange and noCracks == true then  -- for now this always works		
			positionCrackX = math.floor(random(mapX*512/4,mapX*512*3/4))
			positionCrackZ = math.floor(random(mapY*512/4,mapY*512*3/4))
			crack = true
		end
	end
	
	if (crack == true) then

		if (f%100 == 0) then
			if (random() < 0.5) then
				local x = math.floor(positionCrackX)
				local z = math.floor(positionCrackZ)
				local y = Spring.GetGroundHeight(x,z)
				
				for key, value in pairs(fx_placement) do
					for k, v in string.gmatch(key,"(%w+),(%w+)") do
						--tonumber(k)
						--tonumber(v)
						SpawnCEG(metalcloud2,tonumber(v)+x, y+10, tonumber(k)+z)
					 end
				end
				
				--for key, value in pairs(img) do
				--	for k, v in string.gmatch(key,"(%w+),(%w+)") do
						--tonumber(k)
						--tonumber(v)
				--		if value ~= 0 and random() < 0.1 then
				--			SpawnCEG(metalcloud2,tonumber(v)+x, y+10, tonumber(k)+z)
				--		end
				--	 end
				--end 
			end
			
			if (random() < 0.1) then
				Echo("WARNING seismic activity detected!")
			end
		end
		
		if (f%1000 == 0) and noCracks == true then
			
			local x = math.floor(positionCrackX)
			local z = math.floor(positionCrackZ)
			local y = Spring.GetGroundHeight(x,z)
			SpawnCEG(metalcloud2,x, y+10, z)
			PlaySoundFile (crushsnd, 2.0, x,y,z, 0,0,0,'battle')
			
			local func = function()
				for key, value in pairs(img) do
					for k, v in string.gmatch(key,"(%w+),(%w+)") do
						local height = Spring.GetGroundOrigHeight(v+x,k+z)
						if value ~= 0 then
							Spring.SetHeightMap(tonumber(v)+x,tonumber(k)+z, height - value)
						end
					 end
				end
			end
			Spring.SetHeightMapFunc(func)
			for key, value in pairs(img) do
				for k, v in string.gmatch(key,"(%w+),(%w+)") do
					local height = Spring.GetGroundOrigHeight(v+x,k+z)
					if value ~= 0 and random()< 0.2 then
						SpawnCEG(metalcloud2,tonumber(v)+x, y+10, tonumber(k)+z)
					end
				 end
			end 
			noCracks = false
		end
		
		if (f%1700 == 0) and duration > random() then	
		
			local x = math.floor(positionCrackX)
			local z = math.floor(positionCrackZ)
			local y = Spring.GetGroundHeight(x,z)
			SpawnCEG(metalcloud2,x, y+10, z)
			PlaySoundFile (crushsnd, 2.0, x,y,z, 0,0,0,'battle')
			
			local func = function()
				for key, value in pairs(img) do
					for k, v in string.gmatch(key,"(%w+),(%w+)") do
						if value ~= 0 then
							Spring.SetHeightMap(tonumber(v)+x,tonumber(k)+z, Spring.GetGroundOrigHeight(v+x,k+z))
						end
					 end
				end
			end
			Spring.SetHeightMapFunc(func)
			for key, value in pairs(img) do
				for k, v in string.gmatch(key,"(%w+),(%w+)") do
					local height = Spring.GetGroundOrigHeight(v+x,k+z)
					if value ~= 0 and random()< 0.2 then
						SpawnCEG(metalcloud2,tonumber(v)+x, y+10, tonumber(k)+z)
					end
				 end
			end 
			crack = false
			noCracks = true
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
