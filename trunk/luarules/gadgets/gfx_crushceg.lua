   function gadget:GetInfo()
      return {
        name      = "Crush ceg",
        desc      = "Nice dt crush effect",
        author    = "Jools",
        date      = "Dec 2013",
        license   = "Shark",
        layer     = 0,
        enabled   = true,
      }
    end
    
if gadgetHandler:IsSyncedCode() then

	-------------------
	-- SYNCED PART --
	-------------------
	
	local crushNames = {
		arm_dragons_teeth_dead = true,
		core_dragons_teeth_dead = true,
	}
	
	local metalCloudNames = {
		arm_metal_extractor = true,
		arm_underwater_metal_extractor = true,
		core_metal_extractor = true,
		core_underwater_metal_extractor = true,
		arm_moho_mine = true,
		arm_underwater_moho_mine = true,
		core_moho_mine = true,
		core_underwater_moho_mine = true,
	}
	
	
	
	local crushFeatures 					= {}
	local metalCloudUnits					= {}
	local cloudList							= {}
	local crushCEG 							= "dirtballtrail"
	local crushCEG2							= "FLAKFLARE"
	local crushCEG3							= "Sparks"
	local metalcloud1						= "buttsmoke"
	local metalcloud2						= "smokeshell_medium"
	local GetUnitHealth 					= Spring.GetUnitHealth
	local GetFeatureHealth 					= Spring.GetFeatureHealth
	local SpawnCEG							= Spring.SpawnCEG
	local GetFeaturePosition				= Spring.GetFeaturePosition
	local GetUnitPosition					= Spring.GetUnitPosition
	local GetGameFrame						= Spring.GetGameFrame
	local max								= math.max
	local Echo								= Spring.Echo
	local CRUSHID							= -7 -- this may change, before spring 96 this was -6

	function gadget:Initialize()
		for id, featureDef in ipairs (FeatureDefs) do
			if crushNames[featureDef.name] then
				crushFeatures[id] = true
			end
		end
		
		for id, unitDef in ipairs (UnitDefs) do
			if metalCloudNames[unitDef.name] then
				metalCloudUnits[id] = true
			end
		end
		
	end

	function gadget:FeatureDamaged(featureID, featureDefID, _, damage , weaponDefID, projectileID , attackerID, attackerDefID)
		
		if weaponDefID == CRUSHID and crushFeatures[featureDefID] then
			local health = GetFeatureHealth(featureID)
			if health < 0 then
				local x,y,z = GetFeaturePosition(featureID)
				SendToUnsynced("crushSound", featureID)
				SpawnCEG(crushCEG2,x,y,z)
				SpawnCEG(crushCEG3,x,y,z)
				SpawnCEG(crushCEG,x,y,z)
			end
		end
	end
	
	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID, attackerID, attackerDefID, attackerTeam) 
		
		local health,_,_,_,buildProgress = GetUnitHealth(unitID)
		if health < 0 and buildProgress == 1 then
			
			if metalCloudUnits[unitDefID] then
				local x,y,z = GetUnitPosition(unitID)
				local frame = GetGameFrame()
				
				cloudList[frame] = {x,y,z}
			end
		end
	end
	
	function gadget:GameFrame(frame)
		if cloudList then
			for f,cloud in pairs(cloudList) do
				if frame-f > 55 then
					local x,y,z = cloud[1],cloud[2],cloud[3]
					SpawnCEG(metalcloud1,x,max(y,0),z,0,0,0,1000)
					SpawnCEG(metalcloud2,x,max(y,0),z,0,0,0,1000)
					cloudList[f] = nil
				end
			end
		end
	end

else
	
	-------------------
	-- UNSYNCED PART --
	-------------------
	
	
	local PlaySoundFile				= Spring.PlaySoundFile
	local crushsnd					= "sounds/crush3.wav"
	local myTeamID
	local myAllyID				
	local GetFeaturePosition		= Spring.GetFeaturePosition
	local IsPosInLos				= Spring.IsPosInLos
	
	
	function gadget:Initialize()
		gadgetHandler:AddSyncAction("crushSound", CrushSound)
		myTeamID = Spring.GetMyTeamID()
		myAllyID = Spring.GetMyAllyTeamID()
	end
	
	function CrushSound(_, featureID)
	
		local x,y,z = GetFeaturePosition(featureID)

		if x and y and z then
			local los = CallAsTeam(myTeamID,IsPosInLos, x,y,z,myAllyID)			
			if los then
				PlaySoundFile (crushsnd, 2.0, x,y,z, 'battle')
			end
		end
		
	end	
	
end