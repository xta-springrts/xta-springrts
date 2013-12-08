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

	
	local crushNames = {
		arm_dragons_teeth_dead = true,
		core_dragons_teeth_dead = true,
	}
	local crushFeatures 					= {}
	local crushCEG 							= "dirtballtrail"
	local crushCEG2							= "FLAKFLARE"
	local crushCEG3							= "Sparks"
	local GetFeatureHealth 					= Spring.GetFeatureHealth
	local SpawnCEG							= Spring.SpawnCEG
	local GetFeaturePosition				= Spring.GetFeaturePosition

	function gadget:Initialize()
		for id, featureDef in ipairs (FeatureDefs) do
			if crushNames[featureDef.name] then
				crushFeatures[id] = true
			end
		end
	end

	function gadget:FeatureDamaged(featureID, featureDefID, _, damage , weaponDefID, projectileID , attackerID, attackerDefID)

		if weaponDefID == -6 and crushFeatures[featureDefID] then
			local health,hp = GetFeatureHealth(featureID)
			if health < 0 then
				local x,y,z = GetFeaturePosition(featureID)
				SendToUnsynced("crushSound", featureID)
				SpawnCEG(crushCEG2,x,y,z)
				SpawnCEG(crushCEG3,x,y,z)
				SpawnCEG(crushCEG,x,y,z)
			end
		end
	end
else
	
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