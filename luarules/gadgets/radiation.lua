function gadget:GetInfo()
	return {
		name      	= "radiation",
		desc      	= "Radiation damage",
		author    	= "res (code used from Underwater blue by Jools for FX)",
		date      	= "8-10-2018",
		license 	= "GNU GPL, v3 or later",
		layer     	= 1,
		enabled   	= true,
	}
end


	--[[

		Specifies some units do damage to other units (radiation)

		-parameters options:
			- 

		# TODO
		1. add parameters
		2. Add map damage area fx 
		4. Add more units that do damage to neighborhood
		5. Add list with damage areas (without units) 
		6. Only set one specific unit do damage (instead of all of same unittype)(via unitID link list)
		7. Make a global table with demage units

	--]]	


-- synced only
if (gadgetHandler:IsSyncedCode()) then


	-- LOCALS --


	local floor 						= math.floor
	local random					    = math.random
	local sqrt							= math.sqrt
	local max							= math.max
	local min							= math.min

	local gmatch						= string.gmatch
	local remove						= table.remove

	local modOptions 					= Spring.GetModOptions()
	local SetFeatureHealth				= Spring.SetFeatureHealth
	local DestroyFeature				= Spring.DestroyFeature
	local GetFeatureHealth				= Spring.GetFeatureHealth
	local GetFeaturePosition			= Spring.GetFeaturePosition
	local AddUnitDamage 				= Spring.AddUnitDamage
	local GetFeaturesInSphere			= Spring.GetFeaturesInSphere
	local GetUnitsInSphere				= Spring.GetUnitsInSphere
	local GetUnitPosition				= Spring.GetUnitPosition
	local GetUnitDefID					= Spring.GetUnitDefID
	local GetFeatureDefID				= Spring.GetFeatureDefID
	local Echo					      	= Spring.Echo
	local GetUnitsInCylinder			= Spring.GetUnitsInCylinder
	local GetGroundHeight				= Spring.GetGroundHeight
	local GetGroundOrigHeight			= Spring.GetGroundOrigHeight
	local SetHeightMapFunc				= Spring.SetHeightMapFunc
	local PlaySoundFile					= Spring.PlaySoundFile
	local SetHeightMap 					= Spring.SetHeightMap
	local SpawnCEG					  	= Spring.SpawnCEG
	local SetGameRulesParam 			= Spring.SetGameRulesParam
	local GetGameRulesParam 			= Spring.GetGameRulesParam
	local GaiaTeamID  					= Spring.GetGaiaTeamID()
	local SetUnitNeutral				= Spring.SetUnitNeutral
	local SetUnitNoSelect				= Spring.SetUnitNoSelect
	local CreateUnit					= Spring.CreateUnit
	local DestroyUnit					= Spring.DestroyUnit
	local SetUnitAlwaysVisible			= Spring.SetUnitAlwaysVisible
	local SetUnitPosition 				= Spring.SetUnitPosition
	local SetUnitStealth				= Spring.SetUnitStealth
	local TransferUnit					= Spring.TransferUnit
	local GetTeamList 					= Spring.GetTeamList()
	local GetAllUnits 					= Spring.GetAllUnits
	local ValidFeatureID 				= Spring.ValidFeatureID
	local ValidUnitID 					= Spring.ValidUnitID
	local GetGameRulesParam 			= Spring.GetGameRulesParam


	-- communication between gadget and widget
	local SetGameRulesParam 			= Spring.SetGameRulesParam
	local prefix						= 'radiation_'

	local COMET_FIRE				  	= "RedPlasmaComet"
	local COMET_HIT_GROUND				= "SMALL_NUKE_EXPLOSION_INIATE_COMET"
	local PUFFY							= "PUFFY_COMET"
	local crushsnd					  	= "sounds/battle/crush3.wav"


	local mapX 					      	= Game.mapX
	local mapZ 					      	= Game.mapY

	local WANDGLOW						='WANDGLOW'
	local PORTALGLOW					= 'PORTALGLOW'

	-- SETTINGS --

	local moving = {
		["kbotsf2"] 	= true,
		["kbotsf3"] 	= true,
		["kbotss2"] 	= true,
		["kbotuw3"] 	= true,						-- gimp, spiders, moved land pelican to this
		--["kbotds2"] 	= true,	 					-- commanders
		["tankbh3"] 	= true,
		["tankdh3"] 	= true,	 					-- beaver, crab, triton, crock, garpike, muskrat, zulu
		["tanksh2"] 	= true,
		["tanksh2"] 	= true,
		["tanksh4"] 	= true,
		["tankdtcrush"] = true,	 					-- Bulldog/Reaper/Goliath can crush DT's
		["spid3"] 	= true,
		["krogoth"] 	= true,
		["crawlbomb"] 	= true,						-- crawling bombs
		["tankdh4"] 	= true,						-- beaver, crab, triton, crock, garpike, muskrat, zulu -- land
		["hover1"] 	= true,
		["hover2"]	= true,
		["hover3"]	= true,
		["hover4"]	= true,
		["hover9"]	= true,
		["hover10"]	= true,
	}


	if not GG.radiation then
		GG['radiation'] = {}
	end

	local TeamIDsComets 					= {}
	for _,teamID in pairs(GetTeamList) do
		if GaiaTeamID ~= teamID then
			table.insert(TeamIDsComets, teamID)
		end
	end
	local damageToUnits 					= {}
	local damageToFeatures 					= {}
	local unitsDoDamage					= {}
	local randomUnits 					= true
	local unitNameComet 					= "arm_peewee"
	local FALL_SPEED					= 60  -- 60 every 5th timeframe
	local transfer	 					= true
	local timeDelayCrack					= 30 * 60 + 1 -- 1 min
	local timeDelayComet 					= tonumber(modOptions.time_delay_comet) * 30 * 60 or 30 * 60 + 1 -- 2.5 min
	local timeDelayDamage					= 61 -- every second (either update or do damage)
	local duration						= tonumber(modOptions.duration_crack) *30 *60 + 1 or 9000 +1 		-- 5 min crack duration
	local crackAreaX					= floor(mapX*512*1/10)								-- defines middle
	local crackAreaZ					= floor(mapZ*512*1/10)
	local middle 					  	= false					-- is middle only cracked?
	local cracks						= {}
	local remove_cracks					= {}
	local add_cracks					= {}
	local max_cracks					= tonumber(modOptions.max_cracks) or 10
	local max_comets					= tonumber(modOptions.max_comets) or 10
	local damage_radius					= tonumber(modOptions.max_radius_damage_comets) or 500
	local damage_value            		= tonumber(modOptions.max_damage_comets) or 500
	local randomize_number_of_cracks	= 150 -- same as below but for cracks
	local randomize_number_of_comets	= 100 -- how often number of comets in rain are randomized (higher is less ofthen)
	local cometRainRadius 				= tonumber(modOptions.comet_rain_radius) or 500 -- comet spreading
	local maxDamageRadius				= 1000

	-- DAMAGE PARAMETERS

	local damageValues = {}
	--	["arm_peewee"] 		= {["value"] = 0.1, ["radius"] = 500, ["dDamage"] = 0.01, ["dRadius"] = 1, ["duration"] = 3000, ["self"] = 20},
	--	["arm_hammer"] 		= {["value"] = 0.8, ["radius"] = 500, ["dDamage"] = 0.01, ["dRadius"] = 1, ["duration"] = 3000, ["self"] = 20},
	--	["some_other_unit"] 	= {["value"] = 20, ["radius"] = 500, ["dDamage"] = 1, ["dRadius"] = 1, ["duration"] = 3000, ["self"] = 0.1}
	--}


	-- INITIALISE --


	function gadget:Initialize()
		local mo = Spring.GetModOptions()
		if mo and tonumber(mo.radiation)== 0 then
			Echo("radiation.lua: turned off via modoptions")
			gadgetHandler:RemoveGadget(self)
		end
		Echo("radiation.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
		Echo("Warning some units deal damage because of radiation!")
	end


	-- HELP FUCNTION --


	function update_damage()

		-- updating units causing damage
		for k,v in pairs(unitsDoDamage) do
			-- WANDGLOW, PORTALGLOW
			if ValidUnitID(k) == true then
				unitsDoDamage[k].damage = min(v.damage + damageValues[k].dDamage,1)
				unitsDoDamage[k].radius = min(v.radius +  damageValues[k].dRadius,maxDamageRadius)
				SetGameRulesParam('radiation_radius' .. k, unitsDoDamage[k].radius)
				SetGameRulesParam('radiation_damage' .. k, unitsDoDamage[k].damage)
			elseif v.duration > 0 then
				unitsDoDamage[k].damage = max(v.damage - damageValues[k].dDamage,0)
				unitsDoDamage[k].radius = max(v.radius - damageValues[k].dRadius,0)
				unitsDoDamage[k].duration = v.duration - timeDelayDamage*2
				SetGameRulesParam('radiation_radius' .. k, unitsDoDamage[k].radius)
				SetGameRulesParam('radiation_damage' .. k, unitsDoDamage[k].damage)
				if not ((unitsDoDamage[k].damage > 0) and (unitsDoDamage[k].radius > 0)) then
					unitsDoDamage[k] = nil
					SetGameRulesParam('radiation_radius' .. k, nil)
					SetGameRulesParam('radiation_damage' .. k, nil)
				end
			else
				unitsDoDamage[k] = nil
			end
		end


		-- update damaged to units/features
		for k,v in pairs(unitsDoDamage) do
			local near_units = GetUnitsInSphere(v.x,v.y,v.z, v.radius)
			local near_features = GetFeaturesInSphere(v.x,v.y,v.z, v.radius)

			if not (near_units == nil) then
				for i in pairs(near_units) do
					local unitID = near_units[i]
					local xu,yu,zu = GetUnitPosition(unitID)
					local multiplier = 1-sqrt( (v.x-xu)*(v.x-xu) + (v.y-yu)*(v.y-yu) + (v.z-zu)*(v.z-zu) )/v.radius
					local damage = damageToUnits[unitID] or 0
					damageToUnits[unitID] = max(v.damage *multiplier*1000,damage)
				end
			end
			if not (near_features == nil) then
				for i in pairs(near_features) do
					if not FeatureDefs[GetFeatureDefID(near_features[i])].geoThermal then
						local featureID = near_features[i]
						local unitDefID = GetUnitDefID(featureID)
						local xf,yf,zf = GetFeaturePosition(featureID)
						local multiplier = 1-sqrt( (v.x-xf)*(v.x-xf) + (v.y-yf)*(v.y-yf) + (v.z-zf)*(v.z-zf) )/v.radius
						local damage = damageToFeatures[featureID] or 0
						damageToFeatures[featureID] = max(v.damage*multiplier*1000,damage)
					end
				end
			end

		end
	end


	local function update_radiation_unit()
		if GG.radiation then
			for unitID,v in pairs(GG.radiation) do
				if ValidUnitID(unitID) then
					if damageValues[unitID] == nil then
						damageValues[unitID] = {
							['radius'] = GG.radiation[unitID].radius,
							['damage'] = GG.radiation[unitID].damage,
							['dRadius'] = GG.radiation[unitID].dRadius,
							['dDamage'] = GG.radiation[unitID].dDamage,
							['duration'] = GG.radiation[unitID].duration,
							['self'] = GG.radiation[unitID].self
						}
						local x, y, z = GetUnitPosition(unitID)
						unitsDoDamage[unitID] = {
							["damage"] = GG.radiation[unitID].damage,
							["radius"] = GG.radiation[unitID].radius,
							["x"] = x,
							["y"] = y,
							["z"] = z,
							["duration"] = GG.radiation[unitID].duration,
						}
						SetGameRulesParam('radiation_radius' .. unitID, GG.radiation[unitID].radius)
						SetGameRulesParam('radiation_damage' .. unitID, GG.radiation[unitID].damage)
					end
				end
			end
		end
	end


	--function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	--	unitsDoDamage[unitID] = nil
	--end

	function apply_damage()
		for k,v in pairs(damageToUnits) do
			if ValidUnitID(k) == true then
				AddUnitDamage(k, v)
				damageToUnits[k] = 0

			else
				damageToUnits[k] = nil
			end
		end
		for k,v in pairs(damageToFeatures) do
			-- test if unit exists
			if ValidFeatureID(k) then
				local feature_health = GetFeatureHealth(k)
				SetFeatureHealth(k,feature_health-v)
				damageToFeatures[k] = 0
			else
				damageToFeatures[k] = nil
			end
		end
	end


	-- LOOP --


	function gadget:GameFrame(f)


		-- MAP DAMAGE TO UNITS/FEATURES PART
		if (f%timeDelayDamage == 0) then

			if (f%2 ==0) then

				update_damage()

				update_radiation_unit()

			else

				apply_damage()

			end
		end

	end


end
