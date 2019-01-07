function gadget:GetInfo()
	return {
		name      	= "radiation",
		desc      	= "Radiation damage",
		author    	= "res",
		date      	= "8-10-2018",
		license 	= "GNU GPL, v3 or later",
		layer     	= 1,
		enabled   	= true,
	}
end


	--[[

		-Dependencies: 	-radiation_config
						-widget: fx_radiation

		-What it does:
			1. Specifies some units do damage to area/units by radiation
			2. Allows units to spell radiation to enemy units (weapon)

		-parameters options:
			1. set by unitDefs (customParams) how much units are effected:
				radiationinpact = [0,1]

			2. 	values in weaponDef.customParams (for weapon that have radiation):
				['radius'] =  300, 		natural number,		radius of radiation impact
				['damage'] = 0.1,		[0,1],				damage value
				['dRadius'] = -2,		integer,			change over time
				['dDamage'] = -0.001,	[0,1],				change over time
				['duration'] = 50,		natural number,		radiation after unit die on map
				['protection'] = 0.05   [0,1],				multiplier for damage (higher is more damage dealt)

			2. 	values in radiation_config (for unit that have radiation):
				['radius'] =  300, 		natural number,		radius of radiation impact
				['damage'] = 0.1,		[0,1],				damage value
				['dRadius'] = -2,		integer,			change over time
				['dDamage'] = -0.001,	[0,1],				change over time
				['duration'] = 50,		natural number,		radiation after unit die on map
				['protection'] = 0.05   [0,1],				multiplier for damage (higher is more damage dealt)

			3. DAMAGELEVEL = 100, 		natural number, 	Multiplier for applied damage

			4. MAXDAMAGERADIUS = 1000,	natural number,		Maximum distance radiation is applied to

		TODO: 1. maybe add functionality for units that do selfdamage by shooting stuff (half implemented)
		TODO: 2. maybe make some units susceptible for radiation?

	--]]	


-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end


-- LOCALS --

local radiationWeapons, radiationUnits	= include("LuaRules/Configs/radiation_config.lua")
local sqrt								= math.sqrt
local max								= math.max
local min								= math.min
local abs								= math.abs

local modOptions 						= Spring.GetModOptions()
local SetFeatureHealth					= Spring.SetFeatureHealth
local GetFeatureHealth					= Spring.GetFeatureHealth
local GetFeaturePosition				= Spring.GetFeaturePosition
local AddUnitDamage 					= Spring.AddUnitDamage
local GetFeaturesInSphere				= Spring.GetFeaturesInSphere
local GetUnitsInSphere					= Spring.GetUnitsInSphere
local GetUnitPosition					= Spring.GetUnitPosition
local GetFeatureDefID					= Spring.GetFeatureDefID
local GetUnitDefID						= Spring.GetUnitDefID
local Echo					      		= Spring.Echo
local ValidUnitID 						= Spring.ValidUnitID
local ValidFeatureID 					= Spring.ValidFeatureID
local SetGameRulesParam 				= Spring.SetGameRulesParam
local GetGameRulesParam					= Spring.GetGameRulesParam
local DestroyFeature					= Spring.DestroyFeature

local damageToUnits 					= {}
local damageToFeatures 					= {}
local unitsDoDamage						= {}
local timeDelayDamage					= 13 -- 1/4 second every second (either update or do damage)
local MAXDAMAGERADIUS					= 1000
local damageValues 						= {}
local DAMAGELEVEL 						= 100


-- GLOBALS --


if not GG.radiation then
	GG['radiation'] = {}
end
SetGameRulesParam('radiation_update_number', 0)


-- INITIALISE --


function gadget:Initialize()
	local mo = modOptions
	if mo and tonumber(mo.radiation)== 0 then
		Echo("radiation.lua: turned off via modoptions")
		gadgetHandler:RemoveGadget(self)
	else
		Echo("radiation.lua: gadget:Initialize() Game.mapName=" .. Game.mapName)
		Echo("Warning some units deal damage because of radiation!")
		for w,_ in pairs(radiationWeapons) do
			Script.SetWatchWeapon(w, true)
		end
	end
end


-- HELP FUNCTION --


local function removeUnitDoDamage(unitID)
	unitsDoDamage[unitID] = nil
	damageValues[unitID] = nil
	SetGameRulesParam('radiation_radius' .. unitID, 0)
	SetGameRulesParam('radiation_damage' .. unitID, 0)
	if GG.radiation[unitID] then
		GG.radiation[unitID] = nil
	end
	local update_number = GetGameRulesParam('radiation_update_number')
	SetGameRulesParam('radiation_update_number', update_number + 1)
end



local function update_damage()

	-- updating units causing damage
	for k,v in pairs(unitsDoDamage) do
		if ValidUnitID(k) == true then


			-- update coordinates
			local x,y,z = GetUnitPosition(k)
			unitsDoDamage[k].x = x
			unitsDoDamage[k].y = y
			unitsDoDamage[k].z = z

			-- damage or radius increases or decreases
			unitsDoDamage[k].damage = max(0,min(v.damage + damageValues[k].dDamage,1))
			unitsDoDamage[k].radius = max(0,min(v.radius +  damageValues[k].dRadius,MAXDAMAGERADIUS))
			SetGameRulesParam('radiation_radius' .. k, unitsDoDamage[k].radius)
			SetGameRulesParam('radiation_damage' .. k, unitsDoDamage[k].damage)


			-- remove unit from radiation list if i doesnt deliver radiation anymore
			if (unitsDoDamage[k].damage <= 0 or unitsDoDamage[k].radius <= 0) then
				removeUnitDoDamage(k)
			end

		elseif tonumber(v.duration) > 0 then

			-- damage radius and value only decreases
			unitsDoDamage[k].damage = max(v.damage - abs(damageValues[k].dDamage),0)
			unitsDoDamage[k].radius = max(v.radius - abs(damageValues[k].dRadius),0)
			unitsDoDamage[k].duration = v.duration - timeDelayDamage*2
			SetGameRulesParam('radiation_radius' .. k, unitsDoDamage[k].radius)
			SetGameRulesParam('radiation_damage' .. k, unitsDoDamage[k].damage)

			-- remove area from radiation list if it doesnt deliver radiation anymore
			if (unitsDoDamage[k].damage <= 0 or unitsDoDamage[k].radius <= 0) then
				removeUnitDoDamage(k)
			end

		else
			removeUnitDoDamage(k)

		end
	end


	-- update damaged to units/features
	damageToUnits = {}
	damageToFeatures = {}

	for k,v in pairs(unitsDoDamage) do
		local near_units = GetUnitsInSphere(v.x,v.y,v.z, v.radius)
		local near_features = GetFeaturesInSphere(v.x,v.y,v.z, v.radius)

		if not (near_units == nil) then
			for i in pairs(near_units) do
				local unitID = near_units[i]
				local damage = damageToUnits[unitID] or 0
				local multiplier
				local custom = UnitDefs[GetUnitDefID(unitID)].customParams
				local protection
				if custom ~= nil then
					protection = custom.radiationinpact
				else
					protection = nil
				end

				-- radiation unit
				if k == unitID then
					multiplier = damageValues[k].protection

				-- unit with defined protection
				elseif protection ~= nil then
					local xu,yu,zu = GetUnitPosition(unitID)
					multiplier = protection * 1-sqrt( (v.x-xu)*(v.x-xu) + (v.y-yu)*(v.y-yu) + (v.z-zu)*(v.z-zu) )/v.radius

				-- non radiation unit whitout protection
				else
					local xu,yu,zu = GetUnitPosition(unitID)
					multiplier = 1-sqrt( (v.x-xu)*(v.x-xu) + (v.y-yu)*(v.y-yu) + (v.z-zu)*(v.z-zu) )/v.radius
				end

				damageToUnits[unitID] = max(v.damage *multiplier*DAMAGELEVEL,damage)
			end
		end
		if not (near_features == nil) then
			for i in pairs(near_features) do
				if not FeatureDefs[GetFeatureDefID(near_features[i])].geoThermal then
					local featureID = near_features[i]
					local xf,yf,zf = GetFeaturePosition(featureID)
					local multiplier = 1-sqrt( (v.x-xf)*(v.x-xf) + (v.y-yf)*(v.y-yf) + (v.z-zf)*(v.z-zf) )/v.radius
					local damage = damageToFeatures[featureID] or 0
					damageToFeatures[featureID] = max(v.damage*multiplier*DAMAGELEVEL,damage)
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
						['protection'] = GG.radiation[unitID].protection
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
					local update_number = GetGameRulesParam('radiation_update_number')
					SetGameRulesParam('radiation_update_number', update_number + 1)
				end
			end
		end
	end
end


local function apply_damage()
	for k,v in pairs(damageToUnits) do
		if ValidUnitID(k) == true then
			AddUnitDamage(k, v)
			damageToUnits[k] = 0

		else
			damageToUnits[k] = nil
		end
	end
	for k,v in pairs(damageToFeatures) do
		if ValidFeatureID(k) then
			local feature_health = GetFeatureHealth(k)
			if feature_health-v <= 0 then
				DestroyFeature(k)
			else
				SetFeatureHealth(k,feature_health-v)
			end
			damageToFeatures[k] = 0
		else
			damageToFeatures[k] = nil
		end
	end
end


-- CALL-INS


function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	local UDID = GetUnitDefID(unitID)
	if radiationUnits[UnitDefs[UDID].name] then
		damageValues[unitID] = radiationUnits[UnitDefs[UDID].name]
		GG.radiation[unitID] = damageValues[unitID]
		SetGameRulesParam('radiation_radius' .. unitID, GG.radiation[unitID].radius)
		SetGameRulesParam('radiation_damage' .. unitID, GG.radiation[unitID].damage)
		local update_number = GetGameRulesParam('radiation_update_number')
		SetGameRulesParam('radiation_update_number', update_number + 1)
		local x,y,z = GetUnitPosition(unitID)
		unitsDoDamage[unitID] = {
						["damage"] = GG.radiation[unitID].damage,
						["radius"] = GG.radiation[unitID].radius,
						["x"] = x,
						["y"] = y,
						["z"] = z,
						["duration"] = GG.radiation[unitID].duration
		}
	end
end


function gadget:Explosion(weaponID, px, py, pz, ownerID)
	if (radiationWeapons[weaponID]) then

		--local AOE = WeaponDefs[weaponID].damageAreaOfEffect * 2 --to small i guess
		local AOE = 50
		local hit_units = GetUnitsInSphere(px,py,pz, AOE)
		for index, unitID in pairs(hit_units) do
			if not (ownerID == unitID) then
				if damageValues[unitID] == nil then  -- only add non already hit unit to the radiation units
					damageValues[unitID] = radiationWeapons[weaponID]
					GG.radiation[unitID] = damageValues[unitID]
					SetGameRulesParam('radiation_radius' .. unitID, GG.radiation[unitID].radius)
					SetGameRulesParam('radiation_damage' .. unitID, GG.radiation[unitID].damage)
					local update_number = GetGameRulesParam('radiation_update_number')
					SetGameRulesParam('radiation_update_number', update_number + 1)
					unitsDoDamage[unitID] = {
						["damage"] = GG.radiation[unitID].damage,
						["radius"] = GG.radiation[unitID].radius,
						["x"] = px,
						["y"] = py,
						["z"] = pz,
						["duration"] = GG.radiation[unitID].duration
					}
				end
			end
		end
		--old stuff (that does damage to the shooter of the weapon)
		--[[
		if damageValues[ownerID] == nil then
			damageValues[ownerID] = {
				['radius'] = radiationWeapons[weaponID].radius,
				['damage'] = radiationWeapons[weaponID].damage,
				['dRadius'] = radiationWeapons[weaponID].dRadius,
				['dDamage'] = radiationWeapons[weaponID].dDamage,
				['duration'] = radiationWeapons[weaponID].duration,
				['protection'] = radiationWeapons[weaponID].protection
			}
			GG.radiation[ownerID] = damageValues[ownerID]
			SetGameRulesParam('radiation_radius' .. ownerID, GG.radiation[ownerID].radius)
			SetGameRulesParam('radiation_damage' .. ownerID, GG.radiation[ownerID].damage)
			local update_number = GetGameRulesParam('radiation_update_number')
			SetGameRulesParam('radiation_update_number', update_number + 1)
		end
		--]]
	end
	return false
end


-- LOOP --


function gadget:GameFrame(f)

	if (f%timeDelayDamage == 0) then

		if (f%2 ==0) then

			update_damage()

			update_radiation_unit()

		else

			apply_damage()

		end
	end

end
