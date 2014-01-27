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
	local Echo						= Spring.Echo
	local SpawnCEG					= Spring.SpawnCEG
	local random					= math.random
		
	local wreckNames = {}
	local FeatureNames = {}
	local expCEG					= "napalam"
	
	local function DestroyDeadUnit(unitID)
		if unitID then
			DestroyUnit(unitID)
		end
	end
	
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
			end
			if FeatureNames[heap] then
				wreckNames[i]["heap"] = heap
			end
		end
		
	end
	
	function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID)
		local health = GetUnitHealth(unitID)
		
		if health < 0 and health > -2000 then
			local passengers = GetUnitIsTransporting(unitID)
			if passengers and #passengers >0 then
				local releaseHeld = UnitDefs[unitDefID ].releaseHeld
				local x0,y,z0 = GetUnitPosition(unitID)
				if releaseHeld == false then
					for i, pID in pairs (passengers) do
						local x = x0 +random(-50,50)
						local z = z0 +random(-50,50)
						local rnd = random(0,100)
						local passDefID = GetUnitDefID(pID)
						local wreckName
						if rnd + health/40 > 50 then 
							wreckName = wreckNames[passDefID]["dead"]
						elseif rnd + health/40 > 0 then
							wreckName = wreckNames[passDefID]["heap"]
						end
							
						if wreckName then
							local wreckID = CreateFeature(wreckName, x,y+20,z)
						end
					end
					SpawnCEG(expCEG,x0,y,z0)
				end
			end
		end
	end
end