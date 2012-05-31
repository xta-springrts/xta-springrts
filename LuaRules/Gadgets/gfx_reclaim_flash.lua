   function gadget:GetInfo()
      return {
        name      = "Reclaim flash",
        desc      = "Nice tree reclaim effect",
        author    = "Jools, based on gadget with same name by beherith",
        date      = "January 2012",
        license   = "PD",
        layer     = 0,
        enabled   = true,
      }
    end
     
if (not gadgetHandler:IsSyncedCode()) then
  return
end

local eceg = "gplasmaballbloom"
local mceg = "bplasmaballbloom"
function gadget:FeatureDestroyed(featureID,allyteam)
	fx,fy,fz=Spring.GetFeaturePosition(featureID)
	--Spring.Echo(allyteam)
	if (fx ~= nil) then
		rm, mm, re, me, rl = Spring.GetFeatureResources(featureID)
		if (rm ~= nil) then
			if me > mm and rl == 0 then
				Spring.SpawnCEG(eceg, fx, fy, fz)
				Spring.PlaySoundFile('Sounds/RECLAIM1.wav', 1, fx, fy, fz)
			elseif mm >= me and rl == 0 then
				Spring.SpawnCEG(mceg, fx, fy, fz)
			end
		end
	end
end

