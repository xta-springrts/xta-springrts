   function gadget:GetInfo()
      return {
        name      = "Transporter wrecks",
        desc      = "Places wrecks from dead transsporter",
        author    = "Jools",
        date      = "Oct 2013",
        license   = "Shark",
        layer     = 0,
        enabled   = true,
      }
    end
     
if (gadgetHandler:IsSyncedCode()) then
	-----------------
	-- SYNCED PART --
	-----------------

	local GetUnitIsTransporting		= Spring.GetUnitIsTransporting
	local GetUnitPosition			= Spring.GetUnitPosition
	local GetUnitDefID				= Spring.GetUnitDefID
	local GetUnitHealth				= Spring.GetUnitHealth
	local CreateUnit				= Spring.CreateUnit
	local CreateFeature				= Spring.CreateFeature
	local DestroyUnit				= Spring.DestroyUnit
	local SpawnCEG					= Spring.SpawnCEG
	local Echo						= Spring.Echo
	local random					= math.random
	local wreckCEG					= "napalam"
	local wreckprojectile			= "DECOY_BLAST"
	
	local wreckNames = {}
	local FeatureNames = {}
	local weaponDefID
	
	function gadget:Initialize()
		for _, fdef in pairs (FeatureDefs) do
			FeatureNames[fdef.name] = true
		end
	
		for i, uDef in ipairs (UnitDefs) do
			local dead = uDef.wreckName
			local heap = uDef.name .. "_heap"
			wreckNames[i] = {}
			if FeatureNames[dead] then
				wreckNames[i]["dead"] = dead
				--Echo("Wreck:",i,dead)
			end
			if FeatureNames[heap] then
				wreckNames[i]["heap"] = heap
				--Echo("Heap:",i,heap)
			end
		end
		
		weaponDefID = WeaponDefNames[wreckprojectile]
	end
	
	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID)
		local health = GetUnitHealth(unitID)
		
		if health < 0 and health > -1000 then
			local passengers = GetUnitIsTransporting(unitID)
			if passengers and #passengers >0 then
				local releaseHeld = UnitDefs[GetUnitDefID(unitID) ].releaseHeld
				local x0,y,z0 = GetUnitPosition(unitID)
				if releaseHeld == false then
					for i, pID in pairs (passengers) do
						local x = x0 +random(-50,50)
						local z = z0 +random(-50,50)
						local rnd = random(0,100)
						local passDefID = GetUnitDefID(pID)
						local wreckName
						if rnd > 70 then 
							wreckName = wreckNames[passDefID]["heap"]
						elseif rnd > 40 then
							wreckName = wreckNames[passDefID]["dead"]
						end
							
						if wreckName then
							local wreckID = CreateFeature(wreckName, x,y+20,z)
	
						elseif passDefID then
							local deadID = CreateUnit(passDefID,x,y,z,0,unitTeam)
							DestroyUnit(deadID)
						end
					end
				end
			end
		end
	end
end