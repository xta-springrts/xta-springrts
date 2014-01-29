function gadget:GetInfo()
  return {
	name      = "Featurespawner",
	desc      = "Places all wrecks and heaps on map",
	author    = "Jools",
	date      = "Oct 2013",
	license   = "Shark",
	layer     = 0,
	enabled   = false,
  }
end

-- designed for maps like coldplace and bigger. If you use on too small map, spring may crash. Modify "step" variable if needed

local modOptions = Spring.GetModOptions()

if modOptions and modOptions.debugmode then
	if modOptions.debugmode == '1' then 
		enable = true 
	end
	else
	if Game.modVersion =='$VERSION' then 
		enable = true 
	end
end

if not enable then 	-- allow spawning info only for SVN version
	return false
end
	 
if (gadgetHandler:IsSyncedCode()) then
	-----------------
	-- SYNCED PART --
	-----------------
	
	local spawnCommand = "spawnfeatures"
	local Echo = Spring.Echo

	function gadget:Initialize()
  		gadgetHandler:AddChatAction(spawnCommand, SpawnAllFeatures, "Spawn all features on map")
	end

	function gadget:Shutdown()
		gadgetHandler:RemoveChatAction(spawnCommand)
	end
	
	function gadget:GameFrame(f)
		if f==150 then
			SpawnAllFeatures()
		end
	end	
	
	function SpawnAllFeatures()
		Echo("Spawning all features...")
		local row, col = 0, 0
		local x0,z0 = 100,100
		local mapx,mapz = Game.mapSizeX, Game.mapSizeZ
		local step = 250 -- modify if needed on smaller map
		local count = 0
		for i, fdef in ipairs (FeatureDefs) do
			local x = x0 + col * step
			local z 
			if x > mapx then
				col = 0
				row = row + 1 
			end
			
			x = x0 + col * step
			z = z0 + row * step
			y = Spring.GetGroundHeight(x,z)
			
			if z > mapz then row = 0.5 end
			
			if x and y and z then
				--if fdef.name:match("core_") then
					Spring.CreateFeature(fdef.id,x,y,z)
				
					--Echo("Feature:",i,x,z,fdef.name)
					
					-- gl.PushMatrix()			
					-- gl.Translate(x,y,z)
					-- gl.Billboard()			
					-- gl.Text(fdef.name,0,0,10)
					-- gl.PopMatrix()
					
					if i%2 == 0 then z = z - 40 end
				
					Spring.MarkerAddPoint(x,y,z,fdef.name)
					count = count + 1
					col = col + 1
				--end
			end
		end
		Echo("Spawned " .. count .. "features.")
	end
	
else

end