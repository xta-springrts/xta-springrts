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
	TODO - add damage
	
--]]


-- synced
if (gadgetHandler:IsSyncedCode()) then

-- locals
local Echo						= Spring.Echo
local GaiaTeamID  				= Spring.GetGaiaTeamID()
local random					= math.random
local mapX 						= Game.mapX
local mapY 						= Game.mapY
local GetGroundHeight			= Spring.GetGroundHeight
local GetGroundOrigHeight		= Spring.GetGroundOrigHeight
local SetHeightMapFunc			= Spring.SetHeightMapFunc
local PlaySoundFile				= Spring.PlaySoundFile
local SetHeightMap 				= Spring.SetHeightMap
local images 					= include("LuaRules/gadgets/img.lua")
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
local noCrack 					= true
local fx_placement 				= {}
local img_used 					= {}
local image						= {}
local size						= {}

-- settings
local timeDelayFirstCrack		= 3000							-- one and half minute delay
local crackInterval 			= 1800							-- one minute time delay new crack
local crackChange 				= 0.7
local duration					= 30 * 60 * 5					-- 5 min crack
local crackAreaX				= math.floor(mapX*512*1/10)		-- defines middle of the map
local crackAreaZ				= math.floor(mapY*512*1/10)
local middle 					= false							-- is middle only cracked?
local damage 					= false
local maps 						= {								-- maps
	["TheColdPlace"] 				= true,
	["The Cold Place Remake V3c"] 	= true,
	["The Cold Place Remake"] 		= true,
	["Geyser_Plains_TNM04-V3"] 		= true,
	["hotstepper_lm"] 				= true,
}


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
	
	if (f > timeDelayFirstCrack) then
		-- check every minute 
		if (f%crackInterval == 0) and crack == false then
			
			-- after some time load the crack
			if random() < crackChange and noCrack == true then  

				-- valid are 1, 2, 3, 4 and 5
				img_used = images[math.random(1,5)]
				img = img_used[2]
				size = img_used[1]
			
				-- get some points to emit fx from
				fx_placement = {}
				for key, value in pairs(img) do
					if value ~= 0 and random() < 0.005 then
						fx_placement[key] = value
					end
				end 
			
				-- all over map
				if middle == false then
					positionCrackX = math.floor(random(0,(mapX*512-size["x"])))
					positionCrackZ = math.floor(random(0, (mapY*512-size["z"])))
				
				-- just in middle
				else
					positionCrackX = math.floor(random(crackAreaX,  mapX*512-crackAreaX-size["x"]))
					positionCrackZ = math.floor(random(crackAreaZ,  mapY*512-crackAreaX-size["z"]))
				end
				Echo(positionCrackX)
				Echo(positionCrackZ)
				crack = true
			end
		end
		
		if (crack == true) then

			-- after another minute emit-fx and show some warning message
			if (f%300 == 0) and noCrack == true then
				if (random() < 0.5) then
				
					-- emit fx on points
					for key, value in pairs(fx_placement) do
						for k, v in string.gmatch(key,"(%w+),(%w+)") do
							if random() < 0.1 then
								local y = GetGroundHeight(k,v)
								SpawnCEG(metalcloud2,tonumber(v)+positionCrackX, y+10, tonumber(k)+positionCrackZ)
								if random() < 0.1 then
									PlaySoundFile (crushsnd, 2.0, positionCrackX,y,positionCrackZ, 0,0,0,'battle')
								end
							end
						end
					end
					
					if random() < 0.5 then
						Echo("WARNING seismic activity detected!")
					end
				end
			end
			
			if (f%(crackInterval-1) == 0) and noCrack == true then
		
				-- create the crack
				local func1 = function()
					for key, value in pairs(img) do
						for k, v in string.gmatch(key,"(%w+),(%w+)") do
							local height = GetGroundOrigHeight(v+positionCrackX,k+positionCrackZ)
							if value ~= 0 then
								SetHeightMap(tonumber(v)+positionCrackX,tonumber(k)+positionCrackZ, height - value)
							end
						 end
					end
				end
				SetHeightMapFunc(func1)
				
				-- play some sound and emit fx
				for key, value in pairs(img) do
					for k, v in string.gmatch(key,"(%w+),(%w+)") do
						local height = Spring.GetGroundOrigHeight(v+positionCrackX,k+positionCrackZ)
						if value ~= 0 and random()< 0.2 then
							SpawnCEG(metalcloud2,tonumber(v)+positionCrackX, height + 10, tonumber(k)+positionCrackZ)
							PlaySoundFile (crushsnd, 2.0, positionCrackX,height,positionCrackZ, 0,0,0,'battle')
						end
					 end
				end 
				noCrack = false
			end
			
			if (f%(crackInterval+duration)== 0 and (noCrack == false)) then	
			
				-- undo crack
				local func2 = function()
					for key, value in pairs(img) do
						for k, v in string.gmatch(key,"(%w+),(%w+)") do
							SetHeightMap(tonumber(v)+positionCrackX,tonumber(k)+positionCrackZ, GetGroundOrigHeight(v+positionCrackX,k+positionCrackZ))
						 end
					end
				end
				SetHeightMapFunc(func2)
	
				-- emit some fx
				for key, value in pairs(fx_placement) do
					for k, v in string.gmatch(key,"(%w+),(%w+)") do
						if random() < 0.1 then
							local y = GetGroundHeight(k,v)
							SpawnCEG(metalcloud2,tonumber(v)+positionCrackX, y+10, tonumber(k)+positionCrackZ)
						end
					end
				end
				crack = false
				noCrack = true
			end
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
